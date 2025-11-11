# Microsoft Defender for Cloud (MDC) Module
# Provides cloud security posture management, threat protection, and compliance operations

function Get-MDCSecurityAlerts {
    <#
    .SYNOPSIS
        Retrieves security alerts from Microsoft Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER Filter
        OData filter query
    
    .PARAMETER Top
        Number of results to return (default: 100)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [int]$Top = 100
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/alerts?api-version=2022-01-01"
    
    if ($Filter) {
        $uri += "&`$filter=$Filter"
    }
    
    $uri += "&`$top=$Top"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) MDC security alerts"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve MDC security alerts: $($_.Exception.Message)"
        throw
    }
}

function Update-MDCSecurityAlert {
    <#
    .SYNOPSIS
        Updates the status of a Defender for Cloud security alert
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER AlertName
        Alert name (resource name)
    
    .PARAMETER Status
        New alert status: Active, InProgress, Dismissed, Resolved
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$AlertName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Active", "InProgress", "Dismissed", "Resolved")]
        [string]$Status
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Security/locations/centralus/alerts/$AlertName/updateState?api-version=2022-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        state = $Status
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Updated MDC alert $AlertName to status: $Status"
        return $response
    } catch {
        Write-Error "Failed to update MDC alert: $($_.Exception.Message)"
        throw
    }
}

function Get-MDCSecurityRecommendations {
    <#
    .SYNOPSIS
        Retrieves security recommendations from Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER Filter
        OData filter (e.g., "properties/state eq 'Active'")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/assessments?api-version=2020-01-01"
    
    if ($Filter) {
        $uri += "&`$filter=$Filter"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
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

function Get-MDCSecureScore {
    <#
    .SYNOPSIS
        Gets the Microsoft Secure Score for a subscription
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/secureScores?api-version=2020-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
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

function Get-MDCRegulatoryCompliance {
    <#
    .SYNOPSIS
        Gets regulatory compliance assessment
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER Standard
        Compliance standard name (e.g., "Azure-CIS-1.3.0", "PCI-DSS-3.2.1")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$false)]
        [string]$Standard
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/regulatoryComplianceStandards?api-version=2019-01-01-preview"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        if ($Standard) {
            $filtered = $response.value | Where-Object { $_.name -eq $Standard }
            return $filtered
        }
        
        Write-Host "Retrieved $($response.value.Count) compliance standards"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve regulatory compliance: $($_.Exception.Message)"
        throw
    }
}

function Enable-MDCDefenderPlan {
    <#
    .SYNOPSIS
        Enables a specific Defender plan in Defender for Cloud
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER PlanName
        Plan name: VirtualMachines, SqlServers, AppServices, StorageAccounts, 
                   KeyVaults, Containers, Arm, Dns, OpenSourceRelationalDatabases
    
    .PARAMETER PricingTier
        Pricing tier: Standard (enabled) or Free (disabled)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("VirtualMachines", "SqlServers", "AppServices", "StorageAccounts", 
                     "KeyVaults", "Containers", "Arm", "Dns", "OpenSourceRelationalDatabases")]
        [string]$PlanName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Standard", "Free")]
        [string]$PricingTier
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/pricings/$PlanName`?api-version=2024-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        properties = @{
            pricingTier = $PricingTier
        }
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body
        Write-Host "Set Defender plan $PlanName to $PricingTier tier"
        return $response
    } catch {
        Write-Error "Failed to update Defender plan: $($_.Exception.Message)"
        throw
    }
}

function Get-MDCDefenderPlans {
    <#
    .SYNOPSIS
        Gets all Defender for Cloud plans and their status
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/pricings?api-version=2024-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
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

function Set-MDCAutoProvisioning {
    <#
    .SYNOPSIS
        Configures auto-provisioning of security agents
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER SettingName
        Setting name: default (Log Analytics agent)
    
    .PARAMETER AutoProvision
        Enable or disable auto-provisioning
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$false)]
        [string]$SettingName = "default",
        
        [Parameter(Mandatory=$true)]
        [bool]$AutoProvision
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/autoProvisioningSettings/$SettingName`?api-version=2017-08-01-preview"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $autoProvisionValue = if ($AutoProvision) { "On" } else { "Off" }
    
    $body = @{
        properties = @{
            autoProvision = $autoProvisionValue
        }
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body
        Write-Host "Set auto-provisioning to: $autoProvisionValue"
        return $response
    } catch {
        Write-Error "Failed to update auto-provisioning: $($_.Exception.Message)"
        throw
    }
}

function Get-MDCJitAccessPolicy {
    <#
    .SYNOPSIS
        Gets Just-in-Time (JIT) VM access policies
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Optional: Filter by resource group
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
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Security/locations/centralus/jitNetworkAccessPolicies?api-version=2020-01-01"
    } else {
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/jitNetworkAccessPolicies?api-version=2020-01-01"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
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

function New-MDCJitAccessRequest {
    <#
    .SYNOPSIS
        Requests Just-in-Time VM access
    
    .PARAMETER Token
        Azure Resource Manager access token
    
    .PARAMETER SubscriptionId
        Azure subscription ID
    
    .PARAMETER ResourceGroupName
        Resource group name
    
    .PARAMETER Location
        Azure location
    
    .PARAMETER PolicyName
        JIT policy name
    
    .PARAMETER VirtualMachineId
        Full resource ID of the VM
    
    .PARAMETER Port
        Port number to allow
    
    .PARAMETER Duration
        Access duration in ISO 8601 format (e.g., "PT3H" for 3 hours)
    
    .PARAMETER AllowedSourceAddress
        Source IP address or CIDR to allow
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory=$true)]
        [string]$Location,
        
        [Parameter(Mandatory=$true)]
        [string]$PolicyName,
        
        [Parameter(Mandatory=$true)]
        [string]$VirtualMachineId,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [string]$Duration = "PT3H",
        
        [Parameter(Mandatory=$true)]
        [string]$AllowedSourceAddress
    )
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Security/locations/$Location/jitNetworkAccessPolicies/$PolicyName/initiate?api-version=2020-01-01"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        virtualMachines = @(
            @{
                id = $VirtualMachineId
                ports = @(
                    @{
                        number = $Port
                        duration = $Duration
                        allowedSourceAddressPrefix = $AllowedSourceAddress
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "JIT access request initiated for VM on port $Port"
        return $response
    } catch {
        Write-Error "Failed to request JIT access: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function @(
    'Get-MDCSecurityAlerts',
    'Update-MDCSecurityAlert',
    'Get-MDCSecurityRecommendations',
    'Get-MDCSecureScore',
    'Get-MDCRegulatoryCompliance',
    'Enable-MDCDefenderPlan',
    'Get-MDCDefenderPlans',
    'Set-MDCAutoProvisioning',
    'Get-MDCJitAccessPolicy',
    'New-MDCJitAccessRequest'
)
