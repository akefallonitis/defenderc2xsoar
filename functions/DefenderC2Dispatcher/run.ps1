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
$scanType = $Request.Query.scanType
$isolationType = $Request.Query.isolationType
$comment = $Request.Query.comment
$actionId = $Request.Query.actionId

if ($Request.Body) {
    if ($Request.Body.action) { $action = $Request.Body.action }
    if ($Request.Body.tenantId) { $tenantId = $Request.Body.tenantId }
    if ($Request.Body.deviceFilter) { $deviceFilter = $Request.Body.deviceFilter }
    if ($Request.Body.deviceIds) { $deviceIds = $Request.Body.deviceIds }
    if ($Request.Body.scriptName) { $scriptName = $Request.Body.scriptName }
    if ($Request.Body.filePath) { $filePath = $Request.Body.filePath }
    if ($Request.Body.fileHash) { $fileHash = $Request.Body.fileHash }
    if ($Request.Body.scanType) { $scanType = $Request.Body.scanType }
    if ($Request.Body.isolationType) { $isolationType = $Request.Body.isolationType }
    if ($Request.Body.comment) { $comment = $Request.Body.comment }
    if ($Request.Body.actionId) { $actionId = $Request.Body.actionId }
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
            $isoType = if ($isolationType) { $isolationType } else { "Full" }
            $commentText = if ($comment) { $comment } else { "Isolated via Azure Function" }
            $response = Invoke-DeviceIsolation -Token $token -DeviceIds $deviceIdList -Comment $commentText -IsolationType $isoType
            $result.details = "Device isolation ($isoType) initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Unisolate Device" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for unisolation"
            }
            $commentText = if ($comment) { $comment } else { "Unisolated via Azure Function" }
            $response = Invoke-DeviceUnisolation -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.details = "Device unisolation initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Restrict App Execution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for app restriction"
            }
            $commentText = if ($comment) { $comment } else { "Restricted via Azure Function" }
            $response = Invoke-RestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.details = "App execution restriction initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Unrestrict App Execution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for app unrestriction"
            }
            $commentText = if ($comment) { $comment } else { "Unrestricted via Azure Function" }
            $response = Invoke-UnrestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.details = "App execution unrestriction initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Collect Investigation Package" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for investigation package collection"
            }
            $commentText = if ($comment) { $comment } else { "Collected via Azure Function" }
            $response = Invoke-CollectInvestigationPackage -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.details = "Investigation package collection initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Run Antivirus Scan" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for antivirus scan"
            }
            $scanTypeValue = if ($scanType) { $scanType } else { "Quick" }
            $commentText = if ($comment) { $comment } else { "Scan via Azure Function" }
            $response = Invoke-AntivirusScan -Token $token -DeviceIds $deviceIdList -ScanType $scanTypeValue -Comment $commentText
            $result.details = "Antivirus scan ($scanTypeValue) initiated for $($deviceIdList.Count) device(s)"
            $result.actionIds = $response | ForEach-Object { $_.id }
        }
        "Stop & Quarantine File" {
            if (-not $fileHash) {
                throw "File hash required for stop and quarantine"
            }
            $commentText = if ($comment) { $comment } else { "Quarantined via Azure Function" }
            $response = Invoke-StopAndQuarantineFile -Token $token -Sha1 $fileHash -Comment $commentText
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
            if (-not $actionId) {
                throw "Action ID required for status check"
            }
            $actionStatus = Get-MachineActionStatus -Token $token -ActionId $actionId
            $result.details = "Retrieved action status"
            $result.actionStatus = $actionStatus
        }
        "Get All Actions" {
            $filter = $Request.Query.filter
            if ($Request.Body.filter) { $filter = $Request.Body.filter }
            $actions = Get-AllMachineActions -Token $token -Filter $filter
            $result.details = "Retrieved $($actions.Count) machine actions"
            $result.actions = $actions | Select-Object -First 100
        }
        "Cancel Action" {
            if (-not $actionId) {
                throw "Action ID required for cancellation"
            }
            $commentText = if ($comment) { $comment } else { "Cancelled via Azure Function" }
            $cancelResult = Stop-MachineAction -Token $token -ActionId $actionId -Comment $commentText
            $result.details = "Cancelled action $actionId"
            $result.cancelResult = $cancelResult
        }
        "Offboard Device" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for offboarding"
            }
            $commentText = if ($comment) { $comment } else { "Offboarded via Azure Function" }
            $response = Invoke-DeviceOffboard -Token $token -DeviceId $deviceIdList[0] -Comment $commentText
            $result.details = "Device offboarding initiated for device"
            $result.actionId = $response.id
        }
        "Start Investigation" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for automated investigation"
            }
            $commentText = if ($comment) { $comment } else { "Investigation via Azure Function" }
            $response = Start-AutomatedInvestigation -Token $token -DeviceId $deviceIdList[0] -Comment $commentText
            $result.details = "Automated investigation started"
            $result.investigationId = $response.id
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
