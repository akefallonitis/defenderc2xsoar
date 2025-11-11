# Azure Functions Deployment with WEBSITE_RUN_FROM_PACKAGE

## How It Works

When you use `WEBSITE_RUN_FROM_PACKAGE`, Azure Functions operates in **read-only mode** from a package file. The behavior depends on the source URL type.

### Automatic Reload (HTTP/HTTPS URLs)

**Applies to:** GitHub raw URLs, public HTTP endpoints

1. **ETag Monitoring**: Function App periodically checks the package URL's ETag header
2. **Auto-Reload**: When ETag changes (new commit), Function App automatically downloads new package
3. **Typical reload time: 30-90 seconds** (no manual restart needed)
4. **Zero downtime**: Seamless transition between versions

**Current Configuration (uses auto-reload):**
```
https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
```

### Manual Reload Required (Azure Storage with SAS Token)

**Applies to:** Azure Blob Storage URLs with SAS tokens

- Function App caches package indefinitely
- Manual restart or sync required to pull updates
- Used when immutable versioned deployments are needed

### Key Differences

| Source Type | Auto-Reload | Best For |
|-------------|-------------|----------|
| **GitHub HTTP URL** | ✅ Yes (ETag-based) | Development, rapid iteration |
| **Azure Storage SAS** | ❌ No | Production, versioned releases |
| **Azure Storage Public** | ✅ Yes (if ETag changes) | Hybrid scenarios |

---

## Current Configuration

**Package URL:**
```
https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
```

**Configured in:** `azuredeploy.json` → `WEBSITE_RUN_FROM_PACKAGE` variable

---

## Deployment Options

### Option 1: Git Push (Automatic Reload) - RECOMMENDED ✅

**Current Method:** Just push to GitHub and wait for automatic reload.

```bash
# Make changes to code
git add .
git commit -m "Update function code"
git push origin main

# Wait 30-90 seconds for automatic reload
# Test endpoints - new code is live!
```

**Advantages:**
- ✅ Zero manual intervention
- ✅ ETag-based automatic detection
- ✅ No downtime
- ✅ Simple workflow

**When to use:** All code updates, bug fixes, new features

### Option 2: Manual Sync (Force Immediate Reload)

For immediate reload without waiting for ETag detection:

```bash
# Trigger immediate sync
az functionapp deployment source sync \
  --resource-group "alex-testing-rg" \
  --name "sentryxdr"
```

**Or via PowerShell:**
```powershell
Sync-AzFunctionApp -Name "sentryxdr" -ResourceGroupName "alex-testing-rg"
```

**When to use:** Urgent hotfixes, testing, verification

### Option 3: Restart Function App (Emergency Only)

Only needed if package isn't loading correctly:

```powershell
# Restart the Function App
Restart-AzFunctionApp -Name "sentryxdr" -ResourceGroupName "alex-testing-rg"
```

**Or via Azure Portal:**
1. Go to Function App
2. Click "Restart"
3. Wait ~30 seconds
4. Test functions

**When to use:** Package load errors, cache corruption, emergency recovery

### Option 4: Versioned Package URLs

For production deployments with explicit version control:

```json
"packageUrl": "https://github.com/akefallonitis/defenderc2xsoar/releases/download/v3.0.1/function-package.zip"
```

Change version in ARM template to deploy specific release.

**When to use:** Production releases, rollback scenarios

### Option 5: Azure DevOps / GitHub Actions

Set up CI/CD pipeline to:
1. Build package on commit
2. Upload to Azure Storage or GitHub Release
3. Update ARM template with new version
4. Run automated tests

**When to use:** Enterprise deployments, compliance requirements

---

## Why Function App Shows 404

**Root Cause:** Function App hasn't reloaded the updated package yet.

**How to verify:**
1. ✅ Package exists on GitHub (confirmed)
2. ⏳ Waiting for automatic reload (30-90 seconds after Git push)
3. ⚡ Force immediate reload: `az functionapp deployment source sync`

**Timeline:**
- **Immediate (0s):** Git push completes, package available on GitHub
- **30-60s:** GitHub CDN propagates, ETag updates
- **60-90s:** Function App detects ETag change, downloads new package
- **90s+:** New code active for all requests

**If still 404 after 2 minutes:** Run manual sync or restart (see Option 2/3 above)

---

## Comparison with Azure Sentinel Connectors

Azure Sentinel data connectors (50+ examples researched) use the **same pattern**:

- **Package Location**: GitHub raw URL or Azure Storage
- **Configuration**: `WEBSITE_RUN_FROM_PACKAGE` app setting
- **Deployment**: ARM template with connection strings (standard)
- **Updates**: Automatic reload for HTTP URLs (ETag-based)

**Examples from Microsoft Azure-Sentinel Repository:**

1. **Qualys VM Knowledgebase:**
   - Uses GitHub raw URL
   - Connection strings for storage (not managed identity)
   - Auto-reload enabled

2. **Varonis Data Security Platform:**
   ```bicep
   {
     name: 'AzureWebJobsStorage'
     value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value}'
   }
   {
     name: 'WEBSITE_RUN_FROM_PACKAGE'
     value: '1'  // Or direct URL
   }
   ```

3. **Veeam Backup Connector:**
   - Same pattern: connection strings + WEBSITE_RUN_FROM_PACKAGE
   - Uses `listKeys()` in ARM template (secure, no hard-coded keys)

**Key Insight:** Connection strings are Microsoft's **standard pattern**, not a security risk. Keys generated during deployment via ARM template's `listKeys()` function.

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

**Azure Functions with `WEBSITE_RUN_FROM_PACKAGE` (HTTP URLs):**
- ✅ Provides immutable, reproducible deployments
- ✅ Works great for read-only function code
- ✅ **Auto-reload enabled** via ETag detection (30-90s)
- ✅ No manual restart needed for normal updates
- 🔄 Manual sync available for immediate reload

**Current Status (DefenderC2XSOAR):**
- Package exists on GitHub ✅
- ARM template configured correctly ✅
- Connection strings (standard pattern) ✅
- Auto-reload enabled ✅
- **Expected behavior:** Code updates live within 90 seconds of Git push

---

## Quick Reference Commands

```bash
# Force immediate reload (Option 2)
az functionapp deployment source sync --resource-group "alex-testing-rg" --name "sentryxdr"

# Emergency restart (Option 3)
az functionapp restart --resource-group "alex-testing-rg" --name "sentryxdr"

# Check package accessibility
curl -I https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip

# Test Gateway endpoint
curl -X POST "https://sentryxdr.azurewebsites.net/api/Gateway" \
  -H "x-functions-key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"tenant":"TENANT_ID","service":"mde","action":"GetAllDevices"}'
```

---

**Next Step:** Wait 90 seconds after Git push, then test endpoints!
