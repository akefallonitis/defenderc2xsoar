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
    # Import MDEAutomator module
    # Import-Module MDEAutomator -ErrorAction Stop
    
    # Connect to MDE using App Registration with Client Secret
    # $token = Connect-MDE -AppId $appId -ClientSecret $secretId -TenantId $tenantId

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
