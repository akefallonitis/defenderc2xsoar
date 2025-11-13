<#
.SYNOPSIS
    Centralized Authentication Manager for DefenderXDRC2XSOAR
    
.DESCRIPTION
    Handles authentication to all Microsoft security APIs with token caching,
    automatic refresh, and multi-tenant support.
    
    Supported Services:
    - MDE (Microsoft Defender for Endpoint)
    - Graph (Microsoft Graph API - MDO, Entra ID, Intune)
    - Azure (Azure Resource Manager)
    - MDC (Microsoft Defender for Cloud)
    - MDI (Microsoft Defender for Identity)
#>

# Global token cache with expiration tracking
if (-not $global:DefenderXDRTokenCache) {
    $global:DefenderXDRTokenCache = @{}
}

function Get-TokenCacheKey {
    <#
    .SYNOPSIS
        Generates a unique cache key for tenant + service + app combination
    #>
    param(
        [string]$TenantId,
        [string]$Service,
        [string]$AppId
    )
    
    return "$TenantId|$Service|$AppId"
}

function Test-TokenValid {
    <#
    .SYNOPSIS
        Checks if a cached token is still valid (5 minute buffer)
    #>
    param(
        [hashtable]$TokenInfo
    )
    
    if (-not $TokenInfo -or -not $TokenInfo.ExpiresAt) {
        return $false
    }
    
    $now = Get-Date
    $expiresIn = ($TokenInfo.ExpiresAt - $now).TotalMinutes
    
    return ($expiresIn -gt 5)
}

function Get-OAuthToken {
    <#
    .SYNOPSIS
        Gets OAuth token for specified service with automatic caching
        
    .PARAMETER TenantId
        Azure AD Tenant ID
        
    .PARAMETER AppId
        Application (Client) ID from App Registration (optional for Azure service with Managed Identity)
        
    .PARAMETER ClientSecret
        Client Secret from App Registration (optional for Azure service with Managed Identity)
        
    .PARAMETER Service
        Target service: MDE, Graph, Azure, MDC, MDI
        
    .PARAMETER UseManagedIdentity
        Use Managed Identity instead of App Registration (only for Azure service)
        
    .PARAMETER ForceRefresh
        Force token refresh even if cached token is valid
        
    .EXAMPLE
        # App Registration auth
        $token = Get-OAuthToken -TenantId "tenant-id" -AppId "app-id" -ClientSecret "secret" -Service "MDE"
        
    .EXAMPLE
        # Managed Identity auth (Azure only)
        $token = Get-OAuthToken -Service "Azure" -UseManagedIdentity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$AppId,
        
        [Parameter(Mandatory = $false)]
        $ClientSecret,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("MDE", "Graph", "Azure", "MDC", "MDI")]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseManagedIdentity,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )
    
    try {
        # Managed Identity authentication (Azure only)
        if ($UseManagedIdentity) {
            if ($Service -ne "Azure" -and $Service -ne "MDC") {
                throw "Managed Identity authentication only supported for Azure/MDC service (Azure RM API)"
            }
            
            Write-Verbose "Requesting Managed Identity token for $Service"
            
            $resource = if ($Service -eq "Azure" -or $Service -eq "MDC") {
                "https://management.azure.com"
            }
            
            $apiVersion = "2019-08-01"
            $msiEndpoint = $env:IDENTITY_ENDPOINT
            $msiSecret = $env:IDENTITY_HEADER
            
            if (-not $msiEndpoint) {
                throw "Managed Identity not available. IDENTITY_ENDPOINT environment variable not set."
            }
            
            $tokenUri = "$($msiEndpoint)?resource=$resource&api-version=$apiVersion"
            $headers = @{ "X-IDENTITY-HEADER" = $msiSecret }
            
            $response = Invoke-RestMethod -Method Get -Uri $tokenUri -Headers $headers
            
            # Cache the token
            $cacheKey = "ManagedIdentity|$Service"
            $tokenInfo = @{
                AccessToken = $response.access_token
                TokenType   = "Bearer"
                ExpiresIn   = $response.expires_in
                ExpiresAt   = (Get-Date).AddSeconds([int]$response.expires_in)
                Service     = $Service
                AuthMethod  = "ManagedIdentity"
            }
            
            $global:DefenderXDRTokenCache[$cacheKey] = $tokenInfo
            Write-Verbose "Managed Identity token acquired (expires in $([int](($tokenInfo.ExpiresAt - (Get-Date)).TotalMinutes)) minutes)"
            
            return $response.access_token
        }
        
        # App Registration authentication (all services)
        if (-not $TenantId -or -not $AppId -or -not $ClientSecret) {
            throw "TenantId, AppId, and ClientSecret are required for App Registration authentication"
        }
        
        # Check cache first
        $cacheKey = Get-TokenCacheKey -TenantId $TenantId -Service $Service -AppId $AppId
        
        if (-not $ForceRefresh -and $global:DefenderXDRTokenCache.ContainsKey($cacheKey)) {
            $cachedToken = $global:DefenderXDRTokenCache[$cacheKey]
            if (Test-TokenValid -TokenInfo $cachedToken) {
                Write-Verbose "Using cached token for $Service (expires in $([int](($cachedToken.ExpiresAt - (Get-Date)).TotalMinutes)) minutes)"
                return $cachedToken.AccessToken
            }
        }
        
        # Convert SecureString to plain text if needed
        if ($ClientSecret -is [SecureString]) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
            $ClientSecretPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        } else {
            $ClientSecretPlain = $ClientSecret
        }
        
        # Define scopes for each service
        $scopes = @{
            "MDE"   = "https://api.securitycenter.microsoft.com/.default"
            "Graph" = "https://graph.microsoft.com/.default"
            "Azure" = "https://management.azure.com/.default"
            "MDC"   = "https://management.azure.com/.default"  # MDC uses Azure RM
            "MDI"   = "https://graph.microsoft.com/.default"    # MDI uses Graph API
        }
        
        # Prepare OAuth2 request
        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        
        $body = @{
            client_id     = $AppId
            scope         = $scopes[$Service]
            client_secret = $ClientSecretPlain
            grant_type    = "client_credentials"
        }
        
        # Request access token
        Write-Verbose "Requesting new token for $Service via App Registration"
        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
        
        # Cache the token
        $tokenInfo = @{
            AccessToken = $response.access_token
            TokenType   = $response.token_type
            ExpiresIn   = $response.expires_in
            ExpiresAt   = (Get-Date).AddSeconds($response.expires_in)
            TenantId    = $TenantId
            Service     = $Service
        }
        
        $global:DefenderXDRTokenCache[$cacheKey] = $tokenInfo
        
        Write-Verbose "New token cached for $Service (expires at $($tokenInfo.ExpiresAt))"
        
        return $response.access_token
        
    } catch {
        Write-Error "Failed to authenticate to $Service : $($_.Exception.Message)"
        throw
    }
}

function Connect-DefenderXDR {
    <#
    .SYNOPSIS
        Universal authentication function for all Defender XDR services
        
    .PARAMETER TenantId
        Azure AD Tenant ID
        
    .PARAMETER AppId
        Application (Client) ID
        
    .PARAMETER ClientSecret
        Client Secret
        
    .PARAMETER Services
        Array of services to authenticate to (MDE, Graph, Azure, MDC, MDI)
        
    .EXAMPLE
        $tokens = Connect-DefenderXDR -TenantId "tid" -AppId "aid" -ClientSecret "secret" -Services @("MDE", "Graph")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        
        [Parameter(Mandatory = $true)]
        $ClientSecret,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("MDE", "Graph", "Azure", "MDC", "MDI")]
        [string[]]$Services = @("MDE", "Graph", "Azure")
    )
    
    $tokens = @{}
    
    foreach ($service in $Services) {
        try {
            $token = Get-OAuthToken -TenantId $TenantId -AppId $AppId -ClientSecret $ClientSecret -Service $service
            $tokens[$service] = $token
            Write-Host "✅ Authenticated to $service" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to authenticate to $service : $($_.Exception.Message)"
        }
    }
    
    return $tokens
}

function Get-AuthHeaders {
    <#
    .SYNOPSIS
        Creates authentication headers for API requests
        
    .PARAMETER Token
        Access token string
        
    .PARAMETER ContentType
        Content-Type header (default: application/json)
        
    .EXAMPLE
        $headers = Get-AuthHeaders -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $false)]
        [string]$ContentType = "application/json"
    )
    
    return @{
        'Authorization' = "Bearer $Token"
        'Content-Type'  = $ContentType
    }
}

function Clear-TokenCache {
    <#
    .SYNOPSIS
        Clears the token cache (useful for testing or forced re-authentication)
        
    .PARAMETER TenantId
        Optional: Clear only tokens for specific tenant
        
    .PARAMETER Service
        Optional: Clear only tokens for specific service
        
    .EXAMPLE
        Clear-TokenCache
        Clear-TokenCache -TenantId "tenant-id"
        Clear-TokenCache -Service "MDE"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("MDE", "Graph", "Azure", "MDC", "MDI")]
        [string]$Service
    )
    
    if (-not $TenantId -and -not $Service) {
        # Clear all
        $global:DefenderXDRTokenCache = @{}
        Write-Host "✅ Cleared entire token cache"
    } elseif ($TenantId -and $Service) {
        # Clear specific tenant + service
        $keysToRemove = $global:DefenderXDRTokenCache.Keys | Where-Object { $_ -like "$TenantId|$Service|*" }
        foreach ($key in $keysToRemove) {
            $global:DefenderXDRTokenCache.Remove($key)
        }
        Write-Host "✅ Cleared token cache for $TenantId / $Service"
    } elseif ($TenantId) {
        # Clear all services for tenant
        $keysToRemove = $global:DefenderXDRTokenCache.Keys | Where-Object { $_ -like "$TenantId|*" }
        foreach ($key in $keysToRemove) {
            $global:DefenderXDRTokenCache.Remove($key)
        }
        Write-Host "✅ Cleared token cache for tenant $TenantId"
    } elseif ($Service) {
        # Clear service across all tenants
        $keysToRemove = $global:DefenderXDRTokenCache.Keys | Where-Object { $_ -like "*|$Service|*" }
        foreach ($key in $keysToRemove) {
            $global:DefenderXDRTokenCache.Remove($key)
        }
        Write-Host "✅ Cleared token cache for service $Service"
    }
}

function Get-TokenCacheStats {
    <#
    .SYNOPSIS
        Gets statistics about current token cache
        
    .EXAMPLE
        Get-TokenCacheStats
    #>
    [CmdletBinding()]
    param()
    
    $stats = @{
        TotalCachedTokens = $global:DefenderXDRTokenCache.Count
        ValidTokens = 0
        ExpiredTokens = 0
        Tokens = @()
    }
    
    foreach ($key in $global:DefenderXDRTokenCache.Keys) {
        $tokenInfo = $global:DefenderXDRTokenCache[$key]
        $isValid = Test-TokenValid -TokenInfo $tokenInfo
        
        if ($isValid) {
            $stats.ValidTokens++
        } else {
            $stats.ExpiredTokens++
        }
        
        $stats.Tokens += @{
            CacheKey = $key
            Service = $tokenInfo.Service
            TenantId = $tokenInfo.TenantId
            ExpiresAt = $tokenInfo.ExpiresAt
            IsValid = $isValid
        }
    }
    
    return $stats
}

# Backward compatibility wrappers for existing code

function Connect-MDE {
    <#
    .SYNOPSIS
        Connects to Microsoft Defender for Endpoint (backward compatible)
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
    
    $token = Get-OAuthToken -TenantId $TenantId -AppId $AppId -ClientSecret $ClientSecret -Service "MDE"
    
    # Return in legacy format for compatibility
    return @{
        AccessToken = $token
        TokenType   = "Bearer"
        ExpiresIn   = 3600
        ExpiresAt   = (Get-Date).AddHours(1)
        TenantId    = $TenantId
    }
}

function Get-GraphToken {
    <#
    .SYNOPSIS
        Gets Microsoft Graph API token (backward compatible)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$true)]
        [string]$AppId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )
    
    return Get-OAuthToken -TenantId $TenantId -AppId $AppId -ClientSecret $ClientSecret -Service "Graph"
}

function Get-AzureAccessToken {
    <#
    .SYNOPSIS
        Gets Azure Resource Manager token (backward compatible)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$true)]
        [string]$AppId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )
    
    return Get-OAuthToken -TenantId $TenantId -AppId $AppId -ClientSecret $ClientSecret -Service "Azure"
}

function Test-MDEToken {
    <#
    .SYNOPSIS
        Validates if the MDE token is still valid (backward compatible)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    return Test-TokenValid -TokenInfo $Token
}

function Get-MDEAuthHeaders {
    <#
    .SYNOPSIS
        Creates authentication headers for MDE API requests (backward compatible)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    return Get-AuthHeaders -Token $Token.AccessToken
}

Export-ModuleMember -Function @(
    # New centralized functions
    'Get-OAuthToken',
    'Connect-DefenderXDR',
    'Get-AuthHeaders',
    'Clear-TokenCache',
    'Get-TokenCacheStats',
    
    # Backward compatible functions
    'Connect-MDE',
    'Get-GraphToken',
    'Get-AzureAccessToken',
    'Test-MDEToken',
    'Get-MDEAuthHeaders'
)
