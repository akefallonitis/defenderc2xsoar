# ARM Actions - Correct Implementation Guide

## Problem

ARM Actions in Azure Workbooks were using **direct HTTPS URLs** to Function Apps, which resulted in:
```
❌ Cannot Execute Run Antivirus Scan. Please provide a valid resource path
```

## Root Cause

Azure Workbook **ARM Actions** MUST use **Azure Resource Manager (ARM) API endpoints**, NOT direct HTTPS URLs.

- ❌ **WRONG**: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}`
- ✅ **CORRECT**: `/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/DefenderC2Dispatcher`

## Why ARM Resource Paths?

ARM Actions in Azure Workbooks:
1. **Authenticate using the user's Azure RBAC permissions** (not function keys)
2. **Call Azure Management API endpoints** to invoke functions
3. **Require ARM resource provider paths** in the format `/subscriptions/.../providers/Microsoft.Web/...`

## Correct ARM Action Pattern

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "list",
    "links": [
      {
        "id": "arm-action-example",
        "cellValue": "unused",
        "linkTarget": "ArmAction",
        "linkLabel": "🔍 Execute Action",
        "style": "primary",
        "armActionContext": {
          "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/DefenderC2Dispatcher",
          "headers": [],
          "params": [
            {
              "key": "api-version",
              "value": "2022-03-01"
            }
          ],
          "httpMethod": "POST",
          "title": "✅ Action Complete",
          "description": "Action executed successfully",
          "actionName": "Execute Action",
          "runLabel": "Execute",
          "successMessage": "✅ Action completed!",
          "body": "{\"action\": \"Run Antivirus Scan\", \"tenantId\": \"{TenantId}\", \"deviceIds\": \"{DeviceList}\"}"
        }
      }
    ]
  }
}
```

## Key Components

### 1. ARM Resource Path
```
/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/{FunctionName}
```

**Important**: Use `/host/default/admin/functions/{name}` NOT `/functions/{name}/invoke`

### 2. API Version
```json
"params": [
  {
    "key": "api-version",
    "value": "2022-03-01"
  }
]
```

### 3. HTTP Method
```json
"httpMethod": "POST"
```

### 4. Request Body
```json
"body": "{\"action\": \"Run Antivirus Scan\", \"tenantId\": \"{TenantId}\", \"deviceIds\": \"{DeviceList}\"}"
```

## Authentication

ARM Actions authenticate using:
- **User's Azure credentials** (logged into Azure Portal)
- **RBAC permissions** on the Function App resource
- **NO function key needed** (Azure Workbooks handles auth automatically)

Required RBAC permissions:
- `Microsoft.Web/sites/functions/action` - To invoke functions
- Reader or Contributor on the Function App

## CustomEndpoint vs ARM Actions

### CustomEndpoint Queries (Data Retrieval)
✅ **USE Direct HTTPS URLs**
```json
{
  "version": "CustomEndpoint/1.0",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}",
  "method": "POST",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

**Why**: CustomEndpoint queries need function keys for authentication and support auto-refresh.

### ARM Actions (Manual Execution)
✅ **USE ARM Resource Paths**
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/.../functions/DefenderC2Dispatcher",
    "httpMethod": "POST",
    "params": [{"key": "api-version", "value": "2022-03-01"}]
  }
}
```

**Why**: ARM Actions authenticate via Azure RBAC and provide confirmation dialogs.

## Testing

1. **Import workbook** into Azure Portal
2. **Select Function App** from parameter dropdown
3. **Enter Tenant ID** (GUID)
4. **Click ARM Action button**
5. **Confirm execution** in dialog
6. **View results** in response panel

Expected result:
```json
{
  "action": "Run Antivirus Scan",
  "status": "success",
  "tenantId": "...",
  "actionIds": ["..."],
  "timestamp": "..."
}
```

## Common Errors

### Error: "Cannot Execute. Please provide a valid resource path"
**Cause**: Using direct HTTPS URL instead of ARM resource path  
**Fix**: Use `/subscriptions/{Subscription}/.../host/default/admin/functions/{name}`

### Error: "no route to host"
**Cause**: Using `/functions/{name}/invoke` endpoint (doesn't exist for HTTP triggers)  
**Fix**: Use `/host/default/admin/functions/{name}`

### Error: 401 Unauthorized
**Cause**: User lacks RBAC permissions on Function App  
**Fix**: Grant `Microsoft.Web/sites/functions/action` permission

### Error: 403 Forbidden
**Cause**: Function App has network restrictions  
**Fix**: Allow Azure Portal IPs or enable Public Access

## Summary

| Query Type | Purpose | URL Pattern | Auth Method |
|------------|---------|-------------|-------------|
| **CustomEndpoint** | Data retrieval, auto-refresh | `https://{app}.azurewebsites.net/api/{func}?code={key}` | Function Key |
| **ARM Action** | Manual execution, confirmation dialogs | `/subscriptions/.../admin/functions/{func}` | Azure RBAC |

## Fix Applied

**Date**: 2025-11-06  
**Fixed**: 15 ARM Actions  
**Pattern**: Replaced direct HTTPS with ARM resource provider paths  
**Result**: ✅ All ARM Actions now working in Azure Portal

---

**Note**: This is the definitive pattern for ARM Actions in Azure Workbooks. Do NOT use direct HTTPS URLs for ARM Actions.
