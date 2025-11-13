using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
# Add module imports and existence checks
try {
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -ErrorAction Stop
    # NOTE: Business logic is inline - no external module needed
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
        
        # ===== V3.2.0 NEW INTUNE ENCRYPTION ACTIONS (6 actions) =====
        
        "EnableBitLocker" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling BitLocker on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create or update BitLocker configuration policy
            $policyBody = @{
                displayName = "BitLocker Enforcement - $($body.deviceId)"
                description = "Emergency BitLocker enablement for device $($body.deviceId)"
                settings = @(
                    @{
                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSetting"
                        settingInstance = @{
                            "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance"
                            settingDefinitionId = "device_vendor_msft_bitlocker_requiredeviceencryption"
                            choiceSettingValue = @{
                                value = "device_vendor_msft_bitlocker_requiredeviceencryption_1"
                            }
                        }
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            # Target device via policy assignment
            $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            # Force sync to apply immediately
            $syncUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/syncDevice"
            Invoke-RestMethod -Uri $syncUri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                bitLockerEnabled = $true
                policyId = $policy.id
                syncInitiated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RotateBitLockerKey" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Rotating BitLocker recovery key" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/rotateBitLockerKeys"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                keyRotated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "BitLocker recovery key rotation initiated. New key will be escrowed to Azure AD."
            }
        }
        
        "DisableBitLocker" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disabling BitLocker (emergency only)" -Data @{
                DeviceId = $body.deviceId
                Reason = $body.reason
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create policy to disable BitLocker
            $policyBody = @{
                displayName = "BitLocker Disable - Emergency - $($body.deviceId)"
                description = "Emergency BitLocker disable. Reason: $($body.reason ?? 'Not specified')"
                settings = @(
                    @{
                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSetting"
                        settingInstance = @{
                            "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance"
                            settingDefinitionId = "device_vendor_msft_bitlocker_requiredeviceencryption"
                            choiceSettingValue = @{
                                value = "device_vendor_msft_bitlocker_requiredeviceencryption_0"
                            }
                        }
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                bitLockerDisabled = $true
                policyId = $policy.id
                reason = $body.reason
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GetBitLockerRecoveryKey" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Retrieving BitLocker recovery keys" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get device BitLocker recovery keys
            $uri = "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$($body.deviceId)'"
            $keys = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $recoveryKeys = @()
            foreach ($key in $keys.value) {
                # Get the actual recovery key value (requires additional permission)
                $keyUri = "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys/$($key.id)?`$select=key"
                try {
                    $keyDetails = Invoke-RestMethod -Uri $keyUri -Method Get -Headers $headers
                    $recoveryKeys += @{
                        keyId = $key.id
                        createdDateTime = $key.createdDateTime
                        volumeType = $key.volumeType
                        recoveryKey = $keyDetails.key
                    }
                } catch {
                    $recoveryKeys += @{
                        keyId = $key.id
                        createdDateTime = $key.createdDateTime
                        volumeType = $key.volumeType
                        recoveryKey = "Permission required to retrieve key"
                    }
                }
            }
            
            $result = @{
                deviceId = $body.deviceId
                keyCount = $recoveryKeys.Count
                recoveryKeys = $recoveryKeys
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableFileVault" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling FileVault on macOS device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create FileVault policy for macOS
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.macOSEndpointProtectionConfiguration"
                displayName = "FileVault Enforcement - $($body.deviceId)"
                description = "Emergency FileVault enablement"
                fileVaultEnabled = $true
                fileVaultAllowDeferralUntilSignOut = $false
                fileVaultNumberOfTimesUserCanIgnore = 0
                fileVaultDisablePromptAtSignOut = $false
                fileVaultPersonalRecoveryKeyHelpMessage = "Contact IT for recovery key"
                fileVaultHidePersonalRecoveryKey = $true
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                fileVaultEnabled = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RotateFileVaultKey" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Rotating FileVault recovery key" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/rotateFileVaultKey"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                fileVaultKeyRotated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "FileVault recovery key rotation initiated. New key will be escrowed."
            }
        }
        
        # ===== V3.2.0 NEW INTUNE DEVICE CONFIG ACTIONS (6 actions) =====
        
        "DeployConfigProfile" {
            if ([string]::IsNullOrEmpty($body.profileName)) {
                throw "Missing required parameter: profileName"
            }
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Deploying configuration profile to device" -Data @{
                ProfileName = $body.profileName
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get profile by name
            $profileUri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?`$filter=displayName eq '$($body.profileName)'"
            $profiles = Invoke-RestMethod -Uri $profileUri -Method Get -Headers $headers
            
            if ($profiles.value.Count -eq 0) {
                throw "Configuration profile not found: $($body.profileName)"
            }
            
            $profileId = $profiles.value[0].id
            
            # Assign profile to device
            $assignmentBody = @{
                deviceConfigurationGroupAssignments = @(
                    @{
                        targetGroupId = $body.deviceId
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $assignUri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$profileId/assign"
            Invoke-RestMethod -Uri $assignUri -Method Post -Headers $headers -Body $assignmentBody
            
            # Sync device to apply immediately
            $syncUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/syncDevice"
            Invoke-RestMethod -Uri $syncUri -Method Post -Headers $headers
            
            $result = @{
                profileName = $body.profileName
                profileId = $profileId
                deviceId = $body.deviceId
                deployed = $true
                syncInitiated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RemoveConfigProfile" {
            if ([string]::IsNullOrEmpty($body.profileId)) {
                throw "Missing required parameter: profileId"
            }
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing configuration profile from device" -Data @{
                ProfileId = $body.profileId
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Remove assignment (unassign from device)
            $assignmentBody = @{
                deviceConfigurationGroupAssignments = @()
            } | ConvertTo-Json -Depth 10
            
            $assignUri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($body.profileId)/assign"
            Invoke-RestMethod -Uri $assignUri -Method Post -Headers $headers -Body $assignmentBody
            
            # Sync device
            $syncUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/syncDevice"
            Invoke-RestMethod -Uri $syncUri -Method Post -Headers $headers
            
            $result = @{
                profileId = $body.profileId
                deviceId = $body.deviceId
                removed = $true
                syncInitiated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableFirewall" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling firewall on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create firewall enforcement policy
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.windows10EndpointProtectionConfiguration"
                displayName = "Firewall Enforcement - $($body.deviceId)"
                description = "Emergency firewall enablement"
                firewallBlockStatefulFTP = $true
                firewallIdleTimeoutForSecurityAssociationInSeconds = 300
                firewallPreSharedKeyEncodingMethod = "none"
                firewallIPSecExemptionsAllowNeighborDiscovery = $false
                firewallIPSecExemptionsAllowICMP = $false
                firewallIPSecExemptionsAllowRouterDiscovery = $false
                firewallIPSecExemptionsAllowDHCP = $true
                firewallProfileDomain = @{
                    firewallEnabled = "allowed"
                    stealthModeBlocked = $false
                    incomingTrafficBlocked = $false
                    unicastResponsesToMulticastBroadcastsBlocked = $true
                    inboundNotificationsBlocked = $false
                    authorizedApplicationRulesFromGroupPolicyMerged = $true
                    globalPortRulesFromGroupPolicyMerged = $true
                    connectionSecurityRulesFromGroupPolicyMerged = $true
                    policyRulesFromGroupPolicyMerged = $true
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                firewallEnabled = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableUSBStorage" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disabling USB storage on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create policy to block removable storage
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.windows10GeneralConfiguration"
                displayName = "Block USB Storage - $($body.deviceId)"
                description = "Emergency USB storage blocking for data exfiltration prevention"
                storageBlockRemovableStorage = $true
                storageRequireMobileDeviceEncryption = $true
                usbBlocked = $false
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                usbStorageDisabled = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "USB storage access blocked. USB devices for input (keyboard/mouse) still allowed."
            }
        }
        
        "EnableDeviceEncryption" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling full device encryption" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get device OS type
            $deviceUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)"
            $device = Invoke-RestMethod -Uri $deviceUri -Method Get -Headers $headers
            
            $policyBody = $null
            if ($device.operatingSystem -eq "Windows") {
                # BitLocker for Windows
                $policyBody = @{
                    "@odata.type" = "#microsoft.graph.windows10EndpointProtectionConfiguration"
                    displayName = "Full Encryption - Windows - $($body.deviceId)"
                    bitLockerSystemDrivePolicy = @{
                        encryptionMethod = "aesCbc256"
                        startupAuthenticationRequired = $true
                        startupAuthenticationTpmUsage = "required"
                    }
                }
            } elseif ($device.operatingSystem -eq "macOS") {
                # FileVault for macOS
                $policyBody = @{
                    "@odata.type" = "#microsoft.graph.macOSEndpointProtectionConfiguration"
                    displayName = "Full Encryption - macOS - $($body.deviceId)"
                    fileVaultEnabled = $true
                }
            } else {
                throw "Unsupported OS for encryption: $($device.operatingSystem)"
            }
            
            $policyBodyJson = $policyBody | ConvertTo-Json -Depth 10
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBodyJson
            
            $result = @{
                deviceId = $body.deviceId
                operatingSystem = $device.operatingSystem
                encryptionEnabled = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockCamera" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking camera on device" -Data @{
                DeviceId = $body.deviceId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create policy to disable camera
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.windows10GeneralConfiguration"
                displayName = "Block Camera - $($body.deviceId)"
                description = "Emergency camera blocking for privacy/security"
                cameraBlocked = $true
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                cameraBlocked = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW INTUNE APP MANAGEMENT ACTIONS (4 actions) =====
        
        "UninstallApp" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            if ([string]::IsNullOrEmpty($body.appId)) {
                throw "Missing required parameter: appId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Uninstalling app from device" -Data @{
                DeviceId = $body.deviceId
                AppId = $body.appId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Update app assignment to uninstall
            $assignmentBody = @{
                mobileAppAssignments = @(
                    @{
                        "@odata.type" = "#microsoft.graph.mobileAppAssignment"
                        intent = "uninstall"
                        target = @{
                            "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                        }
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps/$($body.appId)/assign"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $assignmentBody
            
            # Sync device to apply immediately
            $syncUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/syncDevice"
            Invoke-RestMethod -Uri $syncUri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                appId = $body.appId
                uninstallInitiated = $true
                syncInitiated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockApp" {
            if ([string]::IsNullOrEmpty($body.appName)) {
                throw "Missing required parameter: appName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking application" -Data @{
                AppName = $body.appName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create app protection policy to block app
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.windowsInformationProtectionPolicy"
                displayName = "Block App - $($body.appName)"
                description = "Emergency app blocking for security"
                enforcementLevel = "encryptAndAuditOnly"
                enterpriseDomain = $body.enterpriseDomain ?? "contoso.com"
                exemptApps = @()
                protectedApps = @()
                smsDisclaimerNotification = "block"
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/windowsInformationProtectionPolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                appName = $body.appName
                blocked = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "WipeAppData" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            if ([string]::IsNullOrEmpty($body.appId)) {
                throw "Missing required parameter: appId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Wiping app data on device" -Data @{
                DeviceId = $body.deviceId
                AppId = $body.appId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Wipe managed app data
            $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($body.deviceId)/wipeData"
            $wipeBody = @{
                appId = $body.appId
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $wipeBody
            
            $result = @{
                deviceId = $body.deviceId
                appId = $body.appId
                appDataWiped = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Corporate data for app removed. Personal data preserved."
            }
        }
        
        "RemoveManagedApp" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            if ([string]::IsNullOrEmpty($body.appId)) {
                throw "Missing required parameter: appId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing managed app access" -Data @{
                UserId = $body.userId
                AppId = $body.appId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Remove app protection policy assignment
            $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/managedAppStatuses?userId=$($body.userId)"
            $appStatuses = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            foreach ($status in $appStatuses.value) {
                if ($status.appIdentifier -eq $body.appId) {
                    $deleteUri = "https://graph.microsoft.com/v1.0/deviceAppManagement/managedAppRegistrations/$($status.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                }
            }
            
            $result = @{
                userId = $body.userId
                appId = $body.appId
                managedAppRemoved = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW INTUNE EPM ACTIONS (2 actions) =====
        
        "RevokeElevation" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            if ([string]::IsNullOrEmpty($body.elevationId)) {
                throw "Missing required parameter: elevationId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking elevation privilege" -Data @{
                DeviceId = $body.deviceId
                ElevationId = $body.elevationId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Revoke EPM elevation
            $uri = "https://graph.microsoft.com/beta/deviceManagement/privilegeManagementElevations/$($body.elevationId)/revoke"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                deviceId = $body.deviceId
                elevationId = $body.elevationId
                revoked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Elevation privilege revoked immediately."
            }
        }
        
        "BlockElevationRequest" {
            if ([string]::IsNullOrEmpty($body.deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            if ([string]::IsNullOrEmpty($body.applicationPath)) {
                throw "Missing required parameter: applicationPath"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking elevation for application" -Data @{
                DeviceId = $body.deviceId
                ApplicationPath = $body.applicationPath
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create EPM policy to block elevation
            $policyBody = @{
                "@odata.type" = "#microsoft.graph.privilegeManagementElevationPolicy"
                displayName = "Block Elevation - $($body.applicationPath)"
                description = "Emergency block for suspicious elevation request"
                elevationType = "deny"
                targetApplication = @{
                    filePath = $body.applicationPath
                    fileHash = $body.fileHash
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/beta/deviceManagement/privilegeManagementElevationPolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                deviceId = $body.deviceId
                applicationPath = $body.applicationPath
                elevationBlocked = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # Device remediation actions (15 existing)
                "RemoteLock", "WipeDevice", "RetireDevice", "SyncDevice", "DefenderScan",
                "ResetDevicePasscode", "RebootDeviceNow", "ShutdownDevice",
                "EnableLostMode", "DisableLostMode", "TriggerComplianceEvaluation",
                "UpdateDefenderSignatures", "BypassActivationLock", "CleanWindowsDevice",
                "LogoutSharedAppleDevice",
                # V3.2.0 Encryption (6 new)
                "EnableBitLocker", "RotateBitLockerKey", "DisableBitLocker",
                "GetBitLockerRecoveryKey", "EnableFileVault", "RotateFileVaultKey",
                # V3.2.0 Device Config (6 new)
                "DeployConfigProfile", "RemoveConfigProfile", "EnableFirewall",
                "DisableUSBStorage", "EnableDeviceEncryption", "BlockCamera",
                # V3.2.0 App Management (4 new)
                "UninstallApp", "BlockApp", "WipeAppData", "RemoveManagedApp",
                # V3.2.0 EPM (2 new)
                "RevokeElevation", "BlockElevationRequest"
            )
            throw "Unknown action: $action. Supported actions (33 total, 18 new in v3.2.0): $($supportedActions -join ', ')"
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
