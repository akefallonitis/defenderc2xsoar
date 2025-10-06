# Complete deployment script
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectTag = "DefenderC2",
    
    [Parameter(Mandatory=$false)]
    [string]$CreatedByTag = $env:USERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$DeleteAtTag = "Never"
)

Write-Host "🚀 Starting complete one-click deployment..." -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to Azure
Write-Host "🔐 Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (!$account) {
    Write-Host "❌ Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Azure login failed" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# 1. Create deployment package
Write-Host "📦 Step 1/4: Creating deployment package..." -ForegroundColor Cyan
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$createPackageScript = Join-Path $scriptPath "create-package.ps1"

if (Test-Path $createPackageScript) {
    & $createPackageScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create deployment package" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  Package creation script not found, skipping..." -ForegroundColor Yellow
}
Write-Host ""

# 2. Check if resource group exists, create if not
Write-Host "🗂️  Step 2/4: Checking resource group..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (!$rgExists) {
    Write-Host "📝 Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create resource group" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Resource group created" -ForegroundColor Green
} else {
    Write-Host "✅ Resource group exists" -ForegroundColor Green
}
Write-Host ""

# 3. Deploy ARM template
Write-Host "🔧 Step 3/4: Deploying infrastructure via ARM template..." -ForegroundColor Cyan
$templateFile = Join-Path $scriptPath "azuredeploy.json"

if (!(Test-Path $templateFile)) {
    Write-Host "❌ ARM template not found: $templateFile" -ForegroundColor Red
    exit 1
}

Write-Host "   Function App: $FunctionAppName" -ForegroundColor Gray
Write-Host "   Location: $Location" -ForegroundColor Gray
Write-Host "   Project Tag: $ProjectTag" -ForegroundColor Gray

$deploymentName = "defenderc2-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

az deployment group create `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --template-file $templateFile `
    --parameters `
        functionAppName=$FunctionAppName `
        spnId=$AppId `
        spnSecret=$ClientSecret `
        projectTag=$ProjectTag `
        createdByTag=$CreatedByTag `
        deleteAtTag=$DeleteAtTag `
        location=$Location `
    --verbose

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ARM template deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green
Write-Host ""

# 4. Verify deployment
Write-Host "✅ Step 4/4: Verifying deployment..." -ForegroundColor Cyan

# Get function app info
$functionAppInfo = az functionapp show `
    --resource-group $ResourceGroupName `
    --name $FunctionAppName `
    --query "{defaultHostName:defaultHostName,state:state}" `
    -o json | ConvertFrom-Json

if ($functionAppInfo) {
    Write-Host "✅ Function App Status: $($functionAppInfo.state)" -ForegroundColor Green
    Write-Host "✅ Function App URL: https://$($functionAppInfo.defaultHostName)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not retrieve function app info" -ForegroundColor Yellow
}

# List deployed functions
Write-Host ""
Write-Host "🔍 Deployed functions:" -ForegroundColor Cyan
$functions = az functionapp function list `
    --resource-group $ResourceGroupName `
    --name $FunctionAppName `
    --query "[].name" -o tsv 2>$null

if ($functions) {
    $functions | ForEach-Object {
        Write-Host "  ✓ $_" -ForegroundColor Green
    }
} else {
    Write-Host "  ⏳ Functions are being deployed from package..." -ForegroundColor Yellow
    Write-Host "  ℹ️  Wait a few minutes, then check the Azure Portal" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎉 Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 2-3 minutes for functions to be fully deployed" -ForegroundColor White
Write-Host "  2. Open Azure Portal and navigate to your function app" -ForegroundColor White
Write-Host "  3. Check that all 11 functions are visible (5 MDE + 5 File Ops + 1 Orchestrator)" -ForegroundColor White
Write-Host "  4. Configure the workbooks with your function app URL" -ForegroundColor White
Write-Host "  5. Test the functions using the Defender C2 and File Operations workbooks" -ForegroundColor White
Write-Host ""
Write-Host "Function App URL: https://$($functionAppInfo.defaultHostName)" -ForegroundColor Cyan
Write-Host "Workbooks: Deploy 'Defender C2 Workbook' and 'File Operations' in Azure Monitor" -ForegroundColor Cyan
