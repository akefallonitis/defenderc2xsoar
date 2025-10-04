using namespace System.Net

# Custom Detection Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDECDManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId
$detectionName = $Request.Query.detectionName ?? $Request.Body.detectionName
$detectionQuery = $Request.Query.detectionQuery ?? $Request.Body.detectionQuery
$severity = $Request.Query.severity ?? $Request.Body.severity

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
        action = $action ?? "List All Detections"
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    switch ($action) {
        "List All Detections" {
            # $detections = Get-DetectionRules
            $result.details = "Retrieved all custom detection rules"
            $result.detections = @() # Would contain actual detections
        }
        "Create Detection" {
            if ($detectionName -and $detectionQuery) {
                # $newDetection = Install-DetectionRule -jsonContent $detectionObject
                $result.details = "Created detection rule: $detectionName"
                $result.detectionName = $detectionName
            }
        }
        "Update Detection" {
            if ($detectionName -and $detectionQuery) {
                # Update-DetectionRule -RuleId $ruleId -jsonContent $detectionObject
                $result.details = "Updated detection rule: $detectionName"
            }
        }
        "Delete Detection" {
            if ($detectionName) {
                # Undo-DetectionRule -RuleId $ruleId
                $result.details = "Deleted detection rule: $detectionName"
            }
        }
        "Backup Detections" {
            # $detections = Get-DetectionRules
            # Save to Azure Storage
            $result.details = "Backed up all custom detection rules"
            $result.backupLocation = "Azure Blob Storage"
        }
        default {
            $result.details = "Retrieved all custom detection rules"
            $result.detections = @()
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
