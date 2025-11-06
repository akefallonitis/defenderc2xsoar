# ✅ DEPLOYMENT CHECKLIST

## 📦 Package Validation Complete

Use this checklist to deploy the DefenderC2 solution to your Azure environment.

---

## Pre-Deployment Checklist

### ✅ Prerequisites
- [ ] Azure subscription with Contributor role
- [ ] Microsoft Defender for Endpoint license
- [ ] Azure AD App Registration created
  - [ ] API Permissions granted (Microsoft Graph, WindowsDefenderATP)
  - [ ] Admin consent provided
  - [ ] Client secret created and saved

### ✅ Package Verification
- [x] Workbook JSON validated (`workbook/DefenderC2-Complete.json`)
- [x] FunctionKey parameter present and configured
- [x] ARM actions use Type 11 (LinkItem) format
- [x] All 6 functions have `authLevel: "function"`
- [x] ARM templates validated
- [x] Documentation updated

---

## Deployment Steps

### Step 1: Deploy Function App
**Choose one method:**

#### Option A: Azure Portal (Recommended for first deployment)
- [ ] Navigate to Azure Portal → Create Resource → Function App
- [ ] Configure:
  - Name: `defenderc2-<your-name>`
  - Runtime: PowerShell 7.2 or later
  - OS: Windows
  - Plan: Consumption (Serverless) or Premium
- [ ] Click "Review + Create" → "Create"
- [ ] Wait for deployment to complete

#### Option B: ARM Template
```powershell
# From deployment/ directory
cd deployment
az deployment group create `
  --resource-group <your-resource-group> `
  --template-file azuredeploy.json `
  --parameters azuredeploy.parameters.json
```

- [ ] ARM template deployment completed successfully
- [ ] Function app is running

### Step 2: Upload Function Code
- [ ] Open Function App in Azure Portal
- [ ] Navigate to "Advanced Tools" → "Go"
- [ ] Open "App Service Editor" or use VS Code/deployment tools
- [ ] Upload entire `functions/` directory
- [ ] Verify all 6 functions are present:
  - [ ] DefenderC2Dispatcher
  - [ ] DefenderC2CDManager
  - [ ] DefenderC2HuntManager
  - [ ] DefenderC2TIManager
  - [ ] DefenderC2IncidentManager
  - [ ] DefenderC2Orchestrator

### Step 3: Configure Function App Settings
- [ ] Navigate to Function App → Configuration → Application Settings
- [ ] Add required settings:
  ```
  TENANT_ID: <your-azure-ad-tenant-id>
  CLIENT_ID: <your-app-registration-client-id>
  CLIENT_SECRET: <your-app-registration-client-secret>
  ```
- [ ] Click "Save" → "Continue"
- [ ] Restart Function App

### Step 4: Verify Function Authentication Level
- [ ] For each function, check function.json has:
  ```json
  {
    "authLevel": "function"
  }
  ```
- [ ] If any function has `"authLevel": "anonymous"`, update it to `"function"`
- [ ] Restart Function App after changes

### Step 5: Upload Workbook
- [ ] Navigate to Azure Portal → Monitor → Workbooks
- [ ] Click "+ New"
- [ ] Click "Advanced Editor" (</> icon in toolbar)
- [ ] Select "Gallery Template" → Clear existing JSON
- [ ] Copy entire contents of `workbook/DefenderC2-Complete.json`
- [ ] Paste into editor
- [ ] Click "Apply"
- [ ] Click "Done Editing"
- [ ] Click "Save As"
  - Name: `DefenderC2 Complete`
  - Region: Same as Function App
  - Resource Group: Same as Function App
- [ ] Click "Apply"

### Step 6: Configure Workbook Parameters
- [ ] Open saved workbook
- [ ] Configure top menu parameters:
  - [ ] **Function App**: Select your deployed function app from dropdown
  - [ ] **Tenant ID**: Should auto-populate (verify it's correct)
  - [ ] **Function Key**: Should auto-populate automatically ✅
- [ ] Verify Function Key parameter shows a value (starts with letters/numbers)

### Step 7: Grant RBAC Permissions
Users need Contributor role on Function App to execute ARM actions:

```powershell
# For each user who will use ARM actions
az role assignment create `
  --assignee <user-email@domain.com> `
  --role "Contributor" `
  --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Web/sites/<function-app-name>"
```

- [ ] RBAC permissions granted to required users
- [ ] Verify users can see Function App in their Azure Portal

---

## Testing & Validation

### Test 1: Function Key Auto-population
- [ ] Open workbook
- [ ] Change Function App dropdown selection
- [ ] Verify Function Key parameter updates automatically
- [ ] Verify key is not empty (should show alphanumeric string)

### Test 2: ARM Actions
- [ ] Navigate to "Device Management" tab
- [ ] Select a test device from list
- [ ] Click "Run Scan" button
- [ ] Verify confirmation dialog appears with:
  - Title: "Run Antivirus Scan"
  - Description explaining the action
  - OK and Cancel buttons
- [ ] Click "OK"
- [ ] Verify execution starts (shows "Running scan..." or similar)
- [ ] Check Function App logs for execution

### Test 3: Custom Endpoint
- [ ] Navigate to "Custom Endpoint" tab (if available)
- [ ] Verify Function Key is already populated
- [ ] Enter a test query
- [ ] Click "Execute"
- [ ] Verify response received

### Test 4: Function App Logs
- [ ] Navigate to Function App → Log Stream
- [ ] Execute an ARM action from workbook
- [ ] Verify logs show:
  - Incoming request
  - Authentication success
  - Action execution
  - Response sent

---

## Troubleshooting

### Issue: Function Key Not Auto-populating
**Symptoms**: FunctionKey parameter is empty

**Solutions**:
- [ ] Verify you selected a Function App from dropdown
- [ ] Check you have Contributor role on Function App
- [ ] Try refreshing the workbook
- [ ] Check browser console for errors

### Issue: ARM Actions Don't Work
**Symptoms**: Clicking ARM action does nothing or shows error

**Solutions**:
- [ ] Verify functions have `authLevel: "function"` (not "anonymous")
  - Check each function.json file
  - Update if needed and restart Function App
- [ ] Verify user has Contributor role on Function App
- [ ] Check Function App is running (not stopped)
- [ ] Verify ARM actions use Type 11 (LinkItem) format
- [ ] Check Function App logs for errors

### Issue: 401 Unauthorized Error
**Symptoms**: ARM action returns 401 error

**Solutions**:
- [ ] Update function.json to `"authLevel": "function"`
- [ ] Redeploy Function App
- [ ] Verify user has RBAC permissions
- [ ] Check App Registration permissions

### Issue: 500 Internal Server Error
**Symptoms**: Function executes but returns 500 error

**Solutions**:
- [ ] Check Function App Configuration settings (TENANT_ID, CLIENT_ID, CLIENT_SECRET)
- [ ] Verify App Registration permissions
- [ ] Check Function App logs for detailed error
- [ ] Verify PowerShell modules are installed

---

## Post-Deployment

### Documentation
- [ ] Review [DEPLOYMENT_PACKAGE.md](DEPLOYMENT_PACKAGE.md) for detailed reference
- [ ] Share [QUICKSTART.md](QUICKSTART.md) with end users
- [ ] Review [DEFENDERC2_QUICKREF.md](DEFENDERC2_QUICKREF.md) for feature overview

### Monitoring
- [ ] Set up Azure Monitor alerts for Function App failures
- [ ] Enable Application Insights (if not already enabled)
- [ ] Review execution logs regularly

### Security
- [ ] Rotate App Registration client secret periodically
- [ ] Review RBAC permissions regularly
- [ ] Monitor for unauthorized access attempts
- [ ] Keep function code updated

---

## Success Criteria

You've successfully deployed DefenderC2 when:

- ✅ Function App is deployed and running
- ✅ All 6 functions are present with correct authLevel
- ✅ Workbook is uploaded and accessible
- ✅ Function Key auto-populates in workbook
- ✅ ARM actions show confirmation dialogs
- ✅ ARM actions execute successfully
- ✅ Function App logs show successful executions
- ✅ Users can perform device management tasks

---

## Need Help?

**Documentation**:
- DEPLOYMENT_PACKAGE.md - Complete deployment guide
- AUTH_LEVEL_UPDATE.md - Authentication configuration details
- CRITICAL_FINDING.md - Root cause analysis and fixes

**Testing Tools**:
- `validate_workbook.py` - Validates workbook JSON structure
- `workbook_tests/verify_arm_actions.py` - Verifies ARM action format

**Common Files to Check**:
- `functions/*/function.json` - Function authentication settings
- `workbook/DefenderC2-Complete.json` - Production workbook
- `deployment/azuredeploy.json` - ARM deployment template

---

**Package Version**: 1.0.0  
**Last Updated**: 2025-01-06  
**Status**: PRODUCTION READY ✅
