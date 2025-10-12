# Azure Workbook Best Practices for DefenderC2

## Quick Reference Guide

This guide documents the correct configuration patterns for Azure Workbooks based on official Azure Sentinel examples.

## CustomEndpoint Queries

### Purpose
Used for auto-refresh queries that fetch data from custom APIs (like Azure Function Apps).

### Correct Format
```json
{
  "version": "CustomEndpoint/1.0",
  "data": null,
  "headers": [],
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": null,
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ],
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [
          {"path": "$.id", "columnid": "id"},
          {"path": "$.computerDnsName", "columnid": "name"}
        ]
      }
    }
  ]
}
```

### Key Points
- ✅ Use `CustomEndpoint/1.0` version
- ✅ Use parameter substitution: `{FunctionAppName}`, `{TenantId}`
- ✅ Set `queryType: 10` for CustomEndpoint
- ✅ Use `urlParams` for query parameters
- ✅ Include `criteriaData` for auto-refresh triggers

### Example Parameter Definition
```json
{
  "name": "DeviceList",
  "type": 2,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}],\"transformers\":[...]}",
  "queryType": 10,
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ]
}
```

## ARM Actions

### Purpose
Used for buttons that trigger Azure Resource Manager API calls (like invoking Function Apps).

### ✅ Correct Format
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [
      {
        "key": "api-version",
        "value": "2022-03-01"
      }
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"comment\":\"Isolated via Workbook\"}",
    "httpMethod": "POST",
    "title": "Isolate Devices",
    "description": "Initiating device isolation...",
    "actionName": "Isolate",
    "runLabel": "Isolate Devices"
  }
}
```

### ❌ Incorrect Format (Old)
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
    ...
  }
}
```

### Key Points
- ✅ Use **relative path** starting with `/subscriptions/`
- ❌ Do NOT use full URL with `https://management.azure.com`
- ✅ Put `api-version` ONLY in `params` array
- ❌ Do NOT put `api-version` in the path query string
- ✅ Use parameter substitution: `{Subscription}`, `{ResourceGroup}`, `{FunctionAppName}`, `{TenantId}`
- ✅ Include descriptive `title`, `description`, and `runLabel`

## Parameter Autodiscovery

### From Azure Resources
Parameters can autodiscover values from Azure Resource Graph queries:

```json
{
  "name": "FunctionAppName",
  "type": 1,
  "query": "Resources | where id == '{FunctionApp}' | project value = name",
  "queryType": 1,
  "resourceType": "microsoft.resourcegraph/resources",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{FunctionApp}"
    }
  ]
}
```

### Key Points
- ✅ Use Azure Resource Graph for resource autodiscovery
- ✅ Include `criteriaData` to trigger re-evaluation when dependencies change
- ✅ Use `isHiddenWhenLocked: true` for auto-discovered params
- ✅ Chain parameters: FunctionApp → Subscription → ResourceGroup → FunctionAppName → TenantId

## Common Patterns

### Device List Parameter
```json
{
  "name": "DeviceList",
  "label": "Available Devices",
  "type": 2,
  "multiSelect": true,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}],\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"value\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"label\"}]}}]}",
  "queryType": 10,
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ]
}
```

### Action Button
```json
{
  "id": "isolate-action",
  "linkTarget": "ArmAction",
  "linkLabel": "🚨 Isolate Devices",
  "style": "primary",
  "linkIsContextBlade": true,
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "params": [{"key": "api-version", "value": "2022-03-01"}],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
    "httpMethod": "POST"
  }
}
```

## Verification Checklist

### CustomEndpoint Queries
- [ ] Uses `CustomEndpoint/1.0` version
- [ ] Uses parameter substitution for FunctionAppName and TenantId
- [ ] Sets `queryType: 10`
- [ ] Includes proper transformers for data parsing
- [ ] Has `criteriaData` for dependencies

### ARM Actions
- [ ] Path starts with `/subscriptions/`
- [ ] Path does NOT include full `https://management.azure.com` URL
- [ ] `api-version` is in `params` array only
- [ ] `api-version` is NOT in path query string
- [ ] Body includes all required parameters (tenantId, deviceIds, etc.)
- [ ] Uses parameter substitution for dynamic values

### Parameters
- [ ] Resource selectors use Azure Resource Graph (queryType: 1)
- [ ] Auto-discovered params have `criteriaData`
- [ ] Hidden params use `isHiddenWhenLocked: true`
- [ ] Multi-select params have proper `delimiter` and `quote` settings

## Reference
Based on:
- Azure Sentinel Advanced Workbook Concepts
- Azure Workbooks Documentation
- Microsoft Graph API Best Practices
- Azure Function Apps ARM API Documentation

## Common Mistakes to Avoid

1. ❌ Using full URLs in ARM action paths
2. ❌ Duplicating api-version in both path and params
3. ❌ Hardcoding values instead of using parameter substitution
4. ❌ Missing criteriaData for dependent parameters
5. ❌ Wrong queryType for CustomEndpoint (should be 10)
6. ❌ Forgetting to include transformers for JSON parsing
7. ❌ Not using relative paths for ARM actions

## Testing Tips

1. **Test Parameter Autodiscovery**
   - Select FunctionApp → Verify Subscription populates
   - Change FunctionApp → Verify all dependent params refresh

2. **Test CustomEndpoint Queries**
   - Check browser console for API calls
   - Verify correct URL with substituted parameters
   - Confirm data displays in tables

3. **Test ARM Actions**
   - Click button → Verify confirmation dialog
   - Check that action executes successfully
   - Confirm proper error messages on failure

4. **Test Auto-Refresh**
   - Enable auto-refresh on CustomEndpoint queries
   - Verify data updates every 30 seconds
   - Check that refresh doesn't break parameter state

---

**Last Updated**: October 12, 2025  
**Applies To**: DefenderC2-Workbook.json, FileOperations.workbook
