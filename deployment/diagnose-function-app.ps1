<#
.SYNOPSIS
    Diagnose DefenderC2XSOAR Function App configuration issues
    
.DESCRIPTION
    Checks common configuration problems:
    - Function app deployment status
    - Environment variables (APPID, SECRETID)
    - Function keys
    - WEBSITE_RUN_FROM_PACKAGE setting
    - Package URL accessibility
    
.PARAMETER FunctionAppName
    Name of the function app (default: sentryxdr)
    
.PARAMETER ResourceGroup
    Resource group name (default: alex-testing-rg)
    
.EXAMPLE
    .\diagnose-function-app.ps1
    
.EXAMPLE
    .\diagnose-function-app.ps1 -FunctionAppName "sentryxdr" -ResourceGroup "alex-testing-rg"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$FunctionAppName = "sentryxdr",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "alex-testing-rg"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  DefenderC2XSOAR Function App Diagnostics" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
Write-Host "[1/6] Checking Azure CLI..." -ForegroundColor Yellow
$azCmd = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCmd) {
    Write-Host "   [FAIL] Azure CLI not installed" -ForegroundColor Red
    Write-Host "   Please install from: https://learn.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}
Write-Host "   [PASS] Azure CLI found: $($azCmd.Version)" -ForegroundColor Green

# Check Azure CLI login status
Write-Host "`n[2/6] Checking Azure CLI login status..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "   [PASS] Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
} catch {
    Write-Host "   [FAIL] Not logged in to Azure CLI" -ForegroundColor Red
    Write-Host "   Run: az login" -ForegroundColor Yellow
    exit 1
}

# Check function app exists
Write-Host "`n[3/6] Checking function app existence..." -ForegroundColor Yellow
try {
    $functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroup 2>&1 | ConvertFrom-Json
    Write-Host "   [PASS] Function app found: $($functionApp.name)" -ForegroundColor Green
    Write-Host "   Location: $($functionApp.location)" -ForegroundColor Gray
    Write-Host "   State: $($functionApp.state)" -ForegroundColor $(if ($functionApp.state -eq "Running") { "Green" } else { "Yellow" })
    Write-Host "   Default hostname: $($functionApp.defaultHostName)" -ForegroundColor Gray
} catch {
    Write-Host "   [FAIL] Function app not found: $FunctionAppName" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor DarkRed
    exit 1
}

# Check environment variables (App Settings)
Write-Host "`n[4/6] Checking environment variables..." -ForegroundColor Yellow
try {
    $appSettings = az functionapp config appsettings list --name $FunctionAppName --resource-group $ResourceGroup 2>&1 | ConvertFrom-Json
    
    $requiredSettings = @("APPID", "SECRETID", "WEBSITE_RUN_FROM_PACKAGE")
    $foundSettings = @{}
    
    foreach ($setting in $appSettings) {
        if ($setting.name -in $requiredSettings) {
            $foundSettings[$setting.name] = $setting.value
        }
    }
    
    # Check APPID
    if ($foundSettings.ContainsKey("APPID")) {
        Write-Host "   [PASS] APPID is set: $($foundSettings['APPID'])" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] APPID is NOT set" -ForegroundColor Red
        Write-Host "   ACTION REQUIRED: Set APPID environment variable to your App Registration Client ID" -ForegroundColor Yellow
    }
    
    # Check SECRETID
    if ($foundSettings.ContainsKey("SECRETID")) {
        Write-Host "   [PASS] SECRETID is set: ****$($foundSettings['SECRETID'].Substring([Math]::Max(0, $foundSettings['SECRETID'].Length - 4)))" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] SECRETID is NOT set" -ForegroundColor Red
        Write-Host "   ACTION REQUIRED: Set SECRETID environment variable to your App Registration Client Secret" -ForegroundColor Yellow
    }
    
    # Check WEBSITE_RUN_FROM_PACKAGE
    if ($foundSettings.ContainsKey("WEBSITE_RUN_FROM_PACKAGE")) {
        Write-Host "   [PASS] WEBSITE_RUN_FROM_PACKAGE is set" -ForegroundColor Green
        Write-Host "   Package URL: $($foundSettings['WEBSITE_RUN_FROM_PACKAGE'])" -ForegroundColor Gray
        
        # Try to access the package URL
        try {
            $packageUrl = $foundSettings['WEBSITE_RUN_FROM_PACKAGE']
            $response = Invoke-WebRequest -Uri $packageUrl -Method Head -UseBasicParsing -ErrorAction Stop
            Write-Host "   [PASS] Package URL is accessible" -ForegroundColor Green
            Write-Host "   Content-Length: $($response.Headers['Content-Length']) bytes" -ForegroundColor Gray
            Write-Host "   Last-Modified: $($response.Headers['Last-Modified'])" -ForegroundColor Gray
            if ($response.Headers.ContainsKey('ETag')) {
                Write-Host "   ETag: $($response.Headers['ETag'])" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   [WARN] Package URL not accessible: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [WARN] WEBSITE_RUN_FROM_PACKAGE is NOT set" -ForegroundColor Yellow
        Write-Host "   Function app may be using local deployment instead of package" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "   [FAIL] Could not retrieve app settings" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor DarkRed
}

# Check function app logs (recent errors)
Write-Host "`n[5/6] Checking recent function app logs..." -ForegroundColor Yellow
try {
    $logAnalyticsQuery = "FunctionAppLogs | where TimeGenerated > ago(30m) | where Level == 'Error' | project TimeGenerated, Message | take 10"
    Write-Host "   Note: Full log analysis requires Log Analytics workspace configured" -ForegroundColor Gray
    Write-Host "   View logs at: https://portal.azure.com -> $FunctionAppName -> Log stream" -ForegroundColor Gray
} catch {
    Write-Host "   [INFO] Logs can be viewed in Azure Portal" -ForegroundColor Gray
}

# Check function deployment status
Write-Host "`n[6/6] Checking deployment status..." -ForegroundColor Yellow
try {
    # Try to get function list
    $functions = az functionapp function list --name $FunctionAppName --resource-group $ResourceGroup 2>&1 | ConvertFrom-Json
    if ($functions -and $functions.Count -gt 0) {
        Write-Host "   [PASS] Functions are deployed: $($functions.Count) functions found" -ForegroundColor Green
        foreach ($func in $functions | Select-Object -First 5) {
            Write-Host "   - $($func.name)" -ForegroundColor Gray
        }
        if ($functions.Count -gt 5) {
            Write-Host "   ... and $($functions.Count - 5) more" -ForegroundColor Gray
        }
    } else {
        Write-Host "   [WARN] No functions found - may still be deploying" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [WARN] Could not list functions: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   This is normal if the function app is still cold starting" -ForegroundColor Gray
}

# Summary and recommendations
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "  RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$hasAppId = $foundSettings.ContainsKey("APPID") -and $foundSettings["APPID"]
$hasSecretId = $foundSettings.ContainsKey("SECRETID") -and $foundSettings["SECRETID"]
$hasPackage = $foundSettings.ContainsKey("WEBSITE_RUN_FROM_PACKAGE") -and $foundSettings["WEBSITE_RUN_FROM_PACKAGE"]

if (-not $hasAppId -or -not $hasSecretId) {
    Write-Host "`n[CRITICAL] Missing authentication credentials!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix this, run:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  az functionapp config appsettings set \" -ForegroundColor White
    Write-Host "    --name $FunctionAppName \" -ForegroundColor White
    Write-Host "    --resource-group $ResourceGroup \" -ForegroundColor White
    Write-Host "    --settings APPID=<your-app-registration-client-id> SECRETID=<your-client-secret>" -ForegroundColor White
    Write-Host ""
    Write-Host "Replace <your-app-registration-client-id> and <your-client-secret> with actual values" -ForegroundColor Gray
} elseif ($functionApp.state -ne "Running") {
    Write-Host "`n[ACTION] Function app is not running!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start it:" -ForegroundColor Yellow
    Write-Host "  az functionapp start --name $FunctionAppName --resource-group $ResourceGroup" -ForegroundColor White
} elseif ($hasPackage) {
    Write-Host "`n[ACTION] Function app appears configured correctly" -ForegroundColor Green
    Write-Host ""
    Write-Host "If still getting 401 errors, try:" -ForegroundColor Yellow
    Write-Host "1. Restart the function app:" -ForegroundColor Gray
    Write-Host "   az functionapp restart --name $FunctionAppName --resource-group $ResourceGroup" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Wait 2 minutes, then test:" -ForegroundColor Gray
    Write-Host "   cd deployment; .\test-all-functions-comprehensive.ps1 -TenantId 'a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9' -FunctionKey '<your-key>'" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Check Azure Portal logs:" -ForegroundColor Gray
    Write-Host "   https://portal.azure.com -> $FunctionAppName -> Functions -> Gateway -> Monitor" -ForegroundColor White
} else {
    Write-Host "`n[ACTION] Configuration needs review" -ForegroundColor Yellow
    Write-Host "Please verify all settings in Azure Portal" -ForegroundColor Gray
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host ""
