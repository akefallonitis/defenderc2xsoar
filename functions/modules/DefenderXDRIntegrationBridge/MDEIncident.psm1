<#
.SYNOPSIS
    Incident management module for DefenderXDR C2 XSOAR

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

function Update-SecurityIncident {
    <#
    .SYNOPSIS
        Updates a security incident
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER IncidentId
        ID of the incident to update
        
    .PARAMETER Status
        New status: Active, Resolved, InProgress
        
    .PARAMETER Classification
        Classification: Unknown, FalsePositive, TruePositive
        
    .PARAMETER Determination
        Determination: NotAvailable, Apt, Malware, SecurityPersonnel, SecurityTesting, UnwantedSoftware, Other
        
    .PARAMETER AssignedTo
        User principal name to assign the incident to
        
    .EXAMPLE
        Update-SecurityIncident -Token $token -IncidentId "incident-id" -Status "Resolved" -Classification "TruePositive" -Determination "Malware"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$IncidentId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Active", "Resolved", "InProgress")]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Unknown", "FalsePositive", "TruePositive")]
        [string]$Classification,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("NotAvailable", "Apt", "Malware", "SecurityPersonnel", "SecurityTesting", "UnwantedSoftware", "Other")]
        [string]$Determination,
        
        [Parameter(Mandatory = $false)]
        [string]$AssignedTo
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:GraphApiBase/incidents/$IncidentId"
        
        # Build update body with only provided parameters
        $updateBody = @{}
        
        if ($Status) {
            $updateBody.status = $Status.ToLower()
        }
        
        if ($Classification) {
            $updateBody.classification = $Classification.ToLower()
        }
        
        if ($Determination) {
            $updateBody.determination = $Determination.ToLower()
        }
        
        if ($AssignedTo) {
            $updateBody.assignedTo = $AssignedTo
        }
        
        if ($updateBody.Count -eq 0) {
            Write-Warning "No update parameters provided"
            return $null
        }
        
        $body = $updateBody | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Successfully updated incident: $IncidentId"
        
        return $response
        
    } catch {
        Write-Error "Failed to update incident: $($_.Exception.Message)"
        throw
    }
}

function Add-IncidentComment {
    <#
    .SYNOPSIS
        Adds a comment to a security incident
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER IncidentId
        ID of the incident
        
    .PARAMETER Comment
        Comment text to add
        
    .EXAMPLE
        Add-IncidentComment -Token $token -IncidentId "incident-id" -Comment "Investigated and confirmed malware"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$IncidentId,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:GraphApiBase/incidents/$IncidentId/comments"
        
        $body = @{
            comment = $Comment
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Successfully added comment to incident: $IncidentId"
        
        return $response
        
    } catch {
        Write-Error "Failed to add comment to incident: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-SecurityIncidents, Update-SecurityIncident, Add-IncidentComment
