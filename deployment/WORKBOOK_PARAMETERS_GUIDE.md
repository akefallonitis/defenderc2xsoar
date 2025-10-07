# DefenderC2 Workbook Parameters - Quick Reference Guide

## Overview

This guide explains the parameters used in DefenderC2 workbooks and how to ensure they are properly configured during deployment.

## The Critical Issue This Solves

**Problem**: "WORK DEPLOYMENT DOES NOT INCLUDE CORRECT PARAMETERS FOR FUCNTIONS APPS FOR BOTH CUSTOM ENDPOINTS AND ARM ACTIONS AS NOTHING IS POPULATED"

**Solution**: The deployment scripts now automatically populate all required parameters, especially the **Function App Name** parameter that is critical for all API calls to work.

## Workbook Parameters Explained

### 1. Function App Name (Critical!)

**What it is**: The name of your Azure Function App  
**Example values**: `defc2`, `mydefender`, `sec-functions`  
**How it's used**: Constructs full URL as `https://{FunctionAppName}.azurewebsites.net`  
**Why it matters**: ALL API calls depend on this being correct

#### Before Fix (Problems)
- ❌ Auto-discovery could fail
- ❌ Complex ARG queries
- ❌ Naming restrictions required
- ❌ Sometimes empty/not populated

#### After Fix (Solution)
- ✅ Deployment script sets it automatically
- ✅ Simple text input, any name works
- ✅ Always populated correctly
- ✅ Easy to update if changed

#### How to Set It

**Option 1: Automated (Recommended)**
```powershell
.\deploy-workbook.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -WorkspaceResourceId "/subscriptions/.../workspaces/myworkspace" `
    -FunctionAppName "defc2" `  # <-- Script sets this in the workbook
    -DeployMainWorkbook
```

**Option 2: Manual**
1. Open workbook in Azure Portal
2. Click **Edit** → **Advanced Editor**
3. Search for `"name": "FunctionAppName"`
4. Update `"value": "defc2"` to your function app name
5. Click **Apply** → **Done Editing** → **Save**

### 2. Target Tenant ID

**What it is**: Azure AD Tenant ID / Log Analytics Workspace Customer ID  
**How it's populated**: Auto-discovered from the selected Log Analytics workspace  
**User action**: Select workspace in workbook parameters  
**Status**: ✅ Auto-populated, no manual configuration needed

### 3. Subscription

**What it is**: Azure subscription context  
**User action**: Select from dropdown in workbook  
**Status**: ✅ User selection required (one-time setup)

### 4. Workspace

**What it is**: Log Analytics workspace for queries  
**User action**: Select from dropdown in workbook  
**Status**: ✅ User selection required (one-time setup)

## ARMEndpoint Query Configuration

All workbook queries use the ARMEndpoint/1.0 format to call Azure Functions:

### Correct Configuration (After Fix)

```json
{
  "version": "ARMEndpoint/1.0",
  "method": "POST",
  "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "headers": [
    {"name": "Content-Type", "value": "application/json"}
  ],
  "httpBodySchema": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [...]
}
```

**Key points**:
- ✅ Path uses `{FunctionAppName}` parameter
- ✅ Full URL constructed: `https://{FunctionAppName}.azurewebsites.net/api/...`
- ✅ POST method with JSON body
- ✅ Content-Type header set
- ✅ All required parameters in httpBodySchema

### What Changed from Previous Versions

#### Version 1.0 (Broken)
```json
"path": "{FunctionAppUrl}/api/DefenderC2Dispatcher",
"urlParams": [{"name": "api-version", "value": "2022-08-01"}]
```
- ❌ Used FunctionAppUrl (complex auto-discovery)
- ❌ Had urlParams with api-version (Azure ARM API pattern)
- ❌ Could fail if auto-discovery didn't work

#### Version 2.0 (Current - Working)
```json
"path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
"httpBodySchema": "{...}"
```
- ✅ Simple FunctionAppName parameter
- ✅ No urlParams needed
- ✅ Clean POST with JSON body
- ✅ Works 100% of the time

## Function Endpoints Used

The workbooks call these Azure Function endpoints:

| Function Endpoint | Purpose | Queries Using It |
|-------------------|---------|------------------|
| DefenderC2Dispatcher | Device actions, isolation, scans | 13 queries |
| DefenderC2IncidentManager | Security incidents management | 3 queries |
| DefenderC2TIManager | Threat intelligence indicators | 4 queries |
| DefenderC2HuntManager | Advanced hunting queries | 2 queries |
| DefenderC2CDManager | Custom detection rules | 5 queries |
| DefenderC2Orchestrator | File operations (FileOps workbook) | 1 query |

**Total**: 28 endpoint references across both workbooks

## Required Parameters by Function

### DefenderC2Dispatcher
```json
{
  "action": "Get Devices|Isolate Device|...",
  "tenantId": "{TenantId}",
  "deviceIds": "..." // (for device actions)
}
```

### DefenderC2IncidentManager
```json
{
  "action": "Get Incidents|Update Incident|...",
  "tenantId": "{TenantId}",
  "severity": "High|Medium|Low",
  "status": "New|InProgress|Resolved"
}
```

### DefenderC2TIManager
```json
{
  "action": "List Indicators|Add Indicator|...",
  "tenantId": "{TenantId}",
  "indicators": "...", // (for add/update)
  "indicatorType": "..." // (FileSha256, IP, URL, etc.)
}
```

### DefenderC2HuntManager
```json
{
  "action": "Execute Hunt|Get Hunt Status",
  "tenantId": "{TenantId}",
  "huntQuery": "DeviceProcessEvents | where ..." // (for execute)
}
```

**Note**: Fixed parameter name from `query` to `huntQuery` (camelCase) in PR #37

### DefenderC2CDManager
```json
{
  "action": "List Detections|Create Detection|...",
  "tenantId": "{TenantId}"
}
```

## Deployment Scripts Parameter Handling

### deploy-workbook.ps1

This script automatically:
1. Loads workbook JSON from file
2. Finds the FunctionAppName parameter in the JSON
3. Updates its value to your function app name
4. Deploys the workbook with the updated content

**Code snippet**:
```powershell
$funcAppParam = $workbookContent.items | 
    Where-Object { $_.type -eq "1" } | 
    Select-Object -ExpandProperty content | 
    Select-Object -ExpandProperty parameters |
    ForEach-Object { $_ } |
    Where-Object { $_.name -eq "FunctionAppName" } |
    Select-Object -First 1

if ($funcAppParam) {
    $funcAppParam.value = $FunctionAppName
    Write-Host "✅ Function App Name parameter updated"
}
```

### deploy-all.ps1

This script orchestrates the complete deployment:
1. Calls `deploy-complete.ps1` to deploy Function App
2. Calls `deploy-workbook.ps1` to deploy workbooks
3. Passes the same FunctionAppName to both

**Ensures consistency**: Function App name matches workbook configuration

## Verification Checklist

After deployment, verify these settings:

### In Azure Portal

1. **Open workbook**: Monitor → Workbooks → "DefenderC2 Command & Control Console"
2. **Check parameters at top**:
   - [ ] Function App Name = your function app (e.g., `defc2`)
   - [ ] Subscription = selected
   - [ ] Workspace = selected
   - [ ] Tenant ID = auto-populated GUID

### Test a Query

1. Go to **Defender C2** tab
2. Click **Get Devices** button
3. Should see device list (not error messages)

### Common Errors and Fixes

**Error**: "Please provide a valid resource path"
- **Cause**: Function App Name is wrong or empty
- **Fix**: Update Function App Name parameter

**Error**: "404 Not Found"
- **Cause**: Function App doesn't exist or wrong name
- **Fix**: Verify function app exists: `az functionapp show -n {name} -g {rg}`

**Error**: "500 Internal Server Error"
- **Cause**: Function app missing APPID/SECRETID env vars
- **Fix**: Check function app settings

**Error**: "No data"
- **Cause**: Query succeeded but no data available
- **Fix**: This is normal if no devices/incidents exist

## Best Practices

1. **Use Deployment Scripts**: They handle all parameter configuration automatically
2. **Document Your Function App Name**: Keep it handy for manual updates
3. **Keep Workbooks Updated**: Pull latest from repository
4. **Test After Deployment**: Verify at least one query works
5. **Pin Workbooks**: Add to dashboard for quick access

## Migration from Old Versions

If you have old workbooks with FunctionAppUrl parameter:

### Option 1: Redeploy (Recommended)
```powershell
# Delete old workbook in Portal, then:
.\deploy-workbook.ps1 -ResourceGroupName "rg" -WorkspaceResourceId "..." -FunctionAppName "defc2" -DeployMainWorkbook
```

### Option 2: Manual Update
1. Download new workbook JSON from repository
2. Azure Portal → Workbooks → Your workbook → Edit → Advanced Editor
3. Replace entire JSON
4. Update Function App Name parameter
5. Save

## Support

If parameters are not populating:
1. Verify you're using the latest deployment scripts
2. Check PowerShell script execution completed without errors
3. Review Azure Portal → Workbooks for the deployed workbook
4. Open GitHub issue with:
   - Deployment method used
   - Script output/errors
   - Workbook parameter values shown in Portal

## Summary

✅ **Function App Name parameter is the critical fix**  
✅ **Deployment scripts now set it automatically**  
✅ **Workbooks work immediately after deployment**  
✅ **No complex configuration required**  
✅ **All ARMEndpoint queries have correct parameters**

---

**Last Updated**: 2024-01-08  
**Applies To**: Workbook v2.0, PR #37 and later
