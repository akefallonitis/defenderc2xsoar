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
    # Import MDEAutomator module (you'll need to include this in your function app)
    # Import-Module MDEAutomator -ErrorAction Stop

    # Connect to MDE using App Registration with Client Secret
    # In production, use Connect-MDE with app credentials from environment variables
    # $token = Connect-MDE -AppId $appId -ClientSecret $secretId -TenantId $tenantId

    # For demonstration, simulate the response
    $result = @{
        action = $action
        status = "Initiated"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        message = "Action '$action' initiated successfully"
    }

    # Execute action based on type
    switch ($action) {
        "Isolate Device" {
            # Invoke-MachineIsolation -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "Device isolation initiated for $deviceIds"
        }
        "Unisolate Device" {
            # Undo-MachineIsolation -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "Device unisolation initiated for $deviceIds"
        }
        "Restrict App Execution" {
            # Invoke-RestrictAppExecution -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "App execution restriction initiated for $deviceIds"
        }
        "Unrestrict App Execution" {
            # Undo-RestrictAppExecution -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "App execution unrestriction initiated for $deviceIds"
        }
        "Collect Investigation Package" {
            # Invoke-CollectInvestigationPackage -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "Investigation package collection initiated for $deviceIds"
        }
        "Run Antivirus Scan" {
            # Invoke-FullDiskScan -token $token -DeviceIds $deviceIds.Split(',')
            $result.details = "Antivirus scan initiated for $deviceIds"
        }
        "Stop & Quarantine File" {
            # Invoke-StopAndQuarantineFile -token $token -Sha1 $fileHash
            $result.details = "Stop and quarantine initiated for file hash $fileHash"
        }
        "Run Live Response Script" {
            # Invoke-LRScript -token $token -DeviceIds $deviceIds.Split(',') -scriptName $scriptName
            $result.details = "Live response script '$scriptName' initiated for $deviceIds"
        }
        "Get File" {
            # Invoke-GetFile -token $token -filePath $filePath -DeviceIds $deviceIds.Split(',')
            $result.details = "File retrieval initiated from path '$filePath' on $deviceIds"
        }
        "Put File" {
            # Invoke-PutFile -token $token -fileName $scriptName -DeviceIds $deviceIds.Split(',')
            $result.details = "File push initiated for '$scriptName' to $deviceIds"
        }
        "GetActions" {
            # $actions = Get-Actions -token $token
            $result.details = "Retrieved machine actions"
            $result.actions = @() # Would contain actual actions
        }
        "CancelAllActions" {
            # Undo-Actions -token $token
            $result.details = "All pending actions cancelled"
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
