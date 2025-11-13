# Microsoft Entra ID & Identity Protection Module
# Provides user management and identity protection capabilities

function Set-UserAccountStatus {
    <#
    .SYNOPSIS
        Enables or disables a user account
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER UserId
        User email address or ID
    
    .PARAMETER Enabled
        True to enable, False to disable
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        accountEnabled = $Enabled
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body
        Write-Host "User account $(if($Enabled){'enabled'}else{'disabled'}): $UserId"
        return $response
    } catch {
        Write-Error "Failed to update user account status: $($_.Exception.Message)"
        throw
    }
}

function Reset-UserPassword {
    <#
    .SYNOPSIS
        Resets a user's password
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER UserId
        User email address or ID
    
    .PARAMETER NewPassword
        New password for the user
    
    .PARAMETER ForceChangeNextSignIn
        Force user to change password on next sign-in
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [string]$NewPassword,
        
        [Parameter(Mandatory=$false)]
        [bool]$ForceChangeNextSignIn = $true
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        passwordProfile = @{
            password = $NewPassword
            forceChangePasswordNextSignIn = $ForceChangeNextSignIn
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body
        Write-Host "Password reset for user: $UserId"
        return $response
    } catch {
        Write-Error "Failed to reset password: $($_.Exception.Message)"
        throw
    }
}

function Confirm-UserCompromised {
    <#
    .SYNOPSIS
        Confirms a user as compromised in Identity Protection
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER UserIds
        Array of user IDs (GUIDs) to confirm as compromised
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string[]]$UserIds
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/confirmCompromised"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        userIds = $UserIds
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Users confirmed as compromised: $($UserIds -join ', ')"
        return $response
    } catch {
        Write-Error "Failed to confirm users as compromised: $($_.Exception.Message)"
        throw
    }
}

function Dismiss-UserRisk {
    <#
    .SYNOPSIS
        Dismisses risk for users in Identity Protection
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER UserIds
        Array of user IDs (GUIDs) to dismiss risk
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string[]]$UserIds
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/dismiss"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        userIds = $UserIds
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "User risk dismissed for: $($UserIds -join ', ')"
        return $response
    } catch {
        Write-Error "Failed to dismiss user risk: $($_.Exception.Message)"
        throw
    }
}

function Revoke-UserSessions {
    <#
    .SYNOPSIS
        Revokes all active sessions for a user
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER UserId
        User email address or ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/revokeSignInSessions"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        Write-Host "All sessions revoked for: $UserId"
        return $response
    } catch {
        Write-Error "Failed to revoke user sessions: $($_.Exception.Message)"
        throw
    }
}

function Get-UserRiskDetections {
    <#
    .SYNOPSIS
        Gets risk detections for analysis
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER Filter
        OData filter string
    
    .PARAMETER Top
        Maximum number of results to return
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [int]$Top = 50
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskDetections"
    
    $queryParams = @()
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Top) { $queryParams += "`$top=$Top" }
    
    if ($queryParams.Count -gt 0) {
        $uri += "?" + ($queryParams -join "&")
    }
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        return $response.value
    } catch {
        Write-Error "Failed to get risk detections: $($_.Exception.Message)"
        throw
    }
}

function Get-RiskyUsers {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers"
        Write-Host "Getting risky users from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    }
    catch {
        Write-Error "Failed to get risky users: $($_.Exception.Message)"
        throw
    }
}

function Get-ConditionalAccessPolicies {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
        Write-Host "Getting conditional access policies from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    }
    catch {
        Write-Error "Failed to get conditional access policies: $($_.Exception.Message)"
        throw
    }
}

function Get-NamedLocations {
    <#
    .SYNOPSIS
        Get all named locations (IP-based Conditional Access policies)
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) named locations"
        return $response.value
    } catch {
        Write-Error "Failed to get named locations: $($_.Exception.Message)"
        throw
    }
}

function Add-IPToNamedLocation {
    <#
    .SYNOPSIS
        Add malicious IP/CIDR to a named location for blocking via Conditional Access
    
    .DESCRIPTION
        Creates or updates an IP-based named location to block attacker IPs across all Microsoft 365 services.
        This provides network-level threat containment at the identity layer.
    
    .PARAMETER Token
        Graph API authentication token (string or hashtable)
    
    .PARAMETER LocationName
        Name of the named location (e.g., "Blocked IPs - Threat Response")
    
    .PARAMETER IPAddresses
        Array of IP addresses or CIDR ranges to block (e.g., @("1.2.3.4/32", "5.6.7.0/24"))
    
    .PARAMETER IsTrusted
        Whether the location is trusted (should be $false for blocked IPs)
    
    .EXAMPLE
        Add-IPToNamedLocation -Token $token -LocationName "Blocked Threat IPs" -IPAddresses @("192.168.1.100/32") -IsTrusted $false
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Token,
        
        [Parameter(Mandatory=$true)]
        [string]$LocationName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$IPAddresses,
        
        [Parameter(Mandatory=$false)]
        [bool]$IsTrusted = $false
    )
    
    # Handle both string and hashtable token formats
    $accessToken = if ($Token -is [hashtable]) { $Token.AccessToken } else { $Token }
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    # Check if named location already exists
    $existingLocations = Get-NamedLocations -Token $Token
    $existingLocation = $existingLocations | Where-Object { $_.displayName -eq $LocationName }
    
    if ($existingLocation) {
        # Update existing location - append new IPs
        Write-Host "Updating existing named location: $LocationName"
        
        # Get current IP ranges
        $currentIPs = $existingLocation.ipRanges | ForEach-Object { $_.cidrAddress }
        
        # Merge with new IPs (remove duplicates)
        $allIPs = ($currentIPs + $IPAddresses) | Select-Object -Unique
        
        $ipRanges = $allIPs | ForEach-Object {
            @{ "@odata.type" = "#microsoft.graph.iPv4CidrRange"; cidrAddress = $_ }
        }
        
        $body = @{
            "@odata.type" = "#microsoft.graph.ipNamedLocation"
            displayName = $LocationName
            isTrusted = $IsTrusted
            ipRanges = $ipRanges
        } | ConvertTo-Json -Depth 10
        
        $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations/$($existingLocation.id)"
        
        try {
            $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body
            Write-Host "✅ Added $($IPAddresses.Count) IP(s) to named location '$LocationName' (Total: $($allIPs.Count) IPs)"
            return $response
        } catch {
            Write-Error "Failed to update named location: $($_.Exception.Message)"
            throw
        }
    } else {
        # Create new named location
        Write-Host "Creating new named location: $LocationName"
        
        $ipRanges = $IPAddresses | ForEach-Object {
            @{ "@odata.type" = "#microsoft.graph.iPv4CidrRange"; cidrAddress = $_ }
        }
        
        $body = @{
            "@odata.type" = "#microsoft.graph.ipNamedLocation"
            displayName = $LocationName
            isTrusted = $IsTrusted
            ipRanges = $ipRanges
        } | ConvertTo-Json -Depth 10
        
        $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
        
        try {
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            Write-Host "✅ Created named location '$LocationName' with $($IPAddresses.Count) IP(s)"
            Write-Host "⚠️  Create a Conditional Access policy to BLOCK this named location!"
            return $response
        } catch {
            Write-Error "Failed to create named location: $($_.Exception.Message)"
            throw
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Set-UserAccountStatus',
    'Reset-UserPassword',
    'Confirm-UserCompromised',
    'Dismiss-UserRisk',
    'Revoke-UserSessions',
    'Get-UserRiskDetections',
    'Get-RiskyUsers',
    'Get-ConditionalAccessPolicies',
    'Get-NamedLocations',
    'Add-IPToNamedLocation'
)
