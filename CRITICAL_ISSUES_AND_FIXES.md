# DefenderXDR C2 v3.0.0 - Critical Issues & Fixes

**Date**: November 13, 2025  
**Status**: 🔴 **DEPLOYMENT BROKEN** - All API calls returning 500 Internal Server Error  
**Root Cause**: Authentication configuration issues

---

## 🔴 CRITICAL ISSUES IDENTIFIED

### Issue #1: Environment Variables Not Loaded
**Symptom**: All API requests return 500 Internal Server Error  
**Root Cause**: Orchestrator cannot find `APPID` and `SECRETID` environment variables  
**Evidence**: Azure Portal logs show "Gateway error: Response status code does not indicate success:500"

**Current Configuration** (from Azure Portal):
```
APPID = <your-app-id>  ✅ SHOULD BE SET
SECRETID = <your-client-secret>  ✅ SHOULD BE SET
```

**Code Expectation** (Orchestrator line 100-101):
```powershell
$appId = $env:APPID
$secretId = $env:SECRETID
```

**Fix Required**:
1. Verify environment variables are actually loaded in Function App
2. Check if Function App needs restart to pick up new environment variables
3. Validate App Registration has admin consent for all API permissions

### Issue #2: App Registration Permissions Not Granted
**Symptom**: Even with valid credentials, authentication may fail without admin consent  
**Root Cause**: Application permissions require tenant admin consent  
**Required Action**: Grant admin consent for all API permissions

**Required Permissions** (Total: 25):
- **Microsoft Graph API** (19 permissions):
  - SecurityIncident.ReadWrite.All
  - SecurityAlert.ReadWrite.All
  - ThreatHunting.Read.All
  - User.ReadWrite.All
  - UserAuthenticationMethod.ReadWrite.All
  - IdentityRiskyUser.ReadWrite.All
  - Policy.ReadWrite.ConditionalAccess
  - DeviceManagementManagedDevices.ReadWrite.All
  - DeviceManagementConfiguration.ReadWrite.All
  - Mail.ReadWrite
  - Files.ReadWrite.All
  - eDiscovery.ReadWrite.All
  - Application.ReadWrite.All
  - Directory.ReadWrite.All
  - And more...

- **Microsoft Defender for Endpoint API** (6 permissions):
  - Machine.ReadWrite.All
  - Machine.LiveResponse
  - Alert.ReadWrite.All
  - Ti.ReadWrite.All
  - AdvancedQuery.Read.All
  - Library.Manage

---

## 🔧 IMMEDIATE FIXES REQUIRED

### Fix #1: Restart Function App (PRIORITY 1)
Azure Function Apps cache environment variables. After adding `APPID` and `SECRETID`, restart is required.

**Azure Portal Steps**:
1. Navigate to Function App: `https://portal.azure.com` → sentryxdr
2. Click "Restart" in the Overview blade
3. Wait 2-3 minutes for Function App to fully restart
4. Test API endpoint

**PowerShell Command**:
```powershell
Restart-AzWebApp -ResourceGroupName "<your-resource-group>" -Name "<your-function-app>"
```

### Fix #2: Grant Admin Consent (PRIORITY 1)
App Registration permissions are configured but not granted by tenant admin.

**Azure Portal Steps**:
1. Navigate to: Azure Portal → App Registrations → DefenderXDR C2
2. Click "API permissions" in left menu
3. Click "Grant admin consent for [Your Tenant]" button
4. Confirm the consent dialog

**Direct URL**:
```
https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/<your-app-id>
```

### Fix #3: Run Permission Configuration Script
Use the provided PowerShell script to automate permission setup:

**Command**:
```powershell
cd deployment
.\Configure-AppRegistrationPermissions.ps1 `
    -AppId "<your-app-id>" `
    -TenantId "<your-tenant-id>" `
    -CreateNewSecret
```

**What It Does**:
- Removes all existing API permissions (clean slate)
- Adds all 25 required permissions for v3.0.0
- Optionally creates a new client secret (2-year expiry)
- Provides direct link to grant admin consent

---

## 🧪 DIAGNOSTIC TOOLS CREATED

### Tool #1: DiagnosticCheck Function
New Azure Function endpoint to validate environment configuration.

**Test Command**:
```powershell
Invoke-RestMethod -Uri "https://<your-function-app>.azurewebsites.net/api/DiagnosticCheck?code=<your-function-key>"
```

**Expected Response**:
```json
{
  "functionApp": {
    "hostname": "<your-function-app>.azurewebsites.net",
    "resourceGroup": "<your-resource-group>"
  },
  "credentials": {
    "appIdConfigured": true,
    "appIdValue": "<app-id-prefix>...",
    "secretIdConfigured": true,
    "secretIdValue": "***CONFIGURED***"
  },
  "modules": {
    "authManagerExists": true,
    "validationHelperExists": true,
    "loggingHelperExists": true
  }
}
```

### Tool #2: Test-API-Quick.ps1
Quick validation script to test all major endpoints.

**Run**:
```powershell
cd deployment
.\Test-API-Quick.ps1
```

**What It Tests**:
- MDE Worker: GetDevices, GetAllActions, GetIndicators, GetIncidents, GetAlerts
- EntraID Worker: GetRiskyUsers, GetRiskDetections
- Intune Worker: GetManagedDevices
- Azure Worker: GetResourceGroups, GetVMs

---

## 📋 STEP-BY-STEP RESOLUTION PLAN

### Step 1: Deploy Diagnostic Function (IMMEDIATE)
```powershell
# Commit new diagnostic function
cd c:\Users\AlexandrosKefallonit\Desktop\FF\defenderc2xsoar\defenderc2xsoar
git add functions/DiagnosticCheck/
git commit -m "Add diagnostic endpoint for troubleshooting"
git push

# Wait 2-3 minutes for auto-deployment (if enabled)
# OR manually deploy via Azure Portal
```

### Step 2: Run Diagnostic Check (IMMEDIATE)
```powershell
# Test diagnostic endpoint
$result = Invoke-RestMethod -Uri "https://<your-function-app>.azurewebsites.net/api/DiagnosticCheck?code=<your-function-key>"
$result | ConvertTo-Json -Depth 5

# Check if credentials are configured
if (-not $result.credentials.appIdConfigured) {
    Write-Host "❌ APPID not configured in environment variables" -ForegroundColor Red
}
if (-not $result.credentials.secretIdConfigured) {
    Write-Host "❌ SECRETID not configured in environment variables" -ForegroundColor Red
}
```

### Step 3: Restart Function App (IMMEDIATE)
```powershell
# Via Azure CLI
az functionapp restart --name <your-function-app> --resource-group <your-resource-group>

# OR via PowerShell
Restart-AzWebApp -ResourceGroupName "<your-resource-group>" -Name "<your-function-app>"

# Wait 2-3 minutes, then re-run diagnostic check
```

### Step 4: Configure App Registration Permissions (HIGH PRIORITY)
```powershell
# Run permission configuration script
cd deployment
.\Configure-AppRegistrationPermissions.ps1 `
    -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
    -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" `
    -CreateNewSecret

# Follow prompts to grant admin consent in Azure Portal
```

### Step 5: Test API Endpoints (VALIDATION)
```powershell
# Run quick API test
cd deployment
.\Test-API-Quick.ps1

# Expected: All tests should pass (✅ SUCCESS)
# If still failing, check Application Insights logs for detailed errors
```

### Step 6: Validate Storage Account Configuration (OPTIONAL)
Check if storage account strings are properly configured for Live Response file operations:

**Required Environment Variables**:
- `AzureWebJobsStorage`: Connection string for Azure Functions runtime
- `STORAGE_ACCOUNT_NAME`: Storage account name for Live Response files (optional)
- `AzureWebJobsStorage` format: `DefaultEndpointsProtocol=https;AccountName=XXX;AccountKey=XXX`

**Validation**:
```powershell
# Check current storage configuration
$diagnosticResult = Invoke-RestMethod -Uri "https://<your-function-app>.azurewebsites.net/api/DiagnosticCheck?code=<your-function-key>"
$diagnosticResult.storage
```

---

## 🎯 SUCCESS CRITERIA

All tests should pass with these results:

1. **Diagnostic Check**: ✅ All credentials configured
2. **API Test - MDE GetDevices**: ✅ Returns device list
3. **API Test - MDE GetIncidents**: ✅ Returns incident list
4. **API Test - EntraID GetRiskyUsers**: ✅ Returns risky user list
5. **API Test - Azure GetResourceGroups**: ✅ Returns resource group list

---

## 📞 SUPPORT INFORMATION

**Azure Function App**:
- Name: <your-function-app>
- URL: https://<your-function-app>.azurewebsites.net
- Resource Group: <your-resource-group>
- Tenant ID: <your-tenant-id>

**App Registration**:
- App ID: <your-app-id>
- Display Name: DefenderXDR C2
- Portal URL: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/<your-app-id>

**Application Insights**:
- View logs: Azure Portal → <your-function-app> → Monitoring → Logs
- Query: `traces | where timestamp > ago(1h) | order by timestamp desc`

---

## 📝 NOTES

1. **Environment Variables**: Azure Functions cache environment variables. Always restart after changes.
2. **Admin Consent**: Required for all application permissions. Cannot be bypassed.
3. **Token Caching**: AuthManager caches tokens for 55 minutes. First call after restart will be slower.
4. **Multi-Tenant**: Each tenant requires separate OAuth token. Tokens are cached per tenant.

---

**Last Updated**: November 13, 2025  
**Next Action**: Restart Function App and run diagnostic check
