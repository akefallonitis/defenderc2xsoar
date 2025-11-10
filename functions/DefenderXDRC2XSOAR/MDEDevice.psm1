<#
.SYNOPSIS
    Device actions module for MDE Automator Local
    
.DESCRIPTION
    Handles device-related operations in Microsoft Defender for Endpoint
#>

# Import auth module for headers
if (-not (Get-Module -Name MDEAuth)) {
    $ModulePath = Join-Path $PSScriptRoot "MDEAuth.psm1"
    Import-Module $ModulePath -Force
}

$script:MDEApiBase = "https://api.securitycenter.microsoft.com/api"

function Invoke-DeviceIsolation {
    <#
    .SYNOPSIS
        Isolates device(s) from the network
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs to isolate
        
    .PARAMETER Comment
        Reason for isolation
        
    .PARAMETER IsolationType
        Type of isolation: Full or Selective
        
    .EXAMPLE
        Invoke-DeviceIsolation -Token $token -DeviceIds "device-id" -Comment "Suspected compromise" -IsolationType "Full"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Full", "Selective")]
        [string]$IsolationType = "Full"
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/isolate"
            
            $body = @{
                Comment       = $Comment
                IsolationType = $IsolationType
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully initiated isolation for device: $deviceId"
            
        } catch {
            Write-Error "Failed to isolate device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-DeviceUnisolation {
    <#
    .SYNOPSIS
        Releases device(s) from isolation
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs to release
        
    .PARAMETER Comment
        Reason for releasing from isolation
        
    .EXAMPLE
        Invoke-DeviceUnisolation -Token $token -DeviceIds "device-id" -Comment "Threat remediated"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/unisolate"
            
            $body = @{
                Comment = $Comment
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully initiated unisolation for device: $deviceId"
            
        } catch {
            Write-Error "Failed to unisolate device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-RestrictAppExecution {
    <#
    .SYNOPSIS
        Restricts app execution on device(s)
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs
        
    .PARAMETER Comment
        Reason for restriction
        
    .EXAMPLE
        Invoke-RestrictAppExecution -Token $token -DeviceIds "device-id" -Comment "Suspicious activity detected"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/restrictCodeExecution"
            
            $body = @{
                Comment = $Comment
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully initiated app execution restriction for device: $deviceId"
            
        } catch {
            Write-Error "Failed to restrict app execution on device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-UnrestrictAppExecution {
    <#
    .SYNOPSIS
        Removes app execution restriction from device(s)
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs
        
    .PARAMETER Comment
        Reason for removing restriction
        
    .EXAMPLE
        Invoke-UnrestrictAppExecution -Token $token -DeviceIds "device-id" -Comment "Investigation completed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/unrestrictCodeExecution"
            
            $body = @{
                Comment = $Comment
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully removed app execution restriction for device: $deviceId"
            
        } catch {
            Write-Error "Failed to unrestrict app execution on device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-AntivirusScan {
    <#
    .SYNOPSIS
        Initiates antivirus scan on device(s)
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs
        
    .PARAMETER ScanType
        Type of scan: Quick or Full
        
    .PARAMETER Comment
        Reason for scan
        
    .EXAMPLE
        Invoke-AntivirusScan -Token $token -DeviceIds "device-id" -ScanType "Full" -Comment "Routine scan"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Quick", "Full")]
        [string]$ScanType = "Full",
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/runAntiVirusScan"
            
            $body = @{
                Comment  = $Comment
                ScanType = $ScanType
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully initiated $ScanType scan for device: $deviceId"
            
        } catch {
            Write-Error "Failed to initiate scan on device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-CollectInvestigationPackage {
    <#
    .SYNOPSIS
        Collects investigation package from device(s)
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceIds
        Array of device IDs
        
    .PARAMETER Comment
        Reason for collection
        
    .EXAMPLE
        Invoke-CollectInvestigationPackage -Token $token -DeviceIds "device-id" -Comment "Security investigation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string[]]$DeviceIds,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    $results = @()
    
    foreach ($deviceId in $DeviceIds) {
        try {
            $uri = "$script:MDEApiBase/machines/$deviceId/collectInvestigationPackage"
            
            $body = @{
                Comment = $Comment
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
            $results += $response
            
            Write-Verbose "Successfully initiated investigation package collection for device: $deviceId"
            
        } catch {
            Write-Error "Failed to collect investigation package from device $deviceId : $($_.Exception.Message)"
            throw
        }
    }
    
    return $results
}

function Invoke-StopAndQuarantineFile {
    <#
    .SYNOPSIS
        Stops and quarantines a file across all devices
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Sha1
        SHA1 hash of the file
        
    .PARAMETER Comment
        Reason for quarantine
        
    .EXAMPLE
        Invoke-StopAndQuarantineFile -Token $token -Sha1 "file-sha1-hash" -Comment "Malware detected"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$Sha1,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/StopAndQuarantineFile"
        
        $body = @{
            Comment = $Comment
            Sha1    = $Sha1
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully initiated stop and quarantine for file: $Sha1"
        
        return $response
        
    } catch {
        Write-Error "Failed to stop and quarantine file $Sha1 : $($_.Exception.Message)"
        throw
    }
}

function Get-DeviceInfo {
    <#
    .SYNOPSIS
        Gets information about a specific device
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceId
        Device ID
        
    .EXAMPLE
        Get-DeviceInfo -Token $token -DeviceId "device-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/$DeviceId"
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response
        
    } catch {
        Write-Error "Failed to get device info for $DeviceId : $($_.Exception.Message)"
        throw
    }
}

function Get-AllDevices {
    <#
    .SYNOPSIS
        Gets all devices in the tenant
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Filter
        Optional OData filter
        
    .EXAMPLE
        Get-AllDevices -Token $token
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
        $uri = "$script:MDEApiBase/machines"
        
        if ($Filter) {
            $uri += "?`$filter=$Filter"
        }
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get devices: $($_.Exception.Message)"
        throw
    }
}

function Get-MachineActionStatus {
    <#
    .SYNOPSIS
        Gets the status of a machine action
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER ActionId
        Action ID to check
        
    .EXAMPLE
        Get-MachineActionStatus -Token $token -ActionId "action-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$ActionId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machineactions/$ActionId"
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response
        
    } catch {
        Write-Error "Failed to get action status for $ActionId : $($_.Exception.Message)"
        throw
    }
}

function Get-AllMachineActions {
    <#
    .SYNOPSIS
        Gets all machine actions
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER Filter
        Optional OData filter
        
    .EXAMPLE
        Get-AllMachineActions -Token $token -Filter "status eq 'Pending'"
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
        $uri = "$script:MDEApiBase/machineactions"
        
        if ($Filter) {
            $uri += "?`$filter=$Filter"
        }
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get machine actions: $($_.Exception.Message)"
        throw
    }
}

function Stop-MachineAction {
    <#
    .SYNOPSIS
        Cancels a pending machine action
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER ActionId
        Action ID to cancel
        
    .PARAMETER Comment
        Reason for cancellation
        
    .EXAMPLE
        Stop-MachineAction -Token $token -ActionId "action-id" -Comment "False positive"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$ActionId,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machineactions/$ActionId/cancel"
        
        $body = @{
            Comment = $Comment
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully cancelled action: $ActionId"
        
        return $response
        
    } catch {
        Write-Error "Failed to cancel action $ActionId : $($_.Exception.Message)"
        throw
    }
}

function Invoke-DeviceOffboard {
    <#
    .SYNOPSIS
        Offboards a device from Microsoft Defender for Endpoint
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceId
        Device ID to offboard
        
    .PARAMETER Comment
        Reason for offboarding
        
    .EXAMPLE
        Invoke-DeviceOffboard -Token $token -DeviceId "device-id" -Comment "Device decommissioned"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/$DeviceId/offboard"
        
        $body = @{
            Comment = $Comment
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully initiated offboarding for device: $DeviceId"
        
        return $response
        
    } catch {
        Write-Error "Failed to offboard device $DeviceId : $($_.Exception.Message)"
        throw
    }
}

function Start-AutomatedInvestigation {
    <#
    .SYNOPSIS
        Triggers an automated investigation on a device
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceId
        Device ID to investigate
        
    .PARAMETER Comment
        Reason for investigation
        
    .EXAMPLE
        Start-AutomatedInvestigation -Token $token -DeviceId "device-id" -Comment "Suspicious activity detected"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/$DeviceId/startInvestigation"
        
        $body = @{
            Comment = $Comment
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        
        Write-Verbose "Successfully triggered investigation for device: $DeviceId"
        
        return $response
        
    } catch {
        Write-Error "Failed to start investigation on device $DeviceId : $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Invoke-DeviceIsolation, Invoke-DeviceUnisolation, Invoke-RestrictAppExecution, 
    Invoke-UnrestrictAppExecution, Invoke-AntivirusScan, Invoke-CollectInvestigationPackage, 
    Invoke-StopAndQuarantineFile, Invoke-DeviceOffboard, Start-AutomatedInvestigation,
    Get-DeviceInfo, Get-AllDevices, Get-MachineActionStatus, 
    Get-AllMachineActions, Stop-MachineAction
