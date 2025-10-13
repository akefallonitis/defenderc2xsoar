# 🎯 ARM Action Parameter Fix - Quick Reference

## The Problem
```json
❌ BEFORE (BROKEN):
"path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations"

Result: ARM blade shows "tenantId":"<unset>", "deviceIds":""
```

## The Solution
```json
✅ AFTER (FIXED):
"path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations"

Result: ARM blade shows "tenantId":"actual-guid", "deviceIds":"device-ids"
```

## Why It Works
- **FunctionApp** is a Type 5 (Resource Picker) parameter
- Returns FULL ARM resource ID: `/subscriptions/xxx/resourceGroups/xxx/providers/microsoft.web/sites/appname`
- Just append `/functions/DefenderC2Dispatcher/invocations`
- Azure ARM engine recognizes and processes natively

## What Changed
- **15 ARM actions** across 5 function endpoints
- **Commit**: `270465c` on `main` branch
- **Status**: ✅ Ready to test

## Testing Steps
1. Open workbook in Azure Portal
2. Select Function App
3. Select devices from Device List  
4. Click "Isolate Devices"
5. **Verify ARM blade shows populated parameters**

## Key Insight
**Use resource picker parameters (`{FunctionApp}`) in ARM paths**  
**Use text parameters (`{FunctionAppName}`, `{TenantId}`) in POST body**

## References
- Full documentation: `ARM_ACTION_PARAMETER_FIX_COMPLETE.md`
- Commit: `270465c`
- Previous attempts: `aaef01c`, `993766c`

---

*This fix eliminates text-based parameter substitution issues and follows Azure Workbook best practices.*
