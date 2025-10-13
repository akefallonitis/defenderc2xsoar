# DefenderC2 Workbook Fixes Summary

## ⚠️ OUTDATED DOCUMENTATION ⚠️

**This document describes an intermediate implementation that was superseded by Issue #57.**

**For current implementation, see:** `ISSUE_57_COMPLETE_FIX.md`

**Key Changes Since This Document:**
- All ARMEndpoint queries converted to CustomEndpoint (queryType: 10)
- Zero ARMEndpoint queries remain in workbooks
- ARM Actions still use the fixes described here (relative paths, api-version in params)

---

## Historical Overview
This document originally described fixes for DeviceId autopopulation and ARMEndpoint configuration, but those ARMEndpoint queries no longer exist.

## Issues Fixed

### 1. ✅ DeviceId Autopopulation
**Issue:** DeviceId parameter was showing `<query failed>` error in UI.

**Status:** ✅ **ALREADY WORKING** - No changes needed

**Verification:**
- DeviceList parameter correctly uses `CustomEndpoint/1.0`
- Query method: POST to `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`
- Body: `{"action": "Get Devices", "tenantId": "{TenantId}"}`
- JSONPath parsing: `$.devices[*]` with columns: `id` (value), `computerDnsName` (label)
- All 5 device parameters (DeviceList, IsolateDeviceIds, UnisolateDeviceIds, RestrictDeviceIds, ScanDeviceIds) are configured correctly

### 2. ❌ ARMEndpoint Queries - SUPERSEDED
**Original Issue:** ARMEndpoint queries were missing the required `api-version` URL parameter.

**Intermediate Solution:** Added `urlParams` array with `api-version=2022-03-01`.

**Final Solution (Issue #57):** Converted all ARMEndpoint queries to CustomEndpoint queries.

**Why Changed:** ARMEndpoint is designed for Azure Resource Manager APIs. Custom Function Apps should use CustomEndpoint (queryType: 10) instead.

**Current Implementation:**
```json
{
  "queryType": 10,
  "query": "{
    \"version\": \"CustomEndpoint/1.0\",
    \"method\": \"POST\",
    \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",
    \"body\": \"{\\\"action\\\": \\\"Get Devices\\\", \\\"tenantId\\\": \\\"{TenantId}\\\"}\",
    \"transformers\": [...]
  }"
}
```

**Current State:**
- `workbook/DefenderC2-Workbook.json`: 21 CustomEndpoint queries (0 ARMEndpoint)
- `workbook/FileOperations.workbook`: 1 CustomEndpoint query (0 ARMEndpoint)

**Queries Converted to CustomEndpoint:**
All queries now use CustomEndpoint (queryType: 10) with proper parameter substitution for {FunctionAppName} and {TenantId}. This includes queries across all workbook tabs:
- Device Actions
- Threat Intel Manager
- Action Manager
- Incident Manager
- Hunt Manager
- Custom Detection Manager
- Interactive Console
- File Operations

### 3. ✅ ARM Actions - Still Accurate
**Issue:** ARM Actions had multiple problems:
- Using full URLs instead of relative paths
- api-version in both URL and params (duplicate)
- Missing proper Azure Resource Manager API structure

**Solution:** Fixed all ARM Actions to use Azure best practices (see `ARM_ACTION_FIX_SUMMARY.md` for details).

**Current Implementation:**
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "httpMethod": "POST",
    "headers": [...],
    "body": "...",
    "params": [
      {"key": "api-version", "value": "2022-03-01"}
    ]
  }
}
```

**Key Points:**
- Relative path starting with `/subscriptions/`
- api-version only in params array (not in URL)
- Proper Azure Resource Manager API structure

**Actions Fixed:**
1. 🚨 Isolate Devices
2. 🔓 Unisolate Devices
3. 🛡️ Restrict App Execution
4. 🔍 Run Antivirus Scan
5. 📄 Add File Indicators
6. 🌐 Add IP Indicators
7. 🔗 Add URL/Domain Indicators
8. 🛑 Cancel Action
9. ✏️ Update Incident
10. 💬 Add Comment
11. ➕ Create Detection Rule
12. ✏️ Update Detection Rule
13. ❌ Delete Detection Rule
14. 📤 Deploy to Device (FileOperations)
15. 📥 Download from Library (FileOperations)
16. 🗑️ Delete from Library (FileOperations)
17. 📥 Download File from Device (FileOperations)

### 4. ✅ Custom Endpoint Configuration
**Status:** ✅ **ALREADY WORKING** - No changes needed

**Verification:**
- All device parameters use `CustomEndpoint/1.0` with:
  - POST method
  - Correct Function App URL with parameter substitution
  - Proper headers: `Content-Type: application/json`
  - JSONPath transformers for response parsing
  - Parameter substitution for `{FunctionAppName}` and `{TenantId}`

## Current Validation Results

### Latest Validation Report (Post Issue #57)
```
================================================================================
DEFENDERC2 WORKBOOK VALIDATION REPORT
================================================================================

📋 Device Parameters
--------------------------------------------------------------------------------
  ✅ DeviceList: CustomEndpoint/1.0
  ✅ IsolateDeviceIds: CustomEndpoint/1.0
  ✅ UnisolateDeviceIds: CustomEndpoint/1.0
  ✅ RestrictDeviceIds: CustomEndpoint/1.0
  ✅ ScanDeviceIds: CustomEndpoint/1.0
  ✅ PASS: All 5 device parameters use CustomEndpoint/1.0

⚙️  CustomEndpoint Queries
--------------------------------------------------------------------------------
  ✅ PASS: 21 CustomEndpoint queries with parameter substitution
  ✅ PASS: 0 ARMEndpoint queries (correctly converted)

🔗 ARM Actions
--------------------------------------------------------------------------------
  ✅ PASS: 15 ARM Actions with api-version in params
  ✅ PASS: 15 ARM Actions with relative paths
  ✅ PASS: 15 ARM Actions without api-version in URL

📊 Global Parameters
--------------------------------------------------------------------------------
  ✅ PASS: 6/6 parameters marked as global

================================================================================
OVERALL SUMMARY
--------------------------------------------------------------------------------
  ✅ Device Parameters: 5/5 using CustomEndpoint
  ✅ CustomEndpoint Queries: 21/21 with parameter substitution
  ✅ ARM Actions: 15/15 properly configured
  ✅ Global Parameters: 6/6 marked correctly

  ✅✅✅ ALL REQUIREMENTS MET ✅✅✅
================================================================================
```

## Files Current State

1. **workbook/DefenderC2-Workbook.json**
   - 21 CustomEndpoint queries (0 ARMEndpoint)
   - 15 ARM Actions with relative paths and api-version
   - 5 device parameters with CustomEndpoint
   - 6 global parameters

2. **workbook/FileOperations.workbook**
   - 1 CustomEndpoint query (0 ARMEndpoint)
   - 4 ARM Actions with relative paths and api-version
   - 3 global parameters

## Technical Details

### ARMEndpoint Query Fix
For queries with standard JSON:
- Parsed JSON object
- Added `urlParams` array if not present
- Appended `{"name": "api-version", "value": "2022-03-01"}`

For queries with unquoted placeholders (e.g., `{RefreshInterval}`):
- Used regex to find insertion point after `"path":"..."`
- Manually inserted `"urlParams":[{"name":"api-version","value":"2022-03-01"}],`

### ARM Action Fix
- Added or updated `params` array in `armActionContext`
- Appended `{"key": "api-version", "value": "2022-03-01"}`

### API Version Value
Used `2022-03-01` as the api-version value, which is a stable Azure Management API version that supports:
- Function App invocation endpoints
- Azure Resource Manager operations
- Custom endpoint queries

## Testing Recommendations

1. **Device Parameter Testing:**
   - Open workbook in Azure Portal
   - Verify "Available Devices" dropdown populates with device list
   - Verify device names display correctly (not just IDs)
   - Test multi-select functionality

2. **Query Testing:**
   - Navigate to each tab (Device Manager, Threat Intel, Action Manager, etc.)
   - Verify tables load without "api-version" errors
   - Check auto-refresh functionality (30s intervals where configured)

3. **Action Testing:**
   - Test device isolation/unisolation actions
   - Test indicator addition (TI Manager)
   - Test incident updates
   - Verify no "api-version URL parameter" errors

## Known Limitations

1. **Function App Authentication:**
   - Current implementation assumes anonymous Function App access
   - If Function App requires authentication, add `?code={FunctionKey}` to URLs
   - FunctionKey parameter is already available but optional

2. **Error Handling:**
   - Workbook displays generic error messages for failed queries
   - Check Function App logs for detailed error information

## References

- Issue: "Fix issues: DeviceId autopopulation and ARM Action/Custom Endpoint problems after PR merge"
- Documentation: 
  - `deployment/CUSTOMENDPOINT_GUIDE.md`
  - `deployment/WORKBOOK_SAMPLES.md`
  - `deployment/DEVICE_PARAMETER_AUTOPOPULATION.md`
- Azure Workbooks documentation: https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview

---

**Date:** 2025-10-11  
**Status:** ✅ Complete - All requirements met and validated
