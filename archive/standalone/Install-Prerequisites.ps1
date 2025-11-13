<#
.SYNOPSIS
    Installation and prerequisite checker for MDE Automator Local
    
.DESCRIPTION
    Checks for and helps install required prerequisites for running the standalone MDE Automator
    
.EXAMPLE
    .\Install-Prerequisites.ps1
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                       ║" -ForegroundColor Cyan
Write-Host "║        MDE Automator Local - Prerequisites Installer                 ║" -ForegroundColor Cyan
Write-Host "║                                                                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
Write-Host "[1/3] Checking PowerShell version..." -ForegroundColor Yellow

$psVersion = $PSVersionTable.PSVersion
Write-Host "  Current version: $($psVersion.ToString())" -ForegroundColor Gray

if ($psVersion.Major -ge 7) {
    Write-Host "  ✓ PowerShell 7.0+ detected" -ForegroundColor Green
} else {
    Write-Host "  ✗ PowerShell 7.0 or later is required" -ForegroundColor Red
    Write-Host "  Download from: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
    
    $install = Read-Host "  Would you like to open the download page? (Y/N)"
    if ($install -eq 'Y' -or $install -eq 'y') {
        Start-Process "https://github.com/PowerShell/PowerShell/releases/latest"
    }
    
    Write-Host ""
    Write-Host "  Please install PowerShell 7+ and run this script again." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check internet connectivity
Write-Host "[2/3] Checking internet connectivity..." -ForegroundColor Yellow

try {
    $testConnection = Test-Connection -ComputerName "login.microsoftonline.com" -Count 1 -Quiet -ErrorAction Stop
    
    if ($testConnection) {
        Write-Host "  ✓ Internet connectivity verified" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Cannot reach Microsoft authentication endpoints" -ForegroundColor Red
        Write-Host "  Please check your internet connection and firewall settings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠ Could not test connectivity (this may be normal)" -ForegroundColor Yellow
}

Write-Host ""

# Check module files
Write-Host "[3/3] Checking module files..." -ForegroundColor Yellow

$requiredModules = @(
    "modules\MDEAuth.psm1"
    "modules\MDEConfig.psm1"
    "modules\MDEDevice.psm1"
    "modules\MDEThreatIntel.psm1"
    "modules\MDEHunting.psm1"
    "modules\MDEIncident.psm1"
    "modules\MDEDetection.psm1"
)

$allModulesPresent = $true

foreach ($module in $requiredModules) {
    $modulePath = Join-Path $PSScriptRoot $module
    
    if (Test-Path $modulePath) {
        Write-Host "  ✓ $module" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $module (missing)" -ForegroundColor Red
        $allModulesPresent = $false
    }
}

if (-not $allModulesPresent) {
    Write-Host ""
    Write-Host "  ✗ Some required modules are missing" -ForegroundColor Red
    Write-Host "  Please ensure you have downloaded the complete standalone package" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ All prerequisites are met!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create an Azure AD App Registration" -ForegroundColor White
Write-Host "     - See QUICKSTART.md for detailed instructions" -ForegroundColor Gray
Write-Host "  2. Grant required API permissions" -ForegroundColor White
Write-Host "     - See README.md for the complete permission list" -ForegroundColor Gray
Write-Host "  3. Run the MDE Automator" -ForegroundColor White
Write-Host "     - Execute: .\Start-MDEAutomatorLocal.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$launchNow = Read-Host "Would you like to launch MDE Automator now? (Y/N)"

if ($launchNow -eq 'Y' -or $launchNow -eq 'y') {
    Write-Host ""
    Write-Host "Launching MDE Automator..." -ForegroundColor Green
    Write-Host ""
    
    $launcherPath = Join-Path $PSScriptRoot "Start-MDEAutomatorLocal.ps1"
    
    if (Test-Path $launcherPath) {
        & $launcherPath
    } else {
        Write-Host "✗ Launcher script not found: $launcherPath" -ForegroundColor Red
    }
} else {
    Write-Host "You can launch MDE Automator anytime by running:" -ForegroundColor White
    Write-Host "  .\Start-MDEAutomatorLocal.ps1" -ForegroundColor Cyan
}
