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

# Export functions
Export-ModuleMember -Function @(
    'Get-AzureAccessToken',
    'Add-NSGDenyRule',
    'Stop-AzureVM',
    'Disable-StorageAccountPublicAccess',
    'Remove-VMPublicIP',
    'Get-AzureVMs'
)
