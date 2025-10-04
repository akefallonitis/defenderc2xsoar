<#
.SYNOPSIS
    Standalone PowerShell Framework for Microsoft Defender for Endpoint Automation
    
.DESCRIPTION
    A local version of the MDEAutomator with a menu-driven UI for managing MDE operations
    without requiring Azure infrastructure. Similar to the original MDEAutomator interface.
    
.EXAMPLE
    .\Start-MDEAutomatorLocal.ps1
    
.NOTES
    Requires PowerShell 7.0 or later
    Requires internet connectivity to Microsoft Defender API endpoints
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import required modules
$ScriptRoot = $PSScriptRoot
Import-Module "$ScriptRoot\modules\MDEAuth.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEDevice.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEThreatIntel.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEHunting.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEIncident.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEDetection.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEConfig.psm1" -Force
Import-Module "$ScriptRoot\modules\MDELiveResponse.psm1" -Force

# Global variables
$script:Token = $null
$script:Config = $null
$script:LiveResponseSession = $null
$script:CommandHistory = @()

function Show-Banner {
    Clear-Host
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "║        MDE Automator - Standalone PowerShell Framework                ║" -ForegroundColor Cyan
    Write-Host "║        Local Edition                                                  ║" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if ($script:Token) {
        Write-Host "✓ Connected to tenant: " -NoNewline -ForegroundColor Green
        Write-Host $script:Config.TenantId -ForegroundColor Yellow
    } else {
        Write-Host "✗ Not authenticated" -ForegroundColor Red
    }
    Write-Host ""
}

function Show-MainMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Main Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  Authentication & Configuration" -ForegroundColor White
    Write-Host " 2.  Device Actions (Isolate, Scan, etc.)" -ForegroundColor White
    Write-Host " 3.  Threat Intelligence Manager" -ForegroundColor White
    Write-Host " 4.  Advanced Hunting" -ForegroundColor White
    Write-Host " 5.  Incident Manager" -ForegroundColor White
    Write-Host " 6.  Custom Detection Manager" -ForegroundColor White
    Write-Host " 7.  Action Manager (View/Cancel Actions)" -ForegroundColor White
    Write-Host " 8.  Live Response Operations" -ForegroundColor White
    Write-Host " 9.  View Current Configuration" -ForegroundColor White
    Write-Host " 0.  Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-DeviceActionsMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Device Actions Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  Isolate Device(s)" -ForegroundColor White
    Write-Host " 2.  Release Device(s) from Isolation" -ForegroundColor White
    Write-Host " 3.  Restrict App Execution" -ForegroundColor White
    Write-Host " 4.  Remove App Execution Restriction" -ForegroundColor White
    Write-Host " 5.  Run Antivirus Scan" -ForegroundColor White
    Write-Host " 6.  Collect Investigation Package" -ForegroundColor White
    Write-Host " 7.  Stop and Quarantine File" -ForegroundColor White
    Write-Host " 8.  Get Device Information" -ForegroundColor White
    Write-Host " 9.  List All Devices" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-ThreatIntelMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Threat Intelligence Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  Add File Indicator (SHA256)" -ForegroundColor White
    Write-Host " 2.  Remove File Indicator" -ForegroundColor White
    Write-Host " 3.  Add IP Indicator" -ForegroundColor White
    Write-Host " 4.  Remove IP Indicator" -ForegroundColor White
    Write-Host " 5.  Add URL/Domain Indicator" -ForegroundColor White
    Write-Host " 6.  Remove URL/Domain Indicator" -ForegroundColor White
    Write-Host " 7.  Add Certificate Indicator (SHA1)" -ForegroundColor White
    Write-Host " 8.  Remove Certificate Indicator" -ForegroundColor White
    Write-Host " 9.  List All Indicators" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-HuntingMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Advanced Hunting Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  Execute Custom KQL Query" -ForegroundColor White
    Write-Host " 2.  Run Saved Query from Library" -ForegroundColor White
    Write-Host " 3.  Save Query to Library" -ForegroundColor White
    Write-Host " 4.  List Query Library" -ForegroundColor White
    Write-Host " 5.  Export Results to CSV" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-IncidentMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Incident Manager Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  List All Incidents" -ForegroundColor White
    Write-Host " 2.  Get Incident Details" -ForegroundColor White
    Write-Host " 3.  Update Incident Status" -ForegroundColor White
    Write-Host " 4.  Update Incident Classification" -ForegroundColor White
    Write-Host " 5.  Add Comment to Incident" -ForegroundColor White
    Write-Host " 6.  Filter Incidents (High Severity)" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-DetectionMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Custom Detection Manager Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  List All Custom Detections" -ForegroundColor White
    Write-Host " 2.  Get Detection Details" -ForegroundColor White
    Write-Host " 3.  Create New Detection Rule" -ForegroundColor White
    Write-Host " 4.  Update Detection Rule" -ForegroundColor White
    Write-Host " 5.  Delete Detection Rule" -ForegroundColor White
    Write-Host " 6.  Enable/Disable Detection Rule" -ForegroundColor White
    Write-Host " 7.  Backup All Detections to File" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-ActionManagerMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Action Manager Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  List All Machine Actions" -ForegroundColor White
    Write-Host " 2.  Get Action Details" -ForegroundColor White
    Write-Host " 3.  Cancel Pending Action" -ForegroundColor White
    Write-Host " 4.  Cancel All Pending Actions" -ForegroundColor White
    Write-Host " 5.  Filter Actions by Status" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-LiveResponseMenu {
    Show-Banner
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Live Response Menu" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1.  Interactive Shell (Connect to Device)" -ForegroundColor White
    Write-Host " 2.  Run Live Response Script" -ForegroundColor White
    Write-Host " 3.  Get File from Device" -ForegroundColor White
    Write-Host " 4.  Put File to Device" -ForegroundColor White
    Write-Host " 5.  List Available Scripts in Library" -ForegroundColor White
    Write-Host " 6.  View Active Sessions" -ForegroundColor White
    Write-Host " 0.  Back to Main Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-InteractiveShellBanner {
    param(
        [string]$DeviceId,
        [string]$SessionId,
        [string]$Status
    )
    
    Clear-Host
    # Black background with green text theme
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green -BackgroundColor Black
    Write-Host "║              LIVE RESPONSE - INTERACTIVE SHELL                        ║" -ForegroundColor Green -BackgroundColor Black
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green -BackgroundColor Black
    Write-Host ""
    Write-Host "Device ID    : " -NoNewline -ForegroundColor Green -BackgroundColor Black
    Write-Host $DeviceId -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "Session ID   : " -NoNewline -ForegroundColor Green -BackgroundColor Black
    Write-Host $SessionId -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "Status       : " -NoNewline -ForegroundColor Green -BackgroundColor Black
    Write-Host $Status -ForegroundColor $(if ($Status -eq "Active") { "Green" } else { "Red" }) -BackgroundColor Black
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Green -BackgroundColor Black
    Write-Host ""
}

function Show-CommandHistoryPanel {
    param(
        [array]$History,
        [int]$MaxLines = 10
    )
    
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green -BackgroundColor Black
    Write-Host "║  COMMAND HISTORY (Last $MaxLines)                                      " -ForegroundColor Green -BackgroundColor Black -NoNewline
    Write-Host "║" -ForegroundColor Green -BackgroundColor Black
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green -BackgroundColor Black
    
    $recentHistory = $History | Select-Object -Last $MaxLines
    foreach ($entry in $recentHistory) {
        $timestamp = $entry.Timestamp.ToString("HH:mm:ss")
        $statusIcon = switch ($entry.Status) {
            "Completed" { "✓" }
            "Failed" { "✗" }
            "InProgress" { "⏳" }
            "Pending" { "⏸" }
            default { "?" }
        }
        
        $statusColor = switch ($entry.Status) {
            "Completed" { "Green" }
            "Failed" { "Red" }
            "InProgress" { "Yellow" }
            "Pending" { "Gray" }
            default { "White" }
        }
        
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray -BackgroundColor Black
        Write-Host "$statusIcon " -NoNewline -ForegroundColor $statusColor -BackgroundColor Black
        Write-Host $entry.Command -ForegroundColor White -BackgroundColor Black
    }
    Write-Host ""
}

function Invoke-InteractiveShell {
    param(
        [hashtable]$Token,
        [string]$DeviceId,
        [string]$SessionId
    )
    
    $continue = $true
    
    while ($continue) {
        # Get session status
        try {
            $session = Get-MDELiveResponseSession -Token $Token -SessionId $SessionId
            $sessionStatus = $session.status
        } catch {
            $sessionStatus = "Unknown"
        }
        
        # Split screen display
        Show-InteractiveShellBanner -DeviceId $DeviceId -SessionId $SessionId -Status $sessionStatus
        Show-CommandHistoryPanel -History $script:CommandHistory
        
        # Command prompt
        Write-Host "Commands: " -NoNewline -ForegroundColor Green -BackgroundColor Black
        Write-Host "help, dir <path>, getfile, putfile, runscript, exit" -ForegroundColor Yellow -BackgroundColor Black
        Write-Host ""
        Write-Host "LR> " -NoNewline -ForegroundColor Green -BackgroundColor Black
        $input = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }
        
        # Parse command
        $parts = $input -split '\s+', 2
        $command = $parts[0].ToLower()
        $args = if ($parts.Length -gt 1) { $parts[1] } else { "" }
        
        switch ($command) {
            "help" {
                Write-Host ""
                Write-Host "Available Commands:" -ForegroundColor Green -BackgroundColor Black
                Write-Host "  help              - Show this help message" -ForegroundColor White -BackgroundColor Black
                Write-Host "  dir <path>        - List directory contents" -ForegroundColor White -BackgroundColor Black
                Write-Host "  getfile <path>    - Download file from device" -ForegroundColor White -BackgroundColor Black
                Write-Host "  putfile <path>    - Upload file to device" -ForegroundColor White -BackgroundColor Black
                Write-Host "  runscript <name>  - Execute script from library" -ForegroundColor White -BackgroundColor Black
                Write-Host "  run <command>     - Execute arbitrary command" -ForegroundColor White -BackgroundColor Black
                Write-Host "  history           - Show command history" -ForegroundColor White -BackgroundColor Black
                Write-Host "  clear             - Clear screen" -ForegroundColor White -BackgroundColor Black
                Write-Host "  exit              - Close session and return" -ForegroundColor White -BackgroundColor Black
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "dir" {
                $path = if ([string]::IsNullOrWhiteSpace($args)) { "C:\" } else { $args }
                
                Write-Host ""
                Write-Host "⏳ Listing directory: $path" -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    $params = @{
                        Path = $path
                    }
                    
                    $cmd = Invoke-MDELiveResponseCommand -Token $Token -SessionId $SessionId -Command "dir" -Parameters $params
                    
                    # Add to history
                    $script:CommandHistory += @{
                        Timestamp = Get-Date
                        Command = "dir $path"
                        Status = "Pending"
                        CommandId = $cmd.id
                    }
                    
                    # Wait for result
                    $result = Wait-MDELiveResponseCommand -Token $Token -CommandId $cmd.id -PollingIntervalSeconds 3
                    
                    # Update history
                    $historyEntry = $script:CommandHistory | Where-Object { $_.CommandId -eq $cmd.id }
                    if ($historyEntry) {
                        $historyEntry.Status = $result.status
                    }
                    
                    if ($result.status -eq "Completed") {
                        Write-Host ""
                        Write-Host "✓ Directory listing:" -ForegroundColor Green -BackgroundColor Black
                        Write-Host $result.value -ForegroundColor White -BackgroundColor Black
                    } else {
                        Write-Host ""
                        Write-Host "✗ Command failed: $($result.error)" -ForegroundColor Red -BackgroundColor Black
                    }
                    
                } catch {
                    Write-Host ""
                    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "getfile" {
                if ([string]::IsNullOrWhiteSpace($args)) {
                    Write-Host ""
                    Write-Host "✗ Usage: getfile <remote_path>" -ForegroundColor Red -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue
                }
                
                $remotePath = $args
                Write-Host ""
                Write-Host "Enter local destination path: " -NoNewline -ForegroundColor Green -BackgroundColor Black
                $localPath = Read-Host
                
                if ([string]::IsNullOrWhiteSpace($localPath)) {
                    $localPath = Join-Path $env:TEMP (Split-Path -Leaf $remotePath)
                }
                
                Write-Host ""
                Write-Host "⏳ Downloading file: $remotePath" -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    $success = Get-MDELiveResponseFile -Token $Token -SessionId $SessionId -FilePath $remotePath -DestinationPath $localPath
                    
                    $script:CommandHistory += @{
                        Timestamp = Get-Date
                        Command = "getfile $remotePath"
                        Status = if ($success) { "Completed" } else { "Failed" }
                        CommandId = $null
                    }
                    
                    if ($success) {
                        Write-Host ""
                        Write-Host "✓ File downloaded to: $localPath" -ForegroundColor Green -BackgroundColor Black
                    } else {
                        Write-Host ""
                        Write-Host "✗ File download failed" -ForegroundColor Red -BackgroundColor Black
                    }
                    
                } catch {
                    Write-Host ""
                    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "putfile" {
                if ([string]::IsNullOrWhiteSpace($args)) {
                    Write-Host ""
                    Write-Host "✗ Usage: putfile <local_path>" -ForegroundColor Red -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue
                }
                
                $localPath = $args
                
                if (-not (Test-Path $localPath)) {
                    Write-Host ""
                    Write-Host "✗ File not found: $localPath" -ForegroundColor Red -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue
                }
                
                Write-Host ""
                Write-Host "Enter remote destination path: " -NoNewline -ForegroundColor Green -BackgroundColor Black
                $remotePath = Read-Host
                
                if ([string]::IsNullOrWhiteSpace($remotePath)) {
                    $remotePath = "C:\Temp\" + (Split-Path -Leaf $localPath)
                }
                
                Write-Host ""
                Write-Host "⏳ Uploading file: $localPath" -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    $success = Send-MDELiveResponseFile -Token $Token -SessionId $SessionId -SourcePath $localPath -DestinationPath $remotePath
                    
                    $script:CommandHistory += @{
                        Timestamp = Get-Date
                        Command = "putfile $localPath"
                        Status = if ($success) { "Completed" } else { "Failed" }
                        CommandId = $null
                    }
                    
                    if ($success) {
                        Write-Host ""
                        Write-Host "✓ File uploaded to: $remotePath" -ForegroundColor Green -BackgroundColor Black
                    } else {
                        Write-Host ""
                        Write-Host "✗ File upload failed" -ForegroundColor Red -BackgroundColor Black
                    }
                    
                } catch {
                    Write-Host ""
                    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "runscript" {
                if ([string]::IsNullOrWhiteSpace($args)) {
                    Write-Host ""
                    Write-Host "✗ Usage: runscript <script_name> [arguments]" -ForegroundColor Red -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue
                }
                
                $scriptParts = $args -split '\s+', 2
                $scriptName = $scriptParts[0]
                $scriptArgs = if ($scriptParts.Length -gt 1) { $scriptParts[1] } else { "" }
                
                Write-Host ""
                Write-Host "⏳ Running script: $scriptName" -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    $result = Invoke-MDELiveResponseScript -Token $Token -SessionId $SessionId -ScriptName $scriptName -Arguments $scriptArgs
                    
                    $script:CommandHistory += @{
                        Timestamp = Get-Date
                        Command = "runscript $scriptName"
                        Status = $result.status
                        CommandId = $result.id
                    }
                    
                    if ($result.status -eq "Completed") {
                        Write-Host ""
                        Write-Host "✓ Script completed:" -ForegroundColor Green -BackgroundColor Black
                        Write-Host $result.value -ForegroundColor White -BackgroundColor Black
                    } else {
                        Write-Host ""
                        Write-Host "✗ Script failed: $($result.error)" -ForegroundColor Red -BackgroundColor Black
                    }
                    
                } catch {
                    Write-Host ""
                    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "run" {
                if ([string]::IsNullOrWhiteSpace($args)) {
                    Write-Host ""
                    Write-Host "✗ Usage: run <command>" -ForegroundColor Red -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    continue
                }
                
                Write-Host ""
                Write-Host "⏳ Executing: $args" -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    $params = @{
                        CommandLine = $args
                    }
                    
                    $cmd = Invoke-MDELiveResponseCommand -Token $Token -SessionId $SessionId -Command "RunCommand" -Parameters $params
                    
                    $script:CommandHistory += @{
                        Timestamp = Get-Date
                        Command = "run $args"
                        Status = "Pending"
                        CommandId = $cmd.id
                    }
                    
                    $result = Wait-MDELiveResponseCommand -Token $Token -CommandId $cmd.id -PollingIntervalSeconds 3
                    
                    $historyEntry = $script:CommandHistory | Where-Object { $_.CommandId -eq $cmd.id }
                    if ($historyEntry) {
                        $historyEntry.Status = $result.status
                    }
                    
                    if ($result.status -eq "Completed") {
                        Write-Host ""
                        Write-Host "✓ Command output:" -ForegroundColor Green -BackgroundColor Black
                        Write-Host $result.value -ForegroundColor White -BackgroundColor Black
                    } else {
                        Write-Host ""
                        Write-Host "✗ Command failed: $($result.error)" -ForegroundColor Red -BackgroundColor Black
                    }
                    
                } catch {
                    Write-Host ""
                    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "history" {
                Write-Host ""
                Write-Host "Command History:" -ForegroundColor Green -BackgroundColor Black
                Write-Host ""
                
                foreach ($entry in $script:CommandHistory) {
                    $timestamp = $entry.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $statusIcon = switch ($entry.Status) {
                        "Completed" { "✓" }
                        "Failed" { "✗" }
                        "InProgress" { "⏳" }
                        "Pending" { "⏸" }
                        default { "?" }
                    }
                    
                    Write-Host "[$timestamp] $statusIcon $($entry.Command)" -ForegroundColor White -BackgroundColor Black
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "clear" {
                # Just continue to refresh
                continue
            }
            "exit" {
                Write-Host ""
                Write-Host "Closing session..." -ForegroundColor Yellow -BackgroundColor Black
                
                try {
                    Stop-MDELiveResponseSession -Token $Token -SessionId $SessionId
                    Write-Host "✓ Session closed" -ForegroundColor Green -BackgroundColor Black
                } catch {
                    Write-Host "✗ Error closing session: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
                
                $script:LiveResponseSession = $null
                $continue = $false
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            default {
                Write-Host ""
                Write-Host "✗ Unknown command: $command" -ForegroundColor Red -BackgroundColor Black
                Write-Host "Type 'help' for available commands" -ForegroundColor Yellow -BackgroundColor Black
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}

function Invoke-Authentication {
    Show-Banner
    Write-Host "Authentication & Configuration" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Load or create configuration
        $script:Config = Get-MDEConfiguration
        
        if (-not $script:Config) {
            Write-Host "No configuration found. Let's set up your credentials." -ForegroundColor Yellow
            Write-Host ""
            
            $tenantId = Read-Host "Enter your Tenant ID"
            $appId = Read-Host "Enter your Application (Client) ID"
            $clientSecret = Read-Host "Enter your Client Secret" -AsSecureString
            
            $script:Config = @{
                TenantId = $tenantId
                AppId = $appId
                ClientSecret = $clientSecret
            }
            
            # Save configuration
            $save = Read-Host "Save configuration for future sessions? (Y/N)"
            if ($save -eq 'Y' -or $save -eq 'y') {
                Save-MDEConfiguration -Config $script:Config
                Write-Host "✓ Configuration saved" -ForegroundColor Green
            }
        } else {
            Write-Host "✓ Configuration loaded" -ForegroundColor Green
            Write-Host "  Tenant ID: $($script:Config.TenantId)" -ForegroundColor Gray
            Write-Host ""
            
            $reauth = Read-Host "Use existing configuration? (Y/N)"
            if ($reauth -eq 'N' -or $reauth -eq 'n') {
                $tenantId = Read-Host "Enter your Tenant ID"
                $appId = Read-Host "Enter your Application (Client) ID"
                $clientSecret = Read-Host "Enter your Client Secret" -AsSecureString
                
                $script:Config = @{
                    TenantId = $tenantId
                    AppId = $appId
                    ClientSecret = $clientSecret
                }
                
                Save-MDEConfiguration -Config $script:Config
            }
        }
        
        # Authenticate
        Write-Host ""
        Write-Host "Authenticating..." -ForegroundColor Yellow
        $script:Token = Connect-MDE -TenantId $script:Config.TenantId -AppId $script:Config.AppId -ClientSecret $script:Config.ClientSecret
        
        Write-Host "✓ Successfully authenticated!" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "✗ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-DeviceActionsMenu {
    do {
        Show-DeviceActionsMenu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $comment = Read-Host "Enter isolation reason/comment"
                $isolationType = Read-Host "Isolation type (Full/Selective) [Full]"
                if ([string]::IsNullOrWhiteSpace($isolationType)) { $isolationType = "Full" }
                
                try {
                    Write-Host "Initiating device isolation..." -ForegroundColor Yellow
                    $result = Invoke-DeviceIsolation -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -Comment $comment -IsolationType $isolationType
                    Write-Host "✓ Device isolation initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $comment = Read-Host "Enter release reason/comment"
                
                try {
                    Write-Host "Releasing device from isolation..." -ForegroundColor Yellow
                    $result = Invoke-DeviceUnisolation -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -Comment $comment
                    Write-Host "✓ Device release initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $comment = Read-Host "Enter restriction reason/comment"
                
                try {
                    Write-Host "Restricting app execution..." -ForegroundColor Yellow
                    $result = Invoke-RestrictAppExecution -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -Comment $comment
                    Write-Host "✓ App execution restriction initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $comment = Read-Host "Enter unrestriction reason/comment"
                
                try {
                    Write-Host "Removing app execution restriction..." -ForegroundColor Yellow
                    $result = Invoke-UnrestrictAppExecution -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -Comment $comment
                    Write-Host "✓ App execution unrestriction initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $scanType = Read-Host "Scan type (Quick/Full) [Full]"
                if ([string]::IsNullOrWhiteSpace($scanType)) { $scanType = "Full" }
                $comment = Read-Host "Enter scan reason/comment"
                
                try {
                    Write-Host "Initiating antivirus scan..." -ForegroundColor Yellow
                    $result = Invoke-AntivirusScan -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -ScanType $scanType -Comment $comment
                    Write-Host "✓ Antivirus scan initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceIds = Read-Host "Enter Device ID(s) (comma-separated)"
                $comment = Read-Host "Enter collection reason/comment"
                
                try {
                    Write-Host "Collecting investigation package..." -ForegroundColor Yellow
                    $result = Invoke-CollectInvestigationPackage -Token $script:Token -DeviceIds $deviceIds.Split(',').Trim() -Comment $comment
                    Write-Host "✓ Investigation package collection initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID(s): $($result.id -join ', ')" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $fileHash = Read-Host "Enter File SHA1 Hash"
                $comment = Read-Host "Enter quarantine reason/comment"
                
                try {
                    Write-Host "Stopping and quarantining file..." -ForegroundColor Yellow
                    $result = Invoke-StopAndQuarantineFile -Token $script:Token -Sha1 $fileHash -Comment $comment
                    Write-Host "✓ Stop and quarantine initiated successfully!" -ForegroundColor Green
                    Write-Host "Action ID: $($result.id)" -ForegroundColor Gray
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceId = Read-Host "Enter Device ID"
                
                try {
                    Write-Host "Retrieving device information..." -ForegroundColor Yellow
                    $device = Get-DeviceInfo -Token $script:Token -DeviceId $deviceId
                    
                    Write-Host ""
                    Write-Host "Device Information:" -ForegroundColor Green
                    Write-Host "  Computer Name: $($device.computerDnsName)" -ForegroundColor White
                    Write-Host "  OS Platform: $($device.osPlatform)" -ForegroundColor White
                    Write-Host "  OS Version: $($device.osVersion)" -ForegroundColor White
                    Write-Host "  Risk Score: $($device.riskScore)" -ForegroundColor White
                    Write-Host "  Health Status: $($device.healthStatus)" -ForegroundColor White
                    Write-Host "  Last Seen: $($device.lastSeen)" -ForegroundColor White
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "9" {
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                try {
                    Write-Host ""
                    Write-Host "Retrieving all devices..." -ForegroundColor Yellow
                    $devices = Get-AllDevices -Token $script:Token
                    
                    Write-Host ""
                    Write-Host "Total Devices: $($devices.Count)" -ForegroundColor Green
                    Write-Host ""
                    
                    $devices | Format-Table -Property id, computerDnsName, osPlatform, riskScore, healthStatus, lastSeen -AutoSize
                    
                    $export = Read-Host "Export to CSV? (Y/N)"
                    if ($export -eq 'Y' -or $export -eq 'y') {
                        $exportPath = Join-Path $PSScriptRoot "devices_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                        $devices | Export-Csv -Path $exportPath -NoTypeInformation
                        Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                return
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Invoke-LiveResponseMenu {
    do {
        Show-LiveResponseMenu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" {
                # Interactive Shell
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceId = Read-Host "Enter Device ID to connect"
                
                if ([string]::IsNullOrWhiteSpace($deviceId)) {
                    Write-Host "✗ Device ID is required" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                try {
                    Write-Host ""
                    Write-Host "⏳ Initiating Live Response session..." -ForegroundColor Yellow
                    $session = Start-MDELiveResponseSession -Token $script:Token -DeviceId $deviceId -Comment "Interactive Shell Session"
                    
                    Write-Host "⏳ Waiting for session to become active..." -ForegroundColor Yellow
                    
                    # Wait for session to become active
                    $maxWait = 60
                    $waited = 0
                    $sessionStatus = "Pending"
                    
                    while ($sessionStatus -ne "Active" -and $waited -lt $maxWait) {
                        Start-Sleep -Seconds 3
                        $waited += 3
                        
                        $sessionInfo = Get-MDELiveResponseSession -Token $script:Token -SessionId $session.id
                        $sessionStatus = $sessionInfo.status
                        
                        Write-Host "  Status: $sessionStatus" -ForegroundColor Gray
                    }
                    
                    if ($sessionStatus -eq "Active") {
                        Write-Host "✓ Session established!" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "Press any key to enter interactive shell..."
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        
                        $script:LiveResponseSession = $session
                        $script:CommandHistory = @()
                        
                        # Enter interactive shell
                        Invoke-InteractiveShell -Token $script:Token -DeviceId $deviceId -SessionId $session.id
                    } else {
                        Write-Host "✗ Session failed to become active (Status: $sessionStatus)" -ForegroundColor Red
                        Write-Host ""
                        Write-Host "Press any key to continue..."
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                    
                } catch {
                    Write-Host "✗ Failed to start session: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "Press any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "2" {
                # Run Live Response Script
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceId = Read-Host "Enter Device ID"
                $scriptName = Read-Host "Enter script name from library"
                $scriptArgs = Read-Host "Enter script arguments (optional)"
                
                try {
                    Write-Host ""
                    Write-Host "⏳ Starting Live Response session..." -ForegroundColor Yellow
                    $session = Start-MDELiveResponseSession -Token $script:Token -DeviceId $deviceId -Comment "Run Script: $scriptName"
                    
                    # Wait for session
                    Start-Sleep -Seconds 5
                    
                    Write-Host "⏳ Running script..." -ForegroundColor Yellow
                    $result = Invoke-MDELiveResponseScript -Token $script:Token -SessionId $session.id -ScriptName $scriptName -Arguments $scriptArgs
                    
                    if ($result.status -eq "Completed") {
                        Write-Host ""
                        Write-Host "✓ Script completed successfully!" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "Output:" -ForegroundColor Yellow
                        Write-Host $result.value -ForegroundColor White
                    } else {
                        Write-Host ""
                        Write-Host "✗ Script failed: $($result.error)" -ForegroundColor Red
                    }
                    
                    # Clean up session
                    Stop-MDELiveResponseSession -Token $script:Token -SessionId $session.id | Out-Null
                    
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                # Get File from Device
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceId = Read-Host "Enter Device ID"
                $remotePath = Read-Host "Enter remote file path"
                $localPath = Read-Host "Enter local destination path"
                
                if ([string]::IsNullOrWhiteSpace($localPath)) {
                    $localPath = Join-Path $env:TEMP (Split-Path -Leaf $remotePath)
                }
                
                try {
                    Write-Host ""
                    Write-Host "⏳ Starting Live Response session..." -ForegroundColor Yellow
                    $session = Start-MDELiveResponseSession -Token $script:Token -DeviceId $deviceId -Comment "Get File: $remotePath"
                    
                    # Wait for session
                    Start-Sleep -Seconds 5
                    
                    Write-Host "⏳ Downloading file..." -ForegroundColor Yellow
                    $success = Get-MDELiveResponseFile -Token $script:Token -SessionId $session.id -FilePath $remotePath -DestinationPath $localPath
                    
                    if ($success) {
                        Write-Host ""
                        Write-Host "✓ File downloaded to: $localPath" -ForegroundColor Green
                    } else {
                        Write-Host ""
                        Write-Host "✗ File download failed" -ForegroundColor Red
                    }
                    
                    # Clean up session
                    Stop-MDELiveResponseSession -Token $script:Token -SessionId $session.id | Out-Null
                    
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                # Put File to Device
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                $deviceId = Read-Host "Enter Device ID"
                $localPath = Read-Host "Enter local file path"
                
                if (-not (Test-Path $localPath)) {
                    Write-Host "✗ File not found: $localPath" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                $remotePath = Read-Host "Enter remote destination path"
                
                if ([string]::IsNullOrWhiteSpace($remotePath)) {
                    $remotePath = "C:\Temp\" + (Split-Path -Leaf $localPath)
                }
                
                try {
                    Write-Host ""
                    Write-Host "⏳ Starting Live Response session..." -ForegroundColor Yellow
                    $session = Start-MDELiveResponseSession -Token $script:Token -DeviceId $deviceId -Comment "Put File: $(Split-Path -Leaf $localPath)"
                    
                    # Wait for session
                    Start-Sleep -Seconds 5
                    
                    Write-Host "⏳ Uploading file..." -ForegroundColor Yellow
                    $success = Send-MDELiveResponseFile -Token $script:Token -SessionId $session.id -SourcePath $localPath -DestinationPath $remotePath
                    
                    if ($success) {
                        Write-Host ""
                        Write-Host "✓ File uploaded to: $remotePath" -ForegroundColor Green
                    } else {
                        Write-Host ""
                        Write-Host "✗ File upload failed" -ForegroundColor Red
                    }
                    
                    # Clean up session
                    Stop-MDELiveResponseSession -Token $script:Token -SessionId $session.id | Out-Null
                    
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                # List Available Scripts
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                try {
                    Write-Host ""
                    Write-Host "⏳ Retrieving library scripts..." -ForegroundColor Yellow
                    $scripts = Get-MDELiveResponseLibraryScripts -Token $script:Token
                    
                    Write-Host ""
                    Write-Host "Available Scripts in Library:" -ForegroundColor Green
                    Write-Host ""
                    
                    if ($scripts.Count -eq 0) {
                        Write-Host "No scripts found in the library" -ForegroundColor Yellow
                    } else {
                        $scripts | Format-Table -Property fileName, description -AutoSize
                    }
                    
                } catch {
                    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                # View Active Sessions
                if (-not $script:Token) {
                    Write-Host "✗ Please authenticate first (Option 1 in Main Menu)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }
                
                Write-Host ""
                if ($script:LiveResponseSession) {
                    Write-Host "Active Session:" -ForegroundColor Green
                    Write-Host "  Session ID: $($script:LiveResponseSession.id)" -ForegroundColor White
                    Write-Host "  Device ID: $($script:LiveResponseSession.machineId)" -ForegroundColor White
                    Write-Host "  Status: $($script:LiveResponseSession.status)" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Command History: $($script:CommandHistory.Count) commands" -ForegroundColor Gray
                } else {
                    Write-Host "No active sessions" -ForegroundColor Yellow
                }
                
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                return
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# Main program loop
try {
    do {
        Show-MainMenu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" { Invoke-Authentication }
            "2" { Invoke-DeviceActionsMenu }
            "3" { 
                Write-Host "Threat Intelligence Manager - Coming soon in this menu!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "4" { 
                Write-Host "Advanced Hunting - Coming soon in this menu!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "5" { 
                Write-Host "Incident Manager - Coming soon in this menu!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "6" { 
                Write-Host "Custom Detection Manager - Coming soon in this menu!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "7" { 
                Write-Host "Action Manager - Coming soon in this menu!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "8" { 
                Invoke-LiveResponseMenu
            }
            "9" {
                Show-Banner
                if ($script:Config) {
                    Write-Host "Current Configuration:" -ForegroundColor Yellow
                    Write-Host "  Tenant ID: $($script:Config.TenantId)" -ForegroundColor White
                    Write-Host "  App ID: $($script:Config.AppId)" -ForegroundColor White
                    Write-Host "  Token Status: $(if ($script:Token) { '✓ Valid' } else { '✗ Not authenticated' })" -ForegroundColor White
                } else {
                    Write-Host "✗ No configuration loaded" -ForegroundColor Red
                }
                Write-Host ""
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                Write-Host ""
                Write-Host "Thank you for using MDE Automator!" -ForegroundColor Cyan
                Write-Host ""
                exit
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
    
} catch {
    Write-Host ""
    Write-Host "✗ An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
