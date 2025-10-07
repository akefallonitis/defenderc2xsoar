<#
.SYNOPSIS
    Deploy DefenderC2 Workbooks to Azure Monitor

.DESCRIPTION
    This script deploys the DefenderC2 workbooks (main workbook and file operations workbook) to Azure Monitor.
    It automatically loads the workbook content from JSON files and deploys them using ARM templates.

.PARAMETER ResourceGroupName
    The name of the resource group where the workbook will be deployed

.PARAMETER WorkspaceResourceId
    The resource ID of the Log Analytics workspace. Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}

.PARAMETER FunctionAppName
    The name of your DefenderC2 Function App (e.g., 'defc2', 'mydefender'). This will be set as the default value in the workbook parameter.

.PARAMETER Location
    Azure region for the workbook. Defaults to the resource group location.

.PARAMETER DeployMainWorkbook
    Switch to deploy the main DefenderC2 Command & Control Console workbook

.PARAMETER DeployFileOpsWorkbook
    Switch to deploy the File Operations workbook

.EXAMPLE
    .\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "/subscriptions/.../workspaces/myworkspace" -FunctionAppName "defc2" -DeployMainWorkbook

.EXAMPLE
    .\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "/subscriptions/.../workspaces/myworkspace" -FunctionAppName "mydefender" -DeployMainWorkbook -DeployFileOpsWorkbook
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceResourceId,

    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $false)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [switch]$DeployMainWorkbook,

    [Parameter(Mandatory = $false)]
    [switch]$DeployFileOpsWorkbook
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 DefenderC2 Workbook Deployment" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Validate Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Install from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    $account = az account show --output json 2>&1 | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Not logged in to Azure" -ForegroundColor Red
    Write-Host "   Run: az login" -ForegroundColor Yellow
    exit 1
}

# Get location if not specified
if ([string]::IsNullOrEmpty($Location)) {
    $rg = az group show --name $ResourceGroupName --output json | ConvertFrom-Json
    $Location = $rg.location
    Write-Host "✅ Using resource group location: $Location" -ForegroundColor Green
}

# Validate at least one workbook is selected
if (-not $DeployMainWorkbook -and -not $DeployFileOpsWorkbook) {
    Write-Host "⚠️  No workbook selected for deployment" -ForegroundColor Yellow
    Write-Host "   Use -DeployMainWorkbook and/or -DeployFileOpsWorkbook" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Deploy Main Workbook
if ($DeployMainWorkbook) {
    Write-Host "📊 Deploying Main Workbook: DefenderC2 Command & Control Console" -ForegroundColor Cyan
    
    $workbookFile = Join-Path $scriptPath "..\workbook\DefenderC2-Workbook.json"
    
    if (-not (Test-Path $workbookFile)) {
        Write-Host "❌ Workbook file not found: $workbookFile" -ForegroundColor Red
        exit 1
    }

    Write-Host "   Loading workbook content..." -ForegroundColor Gray
    $workbookContent = Get-Content $workbookFile -Raw | ConvertFrom-Json
    
    # Update the FunctionAppName parameter default value
    Write-Host "   Setting Function App Name parameter to: $FunctionAppName" -ForegroundColor Gray
    $funcAppParam = $workbookContent.items | 
        Where-Object { $_.type -eq "1" } | 
        Select-Object -ExpandProperty content | 
        Where-Object { $_ -ne $null } |
        Select-Object -ExpandProperty parameters |
        Where-Object { $_ -ne $null } |
        ForEach-Object { $_ } |
        Where-Object { $_.name -eq "FunctionAppName" } |
        Select-Object -First 1
    
    if ($funcAppParam) {
        $funcAppParam.value = $FunctionAppName
        Write-Host "   ✅ Function App Name parameter updated" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Could not find FunctionAppName parameter in workbook" -ForegroundColor Yellow
    }

    # Create temporary parameters file
    $tempParamsFile = Join-Path $env:TEMP "defenderc2-workbook-params-$(Get-Date -Format 'yyyyMMddHHmmss').json"
    
    $parameters = @{
        '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        contentVersion = '1.0.0.0'
        parameters = @{
            workbookDisplayName = @{
                value = 'DefenderC2 Command & Control Console'
            }
            workbookSourceId = @{
                value = $WorkspaceResourceId
            }
            workbookContent = @{
                value = $workbookContent
            }
            location = @{
                value = $Location
            }
        }
    }
    
    $parameters | ConvertTo-Json -Depth 100 | Out-File $tempParamsFile -Encoding UTF8
    
    Write-Host "   Deploying workbook..." -ForegroundColor Gray
    
    $deploymentName = "defenderc2-workbook-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $templateFile = Join-Path $scriptPath "workbook-deploy.json"
    
    try {
        az deployment group create `
            --resource-group $ResourceGroupName `
            --name $deploymentName `
            --template-file $templateFile `
            --parameters "@$tempParamsFile" `
            --output json | ConvertFrom-Json | Out-Null
        
        Write-Host "   ✅ Main workbook deployed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Failed to deploy main workbook" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        Remove-Item $tempParamsFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    finally {
        Remove-Item $tempParamsFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
}

# Deploy File Operations Workbook
if ($DeployFileOpsWorkbook) {
    Write-Host "📊 Deploying File Operations Workbook" -ForegroundColor Cyan
    
    $workbookFile = Join-Path $scriptPath "..\workbook\FileOperations.workbook"
    
    if (-not (Test-Path $workbookFile)) {
        Write-Host "❌ Workbook file not found: $workbookFile" -ForegroundColor Red
        exit 1
    }

    Write-Host "   Loading workbook content..." -ForegroundColor Gray
    $workbookContent = Get-Content $workbookFile -Raw | ConvertFrom-Json
    
    # Update the FunctionAppName parameter default value
    Write-Host "   Setting Function App Name parameter to: $FunctionAppName" -ForegroundColor Gray
    $funcAppParam = $workbookContent.items | 
        Where-Object { $_.type -eq "1" } | 
        Select-Object -ExpandProperty content | 
        Where-Object { $_ -ne $null } |
        Select-Object -ExpandProperty parameters |
        Where-Object { $_ -ne $null } |
        ForEach-Object { $_ } |
        Where-Object { $_.name -eq "FunctionAppName" } |
        Select-Object -First 1
    
    if ($funcAppParam) {
        $funcAppParam.value = $FunctionAppName
        Write-Host "   ✅ Function App Name parameter updated" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Could not find FunctionAppName parameter in workbook" -ForegroundColor Yellow
    }

    # Create temporary parameters file
    $tempParamsFile = Join-Path $env:TEMP "defenderc2-fileops-params-$(Get-Date -Format 'yyyyMMddHHmmss').json"
    
    $parameters = @{
        '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        contentVersion = '1.0.0.0'
        parameters = @{
            workbookDisplayName = @{
                value = 'DefenderC2 File Operations'
            }
            workbookSourceId = @{
                value = $WorkspaceResourceId
            }
            workbookContent = @{
                value = $workbookContent
            }
            location = @{
                value = $Location
            }
        }
    }
    
    $parameters | ConvertTo-Json -Depth 100 | Out-File $tempParamsFile -Encoding UTF8
    
    Write-Host "   Deploying workbook..." -ForegroundColor Gray
    
    $deploymentName = "defenderc2-fileops-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $templateFile = Join-Path $scriptPath "workbook-deploy.json"
    
    try {
        az deployment group create `
            --resource-group $ResourceGroupName `
            --name $deploymentName `
            --template-file $templateFile `
            --parameters "@$tempParamsFile" `
            --output json | ConvertFrom-Json | Out-Null
        
        Write-Host "   ✅ File Operations workbook deployed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Failed to deploy File Operations workbook" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        Remove-Item $tempParamsFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    finally {
        Remove-Item $tempParamsFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
}

Write-Host "✅ Workbook deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Go to Azure Portal > Monitor > Workbooks" -ForegroundColor White
Write-Host "   2. Find your deployed workbook(s)" -ForegroundColor White
Write-Host "   3. Open the workbook and verify the Function App Name parameter is set to: $FunctionAppName" -ForegroundColor White
Write-Host "   4. Select your subscription and workspace in the workbook parameters" -ForegroundColor White
Write-Host "   5. The workbook is ready to use!" -ForegroundColor White
Write-Host ""
