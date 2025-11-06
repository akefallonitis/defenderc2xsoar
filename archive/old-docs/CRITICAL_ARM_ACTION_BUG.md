# 🚨 CRITICAL BUG FOUND - ARM ACTIONS NOT WORKING

## Error Message
```
"Run Antivirus Scan action failed"
Error: "No route registered for '/api/functions/DefenderC2Dispatcher/invocations?api-version=2022-05-13'"
```

## Root Cause
The ARM action path format is **INCORRECTLY USING**:
```
/subscriptions/{Sub}/resourceGroups/{RG}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations
```

This path format (`/functions/.../invocations`) is for:
- ❌ **System Functions** (e.g., Logic Apps triggers)
- ❌ **Durable Functions orchestrations**  
- ❌ **NOT for regular Azure Function HTTP triggers**

## Problem
Azure Workbooks ARM actions are trying to call:
```
https://defenderc2.azurewebsites.net/api/functions/DefenderC2Dispatcher/invocations
```

But the actual Function App endpoint is:
```
✅ https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher
```

## Evidence
1. **Direct Function App call WORKS**:
   ```powershell
   Invoke-WebRequest -Method POST -Uri "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=a92a42cd..."
   # Returns devices successfully!
   ```

2. **ARM action call FAILS**:
   - Azure tries to route to `/api/functions/DefenderC2Dispatcher/invocations`
   - Function App doesn't recognize this path
   - Error: "No route registered"

## Incorrect Pattern (Current)
```json
{
  "type": 11,
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "Run Antivirus Scan"}
    ],
    "httpMethod": "POST"
  }
}
```

## Solution Options

### Option 1: Use CustomEndpoint Instead of ArmAction
ARM actions are NOT designed for calling HTTP-triggered Function Apps. They're designed for Azure Resource Manager operations (creating/modifying resources).

**Correct pattern for Function App calls**:
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\": \"CustomEndpoint/1.0\", \"data\": null, \"headers\": [], \"method\": \"POST\", \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\", \"urlParams\": [{\"key\": \"action\", \"value\": \"Run Antivirus Scan\"}, {\"key\": \"tenantId\", \"value\": \"{TenantId}\"}, {\"key\": \"deviceIds\", \"value\": \"{DeviceList}\"}]}",
    "queryType": 10
  }
}
```

**But this has NO Azure RBAC confirmation dialog!**

### Option 2: Use Link to Open Azure Portal Blade
Open the Function App execution blade in Azure Portal:
```json
{
  "type": 11,
  "linkTarget": "OpenBlade",
  "bladeOpenContext": {
    "bladeName": "FunctionAppBlade",
    "extensionName": "Microsoft_Azure_WebSites"
  }
}
```

**But this doesn't execute the function directly!**

### Option 3: Check DeviceManager-Hybrid.json Again
The working sample uses the same `/functions/.../invocations` path, so either:
1. ❓ It's also broken
2. ❓ There's a missing configuration
3. ❓ The Function App needs special setup

## Next Steps
1. ✅ Test if DeviceManager-Hybrid.json actually works in production
2. 🔍 Check Azure Function App ARM API documentation for correct invocation path
3. 🔍 Check if Function App needs "Deployment Center" or "System Functions" configuration
4. 💡 Consider hybrid approach: CustomEndpoint with manual confirmation step

## Critical Questions
1. **Does DeviceManager-Hybrid.json work in your production environment?**
2. **Are your Function Apps configured differently?**
3. **Do we need to enable "System Functions" or "Managed Functions" feature?**

## Impact
- ❌ All 16 ARM actions are broken
- ❌ User gets error messages when clicking execute buttons
- ❌ No Azure RBAC confirmation appears
- ❌ Success Criterion #1 NOT met if ARM actions don't work

## Workaround (Temporary)
Use CustomEndpoint queries wrapped in conditional groups with manual confirmation text:
```
⚠️ WARNING: This will execute "Run Antivirus Scan" on selected devices
Click Execute to confirm →
```
