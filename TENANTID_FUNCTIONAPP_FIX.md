# TenantId Function App Autopopulation Fix

## Problem Statement
"what about customendpoints fix and autopopulate tenantid functionapp url as we did prior to available devices"

## Issue Identified
The TenantId parameter in DefenderC2-Workbook.json was being autodiscovered from the Subscription resource container instead of directly from the Function App resource. This was inconsistent with how the DeviceList parameter works, which properly depends on FunctionAppName and TenantId with criteriaData.

## Solution

### Changed TenantId Query Source
**Before:**
```json
{
  "name": "TenantId",
  "query": "resourcecontainers\n| where type =~ 'microsoft.resources/subscriptions'\n| extend subscriptionGuid = tolower(tostring(subscriptionId))\n| extend tenantGuid = tostring(tenantId)\n| where subscriptionGuid == tolower('{Subscription}')\n| project value = tenantGuid",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{Subscription}"
    }
  ]
}
```

**After:**
```json
{
  "name": "TenantId",
  "query": "Resources\n| where id == '{FunctionApp}'\n| project value = tenantId",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{FunctionApp}"
    }
  ]
}
```

## Why This Fix Is Important

### 1. Correct Tenant ID Source
- Function App resource has the correct Azure AD tenant ID
- Workspace `customerId` ≠ Azure AD tenant ID
- Subscription-level tenant ID requires extra indirection
- Direct Function App query is simpler and more reliable

### 2. Proper Dependency Chain
The parameter dependency chain now works correctly:

```
FunctionApp (user selection)
  ↓
  ├─→ Subscription (autodiscovered)
  ├─→ ResourceGroup (autodiscovered)
  ├─→ FunctionAppName (autodiscovered)
  └─→ TenantId (autodiscovered) ⭐ FIXED
       ↓
       └─→ DeviceList (autodiscovered from API)
```

All autodiscovered parameters now properly depend on FunctionApp with criteriaData, ensuring automatic refresh when the user changes their Function App selection.

### 3. Authentication Consistency
- Ensures authentication works with the tenant where App Registration exists
- TenantId is passed to all CustomEndpoint queries via urlParams
- All 22 CustomEndpoint queries use `{TenantId}` variable

## Verification Results

### Parameter Configuration
✅ **TenantId Query**: `Resources | where id == '{FunctionApp}' | project value = tenantId`  
✅ **CriteriaData**: Depends on `{FunctionApp}`  
✅ **Auto-refresh**: Enabled when FunctionApp changes

### CustomEndpoint Queries Status
✅ **DefenderC2-Workbook.json**: 21 queries properly formatted
- body: null
- headers: []
- Clean URLs (no query strings)
- urlParams with {TenantId}
- URLs with {FunctionAppName}

✅ **FileOperations.workbook**: 1 query properly formatted
- Same format as above
- Note: FileOperations uses Workspace customerId for TenantId (different use case)

### Dependency Chain Verification
```
1. FunctionApp (user selection) ✅
   ↓
2. Subscription → depends on FunctionApp ✅
   ↓
3. ResourceGroup → depends on FunctionApp ✅
   ↓
4. FunctionAppName → depends on FunctionApp ✅
   ↓
5. TenantId → depends on FunctionApp ✅ (FIXED)
   ↓
6. DeviceList → depends on FunctionAppName and TenantId ✅
```

## Files Modified
- `workbook/DefenderC2-Workbook.json` (3 lines changed)

## Impact
- ✅ TenantId now correctly autodiscovers from Function App resource
- ✅ Proper auto-refresh when Function App selection changes
- ✅ Consistent with DeviceList parameter pattern
- ✅ Simpler query (no subscription indirection needed)
- ✅ More reliable tenant ID resolution

## Testing
All verification scripts pass:
```bash
python3 scripts/verify_workbook_config.py
# ✅ All checks passed
```

## Related Documentation
- `WORKBOOK_AUTOPOPULATION_FIX.md` - CustomEndpoint query format fixes
- `PARAMETER_AUTOPOPULATION_FIX.md` - Previous parameter autopopulation fixes
- `ISSUE_57_FINAL_CONFIRMATION.md` - TenantId should come from FunctionApp resource

---

**Status**: ✅ Complete  
**Date**: October 12, 2025  
**Issue**: "customendpoints fix and autopopulate tenantid functionapp url as we did prior to available devices"
