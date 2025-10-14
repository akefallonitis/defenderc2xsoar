# ARM Actions & CustomEndpoints Fresh Fix

## 🎯 Problem Statement

User reported issues with the DefenderC2-Workbook-MINIMAL-FIXED.json workbook:

1. ❌ **ARM actions not using proper management API resource format** - Parameters were in query string instead of POST body
2. ❌ **Device List CustomEndpoint "stacks in loop"** - Redundant criteriaData dependencies causing refresh loops
3. ❌ **Menu values not populating** - CriteriaData issues preventing proper parameter waiting

## 🔍 Root Cause Analysis

### Issue 1: ARM Actions Using Query Parameters Instead of POST Body

**Problem**: ARM actions were using `params` array to send function parameters:
```json
{
  "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
  "params": [
    {"key": "api-version", "value": "2022-03-01"},
    {"key": "action", "value": "Isolate Device"},
    {"key": "tenantId", "value": "{TenantId}"},
    {"key": "deviceIds", "value": "{DeviceList}"}
  ],
  "body": null
}
```

This creates a request like:
```
POST /invocations?api-version=2022-03-01&action=Isolate+Device&tenantId=xxx&deviceIds=yyy
```

**Why It's Wrong**: Azure Function App invocations through the ARM API expect parameters in the POST body as JSON, not as query parameters. Only `api-version` should be in the query string.

### Issue 2: Redundant CriteriaData Dependencies

**Problem**: CustomEndpoint queries included redundant dependencies:
```json
"criteriaData": [
  {"value": "{FunctionApp}"},       // ❌ Redundant
  {"value": "{FunctionAppName}"},   // ✅ Actually used
  {"value": "{TenantId}"}           // ✅ Actually used
]
```

**Why It's Wrong**: 
- `FunctionAppName` already depends on `FunctionApp` via its own criteriaData
- Including both creates a circular/redundant dependency chain
- This can cause refresh loops where the query keeps re-running

The CustomEndpoint query only uses `{FunctionAppName}` and `{TenantId}`:
```
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher
URLParams: [
  {"key": "action", "value": "Get Devices"},
  {"key": "tenantId", "value": "{TenantId}"}
]
```

## ✅ Solution Applied

### Fix 1: ARM Actions Now Use POST Body

**Changed all 3 ARM actions to:**
```json
{
  "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
  "headers": [
    {"name": "Content-Type", "value": "application/json"}
  ],
  "params": [
    {"key": "api-version", "value": "2022-03-01"}
  ],
  "body": "{\"action\": \"Isolate Device\", \"tenantId\": \"{TenantId}\", \"deviceIds\": \"{DeviceList}\", \"isolationType\": \"Full\", \"comment\": \"Isolated via Workbook\"}"
}
```

**Result**: Request is now:
```
POST /invocations?api-version=2022-03-01
Content-Type: application/json

{
  "action": "Isolate Device",
  "tenantId": "xxx",
  "deviceIds": "yyy",
  "isolationType": "Full",
  "comment": "Isolated via Workbook"
}
```

### Fix 2: Simplified CustomEndpoint CriteriaData

**Removed redundant `{FunctionApp}` dependency:**
```json
"criteriaData": [
  {"criterionType": "param", "value": "{FunctionAppName}"},
  {"criterionType": "param", "value": "{TenantId}"}
]
```

**Result**: CustomEndpoints now only depend on parameters they directly use, preventing refresh loops.

## 📊 Changes Made

### File Modified
- `workbook/DefenderC2-Workbook-MINIMAL-FIXED.json`

### Specific Changes

#### ARM Actions (3 actions fixed)
1. **Isolate Devices**
   - ✅ Moved 5 params to POST body
   - ✅ Added Content-Type: application/json header
   - ✅ Kept api-version in query string

2. **Unisolate Devices**
   - ✅ Moved 4 params to POST body
   - ✅ Added Content-Type: application/json header
   - ✅ Kept api-version in query string

3. **Run Antivirus Scan**
   - ✅ Moved 5 params to POST body
   - ✅ Added Content-Type: application/json header
   - ✅ Kept api-version in query string

#### CustomEndpoints (2 endpoints fixed)
1. **DeviceList Parameter**
   - ✅ Removed `{FunctionApp}` from criteriaData
   - ✅ Now depends only on `{FunctionAppName}` and `{TenantId}`

2. **Device List - Live Data Grid**
   - ✅ Removed `{FunctionApp}` from criteriaData
   - ✅ Now depends only on `{FunctionAppName}` and `{TenantId}`

### Statistics
- **ARM actions modified**: 3
- **Parameters moved to body**: 14 (5 + 4 + 5)
- **Headers added**: 3 (Content-Type for each action)
- **CustomEndpoints fixed**: 2
- **Redundant dependencies removed**: 2

## 📚 Technical Background

### Azure Function Invocation API Format

When invoking Azure Functions through the ARM API, the correct format is:

```
POST /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{name}/functions/{func}/invocations?api-version={version}
Content-Type: application/json

{
  "param1": "value1",
  "param2": "value2"
}
```

**NOT**:
```
POST /invocations?api-version={version}&param1=value1&param2=value2
```

### CriteriaData Best Practices

CriteriaData should **only** include parameters that are:
1. **Directly referenced** in the query (URL, urlParams, body)
2. **Not derivable** from other included parameters

**Example**:
```
Parameter Flow:
  FunctionApp (resource picker)
    ↓ (has criteriaData)
  FunctionAppName (text, derived from FunctionApp)
    ↓ (used in query)
  CustomEndpoint Query
```

The CustomEndpoint should depend on `{FunctionAppName}`, NOT both `{FunctionApp}` and `{FunctionAppName}`.

## ✅ Verification

### Parameter Flow (After Fix)

```
1. User selects FunctionApp (Resource Picker)
   ↓
2. Auto-populates:
   • Subscription (depends on FunctionApp)
   • ResourceGroup (depends on FunctionApp)
   • FunctionAppName (depends on FunctionApp)
   
3. User selects TenantId (Dropdown)

4. Auto-populates:
   • DeviceList (depends on FunctionAppName + TenantId)
   
5. Device List grid displays (depends on FunctionAppName + TenantId)

6. ARM actions available (use FunctionApp path + POST body with TenantId + DeviceList)
```

### Expected Behavior

1. **No Refresh Loops**: CustomEndpoints run once when dependencies change, not continuously
2. **ARM Actions Work**: Function receives parameters as JSON in POST body
3. **Parameters Populate**: Clear dependency chain without redundancy

## 🚀 Deployment

The workbook is ready to deploy. After deployment:

1. **Select Function App** - Should auto-populate Subscription, ResourceGroup, FunctionAppName
2. **Select Tenant ID** - Should auto-populate DeviceList dropdown
3. **Device grid displays** - Should load once and display devices
4. **Click ARM action button** - Should send parameters in POST body to function

## 🔗 References

- [Azure Functions HTTP trigger](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger)
- [Azure Workbooks ARM Actions](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-link-actions)
- [Azure Workbooks Criteria Parameters](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-criteria)

---

**Date**: October 14, 2025  
**Issue**: ARM actions and CustomEndpoints not working correctly  
**Resolution**: Fixed ARM actions to use POST body, simplified CustomEndpoint criteriaData  
**Impact**: All 3 ARM actions and 2 CustomEndpoints fixed
