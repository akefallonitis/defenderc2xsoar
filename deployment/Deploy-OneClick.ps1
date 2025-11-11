<#
.SYNOPSIS
    One-Click Deployment for DefenderC2XSOAR
    
.DESCRIPTION
    Complete automated deployment of DefenderC2XSOAR including:
    - Resource Group creation
    - Azure Function App
    - Storage Account
    - Application Insights
    - App Registration (optional - can use existing)
    - Automatic package deployment from GitHub
    
.PARAMETER ResourceGroupName
    Name of the resource group to create/use
    
.PARAMETER Location
    Azure region for deployment (default: eastus)
    
.PARAMETER FunctionAppName
    Name for the Function App (must be globally unique)
    
.PARAMETER AppRegistrationName
    Name for the App Registration (optional - provide existing AppId instead)
    
.PARAMETER ExistingAppId
    Use existing App Registration instead of creating new one
    
.PARAMETER ExistingAppSecret
    Client secret for existing App Registration
    
.PARAMETER SkipAppRegistration
    Skip app registration creation (you'll configure manually later)
    
.EXAMPLE
    .\Deploy-DefenderC2.ps1 -ResourceGroupName "defenderc2-rg" -FunctionAppName "mydefenderc2" -Location "eastus"
    
.EXAMPLE
    .\Deploy-DefenderC2.ps1 -ResourceGroupName "defenderc2-rg" -FunctionAppName "mydefenderc2" -ExistingAppId "your-app-id" -ExistingAppSecret "your-secret"
    
.NOTES
    Version: 1.0.0
    Requires: Az PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $false)]
    [string]$AppRegistrationName,
    
    [Parameter(Mandatory = $false)]
    [string]$ExistingAppId,
    
    [Parameter(Mandatory = $false)]
    [string]$ExistingAppSecret,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAppRegistration
)

$ErrorActionPreference = "Stop"

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  DefenderC2XSOAR - One-Click Deployment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Check Azure PowerShell module
if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Error "Azure PowerShell module not found. Install with: Install-Module Az -Force"
    exit 1
}

# Connect to Azure
Write-Host "Step 1: Connecting to Azure..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount | Out-Null
    }
    Write-Host "✅ Connected to Azure" -ForegroundColor Green
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
    Write-Host "   Tenant: $($context.Tenant.Id)" -ForegroundColor Gray
} catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# APP REGISTRATION
# ============================================================================

Write-Host ""
Write-Host "Step 2: Configuring App Registration..." -ForegroundColor Yellow

if ($ExistingAppId -and $ExistingAppSecret) {
    Write-Host "✅ Using existing App Registration: $ExistingAppId" -ForegroundColor Green
    $appId = $ExistingAppId
    $appSecret = $ExistingAppSecret
    
} elseif ($SkipAppRegistration) {
    Write-Host "⚠️  Skipping App Registration - you'll need to configure manually" -ForegroundColor Yellow
    $appId = "CONFIGURE_MANUALLY"
    $appSecret = "CONFIGURE_MANUALLY"
    
} else {
    if (-not $AppRegistrationName) {
        $AppRegistrationName = "DefenderC2XSOAR-$FunctionAppName"
    }
    
    Write-Host "   Creating new App Registration: $AppRegistrationName" -ForegroundColor White
    Write-Host ""
    Write-Host "   ⚠️  MANUAL STEP REQUIRED:" -ForegroundColor Yellow
    Write-Host "   Due to permissions, please create the app registration manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. Go to: https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps" -ForegroundColor Cyan
    Write-Host "   2. Click 'New registration'" -ForegroundColor Cyan
    Write-Host "   3. Name: $AppRegistrationName" -ForegroundColor Cyan
    Write-Host "   4. Supported account types: 'Accounts in any organizational directory (Multi-tenant)'" -ForegroundColor Cyan
    Write-Host "   5. Click 'Register'" -ForegroundColor Cyan
    Write-Host "   6. Go to 'Certificates & secrets' → 'New client secret'" -ForegroundColor Cyan
    Write-Host "   7. Copy the Application (client) ID and Client Secret" -ForegroundColor Cyan
    Write-Host ""
    
    $appId = Read-Host "   Enter Application (Client) ID"
    $appSecret = Read-Host "   Enter Client Secret" -AsSecureString
    $appSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($appSecret))
    
    Write-Host "✅ App Registration configured" -ForegroundColor Green
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

Write-Host ""
Write-Host "Step 3: Creating Resource Group..." -ForegroundColor Yellow

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($rg) {
    Write-Host "✅ Resource Group already exists: $ResourceGroupName" -ForegroundColor Green
} else {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
    Write-Host "✅ Created Resource Group: $ResourceGroupName in $Location" -ForegroundColor Green
}

# ============================================================================
# ARM TEMPLATE DEPLOYMENT
# ============================================================================

Write-Host ""
Write-Host "Step 4: Deploying Azure Resources via ARM Template..." -ForegroundColor Yellow
Write-Host "   This will take 3-5 minutes..." -ForegroundColor Gray

$templateFile = Join-Path $PSScriptRoot "azuredeploy.json"
if (-not (Test-Path $templateFile)) {
    Write-Error "ARM template not found at: $templateFile"
    exit 1
}

$deploymentName = "DefenderC2-Deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $templateFile `
        -functionAppName $FunctionAppName `
        -spnId $appId `
        -spnSecret (ConvertTo-SecureString -String $appSecret -AsPlainText -Force) `
        -Verbose
    
    Write-Host "✅ ARM template deployment completed" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Deployed Resources:" -ForegroundColor White
    Write-Host "   • Function App: $FunctionAppName" -ForegroundColor Gray
    Write-Host "   • Storage Account: $(($deployment.Outputs.storageAccountName.Value))" -ForegroundColor Gray
    Write-Host "   • App Insights: $(($deployment.Outputs.appInsightsName.Value))" -ForegroundColor Gray
    
} catch {
    Write-Error "ARM template deployment failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Deployment logs:" -ForegroundColor Yellow
    Get-AzResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $deploymentName | 
        Format-Table -Property ProvisioningState, StatusMessage
    exit 1
}

# ============================================================================
# RESTART FUNCTION APP
# ============================================================================

Write-Host ""
Write-Host "Step 5: Loading Function Package..." -ForegroundColor Yellow
Write-Host "   Restarting Function App to load code from GitHub..." -ForegroundColor Gray

Start-Sleep -Seconds 10  # Wait for deployment to complete

try {
    Restart-AzFunctionApp -Name $FunctionAppName -ResourceGroupName $ResourceGroupName -Force
    Write-Host "✅ Function App restarted" -ForegroundColor Green
    Write-Host "   Waiting for app to start (30 seconds)..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
} catch {
    Write-Warning "Failed to restart Function App: $($_.Exception.Message)"
    Write-Host "   You may need to restart manually in Azure Portal" -ForegroundColor Yellow
}

# ============================================================================
# GET FUNCTION KEYS
# ============================================================================

Write-Host ""
Write-Host "Step 6: Retrieving Function Keys..." -ForegroundColor Yellow

try {
    # Get the master key
    $keys = Invoke-AzResourceAction `
        -ResourceGroupName $ResourceGroupName `
        -ResourceType Microsoft.Web/sites/functions `
        -ResourceName "$FunctionAppName/XDROrchestrator" `
        -Action listkeys `
        -ApiVersion 2022-03-01 `
        -Force
    
    $functionKey = $keys.default
    Write-Host "✅ Function key retrieved" -ForegroundColor Green
    
} catch {
    Write-Warning "Could not retrieve function key automatically"
    Write-Host "   Retrieve it manually from Azure Portal → Function App → Functions → XDROrchestrator → Function Keys" -ForegroundColor Yellow
    $functionKey = "RETRIEVE_FROM_PORTAL"
}

# ============================================================================
# TEST DEPLOYMENT
# ============================================================================

Write-Host ""
Write-Host "Step 7: Testing Deployment..." -ForegroundColor Yellow

if ($functionKey -ne "RETRIEVE_FROM_PORTAL") {
    try {
        $headers = @{"x-functions-key" = $functionKey}
        $tenantId = (Get-AzContext).Tenant.Id
        $testUrl = "https://$FunctionAppName.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=$tenantId"
        
        Write-Host "   Testing endpoint..." -ForegroundColor Gray
        $result = Invoke-RestMethod -Uri $testUrl -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        
        if ($result.success) {
            Write-Host "✅ Function App is working!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Function returned: $($result.error.message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Function test failed: $($_.Exception.Message)"
        Write-Host "   This is normal if permissions haven't been granted yet" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  Skipping test - function key not available" -ForegroundColor Yellow
}

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalMinutes

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment Summary:" -ForegroundColor White
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "  Location: $Location" -ForegroundColor Cyan
Write-Host "  Function App: $FunctionAppName" -ForegroundColor Cyan
Write-Host "  Function URL: https://$FunctionAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  App ID: $appId" -ForegroundColor Cyan
Write-Host "  Tenant ID: $((Get-AzContext).Tenant.Id)" -ForegroundColor Cyan
if ($functionKey -ne "RETRIEVE_FROM_PORTAL") {
    Write-Host "  Function Key: $functionKey" -ForegroundColor Cyan
}
Write-Host "  Deployment Time: $([Math]::Round($duration, 2)) minutes" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# NEXT STEPS
# ============================================================================

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Apply API Permissions:" -ForegroundColor White
Write-Host "   cd deployment" -ForegroundColor Cyan
Write-Host "   .\Apply-DefenderC2Permissions.ps1 -AppId '$appId' -TenantId '$((Get-AzContext).Tenant.Id)'" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Test the deployment:" -ForegroundColor White
if ($functionKey -ne "RETRIEVE_FROM_PORTAL") {
    Write-Host '   $headers = @{"x-functions-key" = "' + $functionKey + '"}' -ForegroundColor Cyan
} else {
    Write-Host '   $headers = @{"x-functions-key" = "YOUR_FUNCTION_KEY"}' -ForegroundColor Cyan
}
Write-Host '   Invoke-RestMethod -Uri "https://' + $FunctionAppName + '.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=' + (Get-AzContext).Tenant.Id + '" -Headers $headers' -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Deploy Workbook (optional):" -ForegroundColor White
Write-Host "   cd deployment" -ForegroundColor Cyan
Write-Host "   .\deploy-workbook.ps1 -ResourceGroupName '$ResourceGroupName' -WorkspaceName 'YOUR_SENTINEL_WORKSPACE'" -ForegroundColor Cyan
Write-Host ""

# Save deployment info
$deploymentInfo = @{
    ResourceGroup = $ResourceGroupName
    Location = $Location
    FunctionApp = $FunctionAppName
    FunctionUrl = "https://$FunctionAppName.azurewebsites.net"
    AppId = $appId
    TenantId = (Get-AzContext).Tenant.Id
    FunctionKey = $functionKey
    DeploymentTime = (Get-Date).ToString("o")
    Duration = "$([Math]::Round($duration, 2)) minutes"
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "deployment-info-$(Get-Date -Format 'yyyyMMddHHmmss').json"
Write-Host "Deployment info saved to: deployment-info-$(Get-Date -Format 'yyyyMMddHHmmss').json" -ForegroundColor Gray
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
