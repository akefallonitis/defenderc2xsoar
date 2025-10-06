using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get parameters from query string or body
$action = $Request.Query.action
$tenantId = $Request.Query.tenantId
$deviceFilter = $Request.Query.deviceFilter
$deviceIds = $Request.Query.deviceIds
$scriptName = $Request.Query.scriptName
$filePath = $Request.Query.filePath
$fileHash = $Request.Query.fileHash

if ($Request.Body) {
    $action = $Request.Body.action ?? $action
    $tenantId = $Request.Body.tenantId ?? $tenantId
    $deviceFilter = $Request.Body.deviceFilter ?? $deviceFilter
    $deviceIds = $Request.Body.deviceIds ?? $deviceIds
    $scriptName = $Request.Body.scriptName ?? $scriptName
    $filePath = $Request.Body.filePath ?? $filePath
    $fileHash = $Request.Body.fileHash ?? $fileHash
}

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate required parameters
if (-not $action -or -not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters: action and tenantId are required"
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
        action = $action
        status = "Initiated"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        message = "Action '$action' initiated successfully"
    }

    # Parse device IDs if provided
    $deviceIdList = if ($deviceIds) { $deviceIds.Split(',').Trim() } else { @() }

    # Execute action based on type
    switch ($action) {
        "Isolate Device" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for isolation"
            }
            $response = Invoke-DeviceIsolation -Token $token -DeviceIds $deviceIdList -Comment "Isolated via Azure Function" -IsolationType "Full"
            $result.details = "Device isolation initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Unisolate Device" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for unisolation"
            }
            $response = Invoke-DeviceUnisolation -Token $token -DeviceIds $deviceIdList -Comment "Unisolated via Azure Function"
            $result.details = "Device unisolation initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Restrict App Execution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for app restriction"
            }
            $response = Invoke-RestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment "Restricted via Azure Function"
            $result.details = "App execution restriction initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Unrestrict App Execution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for app unrestriction"
            }
            $response = Invoke-UnrestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment "Unrestricted via Azure Function"
            $result.details = "App execution unrestriction initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Collect Investigation Package" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for investigation package collection"
            }
            $response = Invoke-CollectInvestigationPackage -Token $token -DeviceIds $deviceIdList -Comment "Collected via Azure Function"
            $result.details = "Investigation package collection initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Run Antivirus Scan" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for antivirus scan"
            }
            $response = Invoke-AntivirusScan -Token $token -DeviceIds $deviceIdList -ScanType "Full" -Comment "Scan via Azure Function"
            $result.details = "Antivirus scan initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Stop & Quarantine File" {
            if (-not $fileHash) {
                throw "File hash required for stop and quarantine"
            }
            $response = Invoke-StopAndQuarantineFile -Token $token -Sha1 $fileHash -Comment "Quarantined via Azure Function"
            $result.details = "Stop and quarantine initiated for file hash $fileHash"
            $result.actionId = $response.id
        }
        "Get Devices" {
            $devices = Get-AllDevices -Token $token -Filter $deviceFilter
            $result.details = "Retrieved $($devices.Count) device(s)"
            $result.devices = $devices | Select-Object -First 100
        }
        "Get Device Info" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for device info"
            }
            $deviceInfo = Get-DeviceInfo -Token $token -DeviceId $deviceIdList[0]
            $result.details = "Retrieved device information"
            $result.device = $deviceInfo
        }
        "Get Action Status" {
            $actionId = $Request.Query.actionId ?? $Request.Body.actionId
            if (-not $actionId) {
                throw "Action ID required for status check"
            }
            $actionStatus = Get-MachineActionStatus -Token $token -ActionId $actionId
            $result.details = "Retrieved action status"
            $result.actionStatus = $actionStatus
        }
        "Get All Actions" {
            $filter = $Request.Query.filter ?? $Request.Body.filter
            $actions = Get-AllMachineActions -Token $token -Filter $filter
            $result.details = "Retrieved $($actions.Count) machine actions"
            $result.actions = $actions | Select-Object -First 100
        }
        "Cancel Action" {
            $actionId = $Request.Query.actionId ?? $Request.Body.actionId
            if (-not $actionId) {
                throw "Action ID required for cancellation"
            }
            $cancelResult = Stop-MachineAction -Token $token -ActionId $actionId -Comment "Cancelled via Azure Function"
            $result.details = "Cancelled action $actionId"
            $result.cancelResult = $cancelResult
        }
        default {
            $result.status = "Unknown"
            $result.message = "Unknown action type: $action"
        }
    }

    # Return success response
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
            details = $_.Exception.ToString()
        } | ConvertTo-Json
    })
}
