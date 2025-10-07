<#
.SYNOPSIS
    Complete DefenderC2 Deployment - Function App and Workbooks

.DESCRIPTION
    This script performs a complete deployment of DefenderC2:
    1. Deploys the Function App infrastructure (using deploy-complete.ps1)
    2. Deploys the workbooks to Azure Monitor (using deploy-workbook.ps1)
    
    This is the recommended one-command deployment method.

.PARAMETER ResourceGroupName
    The name of the resource group where resources will be deployed

.PARAMETER FunctionAppName
    Globally unique name for your function app (3-60 characters, lowercase letters, numbers, and hyphens only)

.PARAMETER AppId
    Application (client) ID from your multi-tenant app registration

.PARAMETER ClientSecret
    Client secret from your multi-tenant app registration

.PARAMETER WorkspaceResourceId
    The resource ID of the Log Analytics workspace for workbook deployment
    Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}

.PARAMETER Location
    Azure region for deployment (defaults to resource group location)

.PARAMETER ProjectTag
    Value for the 'Project' tag (required by Azure Policy)

.PARAMETER CreatedByTag
    Value for the 'CreatedBy' tag (required by Azure Policy)

.PARAMETER DeleteAtTag
    Value for the 'DeleteAt' tag (required by Azure Policy). Use 'Never' if no expiration.

.PARAMETER SkipFunctionApp
    Skip Function App deployment (only deploy workbooks)

.PARAMETER SkipWorkbooks
    Skip workbook deployment (only deploy Function App)

.EXAMPLE
    .\deploy-all.ps1 `
        -ResourceGroupName "rg-defenderc2" `
        -FunctionAppName "defc2" `
        -AppId "12345678-1234-1234-1234-123456789012" `
        -ClientSecret "your-secret" `
        -WorkspaceResourceId "/subscriptions/.../workspaces/myworkspace" `
        -ProjectTag "DefenderC2" `
        -CreatedByTag "john.doe@example.com" `
        -DeleteAtTag "Never"

.EXAMPLE
    # Deploy only workbooks (Function App already exists)
    .\deploy-all.ps1 `
        -ResourceGroupName "rg-defenderc2" `
        -FunctionAppName "defc2" `
        -WorkspaceResourceId "/subscriptions/.../workspaces/myworkspace" `
        -SkipFunctionApp
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $false)]
    [string]$AppId,

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceResourceId,

    [Parameter(Mandatory = $false)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$ProjectTag = "DefenderC2",

    [Parameter(Mandatory = $false)]
    [string]$CreatedByTag = "DefenderC2-Deployment",

    [Parameter(Mandatory = $false)]
    [string]$DeleteAtTag = "Never",

    [Parameter(Mandatory = $false)]
    [switch]$SkipFunctionApp,

    [Parameter(Mandatory = $false)]
    [switch]$SkipWorkbooks
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 DefenderC2 Complete Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Validate parameters
if (-not $SkipFunctionApp -and ([string]::IsNullOrEmpty($AppId) -or [string]::IsNullOrEmpty($ClientSecret))) {
    Write-Host "❌ AppId and ClientSecret are required when deploying Function App" -ForegroundColor Red
    Write-Host "   Use -SkipFunctionApp if you only want to deploy workbooks" -ForegroundColor Yellow
    exit 1
}

# Step 1: Deploy Function App
if (-not $SkipFunctionApp) {
    Write-Host "📦 Step 1/2: Deploying Function App Infrastructure" -ForegroundColor Cyan
    Write-Host ""
    
    $deployCompletePath = Join-Path $scriptPath "deploy-complete.ps1"
    
    if (-not (Test-Path $deployCompletePath)) {
        Write-Host "❌ deploy-complete.ps1 not found at: $deployCompletePath" -ForegroundColor Red
        exit 1
    }
    
    try {
        $params = @{
            ResourceGroupName = $ResourceGroupName
            FunctionAppName   = $FunctionAppName
            AppId             = $AppId
            ClientSecret      = $ClientSecret
            ProjectTag        = $ProjectTag
            CreatedByTag      = $CreatedByTag
            DeleteAtTag       = $DeleteAtTag
        }
        
        if (-not [string]::IsNullOrEmpty($Location)) {
            $params.Add("Location", $Location)
        }
        
        & $deployCompletePath @params
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Function App deployment failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✅ Function App deployed successfully" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "❌ Function App deployment failed: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "⏭️  Skipping Function App deployment (as requested)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 2: Deploy Workbooks
if (-not $SkipWorkbooks) {
    Write-Host "📊 Step 2/2: Deploying Workbooks to Azure Monitor" -ForegroundColor Cyan
    Write-Host ""
    
    $deployWorkbookPath = Join-Path $scriptPath "deploy-workbook.ps1"
    
    if (-not (Test-Path $deployWorkbookPath)) {
        Write-Host "❌ deploy-workbook.ps1 not found at: $deployWorkbookPath" -ForegroundColor Red
        exit 1
    }
    
    try {
        $params = @{
            ResourceGroupName   = $ResourceGroupName
            WorkspaceResourceId = $WorkspaceResourceId
            FunctionAppName     = $FunctionAppName
            DeployMainWorkbook  = $true
            DeployFileOpsWorkbook = $true
        }
        
        if (-not [string]::IsNullOrEmpty($Location)) {
            $params.Add("Location", $Location)
        }
        
        & $deployWorkbookPath @params
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Workbook deployment failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✅ Workbooks deployed successfully" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "❌ Workbook deployment failed: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "⏭️  Skipping workbook deployment (as requested)" -ForegroundColor Yellow
    Write-Host ""
}

# Summary
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "   Function App: $FunctionAppName" -ForegroundColor White
Write-Host "   Function App URL: https://$FunctionAppName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "📊 Workbooks Deployed:" -ForegroundColor Cyan
Write-Host "   • DefenderC2 Command & Control Console" -ForegroundColor White
Write-Host "   • DefenderC2 File Operations" -ForegroundColor White
Write-Host ""
Write-Host "✅ Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Go to Azure Portal > Monitor > Workbooks" -ForegroundColor White
Write-Host "   2. Open 'DefenderC2 Command & Control Console'" -ForegroundColor White
Write-Host "   3. Select your subscription and workspace" -ForegroundColor White
Write-Host "   4. Verify Function App Name parameter is set to: $FunctionAppName" -ForegroundColor White
Write-Host "   5. Start using the workbook!" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   • Workbook Guide: deployment/WORKBOOK_DEPLOYMENT.md" -ForegroundColor White
Write-Host "   • Main Deployment Guide: DEPLOYMENT.md" -ForegroundColor White
Write-Host "   • Quick Start: QUICKSTART.md" -ForegroundColor White
Write-Host ""
