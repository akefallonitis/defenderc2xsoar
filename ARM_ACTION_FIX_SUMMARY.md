# ARM Action Path Fix - Azure Workbook Best Practices

## Problem Statement
The DefenderC2 workbooks were not following Azure Workbook best practices for ARM actions as demonstrated in the official Azure Sentinel Advanced Workbook Concepts reference.

## Issues Identified

### 1. Full URLs Instead of Relative Paths
**Issue**: ARM actions were using full URLs like:
```
https://management.azure.com/subscriptions/{Subscription}/...
```

**Should be**: Relative paths starting with:
```
/subscriptions/{Subscription}/...
```

**Why**: Azure Workbooks automatically prepend the management API endpoint. Using full URLs can cause issues with endpoint resolution and authentication.

### 2. Duplicate api-version Specification
**Issue**: api-version was specified in BOTH locations:
- In the path: `...?api-version=2022-03-01`
- In the params array: `{"key": "api-version", "value": "2022-03-01"}`

**Should be**: Only in the params array.

**Why**: Having it in both places is redundant and can cause conflicts. The params array is the proper location per Azure standards.

## Changes Made

### DefenderC2-Workbook.json
Fixed 15 ARM actions:
- ✅ 4 actions for device isolation/unisolation
- ✅ 3 actions for threat intelligence indicators
- ✅ 1 action for app execution restriction
- ✅ 2 actions for incident management
- ✅ 3 actions for custom detection rules
- ✅ 2 actions for orchestration

### FileOperations.workbook
Fixed 4 ARM actions:
- ✅ 4 file operation actions via DefenderC2Orchestrator

## Before vs After

### Before (Incorrect)
```json
{
  "armActionContext": {
    "path": "https://management.azure.com/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
    "httpMethod": "POST"
  }
}
```

### After (Correct)
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
    "httpMethod": "POST"
  }
}
```

## Verification

### Enhanced Verification Script
Updated `scripts/verify_workbook_config.py` to check:
1. ✅ All ARM actions have api-version in params array
2. ✅ All ARM actions use relative paths (start with `/subscriptions/`)
3. ✅ All ARM actions do NOT have api-version in URL
4. ✅ All CustomEndpoint queries use parameter substitution
5. ✅ All device parameters use CustomEndpoint format

### Verification Results
```
================================================================================
DefenderC2 Workbook Configuration Verification
================================================================================

DefenderC2-Workbook.json:
✅ ARM Actions: 15/15 with api-version in params
✅ ARM Actions: 15/15 with relative paths
✅ ARM Actions: 15/15 without api-version in URL
✅ Device Parameters: 5/5 with CustomEndpoint
✅ CustomEndpoint Queries: 21/21 with parameter substitution

FileOperations.workbook:
✅ ARM Actions: 4/4 with api-version in params
✅ ARM Actions: 4/4 with relative paths
✅ ARM Actions: 4/4 without api-version in URL
✅ CustomEndpoint Queries: 1/1 with parameter substitution

🎉 SUCCESS: All workbooks are correctly configured!
```

## Parameter Autopopulation Status

### Already Working Correctly
All parameters properly autodiscover and autopopulate:

#### From FunctionApp Resource
- ✅ **Subscription** - Auto-discovered from FunctionApp resource
- ✅ **ResourceGroup** - Auto-discovered from FunctionApp resource
- ✅ **FunctionAppName** - Auto-discovered from FunctionApp resource
- ✅ **TenantId** - Auto-discovered from FunctionApp resource

#### Device Lists
- ✅ **DeviceList** - Auto-populated via CustomEndpoint query to DefenderC2Dispatcher
- ✅ **IsolateDeviceIds** - Auto-populated via CustomEndpoint query
- ✅ **UnisolateDeviceIds** - Auto-populated via CustomEndpoint query
- ✅ **RestrictDeviceIds** - Auto-populated via CustomEndpoint query
- ✅ **ScanDeviceIds** - Auto-populated via CustomEndpoint query

### CustomEndpoint Query Format
All CustomEndpoint queries properly use parameter substitution:
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

### ARM Action Body Format
All ARM action bodies properly include required parameters:
```json
{
  "action": "Isolate Device",
  "tenantId": "{TenantId}",
  "deviceIds": "{IsolateDeviceIds}",
  "isolationType": "{IsolationType}",
  "comment": "Isolated via Workbook"
}
```

## Reference
Based on Azure Sentinel's official Advanced Workbook Concepts:
- File: `Azure/Azure-Sentinel/Workbooks/AdvancedWorkbookConcepts.json`
- Demonstrates proper ARM action format with relative paths
- Shows best practices for parameter substitution
- Illustrates correct api-version placement in params array

## Impact
These changes ensure:
1. ✅ Proper compatibility with Azure Workbook runtime
2. ✅ Correct endpoint resolution
3. ✅ Proper API versioning
4. ✅ Consistent with Azure best practices
5. ✅ Better maintainability and debugging

## Testing Recommendations
When deploying these workbooks:
1. Verify ARM actions trigger correctly
2. Confirm parameter substitution works
3. Check that Function App invocations succeed
4. Validate error messages are meaningful
5. Test auto-refresh functionality

---

**Status**: ✅ Complete  
**Date**: October 12, 2025  
**Files Changed**: 3 (2 workbooks + 1 verification script)  
**ARM Actions Fixed**: 19 total (15 + 4)
