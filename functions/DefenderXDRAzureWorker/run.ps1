using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/Azure.psm1" -Force

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
        
        "GetVMs" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting Azure VMs" -Data @{
                SubscriptionId = $body.subscriptionId
            }
            
            $vmListParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
            }
            
            if ($body.resourceGroup) {
                $vmListParams.ResourceGroup = $body.resourceGroup
            }
            
            $vms = Get-AzureVMs @vmListParams
            $result = @{
                count = $vms.Count
                vms = $vms
            }
        }
        
        "GetResourceGroups" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting resource groups"
            $rgParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
            }
            
            $resourceGroups = Get-AzureResourceGroups @rgParams
            $result = @{
                count = $resourceGroups.Count
                resourceGroups = $resourceGroups
            }
        }
        
        "GetNSGs" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting network security groups"
            $nsgListParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
            }
            
            if ($body.resourceGroup) {
                $nsgListParams.ResourceGroup = $body.resourceGroup
            }
            
            $nsgs = Get-AzureNSGs @nsgListParams
            $result = @{
                count = $nsgs.Count
                nsgs = $nsgs
            }
        }
        
        "GetStorageAccounts" {
            if ([string]::IsNullOrEmpty($body.subscriptionId)) {
                throw "Missing required parameter: subscriptionId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting storage accounts"
            $storageListParams = @{
                Token = $token
                SubscriptionId = $body.subscriptionId
            }
            
            if ($body.resourceGroup) {
                $storageListParams.ResourceGroup = $body.resourceGroup
            }
            
            $storageAccounts = Get-AzureStorageAccounts @storageListParams
            $result = @{
                count = $storageAccounts.Count
                storageAccounts = $storageAccounts
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
                # Original actions
                "AddNSGDenyRule", "StopVM", "DisableStoragePublicAccess", "RemoveVMPublicIP",
                "GetVMs", "GetResourceGroups", "GetNSGs", "GetStorageAccounts",
                # Azure Firewall (NEW)
                "BlockIPInFirewall", "BlockDomainInFirewall", "EnableThreatIntel",
                # Key Vault (NEW)
                "DisableKeyVaultSecret", "RotateKeyVaultKey", "PurgeDeletedSecret",
                # Service Principals (NEW)
                "DisableServicePrincipal", "RemoveAppCredentials", "RevokeAppCertificates",
                # VM Operations (NEW)
                "DeallocateVM", "RestartVM", "ApplyIsolationNSG", "RedeployVM", "TakeVMSnapshot"
            )
            throw "Unknown action: $action. Supported actions: $($supportedActions -join ', ')"
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
