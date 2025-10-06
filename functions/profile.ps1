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

# Import MDEAutomator module
$MDEAutomatorPath = Join-Path $PSScriptRoot "MDEAutomator"
if (Test-Path $MDEAutomatorPath) {
    Import-Module (Join-Path $MDEAutomatorPath "MDEAutomator.psd1") -Force -ErrorAction SilentlyContinue
    Write-Host "MDEAutomator module loaded successfully"
}

# Initialize storage context for file library
if ($env:AzureWebJobsStorage) {
    Write-Host "📦 Initializing storage context for file library..."
    try {
        $global:StorageContext = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
        
        # Ensure library container exists
        $libraryContainer = Get-AzStorageContainer -Name "library" -Context $global:StorageContext -ErrorAction SilentlyContinue
        if (-not $libraryContainer) {
            Write-Host "📂 Creating library container..."
            New-AzStorageContainer -Name "library" -Context $global:StorageContext -Permission Off | Out-Null
            Write-Host "✅ Library container created"
        } else {
            Write-Host "✅ Library container ready"
        }
    } catch {
        Write-Warning "Failed to initialize storage context: $($_.Exception.Message)"
    }
}
