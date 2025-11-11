# Azure Functions Auto-Sync Behavior with WEBSITE_RUN_FROM_PACKAGE

## How It Works

When you use `WEBSITE_RUN_FROM_PACKAGE`, Azure Functions operates in **read-only mode** from a package file.

### Key Points:

1. **Package Caching**: The Function App downloads and caches the package on first load
2. **No Auto-Sync**: Function Apps do NOT automatically check for package updates
3. **Manual Restart Required**: You must restart the Function App to pull a new package
4. **Alternative**: Change the URL to force a refresh (add version query parameter)

---

## Current Configuration

**Package URL:**
```
https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
```

**Configured in:** `azuredeploy.json` → `WEBSITE_RUN_FROM_PACKAGE` variable

---

## Deployment Options

### Option 1: Restart Function App (Recommended)

After pushing changes to GitHub:

```powershell
# Restart the Function App to pull new package
Restart-AzFunctionApp -Name "sentryxdr" -ResourceGroupName "alex-testing-rg"
```

**Or via Azure Portal:**
1. Go to Function App
2. Click "Restart"
3. Wait ~30 seconds
4. Test functions

### Option 2: Versioned Package URLs

Use versioned URLs in ARM template to force immediate updates:

```json
"packageUrl": "https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip?v=1.0.1"
```

Change version number when you update the package.

### Option 3: Azure DevOps / GitHub Actions

Set up CI/CD pipeline to:
1. Build package on commit
2. Upload to Azure Storage
3. Restart Function App
4. Run tests

---

## Why Function App Shows 404

**Root Cause:** Function App has old cached package that doesn't include new functions.

**Fix:**
1. Verify package exists on GitHub ✅ (already confirmed working)
2. **Restart Function App** ← This is the missing step!
3. Test endpoints

---

## Comparison with Azure Sentinel Connectors

Azure Sentinel data connectors (like Qualys VM) use the **same pattern**:

- **Package Location**: GitHub raw URL or Azure Storage
- **Configuration**: `WEBSITE_RUN_FROM_PACKAGE` app setting
- **Deployment**: ARM template with package URL
- **Updates**: Require manual restart or app setting change

**Example from Sentinel:**
```json
{
  "name": "WEBSITE_RUN_FROM_PACKAGE",
  "value": "https://aka.ms/sentinel-QualysKB-functionapp"
}
```

---

## Best Practices

### ✅ DO:
- Use GitHub releases for versioned packages
- Document deployment steps
- Test after every restart
- Use Application Insights for monitoring

### ❌ DON'T:
- Expect automatic updates
- Modify files in the Function App directly (read-only)
- Skip restart after package changes

---

## Deployment Checklist

After updating code and pushing to GitHub:

- [ ] Package rebuilt and pushed to GitHub
- [ ] Verify package URL is accessible
- [ ] **Restart Function App** (critical step!)
- [ ] Wait 30-60 seconds for app to start
- [ ] Test function endpoints
- [ ] Check Application Insights for errors

---

## Verification Script

```powershell
# Full deployment verification
$functionAppName = "sentryxdr"
$resourceGroup = "alex-testing-rg"
$tenantId = "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
$functionKey = "IM4G-JE3r1vDk35ZmAlmZIv8muL7-vTkjlKczXFJikAzFuLkGIQ=="

Write-Host "1. Checking package availability..." -ForegroundColor Yellow
$packageUrl = "https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip"
$response = Invoke-WebRequest -Uri $packageUrl -Method Head
if ($response.StatusCode -eq 200) {
    Write-Host "   ✅ Package available" -ForegroundColor Green
} else {
    Write-Host "   ❌ Package not found" -ForegroundColor Red
    exit 1
}

Write-Host "2. Restarting Function App..." -ForegroundColor Yellow
Restart-AzFunctionApp -Name $functionAppName -ResourceGroupName $resourceGroup
Write-Host "   ✅ Restart initiated" -ForegroundColor Green

Write-Host "3. Waiting for app to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "4. Testing Orchestrator endpoint..." -ForegroundColor Yellow
try {
    $headers = @{"x-functions-key" = $functionKey}
    $testUrl = "https://$functionAppName.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=$tenantId"
    $result = Invoke-RestMethod -Uri $testUrl -Headers $headers -TimeoutSec 30
    
    if ($result.success) {
        Write-Host "   ✅ Function working!" -ForegroundColor Green
        Write-Host "   Data count: $($result.data.count)" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️  Function returned error" -ForegroundColor Yellow
        Write-Host "   $($result.error.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Function test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Deployment Verification Complete ===" -ForegroundColor Cyan
```

---

## Summary

**Azure Functions with `WEBSITE_RUN_FROM_PACKAGE`:**
- ✅ Provides immutable, reproducible deployments
- ✅ Works great for read-only function code
- ❌ Does NOT auto-sync from package URL
- 🔄 **Requires manual restart** to pull updates

**Current Status:**
- Package exists on GitHub ✅
- ARM template configured correctly ✅
- **Action needed:** Restart Function App to load new package

---

**Next Step:** Run the restart command and test!
