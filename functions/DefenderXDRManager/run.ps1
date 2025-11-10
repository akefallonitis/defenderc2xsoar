using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "DefenderXDRManager: Processing XDR action request"

# Get parameters from query string or body
$action = $Request.Query.action
$tenantId = $Request.Query.tenantId
$service = $Request.Query.service

if ($Request.Body) {
    if ($Request.Body.action) { $action = $Request.Body.action }
    if ($Request.Body.tenantId) { $tenantId = $Request.Body.tenantId }
    if ($Request.Body.service) { $service = $Request.Body.service }
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

# Validate environment variables
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
    $result = @{
        action = $action
        service = $service
        status = "Initiated"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        message = "XDR action '$action' initiated successfully"
    }

    # Determine which service and get appropriate token
    switch -Wildcard ($service) {
        "MDO*" {
            # Email Remediation actions - requires Graph API
            $graphToken = Get-GraphToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId
            
            switch ($action) {
                "Soft Delete Email" {
                    $networkMessageId = if ($Request.Body.networkMessageId) { $Request.Body.networkMessageId } else { $Request.Query.networkMessageId }
                    $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
                    
                    if (-not $networkMessageId -or -not $recipientEmail) {
                        throw "networkMessageId and recipientEmail are required"
                    }
                    
                    $response = Invoke-EmailRemediation -Token $graphToken -Action "softDelete" -NetworkMessageId $networkMessageId -RecipientEmailAddress $recipientEmail
                    $result.details = "Soft delete email initiated"
                    $result.response = $response
                }
                "Hard Delete Email" {
                    $networkMessageId = if ($Request.Body.networkMessageId) { $Request.Body.networkMessageId } else { $Request.Query.networkMessageId }
                    $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
                    
                    if (-not $networkMessageId -or -not $recipientEmail) {
                        throw "networkMessageId and recipientEmail are required"
                    }
                    
                    $response = Invoke-EmailRemediation -Token $graphToken -Action "hardDelete" -NetworkMessageId $networkMessageId -RecipientEmailAddress $recipientEmail
                    $result.details = "Hard delete email initiated"
                    $result.response = $response
                }
                "Move Email to Junk" {
                    $networkMessageId = if ($Request.Body.networkMessageId) { $Request.Body.networkMessageId } else { $Request.Query.networkMessageId }
                    $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
                    
                    if (-not $networkMessageId -or -not $recipientEmail) {
                        throw "networkMessageId and recipientEmail are required"
                    }
                    
                    $response = Invoke-EmailRemediation -Token $graphToken -Action "moveToJunk" -NetworkMessageId $networkMessageId -RecipientEmailAddress $recipientEmail
                    $result.details = "Move to junk initiated"
                    $result.response = $response
                }
                "Move Email to Inbox" {
                    $networkMessageId = if ($Request.Body.networkMessageId) { $Request.Body.networkMessageId } else { $Request.Query.networkMessageId }
                    $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
                    
                    if (-not $networkMessageId -or -not $recipientEmail) {
                        throw "networkMessageId and recipientEmail are required"
                    }
                    
                    $response = Invoke-EmailRemediation -Token $graphToken -Action "moveToInbox" -NetworkMessageId $networkMessageId -RecipientEmailAddress $recipientEmail
                    $result.details = "Move to inbox initiated"
                    $result.response = $response
                }
                "Submit Email Threat" {
                    $category = if ($Request.Body.category) { $Request.Body.category } else { $Request.Query.category }
                    $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
                    $messageUrl = if ($Request.Body.messageUrl) { $Request.Body.messageUrl } else { $Request.Query.messageUrl }
                    
                    if (-not $category -or -not $recipientEmail -or -not $messageUrl) {
                        throw "category, recipientEmail, and messageUrl are required"
                    }
                    
                    $response = Submit-EmailThreat -Token $graphToken -Category $category -RecipientEmailAddress $recipientEmail -MessageUrl $messageUrl
                    $result.details = "Email threat submitted"
                    $result.response = $response
                }
                "Submit URL Threat" {
                    $category = if ($Request.Body.category) { $Request.Body.category } else { $Request.Query.category }
                    $url = if ($Request.Body.url) { $Request.Body.url } else { $Request.Query.url }
                    
                    if (-not $category -or -not $url) {
                        throw "category and url are required"
                    }
                    
                    $response = Submit-URLThreat -Token $graphToken -Category $category -Url $url
                    $result.details = "URL threat submitted"
                    $result.response = $response
                }
                "Remove Mail Forwarding" {
                    $userId = if ($Request.Body.userId) { $Request.Body.userId } else { $Request.Query.userId }
                    
                    if (-not $userId) {
                        throw "userId is required"
                    }
                    
                    $response = Remove-MailForwardingRules -Token $graphToken -UserId $userId
                    $result.details = "Mail forwarding rules removed"
                    $result.response = $response
                }
                default {
                    throw "Unknown MDO action: $action"
                }
            }
        }
        "EntraID*" {
            # Identity & Access actions - requires Graph API
            $graphToken = Get-GraphToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId
            
            switch ($action) {
                "Disable User" {
                    $userId = if ($Request.Body.userId) { $Request.Body.userId } else { $Request.Query.userId }
                    
                    if (-not $userId) {
                        throw "userId is required"
                    }
                    
                    $response = Set-UserAccountStatus -Token $graphToken -UserId $userId -Enabled $false
                    $result.details = "User disabled: $userId"
                    $result.response = $response
                }
                "Enable User" {
                    $userId = if ($Request.Body.userId) { $Request.Body.userId } else { $Request.Query.userId }
                    
                    if (-not $userId) {
                        throw "userId is required"
                    }
                    
                    $response = Set-UserAccountStatus -Token $graphToken -UserId $userId -Enabled $true
                    $result.details = "User enabled: $userId"
                    $result.response = $response
                }
                "Reset User Password" {
                    $userId = if ($Request.Body.userId) { $Request.Body.userId } else { $Request.Query.userId }
                    $newPassword = if ($Request.Body.newPassword) { $Request.Body.newPassword } else { $Request.Query.newPassword }
                    $forceChange = if ($Request.Body.forceChange -ne $null) { $Request.Body.forceChange } else { $true }
                    
                    if (-not $userId) {
                        throw "userId is required"
                    }
                    
                    # Generate random password if not provided
                    if (-not $newPassword) {
                        $newPassword = "TempP@ss$(Get-Random -Minimum 1000 -Maximum 9999)!"
                    }
                    
                    $response = Reset-UserPassword -Token $graphToken -UserId $userId -NewPassword $newPassword -ForceChangeNextSignIn $forceChange
                    $result.details = "Password reset for user: $userId"
                    $result.temporaryPassword = $newPassword
                    $result.response = $response
                }
                "Confirm User Compromised" {
                    $userIds = if ($Request.Body.userIds) { $Request.Body.userIds } else { $Request.Query.userIds }
                    
                    if (-not $userIds) {
                        throw "userIds is required"
                    }
                    
                    # Handle comma-separated string
                    if ($userIds -is [string]) {
                        $userIds = $userIds.Split(',').Trim()
                    }
                    
                    $response = Confirm-UserCompromised -Token $graphToken -UserIds $userIds
                    $result.details = "Users confirmed as compromised"
                    $result.response = $response
                }
                "Dismiss User Risk" {
                    $userIds = if ($Request.Body.userIds) { $Request.Body.userIds } else { $Request.Query.userIds }
                    
                    if (-not $userIds) {
                        throw "userIds is required"
                    }
                    
                    # Handle comma-separated string
                    if ($userIds -is [string]) {
                        $userIds = $userIds.Split(',').Trim()
                    }
                    
                    $response = Dismiss-UserRisk -Token $graphToken -UserIds $userIds
                    $result.details = "User risk dismissed"
                    $result.response = $response
                }
                "Revoke User Sessions" {
                    $userId = if ($Request.Body.userId) { $Request.Body.userId } else { $Request.Query.userId }
                    
                    if (-not $userId) {
                        throw "userId is required"
                    }
                    
                    $response = Revoke-UserSessions -Token $graphToken -UserId $userId
                    $result.details = "User sessions revoked: $userId"
                    $result.response = $response
                }
                "Get Risk Detections" {
                    $filter = if ($Request.Body.filter) { $Request.Body.filter } else { $Request.Query.filter }
                    $top = if ($Request.Body.top) { $Request.Body.top } else { if ($Request.Query.top) { $Request.Query.top } else { 50 } }
                    
                    $response = Get-UserRiskDetections -Token $graphToken -Filter $filter -Top $top
                    $result.details = "Risk detections retrieved"
                    $result.detections = $response
                }
                default {
                    throw "Unknown Entra ID action: $action"
                }
            }
        }
        "ConditionalAccess*" {
            # Conditional Access actions - requires Graph API
            $graphToken = Get-GraphToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId
            
            switch ($action) {
                "Create Named Location" {
                    $displayName = if ($Request.Body.displayName) { $Request.Body.displayName } else { $Request.Query.displayName }
                    $ipRanges = if ($Request.Body.ipRanges) { $Request.Body.ipRanges } else { $Request.Query.ipRanges }
                    $isTrusted = if ($Request.Body.isTrusted -ne $null) { $Request.Body.isTrusted } else { $false }
                    
                    if (-not $displayName -or -not $ipRanges) {
                        throw "displayName and ipRanges are required"
                    }
                    
                    # Handle comma-separated string
                    if ($ipRanges -is [string]) {
                        $ipRanges = $ipRanges.Split(',').Trim()
                    }
                    
                    $response = New-NamedLocation -Token $graphToken -DisplayName $displayName -IpRanges $ipRanges -IsTrusted $isTrusted
                    $result.details = "Named location created: $displayName"
                    $result.response = $response
                }
                "Update Named Location" {
                    $locationId = if ($Request.Body.locationId) { $Request.Body.locationId } else { $Request.Query.locationId }
                    $displayName = if ($Request.Body.displayName) { $Request.Body.displayName } else { $Request.Query.displayName }
                    $ipRanges = if ($Request.Body.ipRanges) { $Request.Body.ipRanges } else { $Request.Query.ipRanges }
                    $isTrusted = if ($Request.Body.isTrusted -ne $null) { $Request.Body.isTrusted } else { $null }
                    
                    if (-not $locationId) {
                        throw "locationId is required"
                    }
                    
                    # Handle comma-separated string for IP ranges
                    if ($ipRanges -and $ipRanges -is [string]) {
                        $ipRanges = $ipRanges.Split(',').Trim()
                    }
                    
                    $response = Update-NamedLocation -Token $graphToken -LocationId $locationId -DisplayName $displayName -IpRanges $ipRanges -IsTrusted $isTrusted
                    $result.details = "Named location updated: $locationId"
                    $result.response = $response
                }
                "Create Sign-In Risk Policy" {
                    $displayName = if ($Request.Body.displayName) { $Request.Body.displayName } else { $Request.Query.displayName }
                    $riskLevels = if ($Request.Body.riskLevels) { $Request.Body.riskLevels } else { @("high", "medium") }
                    $grantControls = if ($Request.Body.grantControls) { $Request.Body.grantControls } else { @("mfa") }
                    
                    if (-not $displayName) {
                        throw "displayName is required"
                    }
                    
                    $response = New-SignInRiskPolicy -Token $graphToken -DisplayName $displayName -RiskLevels $riskLevels -GrantControls $grantControls
                    $result.details = "Sign-in risk policy created: $displayName"
                    $result.response = $response
                }
                "Create User Risk Policy" {
                    $displayName = if ($Request.Body.displayName) { $Request.Body.displayName } else { $Request.Query.displayName }
                    $riskLevels = if ($Request.Body.riskLevels) { $Request.Body.riskLevels } else { @("high") }
                    $requirePasswordChange = if ($Request.Body.requirePasswordChange -ne $null) { $Request.Body.requirePasswordChange } else { $true }
                    
                    if (-not $displayName) {
                        throw "displayName is required"
                    }
                    
                    $response = New-UserRiskPolicy -Token $graphToken -DisplayName $displayName -RiskLevels $riskLevels -RequirePasswordChange $requirePasswordChange
                    $result.details = "User risk policy created: $displayName"
                    $result.response = $response
                }
                "Get Named Locations" {
                    $response = Get-NamedLocations -Token $graphToken
                    $result.details = "Named locations retrieved"
                    $result.locations = $response
                }
                default {
                    throw "Unknown Conditional Access action: $action"
                }
            }
        }
        "Intune*" {
            # Intune Device Management actions - requires Graph API
            $graphToken = Get-GraphToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId
            
            switch ($action) {
                "Remote Lock Device" {
                    $deviceId = if ($Request.Body.deviceId) { $Request.Body.deviceId } else { $Request.Query.deviceId }
                    
                    if (-not $deviceId) {
                        throw "deviceId is required"
                    }
                    
                    $response = Invoke-IntuneDeviceRemoteLock -Token $graphToken -DeviceId $deviceId
                    $result.details = "Remote lock initiated for device: $deviceId"
                    $result.response = $response
                }
                "Wipe Device" {
                    $deviceId = if ($Request.Body.deviceId) { $Request.Body.deviceId } else { $Request.Query.deviceId }
                    $keepEnrollmentData = if ($Request.Body.keepEnrollmentData -ne $null) { $Request.Body.keepEnrollmentData } else { $false }
                    $keepUserData = if ($Request.Body.keepUserData -ne $null) { $Request.Body.keepUserData } else { $false }
                    
                    if (-not $deviceId) {
                        throw "deviceId is required"
                    }
                    
                    $response = Invoke-IntuneDeviceWipe -Token $graphToken -DeviceId $deviceId -KeepEnrollmentData $keepEnrollmentData -KeepUserData $keepUserData
                    $result.details = "Device wipe initiated: $deviceId"
                    $result.response = $response
                }
                "Retire Device" {
                    $deviceId = if ($Request.Body.deviceId) { $Request.Body.deviceId } else { $Request.Query.deviceId }
                    
                    if (-not $deviceId) {
                        throw "deviceId is required"
                    }
                    
                    $response = Invoke-IntuneDeviceRetire -Token $graphToken -DeviceId $deviceId
                    $result.details = "Device retire initiated: $deviceId"
                    $result.response = $response
                }
                "Sync Device" {
                    $deviceId = if ($Request.Body.deviceId) { $Request.Body.deviceId } else { $Request.Query.deviceId }
                    
                    if (-not $deviceId) {
                        throw "deviceId is required"
                    }
                    
                    $response = Sync-IntuneDevice -Token $graphToken -DeviceId $deviceId
                    $result.details = "Device sync requested: $deviceId"
                    $result.response = $response
                }
                "Run Defender Scan" {
                    $deviceId = if ($Request.Body.deviceId) { $Request.Body.deviceId } else { $Request.Query.deviceId }
                    $quickScan = if ($Request.Body.quickScan -ne $null) { $Request.Body.quickScan } else { $true }
                    
                    if (-not $deviceId) {
                        throw "deviceId is required"
                    }
                    
                    $response = Invoke-IntuneDefenderScan -Token $graphToken -DeviceId $deviceId -QuickScan $quickScan
                    $result.details = "Defender scan initiated: $deviceId"
                    $result.response = $response
                }
                "Get Managed Devices" {
                    $filter = if ($Request.Body.filter) { $Request.Body.filter } else { $Request.Query.filter }
                    $top = if ($Request.Body.top) { $Request.Body.top } else { if ($Request.Query.top) { $Request.Query.top } else { 100 } }
                    
                    $response = Get-IntuneManagedDevices -Token $graphToken -Filter $filter -Top $top
                    $result.details = "Managed devices retrieved"
                    $result.devices = $response
                }
                default {
                    throw "Unknown Intune action: $action"
                }
            }
        }
        "Azure*" {
            # Azure Infrastructure actions - requires Azure RM token
            $azureToken = Get-AzureAccessToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId
            
            switch ($action) {
                "Add NSG Deny Rule" {
                    $subscriptionId = if ($Request.Body.subscriptionId) { $Request.Body.subscriptionId } else { $Request.Query.subscriptionId }
                    $resourceGroupName = if ($Request.Body.resourceGroupName) { $Request.Body.resourceGroupName } else { $Request.Query.resourceGroupName }
                    $nsgName = if ($Request.Body.nsgName) { $Request.Body.nsgName } else { $Request.Query.nsgName }
                    $ruleName = if ($Request.Body.ruleName) { $Request.Body.ruleName } else { $Request.Query.ruleName }
                    $sourceAddressPrefix = if ($Request.Body.sourceAddressPrefix) { $Request.Body.sourceAddressPrefix } else { $Request.Query.sourceAddressPrefix }
                    $destinationPortRange = if ($Request.Body.destinationPortRange) { $Request.Body.destinationPortRange } else { $Request.Query.destinationPortRange }
                    $priority = if ($Request.Body.priority) { $Request.Body.priority } else { if ($Request.Query.priority) { $Request.Query.priority } else { 100 } }
                    $protocol = if ($Request.Body.protocol) { $Request.Body.protocol } else { if ($Request.Query.protocol) { $Request.Query.protocol } else { "*" } }
                    
                    if (-not $subscriptionId -or -not $resourceGroupName -or -not $nsgName -or -not $ruleName -or -not $sourceAddressPrefix -or -not $destinationPortRange) {
                        throw "subscriptionId, resourceGroupName, nsgName, ruleName, sourceAddressPrefix, and destinationPortRange are required"
                    }
                    
                    $response = Add-NSGDenyRule -Token $azureToken -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -NSGName $nsgName -RuleName $ruleName -SourceAddressPrefix $sourceAddressPrefix -DestinationPortRange $destinationPortRange -Priority $priority -Protocol $protocol
                    $result.details = "NSG deny rule added: $ruleName"
                    $result.response = $response
                }
                "Stop Azure VM" {
                    $subscriptionId = if ($Request.Body.subscriptionId) { $Request.Body.subscriptionId } else { $Request.Query.subscriptionId }
                    $resourceGroupName = if ($Request.Body.resourceGroupName) { $Request.Body.resourceGroupName } else { $Request.Query.resourceGroupName }
                    $vmName = if ($Request.Body.vmName) { $Request.Body.vmName } else { $Request.Query.vmName }
                    
                    if (-not $subscriptionId -or -not $resourceGroupName -or -not $vmName) {
                        throw "subscriptionId, resourceGroupName, and vmName are required"
                    }
                    
                    $response = Stop-AzureVM -Token $azureToken -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -VMName $vmName
                    $result.details = "Azure VM stop initiated: $vmName"
                    $result.response = $response
                }
                "Disable Storage Public Access" {
                    $subscriptionId = if ($Request.Body.subscriptionId) { $Request.Body.subscriptionId } else { $Request.Query.subscriptionId }
                    $resourceGroupName = if ($Request.Body.resourceGroupName) { $Request.Body.resourceGroupName } else { $Request.Query.resourceGroupName }
                    $storageAccountName = if ($Request.Body.storageAccountName) { $Request.Body.storageAccountName } else { $Request.Query.storageAccountName }
                    
                    if (-not $subscriptionId -or -not $resourceGroupName -or -not $storageAccountName) {
                        throw "subscriptionId, resourceGroupName, and storageAccountName are required"
                    }
                    
                    $response = Disable-StorageAccountPublicAccess -Token $azureToken -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
                    $result.details = "Storage public access disabled: $storageAccountName"
                    $result.response = $response
                }
                "Remove VM Public IP" {
                    $subscriptionId = if ($Request.Body.subscriptionId) { $Request.Body.subscriptionId } else { $Request.Query.subscriptionId }
                    $resourceGroupName = if ($Request.Body.resourceGroupName) { $Request.Body.resourceGroupName } else { $Request.Query.resourceGroupName }
                    $networkInterfaceName = if ($Request.Body.networkInterfaceName) { $Request.Body.networkInterfaceName } else { $Request.Query.networkInterfaceName }
                    
                    if (-not $subscriptionId -or -not $resourceGroupName -or -not $networkInterfaceName) {
                        throw "subscriptionId, resourceGroupName, and networkInterfaceName are required"
                    }
                    
                    $response = Remove-VMPublicIP -Token $azureToken -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -NetworkInterfaceName $networkInterfaceName
                    $result.details = "VM public IP removed: $networkInterfaceName"
                    $result.response = $response
                }
                "Get Azure VMs" {
                    $subscriptionId = if ($Request.Body.subscriptionId) { $Request.Body.subscriptionId } else { $Request.Query.subscriptionId }
                    $resourceGroupName = if ($Request.Body.resourceGroupName) { $Request.Body.resourceGroupName } else { $Request.Query.resourceGroupName }
                    
                    if (-not $subscriptionId) {
                        throw "subscriptionId is required"
                    }
                    
                    $response = Get-AzureVMs -Token $azureToken -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName
                    $result.details = "Azure VMs retrieved"
                    $result.vms = $response
                }
                default {
                    throw "Unknown Azure action: $action"
                }
            }
        }
        default {
            throw "Unknown or unspecified service. Please specify service parameter (MDO, EntraID, ConditionalAccess, Intune, or Azure)"
        }
    }

    # Return success response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 10
    })

} catch {
    Write-Error $_.Exception.Message
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = $_.Exception.Message
            details = $_.Exception.ToString()
            action = $action
            service = $service
        } | ConvertTo-Json
    })
}
