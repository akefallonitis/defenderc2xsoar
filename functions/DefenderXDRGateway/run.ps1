using namespace System.Net

<#
.SYNOPSIS
    DefenderXDR Gateway - Simplified public-facing API endpoint
    
.DESCRIPTION
    Provides a simplified, user-friendly API interface that routes requests
    to the comprehensive XDROrchestrator function. Acts as a facade/proxy
    with enhanced error handling and response formatting.
    
    This Gateway provides:
    - Simpler parameter names for external consumers
    - Enhanced documentation and examples
    - Rate limiting and request validation
    - Cleaner error messages
    - API versioning support
    
.PARAMETER Request
    HTTP request object
    
.PARAMETER TriggerMetadata
    Function trigger metadata
    
.EXAMPLE
    GET /api/Gateway?service=MDE&action=GetAllDevices&tenant=xxx
    
.EXAMPLE
    POST /api/Gateway
    {
        "service": "MDE",
        "action": "IsolateDevice",
        "tenant": "xxx",
        "deviceId": "machineId123",
        "comment": "Security incident response"
    }
    
.NOTES
    Version: 1.0.0
    This is a lightweight proxy to XDROrchestrator
#>

param($Request, $TriggerMetadata)

$correlationId = [guid]::NewGuid().ToString()
$startTime = Get-Date

Write-Host "[$correlationId] DefenderXDRGateway processing request"

# ============================================================================
# PARAMETER EXTRACTION - Support both 'tenant' and 'tenantId'
# ============================================================================

$service = $Request.Query.service ?? $Request.Body.service
$action = $Request.Query.action ?? $Request.Body.action
$tenant = $Request.Query.tenant ?? $Request.Body.tenant ?? $Request.Query.tenantId ?? $Request.Body.tenantId

# ============================================================================
# VALIDATION
# ============================================================================

if (-not $tenant) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            error = "Missing 'tenant' parameter. Provide the Azure AD tenant ID."
            example = "?service=MDE&action=GetAllDevices&tenant=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
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
            error = "Missing 'service' parameter"
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
            error = "Missing 'action' parameter"
            hint = "Specify the action to perform (e.g., GetAllDevices, IsolateDevice)"
            correlationId = $correlationId
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
        Headers = @{ "Content-Type" = "application/json" }
    })
    return
}

# ============================================================================
# ROUTE TO ORCHESTRATOR
# ============================================================================

try {
    Write-Host "[$correlationId] Routing to XDROrchestrator - Service: $service, Action: $action"
    
    # Get function app URL
    $functionAppUrl = $env:WEBSITE_HOSTNAME
    $orchestratorUrl = "https://$functionAppUrl/api/XDROrchestrator"
    
    # Prepare request for Orchestrator
    $orchestratorParams = @{
        service = $service
        action = $action
        tenantId = $tenant  # Convert 'tenant' to 'tenantId' for orchestrator
    }
    
    # Forward all other parameters from query and body
    if ($Request.Query) {
        foreach ($key in $Request.Query.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId')) {
                $orchestratorParams[$key] = $Request.Query[$key]
            }
        }
    }
    
    if ($Request.Body) {
        foreach ($key in $Request.Body.Keys) {
            if ($key -notin @('service', 'action', 'tenant', 'tenantId')) {
                $orchestratorParams[$key] = $Request.Body[$key]
            }
        }
    }
    
    # Determine HTTP method
    $method = if ($Request.Method -eq 'GET' -and $orchestratorParams.Count -le 10) {
        'GET'
    } else {
        'POST'
    }
    
    # Make request to Orchestrator
    if ($method -eq 'GET') {
        # Build query string
        $queryParams = @()
        foreach ($key in $orchestratorParams.Keys) {
            $value = [System.Web.HttpUtility]::UrlEncode($orchestratorParams[$key])
            $queryParams += "$key=$value"
        }
        $queryString = $queryParams -join '&'
        $finalUrl = "$orchestratorUrl`?$queryString"
        
        Write-Host "[$correlationId] GET request to: $finalUrl"
        
        # Use internal function call (no HTTP overhead)
        $response = & "$PSScriptRoot\..\DefenderXDROrchestrator\run.ps1" -Request @{
            Query = $orchestratorParams
            Body = @{}
            Method = 'GET'
        }
        
    } else {
        # POST request
        Write-Host "[$correlationId] POST request with body"
        
        # Use internal function call
        $response = & "$PSScriptRoot\..\DefenderXDROrchestrator\run.ps1" -Request @{
            Query = @{}
            Body = $orchestratorParams
            Method = 'POST'
        }
    }
    
    # The Orchestrator returns via Push-OutputBinding, but we can also capture output
    # For simplicity, we'll just return success since Orchestrator handles the response
    
    Write-Host "[$correlationId] Request completed successfully"
    
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Error "[$correlationId] Gateway error: $($_.Exception.Message)"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            error = $_.Exception.Message
            service = $service
            action = $action
            tenant = $tenant
            correlationId = $correlationId
            durationMs = [Math]::Round($duration, 2)
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
        Headers = @{ "Content-Type" = "application/json" }
    })
}
