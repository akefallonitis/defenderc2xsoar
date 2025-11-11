# Microsoft Entra ID & Identity Protection Module
# Provides user management and identity protection capabilities

function Set-UserAccountStatus {
    <#
    .SYNOPSIS
        Enables or disables a user account
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER UserId
        User email address or ID
    
    .PARAMETER Enabled
        True to enable, False to disable
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId"
    $headers = @{
        "Authorization" = "Bearer $Token"
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
        Graph API authentication token
    
    .PARAMETER UserId
        User email address or ID
    
    .PARAMETER NewPassword
        New password for the user
    
    .PARAMETER ForceChangeNextSignIn
        Force user to change password on next sign-in
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId,
        
        [Parameter(Mandatory=$true)]
        [string]$NewPassword,
        
        [Parameter(Mandatory=$false)]
        [bool]$ForceChangeNextSignIn = $true
    )
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId"
    $headers = @{
        "Authorization" = "Bearer $Token"
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
        Graph API authentication token
    
    .PARAMETER UserIds
        Array of user IDs (GUIDs) to confirm as compromised
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string[]]$UserIds
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/confirmCompromised"
    $headers = @{
        "Authorization" = "Bearer $Token"
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
        Graph API authentication token
    
    .PARAMETER UserIds
        Array of user IDs (GUIDs) to dismiss risk
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string[]]$UserIds
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/dismiss"
    $headers = @{
        "Authorization" = "Bearer $Token"
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
        Graph API authentication token
    
    .PARAMETER UserId
        User email address or ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId
    )
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/revokeSignInSessions"
    $headers = @{
        "Authorization" = "Bearer $Token"
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
        Graph API authentication token
    
    .PARAMETER Filter
        OData filter string
    
    .PARAMETER Top
        Maximum number of results to return
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [int]$Top = 50
    )
    
    $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskDetections"
    
    $queryParams = @()
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Top) { $queryParams += "`$top=$Top" }
    
    if ($queryParams.Count -gt 0) {
        $uri += "?" + ($queryParams -join "&")
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
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

# Export functions
Export-ModuleMember -Function @(
    'Set-UserAccountStatus',
    'Reset-UserPassword',
    'Confirm-UserCompromised',
    'Dismiss-UserRisk',
    'Revoke-UserSessions',
    'Get-UserRiskDetections'
)
