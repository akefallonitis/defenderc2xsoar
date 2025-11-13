using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
# Add module imports and existence checks
try {
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/Intune.psm1" -ErrorAction Stop
} catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{ error = "Required module import failed: $($_.Exception.Message)" } | ConvertTo-Json
    })
    return
}

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
        
        #region Enhanced Device Management Actions (Graph v1.0 - Stable)
        
        "ResetDevicePasscode" {
            # Reset device passcode (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Resetting device passcode" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/resetPasscode"
            $resetResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "ResetPasscode"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RebootDeviceNow" {
            # Reboot device immediately (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Rebooting device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/rebootNow"
            $rebootResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "RebootNow"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ShutdownDevice" {
            # Shutdown device (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Shutting down device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/shutDown"
            $shutdownResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "ShutDown"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableLostMode" {
            # Enable lost mode on device (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Enabling lost mode on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Prepare lost mode parameters
            $lostModeBody = @{
                message = if ($body.message) { $body.message } else { "This device has been reported as lost. Please contact IT." }
                phoneNumber = if ($body.phoneNumber) { $body.phoneNumber } else { "" }
                footer = if ($body.footer) { $body.footer } else { "IT Department" }
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/enableLostMode"
            $lostModeResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $lostModeBody
            
            $result = @{
                deviceId = $body.deviceId
                action = "EnableLostMode"
                status = "initiated"
                message = if ($body.message) { $body.message } else { "This device has been reported as lost. Please contact IT." }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableLostMode" {
            # Disable lost mode on device (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling lost mode on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/disableLostMode"
            $disableResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "DisableLostMode"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "TriggerComplianceEvaluation" {
            # Trigger device compliance policy evaluation (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Triggering compliance evaluation" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/reevaluateCompliance"
            $evalResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "TriggerComplianceEvaluation"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "UpdateDefenderSignatures" {
            # Update Windows Defender signatures (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Updating Defender signatures" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/windowsDefenderUpdateSignatures"
            $updateResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "UpdateDefenderSignatures"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BypassActivationLock" {
            # Bypass activation lock on iOS device (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Bypassing activation lock" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/bypassActivationLock"
            $bypassResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "BypassActivationLock"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "CleanWindowsDevice" {
            # Clean Windows device (remove apps and settings but keep enrollment) (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Cleaning Windows device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $cleanBody = @{
                keepUserData = if ($body.keepUserData) { [bool]$body.keepUserData } else { $false }
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/cleanWindowsDevice"
            $cleanResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $cleanBody
            
            $result = @{
                deviceId = $body.deviceId
                action = "CleanWindowsDevice"
                keepUserData = if ($body.keepUserData) { [bool]$body.keepUserData } else { $false }
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "LogoutSharedAppleDevice" {
            # Logout current user from shared iPad (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Logging out shared Apple device user" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/logoutSharedAppleDeviceActiveUser"
            $logoutResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                action = "LogoutSharedAppleDeviceUser"
                status = "initiated"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # Device remediation actions
                "RemoteLock", "WipeDevice", "RetireDevice", "SyncDevice", "DefenderScan",
                # Enhanced device management
                "ResetDevicePasscode", "RebootDeviceNow", "ShutdownDevice",
                "EnableLostMode", "DisableLostMode", "TriggerComplianceEvaluation",
                "UpdateDefenderSignatures", "BypassActivationLock", "CleanWindowsDevice",
                "LogoutSharedAppleDevice"
            )
            throw "Unknown action: $action. Supported actions (15 remediation-focused): $($supportedActions -join ', ')"
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
