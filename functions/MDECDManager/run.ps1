using namespace System.Net

# Custom Detection Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDECDManager function processed a request."

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

    switch ($action) {
        "List All Detections" {
            $detections = Get-CustomDetections -Token $token
            $result.details = "Retrieved $($detections.Count) custom detection rules"
            $result.detections = $detections
        }
        "Create Detection" {
            if ($detectionName -and $detectionQuery) {
                # Note: Creating custom detections requires Graph API POST calls
                # The current module doesn't have a create function implemented
                # This would need to be added to MDEDetection.psm1
                $result.details = "Create detection functionality requires additional implementation"
                $result.detectionName = $detectionName
                $result.note = "Please add New-CustomDetection function to MDEDetection.psm1"
            } else {
                throw "Detection name and query are required for creating a detection"
            }
        }
        "Update Detection" {
            if ($detectionName -and $detectionQuery) {
                # Note: Updating custom detections requires Graph API PATCH calls
                # This would need to be added to MDEDetection.psm1
                $result.details = "Update detection functionality requires additional implementation"
                $result.note = "Please add Update-CustomDetection function to MDEDetection.psm1"
            } else {
                throw "Detection name and query are required for updating a detection"
            }
        }
        "Delete Detection" {
            if ($detectionName) {
                # Note: Deleting custom detections requires Graph API DELETE calls
                # This would need to be added to MDEDetection.psm1
                $result.details = "Delete detection functionality requires additional implementation"
                $result.note = "Please add Remove-CustomDetection function to MDEDetection.psm1"
            } else {
                throw "Detection name is required for deleting a detection"
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
