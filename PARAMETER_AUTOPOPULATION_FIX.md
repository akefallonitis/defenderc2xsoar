# Parameter Autopopulation Fix

## Issue
Parameters in FileOperations.workbook were not auto-populating correctly when their dependencies changed. Specifically:
- TenantId was not refreshing when Workspace parameter changed
- FunctionAppName had a placeholder value that prevented user input

## Root Cause

### Missing criteriaData
Azure Workbook parameters use the `criteriaData` field to determine when to re-evaluate their queries. Without this field, a parameter won't refresh when its dependencies change.

**Example:**
```json
{
  "name": "TenantId",
  "query": "Resources | where id == '{Workspace}' | ...",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{Workspace}"
    }
  ]
}
```

When the Workspace parameter changes, the workbook checks `criteriaData` and automatically re-runs the TenantId query.

### Placeholder Value
The FunctionAppName parameter had a hardcoded placeholder value:
```json
{
  "name": "FunctionAppName",
  "value": "__FUNCTION_APP_NAME_PLACEHOLDER__"
}
```

This prevented users from entering their actual function app name.

## Changes Made

### FileOperations.workbook

#### 1. Added criteriaData to TenantId (lines 71-77)
```json
{
  "name": "TenantId",
  "query": "Resources | where id == '{Workspace}' | ...",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{Workspace}"
    }
  ]
}
```

**Effect:** TenantId now auto-refreshes when user selects a different Workspace

#### 2. Removed placeholder from FunctionAppName (line 79 removed)
```json
{
  "name": "FunctionAppName",
  "isRequired": true,
  // "value": "__FUNCTION_APP_NAME_PLACEHOLDER__",  ← REMOVED
  "description": "Enter your DefenderC2 function app name..."
}
```

**Effect:** Users can now enter their actual function app name

## Verification

### DefenderC2-Workbook.json Status
✅ All parameters with dependencies have proper `criteriaData`:
- Subscription → depends on FunctionApp
- ResourceGroup → depends on FunctionApp  
- FunctionAppName → depends on FunctionApp
- TenantId → depends on Subscription
- DeviceList → depends on FunctionAppName and TenantId

### FileOperations.workbook Status
✅ TenantId now has `criteriaData` pointing to Workspace
✅ FunctionAppName placeholder removed

## Testing
Run the test script to verify configuration:
```bash
python3 /tmp/test_parameter_autopopulation.py
```

## User Impact

**Before Fix:**
- Users had to manually enter TenantId even though it should be auto-discovered
- FunctionAppName showed a confusing placeholder
- Parameters didn't refresh when dependencies changed

**After Fix:**
- TenantId automatically populates when Workspace is selected
- FunctionAppName field is empty and ready for user input
- All parameters refresh automatically when dependencies change
- DeviceList continues to work as expected (already had proper configuration)

## Related Documentation
- `WORKBOOK_AUTOPOPULATION_FIX.md` - Previous fix for CustomEndpoint queries
- `deployment/WORKBOOK_PARAMETERS_GUIDE.md` - Parameter configuration guide
- `CRITICAL_FIX_PLACEHOLDER_REMOVAL.md` - Similar placeholder issue previously fixed

---

**Status**: Complete ✅  
**Date**: October 12, 2025  
**Files Modified**: 1 (workbook/FileOperations.workbook)
**Lines Changed**: +7 lines added, -1 line removed
