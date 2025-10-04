using namespace System.Net

# Incident Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDEIncidentManager function processed a request."

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
    # Import MDEAutomator module
    # Import-Module MDEAutomator -ErrorAction Stop
    
    # Connect to MDE using App Registration with Client Secret
    # $token = Connect-MDE -AppId $appId -ClientSecret $secretId -TenantId $tenantId

    $result = @{
        action = $action ?? "GetIncidents"
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    switch ($action) {
        "GetIncidents" {
            # $incidents = Get-Incidents
            # Apply filters if provided
            $result.details = "Retrieved incidents"
            $result.incidents = @() # Would contain actual incidents
            $result.filters = @{
                severity = $severity
                status = $status
            }
        }
        "GetIncidentDetails" {
            if ($incidentId) {
                # $incident = Get-Incident -IncidentId $incidentId
                $result.details = "Retrieved incident $incidentId"
                $result.incident = @{} # Would contain actual incident
            }
        }
        "UpdateIncident" {
            if ($incidentId) {
                # Update-Incident -IncidentId $incidentId -Status $status
                $result.details = "Updated incident $incidentId"
            }
        }
        default {
            # Default to listing incidents
            $result.details = "Retrieved incidents"
            $result.incidents = @()
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
