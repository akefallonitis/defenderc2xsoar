# Before/After Comparison: ARM Actions Fix

## Visual Comparison

### Issue #1: Full URLs vs Relative Paths

#### ❌ BEFORE (Incorrect)
```json
{
  "armActionContext": {
    "path": "https://management.azure.com/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01"
  }
}
```

**Problems:**
- Uses full URL with `https://management.azure.com`
- Can cause endpoint resolution issues
- Not following Azure Workbook standards

#### ✅ AFTER (Correct)
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations"
  }
}
```

**Benefits:**
- Uses relative path starting with `/subscriptions/`
- Azure automatically prepends management endpoint
- Follows Azure Workbook best practices

---

### Issue #2: Duplicate api-version Specification

#### ❌ BEFORE (Incorrect)
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/.../invocations?api-version=2022-03-01",
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ]
  }
}
```

**Problems:**
- api-version appears in BOTH path and params
- Redundant and can cause conflicts
- Violates Azure API standards

#### ✅ AFTER (Correct)
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/.../invocations",
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ]
  }
}
```

**Benefits:**
- api-version only in params array
- Clean URL path
- Proper Azure API format

---

## Complete Example: Isolate Device Action

### ❌ BEFORE (Incorrect)
```json
{
  "id": "isolate-action",
  "cellValue": "unused",
  "linkTarget": "ArmAction",
  "linkLabel": "🚨 Isolate Devices",
  "style": "primary",
  "linkIsContextBlade": true,
  "armActionContext": {
    "path": "https://management.azure.com/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"isolationType\":\"{IsolationType}\",\"comment\":\"Isolated via Workbook\"}",
    "httpMethod": "POST",
    "title": "Isolate Devices",
    "description": "Initiating device isolation...",
    "actionName": "Isolate",
    "runLabel": "Isolate Devices"
  }
}
```

### ✅ AFTER (Correct)
```json
{
  "id": "isolate-action",
  "cellValue": "unused",
  "linkTarget": "ArmAction",
  "linkLabel": "🚨 Isolate Devices",
  "style": "primary",
  "linkIsContextBlade": true,
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"isolationType\":\"{IsolationType}\",\"comment\":\"Isolated via Workbook\"}",
    "httpMethod": "POST",
    "title": "Isolate Devices",
    "description": "Initiating device isolation...",
    "actionName": "Isolate",
    "runLabel": "Isolate Devices"
  }
}
```

### Changes Made:
1. ✅ Removed `https://management.azure.com` prefix
2. ✅ Removed `?api-version=2022-03-01` from path
3. ✅ Kept api-version only in params array
4. ✅ Maintained all parameter substitutions: `{Subscription}`, `{ResourceGroup}`, `{FunctionAppName}`, `{TenantId}`, `{IsolateDeviceIds}`, `{IsolationType}`

---

## All Fixed Actions

### DefenderC2-Workbook.json (15 actions)

1. **Device Management**
   - ✅ Isolate Device
   - ✅ Unisolate Device
   - ✅ Restrict App Execution
   - ✅ Run Antivirus Scan

2. **Threat Intelligence**
   - ✅ Add File Indicators
   - ✅ Update File Indicators
   - ✅ Delete File Indicators

3. **Hunt Management**
   - ✅ Run Advanced Hunt

4. **Incident Management**
   - ✅ Create Incident
   - ✅ Update Incident

5. **Detection Management**
   - ✅ Create Custom Detection
   - ✅ Update Custom Detection
   - ✅ Delete Custom Detection

6. **Orchestration**
   - ✅ Execute Orchestration
   - ✅ Execute Console Command

### FileOperations.workbook (4 actions)

1. **File Operations**
   - ✅ Upload File
   - ✅ Download File
   - ✅ Delete File
   - ✅ List Files

---

## Parameter Substitution (Already Working Correctly)

All ARM actions properly use parameter substitution:

```json
{
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
  "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}"
}
```

### Parameters Auto-populated From:
- `{Subscription}` ← Auto-discovered from FunctionApp resource
- `{ResourceGroup}` ← Auto-discovered from FunctionApp resource
- `{FunctionAppName}` ← Auto-discovered from FunctionApp resource
- `{TenantId}` ← Auto-discovered from FunctionApp resource
- `{IsolateDeviceIds}` ← Selected from DeviceList parameter (CustomEndpoint query)

---

## Testing the Fix

### Before the Fix
When clicking an ARM action button:
1. ❌ Might get endpoint resolution errors
2. ❌ Might get api-version conflicts
3. ❌ Logs show full URL being sent

### After the Fix
When clicking an ARM action button:
1. ✅ Clean endpoint resolution
2. ✅ No api-version conflicts
3. ✅ Logs show proper relative path
4. ✅ Consistent with Azure Workbook standards

### How to Verify
1. Open browser developer console (F12)
2. Go to Network tab
3. Click an ARM action button (e.g., "Isolate Devices")
4. Check the request URL in network logs
5. Should see proper Azure management endpoint with relative path

---

## Migration Guide

If you're maintaining similar workbooks, follow these steps:

### Step 1: Find ARM Actions
Search for `armActionContext` in your workbook JSON files.

### Step 2: Check Path Format
Look for paths starting with `https://management.azure.com`.

### Step 3: Convert to Relative Path
Remove the `https://management.azure.com` prefix:
```bash
# Before
https://management.azure.com/subscriptions/{Subscription}/...

# After
/subscriptions/{Subscription}/...
```

### Step 4: Remove URL api-version
Remove `?api-version=X` from the path (keep in params array).

### Step 5: Verify
Run the verification script:
```bash
python3 scripts/verify_workbook_config.py
```

---

## Reference Documentation

- **Azure Workbooks**: [Official Docs](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- **ARM API**: [Azure Resource Manager](https://learn.microsoft.com/azure/azure-resource-manager/management/overview)
- **Best Practices**: See `AZURE_WORKBOOK_BEST_PRACTICES.md`
- **Verification**: See `scripts/verify_workbook_config.py`

---

**Status**: ✅ All 19 ARM actions fixed and verified  
**Date**: October 12, 2025  
**Impact**: Improved reliability and Azure standards compliance
