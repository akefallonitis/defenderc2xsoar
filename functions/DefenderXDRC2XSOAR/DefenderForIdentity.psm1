# Microsoft Defender for Identity (MDI) Module
# Provides identity threat detection, lateral movement detection, and attack path analysis

function Get-MDIAlerts {
    <#
    .SYNOPSIS
        Gets security alerts from Microsoft Defender for Identity via Microsoft Graph
    
    .PARAMETER Token
        Microsoft Graph API access token
    
    .PARAMETER Filter
        OData filter query
    
    .PARAMETER Top
        Number of results to return (default: 100)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [int]$Top = 100
    )
    
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=$Top"
    
    if ($Filter) {
        $uri += "&`$filter=$Filter"
    }
    
    # Filter for MDI alerts
    if ($Filter) {
        $uri += " and serviceSource eq 'microsoftDefenderForIdentity'"
    } else {
        $uri += "&`$filter=serviceSource eq 'microsoftDefenderForIdentity'"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) MDI alerts"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve MDI alerts: $($_.Exception.Message)"
        throw
    }
}

function Update-MDIAlert {
    <#
    .SYNOPSIS
        Updates the status of an MDI alert
    
    .PARAMETER Token
        Microsoft Graph API access token
    
    .PARAMETER AlertId
        Alert ID
    
    .PARAMETER Status
        New status: new, inProgress, resolved
    
    .PARAMETER Classification
        Classification: unknown, falsePositive, truePositive, benignPositive
    
    .PARAMETER AssignedTo
        User principal name to assign alert to
    
    .PARAMETER Comment
        Comment to add
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$AlertId,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("new", "inProgress", "resolved")]
        [string]$Status,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("unknown", "falsePositive", "truePositive", "benignPositive")]
        [string]$Classification,
        
        [Parameter(Mandatory=$false)]
        [string]$AssignedTo,
        
        [Parameter(Mandatory=$false)]
        [string]$Comment
    )
    
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$AlertId"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{}
    
    if ($Status) { $body.status = $Status }
    if ($Classification) { $body.classification = $Classification }
    if ($AssignedTo) { $body.assignedTo = $AssignedTo }
    if ($Comment) { 
        $body.comments = @(
            @{
                comment = $Comment
                createdByDisplayName = "DefenderXDRC2XSOAR"
            }
        )
    }
    
    $bodyJson = $body | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $bodyJson
        Write-Host "Updated MDI alert: $AlertId"
        return $response
    } catch {
        Write-Error "Failed to update MDI alert: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIHealthIssues {
    <#
    .SYNOPSIS
        Gets health issues from MDI sensors (via Microsoft 365 Defender API)
    
    .PARAMETER Token
        MDE/M365 Defender API access token
    
    .PARAMETER SensorName
        Optional: Filter by sensor name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$SensorName
    )
    
    # Note: MDI health issues may require direct access to MDI portal API
    # This uses the unified security API
    $uri = "https://api.securitycenter.microsoft.com/api/machines"
    
    if ($SensorName) {
        $uri += "?`$filter=computerDnsName eq '$SensorName'"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved MDI sensor information"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve MDI health issues: $($_.Exception.Message)"
        throw
    }
}

function Get-MDILateralMovementPaths {
    <#
    .SYNOPSIS
        Gets lateral movement paths detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    
    .PARAMETER EntityId
        Entity (user/device) ID to check for lateral movement paths
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$EntityId
    )
    
    # Query security alerts for lateral movement detection
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=serviceSource eq 'microsoftDefenderForIdentity' and category eq 'LateralMovement'"
    
    if ($EntityId) {
        $uri += " and (entities/any(e: e/id eq '$EntityId'))"
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) lateral movement detections"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve lateral movement paths: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIIdentitySecureScore {
    <#
    .SYNOPSIS
        Gets identity secure score from Microsoft Graph
    
    .PARAMETER Token
        Microsoft Graph API access token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $uri = "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved identity secure score"
        return $response.value[0]
    } catch {
        Write-Error "Failed to retrieve identity secure score: $($_.Exception.Message)"
        throw
    }
}

function Get-MDISuspiciousActivities {
    <#
    .SYNOPSIS
        Gets suspicious activities detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    
    .PARAMETER Severity
        Filter by severity: low, medium, high, informational
    
    .PARAMETER Status
        Filter by status: new, inProgress, resolved
    
    .PARAMETER Days
        Number of days to look back (default: 7)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("low", "medium", "high", "informational")]
        [string]$Severity,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("new", "inProgress", "resolved")]
        [string]$Status,
        
        [Parameter(Mandatory=$false)]
        [int]$Days = 7
    )
    
    $startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    $filterParts = @(
        "serviceSource eq 'microsoftDefenderForIdentity'",
        "createdDateTime ge $startDate"
    )
    
    if ($Severity) {
        $filterParts += "severity eq '$Severity'"
    }
    
    if ($Status) {
        $filterParts += "status eq '$Status'"
    }
    
    $filter = $filterParts -join " and "
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=$filter&`$top=100"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) suspicious activities from last $Days days"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve suspicious activities: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIExposedCredentials {
    <#
    .SYNOPSIS
        Gets accounts with exposed credentials detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    # Query for credential exposure alerts
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=serviceSource eq 'microsoftDefenderForIdentity' and (title contains 'credential' or title contains 'password')"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) exposed credential alerts"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve exposed credentials: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIAccountEnumeration {
    <#
    .SYNOPSIS
        Gets account enumeration attempts detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    
    .PARAMETER SourceIP
        Optional: Filter by source IP address
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$SourceIP
    )
    
    $filter = "serviceSource eq 'microsoftDefenderForIdentity' and category eq 'AccountEnumeration'"
    
    if ($SourceIP) {
        $filter += " and (entities/any(e: e/ipAddress eq '$SourceIP'))"
    }
    
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=$filter"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) account enumeration attempts"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve account enumeration attempts: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIPrivilegeEscalation {
    <#
    .SYNOPSIS
        Gets privilege escalation attempts detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=serviceSource eq 'microsoftDefenderForIdentity' and category eq 'PrivilegeEscalation'"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) privilege escalation attempts"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve privilege escalation attempts: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIDomainControllerCoverage {
    <#
    .SYNOPSIS
        Gets domain controller coverage status for MDI sensors
    
    .PARAMETER Token
        Microsoft Graph API access token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    # This would typically require MDI-specific API
    # Using Graph API to get alerts related to sensor coverage
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=serviceSource eq 'microsoftDefenderForIdentity' and title contains 'sensor'"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved MDI sensor coverage information"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve domain controller coverage: $($_.Exception.Message)"
        throw
    }
}

function Get-MDIReconnaissanceActivities {
    <#
    .SYNOPSIS
        Gets reconnaissance activities detected by MDI
    
    .PARAMETER Token
        Microsoft Graph API access token
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=serviceSource eq 'microsoftDefenderForIdentity' and (category eq 'Reconnaissance' or category eq 'Discovery')"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        Write-Host "Retrieved $($response.value.Count) reconnaissance activities"
        return $response.value
    } catch {
        Write-Error "Failed to retrieve reconnaissance activities: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function @(
    'Get-MDIAlerts',
    'Update-MDIAlert',
    'Get-MDIHealthIssues',
    'Get-MDILateralMovementPaths',
    'Get-MDIIdentitySecureScore',
    'Get-MDISuspiciousActivities',
    'Get-MDIExposedCredentials',
    'Get-MDIAccountEnumeration',
    'Get-MDIPrivilegeEscalation',
    'Get-MDIDomainControllerCoverage',
    'Get-MDIReconnaissanceActivities'
)
