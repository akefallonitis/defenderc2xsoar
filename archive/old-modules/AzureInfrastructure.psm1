# Azure Infrastructure Security Module
# Provides Azure resource security management via Azure REST API

function Get-AzureAccessToken {
    <#
    .SYNOPSIS
        Gets an Azure Resource Manager access token
    
    .PARAMETER TenantId
        Azure AD tenant ID
    
    .PARAMETER AppId
        Application (client) ID
    
    .PARAMETER ClientSecret
        Client secret
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$true)]
        [string]$AppId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )
    
    $body = @{
        client_id     = $AppId
        client_secret = $ClientSecret
        scope         = "https://management.azure.com/.default"
        grant_type    = "client_credentials"
    }
    
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
    
    return $response.access_token
}

function Add-NSGDenyRule {
    <#
    .SYNOPSIS
        Adds a deny rule to a Network Security Group
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER NSGName
        Network Security Group name
    
    .PARAMETER RuleName
        Name for the new rule
    
    .PARAMETER SourceAddressPrefix
        Source address prefix (IP, CIDR, or tag)
    
    .PARAMETER DestinationPortRange
        Destination port range (e.g., "3389" or "80-443")
    
    .PARAMETER Priority
        Rule priority (100-4096)
    
    .PARAMETER Protocol
        Protocol: Tcp, Udp, or * for all
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$NSGName,
        
        [Parameter(Mandatory=$true)]
        [string]$RuleName,
        
        [Parameter(Mandatory=$true)]
        [string]$SourceAddressPrefix,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPortRange,
        
        [Parameter(Mandatory=$true)]
        [int]$Priority,
        
        [Parameter(Mandatory=$false)]
        [string]$Protocol = "*"
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/networkSecurityGroups/$NSGName/securityRules/$RuleName`?api-version=2023-05-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        properties = @{
            protocol = $Protocol
            sourceAddressPrefix = $SourceAddressPrefix
            destinationAddressPrefix = "*"
            access = "Deny"
            direction = "Inbound"
            sourcePortRange = "*"
            destinationPortRange = $DestinationPortRange
            priority = $Priority
        }
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body
        Write-Host "NSG deny rule added: $RuleName"
        return $response
    } catch {
        Write-Error "Failed to add NSG rule: $($_.Exception.Message)"
        throw
    }
}

function Stop-AzureVM {
    <#
    .SYNOPSIS
        Stops and deallocates an Azure VM
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER VMName
        Virtual machine name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/deallocate?api-version=2023-03-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        Write-Host "VM stop initiated: $VMName"
        return $response
    } catch {
        Write-Error "Failed to stop VM: $($_.Exception.Message)"
        throw
    }
}

function Disable-StorageAccountPublicAccess {
    <#
    .SYNOPSIS
        Disables public network access to a storage account
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER StorageAccountName
        Storage account name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName`?api-version=2023-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        properties = @{
            publicNetworkAccess = "Disabled"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body
        Write-Host "Storage account public access disabled: $StorageAccountName"
        return $response
    } catch {
        Write-Error "Failed to disable storage public access: $($_.Exception.Message)"
        throw
    }
}

function Remove-VMPublicIP {
    <#
    .SYNOPSIS
        Removes public IP from a VM's network interface
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER NetworkInterfaceName
        Network interface name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$NetworkInterfaceName
    )
    
    # First, get the current NIC configuration
    $getUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/networkInterfaces/$NetworkInterfaceName`?api-version=2023-05-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $nic = Invoke-RestMethod -Method Get -Uri $getUri -Headers $headers
        
        # Remove public IP from the first IP configuration
        if ($nic.properties.ipConfigurations[0].properties.publicIPAddress) {
            $nic.properties.ipConfigurations[0].properties.publicIPAddress = $null
            
            $updateUri = $getUri
            $body = $nic | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Method Put -Uri $updateUri -Headers $headers -Body $body
            Write-Host "Public IP removed from NIC: $NetworkInterfaceName"
            return $response
        } else {
            Write-Host "No public IP assigned to NIC: $NetworkInterfaceName"
            return $nic
        }
    } catch {
        Write-Error "Failed to remove public IP: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureVMs {
    <#
    .SYNOPSIS
        Gets all Azure VMs in a subscription or resource group
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Optional resource group name to filter
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceGroupName
    )
    
    if ($ResourceGroupName) {
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines?api-version=2023-03-01"
    } else {
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Compute/virtualMachines?api-version=2023-03-01"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        return $response.value
    } catch {
        Write-Error "Failed to get Azure VMs: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureResourceGroups {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups?api-version=2021-04-01"
        Write-Host "Getting resource groups from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    } catch {
        Write-Error "Failed to get resource groups: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureNSGs {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/networkSecurityGroups?api-version=2021-02-01"
        Write-Host "Getting NSGs from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    } catch {
        Write-Error "Failed to get NSGs: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureStorageAccounts {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts?api-version=2021-04-01"
        Write-Host "Getting storage accounts from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    } catch {
        Write-Error "Failed to get storage accounts: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureKeyVaults {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.KeyVault/vaults?api-version=2021-06-01-preview"
        Write-Host "Getting key vaults from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    } catch {
        Write-Error "Failed to get key vaults: $($_.Exception.Message)"
        throw
    }
}

# ============================================================================
# DEFENDER FOR CLOUD (MDC) INFRASTRUCTURE FUNCTIONS
# Consolidated from DefenderForCloud.psm1 - Infrastructure-specific actions
# Alert retrieval moved to unified Graph API security/alerts_v2
# ============================================================================

function Get-DefenderSecurityRecommendations {
    <#
    .SYNOPSIS
        Gets security recommendations from Microsoft Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) security recommendations"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve security recommendations: $($_.Exception.Message)"
        throw
    }
}

function Get-DefenderSecureScore {
    <#
    .SYNOPSIS
        Gets Microsoft Defender for Cloud secure score
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/secureScores?api-version=2020-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved secure score for subscription"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve secure score: $($_.Exception.Message)"
        throw
    }
}

function Get-DefenderPlans {
    <#
    .SYNOPSIS
        Gets all Defender for Cloud plans and their status
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/pricings?api-version=2024-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) Defender plans"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve Defender plans: $($_.Exception.Message)"
        throw
    }
}

function Enable-DefenderPlan {
    <#
    .SYNOPSIS
        Enables a specific Defender plan in Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER PlanName
        Plan name: VirtualMachines, SqlServers, AppServices, StorageAccounts, etc.
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$PlanName
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/pricings/$PlanName`?api-version=2024-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        properties = @{
            pricingTier = "Standard"
        }
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body
        Write-Host "Enabled Defender plan: $PlanName"
        return $response
    } catch {
        Write-Error "Failed to enable Defender plan: $($_.Exception.Message)"
        throw
    }
}

function Get-DefenderRegulatoryCompliance {
    <#
    .SYNOPSIS
        Gets regulatory compliance assessment from Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/regulatoryComplianceStandards?api-version=2019-01-01-preview"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) compliance standards"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve regulatory compliance: $($_.Exception.Message)"
        throw
    }
}

function Get-JitAccessPolicies {
    <#
    .SYNOPSIS
        Gets Just-in-Time (JIT) VM access policies
    
    .PARAMETER Token
        Azure Resource Manager access token (hashtable)
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/jitNetworkAccessPolicies?api-version=2020-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) JIT access policies"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve JIT policies: $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-AzureAccessToken',
    'Add-NSGDenyRule',
    'Stop-AzureVM',
    'Disable-StorageAccountPublicAccess',
    'Remove-VMPublicIP',
    'Get-AzureVMs',
    'Get-AzureResourceGroups',
    'Get-AzureNSGs',
    'Get-AzureStorageAccounts',
    'Get-AzureKeyVaults',
    'Get-DefenderSecurityRecommendations',
    'Get-DefenderSecureScore',
    'Get-DefenderPlans',
    'Enable-DefenderPlan',
    'Get-DefenderRegulatoryCompliance',
    'Get-JitAccessPolicies'
)
