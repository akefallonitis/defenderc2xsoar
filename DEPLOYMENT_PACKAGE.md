# DefenderC2 XSOAR Integration - Deployment Package

## 🎯 Quick Summary

This package contains a fully functional Azure Workbook integration for Microsoft Defender for Endpoint automation, ready for deployment.

## ✅ What's Included

### 1. **Azure Workbook** (workbook/DefenderC2-Complete.json)
- **Auto-populated Function Key**: Automatically retrieves function keys from Azure
- **16 ARM Actions**: All using proper Type 11 LinkItem format with armActionContext
- **Device Management**: Scan, isolate, unisolate, collect packages, restrict apps
- **Incident Management**: Create/update incidents, add comments
- **Threat Intelligence**: Submit indicators, manage allowlists
- **Hunt Management**: Advanced hunting queries with KQL
- **Custom Endpoint**: Direct API calls with auto-populated function keys

### 2. **Azure Functions** (functions/)
All functions configured with `authLevel: "function"` for ARM action compatibility:
- DefenderC2Dispatcher - Device action orchestration
- DefenderC2CDManager - Conditional access management
- DefenderC2HuntManager - Advanced hunting operations
- DefenderC2TIManager - Threat intelligence operations
- DefenderC2IncidentManager - Incident management
- DefenderC2Orchestrator - Workflow orchestration

### 3. **ARM Deployment Templates** (deployment/)
- azuredeploy.json - Main deployment template
- createUIDefinition.json - Azure Portal UI
- metadata.json - Marketplace metadata

## 🚀 Deployment Steps

### Prerequisites
- Azure subscription with Contributor role
- Microsoft Defender for Endpoint license
- Azure AD app registration with proper permissions

### Option 1: Azure Portal (Recommended)

1. **Upload Workbook**:
   ```
   Azure Portal → Monitor → Workbooks → + New → Advanced Editor
   Paste content from: workbook/DefenderC2-Complete.json
   ```

2. **Deploy Function App**:
   ```
   Azure Portal → Create Resource → Function App
   Runtime: PowerShell 7.2
   Upload code from: functions/ directory
   ```

3. **Configure Parameters**:
   - Subscription: Your Azure subscription
   - Resource Group: Your function app resource group
   - Function App Name: Your function app name
   - Tenant ID: Your Azure AD tenant ID

4. **Function Key Auto-population**:
   - The workbook automatically retrieves function keys via ARM API
   - No manual key configuration needed for ARM actions
   - Keys displayed in "🔑 Function Key" parameter for reference

### Option 2: ARM Template Deployment

```powershell
# Deploy using provided ARM template
cd deployment
az deployment group create `
  --resource-group <your-rg> `
  --template-file azuredeploy.json `
  --parameters azuredeploy.parameters.json
```

## 🔑 Function Key Auto-population

### How It Works
The workbook includes a special parameter that automatically fetches function keys:

```json
{
  "name": "FunctionKey",
  "type": 1,
  "query": "ARM API: /host/default/listKeys",
  "queryType": 12
}
```

- **ARM Actions**: Don't need the key (ARM handles auth automatically)
- **Custom Endpoint Queries**: Use `{FunctionKey}` parameter for direct API calls
- **Auto-refresh**: Updates when Function App parameter changes

### Where Keys Are Used

**ARM Actions** (No key needed):
- Run Antivirus Scan
- Isolate Device
- Unisolate Device
- Collect Investigation Package
- Restrict App Execution
- Unrestrict App Execution
- Cancel Action
- *(All other ARM actions)*

**Custom Endpoint** (Key required):
- Direct HTTP calls to function URLs
- Testing from external tools (Postman, curl)
- Automation scripts

## ⚙️ Authentication Configuration

### Functions Authentication Level
All functions are configured with `"authLevel": "function"`:

**Why "function" level?**
- ✅ Works with ARM /invoke endpoint
- ✅ Secure key-based authentication
- ✅ Compatible with Azure Workbooks ARM actions
- ❌ Anonymous auth doesn't work with ARM /invoke (returns 401)

### Required RBAC Permissions
Users need these roles on the Function App:
- **Contributor** OR **Website Contributor**: To invoke functions via ARM
- Permissions are checked by ARM, not the function

### Function.json Configuration
Each function has this binding configuration:

```json
{
  "authLevel": "function",
  "type": "httpTrigger",
  "direction": "in",
  "name": "Request",
  "methods": ["get", "post"]
}
```

## 🧪 Testing

### Test ARM Actions (Portal)

1. Open workbook in Azure Portal
2. Select your Function App from dropdown
3. Function Key auto-populates automatically
4. Click any ARM action button (e.g., "Run Scan")
5. Confirm in dialog
6. Check execution status

### Test Custom Endpoint (Portal)

1. Navigate to Custom Endpoint tab
2. Function Key already populated from top menu
3. Enter API endpoint URL
4. Click "Execute Query"
5. View JSON response

### Test From Command Line

```powershell
# Get function key from portal or use auto-populated value
$functionKey = "<your-function-key>"
$functionUrl = "https://<your-function-app>.azurewebsites.net/api/DefenderC2Dispatcher"

# Test request
Invoke-RestMethod -Uri "$functionUrl?code=$functionKey" `
  -Method POST `
  -Body (@{
    action = "Run Antivirus Scan"
    tenantId = "<your-tenant-id>"
    deviceIds = @("<device-id>")
  } | ConvertTo-Json) `
  -ContentType "application/json"
```

## 📋 ARM Action Format

All ARM actions use this correct pattern:

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "list",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "🚀 Execute Action",
      "style": "primary",
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invoke",
        "headers": [],
        "params": [
          {"key": "api-version", "value": "2022-03-01"},
          {"key": "action", "value": "Run Antivirus Scan"},
          {"key": "tenantId", "value": "{TenantId}"},
          {"key": "deviceIds", "value": "{DeviceList}"}
        ],
        "httpMethod": "POST",
        "title": "Run Antivirus Scan",
        "description": "This will run a full antivirus scan on selected devices",
        "runLabelFormat": "Running scan..."
      }
    }]
  }
}
```

**Key Points**:
- ✅ Type 11 (LinkItem) - Correct format for ARM actions
- ✅ armActionContext with proper ARM path
- ✅ Confirmation dialogs with descriptions
- ❌ Type 3 with queryType 12 - Old format, doesn't work

## 🔧 Troubleshooting

### ARM Actions Not Working

**Symptom**: Clicking ARM action does nothing or shows error

**Solutions**:
1. Check function authLevel is "function" (not "anonymous")
2. Verify user has Contributor role on Function App
3. Ensure ARM actions use Type 11 (LinkItem) format
4. Check function app is running

### Function Key Not Auto-populating

**Symptom**: Function Key parameter is empty

**Solutions**:
1. Select Function App from dropdown first
2. Verify you have permissions to list keys (Contributor role)
3. Check network connectivity to Azure ARM API
4. Refresh workbook

### 401 Unauthorized Errors

**Cause**: Functions configured with `authLevel: "anonymous"`

**Solution**: Update function.json files to `"authLevel": "function"`

```powershell
# Fix in portal (Advanced Tools → App Service Editor)
# Or redeploy with corrected function.json files
```

## 📚 Additional Documentation

- **Quick Reference**: See DEFENDERC2_QUICKREF.md
- **Deployment Details**: See deployment/README.md
- **Custom Endpoint Guide**: See docs/WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md
- **Authentication Details**: See AUTH_LEVEL_UPDATE.md

## 🎉 What's Fixed

This deployment package includes these critical fixes:

### ✅ ARM Actions Fixed (Type 3 → Type 11)
All ARM actions converted from broken Type 3 (KqlItem) to proper Type 11 (LinkItem) format with armActionContext.

### ✅ Function Authentication Fixed
All 6 functions updated from `authLevel: "anonymous"` to `authLevel: "function"` to work with ARM /invoke endpoint.

### ✅ Function Key Auto-population Added
Workbook now automatically retrieves and displays function keys via ARM listKeys API - no manual configuration needed.

### ✅ Documentation Cleaned Up
Removed 40+ duplicate/outdated documentation files, keeping only essential guides.

## 🚨 Critical Notes

1. **Do NOT use anonymous auth** for functions if using ARM actions
2. **ARM actions require RBAC permissions** on Function App (Contributor role)
3. **Function keys are optional** for ARM actions (ARM handles auth)
4. **Keys are required** for direct HTTP calls (Custom Endpoint)
5. **Test in portal first** before automation

## 📦 Package Contents

```
defenderc2xsoar/
├── workbook/
│   └── DefenderC2-Complete.json    ← Deploy this workbook
├── functions/
│   ├── DefenderC2Dispatcher/
│   ├── DefenderC2CDManager/
│   ├── DefenderC2HuntManager/
│   ├── DefenderC2TIManager/
│   ├── DefenderC2IncidentManager/
│   └── DefenderC2Orchestrator/
├── deployment/
│   ├── azuredeploy.json
│   ├── createUIDefinition.json
│   └── azuredeploy.parameters.json
└── README.md (this file)
```

## 🎯 Next Steps

1. ✅ Deploy Function App with corrected function.json files
2. ✅ Upload workbook to Azure Portal
3. ✅ Configure parameters (Subscription, Resource Group, Function App Name)
4. ✅ Test ARM actions (Function Key auto-populates)
5. ✅ Test Custom Endpoint queries
6. ✅ Grant users Contributor role on Function App
7. ✅ Monitor execution in Function App logs

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-06  
**Status**: Production Ready ✅
