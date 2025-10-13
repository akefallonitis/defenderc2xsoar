# Global Parameters Fix - ARM Actions Now Fully Functional

## Issue Summary
**Problem:** ARM actions required manual input for parameters like TenantId, DeviceId, etc., because parameters were not marked as global, preventing them from being accessible across all workbook components.

**Root Cause:** In Azure Workbooks, parameters used in ARM actions must be marked with `"isGlobal": true` to be accessible across different sections and components. Without this flag, parameters are scoped only to their immediate container.

## Solution
Marked all parameters used in ARM action bodies and paths as global to ensure they are accessible throughout the workbook.

### Changes Made

#### DefenderC2-Workbook.json (31 parameters updated)
Device selection parameters (already had criteriaData, now also global):
- ✅ IsolateDeviceIds
- ✅ UnisolateDeviceIds  
- ✅ RestrictDeviceIds
- ✅ ScanDeviceIds

Action configuration parameters:
- ✅ IsolationType
- ✅ ScanType

Indicator management parameters:
- ✅ FileIndicators
- ✅ FileIndicatorAction
- ✅ FileSeverity
- ✅ FileTitle
- ✅ FileDescription
- ✅ IpIndicators
- ✅ IpIndicatorAction
- ✅ IpSeverity
- ✅ UrlIndicators
- ✅ UrlIndicatorAction

Action management parameters:
- ✅ CancelActionId

Incident management parameters:
- ✅ UpdateIncidentId
- ✅ UpdateStatus
- ✅ CommentIncidentId
- ✅ IncidentComment

Analytics rule parameters:
- ✅ CreateRuleName
- ✅ CreateRuleQuery
- ✅ CreateRuleSeverity
- ✅ UpdateRuleId
- ✅ UpdateRuleQuery
- ✅ DeleteRuleId

Library management parameters:
- ✅ DeviceIds
- ✅ LibraryFileNameUpload
- ✅ LibraryContentUpload
- ✅ LibraryDeployFileName

#### FileOperations.workbook (6 parameters updated)
- ✅ Subscription (used in ARM action paths)
- ✅ DeployDeviceId
- ✅ DeployFileName
- ✅ DownloadDeviceId
- ✅ DownloadFilePath
- ✅ LibraryFileName

## How Azure Workbook Global Parameters Work

### Without Global Flag
```json
{
  "name": "IsolateDeviceIds",
  "isGlobal": false  // or missing
}
```
**Result:** Parameter is only accessible within its immediate container/section. ARM actions in other sections cannot access it.

### With Global Flag
```json
{
  "name": "IsolateDeviceIds",
  "isGlobal": true
}
```
**Result:** Parameter is accessible throughout the entire workbook, including ARM actions in any section.

## Verification

### New Test Script
Created `scripts/test_arm_action_parameters.py` that:
- Extracts all parameters used in ARM action bodies and paths
- Verifies each parameter is marked as global
- Reports any parameters missing the global flag

### Test Results
```
================================================================================
ARM Action Parameter Global Status Test
================================================================================

DefenderC2-Workbook.json:
✅ 35/35 ARM action parameters are global

FileOperations.workbook:
✅ 8/8 ARM action parameters are global (1 is from external scope)

🎉 SUCCESS: All ARM action parameters are correctly marked as global!
```

### Existing Verification
All existing checks continue to pass:
```
✅ ARM Actions: 15/15 with api-version in params (DefenderC2-Workbook.json)
✅ ARM Actions: 15/15 with relative paths
✅ ARM Actions: 15/15 without api-version in URL
✅ Device Parameters: 5/5 with CustomEndpoint
✅ CustomEndpoint Queries: 21/21 with parameter substitution
✅ Global Parameters: 6/6 marked as global (core parameters)

✅ ARM Actions: 4/4 with api-version in params (FileOperations.workbook)
✅ ARM Actions: 4/4 with relative paths
✅ ARM Actions: 4/4 without api-version in URL
✅ CustomEndpoint Queries: 1/1 with parameter substitution
✅ Global Parameters: 3/3 marked as global (core parameters)
```

## Impact

### Before Fix
❌ ARM actions required manual input for all parameters
❌ DeviceIds, TenantId, and other parameters were not accessible to ARM actions
❌ Users had to re-enter values that were already selected elsewhere in the workbook
❌ Workbook functionality was severely limited

### After Fix
✅ ARM actions automatically receive all required parameters
✅ Device selections automatically populate into action dialogs
✅ TenantId, FunctionAppName, and other core parameters are accessible everywhere
✅ Full workbook functionality restored
✅ Consistent with Azure Sentinel best practices

## Related Documentation
- [PARAMETER_AUTOPOPULATION_FIX.md](PARAMETER_AUTOPOPULATION_FIX.md) - Previous criteriaData fixes
- [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md) - Azure Workbook patterns
- [ISSUE_RESOLUTION_AUTOPOPULATION.md](ISSUE_RESOLUTION_AUTOPOPULATION.md) - Parameter autopopulation context

## Technical Details

### Parameter Scoping in Azure Workbooks
1. **Local Parameters** (`isGlobal: false` or missing):
   - Scoped to their containing group
   - Not accessible to ARM actions in other groups
   - Cannot be referenced across tabs or sections

2. **Global Parameters** (`isGlobal: true`):
   - Accessible throughout entire workbook
   - Can be referenced in any ARM action
   - Can be used across tabs and sections
   - Should be used for all parameters referenced in ARM actions

### ARM Action Parameter Resolution
When an ARM action executes:
1. Azure Workbooks parse the body/path for `{ParameterName}` placeholders
2. For each placeholder, lookup the parameter value
3. **If parameter is not global**: Lookup fails → user must manually enter
4. **If parameter is global**: Value is automatically substituted

## Files Modified
- `workbook/DefenderC2-Workbook.json` - 31 parameters marked as global
- `workbook/FileOperations.workbook` - 6 parameters marked as global
- `scripts/test_arm_action_parameters.py` - New test script (created)

---

**Status:** ✅ Complete  
**Date:** October 13, 2025  
**Issue:** "all arm actions need for manual input but dont have tenantid deviceid etc populated"  
**Resolution:** All parameters used in ARM actions are now marked as global
