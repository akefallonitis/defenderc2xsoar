# Quick deployment script for Azure Functions
# This script packages and deploys the function app to Azure

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$PackagePath = "./deploy-package.zip"
)

Write-Host "🚀 Starting deployment to Azure Functions..." -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "   Function App: $FunctionAppName" -ForegroundColor Gray
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    Write-Host "✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "   Download: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to Azure
Write-Host "🔐 Checking Azure login status..." -ForegroundColor Cyan
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name) ($($account.id))" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Azure login failed" -ForegroundColor Red
        exit 1
    }
}

# Create deployment package if it doesn't exist
if (-not (Test-Path $PackagePath)) {
    Write-Host "📦 Package not found. Creating deployment package..." -ForegroundColor Yellow
    & "$PSScriptRoot/create-deployment-package.ps1" -OutputPath $PackagePath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create deployment package" -ForegroundColor Red
        exit 1
    }
}

# Verify function app exists
Write-Host "`n🔍 Verifying function app exists..." -ForegroundColor Cyan
try {
    $funcApp = az functionapp show --resource-group $ResourceGroupName --name $FunctionAppName 2>$null | ConvertFrom-Json
    Write-Host "✅ Function app found: $($funcApp.name)" -ForegroundColor Green
    Write-Host "   Location: $($funcApp.location)" -ForegroundColor Gray
    Write-Host "   State: $($funcApp.state)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Function app not found: $FunctionAppName in resource group $ResourceGroupName" -ForegroundColor Red
    exit 1
}

# Deploy to Azure
Write-Host "`n📤 Deploying function app..." -ForegroundColor Cyan
Write-Host "   This may take a few minutes..." -ForegroundColor Gray

try {
    az functionapp deployment source config-zip `
        --resource-group $ResourceGroupName `
        --name $FunctionAppName `
        --src $PackagePath `
        --build-remote false `
        --timeout 600
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deployment command failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    Write-Host "`n💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   1. Verify the function app is running: az functionapp show -g $ResourceGroupName -n $FunctionAppName" -ForegroundColor Gray
    Write-Host "   2. Check deployment logs in Azure Portal: Function App > Deployment Center > Logs" -ForegroundColor Gray
    Write-Host "   3. Ensure FUNCTIONS_WORKER_RUNTIME is set to 'powershell'" -ForegroundColor Gray
    exit 1
}

# Wait for deployment to complete
Write-Host "`n⏳ Waiting for deployment to stabilize..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Verify functions are deployed
Write-Host "`n🔍 Verifying deployed functions..." -ForegroundColor Cyan
try {
    $functions = az functionapp function list --resource-group $ResourceGroupName --name $FunctionAppName 2>$null | ConvertFrom-Json
    
    if ($functions -and $functions.Count -gt 0) {
        Write-Host "✅ Found $($functions.Count) deployed functions:" -ForegroundColor Green
        foreach ($func in $functions) {
            Write-Host "   ✓ $($func.name)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "⚠️  No functions found yet. They may still be initializing." -ForegroundColor Yellow
        Write-Host "   Check the Azure Portal in a few minutes." -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️  Could not list functions (they may still be initializing)" -ForegroundColor Yellow
}

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Verify functions in Azure Portal: https://portal.azure.com" -ForegroundColor Gray
Write-Host "   2. Test functions using the function URLs" -ForegroundColor Gray
Write-Host "   3. Check logs: az webapp log tail --resource-group $ResourceGroupName --name $FunctionAppName" -ForegroundColor Gray
Write-Host ""
