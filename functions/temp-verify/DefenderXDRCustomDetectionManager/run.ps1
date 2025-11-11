using namespace System.Net

# Custom Detection Manager Function
param($Request, $TriggerMetadata)

Write-Host "DefenderC2CDManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$detectionName = $Request.Query.detectionName ?? $Request.Body.detectionName
$detectionQuery = $Request.Query.detectionQuery ?? $Request.Body.detectionQuery
$severity = $Request.Query.severity ?? $Request.Body.severity

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
        action = $action ?? "List All Detections"
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    # Get additional parameters from request
    $ruleId = $Request.Query.ruleId ?? $Request.Body.ruleId
    $enabled = $Request.Query.enabled ?? $Request.Body.enabled
    
    switch ($action) {
        "List All Detections" {
            $detections = Get-CustomDetections -Token $token
            $result.details = "Retrieved $($detections.Count) custom detection rules"
            $result.detections = $detections
        }
        "Create Detection" {
            if ($detectionName -and $detectionQuery) {
                $newDetection = New-CustomDetection -Token $token -Name $detectionName -Query $detectionQuery -Severity $severity -Description "Created via Azure Function"
                $result.details = "Created custom detection: $detectionName"
                $result.detection = $newDetection
            } else {
                throw "Detection name and query are required for creating a detection"
            }
        }
        "Update Detection" {
            if ($ruleId) {
                $updateParams = @{
                    Token = $token
                    RuleId = $ruleId
                }
                
                if ($detectionName) { $updateParams.Name = $detectionName }
                if ($detectionQuery) { $updateParams.Query = $detectionQuery }
                if ($severity) { $updateParams.Severity = $severity }
                if ($enabled -ne $null) { $updateParams.Enabled = [bool]$enabled }
                
                $updatedDetection = Update-CustomDetection @updateParams
                $result.details = "Updated custom detection: $ruleId"
                $result.detection = $updatedDetection
            } else {
                throw "Rule ID is required for updating a detection"
            }
        }
        "Delete Detection" {
            if ($ruleId) {
                Remove-CustomDetection -Token $token -RuleId $ruleId
                $result.details = "Deleted custom detection: $ruleId"
            } else {
                throw "Rule ID is required for deleting a detection"
            }
        }
        "Backup Detections" {
            $detections = Get-CustomDetections -Token $token
            $result.details = "Retrieved $($detections.Count) custom detection rules for backup"
            $result.detections = $detections
            $result.backupLocation = "Azure Blob Storage (not implemented)"
            $result.note = "Saving to storage would require additional Azure Storage configuration"
        }
        default {
            $detections = Get-CustomDetections -Token $token
            $result.details = "Retrieved $($detections.Count) custom detection rules"
            $result.detections = $detections
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
