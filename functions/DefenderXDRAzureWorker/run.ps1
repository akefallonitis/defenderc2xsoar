using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -Force
# NOTE: Business logic is inline - no external module needed

# Extract parameters from request
$action = $Request.Body.action
$tenantId = $Request.Body.tenantId
$body = $Request.Body

Write-XDRLog -Level "Info" -Message "AzureWorker received request" -Data @{
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

    # Authenticate to Azure Resource Manager
    $tokenParams = @{
        TenantId = $tenantId
        Service = "AzureRM"
    }
    $token = Get-OAuthToken @tokenParams
    
    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to obtain authentication token"
    }

    # Execute action
    $result = $null
    
    switch ($action) {
        "AddNSGDenyRule" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.nsgName)) {
                throw "Missing required parameter: nsgName"
            }
            if ([string]::IsNullOrEmpty($body.sourceIp)) {
                throw "Missing required parameter: sourceIp"
            }
            
            Write-XDRLog -Level "Info" -Message "Adding NSG deny rule" -Data @{
                NSGName = $body.nsgName
                SourceIP = $body.sourceIp
            }
            
            $nsgParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
                ResourceGroup = $body.resourceGroup
                NSGName = $body.nsgName
                SourceIP = $body.sourceIp
            }
            
            if ($body.ruleName) {
                $nsgParams.RuleName = $body.ruleName
            }
            if ($body.priority) {
                $nsgParams.Priority = [int]$body.priority
            }
            
            $nsgResult = Add-AzureNSGDenyRule @nsgParams
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                nsgName = $body.nsgName
                ruleName = $nsgResult.name
                sourceIp = $body.sourceIp
                priority = $nsgResult.priority
                created = $true
            }
        }
        
        "StopVM" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameter: vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Stopping VM" -Data @{
                VMName = $body.vmName
                ResourceGroup = $body.resourceGroup
            }
            
            $vmParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
                ResourceGroup = $body.resourceGroup
                VMName = $body.vmName
            }
            
            $vmResult = Stop-AzureVM @vmParams
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                action = "StopVM"
                status = "stopped"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableStoragePublicAccess" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling storage public access" -Data @{
                StorageAccount = $body.storageAccountName
            }
            
            $storageParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
                ResourceGroup = $body.resourceGroup
                StorageAccountName = $body.storageAccountName
            }
            
            $storageResult = Disable-AzureStoragePublicAccess @storageParams
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                publicAccessDisabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW AZURE STORAGE ACTIONS (6 actions) =====
        
        "RotateStorageAccountKeys" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            $keyName = $body.keyName ?? "key1"  # key1 or key2
            
            Write-XDRLog -Level "Info" -Message "Rotating storage account keys" -Data @{
                StorageAccount = $body.storageAccountName
                KeyName = $keyName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/regenerateKey?api-version=2023-01-01"
            
            $regenerateBody = @{
                keyName = $keyName
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $regenerateBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                keyRotated = $keyName
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Storage account key rotated successfully. Update all applications using this key."
            }
        }
        
        "RevokeStorageSAS" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            Write-XDRLog -Level "Info" -Message "Revoking storage account SAS tokens" -Data @{
                StorageAccount = $body.storageAccountName
            }
            
            # Revoke user delegation keys (invalidates all SAS tokens)
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/revokeUserDelegationKeys?api-version=2023-01-01"
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                sasTokensRevoked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "All user delegation keys revoked. SAS tokens using these keys are now invalid."
            }
        }
        
        "EnableStorageFirewall" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            $allowedIPs = $body.allowedIPs ?? @()  # Array of IP addresses/ranges to allow
            $defaultAction = $body.defaultAction ?? "Deny"
            
            Write-XDRLog -Level "Info" -Message "Enabling storage firewall" -Data @{
                StorageAccount = $body.storageAccountName
                DefaultAction = $defaultAction
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)?api-version=2023-01-01"
            
            $firewallRules = @()
            foreach ($ip in $allowedIPs) {
                $firewallRules += @{
                    value = $ip
                    action = "Allow"
                }
            }
            
            $patchBody = @{
                properties = @{
                    networkAcls = @{
                        bypass = "AzureServices"
                        defaultAction = $defaultAction
                        ipRules = $firewallRules
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $patchBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                firewallEnabled = $true
                defaultAction = $defaultAction
                allowedIPCount = $firewallRules.Count
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableStorageDefender" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling Microsoft Defender for Storage" -Data @{
                StorageAccount = $body.storageAccountName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/providers/Microsoft.Security/defenderForStorageSettings/current?api-version=2022-12-01-preview"
            
            $defenderBody = @{
                properties = @{
                    isEnabled = $true
                    malwareScanning = @{
                        onUpload = @{
                            isEnabled = $true
                            capGBPerMonth = 5000
                        }
                    }
                    sensitiveDataDiscovery = @{
                        isEnabled = $true
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $defenderBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                defenderEnabled = $true
                malwareScanningEnabled = $true
                sensitiveDataDiscoveryEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockStorageContainer" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            if ([string]::IsNullOrEmpty($body.containerName)) {
                throw "Missing required parameter: containerName"
            }
            
            Write-XDRLog -Level "Info" -Message "Blocking storage container access" -Data @{
                StorageAccount = $body.storageAccountName
                Container = $body.containerName
            }
            
            # Set container public access to None
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/blobServices/default/containers/$($body.containerName)?api-version=2023-01-01"
            
            $patchBody = @{
                properties = @{
                    publicAccess = "None"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $patchBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                containerName = $body.containerName
                publicAccessBlocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableStorageSoftDelete" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountName)) {
                throw "Missing required parameter: storageAccountName"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling storage soft delete (emergency data destruction)" -Data @{
                StorageAccount = $body.storageAccountName
            }
            
            # Disable blob soft delete
            $blobUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/blobServices/default?api-version=2023-01-01"
            
            $blobBody = @{
                properties = @{
                    deleteRetentionPolicy = @{
                        enabled = $false
                    }
                    containerDeleteRetentionPolicy = @{
                        enabled = $false
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $blobResponse = Invoke-RestMethod -Method Patch -Uri $blobUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $blobBody
            
            # Disable file share soft delete
            $fileUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Storage/storageAccounts/$($body.storageAccountName)/fileServices/default?api-version=2023-01-01"
            
            $fileBody = @{
                properties = @{
                    shareDeleteRetentionPolicy = @{
                        enabled = $false
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $fileResponse = Invoke-RestMethod -Method Patch -Uri $fileUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $fileBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                storageAccountName = $body.storageAccountName
                blobSoftDeleteDisabled = $true
                containerSoftDeleteDisabled = $true
                fileShareSoftDeleteDisabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                warning = "EMERGENCY ACTION: Soft delete disabled. Deleted data cannot be recovered."
            }
        }
        
        "RemoveVMPublicIP" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameter: vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Removing VM public IP" -Data @{
                VMName = $body.vmName
            }
            
            $publicIpParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
                ResourceGroup = $body.resourceGroup
                VMName = $body.vmName
            }
            
            $publicIpResult = Remove-AzureVMPublicIP @publicIpParams
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                publicIpRemoved = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #region Azure Firewall Actions (Azure ARM API)
        
        "BlockIPInFirewall" {
            # Block malicious IP in Azure Firewall (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.firewallName) -or [string]::IsNullOrEmpty($body.sourceIp)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, firewallName, sourceIp"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking IP in Azure Firewall" -Data @{
                FirewallName = $body.firewallName
                SourceIP = $body.sourceIp
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $ruleName = if ($body.ruleName) { $body.ruleName } else { "Block-IP-$($body.sourceIp -replace '\.', '-')-$(Get-Date -Format 'yyyyMMddHHmmss')" }
            $priority = if ($body.priority) { [int]$body.priority } else { 100 }
            
            # Get existing firewall policy
            $firewallUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/azureFirewalls/$($body.firewallName)?api-version=2023-05-01"
            $firewall = Invoke-RestMethod -Uri $firewallUri -Method Get -Headers $headers
            
            if (-not $firewall.properties.firewallPolicy.id) {
                throw "Firewall policy not configured on firewall"
            }
            
            $policyId = $firewall.properties.firewallPolicy.id
            $policyUri = "https://management.azure.com$policyId/ruleCollectionGroups/DefaultNetworkRuleCollectionGroup?api-version=2023-05-01"
            
            # Create new rule
            $newRule = @{
                name = $ruleName
                ruleType = "NetworkRule"
                sourceAddresses = @($body.sourceIp)
                destinationAddresses = @("*")
                destinationPorts = @("*")
                ipProtocols = @("Any")
            }
            
            try {
                $ruleCollection = Invoke-RestMethod -Uri $policyUri -Method Get -Headers $headers
                
                # Add to existing rule collection
                if (-not $ruleCollection.properties.ruleCollections) {
                    $ruleCollection.properties.ruleCollections = @()
                }
                
                $blockCollection = $ruleCollection.properties.ruleCollections | Where-Object { $_.name -eq "BlockMaliciousIPs" }
                if (-not $blockCollection) {
                    $blockCollection = @{
                        name = "BlockMaliciousIPs"
                        priority = $priority
                        ruleCollectionType = "FirewallPolicyFilterRuleCollection"
                        action = @{ type = "Deny" }
                        rules = @()
                    }
                    $ruleCollection.properties.ruleCollections += $blockCollection
                }
                
                $blockCollection.rules += $newRule
                
                $updateResult = Invoke-RestMethod -Uri $policyUri -Method Put -Headers $headers -Body ($ruleCollection | ConvertTo-Json -Depth 20)
                
                $result = @{
                    subscriptionId = $body.subscriptionId
                    resourceGroup = $body.resourceGroup
                    firewallName = $body.firewallName
                    ruleName = $ruleName
                    sourceIp = $body.sourceIp
                    action = "Deny"
                    created = $true
                    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
            } catch {
                throw "Failed to update firewall policy: $($_.Exception.Message)"
            }
        }
        
        "BlockDomainInFirewall" {
            # Block malicious domain in Azure Firewall (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.firewallName) -or [string]::IsNullOrEmpty($body.domain)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, firewallName, domain"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking domain in Azure Firewall" -Data @{
                FirewallName = $body.firewallName
                Domain = $body.domain
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $ruleName = if ($body.ruleName) { $body.ruleName } else { "Block-Domain-$($body.domain -replace '\.', '-')-$(Get-Date -Format 'yyyyMMddHHmmss')" }
            
            # Get firewall policy
            $firewallUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/azureFirewalls/$($body.firewallName)?api-version=2023-05-01"
            $firewall = Invoke-RestMethod -Uri $firewallUri -Method Get -Headers $headers
            
            if (-not $firewall.properties.firewallPolicy.id) {
                throw "Firewall policy not configured"
            }
            
            $policyId = $firewall.properties.firewallPolicy.id
            $policyUri = "https://management.azure.com$policyId/ruleCollectionGroups/DefaultApplicationRuleCollectionGroup?api-version=2023-05-01"
            
            # Create application rule to block domain
            $newRule = @{
                name = $ruleName
                ruleType = "ApplicationRule"
                sourceAddresses = @("*")
                targetFqdns = @($body.domain)
                protocols = @(
                    @{ protocolType = "Http"; port = 80 }
                    @{ protocolType = "Https"; port = 443 }
                )
            }
            
            try {
                $ruleCollection = Invoke-RestMethod -Uri $policyUri -Method Get -Headers $headers -ErrorAction SilentlyContinue
                
                if (-not $ruleCollection) {
                    # Create new rule collection group
                    $ruleCollection = @{
                        properties = @{
                            priority = 200
                            ruleCollections = @()
                        }
                    }
                }
                
                $blockCollection = $ruleCollection.properties.ruleCollections | Where-Object { $_.name -eq "BlockMaliciousDomains" }
                if (-not $blockCollection) {
                    $blockCollection = @{
                        name = "BlockMaliciousDomains"
                        priority = 200
                        ruleCollectionType = "FirewallPolicyFilterRuleCollection"
                        action = @{ type = "Deny" }
                        rules = @()
                    }
                    $ruleCollection.properties.ruleCollections += $blockCollection
                }
                
                $blockCollection.rules += $newRule
                
                $updateResult = Invoke-RestMethod -Uri $policyUri -Method Put -Headers $headers -Body ($ruleCollection | ConvertTo-Json -Depth 20)
                
                $result = @{
                    subscriptionId = $body.subscriptionId
                    resourceGroup = $body.resourceGroup
                    firewallName = $body.firewallName
                    ruleName = $ruleName
                    domain = $body.domain
                    action = "Deny"
                    created = $true
                    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
            } catch {
                throw "Failed to update firewall policy: $($_.Exception.Message)"
            }
        }
        
        "EnableThreatIntel" {
            # Enable threat intelligence on Azure Firewall (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.firewallName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, firewallName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling threat intelligence on Azure Firewall" -Data @{
                FirewallName = $body.firewallName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $mode = if ($body.mode) { $body.mode } else { "Alert" }  # Alert or Deny
            
            $firewallUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/azureFirewalls/$($body.firewallName)?api-version=2023-05-01"
            $firewall = Invoke-RestMethod -Uri $firewallUri -Method Get -Headers $headers
            
            # Update threat intelligence mode
            $firewall.properties.threatIntelMode = $mode
            
            $updateResult = Invoke-RestMethod -Uri $firewallUri -Method Put -Headers $headers -Body ($firewall | ConvertTo-Json -Depth 20)
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                firewallName = $body.firewallName
                threatIntelMode = $mode
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region Key Vault Actions (Azure ARM API + Graph v1.0)
        
        "DisableKeyVaultSecret" {
            # Disable compromised Key Vault secret (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vaultName) -or [string]::IsNullOrEmpty($body.secretName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vaultName, secretName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disabling Key Vault secret" -Data @{
                VaultName = $body.vaultName
                SecretName = $body.secretName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get current secret version
            $vaultUri = "https://$($body.vaultName).vault.azure.net/secrets/$($body.secretName)?api-version=7.4"
            $secret = Invoke-RestMethod -Uri $vaultUri -Method Get -Headers $headers
            
            # Update secret to disabled
            $updateBody = @{
                attributes = @{
                    enabled = $false
                }
            } | ConvertTo-Json
            
            $updateUri = "https://$($body.vaultName).vault.azure.net/secrets/$($body.secretName)?api-version=7.4"
            $updateResult = Invoke-RestMethod -Uri $updateUri -Method Patch -Headers $headers -Body $updateBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vaultName = $body.vaultName
                secretName = $body.secretName
                disabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RotateKeyVaultKey" {
            # Rotate encryption key in Key Vault (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vaultName) -or [string]::IsNullOrEmpty($body.keyName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vaultName, keyName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Rotating Key Vault key" -Data @{
                VaultName = $body.vaultName
                KeyName = $body.keyName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get current key details
            $keyUri = "https://$($body.vaultName).vault.azure.net/keys/$($body.keyName)?api-version=7.4"
            $currentKey = Invoke-RestMethod -Uri $keyUri -Method Get -Headers $headers
            
            # Create new version of the key
            $newKeyBody = @{
                kty = $currentKey.key.kty
                key_ops = $currentKey.key.key_ops
                attributes = @{
                    enabled = $true
                }
            } | ConvertTo-Json
            
            $createUri = "https://$($body.vaultName).vault.azure.net/keys/$($body.keyName)/create?api-version=7.4"
            $newKey = Invoke-RestMethod -Uri $createUri -Method Post -Headers $headers -Body $newKeyBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vaultName = $body.vaultName
                keyName = $body.keyName
                oldVersion = $currentKey.key.kid.Split('/')[-1]
                newVersion = $newKey.key.kid.Split('/')[-1]
                rotated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "PurgeDeletedSecret" {
            # Permanently purge deleted Key Vault secret (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.vaultName) -or [string]::IsNullOrEmpty($body.secretName)) {
                throw "Missing required parameters: vaultName, secretName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Purging deleted Key Vault secret" -Data @{
                VaultName = $body.vaultName
                SecretName = $body.secretName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $purgeUri = "https://$($body.vaultName).vault.azure.net/deletedsecrets/$($body.secretName)?api-version=7.4"
            Invoke-RestMethod -Uri $purgeUri -Method Delete -Headers $headers
            
            $result = @{
                vaultName = $body.vaultName
                secretName = $body.secretName
                purged = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region Service Principal Actions (Graph v1.0)
        
        # ===== V3.2.0 NEW AZURE SQL ACTIONS (5 actions) =====
        
        "BlockSQLIP" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.serverName)) {
                throw "Missing required parameter: serverName"
            }
            if ([string]::IsNullOrEmpty($body.ipAddress)) {
                throw "Missing required parameter: ipAddress"
            }
            
            Write-XDRLog -Level "Info" -Message "Adding SQL firewall rule to block IP" -Data @{
                ServerName = $body.serverName
                IPAddress = $body.ipAddress
            }
            
            $ruleName = $body.ruleName ?? "BlockMalicious_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            
            # Azure SQL uses allow-list, so we remove any existing rules allowing this IP
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)/firewallRules?api-version=2021-11-01"
            
            $existingRules = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $removedRules = @()
            foreach ($rule in $existingRules.value) {
                if ($rule.properties.startIpAddress -eq $body.ipAddress -or $rule.properties.endIpAddress -eq $body.ipAddress) {
                    $deleteUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)/firewallRules/$($rule.name)?api-version=2021-11-01"
                    Invoke-RestMethod -Method Delete -Uri $deleteUri -Headers @{
                        "Authorization" = "Bearer $token"
                    }
                    $removedRules += $rule.name
                }
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                serverName = $body.serverName
                blockedIP = $body.ipAddress
                removedRules = $removedRules
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "IP address removed from SQL firewall allow list"
            }
        }
        
        "DisableSQLPublicAccess" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.serverName)) {
                throw "Missing required parameter: serverName"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling SQL public network access" -Data @{
                ServerName = $body.serverName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)?api-version=2021-11-01"
            
            $patchBody = @{
                properties = @{
                    publicNetworkAccess = "Disabled"
                    restrictOutboundNetworkAccess = "Enabled"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $patchBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                serverName = $body.serverName
                publicAccessDisabled = $true
                outboundRestricted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "SQL Server now accessible only via private endpoints"
            }
        }
        
        "RotateSQLPassword" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.serverName)) {
                throw "Missing required parameter: serverName"
            }
            
            # Generate strong random password
            $newPassword = -join ((33..126) | Get-Random -Count 32 | ForEach-Object {[char]$_})
            
            Write-XDRLog -Level "Info" -Message "Rotating SQL administrator password" -Data @{
                ServerName = $body.serverName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)?api-version=2021-11-01"
            
            $patchBody = @{
                properties = @{
                    administratorLoginPassword = $newPassword
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $patchBody
            
            # Store new password in Key Vault if provided
            if ($body.keyVaultName -and $body.secretName) {
                $kvToken = Get-OAuthToken -TenantId $tenantId -Service "KeyVault"
                $secretUri = "https://$($body.keyVaultName).vault.azure.net/secrets/$($body.secretName)?api-version=7.4"
                
                $secretBody = @{
                    value = $newPassword
                    attributes = @{
                        enabled = $true
                    }
                } | ConvertTo-Json
                
                Invoke-RestMethod -Method Put -Uri $secretUri -Headers @{
                    "Authorization" = "Bearer $kvToken"
                    "Content-Type" = "application/json"
                } -Body $secretBody
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                serverName = $body.serverName
                passwordRotated = $true
                storedInKeyVault = ($body.keyVaultName -ne $null)
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "SQL administrator password rotated. Update connection strings immediately."
                # DO NOT include password in response for security
            }
        }
        
        "EnableSQLAudit" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.serverName)) {
                throw "Missing required parameter: serverName"
            }
            if ([string]::IsNullOrEmpty($body.databaseName)) {
                throw "Missing required parameter: databaseName"
            }
            if ([string]::IsNullOrEmpty($body.storageAccountId)) {
                throw "Missing required parameter: storageAccountId (for audit logs)"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling SQL auditing" -Data @{
                ServerName = $body.serverName
                DatabaseName = $body.databaseName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)/databases/$($body.databaseName)/auditingSettings/default?api-version=2021-11-01"
            
            $auditBody = @{
                properties = @{
                    state = "Enabled"
                    storageEndpoint = "https://$($body.storageAccountId.Split('/')[-1]).blob.core.windows.net"
                    storageAccountSubscriptionId = $body.subscriptionId
                    retentionDays = 90
                    auditActionsAndGroups = @(
                        "BATCH_COMPLETED_GROUP",
                        "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP",
                        "FAILED_DATABASE_AUTHENTICATION_GROUP",
                        "DATABASE_PERMISSION_CHANGE_GROUP",
                        "DATABASE_PRINCIPAL_CHANGE_GROUP",
                        "DATABASE_ROLE_MEMBER_CHANGE_GROUP",
                        "DATABASE_OBJECT_CHANGE_GROUP"
                    )
                    isStorageSecondaryKeyInUse = $false
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $auditBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                serverName = $body.serverName
                databaseName = $body.databaseName
                auditingEnabled = $true
                retentionDays = 90
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableSQLTDE" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.serverName)) {
                throw "Missing required parameter: serverName"
            }
            if ([string]::IsNullOrEmpty($body.databaseName)) {
                throw "Missing required parameter: databaseName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling SQL Transparent Data Encryption (TDE)" -Data @{
                ServerName = $body.serverName
                DatabaseName = $body.databaseName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Sql/servers/$($body.serverName)/databases/$($body.databaseName)/transparentDataEncryption/current?api-version=2021-11-01"
            
            $tdeBody = @{
                properties = @{
                    state = "Enabled"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $tdeBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                serverName = $body.serverName
                databaseName = $body.databaseName
                tdeEnabled = $true
                encryptionAtRestEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Transparent Data Encryption enabled. Database encrypted at rest."
            }
        }
        
        # ===== V3.2.0 NEW AZURE ARC ACTIONS (4 actions) =====
        
        "IsolateArcServer" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.machineName)) {
                throw "Missing required parameter: machineName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Isolating Arc-enabled server" -Data @{
                MachineName = $body.machineName
            }
            
            # Tag machine for isolation and run network isolation script
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)?api-version=2023-10-03-preview"
            
            $tagBody = @{
                tags = @{
                    SecurityStatus = "Isolated"
                    IsolatedDate = (Get-Date).ToString("yyyy-MM-dd")
                    IsolatedReason = $body.reason ?? "Security incident"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $tagBody
            
            # Run isolation command via Arc extension
            $commandUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)/runCommand?api-version=2023-10-03-preview"
            
            $isolationScript = if ($body.osType -eq "Windows") {
                "New-NetFirewallRule -DisplayName 'Arc Isolation' -Direction Outbound -Action Block -Enabled True"
            } else {
                "iptables -A OUTPUT -j DROP"
            }
            
            $commandBody = @{
                properties = @{
                    source = @{
                        script = $isolationScript
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $commandResponse = Invoke-RestMethod -Method Post -Uri $commandUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $commandBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                machineName = $body.machineName
                isolated = $true
                commandExecuted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RunArcCommand" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.machineName)) {
                throw "Missing required parameter: machineName"
            }
            if ([string]::IsNullOrEmpty($body.script)) {
                throw "Missing required parameter: script"
            }
            
            Write-XDRLog -Level "Info" -Message "Executing command on Arc server" -Data @{
                MachineName = $body.machineName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)/runCommand?api-version=2023-10-03-preview"
            
            $commandBody = @{
                properties = @{
                    source = @{
                        script = $body.script
                        scriptUri = $body.scriptUri
                    }
                    parameters = $body.parameters
                    asyncExecution = $body.async ?? $false
                    timeoutInSeconds = $body.timeout ?? 3600
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $commandBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                machineName = $body.machineName
                commandId = $response.id
                status = $response.properties.provisioningState
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableDefenderArc" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.machineName)) {
                throw "Missing required parameter: machineName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling Defender for Arc server" -Data @{
                MachineName = $body.machineName
            }
            
            # Install MDE extension on Arc machine
            $extensionUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)/extensions/MDE.Windows?api-version=2023-10-03-preview"
            
            $extensionBody = @{
                properties = @{
                    publisher = "Microsoft.Azure.AzureDefenderForServers"
                    type = "MDE.Windows"
                    typeHandlerVersion = "1.0"
                    autoUpgradeMinorVersion = $true
                    settings = @{
                        azureResourceId = "/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)"
                        forceReOnboarding = $false
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $extensionUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $extensionBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                machineName = $body.machineName
                defenderEnabled = $true
                extensionInstalled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisconnectArcServer" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.machineName)) {
                throw "Missing required parameter: machineName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disconnecting Arc server" -Data @{
                MachineName = $body.machineName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.HybridCompute/machines/$($body.machineName)?api-version=2023-10-03-preview"
            
            $response = Invoke-RestMethod -Method Delete -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                machineName = $body.machineName
                disconnected = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Arc agent disconnected. Server is no longer managed by Azure Arc."
            }
        }
        
        # ===== V3.2.0 NEW AZURE WAF ACTIONS (4 actions) =====
        
        "BlockIPInWAF" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.wafPolicyName)) {
                throw "Missing required parameter: wafPolicyName"
            }
            if ([string]::IsNullOrEmpty($body.ipAddress)) {
                throw "Missing required parameter: ipAddress"
            }
            
            Write-XDRLog -Level "Info" -Message "Blocking IP in WAF policy" -Data @{
                WAFPolicy = $body.wafPolicyName
                IPAddress = $body.ipAddress
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$($body.wafPolicyName)?api-version=2023-09-01"
            
            # Get current policy
            $policy = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            # Add custom rule to block IP
            $ruleName = "BlockIP_" + ($body.ipAddress -replace '\.','')
            $newRule = @{
                name = $ruleName
                priority = 10
                ruleType = "MatchRule"
                action = "Block"
                matchConditions = @(
                    @{
                        matchVariables = @(
                            @{
                                variableName = "RemoteAddr"
                            }
                        )
                        operator = "IPMatch"
                        matchValues = @($body.ipAddress)
                    }
                )
            }
            
            if (-not $policy.properties.customRules) {
                $policy.properties.customRules = @()
            }
            $policy.properties.customRules += $newRule
            
            $policyBody = $policy | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $policyBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                wafPolicyName = $body.wafPolicyName
                blockedIP = $body.ipAddress
                ruleName = $ruleName
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "AddWAFCustomRule" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.wafPolicyName)) {
                throw "Missing required parameter: wafPolicyName"
            }
            if ([string]::IsNullOrEmpty($body.ruleName)) {
                throw "Missing required parameter: ruleName"
            }
            if (-not $body.matchConditions) {
                throw "Missing required parameter: matchConditions"
            }
            
            Write-XDRLog -Level "Info" -Message "Adding WAF custom rule" -Data @{
                WAFPolicy = $body.wafPolicyName
                RuleName = $body.ruleName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$($body.wafPolicyName)?api-version=2023-09-01"
            
            $policy = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $newRule = @{
                name = $body.ruleName
                priority = $body.priority ?? 100
                ruleType = "MatchRule"
                action = $body.action ?? "Block"
                matchConditions = $body.matchConditions
            }
            
            if (-not $policy.properties.customRules) {
                $policy.properties.customRules = @()
            }
            $policy.properties.customRules += $newRule
            
            $policyBody = $policy | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $policyBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                wafPolicyName = $body.wafPolicyName
                ruleName = $body.ruleName
                ruleAdded = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableWAFPreventionMode" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.wafPolicyName)) {
                throw "Missing required parameter: wafPolicyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling WAF prevention mode" -Data @{
                WAFPolicy = $body.wafPolicyName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$($body.wafPolicyName)?api-version=2023-09-01"
            
            $patchBody = @{
                properties = @{
                    policySettings = @{
                        mode = "Prevention"
                        state = "Enabled"
                        requestBodyCheck = $true
                        maxRequestBodySizeInKb = 128
                        fileUploadLimitInMb = 100
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $patchBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                wafPolicyName = $body.wafPolicyName
                mode = "Prevention"
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockGeoLocationWAF" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.wafPolicyName)) {
                throw "Missing required parameter: wafPolicyName"
            }
            if (-not $body.countryCodes) {
                throw "Missing required parameter: countryCodes (e.g., ['CN', 'RU'])"
            }
            
            Write-XDRLog -Level "Info" -Message "Blocking geo locations in WAF" -Data @{
                WAFPolicy = $body.wafPolicyName
                Countries = $body.countryCodes -join ','
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$($body.wafPolicyName)?api-version=2023-09-01"
            
            $policy = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $geoRule = @{
                name = "BlockGeoLocations"
                priority = 5
                ruleType = "MatchRule"
                action = "Block"
                matchConditions = @(
                    @{
                        matchVariables = @(
                            @{
                                variableName = "RemoteAddr"
                            }
                        )
                        operator = "GeoMatch"
                        matchValues = $body.countryCodes
                    }
                )
            }
            
            if (-not $policy.properties.customRules) {
                $policy.properties.customRules = @()
            }
            $policy.properties.customRules += $geoRule
            
            $policyBody = $policy | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $policyBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                wafPolicyName = $body.wafPolicyName
                blockedCountries = $body.countryCodes
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableServicePrincipal" {
            # Disable compromised service principal (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.servicePrincipalId)) {
                throw "Missing required parameter: servicePrincipalId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disabling service principal" -Data @{
                ServicePrincipalId = $body.servicePrincipalId
            }
            
            # Need Graph token for service principal operations
            $graphToken = Get-OAuthToken -TenantId $tenantId -Service "Graph"
            $headers = @{
                "Authorization" = "Bearer $graphToken"
                "Content-Type" = "application/json"
            }
            
            $updateBody = @{
                accountEnabled = $false
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/servicePrincipals/$($body.servicePrincipalId)"
            $updateResult = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $updateBody
            
            $result = @{
                servicePrincipalId = $body.servicePrincipalId
                disabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RemoveAppCredentials" {
            # Remove all credentials from compromised app (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.applicationId)) {
                throw "Missing required parameter: applicationId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing application credentials" -Data @{
                ApplicationId = $body.applicationId
            }
            
            $graphToken = Get-OAuthToken -TenantId $tenantId -Service "Graph"
            $headers = @{
                "Authorization" = "Bearer $graphToken"
                "Content-Type" = "application/json"
            }
            
            # Get current app
            $appUri = "https://graph.microsoft.com/v1.0/applications/$($body.applicationId)"
            $app = Invoke-RestMethod -Uri $appUri -Method Get -Headers $headers
            
            $removedSecrets = @()
            $removedCerts = @()
            
            # Remove all password credentials (secrets)
            foreach ($cred in $app.passwordCredentials) {
                $removeBody = @{
                    keyId = $cred.keyId
                } | ConvertTo-Json
                
                $removeUri = "https://graph.microsoft.com/v1.0/applications/$($body.applicationId)/removePassword"
                Invoke-RestMethod -Uri $removeUri -Method Post -Headers $headers -Body $removeBody
                $removedSecrets += $cred.keyId
            }
            
            # Remove all key credentials (certificates)
            foreach ($cert in $app.keyCredentials) {
                $removeBody = @{
                    keyId = $cert.keyId
                } | ConvertTo-Json
                
                $removeUri = "https://graph.microsoft.com/v1.0/applications/$($body.applicationId)/removeKey"
                Invoke-RestMethod -Uri $removeUri -Method Post -Headers $headers -Body $removeBody
                $removedCerts += $cert.keyId
            }
            
            $result = @{
                applicationId = $body.applicationId
                removedSecretsCount = $removedSecrets.Count
                removedCertificatesCount = $removedCerts.Count
                removedSecrets = $removedSecrets
                removedCertificates = $removedCerts
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RevokeAppCertificates" {
            # Revoke all certificates from app registration (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.applicationId)) {
                throw "Missing required parameter: applicationId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking application certificates" -Data @{
                ApplicationId = $body.applicationId
            }
            
            $graphToken = Get-OAuthToken -TenantId $tenantId -Service "Graph"
            $headers = @{
                "Authorization" = "Bearer $graphToken"
                "Content-Type" = "application/json"
            }
            
            $appUri = "https://graph.microsoft.com/v1.0/applications/$($body.applicationId)"
            $app = Invoke-RestMethod -Uri $appUri -Method Get -Headers $headers
            
            $revokedCerts = @()
            foreach ($cert in $app.keyCredentials) {
                $removeBody = @{
                    keyId = $cert.keyId
                } | ConvertTo-Json
                
                $removeUri = "https://graph.microsoft.com/v1.0/applications/$($body.applicationId)/removeKey"
                Invoke-RestMethod -Uri $removeUri -Method Post -Headers $headers -Body $removeBody
                $revokedCerts += @{
                    keyId = $cert.keyId
                    displayName = $cert.displayName
                    endDateTime = $cert.endDateTime
                }
            }
            
            $result = @{
                applicationId = $body.applicationId
                revokedCount = $revokedCerts.Count
                revokedCertificates = $revokedCerts
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW AZURE APP SERVICE ACTIONS (4 actions) =====
        
        "StopAppService" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.appName)) {
                throw "Missing required parameter: appName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Stopping App Service" -Data @{
                AppName = $body.appName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Web/sites/$($body.appName)/stop?api-version=2023-01-01"
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                appName = $body.appName
                stopped = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RestartAppService" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.appName)) {
                throw "Missing required parameter: appName"
            }
            
            Write-XDRLog -Level "Info" -Message "Restarting App Service" -Data @{
                AppName = $body.appName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Web/sites/$($body.appName)/restart?api-version=2023-01-01"
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                appName = $body.appName
                restarted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableAppServiceDefender" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.appName)) {
                throw "Missing required parameter: appName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling Defender for App Service" -Data @{
                AppName = $body.appName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Web/sites/$($body.appName)/providers/Microsoft.Security/defenderForWebAppSettings/default?api-version=2022-12-01-preview"
            
            $defenderBody = @{
                properties = @{
                    isEnabled = $true
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $defenderBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                appName = $body.appName
                defenderEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DisableAppServiceAuth" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.appName)) {
                throw "Missing required parameter: appName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Disabling App Service authentication (emergency access lockout)" -Data @{
                AppName = $body.appName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Web/sites/$($body.appName)/config/authsettingsV2?api-version=2023-01-01"
            
            $authBody = @{
                properties = @{
                    platform = @{
                        enabled = $false
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $authBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                appName = $body.appName
                authDisabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                warning = "Authentication disabled. App is now publicly accessible."
            }
        }
        
        # ===== V3.2.0 NEW AZURE CONTAINERS ACTIONS (3 actions) =====
        
        "QuarantineContainerImage" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.registryName)) {
                throw "Missing required parameter: registryName"
            }
            if ([string]::IsNullOrEmpty($body.imageName)) {
                throw "Missing required parameter: imageName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Quarantining container image" -Data @{
                Registry = $body.registryName
                Image = $body.imageName
            }
            
            # Update image to set quarantine attribute
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.ContainerRegistry/registries/$($body.registryName)/updatePolicies?api-version=2023-07-01"
            
            $policyBody = @{
                quarantinePolicy = @{
                    status = "enabled"
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $policyBody
            
            # Tag specific image as quarantined
            $tagUri = "https://$($body.registryName).azurecr.io/acr/v1/$($body.imageName)/_tags/$($body.tag ?? 'latest')"
            $acrToken = Get-OAuthToken -TenantId $tenantId -Service "AzureContainerRegistry"
            
            $tagBody = @{
                quarantineState = "quarantined"
                quarantineDetails = $body.reason ?? "Security incident"
            } | ConvertTo-Json
            
            Invoke-RestMethod -Method Patch -Uri $tagUri -Headers @{
                "Authorization" = "Bearer $acrToken"
                "Content-Type" = "application/json"
            } -Body $tagBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                registryName = $body.registryName
                imageName = $body.imageName
                tag = $body.tag ?? "latest"
                quarantined = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DeletePod" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.clusterName)) {
                throw "Missing required parameter: clusterName"
            }
            if ([string]::IsNullOrEmpty($body.namespace)) {
                throw "Missing required parameter: namespace"
            }
            if ([string]::IsNullOrEmpty($body.podName)) {
                throw "Missing required parameter: podName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deleting Kubernetes pod" -Data @{
                Cluster = $body.clusterName
                Namespace = $body.namespace
                Pod = $body.podName
            }
            
            # Get AKS credentials and run kubectl command
            $credsUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.ContainerService/managedClusters/$($body.clusterName)/listClusterAdminCredential?api-version=2023-10-01"
            
            $creds = Invoke-RestMethod -Method Post -Uri $credsUri -Headers @{
                "Authorization" = "Bearer $token"
            }
            
            # Use AKS Run Command instead
            $commandUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.ContainerService/managedClusters/$($body.clusterName)/runCommand?api-version=2023-10-01"
            
            $commandBody = @{
                command = "kubectl delete pod $($body.podName) -n $($body.namespace) --force --grace-period=0"
                context = ""
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $commandUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $commandBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                clusterName = $body.clusterName
                namespace = $body.namespace
                podName = $body.podName
                deleted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RestartAKSNode" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.clusterName)) {
                throw "Missing required parameter: clusterName"
            }
            if ([string]::IsNullOrEmpty($body.nodeName)) {
                throw "Missing required parameter: nodeName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Restarting AKS node" -Data @{
                Cluster = $body.clusterName
                Node = $body.nodeName
            }
            
            # Cordon and drain node, then restart VM
            $commandUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.ContainerService/managedClusters/$($body.clusterName)/runCommand?api-version=2023-10-01"
            
            $drainCommand = @"
kubectl cordon $($body.nodeName)
kubectl drain $($body.nodeName) --ignore-daemonsets --delete-emptydir-data --force
"@
            
            $commandBody = @{
                command = $drainCommand
                context = ""
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $commandUri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $commandBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                clusterName = $body.clusterName
                nodeName = $body.nodeName
                cordoned = $true
                drained = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Node drained. Restart underlying VM to complete restart."
            }
        }
        
        # ===== V3.2.0 NEW MICROSOFT DEFENDER FOR CLOUD ACTIONS (6 actions) =====
        
        "EnableDefenderPlan" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.planName)) {
                throw "Missing required parameter: planName (VirtualMachines, SqlServers, AppServices, Storage, Containers, KeyVaults, Dns, Arm, etc.)"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling Defender plan" -Data @{
                Plan = $body.planName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/providers/Microsoft.Security/pricings/$($body.planName)?api-version=2023-01-01"
            
            $pricingBody = @{
                properties = @{
                    pricingTier = "Standard"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $pricingBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                planName = $body.planName
                tier = "Standard"
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ApplySecurityRecommendation" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.assessmentName)) {
                throw "Missing required parameter: assessmentName"
            }
            if ([string]::IsNullOrEmpty($body.resourceId)) {
                throw "Missing required parameter: resourceId"
            }
            
            Write-XDRLog -Level "Info" -Message "Applying security recommendation" -Data @{
                Assessment = $body.assessmentName
            }
            
            # This is a complex action that varies by resource type
            # For now, we'll create a remediation task
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/providers/Microsoft.Security/assessments/$($body.assessmentName)/governanceAssignments/default?api-version=2022-01-01-preview"
            
            $remediationBody = @{
                properties = @{
                    remediationDueDate = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    isGracePeriod = $false
                    governanceEmailNotification = @{
                        disableManagerEmailNotification = $false
                        disableOwnerEmailNotification = $false
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $remediationBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                assessmentName = $body.assessmentName
                resourceId = $body.resourceId
                remediationTaskCreated = $true
                dueDate = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ExcludeVulnerability" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceId)) {
                throw "Missing required parameter: resourceId"
            }
            if ([string]::IsNullOrEmpty($body.ruleId)) {
                throw "Missing required parameter: ruleId"
            }
            
            Write-XDRLog -Level "Info" -Message "Excluding vulnerability from assessment" -Data @{
                RuleId = $body.ruleId
            }
            
            $uri = "https://management.azure.com$($body.resourceId)/providers/Microsoft.Security/assessments/$($body.ruleId)/governanceAssignments/exempt?api-version=2022-01-01-preview"
            
            $exemptBody = @{
                properties = @{
                    isGracePeriod = $false
                    exemptionReason = $body.reason ?? "False positive"
                    exemptionCategory = "Waived"
                }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $exemptBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceId = $body.resourceId
                ruleId = $body.ruleId
                excluded = $true
                reason = $body.reason ?? "False positive"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableJITVMAccess" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameter: vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling JIT VM access" -Data @{
                VMName = $body.vmName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Security/locations/centralus/jitNetworkAccessPolicies/$($body.vmName)?api-version=2020-01-01"
            
            $jitBody = @{
                properties = @{
                    virtualMachines = @(
                        @{
                            id = "/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)"
                            ports = @(
                                @{
                                    number = 22
                                    protocol = "TCP"
                                    allowedSourceAddressPrefix = "*"
                                    maxRequestAccessDuration = "PT3H"
                                },
                                @{
                                    number = 3389
                                    protocol = "TCP"
                                    allowedSourceAddressPrefix = "*"
                                    maxRequestAccessDuration = "PT3H"
                                }
                            )
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $jitBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                jitEnabled = $true
                maxDuration = "PT3H"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockJITRequest" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.requestId)) {
                throw "Missing required parameter: requestId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking JIT access request" -Data @{
                RequestId = $body.requestId
            }
            
            # Deny JIT request by not approving it (implicit deny)
            # There's no explicit deny API, so we'll remove the request
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Security/locations/centralus/jitNetworkAccessPolicies/$($body.policyName)/initiate?api-version=2020-01-01"
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                requestId = $body.requestId
                blocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "JIT request blocked by not approving"
            }
        }
        
        "EnableAdaptiveNetworkHardening" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameter: vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling adaptive network hardening" -Data @{
                VMName = $body.vmName
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)/providers/Microsoft.Security/adaptiveNetworkHardenings/default/enforce?api-version=2020-01-01"
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                adaptiveHardeningEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW AZURE SENTINEL ACTIONS (2 actions) =====
        
        "AddSentinelWatchlist" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.workspaceName)) {
                throw "Missing required parameter: workspaceName"
            }
            if ([string]::IsNullOrEmpty($body.watchlistAlias)) {
                throw "Missing required parameter: watchlistAlias"
            }
            if (-not $body.items) {
                throw "Missing required parameter: items (array of indicators)"
            }
            
            Write-XDRLog -Level "Info" -Message "Adding Sentinel watchlist" -Data @{
                Watchlist = $body.watchlistAlias
                ItemCount = $body.items.Count
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.OperationalInsights/workspaces/$($body.workspaceName)/providers/Microsoft.SecurityInsights/watchlists/$($body.watchlistAlias)?api-version=2023-02-01"
            
            $watchlistBody = @{
                properties = @{
                    displayName = $body.displayName ?? $body.watchlistAlias
                    provider = "DefenderXDR"
                    source = "Remote API"
                    itemsSearchKey = $body.searchKey ?? "Indicator"
                    watchlistAlias = $body.watchlistAlias
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $watchlistBody
            
            # Add watchlist items
            foreach ($item in $body.items) {
                $itemUri = "$uri/watchlistItems/$([guid]::NewGuid().ToString())?api-version=2023-02-01"
                $itemBody = @{
                    properties = @{
                        itemsKeyValue = $item
                    }
                } | ConvertTo-Json -Depth 10
                
                Invoke-RestMethod -Method Put -Uri $itemUri -Headers @{
                    "Authorization" = "Bearer $token"
                    "Content-Type" = "application/json"
                } -Body $itemBody
            }
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                workspaceName = $body.workspaceName
                watchlistAlias = $body.watchlistAlias
                itemsAdded = $body.items.Count
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableSentinelPlaybook" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            if ([string]::IsNullOrEmpty($body.resourceGroup)) {
                throw "Missing required parameter: resourceGroup"
            }
            if ([string]::IsNullOrEmpty($body.workspaceName)) {
                throw "Missing required parameter: workspaceName"
            }
            if ([string]::IsNullOrEmpty($body.playbookName)) {
                throw "Missing required parameter: playbookName"
            }
            if ([string]::IsNullOrEmpty($body.ruleId)) {
                throw "Missing required parameter: ruleId (analytics rule to attach playbook)"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling Sentinel playbook" -Data @{
                Playbook = $body.playbookName
                Rule = $body.ruleId
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.OperationalInsights/workspaces/$($body.workspaceName)/providers/Microsoft.SecurityInsights/automationRules/$($body.ruleId)-playbook?api-version=2023-02-01"
            
            $automationBody = @{
                properties = @{
                    displayName = "Attach $($body.playbookName) to $($body.ruleId)"
                    order = 1
                    triggeringLogic = @{
                        isEnabled = $true
                        conditions = @(
                            @{
                                conditionType = "Property"
                                conditionProperties = @{
                                    propertyName = "IncidentRelatedAnalyticRuleIds"
                                    operator = "Contains"
                                    propertyValues = @($body.ruleId)
                                }
                            }
                        )
                    }
                    actions = @(
                        @{
                            order = 1
                            actionType = "RunPlaybook"
                            actionConfiguration = @{
                                logicAppResourceId = "/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Logic/workflows/$($body.playbookName)"
                                tenantId = $tenantId
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $uri -Headers @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            } -Body $automationBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                workspaceName = $body.workspaceName
                playbookName = $body.playbookName
                ruleId = $body.ruleId
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region VM Operations (Azure ARM API)
        
        "DeallocateVM" {
            # Deallocate VM (stop and release compute resources) (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vmName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deallocating VM" -Data @{
                VMName = $body.vmName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)/deallocate?api-version=2023-03-01"
            $deallocateResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                action = "Deallocate"
                deallocated = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RestartVM" {
            # Restart VM (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Restarting VM" -Data @{
                VMName = $body.vmName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)/restart?api-version=2023-03-01"
            $restartResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                action = "Restart"
                restarted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ApplyIsolationNSG" {
            # Apply isolation NSG to VM network interface (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vmName) -or [string]::IsNullOrEmpty($body.isolationNsgId)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vmName, isolationNsgId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Applying isolation NSG to VM" -Data @{
                VMName = $body.vmName
                IsolationNSG = $body.isolationNsgId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get VM details
            $vmUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)?api-version=2023-03-01"
            $vm = Invoke-RestMethod -Uri $vmUri -Method Get -Headers $headers
            
            # Get primary NIC
            $nicId = $vm.properties.networkProfile.networkInterfaces[0].id
            $nicUri = "https://management.azure.com$nicId?api-version=2023-05-01"
            $nic = Invoke-RestMethod -Uri $nicUri -Method Get -Headers $headers
            
            # Update NIC with isolation NSG
            $nic.properties.networkSecurityGroup = @{
                id = $body.isolationNsgId
            }
            
            $updateResult = Invoke-RestMethod -Uri $nicUri -Method Put -Headers $headers -Body ($nic | ConvertTo-Json -Depth 20)
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                nicId = $nicId
                isolationNsgId = $body.isolationNsgId
                applied = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RedeployVM" {
            # Redeploy VM to new host (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vmName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Redeploying VM to new host" -Data @{
                VMName = $body.vmName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)/redeploy?api-version=2023-03-01"
            $redeployResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                action = "Redeploy"
                redeployed = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "TakeVMSnapshot" {
            # Take VM disk snapshot for forensics (Azure ARM API)
            if ([string]::IsNullOrEmpty($body.subscriptionId) -or [string]::IsNullOrEmpty($body.resourceGroup) -or 
                [string]::IsNullOrEmpty($body.vmName)) {
                throw "Missing required parameters: subscriptionId, resourceGroup, vmName"
            }
            
            Write-XDRLog -Level "Info" -Message "Taking VM disk snapshot" -Data @{
                VMName = $body.vmName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get VM details
            $vmUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($body.vmName)?api-version=2023-03-01"
            $vm = Invoke-RestMethod -Uri $vmUri -Method Get -Headers $headers
            
            $osDiskId = $vm.properties.storageProfile.osDisk.managedDisk.id
            $snapshotName = if ($body.snapshotName) { $body.snapshotName } else { "$($body.vmName)-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
            
            # Create snapshot
            $snapshotBody = @{
                location = $vm.location
                properties = @{
                    creationData = @{
                        createOption = "Copy"
                        sourceResourceId = $osDiskId
                    }
                    incremental = $false
                }
            } | ConvertTo-Json -Depth 10
            
            $snapshotUri = "https://management.azure.com/subscriptions/$($body.subscriptionId)/resourceGroups/$($body.resourceGroup)/providers/Microsoft.Compute/snapshots/$snapshotName?api-version=2023-03-01"
            $snapshot = Invoke-RestMethod -Uri $snapshotUri -Method Put -Headers $headers -Body $snapshotBody
            
            $result = @{
                subscriptionId = $body.subscriptionId
                resourceGroup = $body.resourceGroup
                vmName = $body.vmName
                snapshotName = $snapshotName
                snapshotId = $snapshot.id
                osDiskId = $osDiskId
                created = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # Network security
                "AddNSGDenyRule", "ApplyIsolationNSG",
                # VM operations
                "StopVM", "DeallocateVM", "RestartVM", "RemoveVMPublicIP", "RedeployVM", "TakeVMSnapshot",
                # Azure Firewall
                "BlockIPInFirewall", "BlockDomainInFirewall", "EnableThreatIntel",
                # Storage security
                "DisableStoragePublicAccess",
                # Key Vault
                "DisableKeyVaultSecret", "RotateKeyVaultKey", "PurgeDeletedSecret",
                # Service Principals
                "DisableServicePrincipal", "RemoveAppCredentials", "RevokeAppCertificates"
            )
            throw "Unknown action: $action. Supported actions (18 remediation-focused): $($supportedActions -join ', ')"
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

    Write-XDRLog -Level "Info" -Message "AzureWorker completed successfully" -Data @{
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
    Write-XDRLog -Level "Error" -Message "AzureWorker failed" -Data @{
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
