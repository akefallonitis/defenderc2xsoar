# ARM Template Validation Script
# This script validates the ARM template and parameters before deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "azuredeploy.json",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-mde-automator-test",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

Write-Host "ARM Template Validation Script" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure PowerShell module is installed
Write-Host "Checking Azure PowerShell module..." -ForegroundColor Yellow
if (Get-Module -ListAvailable -Name Az.Resources) {
    Write-Host "✓ Az.Resources module found" -ForegroundColor Green
} else {
    Write-Host "✗ Az.Resources module not found. Install with: Install-Module -Name Az -AllowClobber" -ForegroundColor Red
    exit 1
}

# Check if template file exists
Write-Host "Checking template file..." -ForegroundColor Yellow
if (Test-Path $TemplateFile) {
    Write-Host "✓ Template file found: $TemplateFile" -ForegroundColor Green
} else {
    Write-Host "✗ Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

# Parse JSON to validate syntax
Write-Host "Validating JSON syntax..." -ForegroundColor Yellow
try {
    $template = Get-Content $TemplateFile -Raw | ConvertFrom-Json
    Write-Host "✓ JSON syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "✗ JSON syntax error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check for required parameters
Write-Host "Checking required parameters..." -ForegroundColor Yellow
$requiredParams = @('functionAppName', 'spnId', 'spnSecret', 'projectTag', 'createdByTag', 'deleteAtTag')
$missingParams = @()
foreach ($param in $requiredParams) {
    if (-not $template.parameters.PSObject.Properties[$param]) {
        $missingParams += $param
    }
}

if ($missingParams.Count -eq 0) {
    Write-Host "✓ All required parameters present: $($requiredParams -join ', ')" -ForegroundColor Green
} else {
    Write-Host "✗ Missing parameters: $($missingParams -join ', ')" -ForegroundColor Red
    exit 1
}

# Check resources have tags
Write-Host "Checking resources for required tags..." -ForegroundColor Yellow
$requiredTags = @('Project', 'CreatedBy', 'DeleteAt')
$resourcesWithoutTags = @()

foreach ($resource in $template.resources) {
    if (-not $resource.tags) {
        $resourcesWithoutTags += $resource.type
    } else {
        $missingTags = @()
        foreach ($tag in $requiredTags) {
            if (-not $resource.tags.PSObject.Properties[$tag]) {
                $missingTags += $tag
            }
        }
        if ($missingTags.Count -gt 0) {
            $resourcesWithoutTags += "$($resource.type) (missing: $($missingTags -join ', '))"
        }
    }
}

if ($resourcesWithoutTags.Count -eq 0) {
    Write-Host "✓ All resources have required tags" -ForegroundColor Green
} else {
    Write-Host "✗ Resources missing tags:" -ForegroundColor Red
    foreach ($resource in $resourcesWithoutTags) {
        Write-Host "  - $resource" -ForegroundColor Red
    }
    exit 1
}

# Check function app environment variables
Write-Host "Checking function app environment variables..." -ForegroundColor Yellow
$functionApp = $template.resources | Where-Object { $_.type -eq 'Microsoft.Web/sites' }
$appSettings = $functionApp.properties.siteConfig.appSettings
$requiredSettings = @('APPID', 'SECRETID', 'FUNCTIONS_WORKER_RUNTIME', 'FUNCTIONS_EXTENSION_VERSION')
$missingSettings = @()

foreach ($setting in $requiredSettings) {
    $found = $appSettings | Where-Object { $_.name -eq $setting }
    if (-not $found) {
        $missingSettings += $setting
    }
}

if ($missingSettings.Count -eq 0) {
    Write-Host "✓ All required environment variables configured" -ForegroundColor Green
} else {
    Write-Host "✗ Missing environment variables: $($missingSettings -join ', ')" -ForegroundColor Red
    exit 1
}

# Test Azure connection
Write-Host "Testing Azure connection..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if ($context) {
        Write-Host "✓ Connected to Azure as $($context.Account.Id)" -ForegroundColor Green
        Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Not connected to Azure. Run Connect-AzAccount first" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error checking Azure connection: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test template deployment (validation only)
Write-Host "Validating template deployment..." -ForegroundColor Yellow
$testParams = @{
    functionAppName = 'test-func-app'
    spnId = '00000000-0000-0000-0000-000000000000'
    spnSecret = (ConvertTo-SecureString 'test-secret-value' -AsPlainText -Force)
    projectTag = 'TestProject'
    createdByTag = 'test@example.com'
    deleteAtTag = 'Never'
}

try {
    $validation = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroup `
        -TemplateFile $TemplateFile `
        -Location $Location `
        @testParams `
        -ErrorAction Stop
    
    if ($validation) {
        Write-Host "✗ Template validation failed:" -ForegroundColor Red
        $validation | Format-List
        exit 1
    } else {
        Write-Host "✓ Template validation successful" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Error during validation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "✓ All validation checks passed!" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Create or update your app registration with a client secret" -ForegroundColor White
Write-Host "2. Deploy using the Azure Portal, Azure CLI, or PowerShell" -ForegroundColor White
Write-Host "3. Deploy function code to the function app" -ForegroundColor White
Write-Host "4. Configure the workbook with your function app URL" -ForegroundColor White
Write-Host ""
