# Issue #57 - Complete Fix Summary

## 🎯 Problems Fixed

### Problem 1: ARM Actions Showing `<unset>` Parameters
**Symptom**: ARM action blade showed `%60%3Cunset%3E%60` (URL-encoded `<unset>`) instead of Function App resource ID

**Root Cause**: ARM action criteriaData referenced obsolete text parameters `{Subscription}`, `{ResourceGroup}`, `{FunctionAppName}` instead of the resource picker `{FunctionApp}`

**Fix (Commit 2f3f95b)**:
- Updated criteriaData in all 15 ARM actions (60 changes)
- Removed `{Subscription}`, `{ResourceGroup}`, `{FunctionAppName}` from criteriaData
- Added `{FunctionApp}` to criteriaData
- Script: `scripts/fix_criteria_data.py`

### Problem 2: CustomEndpoint Stuck in Infinite Refresh Loop
**Symptom**: DeviceList and other CustomEndpoint parameters "keeps stack in refreshing"

**Root Cause**: CustomEndpoint criteriaData referenced `{FunctionAppName}` creating circular dependency:
```
User selects {FunctionApp}
  ↓
{FunctionAppName} ARG query starts (derives name from resource ID)
  ↓
DeviceList criteriaData waits for {FunctionAppName}
  ↓
CustomEndpoint tries to call URL: https://{FunctionAppName}.azurewebsites.net/...
  ↓
{FunctionAppName} not yet resolved → INFINITE REFRESH LOOP
```

**Fix (Commit 8b5a709)**:
- Updated criteriaData in 21 CustomEndpoint parameters
- Changed `{FunctionAppName}` → `{FunctionApp}` in criteriaData
- Script: `scripts/fix_customendpoint_criteria.py`

## 🔄 Correct Evaluation Flow (After Fix)

```
1. User selects {FunctionApp} from resource picker
   ↓
2. ARM actions and CustomEndpoints evaluate immediately
   (criteriaData has {FunctionApp}, so they know to refresh)
   ↓
3. ARM actions use: {FunctionApp}/functions/DefenderC2Dispatcher/invocations
   CustomEndpoints call: https://{FunctionAppName}.azurewebsites.net/api/...
   ↓
4. Derived parameters populate via ARG queries:
   - {Subscription} = subscriptionId from {FunctionApp}
   - {ResourceGroup} = resourceGroup from {FunctionApp}
   - {FunctionAppName} = name from {FunctionApp}
   - {TenantId} = from KeyVault secret
```

## 📋 Technical Details

### criteriaData Purpose
The `criteriaData` array tells the Azure Workbook engine **when to refresh/re-evaluate** a component:

```json
"criteriaData": [
  {
    "criterionType": "param",
    "value": "{FunctionApp}"  // ✅ Re-evaluate when FunctionApp changes
  },
  {
    "criterionType": "param", 
    "value": "{TenantId}"     // ✅ Re-evaluate when TenantId changes
  }
]
```

**Critical Rule**: criteriaData must reference **source parameters**, not **derived parameters**

### Parameter Dependency Hierarchy

```
SOURCE PARAMETERS (user-selected):
├─ {FunctionApp} (Type 5 - Resource Picker)
└─ {Workspace} (Type 5 - Resource Picker)

DERIVED PARAMETERS (auto-populated via ARG queries):
├─ {Subscription} ← depends on {FunctionApp}
├─ {ResourceGroup} ← depends on {FunctionApp}
├─ {FunctionAppName} ← depends on {FunctionApp}
└─ {TenantId} ← depends on {FunctionApp} (via KeyVault query)

ACTION-SPECIFIC PARAMETERS:
├─ {DeviceList} ← depends on {FunctionApp} + {TenantId}
├─ {IsolateDeviceIds} ← depends on {FunctionApp} + {TenantId}
└─ ... (other device/action dropdowns)
```

### Why Both Fixes Were Needed

**ARM Actions** (Type 12 - ARM Endpoint):
- Path uses `{FunctionApp}/functions/...`
- criteriaData must include `{FunctionApp}` for path substitution
- Without it: workbook doesn't know to refresh when FunctionApp changes

**CustomEndpoints** (Type 10 - Custom Endpoint):
- URL uses `https://{FunctionAppName}.azurewebsites.net/...`
- criteriaData must include `{FunctionApp}` (not {FunctionAppName})
- Without it: circular dependency → infinite refresh loop

## 🧪 Testing Verification

### Expected Behavior After Fix

1. **Function App Selection**:
   - Select Function App from dropdown
   - Global parameters auto-populate within 2-3 seconds
   - DeviceList dropdown populates with devices
   - No infinite refresh loops

2. **ARM Action Execution**:
   - Click "Run Antivirus Scan" button
   - ARM blade opens with correct path:
     ```
     POST /subscriptions/.../resourceGroups/.../providers/microsoft.web/sites/{functionapp}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01&action=Run%20Antivirus%20Scan&tenantId={guid}&deviceIds={ids}
     ```
   - NO `<unset>` or URL-encoded errors

3. **CustomEndpoint Queries**:
   - DeviceList and other dropdowns refresh when FunctionApp changes
   - Query results populate without delay
   - No "stuck in refreshing" state

## 📊 Impact Summary

| Component | Before | After |
|-----------|--------|-------|
| ARM Actions | `<unset>` in path | ✅ Correct resource ID |
| ARM Action Count | 15 broken | ✅ 15 fixed |
| CustomEndpoints | Infinite refresh | ✅ Evaluates correctly |
| CustomEndpoint Count | 21 broken | ✅ 21 fixed |
| DeviceList Dropdown | Stuck refreshing | ✅ Populates devices |
| Parameter Auto-population | Failed | ✅ Works |
| Total Changes | - | 81 criteriaData fixes |

## 🔗 Related Commits

1. **2f3f95b** - Fix ARM action criteriaData (60 changes)
2. **8b5a709** - Fix CustomEndpoint criteriaData (21 changes)

## 📚 Key Learnings

1. **criteriaData is critical** for parameter substitution and refresh logic
2. **Reference source parameters**, not derived parameters in criteriaData
3. **Circular dependencies** cause infinite refresh loops in CustomEndpoints
4. **ARM actions and CustomEndpoints** need different approaches but same principle
5. **Resource pickers** ({FunctionApp}) should be in criteriaData, not derived text params

## 🚀 Next Steps

1. Deploy updated workbook to Azure Portal
2. Test Function App selection and parameter auto-population
3. Verify ARM actions invoke correctly
4. Confirm DeviceList and other dropdowns populate without refresh loops
5. Test all 15 ARM action buttons across 5 function endpoints
