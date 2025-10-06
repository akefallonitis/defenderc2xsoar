# Complete One-Click Deployment Guide

This guide explains how the complete one-click deployment works and how to use it.

## 🎯 What Gets Deployed

When you click "Deploy to Azure", the ARM template automatically deploys:

1. ✅ **Azure Function App** (PowerShell 7.4 runtime)
2. ✅ **App Service Plan** (Consumption tier)
3. ✅ **Storage Account** (for function app storage)
4. ✅ **Function Code** (all 11 functions from GitHub package)
5. ✅ **Workbook** (MDE Automator Workbook in Azure Monitor)
6. ✅ **Configuration** (all required app settings and environment variables)

## 🚀 Quick Deployment

### Option 1: Azure Portal (Recommended)

Click the button below to deploy everything in one click:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Fill in the required parameters:**
- **Function App Name**: Globally unique name (e.g., `mde-automator-prod`)
- **SPN ID**: Your multi-tenant app registration client ID
- **SPN Secret**: Your multi-tenant app registration client secret
- **Project Tag**: Project name (e.g., `DefenderC2`)
- **Created By Tag**: Your email or name
- **Delete At Tag**: Date or "Never"

### Option 2: PowerShell Script

Use the complete deployment script for automated deployment:

```powershell
cd deployment
./deploy-complete.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -FunctionAppName "mde-automator-prod" `
    -AppId "your-app-id-here" `
    -ClientSecret "your-client-secret-here" `
    -Location "westeurope"
```

### Option 3: Azure CLI

```bash
cd deployment

# Deploy infrastructure and functions
az deployment group create \
  --resource-group rg-defenderc2 \
  --template-file azuredeploy.json \
  --parameters \
    functionAppName=mde-automator-prod \
    spnId=your-app-id \
    spnSecret=your-client-secret \
    projectTag=DefenderC2 \
    createdByTag=your-email \
    deleteAtTag=Never
```

## 📦 How It Works

### 1. Deployment Package

The ARM template uses `WEBSITE_RUN_FROM_PACKAGE` to automatically deploy function code:

```json
{
  "name": "WEBSITE_RUN_FROM_PACKAGE",
  "value": "https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip"
}
```

This package contains all 11 Azure Functions:
- MDEDispatcher
- MDEOrchestrator
- MDECDManager  
- MDEHuntManager
- MDEIncidentManager
- MDETIManager
- ListLibraryFiles
- GetLibraryFile
- PutLiveResponseFileFromLibrary
- GetLiveResponseFile
- DeleteLibraryFile

### 2. Auto-Update via GitHub Actions

When you push changes to the `functions/` directory, GitHub Actions automatically:
1. Creates a new `function-package.zip`
2. Commits it to the repository
3. Next deployment uses the updated package

**Workflow:** `.github/workflows/create-deployment-package.yml`

### 3. Workbook Deployment

The ARM template includes a base64-encoded workbook resource that's automatically deployed to Azure Monitor.

**Access it:** Azure Portal → Monitor → Workbooks → MDE Automator Workbook

## 🔧 Updating the Deployment Package

### Manual Update

```powershell
# Create new package
cd deployment
./create-package.ps1

# Commit and push
git add function-package.zip
git commit -m "Update deployment package"
git push
```

### Automatic Update

Just push changes to the `functions/` directory - GitHub Actions handles the rest:

```bash
# Make changes to functions
vim functions/MDEDispatcher/run.ps1

# Commit and push
git add functions/
git commit -m "Update MDEDispatcher function"
git push

# GitHub Actions will automatically create and commit function-package.zip
```

## ✅ Verification Steps

After deployment (wait 2-3 minutes):

### 1. Check Function App

```bash
az functionapp function list \
  --resource-group rg-defenderc2 \
  --name mde-automator-prod \
  --query "[].name" -o table
```

**Expected output:**
```
MDEDispatcher
MDECDManager
MDEHuntManager
MDEIncidentManager
MDETIManager
```

### 2. Check Function App Settings

In Azure Portal:
1. Navigate to Function App → Configuration
2. Verify these settings exist:
   - ✅ `APPID` - Your app registration ID
   - ✅ `SECRETID` - Your client secret
   - ✅ `WEBSITE_RUN_FROM_PACKAGE` - Package URL
   - ✅ `PROJECT` - `functions`
   - ✅ `FUNCTIONS_WORKER_RUNTIME` - `powershell`
   - ✅ `FUNCTIONS_EXTENSION_VERSION` - `~4`

### 3. Check Workbook

1. Go to Azure Portal → Monitor → Workbooks
2. Find "MDE Automator Workbook"
3. Open and configure with:
   - Function App URL: `https://your-function-app.azurewebsites.net`
   - Target Tenant ID
   - SPN ID (from deployment)

### 4. Test Functions

Use the workbook or direct API calls:

```powershell
# Test MDEDispatcher
$functionUrl = "https://mde-automator-prod.azurewebsites.net/api/MDEDispatcher"
$functionKey = "your-function-key"

Invoke-RestMethod -Uri "$functionUrl?code=$functionKey&action=test" -Method GET
```

## 🔍 Troubleshooting

### Functions Not Appearing

**Symptoms:** Function app deployed but no functions visible

**Solutions:**
1. **Wait 2-3 minutes** - Package deployment takes time
2. **Check Application Insights logs:**
   ```bash
   az monitor app-insights events show \
     --app your-app-insights \
     --type traces \
     --query "[?contains(message, 'Host initialization')]"
   ```
3. **Verify package URL is accessible:**
   ```bash
   curl -I https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
   ```
4. **Check function app logs:**
   ```bash
   az webapp log tail \
     --resource-group rg-defenderc2 \
     --name mde-automator-prod
   ```

### Package Deployment Failed

**Error:** `Could not download package from URL`

**Solutions:**
1. Check the package exists in GitHub repository
2. Ensure repository is public or package URL is accessible
3. Manually create and upload package:
   ```powershell
   cd deployment
   ./create-package.ps1
   git add function-package.zip
   git commit -m "Add deployment package"
   git push
   ```

### Workbook Not Found

**Symptoms:** Can't find workbook in Azure Monitor

**Solutions:**
1. Check workbooks in the resource group:
   ```bash
   az resource list \
     --resource-group rg-defenderc2 \
     --resource-type Microsoft.Insights/workbooks
   ```
2. Manually deploy workbook:
   ```bash
   az deployment group create \
     --resource-group rg-defenderc2 \
     --template-file deployment/workbook-deploy.json
   ```

### PowerShell Version Error

**Error:** `The function runtime is unable to start`

**Solution:** Ensure PowerShell version is set to 7.4:
1. Go to Function App → Configuration
2. Check `powerShellVersion` is `7.4`
3. If not, update ARM template and redeploy

### Authentication Errors

**Error:** `401 Unauthorized` when calling functions

**Solutions:**
1. Verify `APPID` and `SECRETID` are set correctly
2. Check API permissions in app registration:
   - WindowsDefenderATP API permissions
   - Microsoft Graph API permissions
   - Admin consent granted
3. Verify tenant ID is correct
4. Check client secret hasn't expired

## 📚 Advanced Configuration

### Custom Package URL

To use a different package location:

1. Update ARM template variable:
   ```json
   "packageUrl": "https://your-storage-account.blob.core.windows.net/packages/functions.zip"
   ```

2. Upload package to your location:
   ```bash
   az storage blob upload \
     --account-name yourstorage \
     --container-name packages \
     --name functions.zip \
     --file deployment/function-package.zip
   ```

### Deploy from Private Repository

If your repository is private:

1. Create a SAS token for the package
2. Update ARM template to use the SAS URL
3. Or use GitHub Actions to push to Azure Storage

### Custom Workbook

To deploy a customized workbook:

1. Export your workbook as JSON
2. Base64 encode it:
   ```bash
   base64 -w 0 workbook/CustomWorkbook.json > workbook-base64.txt
   ```
3. Update `workbookContent` variable in ARM template
4. Redeploy

## 🔐 Security Best Practices

1. **Rotate Secrets Regularly**: Update client secret every 6-12 months
2. **Use Managed Identity**: Enable system-assigned managed identity where possible
3. **Restrict Network Access**: Configure network rules on function app
4. **Enable Authentication**: Add Azure AD authentication to function app
5. **Monitor Access**: Set up alerts for unusual activity
6. **Secure Secrets**: Consider using Azure Key Vault for secrets

## 📊 Monitoring

### Set Up Alerts

```bash
# Alert on function failures
az monitor metrics alert create \
  --name "Function Failures" \
  --resource-group rg-defenderc2 \
  --scopes $(az functionapp show -g rg-defenderc2 -n mde-automator-prod --query id -o tsv) \
  --condition "avg Http5xx > 5" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### View Metrics

```bash
# View function execution count
az monitor metrics list \
  --resource $(az functionapp show -g rg-defenderc2 -n mde-automator-prod --query id -o tsv) \
  --metric FunctionExecutionCount \
  --aggregation Sum
```

## 🆘 Support

If you encounter issues:

1. Check [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)
2. Review Application Insights logs
3. Open an issue on GitHub with:
   - Deployment method used
   - Error messages
   - ARM template deployment output
   - Function app logs

## 🎉 Success Checklist

- [ ] Function App deployed successfully
- [ ] All 11 functions visible in Azure Portal
- [ ] Function App URL accessible (https://your-app.azurewebsites.net)
- [ ] Workbook deployed to Azure Monitor
- [ ] Environment variables configured correctly
- [ ] Test API call successful
- [ ] Workbook can communicate with function app
- [ ] All functions return valid responses

**Congratulations! Your one-click deployment is complete! 🎉**
