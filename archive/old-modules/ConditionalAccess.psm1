# Microsoft Entra ID Conditional Access Module
# Provides conditional access policy and named location management

function New-NamedLocation {
    <#
    .SYNOPSIS
        Creates a new named location (IP-based)
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DisplayName
        Display name for the named location
    
    .PARAMETER IpRanges
        Array of IP ranges in CIDR notation (e.g., "192.168.1.0/24")
    
    .PARAMETER IsTrusted
        Whether the location is trusted
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$IpRanges,
        
        [Parameter(Mandatory=$false)]
        [bool]$IsTrusted = $false
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $ipRangeObjects = $IpRanges | ForEach-Object {
        @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = $_
        }
    }
    
    $body = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        displayName = $DisplayName
        isTrusted = $IsTrusted
        ipRanges = $ipRangeObjects
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Named location created: $DisplayName"
        return $response
    } catch {
        Write-Error "Failed to create named location: $($_.Exception.Message)"
        throw
    }
}

function Update-NamedLocation {
    <#
    .SYNOPSIS
        Updates an existing named location
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER LocationId
        The ID of the named location to update
    
    .PARAMETER DisplayName
        New display name
    
    .PARAMETER IpRanges
        Array of IP ranges in CIDR notation
    
    .PARAMETER IsTrusted
        Whether the location is trusted
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$LocationId,
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$IpRanges,
        
        [Parameter(Mandatory=$false)]
        [bool]$IsTrusted
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations/$LocationId"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
    }
    
    if ($DisplayName) { $body.displayName = $DisplayName }
    if ($IsTrusted -ne $null) { $body.isTrusted = $IsTrusted }
    if ($IpRanges) {
        $body.ipRanges = $IpRanges | ForEach-Object {
            @{
                "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                cidrAddress = $_
            }
        }
    }
    
    $bodyJson = $body | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $bodyJson
        Write-Host "Named location updated: $LocationId"
        return $response
    } catch {
        Write-Error "Failed to update named location: $($_.Exception.Message)"
        throw
    }
}

function New-ConditionalAccessPolicy {
    <#
    .SYNOPSIS
        Creates a new Conditional Access policy
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DisplayName
        Display name for the policy
    
    .PARAMETER State
        Policy state: enabled, disabled, enabledForReportingButNotEnforced
    
    .PARAMETER PolicyDefinition
        Hashtable containing the full policy definition
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("enabled", "disabled", "enabledForReportingButNotEnforced")]
        [string]$State,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$PolicyDefinition
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $PolicyDefinition.displayName = $DisplayName
    $PolicyDefinition.state = $State
    
    $body = $PolicyDefinition | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Conditional Access policy created: $DisplayName"
        return $response
    } catch {
        Write-Error "Failed to create CA policy: $($_.Exception.Message)"
        throw
    }
}

function New-SignInRiskPolicy {
    <#
    .SYNOPSIS
        Creates a sign-in risk-based Conditional Access policy
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DisplayName
        Display name for the policy
    
    .PARAMETER RiskLevels
        Array of risk levels: low, medium, high
    
    .PARAMETER GrantControls
        Array of grant controls: mfa, compliantDevice, domainJoinedDevice
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$RiskLevels = @("high", "medium"),
        
        [Parameter(Mandatory=$false)]
        [string[]]$GrantControls = @("mfa")
    )
    
    $policyDef = @{
        conditions = @{
            users = @{
                includeUsers = @("All")
            }
            signInRiskLevels = $RiskLevels
        }
        grantControls = @{
            operator = "OR"
            builtInControls = $GrantControls
        }
    }
    
    return New-ConditionalAccessPolicy -Token $Token -DisplayName $DisplayName -State "enabled" -PolicyDefinition $policyDef
}

function New-UserRiskPolicy {
    <#
    .SYNOPSIS
        Creates a user risk-based Conditional Access policy
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DisplayName
        Display name for the policy
    
    .PARAMETER RiskLevels
        Array of risk levels: low, medium, high
    
    .PARAMETER RequirePasswordChange
        Whether to require password change
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$RiskLevels = @("high"),
        
        [Parameter(Mandatory=$false)]
        [bool]$RequirePasswordChange = $true
    )
    
    $controls = @("mfa")
    if ($RequirePasswordChange) {
        $controls += "passwordChange"
    }
    
    $policyDef = @{
        conditions = @{
            users = @{
                includeUsers = @("All")
            }
            userRiskLevels = $RiskLevels
        }
        grantControls = @{
            operator = "AND"
            builtInControls = $controls
        }
    }
    
    return New-ConditionalAccessPolicy -Token $Token -DisplayName $DisplayName -State "enabled" -PolicyDefinition $policyDef
}

function Get-NamedLocations {
    <#
    .SYNOPSIS
        Gets all named locations
    
    .PARAMETER Token
        Graph API authentication token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        return $response.value
    } catch {
        Write-Error "Failed to get named locations: $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-NamedLocation',
    'Update-NamedLocation',
    'New-ConditionalAccessPolicy',
    'New-SignInRiskPolicy',
    'New-UserRiskPolicy',
    'Get-NamedLocations'
)
