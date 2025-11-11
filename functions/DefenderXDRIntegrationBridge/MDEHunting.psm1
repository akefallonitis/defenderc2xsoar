<#
.SYNOPSIS
    Advanced Hunting module for DefenderXDR C2 XSOAR

.DESCRIPTION
    Handles advanced hunting queries in Microsoft Defender for Endpoint
#>

# Import auth module for headers
if (-not (Get-Module -Name MDEAuth)) {
    $ModulePath = Join-Path $PSScriptRoot "MDEAuth.psm1"
    Import-Module $ModulePath -Force
}

$script:MDEApiBase = "https://api.securitycenter.microsoft.com/api"

function Invoke-AdvancedHunting {
    <#
    .SYNOPSIS
        Executes an advanced hunting query
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Query
        KQL query to execute
        
    .EXAMPLE
        Invoke-AdvancedHunting -Token $token -Query "DeviceInfo | take 10"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/advancedqueries/run"
        
        $body = @{
            Query = $Query
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully executed hunting query"
        
        return $response.Results
        
    } catch {
        Write-Error "Failed to execute hunting query: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Invoke-AdvancedHunting
