<#
.SYNOPSIS
    Example: Bulk isolate devices based on risk score
    
.DESCRIPTION
    Demonstrates how to use the standalone framework modules programmatically
    to perform bulk operations without using the interactive menu.
    
.EXAMPLE
    .\bulk-isolate-devices.ps1 -TenantId "xxx" -AppId "xxx" -ClientSecret $secret
    
.NOTES
    This is an example script. Modify for your specific use case.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$AppId,
    
    [Parameter(Mandatory = $false)]
    [securestring]$ClientSecret,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("High", "Medium", "Low")]
    [string]$RiskScore = "High",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Import modules
$ScriptRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$ScriptRoot\modules\MDEAuth.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEDevice.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEConfig.psm1" -Force

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Bulk Device Isolation Script" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Load configuration if credentials not provided
if (-not $TenantId -or -not $AppId -or -not $ClientSecret) {
    Write-Host "Loading saved configuration..." -ForegroundColor Yellow
    $config = Get-MDEConfiguration
    
    if (-not $config) {
        Write-Host "✗ No saved configuration found. Please provide credentials." -ForegroundColor Red
        Write-Host ""
        Write-Host "Usage: .\bulk-isolate-devices.ps1 -TenantId <id> -AppId <id> -ClientSecret <secret>" -ForegroundColor Yellow
        exit 1
    }
    
    $TenantId = $config.TenantId
    $AppId = $config.AppId
    $ClientSecret = $config.ClientSecret
    
    Write-Host "✓ Configuration loaded" -ForegroundColor Green
}

Write-Host ""

# Authenticate
Write-Host "Authenticating to Microsoft Defender..." -ForegroundColor Yellow
try {
    $token = Connect-MDE -TenantId $TenantId -AppId $AppId -ClientSecret $ClientSecret
    Write-Host "✓ Authentication successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get all devices
Write-Host "Retrieving devices with risk score: $RiskScore..." -ForegroundColor Yellow
try {
    $filter = "riskScore eq '$RiskScore'"
    $devices = Get-AllDevices -Token $token -Filter $filter
    
    if ($devices.Count -eq 0) {
        Write-Host "✓ No devices found with risk score: $RiskScore" -ForegroundColor Green
        Write-Host ""
        exit 0
    }
    
    Write-Host "✓ Found $($devices.Count) device(s) with $RiskScore risk score" -ForegroundColor Yellow
    Write-Host ""
    
    # Display devices
    $devices | Format-Table -Property id, computerDnsName, osPlatform, riskScore, healthStatus -AutoSize
    
} catch {
    Write-Host "✗ Failed to retrieve devices: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Confirm action
if (-not $WhatIf) {
    Write-Host "⚠ WARNING: This will ISOLATE $($devices.Count) device(s)!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "Type 'ISOLATE' to confirm"
    
    if ($confirm -ne 'ISOLATE') {
        Write-Host "✗ Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "WhatIf mode: Would isolate $($devices.Count) device(s)" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host ""

# Isolate devices
Write-Host "Isolating devices..." -ForegroundColor Yellow
Write-Host ""

$results = @()
$successCount = 0
$failureCount = 0

foreach ($device in $devices) {
    try {
        Write-Host "  ► Isolating: $($device.computerDnsName) ($($device.id))" -ForegroundColor Gray
        
        $result = Invoke-DeviceIsolation -Token $token -DeviceIds @($device.id) `
            -Comment "Automated isolation - High risk score detected" `
            -IsolationType "Full"
        
        $results += [PSCustomObject]@{
            DeviceName = $device.computerDnsName
            DeviceId   = $device.id
            ActionId   = $result.id
            Status     = "Success"
            Error      = $null
        }
        
        Write-Host "    ✓ Success - Action ID: $($result.id)" -ForegroundColor Green
        $successCount++
        
    } catch {
        $results += [PSCustomObject]@{
            DeviceName = $device.computerDnsName
            DeviceId   = $device.id
            ActionId   = $null
            Status     = "Failed"
            Error      = $_.Exception.Message
        }
        
        Write-Host "    ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
        $failureCount++
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total Devices:    $($devices.Count)" -ForegroundColor White
Write-Host "  Successful:       $successCount" -ForegroundColor Green
Write-Host "  Failed:           $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Export results
$exportPath = Join-Path $PSScriptRoot "isolation-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "✓ Results exported to: $exportPath" -ForegroundColor Green
Write-Host ""

# Display failed devices if any
if ($failureCount -gt 0) {
    Write-Host "Failed Devices:" -ForegroundColor Red
    $results | Where-Object { $_.Status -eq "Failed" } | Format-Table -AutoSize
}

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
