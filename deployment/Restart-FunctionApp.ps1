# Force Azure Function App to Pull Updated Package from GitHub

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestartOnly
)

Write-Host "=== DefenderC2XSOAR Function App Update ===" -ForegroundColor Cyan
Write-Host "Function App: $FunctionAppName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host ""

# Check if logged in to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not logged in to Azure. Logging in..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    Write-Host "✅ Connected to Azure" -ForegroundColor Green
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
} catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

if (-not $RestartOnly) {
    # Method 1: Sync the function app (forces re-download of package)
    Write-Host "`n--- Step 1: Syncing Function App ---" -ForegroundColor Cyan
    try {
        Invoke-AzResourceAction `
            -ResourceGroupName $ResourceGroup `
            -ResourceType "Microsoft.Web/sites" `
            -ResourceName $FunctionAppName `
            -Action "syncfunctiontriggers" `
            -ApiVersion "2021-03-01" `
            -Force
        
        Write-Host "✅ Function triggers synced" -ForegroundColor Green
    } catch {
        Write-Warning "Sync failed: $($_.Exception.Message)"
    }
}

# Method 2: Restart the function app
Write-Host "`n--- Step 2: Restarting Function App ---" -ForegroundColor Cyan
Write-Host "This will restart the function app and force it to pull the latest package..." -ForegroundColor Yellow

try {
    Restart-AzFunctionApp -ResourceGroupName $ResourceGroup -Name $FunctionAppName -Force
    Write-Host "✅ Function App restart initiated" -ForegroundColor Green
} catch {
    Write-Error "Failed to restart: $($_.Exception.Message)"
    exit 1
}

# Wait for restart to complete
Write-Host "`nWaiting for function app to come back online..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check function app status
Write-Host "`n--- Step 3: Verifying Function App Status ---" -ForegroundColor Cyan
try {
    $app = Get-AzFunctionApp -ResourceGroupName $ResourceGroup -Name $FunctionAppName
    $state = $app.State
    
    if ($state -eq "Running") {
        Write-Host "✅ Function App is running" -ForegroundColor Green
    } else {
        Write-Warning "Function App state: $state"
    }
    
    # Get the function app URL
    $url = "https://$($app.DefaultHostName)"
    Write-Host "   URL: $url" -ForegroundColor Gray
    
} catch {
    Write-Error "Failed to verify status: $($_.Exception.Message)"
}

# Try to list functions
Write-Host "`n--- Step 4: Checking Deployed Functions ---" -ForegroundColor Cyan
try {
    $functions = Get-AzFunctionAppFunction -ResourceGroupName $ResourceGroup -FunctionAppName $FunctionAppName
    
    if ($functions) {
        Write-Host "✅ Found $($functions.Count) functions:" -ForegroundColor Green
        foreach ($func in $functions) {
            Write-Host "   - $($func.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Warning "No functions found. The package may not have deployed correctly."
    }
} catch {
    Write-Warning "Could not list functions: $($_.Exception.Message)"
}

Write-Host "`n=== Update Complete ===" -ForegroundColor Cyan
Write-Host "The function app should now be running the latest code from GitHub." -ForegroundColor Green
Write-Host ""
Write-Host "To test the functions, use:" -ForegroundColor Yellow
Write-Host ".\test-functions.ps1 -FunctionAppUrl '$url' -FunctionKey '<your-key>' -TenantId '<tenant-id>'" -ForegroundColor Gray
