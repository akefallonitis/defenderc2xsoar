<#
.SYNOPSIS
    Threat Intelligence module for DefenderXDR C2 XSOAR

.DESCRIPTION
    Handles threat indicator management in Microsoft Defender for Endpoint
#>

# Import auth module for headers
if (-not (Get-Module -Name AuthManager)) {
    $ModulePath = Join-Path $PSScriptRoot "AuthManager.psm1"
    Import-Module $ModulePath -Force
}

$script:MDEApiBase = "https://api.securitycenter.microsoft.com/api"

function Add-FileIndicator {
    <#
    .SYNOPSIS
        Adds file indicator(s) to MDE
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Sha256
        SHA256 hash of the file
        
    .PARAMETER Title
        Title/description of the indicator
        
    .PARAMETER Severity
        Severity level: Informational, Low, Medium, High
        
    .PARAMETER Action
        Action to take: Alert, Block, Allowed
        
    .PARAMETER Description
        Detailed description
        
    .EXAMPLE
        Add-FileIndicator -Token $token -Sha256 "hash" -Title "Malware" -Severity "High" -Action "Block"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$Sha256,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Informational", "Low", "Medium", "High")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Alert", "Block", "Allowed")]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/indicators"
        
        $body = @{
            indicatorValue = $Sha256.ToLower()
            indicatorType  = "FileSha256"
            title          = $Title
            description    = $Description
            severity       = $Severity
            action         = $Action
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully added file indicator: $Sha256"
        
        return $response
        
    } catch {
        Write-Error "Failed to add file indicator: $($_.Exception.Message)"
        throw
    }
}

function Remove-FileIndicator {
    <#
    .SYNOPSIS
        Removes file indicator from MDE
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER IndicatorId
        ID of the indicator to remove
        
    .EXAMPLE
        Remove-FileIndicator -Token $token -IndicatorId "indicator-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$IndicatorId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/indicators/$IndicatorId"
        
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
        
        Write-Verbose "Successfully removed indicator: $IndicatorId"
        
    } catch {
        Write-Error "Failed to remove indicator: $($_.Exception.Message)"
        throw
    }
}

function Add-IPIndicator {
    <#
    .SYNOPSIS
        Adds IP indicator to MDE
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER IPAddress
        IP address
        
    .PARAMETER Title
        Title/description of the indicator
        
    .PARAMETER Severity
        Severity level: Informational, Low, Medium, High
        
    .PARAMETER Action
        Action to take: Alert, Block, Allowed
        
    .PARAMETER Description
        Detailed description
        
    .EXAMPLE
        Add-IPIndicator -Token $token -IPAddress "1.2.3.4" -Title "C2 Server" -Severity "High" -Action "Block"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$IPAddress,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Informational", "Low", "Medium", "High")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Alert", "Block", "Allowed")]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/indicators"
        
        $body = @{
            indicatorValue = $IPAddress
            indicatorType  = "IpAddress"
            title          = $Title
            description    = $Description
            severity       = $Severity
            action         = $Action
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully added IP indicator: $IPAddress"
        
        return $response
        
    } catch {
        Write-Error "Failed to add IP indicator: $($_.Exception.Message)"
        throw
    }
}

function Add-URLIndicator {
    <#
    .SYNOPSIS
        Adds URL/Domain indicator to MDE
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER URL
        URL or domain
        
    .PARAMETER Title
        Title/description of the indicator
        
    .PARAMETER Severity
        Severity level: Informational, Low, Medium, High
        
    .PARAMETER Action
        Action to take: Alert, Block, Allowed
        
    .PARAMETER Description
        Detailed description
        
    .EXAMPLE
        Add-URLIndicator -Token $token -URL "malicious.com" -Title "Phishing Site" -Severity "High" -Action "Block"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$URL,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Informational", "Low", "Medium", "High")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Alert", "Block", "Allowed")]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/indicators"
        
        # Determine if it's a URL or domain
        $indicatorType = if ($URL -match "^https?://") { "Url" } else { "DomainName" }
        
        $body = @{
            indicatorValue = $URL.ToLower()
            indicatorType  = $indicatorType
            title          = $Title
            description    = $Description
            severity       = $Severity
            action         = $Action
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully added URL/Domain indicator: $URL"
        
        return $response
        
    } catch {
        Write-Error "Failed to add URL/Domain indicator: $($_.Exception.Message)"
        throw
    }
}

function Get-AllIndicators {
    <#
    .SYNOPSIS
        Gets all threat indicators
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Filter
        Optional OData filter
        
    .EXAMPLE
        Get-AllIndicators -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/indicators"
        
        if ($Filter) {
            $uri += "?`$filter=$Filter"
        }
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get indicators: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Add-FileIndicator, Remove-FileIndicator, Add-IPIndicator, 
    Add-URLIndicator, Get-AllIndicators
