# Microsoft Intune Device Management Module
# Provides device management capabilities via Microsoft Graph API

function Invoke-IntuneDeviceRemoteLock {
    <#
    .SYNOPSIS
        Remotely locks an Intune-managed device
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DeviceId
        Intune device ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceId
    )
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/remoteLock"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        Write-Host "Remote lock initiated for device: $DeviceId"
        return $response
    } catch {
        Write-Error "Failed to remote lock device: $($_.Exception.Message)"
        throw
    }
}

function Invoke-IntuneDeviceWipe {
    <#
    .SYNOPSIS
        Wipes an Intune-managed device
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DeviceId
        Intune device ID
    
    .PARAMETER KeepEnrollmentData
        Whether to keep enrollment data
    
    .PARAMETER KeepUserData
        Whether to keep user data
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory=$false)]
        [bool]$KeepEnrollmentData = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$KeepUserData = $false
    )
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/wipe"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        keepEnrollmentData = $KeepEnrollmentData
        keepUserData = $KeepUserData
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Wipe initiated for device: $DeviceId"
        return $response
    } catch {
        Write-Error "Failed to wipe device: $($_.Exception.Message)"
        throw
    }
}

function Invoke-IntuneDeviceRetire {
    <#
    .SYNOPSIS
        Retires an Intune-managed device (removes company data only)
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DeviceId
        Intune device ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceId
    )
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/retire"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        Write-Host "Retire initiated for device: $DeviceId"
        return $response
    } catch {
        Write-Error "Failed to retire device: $($_.Exception.Message)"
        throw
    }
}

function Sync-IntuneDevice {
    <#
    .SYNOPSIS
        Syncs an Intune-managed device
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DeviceId
        Intune device ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceId
    )
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/syncDevice"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        Write-Host "Sync requested for device: $DeviceId"
        return $response
    } catch {
        Write-Error "Failed to sync device: $($_.Exception.Message)"
        throw
    }
}

function Invoke-IntuneDefenderScan {
    <#
    .SYNOPSIS
        Initiates a Windows Defender scan on an Intune-managed device
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER DeviceId
        Intune device ID
    
    .PARAMETER QuickScan
        True for quick scan, False for full scan
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory=$false)]
        [bool]$QuickScan = $true
    )
    
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceId/windowsDefenderScan"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        quickScan = $QuickScan
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        Write-Host "Defender scan initiated for device: $DeviceId ($(if($QuickScan){'Quick'}else{'Full'}) scan)"
        return $response
    } catch {
        Write-Error "Failed to initiate Defender scan: $($_.Exception.Message)"
        throw
    }
}

function Get-IntuneManagedDevices {
    <#
    .SYNOPSIS
        Gets all Intune-managed devices
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER Filter
        OData filter string
    
    .PARAMETER Top
        Maximum number of results
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [int]$Top = 100
    )
    
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
    
    $queryParams = @()
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Top) { $queryParams += "`$top=$Top" }
    
    if ($queryParams.Count -gt 0) {
        $uri += "?" + ($queryParams -join "&")
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        return $response.value
    } catch {
        Write-Error "Failed to get managed devices: $($_.Exception.Message)"
        throw
    }
}

function Get-IntuneDeviceComplianceStatus {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    try {
        $headers = @{
            Authorization = "$($Token.TokenType) $($Token.AccessToken)"
            "Content-Type" = "application/json"
        }
        
        $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$select=id,deviceName,complianceState,lastSyncDateTime"
        Write-Host "Getting device compliance status from: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $response.value
    }
    catch {
        Write-Error "Failed to get device compliance status: $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-IntuneDeviceRemoteLock',
    'Invoke-IntuneDeviceWipe',
    'Invoke-IntuneDeviceRetire',
    'Sync-IntuneDevice',
    'Invoke-IntuneDefenderScan',
    'Get-IntuneManagedDevices',
    'Get-IntuneDeviceComplianceStatus'
)
