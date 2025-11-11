<#
.SYNOPSIS
    Quick redeploy of DefenderC2XSOAR function app via Azure portal sync
.DESCRIPTION
    Triggers Azure to pull latest code from GitHub repository.
    Much faster than full deployment - just syncs function code.
.PARAMETER FunctionAppName
    Name of the Azure Function App
.PARAMETER ResourceGroup
    Azure Resource Group name
.EXAMPLE
    .\quick-redeploy.ps1 -FunctionAppName "sentryxdr" -ResourceGroup "YourResourceGroup"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "DefenderC2XSOAR - Quick Redeploy via GitHub Sync" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Function App:     $FunctionAppName" -ForegroundColor Gray
Write-Host "Resource Group:   $ResourceGroup" -ForegroundColor Gray
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✅ Azure CLI found (v$($azVersion.'azure-cli'))" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install from: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    exit 1
}

# Check login status
Write-Host "`n🔐 Checking Azure login status..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged in to Azure. Running az login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray

# Sync function app with GitHub
Write-Host "`n🔄 Syncing function app with GitHub repository..." -ForegroundColor Cyan
try {
    az functionapp deployment source sync `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --output table
    
    Write-Host "✅ Sync completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Sync failed: $_" -ForegroundColor Red
    Write-Host "`n💡 Manual alternative:" -ForegroundColor Yellow
    Write-Host "   1. Go to Azure Portal" -ForegroundColor Gray
    Write-Host "   2. Navigate to your Function App: $FunctionAppName" -ForegroundColor Gray
    Write-Host "   3. Go to Deployment Center" -ForegroundColor Gray
    Write-Host "   4. Click 'Sync' button" -ForegroundColor Gray
    exit 1
}

# Restart function app
Write-Host "`n🔄 Restarting function app..." -ForegroundColor Cyan
try {
    az functionapp restart `
        --name $FunctionAppName `
        --resource-group $ResourceGroup `
        --output none
    
    Write-Host "✅ Function app restarted!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Restart failed (not critical): $_" -ForegroundColor Yellow
}

# Wait for warmup
Write-Host "`n⏳ Waiting for function app to warm up (30 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Get function app URL
Write-Host "`n📊 Function app status:" -ForegroundColor Cyan
$app = az functionapp show --name $FunctionAppName --resource-group $ResourceGroup | ConvertFrom-Json
Write-Host "   URL: https://$($app.defaultHostName)" -ForegroundColor Gray
Write-Host "   State: $($app.state)" -ForegroundColor Gray

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "✅ Redeploy complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Test Gateway: https://$($app.defaultHostName)/api/Gateway?code=<your-key>" -ForegroundColor Gray
Write-Host "  2. Run test suite: .\test-all-services-complete.ps1" -ForegroundColor Gray
Write-Host "=====================================================================" -ForegroundColor Cyan
