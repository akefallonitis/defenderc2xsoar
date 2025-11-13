using namespace System.Net

<#
.SYNOPSIS
    DefenderXDR Gateway - Public-facing API proxy to Orchestrator
    
.DESCRIPTION
    Lightweight gateway that validates input and forwards requests to the XDROrchestrator.
    This Gateway provides a simplified API with user-friendly parameter names.
    
    Architecture: Gateway (validation only) → Orchestrator (authentication + routing) → Workers (business logic)
    
.PARAMETER Request
    HTTP request object from Azure Functions trigger
    
.EXAMPLE
    GET /api/Gateway?service=MDE&action=GetAllDevices&tenantId=xxx-xxx-xxx
    
.EXAMPLE
    POST /api/Gateway
    {
        "service": "MDE",
        "action": "IsolateDevice",
        "tenantId": "xxx-xxx-xxx",
        "deviceIds": "machineId1,machineId2",
        "comment": "Security incident response"
    }
    
.NOTES
    Version: 3.0.0 - Modular architecture following Azure Functions best practices
    Gateway does NOT call modules directly - it's a pure HTTP proxy to Orchestrator
#>

param($Request, $TriggerMetadata)

# Import action tracking module
Import-Module "$PSScriptRoot\..\modules\ActionTracker.psm1" -Force

$correlationId = [guid]::NewGuid().ToString()
$actionId = [guid]::NewGuid().ToString()
$startTime = Get-Date

Write-Host "[$correlationId] DefenderXDRGateway - Processing request (ActionId: $actionId)"

# ============================================================================
# PARAMETER EXTRACTION
# Support both 'tenant' and 'tenantId' for user convenience
# Support ARM Action format (invoked via Azure Management API) and CustomEndpoint format (direct HTTPS)
# ============================================================================

# ARM Actions from Azure Workbooks come through Azure Management API
# Request body is string (not hashtable) when invoked via ARM
$requestBody = $Request.Body
if ($requestBody -is [string]) {
    try {
        $requestBody = $requestBody | ConvertFrom-Json -AsHashtable
        Write-Host "[$correlationId] Parsed ARM Action request body (invoked via Azure Management API)"
    } catch {
        Write-Host "[$correlationId] Could not parse request body as JSON: $_"
        $requestBody = @{}
    }
}

$service = $Request.Query.service ?? $requestBody.service
$action = $Request.Query.action ?? $requestBody.action
$tenantId = $Request.Query.tenantId ?? $requestBody.tenantId ?? $Request.Query.tenant ?? $requestBody.tenant

# ============================================================================
# INPUT VALIDATION
# Gateway only validates required parameters - business logic is in Orchestrator
# ============================================================================

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            error = "Missing required parameter: tenantId"
            hint = "Provide the Azure AD tenant ID in the request"
            example = "POST /api/Gateway with { `"service`": `"MDE`", `"action`": `"GetAllDevices`", `"tenantId`": `"xxx-xxx-xxx`" }"
            correlationId = $correlationId
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
        Headers = @{ "Content-Type" = "application/json" }
    })
    return
}

if (-not $service) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            error = "Missing required parameter: service"
            validServices = @("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure", "MCAS")
            correlationId = $correlationId
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
        Headers = @{ "Content-Type" = "application/json" }
    })
    return
}

if (-not $action) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            error = "Missing required parameter: action"
            hint = "Specify the action to perform (e.g., GetAllDevices, IsolateDevice, AdvancedHunt)"
            correlationId = $correlationId
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
        Headers = @{ "Content-Type" = "application/json" }
    })
    return
}

# ============================================================================
# PROXY TO ORCHESTRATOR
# Forward request to DefenderXDROrchestrator via internal HTTP call
# ============================================================================

try {
    Write-Host "[$correlationId] Routing to Orchestrator - Service: $service, Action: $action, Tenant: $($tenantId.Substring(0,8))..."
    
    # Start action tracking
    $trackingParams = @{
        Parameters = @{}
    }
    if ($Request.Query) {
        foreach ($key in $Request.Query.Keys) {
            if ($key -notin @('code', 'api-version')) {
                $trackingParams.Parameters[$key] = $Request.Query[$key]
            }
        }
    }
    if ($requestBody -is [hashtable]) {
        foreach ($key in $requestBody.Keys) {
            $trackingParams.Parameters[$key] = $requestBody[$key]
        }
    }
    
    Start-ActionTracking `
        -ActionId $actionId `
        -Action $action `
        -Service $service `
        -TenantId $tenantId `
        -Parameters $trackingParams.Parameters `
        -InitiatedBy ($Request.Headers['X-MS-CLIENT-PRINCIPAL-NAME'] ?? "Anonymous") `
        -CorrelationId $correlationId
    
    # Build payload for Orchestrator (standardize parameter names)
    $orchestratorPayload = @{
        service = $service
        action = $action
        tenantId = $tenantId
        correlationId = $correlationId
        actionId = $actionId
    }
    
    # Forward ALL other parameters from query string and body
    if ($Request.Query) {
        foreach ($key in $Request.Query.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId', 'code', 'api-version')) {
                $orchestratorPayload[$key] = $Request.Query[$key]
            }
        }
    }
    
    # Handle both CustomEndpoint format (hashtable) and ARM Action format (parsed from string)
    if ($requestBody -is [hashtable]) {
        foreach ($key in $requestBody.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId', 'correlationId')) {
                $orchestratorPayload[$key] = $requestBody[$key]
            }
        }
    }
    
    # Get Orchestrator URL (internal function-to-function call)
    $functionAppUrl = $env:WEBSITE_HOSTNAME
    if (-not $functionAppUrl) {
        throw "WEBSITE_HOSTNAME environment variable not found - function app misconfiguration"
    }
    
    $orchestratorUrl = "https://$functionAppUrl/api/DefenderXDROrchestrator"
    
    Write-Host "[$correlationId] Calling Orchestrator at: $orchestratorUrl"
    
    # Make internal HTTP POST to Orchestrator
    # Note: Using system key for internal calls (Azure Functions allows internal calls without function key)
    $orchestratorResponse = Invoke-RestMethod `
        -Method Post `
        -Uri $orchestratorUrl `
        -Body ($orchestratorPayload | ConvertTo-Json -Depth 10) `
        -ContentType "application/json" `
        -TimeoutSec 230 `
        -ErrorAction Stop
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "[$correlationId] Orchestrator responded successfully in $([Math]::Round($duration, 2))ms"
    
    # Complete action tracking
    Complete-ActionTracking `
        -ActionId $actionId `
        -TenantId $tenantId `
        -Success $true `
        -Result $orchestratorResponse
    
    # ============================================================================
    # RESPONSE FORMATTING - JSONPath-Friendly Structure
    # Ensure responses have clear array paths for Azure Workbook transformers
    # Examples: $.devices[*], $.incidents[*], $.alerts[*], $.indicators[*]
    # ============================================================================
    
    $formattedResponse = $orchestratorResponse
    
    # If response contains data arrays, ensure JSONPath-friendly naming
    # Common patterns: value[], machines[], alerts[], incidents[], indicators[], etc.
    if ($orchestratorResponse -is [hashtable]) {
        # MDE GetAllDevices: value[] → devices[]
        if ($orchestratorResponse.ContainsKey('value') -and $orchestratorResponse.value -is [array]) {
            $dataArray = $orchestratorResponse.value
            
            # Detect data type and use appropriate array name
            if ($action -match 'Device|Machine') {
                $formattedResponse.devices = $dataArray
                $formattedResponse.Remove('value')
            }
            elseif ($action -match 'Incident') {
                $formattedResponse.incidents = $dataArray
                $formattedResponse.Remove('value')
            }
            elseif ($action -match 'Alert') {
                $formattedResponse.alerts = $dataArray
                $formattedResponse.Remove('value')
            }
            elseif ($action -match 'Indicator|ThreatIntel') {
                $formattedResponse.indicators = $dataArray
                $formattedResponse.Remove('value')
            }
            elseif ($action -match 'Hunt|Query') {
                $formattedResponse.results = $dataArray
                $formattedResponse.Remove('value')
            }
            else {
                # Keep 'value' but also add generic 'data' for fallback
                $formattedResponse.data = $dataArray
            }
        }
        
        # Add Gateway metadata
        $formattedResponse.gatewayMetadata = @{
            correlationId = $correlationId
            durationMs = [Math]::Round($duration, 2)
            timestamp = (Get-Date).ToString("o")
            service = $service
            action = $action
        }
    }
    
    # Forward formatted response to caller
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $formattedResponse | ConvertTo-Json -Depth 10 -Compress:$false
        Headers = @{
            "Content-Type" = "application/json"
            "X-Correlation-ID" = $correlationId
            "X-Duration-Ms" = [Math]::Round($duration, 2)
            "X-Service" = $service
            "X-Action" = $action
        }
    })
    
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    $errorMessage = $_.Exception.Message
    $errorDetails = $_.ErrorDetails.Message ?? ""
    
    Write-Error "[$correlationId] Gateway error: $errorMessage"
    if ($errorDetails) {
        Write-Error "[$correlationId] Error details: $errorDetails"
    }
    
    # Complete action tracking with failure
    Complete-ActionTracking `
        -ActionId $actionId `
        -TenantId $tenantId `
        -Success $false `
        -ErrorMessage $errorMessage
    
    # Return structured error response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            error = @{
                code = "GATEWAY_ORCHESTRATOR_ERROR"
                message = $errorMessage
                details = $errorDetails
            }
            service = $service
            action = $action
            tenantId = $tenantId
            correlationId = $correlationId
            durationMs = [Math]::Round($duration, 2)
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
        Headers = @{
            "Content-Type" = "application/json"
            "X-Correlation-ID" = $correlationId
        }
    })
}
