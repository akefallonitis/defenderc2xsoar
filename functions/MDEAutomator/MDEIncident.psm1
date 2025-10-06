<#
.SYNOPSIS
    Incident management module for MDE Automator Local
    
.DESCRIPTION
    Handles security incident operations in Microsoft Defender for Endpoint
#>

# Import auth module for headers
if (-not (Get-Module -Name MDEAuth)) {
    $ModulePath = Join-Path $PSScriptRoot "MDEAuth.psm1"
    Import-Module $ModulePath -Force
}

$script:GraphApiBase = "https://graph.microsoft.com/v1.0/security"

function Get-SecurityIncidents {
    <#
    .SYNOPSIS
        Gets security incidents
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Filter
        Optional OData filter
        
    .EXAMPLE
        Get-SecurityIncidents -Token $token
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
        $uri = "$script:GraphApiBase/incidents"
        
        if ($Filter) {
            $uri += "?`$filter=$Filter"
        }
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get incidents: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-SecurityIncidents
