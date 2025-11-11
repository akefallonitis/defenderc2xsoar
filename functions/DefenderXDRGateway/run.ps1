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

$correlationId = [guid]::NewGuid().ToString()
$startTime = Get-Date

Write-Host "[$correlationId] DefenderXDRGateway - Processing request"

# ============================================================================
# PARAMETER EXTRACTION
# Support both 'tenant' and 'tenantId' for user convenience
# ============================================================================

$service = $Request.Query.service ?? $Request.Body.service
$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId ?? $Request.Query.tenant ?? $Request.Body.tenant

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
            validServices = @("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure")
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
    
    # Build payload for Orchestrator (standardize parameter names)
    $orchestratorPayload = @{
        service = $service
        action = $action
        tenantId = $tenantId
        correlationId = $correlationId
    }
    
    # Forward ALL other parameters from query string and body
    if ($Request.Query) {
        foreach ($key in $Request.Query.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId', 'code')) {
                $orchestratorPayload[$key] = $Request.Query[$key]
            }
        }
    }
    
    if ($Request.Body -is [hashtable]) {
        foreach ($key in $Request.Body.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId', 'correlationId')) {
                $orchestratorPayload[$key] = $Request.Body[$key]
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
    
    # Forward Orchestrator response to caller
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $orchestratorResponse | ConvertTo-Json -Depth 10
        Headers = @{
            "Content-Type" = "application/json"
            "X-Correlation-ID" = $correlationId
            "X-Duration-Ms" = [Math]::Round($duration, 2)
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
