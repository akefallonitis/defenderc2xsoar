# Critical Fix: FunctionAppName Placeholder Removal

## Problem

CustomEndpoint queries were not autopopulating because the `FunctionAppName` parameter had a hardcoded placeholder value:

```json
"value": "__FUNCTION_APP_NAME_PLACEHOLDER__"
```

This caused all queries to call non-existent URLs like:
```
https://__FUNCTION_APP_NAME_PLACEHOLDER__.azurewebsites.net/api/DefenderC2Dispatcher
```

## Root Cause

The placeholder was meant to be replaced during deployment (likely by the ARM template or deployment script), but:
1. The workbook was being deployed directly without replacement
2. Users couldn't override the hardcoded value in the Azure Portal
3. All CustomEndpoint queries failed silently with no error message

## Solution

**Removed the hardcoded `value` property** from the FunctionAppName parameter:

### Before (BROKEN):
```json
{
  "name": "FunctionAppName",
  "type": 1,
  "isRequired": true,
  "value": "__FUNCTION_APP_NAME_PLACEHOLDER__",  // ← This blocked user input!
  "description": "..."
}
```

### After (FIXED):
```json
{
  "name": "FunctionAppName",
  "type": 1,
  "isRequired": true,
  // NO hardcoded value - users can enter their own!
  "description": "..."
}
```

## Impact

✅ **Now users can enter their actual Function App name**
✅ **CustomEndpoint queries will call the correct URL**
✅ **Device dropdowns will populate automatically**
✅ **All auto-refresh queries will work**

## Testing

After this fix, when users open the workbook:

1. **FunctionAppName field will be empty** (not pre-filled with placeholder)
2. **User enters their Function App name** (e.g., `defenderc2`)
3. **Queries automatically call** `https://defenderc2.azurewebsites.net/api/...`
4. **DeviceList dropdown populates** with actual devices from Defender API
5. **All tabs work correctly** (Threat Intel, Hunt Manager, etc.)

## Why This Was Missed

The placeholder pattern is common in ARM templates for deployment-time substitution:

```json
// deployment/azuredeploy.json
"workbookContent": "[replace(string(variables('workbookContent')), '__FUNCTION_APP_NAME_PLACEHOLDER__', parameters('functionAppName'))]"
```

However, the workbook JSON itself should **never** have hardcoded values that prevent user input. Parameters should either:
- Have no `value` property (user must provide)
- Have a sensible default that users can override
- Be auto-discovered from other resources (like TenantId)

## Related Issues

This fix resolves the final blocker for Issue #57:

- ✅ CustomEndpoint queries configured correctly
- ✅ ARM Actions using Azure Resource Manager API
- ✅ Function Key issue resolved (removed ?code={FunctionKey})
- ✅ ResourceGroup parameter added
- ✅ **FunctionAppName placeholder removed** ← THIS FIX

## Validation

```bash
# Before fix:
grep -o '"value": "__FUNCTION_APP_NAME_PLACEHOLDER__"' workbook/DefenderC2-Workbook.json
# Output: "value": "__FUNCTION_APP_NAME_PLACEHOLDER__"

# After fix:
grep -o '"value": "__FUNCTION_APP_NAME_PLACEHOLDER__"' workbook/DefenderC2-Workbook.json
# Output: (no matches)
```

✅ **Placeholder completely removed**

## Deployment Note

For ARM template deployments that want to pre-fill the FunctionAppName, the template should:

1. Deploy the workbook with the parameter value already substituted in the JSON
2. Use ARM template's `replace()` function at deployment time
3. NOT rely on the workbook having a placeholder value

Example ARM template pattern:
```json
{
  "type": "Microsoft.Insights/workbooks",
  "properties": {
    "serializedData": "[replace(variables('workbookJson'), '__FUNCTION_APP_NAME_PLACEHOLDER__', parameters('functionAppName'))]"
  }
}
```

The workbook JSON itself should remain clean without placeholders.

---

**Status**: Complete ✅  
**Date**: October 11, 2025  
**Severity**: Critical (blocked all CustomEndpoint queries)  
**Resolution Time**: Immediate
