<#
.SYNOPSIS
    Custom detection module for MDE Automator Local
    
.DESCRIPTION
    Handles custom detection rule operations in Microsoft Defender for Endpoint
#>

# Import auth module for headers
$ModuleRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$ModuleRoot\modules\MDEAuth.psm1" -Force

$script:GraphApiBase = "https://graph.microsoft.com/beta/security/rules/detectionRules"

function Get-CustomDetections {
    <#
    .SYNOPSIS
        Gets all custom detection rules
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .EXAMPLE
        Get-CustomDetections -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = $script:GraphApiBase
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get custom detections: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-CustomDetections
