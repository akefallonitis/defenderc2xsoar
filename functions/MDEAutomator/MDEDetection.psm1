<#
.SYNOPSIS
    Custom detection module for MDE Automator Local
    
.DESCRIPTION
    Handles custom detection rule operations in Microsoft Defender for Endpoint
#>

# Import auth module for headers
if (-not (Get-Module -Name MDEAuth)) {
    $ModulePath = Join-Path $PSScriptRoot "MDEAuth.psm1"
    Import-Module $ModulePath -Force
}

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

function New-CustomDetection {
    <#
    .SYNOPSIS
        Creates a new custom detection rule
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Name
        Display name for the detection rule
        
    .PARAMETER Query
        KQL query for the detection
        
    .PARAMETER Severity
        Severity level: Informational, Low, Medium, High
        
    .PARAMETER Description
        Description of the detection rule
        
    .PARAMETER Enabled
        Whether the rule is enabled
        
    .EXAMPLE
        New-CustomDetection -Token $token -Name "Suspicious PowerShell" -Query "DeviceProcessEvents | where ..." -Severity "High"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Informational", "Low", "Medium", "High")]
        [string]$Severity = "Medium",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = $script:GraphApiBase
        
        $body = @{
            displayName = $Name
            queryCondition = @{
                queryText = $Query
            }
            detectionAction = @{
                alertTemplate = @{
                    title = $Name
                    description = $Description
                    severity = $Severity.ToLower()
                    category = "CustomDetection"
                }
            }
            isEnabled = $Enabled
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Successfully created custom detection: $Name"
        
        return $response
        
    } catch {
        Write-Error "Failed to create custom detection: $($_.Exception.Message)"
        throw
    }
}

function Update-CustomDetection {
    <#
    .SYNOPSIS
        Updates an existing custom detection rule
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER RuleId
        ID of the detection rule to update
        
    .PARAMETER Name
        New display name (optional)
        
    .PARAMETER Query
        New KQL query (optional)
        
    .PARAMETER Severity
        New severity level (optional)
        
    .PARAMETER Description
        New description (optional)
        
    .PARAMETER Enabled
        Whether the rule is enabled (optional)
        
    .EXAMPLE
        Update-CustomDetection -Token $token -RuleId "rule-id" -Enabled $false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$RuleId,
        
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Informational", "Low", "Medium", "High")]
        [string]$Severity,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [bool]$Enabled
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:GraphApiBase/$RuleId"
        
        # Build update body with only provided parameters
        $updateBody = @{}
        
        if ($Name) {
            $updateBody.displayName = $Name
        }
        
        if ($Query) {
            $updateBody.queryCondition = @{
                queryText = $Query
            }
        }
        
        if ($Severity -or $Description -or $Name) {
            $alertTemplate = @{}
            if ($Name) { $alertTemplate.title = $Name }
            if ($Description) { $alertTemplate.description = $Description }
            if ($Severity) { $alertTemplate.severity = $Severity.ToLower() }
            
            if ($alertTemplate.Count -gt 0) {
                $updateBody.detectionAction = @{
                    alertTemplate = $alertTemplate
                }
            }
        }
        
        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $updateBody.isEnabled = $Enabled
        }
        
        if ($updateBody.Count -eq 0) {
            Write-Warning "No update parameters provided"
            return $null
        }
        
        $body = $updateBody | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Successfully updated custom detection: $RuleId"
        
        return $response
        
    } catch {
        Write-Error "Failed to update custom detection: $($_.Exception.Message)"
        throw
    }
}

function Remove-CustomDetection {
    <#
    .SYNOPSIS
        Deletes a custom detection rule
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER RuleId
        ID of the detection rule to delete
        
    .EXAMPLE
        Remove-CustomDetection -Token $token -RuleId "rule-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$RuleId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:GraphApiBase/$RuleId"
        
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
        
        Write-Verbose "Successfully deleted custom detection: $RuleId"
        
    } catch {
        Write-Error "Failed to delete custom detection: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-CustomDetections, New-CustomDetection, Update-CustomDetection, Remove-CustomDetection
