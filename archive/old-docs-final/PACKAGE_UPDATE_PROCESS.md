# Deployment Package Update Process

## 🎯 Purpose

This package (`function-package.zip`) is deployed via **WEBSITE_RUN_FROM_PACKAGE** setting in Azure Function App.

**ARM Template URL:** `https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip`

## 📦 When to Update Package

Update the package when you:
- Add new worker functions
- Modify existing function code
- Update PowerShell modules
- Fix bugs in run.ps1 files

## 🔧 How to Update Package

### Step 1: Make Code Changes

Edit files in `functions/` directory:
- Worker functions (MDOWorker, MDCWorker, etc.)
- PowerShell modules (DefenderXDRC2XSOAR/*.psm1)
- Configuration files (host.json, requirements.psd1)

### Step 2: Create New Package

```powershell
# Run from repository root
cd c:\Users\AlexandrosKefallonit\Desktop\FF\defenderc2xsoar\defenderc2xsoar

# Option A: Use the script
.\deployment\create-package.ps1

# Option B: Manual creation
Compress-Archive -Path "functions\*" -DestinationPath "deployment\function-package-NEW.zip" -Force

# Replace old package (close VS Code first if file is locked)
Remove-Item deployment\function-package.zip -Force
Rename-Item deployment\function-package-NEW.zip function-package.zip
```

### Step 3: Verify Package

```powershell
# Check package contents
$zip = [System.IO.Compression.ZipFile]::OpenRead("deployment\function-package.zip")
Write-Host "Total files: $($zip.Entries.Count)"
$workers = $zip.Entries | Where-Object {$_.FullName -match "Worker"}
Write-Host "Worker files: $($workers.Count)"
$zip.Dispose()

# Expected:
# Total files: 54+
# Worker files: 12+ (6 workers x 2 files minimum)
```

### Step 4: Commit to GitHub

```bash
git add deployment/function-package.zip
git commit -m "Update deployment package - [describe changes]"
git push origin main
```

### Step 5: Auto-Update Deployed Function Apps

**Automatic Update (Recommended):**
- Wait 5-10 minutes
- Function apps detect new package via WEBSITE_RUN_FROM_PACKAGE
- Apps automatically restart and load new code
- No manual intervention needed

**Manual Update (If needed immediately):**
```powershell
# Restart function app to force package reload
az functionapp restart --name <function-app-name> --resource-group <rg-name>
```

---

## 🔍 Verification

### Check Package is Live on GitHub
```powershell
# Should return 200 OK and show new file size
Invoke-WebRequest -Uri "https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip" -Method Head
```

### Check Function App Loaded New Package
```powershell
# In Azure Portal:
# Function App → Functions → Should see all workers listed

# Via CLI:
az functionapp function list --name <your-app> --resource-group <your-rg> --query "[].name" -o table
```

### Test Worker Endpoint
```powershell
$FunctionUrl = "https://<your-app>.azurewebsites.net/api/MDOWorker"
$FunctionKey = "<your-key>"

$response = Invoke-RestMethod -Uri $FunctionUrl -Method Post `
  -Headers @{"x-functions-key"=$FunctionKey} `
  -Body (@{action="RemediateEmail"; tenantId="xxx"; messageId="xxx"} | ConvertTo-Json) `
  -ContentType "application/json"

$response
```

---

## ⚠️ Important Notes

### File Locking Issue
If you get "file is being used by another process":
1. Close VS Code Explorer view showing deployment folder
2. Or restart VS Code completely
3. Then run the package creation commands

### Package Size
- Current size: ~80KB (with all 6 workers)
- Old size: ~45KB (without workers)
- If your package is still 45KB, workers didn't get included

### GitHub Raw URL Cache
- GitHub may cache the raw file for 5-10 minutes
- Deployed function apps check for updates every 5-10 minutes
- Force refresh: Restart function app manually

---

## 📋 Checklist

When updating the package:
- [ ] Made code changes in `functions/` directory
- [ ] Ran `create-package.ps1` or manual Compress-Archive
- [ ] Verified package size increased (~80KB)
- [ ] Verified package contains workers (12+ files)
- [ ] Closed VS Code to avoid file locks
- [ ] Replaced `function-package.zip` successfully
- [ ] Committed and pushed to GitHub
- [ ] Waited 5-10 minutes OR restarted function app
- [ ] Tested worker endpoint works

---

## 🚀 One-Click Deployment

**New deployments automatically get latest package:**

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

ARM template automatically:
1. Creates Function App
2. Sets WEBSITE_RUN_FROM_PACKAGE to GitHub raw URL
3. Function App downloads and deploys latest package
4. All workers become immediately available

---

## 🔄 Update Flow Diagram

```
Code Changes
    ↓
Create New Package (create-package.ps1)
    ↓
Replace function-package.zip
    ↓
Git Commit & Push
    ↓
GitHub Raw URL Updates
    ↓
(Wait 5-10 min)
    ↓
Deployed Function Apps Auto-Detect Change
    ↓
Function Apps Auto-Restart
    ↓
New Workers Available
```

---

## 📞 Troubleshooting

**Package not updating?**
- Check GitHub raw URL returns correct size
- Restart function app manually
- Check Application Insights logs for errors

**Workers missing after update?**
- Verify package contains Worker folders
- Check function app logs: Function App → Log stream
- Redeploy if necessary

**File locked during package creation?**
- Close VS Code Explorer
- Close any PowerShell terminals with $zip variables
- Run `[System.GC]::Collect()` to release handles
