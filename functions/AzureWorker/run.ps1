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
        
        default {
            throw "Unknown action: $action. Supported actions: AddNSGDenyRule, StopVM, DisableStoragePublicAccess, RemoveVMPublicIP, GetVMs, GetResourceGroups, GetNSGs, GetStorageAccounts"
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
