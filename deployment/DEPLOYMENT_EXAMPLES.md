# Deployment Examples - Function App Name in Action

This document demonstrates how the dynamic function app name system works in practice across different deployment scenarios.

---

## Example 1: Azure Portal Deployment ("Deploy to Azure" Button)

### User Journey

**Step 1: User clicks "Deploy to Azure" button**

```
https://portal.azure.com/#create/Microsoft.Template/uri/...
```

**Step 2: Azure Portal shows custom UI from `createUIDefinition.json`**

```
┌─────────────────────────────────────────────────┐
│ DefenderC2 Function App Deployment              │
├─────────────────────────────────────────────────┤
│                                                  │
│ Function App Name: [mycompany-defender      ]   │
│                                                  │
│ Multi-tenant App Registration (Client ID):      │
│ [00000000-0000-0000-0000-000000000000       ]   │
│                                                  │
│ Client Secret: [••••••••••••••••••••••••••] │
│                                                  │
│ [✓] Enable Managed Identity                     │
│                                                  │
│ Project Tag: [DefenderAutomation            ]   │
│ CreatedBy Tag: [security-team@example.com   ]   │
│ DeleteAt Tag: [Never                        ]   │
│                                                  │
│                     [ Review + Create ]          │
└─────────────────────────────────────────────────┘
```

**Step 3: ARM Template processes deployment**

```json
{
  "parameters": {
    "functionAppName": "mycompany-defender"  // ← User's input
  },
  "variables": {
    "functionAppName": "[parameters('functionAppName')]"
  },
  "resources": [
    {
      "type": "Microsoft.Web/sites",
      "name": "[variables('functionAppName')]"  // ← Creates: mycompany-defender
    },
    {
      "type": "Microsoft.Insights/workbooks",
      "properties": {
        "serializedData": "[replace(
          base64ToString(variables('workbookContent')), 
          '__FUNCTION_APP_NAME_PLACEHOLDER__', 
          variables('functionAppName')
        )]"
        // ← Replaces placeholder with: mycompany-defender
      }
    }
  ]
}
```

**Step 4: Workbook is deployed with configured parameter**

```json
{
  "name": "FunctionAppName",
  "value": "mycompany-defender",  // ← Automatically configured!
  "label": "Function App Name",
  "type": 1
}
```

**Step 5: All API endpoints automatically work**

```
✓ https://mycompany-defender.azurewebsites.net/api/DefenderC2Dispatcher
✓ https://mycompany-defender.azurewebsites.net/api/DefenderC2TIManager
✓ https://mycompany-defender.azurewebsites.net/api/DefenderC2HuntManager
✓ https://mycompany-defender.azurewebsites.net/api/DefenderC2IncidentManager
... (27 total endpoints)
```

**Result**: ✅ User opens workbook in Azure Portal and it works immediately!

---

## Example 2: PowerShell Script Deployment

### Command

```powershell
.\deployment\deploy-all.ps1 `
    -ResourceGroupName "rg-defender-prod" `
    -FunctionAppName "prod-mde-automation" `
    -SpnId "12345678-1234-1234-1234-123456789012" `
    -SpnSecret "MySecretValue123!" `
    -ProjectTag "SecurityAutomation" `
    -CreatedByTag "john.doe@company.com" `
    -DeleteAtTag "2025-12-31"
```

### Script Processing

```powershell
# Script flow
1. Validates Azure CLI is installed ✓
2. Creates resource group ✓
3. Deploys function app with name: "prod-mde-automation" ✓
4. Loads workbook JSON file ✓
5. Finds FunctionAppName parameter ✓
6. Updates value: __FUNCTION_APP_NAME_PLACEHOLDER__ → "prod-mde-automation" ✓
7. Deploys workbook with updated content ✓
```

### Output

```
🚀 DefenderC2 Complete Deployment
==================================

✅ Azure CLI version: 2.53.0
✅ Logged in as: john.doe@company.com
✅ Resource group 'rg-defender-prod' ready

📦 Deploying Function App...
   Function App Name: prod-mde-automation
   ✅ Function app deployed successfully

📊 Deploying Main Workbook...
   Loading workbook content...
   Setting Function App Name parameter to: prod-mde-automation
   ✅ Function App Name parameter updated
   Deploying workbook...
   ✅ Main workbook deployed successfully

✅ Deployment complete!

📋 Resources Created:
   • Function App: prod-mde-automation
   • Workbook: DefenderC2 Command & Control Console
   • Storage Account: storagexxxxxxxxxxxxx

🎯 Workbook Configuration:
   FunctionAppName = prod-mde-automation

🌐 Endpoints:
   https://prod-mde-automation.azurewebsites.net/api/DefenderC2Dispatcher
   https://prod-mde-automation.azurewebsites.net/api/DefenderC2TIManager
   https://prod-mde-automation.azurewebsites.net/api/DefenderC2HuntManager
   ... (and 24 more)
```

**Result**: ✅ Workbook works with "prod-mde-automation" function app!

---

## Example 3: Azure CLI with ARM Template

### Command

```bash
az deployment group create \
    --resource-group rg-security \
    --template-file deployment/azuredeploy.json \
    --parameters \
        functionAppName=security-ops-defender \
        spnId=87654321-4321-4321-4321-210987654321 \
        spnSecret=MySecret456 \
        projectTag=SecurityOps \
        createdByTag=ops-team@company.com \
        deleteAtTag=Never
```

### Processing

```
Validating template...                    ✓
Creating resources...                      
  ├─ Function App: security-ops-defender  ✓
  ├─ App Service Plan                     ✓
  ├─ Storage Account                      ✓
  └─ Workbook                             ✓
     └─ Replaced: __FUNCTION_APP_NAME_PLACEHOLDER__
        with: security-ops-defender

Deployment succeeded!
```

### Workbook Configuration

```json
{
  "parameters": [
    {
      "name": "FunctionAppName",
      "value": "security-ops-defender",  // ← Automatically set!
      "type": 1
    }
  ]
}
```

### Endpoints

```
✓ https://security-ops-defender.azurewebsites.net/api/DefenderC2Dispatcher
✓ https://security-ops-defender.azurewebsites.net/api/DefenderC2TIManager
✓ https://security-ops-defender.azurewebsites.net/api/DefenderC2HuntManager
... (27 total)
```

**Result**: ✅ Everything works with "security-ops-defender"!

---

## Example 4: Multiple Environments

### Development Environment

```powershell
.\deploy-all.ps1 -FunctionAppName "dev-defender-001" ...
```

**Workbook Configuration**:
```json
{"name": "FunctionAppName", "value": "dev-defender-001"}
```

**Endpoints**:
```
https://dev-defender-001.azurewebsites.net/api/...
```

### Staging Environment

```powershell
.\deploy-all.ps1 -FunctionAppName "stage-defender-001" ...
```

**Workbook Configuration**:
```json
{"name": "FunctionAppName", "value": "stage-defender-001"}
```

**Endpoints**:
```
https://stage-defender-001.azurewebsites.net/api/...
```

### Production Environment

```powershell
.\deploy-all.ps1 -FunctionAppName "prod-defender-001" ...
```

**Workbook Configuration**:
```json
{"name": "FunctionAppName", "value": "prod-defender-001"}
```

**Endpoints**:
```
https://prod-defender-001.azurewebsites.net/api/...
```

**Result**: ✅ Each environment has its own function app name, properly configured!

---

## Example 5: Different Organizations

### Organization A: Financial Services

```bash
az deployment group create ... --parameters functionAppName=finserv-mde-auto
```

**Result**:
- Workbook parameter: `finserv-mde-auto`
- Endpoints: `https://finserv-mde-auto.azurewebsites.net/api/...`

### Organization B: Healthcare

```bash
az deployment group create ... --parameters functionAppName=healthcare-defender
```

**Result**:
- Workbook parameter: `healthcare-defender`
- Endpoints: `https://healthcare-defender.azurewebsites.net/api/...`

### Organization C: Manufacturing

```bash
az deployment group create ... --parameters functionAppName=mfg-security-ops
```

**Result**:
- Workbook parameter: `mfg-security-ops`
- Endpoints: `https://mfg-security-ops.azurewebsites.net/api/...`

**Result**: ✅ Each organization uses their own naming convention!

---

## What Makes This Universal?

### 1. No Hardcoded Values

**BAD (What we DON'T have):**
```json
{
  "name": "FunctionAppName",
  "value": "defc2"  // ❌ Hardcoded - only works with "defc2"
}
```

**GOOD (What we HAVE):**
```json
{
  "name": "FunctionAppName",
  "value": "__FUNCTION_APP_NAME_PLACEHOLDER__"  // ✅ Placeholder - replaced at deployment
}
```

### 2. Parameter-Based URLs

**BAD (What we DON'T have):**
```json
{
  "path": "https://defc2.azurewebsites.net/api/..."  // ❌ Hardcoded URL
}
```

**GOOD (What we HAVE):**
```json
{
  "path": "https://{FunctionAppName}.azurewebsites.net/api/..."  // ✅ Parameter-based
}
```

### 3. Deployment-Time Replacement

**User Input** → **Placeholder Replacement** → **Configured Workbook**

```
mycompany-defender → __FUNCTION_APP_NAME_PLACEHOLDER__ → mycompany-defender
                     (in workbook file)                   (deployed workbook)
```

### 4. Multiple Deployment Methods

All methods support dynamic function app names:
- ✅ Azure Portal ("Deploy to Azure" button)
- ✅ PowerShell scripts
- ✅ Azure CLI with ARM template
- ✅ Azure DevOps pipelines
- ✅ GitHub Actions workflows

---

## Common Patterns

### Pattern 1: Environment Prefixes
```
dev-defender-001
stage-defender-001
prod-defender-001
```

### Pattern 2: Organization Names
```
acme-mde-automation
contoso-defender-ops
fabrikam-security
```

### Pattern 3: Purpose Indicators
```
mde-automation-prod
defender-incident-mgmt
security-orchestration
```

### Pattern 4: Regional Deployments
```
defender-useast-prod
defender-euwest-prod
defender-apsouth-prod
```

**All patterns work!** ✅

---

## Verification After Deployment

### Step 1: Open Workbook in Azure Portal

```
Azure Portal → Monitor → Workbooks → DefenderC2 Command & Control Console
```

### Step 2: Check Parameter Value

```
Edit → Parameters (top bar) → Function App Name
```

**Should show your function app name**, e.g., `mycompany-defender`

### Step 3: Test an Endpoint

Click "Get Devices" button in the workbook.

**Behind the scenes:**
```
1. Workbook reads FunctionAppName parameter: "mycompany-defender"
2. Constructs URL: https://mycompany-defender.azurewebsites.net/api/DefenderC2Dispatcher
3. Sends POST request with authentication
4. Displays results
```

### Step 4: Verify All Endpoints

Run verification script:
```bash
cd deployment
./verify-function-app-name-replacement.sh
```

**Output:**
```
✓ Found 27 usages of {FunctionAppName} parameter
✓ No hardcoded 'defc2' values found
✓ ARM template has correct replacement mechanism
✓ ALL CHECKS PASSED!
```

---

## Troubleshooting (Just in Case)

### Issue: Workbook shows placeholder value

**Symptom**: Workbook parameter shows `__FUNCTION_APP_NAME_PLACEHOLDER__`

**Cause**: Placeholder was not replaced during deployment

**Solution**: Redeploy workbook with PowerShell script:
```powershell
.\deployment\deploy-workbook.ps1 `
    -ResourceGroupName "your-rg" `
    -WorkspaceResourceId "/subscriptions/.../workspaces/..." `
    -FunctionAppName "your-function-app" `
    -DeployMainWorkbook
```

### Issue: Endpoints return 404

**Symptom**: API calls fail with 404 Not Found

**Possible Causes**:
1. Function app name in workbook doesn't match actual function app
2. Function code not deployed to function app
3. Function app not running

**Solution**: Verify function app name matches:
```powershell
# Check deployed function apps
az functionapp list --query "[].name" -o table

# Check workbook parameter
# (View in Azure Portal → Workbooks → Edit → Parameters)
```

---

## Summary

The DefenderC2 workbook deployment system supports **ANY** function app name through:

1. ✅ **Placeholder System**: `__FUNCTION_APP_NAME_PLACEHOLDER__` in source files
2. ✅ **ARM Template Replacement**: Automatic during Portal/CLI deployment
3. ✅ **PowerShell Script Replacement**: Automatic during script deployment
4. ✅ **Parameter-Based URLs**: All endpoints use `{FunctionAppName}`
5. ✅ **Universal Design**: No naming restrictions or conventions required

**Result**: Users can deploy with ANY function app name and the workbook works immediately!

---

**Last Updated**: 2024-10-08  
**Status**: ✅ PRODUCTION READY  
**Tested With**: 5+ different function app names  
**Deployment Methods**: ARM Template, PowerShell, Azure CLI
