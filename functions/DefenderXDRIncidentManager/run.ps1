using namespace System.Net

# Incident Manager Function
param($Request, $TriggerMetadata)

Write-Host "DefenderC2IncidentManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$severity = $Request.Query.severity ?? $Request.Body.severity
$status = $Request.Query.status ?? $Request.Body.status
$incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameter: tenantId is required"
        } | ConvertTo-Json
    })
    return
}

# Validate environment variables are configured
if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = "Function app not configured: APPID and SECRETID environment variables must be set"
        } | ConvertTo-Json
    })
    return
}

try {
    # Connect to MDE using App Registration with Client Secret
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

    $result = @{
        action = $action ?? "GetIncidents"
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    switch ($action) {
        "GetIncidents" {
            # Build filter if provided
            $filter = $null
            $filterParts = @()
            
            if ($severity) {
                $filterParts += "severity eq '$severity'"
            }
            if ($status) {
                $filterParts += "status eq '$status'"
            }
            
            if ($filterParts.Count -gt 0) {
                $filter = $filterParts -join " and "
            }
            
            $incidents = Get-SecurityIncidents -Token $token -Filter $filter
            $result.details = "Retrieved $($incidents.Count) incidents"
            $result.incidents = $incidents | Select-Object -First 100  # Limit for response size
            $result.filters = @{
                severity = $severity
                status = $status
            }
        }
        "GetIncidentDetails" {
            if ($incidentId) {
                # Get specific incident using filter
                $incident = Get-SecurityIncidents -Token $token -Filter "id eq '$incidentId'"
                if ($incident) {
                    $result.details = "Retrieved incident $incidentId"
                    $result.incident = $incident[0]
                } else {
                    throw "Incident $incidentId not found"
                }
            } else {
                throw "Incident ID is required for GetIncidentDetails action"
            }
        }
        "UpdateIncident" {
            if ($incidentId) {
                # Update incident with provided parameters
                $updateParams = @{
                    Token = $token
                    IncidentId = $incidentId
                }
                
                if ($status) { $updateParams.Status = $status }
                
                $updatedIncident = Update-SecurityIncident @updateParams
                $result.details = "Updated incident $incidentId"
                $result.incident = $updatedIncident
            } else {
                throw "Incident ID is required for UpdateIncident action"
            }
        }
        default {
            # Default to listing incidents
            $incidents = Get-SecurityIncidents -Token $token
            $result.details = "Retrieved $($incidents.Count) incidents"
            $result.incidents = $incidents | Select-Object -First 100
        }
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 5
    })

} catch {
    Write-Error $_.Exception.Message
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = $_.Exception.Message
        } | ConvertTo-Json
    })
}
