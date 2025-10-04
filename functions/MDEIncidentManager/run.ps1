using namespace System.Net

# Incident Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDEIncidentManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId
$severity = $Request.Query.severity ?? $Request.Body.severity
$status = $Request.Query.status ?? $Request.Body.status
$incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId

if (-not $tenantId -or -not $spnId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters"
        } | ConvertTo-Json
    })
    return
}

try {
    # Import MDEAutomator module
    # Import-Module MDEAutomator -ErrorAction Stop
    
    # Connect to MDE
    # $token = Connect-MDE -SpnId $spnId -ManagedIdentityId $env:MSI_CLIENT_ID -TenantId $tenantId

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
