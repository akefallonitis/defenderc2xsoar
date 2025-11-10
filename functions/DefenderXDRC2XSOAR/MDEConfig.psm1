<#
.SYNOPSIS
    Configuration management module for DefenderXDR C2 XSOAR
    
.DESCRIPTION
    Handles saving and loading configuration securely
#>

function Get-ConfigPath {
    <#
    .SYNOPSIS
        Returns the path to the configuration file
    #>
    [CmdletBinding()]
    param()
    
    $configDir = Join-Path $env:USERPROFILE ".defenderxdrc2xsoar"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    return Join-Path $configDir "config.json"
}

function Save-MDEConfiguration {
    <#
    .SYNOPSIS
        Saves MDE configuration securely
        
    .PARAMETER Config
        Configuration hashtable containing TenantId, AppId, and ClientSecret
        
    .EXAMPLE
        Save-MDEConfiguration -Config @{ TenantId = "..."; AppId = "..."; ClientSecret = $secureString }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    try {
        $configPath = Get-ConfigPath
        
        # Convert SecureString to encrypted string
        if ($Config.ClientSecret -is [SecureString]) {
            $encryptedSecret = ConvertFrom-SecureString -SecureString $Config.ClientSecret
        } else {
            $secureSecret = ConvertTo-SecureString -String $Config.ClientSecret -AsPlainText -Force
            $encryptedSecret = ConvertFrom-SecureString -SecureString $secureSecret
        }
        
        $configData = @{
            TenantId            = $Config.TenantId
            AppId               = $Config.AppId
            EncryptedSecret     = $encryptedSecret
            LastModified        = (Get-Date).ToString("o")
        }
        
        $configData | ConvertTo-Json | Set-Content -Path $configPath -Force
        
        Write-Verbose "Configuration saved to $configPath"
        
    } catch {
        Write-Error "Failed to save configuration: $($_.Exception.Message)"
        throw
    }
}

function Get-MDEConfiguration {
    <#
    .SYNOPSIS
        Loads MDE configuration
        
    .EXAMPLE
        $config = Get-MDEConfiguration
    #>
    [CmdletBinding()]
    param()
    
    try {
        $configPath = Get-ConfigPath
        
        if (-not (Test-Path $configPath)) {
            Write-Verbose "No configuration file found"
            return $null
        }
        
        $configData = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        
        # Convert encrypted string back to SecureString
        $clientSecret = ConvertTo-SecureString -String $configData.EncryptedSecret
        
        return @{
            TenantId     = $configData.TenantId
            AppId        = $configData.AppId
            ClientSecret = $clientSecret
            LastModified = $configData.LastModified
        }
        
    } catch {
        Write-Error "Failed to load configuration: $($_.Exception.Message)"
        return $null
    }
}

function Remove-MDEConfiguration {
    <#
    .SYNOPSIS
        Removes saved MDE configuration
        
    .EXAMPLE
        Remove-MDEConfiguration
    #>
    [CmdletBinding()]
    param()
    
    try {
        $configPath = Get-ConfigPath
        
        if (Test-Path $configPath) {
            Remove-Item -Path $configPath -Force
            Write-Verbose "Configuration removed from $configPath"
        }
        
    } catch {
        Write-Error "Failed to remove configuration: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Save-MDEConfiguration, Get-MDEConfiguration, Remove-MDEConfiguration
