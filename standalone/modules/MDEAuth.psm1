<#
.SYNOPSIS
    Authentication module for MDE Automator Local
    
.DESCRIPTION
    Handles authentication to Microsoft Defender for Endpoint API using App Registration
#>

function Connect-MDE {
    <#
    .SYNOPSIS
        Authenticates to Microsoft Defender for Endpoint API
        
    .PARAMETER TenantId
        Azure AD Tenant ID
        
    .PARAMETER AppId
        Application (Client) ID from App Registration
        
    .PARAMETER ClientSecret
        Client Secret from App Registration (SecureString or plain text)
        
    .EXAMPLE
        $token = Connect-MDE -TenantId "tenant-id" -AppId "app-id" -ClientSecret $secureSecret
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        
        [Parameter(Mandatory = $true)]
        $ClientSecret
    )
    
    try {
        # Convert SecureString to plain text if needed
        if ($ClientSecret -is [SecureString]) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
            $ClientSecretPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        } else {
            $ClientSecretPlain = $ClientSecret
        }
        
        # Prepare OAuth2 request
        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        
        $body = @{
            client_id     = $AppId
            scope         = "https://api.securitycenter.microsoft.com/.default"
            client_secret = $ClientSecretPlain
            grant_type    = "client_credentials"
        }
        
        # Request access token
        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
        
        # Return token object with metadata
        return @{
            AccessToken = $response.access_token
            TokenType   = $response.token_type
            ExpiresIn   = $response.expires_in
            ExpiresAt   = (Get-Date).AddSeconds($response.expires_in)
            TenantId    = $TenantId
        }
        
    } catch {
        Write-Error "Failed to authenticate: $($_.Exception.Message)"
        throw
    }
}

function Test-MDEToken {
    <#
    .SYNOPSIS
        Validates if the MDE token is still valid
        
    .PARAMETER Token
        Token object returned from Connect-MDE
        
    .EXAMPLE
        if (Test-MDEToken -Token $token) { Write-Host "Token is valid" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    if (-not $Token.ExpiresAt) {
        return $false
    }
    
    # Check if token expires in less than 5 minutes
    $now = Get-Date
    $expiresIn = ($Token.ExpiresAt - $now).TotalMinutes
    
    return ($expiresIn -gt 5)
}

function Get-MDEAuthHeaders {
    <#
    .SYNOPSIS
        Creates authentication headers for MDE API requests
        
    .PARAMETER Token
        Token object returned from Connect-MDE
        
    .EXAMPLE
        $headers = Get-MDEAuthHeaders -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    return @{
        'Authorization' = "$($Token.TokenType) $($Token.AccessToken)"
        'Content-Type'  = 'application/json'
    }
}

Export-ModuleMember -Function Connect-MDE, Test-MDEToken, Get-MDEAuthHeaders
