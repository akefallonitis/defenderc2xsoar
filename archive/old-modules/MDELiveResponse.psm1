<#
.SYNOPSIS
    Live Response module for DefenderXDR C2 XSOAR

.DESCRIPTION
    Handles Live Response operations in Microsoft Defender for Endpoint including
    interactive shell, command execution, file upload/download, and session management
#>

# Import auth module for headers
if (-not (Get-Module -Name AuthManager)) {
    $ModulePath = Join-Path $PSScriptRoot "AuthManager.psm1"
    Import-Module $ModulePath -Force
}

$script:MDEApiBase = "https://api.securitycenter.microsoft.com/api"

function Start-MDELiveResponseSession {
    <#
    .SYNOPSIS
        Initiates a Live Response session on a device
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER DeviceId
        Device ID to start the session on
        
    .PARAMETER Comment
        Comment for the action
        
    .EXAMPLE
        Start-MDELiveResponseSession -Token $token -DeviceId "device-id" -Comment "Investigation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory = $false)]
        [string]$Comment = "Live Response Session"
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/$DeviceId/liveresponse"
        
        $body = @{
            Comment = $Comment
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Live Response session initiated for device: $DeviceId"
        return $response
        
    } catch {
        Write-Error "Failed to start Live Response session: $($_.Exception.Message)"
        throw
    }
}

function Get-MDELiveResponseSession {
    <#
    .SYNOPSIS
        Gets Live Response session status
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Session ID to check
        
    .EXAMPLE
        Get-MDELiveResponseSession -Token $token -SessionId "session-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/liveresponse/sessions/$SessionId"
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response
        
    } catch {
        Write-Error "Failed to get Live Response session: $($_.Exception.Message)"
        throw
    }
}

function Invoke-MDELiveResponseCommand {
    <#
    .SYNOPSIS
        Executes a command in a Live Response session
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Active session ID
        
    .PARAMETER Command
        Command to execute (e.g., "dir", "getfile", "putfile", "remediate")
        
    .PARAMETER Parameters
        Command parameters as hashtable
        
    .EXAMPLE
        Invoke-MDELiveResponseCommand -Token $token -SessionId "session-id" -Command "dir" -Parameters @{Path="C:\"}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/liveresponse/sessions/$SessionId/commands"
        
        $body = @{
            Command = $Command
            Parameters = $Parameters
        } | ConvertTo-Json -Depth 5
        
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
        
        Write-Verbose "Command '$Command' executed in session: $SessionId"
        return $response
        
    } catch {
        Write-Error "Failed to execute command: $($_.Exception.Message)"
        throw
    }
}

function Get-MDELiveResponseCommandResult {
    <#
    .SYNOPSIS
        Gets the result of a Live Response command
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER CommandId
        Command ID to get results for
        
    .EXAMPLE
        Get-MDELiveResponseCommandResult -Token $token -CommandId "command-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$CommandId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/liveresponse/commands/$CommandId"
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response
        
    } catch {
        Write-Error "Failed to get command result: $($_.Exception.Message)"
        throw
    }
}

function Wait-MDELiveResponseCommand {
    <#
    .SYNOPSIS
        Waits for a Live Response command to complete with async polling
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER CommandId
        Command ID to wait for
        
    .PARAMETER TimeoutSeconds
        Maximum time to wait (default: 300)
        
    .PARAMETER PollingIntervalSeconds
        Polling interval respecting API rate limits (default: 5)
        
    .EXAMPLE
        Wait-MDELiveResponseCommand -Token $token -CommandId "command-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$CommandId,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300,
        
        [Parameter(Mandatory = $false)]
        [int]$PollingIntervalSeconds = 5
    )
    
    $startTime = Get-Date
    $status = "Pending"
    
    Write-Verbose "Waiting for command $CommandId to complete..."
    
    while ($status -in @("Pending", "InProgress", "Created")) {
        if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSeconds) {
            Write-Warning "Command timed out after $TimeoutSeconds seconds"
            return $null
        }
        
        Start-Sleep -Seconds $PollingIntervalSeconds
        
        try {
            $result = Get-MDELiveResponseCommandResult -Token $Token -CommandId $CommandId
            $status = $result.status
            
            Write-Verbose "Command status: $status"
            
            if ($status -eq "Completed") {
                return $result
            } elseif ($status -eq "Failed") {
                Write-Error "Command failed: $($result.error)"
                return $result
            }
        } catch {
            Write-Warning "Error polling command status: $($_.Exception.Message)"
        }
    }
    
    return $null
}

function Get-MDELiveResponseFile {
    <#
    .SYNOPSIS
        Downloads a file from a device via Live Response
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Active session ID
        
    .PARAMETER FilePath
        Path to file on the device
        
    .PARAMETER DestinationPath
        Local path to save the file
        
    .EXAMPLE
        Get-MDELiveResponseFile -Token $token -SessionId "session-id" -FilePath "C:\file.txt" -DestinationPath "C:\local\file.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    
    try {
        # Execute getfile command
        $params = @{
            Path = $FilePath
        }
        
        $command = Invoke-MDELiveResponseCommand -Token $Token -SessionId $SessionId -Command "getfile" -Parameters $params
        
        Write-Host "⏳ Waiting for file download to complete..." -ForegroundColor Yellow
        $result = Wait-MDELiveResponseCommand -Token $Token -CommandId $command.id
        
        if ($result -and $result.status -eq "Completed") {
            # Download the file from the result
            if ($result.value) {
                $fileUrl = $result.value
                $headers = Get-MDEAuthHeaders -Token $Token
                Invoke-RestMethod -Method Get -Uri $fileUrl -Headers $headers -OutFile $DestinationPath
                
                Write-Verbose "File downloaded successfully to: $DestinationPath"
                return $true
            }
        }
        
        return $false
        
    } catch {
        Write-Error "Failed to download file: $($_.Exception.Message)"
        throw
    }
}

function Send-MDELiveResponseFile {
    <#
    .SYNOPSIS
        Uploads a file to a device via Live Response
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Active session ID
        
    .PARAMETER SourcePath
        Local file path to upload
        
    .PARAMETER DestinationPath
        Path on the device to upload to
        
    .EXAMPLE
        Send-MDELiveResponseFile -Token $token -SessionId "session-id" -SourcePath "C:\local\file.txt" -DestinationPath "C:\Temp\file.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    
    try {
        # First, upload file to library
        $headers = Get-MDEAuthHeaders -Token $Token
        $fileName = Split-Path -Leaf $SourcePath
        
        # Upload to library
        $libraryUri = "$script:MDEApiBase/liveresponse/library/files"
        $fileContent = [System.IO.File]::ReadAllBytes($SourcePath)
        $fileBase64 = [Convert]::ToBase64String($fileContent)
        
        $uploadBody = @{
            FileName = $fileName
            FileContent = $fileBase64
        } | ConvertTo-Json
        
        $uploadResult = Invoke-RestMethod -Method Post -Uri $libraryUri -Headers $headers -Body $uploadBody -ContentType "application/json"
        
        # Execute putfile command
        $params = @{
            FileName = $fileName
            DestinationPath = $DestinationPath
        }
        
        $command = Invoke-MDELiveResponseCommand -Token $Token -SessionId $SessionId -Command "putfile" -Parameters $params
        
        Write-Host "⏳ Waiting for file upload to complete..." -ForegroundColor Yellow
        $result = Wait-MDELiveResponseCommand -Token $Token -CommandId $command.id
        
        if ($result -and $result.status -eq "Completed") {
            Write-Verbose "File uploaded successfully to: $DestinationPath"
            return $true
        }
        
        return $false
        
    } catch {
        Write-Error "Failed to upload file: $($_.Exception.Message)"
        throw
    }
}

function Stop-MDELiveResponseSession {
    <#
    .SYNOPSIS
        Closes a Live Response session
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Session ID to close
        
    .EXAMPLE
        Stop-MDELiveResponseSession -Token $token -SessionId "session-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/liveresponse/sessions/$SessionId"
        $response = Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
        
        Write-Verbose "Live Response session closed: $SessionId"
        return $response
        
    } catch {
        Write-Error "Failed to close session: $($_.Exception.Message)"
        throw
    }
}

function Get-MDELiveResponseLibraryScripts {
    <#
    .SYNOPSIS
        Gets available scripts from the Live Response library
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .EXAMPLE
        Get-MDELiveResponseLibraryScripts -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/liveresponse/library/scripts"
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        
        return $response.value
        
    } catch {
        Write-Error "Failed to get library scripts: $($_.Exception.Message)"
        throw
    }
}

function Invoke-MDELiveResponseScript {
    <#
    .SYNOPSIS
        Runs a script from the Live Response library
        
    .PARAMETER Token
        Authentication token from Connect-MDE
        
    .PARAMETER SessionId
        Active session ID
        
    .PARAMETER ScriptName
        Name of the script in the library
        
    .PARAMETER Arguments
        Optional script arguments
        
    .EXAMPLE
        Invoke-MDELiveResponseScript -Token $token -SessionId "session-id" -ScriptName "CollectLogs.ps1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $false)]
        [string]$Arguments = ""
    )
    
    try {
        $params = @{
            ScriptName = $ScriptName
        }
        
        if (![string]::IsNullOrWhiteSpace($Arguments)) {
            $params.Arguments = $Arguments
        }
        
        $command = Invoke-MDELiveResponseCommand -Token $Token -SessionId $SessionId -Command "runscript" -Parameters $params
        
        Write-Host "⏳ Waiting for script to complete..." -ForegroundColor Yellow
        $result = Wait-MDELiveResponseCommand -Token $Token -CommandId $command.id
        
        return $result
        
    } catch {
        Write-Error "Failed to run script: $($_.Exception.Message)"
        throw
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Start-MDELiveResponseSession',
    'Get-MDELiveResponseSession',
    'Invoke-MDELiveResponseCommand',
    'Get-MDELiveResponseCommandResult',
    'Wait-MDELiveResponseCommand',
    'Get-MDELiveResponseFile',
    'Send-MDELiveResponseFile',
    'Stop-MDELiveResponseSession',
    'Get-MDELiveResponseLibraryScripts',
    'Invoke-MDELiveResponseScript'
)
