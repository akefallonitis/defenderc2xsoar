# DefenderC2 Workbook: Custom Endpoint Auto-Refresh & ARM Actions Guide

This guide provides step-by-step instructions and code samples for implementing Custom Endpoint auto-refresh and ARM Actions in the DefenderC2 workbook, covering all 7 functional tabs.

---

## Table of Contents
1. [Overview](#overview)
2. [Parameters](#parameters)
3. [Custom Endpoint Auto-Refresh Setup](#custom-endpoint-auto-refresh-setup)
4. [ARM Actions Setup](#arm-actions-setup)
5. [Functional Tabs Implementation](#functional-tabs-implementation)
6. [Troubleshooting](#troubleshooting)
7. [Validation Steps](#validation-steps)
8. [References](#references)

---

## Overview
This guide explains how to:
- Configure Custom Endpoint queries for auto-refresh (recommended: 30s interval)
- Set up ARM Actions for direct Function App HTTP calls
- Pass correct parameters (action, tenantId, etc.)
- Use JSONPath transformers for output parsing
- Implement all 7 functional tabs: Device Manager, Threat Intel, Action Manager, Hunt Manager, Incident Manager, Detection Manager, Console

---

## Parameters
- **FunctionAppName** (required, defined as a workbook parameter)
- **Subscription** (defined as a workbook parameter)
- **Workspace** (defined as a workbook parameter)
- **TenantId** (auto-discovered, ensure correct parameter binding)

---

## Custom Endpoint Auto-Refresh Setup
For each query section in the Azure Workbook UI:
1. **Change Query Type** to `Custom Endpoint`
2. **Data Source**: Custom Endpoint
3. **HTTP Method**: POST
4. **URL**: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher` (use workbook parameter binding, not hardcoded)
5. **Body**: `{ "action": "Get Devices", "tenantId": "{TenantId}" }` (use workbook parameter binding)
6. **Headers**: `Content-Type: application/json`
7. **Result Settings**: JSONPath
  - Table Path: `$.devices[*]`
  - Define columns for id, computerDnsName, isolationState, healthStatus, riskScore, exposureLevel, lastSeen, osPlatform
8. **Enable Auto-refresh**: 30s interval
9. **Troubleshooting**: If parameters are not autopopulated, check workbook parameter definitions and references. Use `{FunctionAppName}` and `{TenantId}` exactly as defined in the Parameters section.

### Sample Custom Endpoint Query JSON
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.devices[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.computerDnsName", "columnid": "computerDnsName"},
            {"path": "$.isolationState", "columnid": "isolationState"},
            {"path": "$.healthStatus", "columnid": "healthStatus"},
            {"path": "$.riskScore", "columnid": "riskScore"},
            {"path": "$.exposureLevel", "columnid": "exposureLevel"},
            {"path": "$.lastSeen", "columnid": "lastSeen"},
            {"path": "$.osPlatform", "columnid": "osPlatform"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## ARM Actions Setup
For each ARM Action button:
1. Use direct HTTP POST to Function App endpoint or Azure Management API as needed
2. Path: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher` (use workbook parameter binding)
3. For management API, use:
   `https://management.azure.com/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/{functionName}/listKeys?api-version=2022-03-01`
4. Headers: `Content-Type: application/json`
5. Body: `{ "action": "Isolate Device", "tenantId": "{TenantId}", "deviceIds": "{DeviceIds}" }` (use workbook parameter binding)

### Sample ARM Action JSON (Function App)
```json
{
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "body": "{ \"action\": \"Isolate Device\", \"tenantId\": \"{TenantId}\", \"deviceIds\": \"{DeviceIds}\" }",
    "httpMethod": "POST"
  }
}
```

### Sample ARM Action JSON (Management API)
```json
{
  "armActionContext": {
    "path": "https://management.azure.com/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/{functionName}/listKeys?api-version=2022-03-01",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "body": "{}",
    "httpMethod": "POST"
  }
}
```

---

## Functional Tabs Implementation
For each of the 7 tabs, configure queries and actions as described above. All tabs should be visible and not conditionally hidden. Example for Threat Intel tab:

### Threat Intel Tab
- **Custom Endpoint to TIManager**:
  - URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager` (use workbook parameter binding)
  - Body: `{ "action": "List Indicators", "tenantId": "{TenantId}" }` (use workbook parameter binding)
  - JSONPath: `$.indicators[*]` with appropriate columns

Repeat similar setup for:
- Device Manager
- Action Manager
- Hunt Manager
- Incident Manager
- Detection Manager
- Console
Ensure each tab's query references the correct endpoint and parameters, and is not conditionally hidden.

---

## Troubleshooting
- If you see "No Log Analytics workspace resources are selected", ensure you have selected the correct workspace
- If Custom Endpoint returns errors, check the Function App authentication and parameters
- For ARM Actions, confirm action, tenantId, and deviceIds are valid and passed as JSON

---

## Validation Steps
1. Import workbook in Azure Portal
2. Configure all parameters
3. Manually edit each query to set Custom Endpoint and ARM Action as described
4. Confirm auto-refresh and real-time data updates
5. Test ARM Actions for expected device response

---

## References
- ![Custom Endpoint configuration UI screenshot](https://github.com/user-attachments/assets/d113dfc8-e263-4201-8ba5-7626da2d8e39)
- ![Log Analytics query screenshot](https://github.com/user-attachments/assets/97097e6b-64a7-454c-85ac-8ed4603ba822)
- ![Manual ARM action and request details](https://github.com/user-attachments/assets/9c4a6c6f-9f91-45d8-a4b4-3e920b711265)

---

**Reference this guide in your PR description.**
