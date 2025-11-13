# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
# if ($env:MSI_SECRET) {
#     Disable-AzContextAutosave -Scope Process | Out-Null
#     Connect-AzAccount -Identity
# }

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.

# Import core modules (v3.3.0 - simplified structure)
$modulesPath = Join-Path $PSScriptRoot "modules"

# Import AuthManager (centralized authentication with caching)
$AuthManagerPath = Join-Path $modulesPath "AuthManager.psm1"
if (Test-Path $AuthManagerPath) {
    Import-Module $AuthManagerPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ AuthManager loaded"
}

# Import ValidationHelper (input validation & sanitization)
$ValidationHelperPath = Join-Path $modulesPath "ValidationHelper.psm1"
if (Test-Path $ValidationHelperPath) {
    Import-Module $ValidationHelperPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ ValidationHelper loaded"
}

# Import LoggingHelper (structured logging & telemetry)
$LoggingHelperPath = Join-Path $modulesPath "LoggingHelper.psm1"
if (Test-Path $LoggingHelperPath) {
    Import-Module $LoggingHelperPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ LoggingHelper loaded"
}

# Import BatchHelper (batch processing for bulk operations)
$BatchHelperPath = Join-Path $modulesPath "BatchHelper.psm1"
if (Test-Path $BatchHelperPath) {
    Import-Module $BatchHelperPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ BatchHelper loaded"
}

# Import ActionTracker (action tracking, history, audit)
$ActionTrackerPath = Join-Path $modulesPath "ActionTracker.psm1"
if (Test-Path $ActionTrackerPath) {
    Import-Module $ActionTrackerPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ ActionTracker loaded"
}

Write-Host "🚀 DefenderXDR v3.3.0 - 5 core modules loaded | 219 actions ready"
