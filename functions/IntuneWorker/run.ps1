using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../DefenderXDRC2XSOAR/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../DefenderXDRC2XSOAR/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../DefenderXDRC2XSOAR/LoggingHelper.psm1" -Force
Import-Module "$PSScriptRoot/../DefenderXDRC2XSOAR/Intune.psm1" -Force

# Extract parameters from request
$action = $Request.Body.action
$tenantId = $Request.Body.tenantId
$body = $Request.Body

Write-XDRLog -Level "Info" -Message "IntuneWorker received request" -Data @{
    Action = $action
    TenantId = $tenantId
}

try {
    # Validate required parameters
    if ([string]::IsNullOrEmpty($action)) {
        throw "Missing required parameter: action"
    }
    
    if (-not (Test-TenantId -TenantId $tenantId)) {
        throw "Invalid or missing tenantId"
    }

    # Authenticate to Microsoft Graph
    $tokenParams = @{
        TenantId = $tenantId
        Service = "Graph"
    }
    $token = Get-OAuthToken @tokenParams
    
    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to obtain authentication token"
    }

    # Execute action
    $result = $null
    
    switch ($action) {
        "RemoteLock" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Remote locking device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $lockParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            $lockResult = Invoke-IntuneRemoteLock @lockParams
            $result = @{
                deviceId = $body.deviceId
                action = "RemoteLock"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "WipeDevice" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Wiping device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $wipeParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            if ($body.keepEnrollmentData) {
                $wipeParams.KeepEnrollmentData = [bool]$body.keepEnrollmentData
            }
            if ($body.keepUserData) {
                $wipeParams.KeepUserData = [bool]$body.keepUserData
            }
            
            $wipeResult = Invoke-IntuneWipeDevice @wipeParams
            $result = @{
                deviceId = $body.deviceId
                action = "WipeDevice"
                status = "initiated"
                keepEnrollmentData = $wipeParams.ContainsKey('KeepEnrollmentData') ? $wipeParams.KeepEnrollmentData : $false
                keepUserData = $wipeParams.ContainsKey('KeepUserData') ? $wipeParams.KeepUserData : $false
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RetireDevice" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Retiring device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $retireParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            $retireResult = Invoke-IntuneRetireDevice @retireParams
            $result = @{
                deviceId = $body.deviceId
                action = "RetireDevice"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "SyncDevice" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Syncing device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $syncParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            $syncResult = Invoke-IntuneSyncDevice @syncParams
            $result = @{
                deviceId = $body.deviceId
                action = "SyncDevice"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DefenderScan" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Starting Defender scan" -Data @{
                DeviceId = $body.deviceId
                ScanType = if ($body.scanType) { $body.scanType } else { "Quick" }
            }
            
            $scanParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            if ($body.scanType) {
                $scanParams.ScanType = $body.scanType
            }
            
            $scanResult = Start-IntuneDefenderScan @scanParams
            $result = @{
                deviceId = $body.deviceId
                action = "DefenderScan"
                scanType = if ($scanParams.ContainsKey('ScanType')) { $scanParams.ScanType } else { "Quick" }
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GetManagedDevices" {
            Write-XDRLog -Level "Info" -Message "Getting managed devices"
            $deviceParams = @{
                Token = $token
            }
            
            if ($body.filter) {
                $deviceParams.Filter = $body.filter
            }
            if ($body.top) {
                $deviceParams.Top = [int]$body.top
            }
            
            $devices = Get-IntuneManagedDevices @deviceParams
            $result = @{
                count = $devices.Count
                devices = $devices
            }
        }
        
        "GetDeviceCompliance" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting device compliance" -Data @{
                DeviceId = $body.deviceId
            }
            
            $complianceParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            $compliance = Get-IntuneDeviceCompliance @complianceParams
            $result = @{
                deviceId = $body.deviceId
                compliance = $compliance
            }
        }
        
        "GetDeviceConfiguration" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting device configuration" -Data @{
                DeviceId = $body.deviceId
            }
            
            $configParams = @{
                Token = $token
                DeviceId = $body.deviceId
            }
            
            $configuration = Get-IntuneDeviceConfiguration @configParams
            $result = @{
                deviceId = $body.deviceId
                configuration = $configuration
            }
        }
        
        default {
            throw "Unknown action: $action. Supported actions: RemoteLock, WipeDevice, RetireDevice, SyncDevice, DefenderScan, GetManagedDevices, GetDeviceCompliance, GetDeviceConfiguration"
        }
    }

    # Build success response
    $responseBody = @{
        success = $true
        action = $action
        tenantId = $tenantId
        result = $result
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    Write-XDRLog -Level "Info" -Message "IntuneWorker completed successfully" -Data @{
        Action = $action
        Success = $true
    }

    # Return direct HTTP response for workbook compatibility
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($responseBody | ConvertTo-Json -Depth 10 -Compress)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })

} catch {
    $errorMessage = $_.Exception.Message
    Write-XDRLog -Level "Error" -Message "IntuneWorker failed" -Data @{
        Action = $action
        Error = $errorMessage
    }

    $responseBody = @{
        success = $false
        action = $action
        tenantId = $tenantId
        error = $errorMessage
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($responseBody | ConvertTo-Json -Depth 10 -Compress)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
}
