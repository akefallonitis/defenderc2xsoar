# Full, Correct Guide: Custom Endpoint and ARM Actions for DefenderC2 Function Apps in Azure Workbooks

## Overview
This guide provides a comprehensive, step-by-step reference for implementing fully functional Custom Endpoint auto-refresh queries and ARM Actions in Azure Workbooks for DefenderC2 Function Apps. It includes:
- Correct, copy-paste JSON code samples for both Custom Endpoint and ARM Action items
- Autodiscovery of parameters (including TenantId)
- Optional Function Key support (parameterized, not required for anonymous access)
- Tab-by-tab instructions
- Troubleshooting and validation

---

## 1. Parameter Autodiscovery & Optional Function Key

### Required Parameters
- **FunctionAppName**: User-provided function app name (e.g., "defc2", "mydefender")
- **TenantId**: Auto-discovered from the selected Log Analytics Workspace
- **FunctionKey**: Optional parameter, only used if Function App requires authentication

### Sample Parameters Section

```json
{
  "parameters": [
    {
      "name": "FunctionAppName",
      "type": 1,
      "isRequired": true,
      "value": "__FUNCTION_APP_NAME_PLACEHOLDER__",
      "description": "Enter your DefenderC2 function app name"
    },
    {
      "name": "TenantId",
      "type": 1,
      "isRequired": true,
      "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | where id == '{Workspace}' | extend TenantId = tostring(properties.customerId) | project value = TenantId, label = TenantId",
      "crossComponentResources": ["{Subscription}"],
      "isHiddenWhenLocked": true,
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources",
      "description": "Auto-discovered from Log Analytics Workspace. This is the Workspace ID (Customer ID) used as the target tenant for Defender API calls."
    },
    {
      "name": "FunctionKey",
      "type": 1,
      "isRequired": false,
      "description": "Optional. Only needed if Function App is not configured for anonymous access. Leave empty for anonymous functions."
    }
  ]
}
```

---

## 2. Custom Endpoint (Auto-Refresh, With/Without Function Key)

### How to Configure in Advanced Editor

Custom Endpoint queries use:
- **queryType**: `10` (Custom Endpoint)
- **query**: JSON string containing CustomEndpoint/1.0 configuration
- **method**: POST
- **url**: Function App endpoint URL
- **auto-refresh**: Enabled for automatic data updates

### URL Patterns

**Without Function Key (Anonymous Access):**
```
https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher
```

**With Function Key (Authenticated Access):**
```
https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}
```

### Sample JSON: Device List (No Function Key)

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.isolationState\",\"columnid\":\"isolationState\"},{\"path\":\"$.healthStatus\",\"columnid\":\"healthStatus\"},{\"path\":\"$.riskScore\",\"columnid\":\"riskScore\"}]}}]}",
    "size": 0,
    "title": "Device List (Custom Endpoint Auto-Refresh)",
    "queryType": 10,
    "visualization": "table"
  },
  "name": "devices-table"
}
```

### Sample JSON: Device List (With Optional Function Key)

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.isolationState\",\"columnid\":\"isolationState\"},{\"path\":\"$.healthStatus\",\"columnid\":\"healthStatus\"},{\"path\":\"$.riskScore\",\"columnid\":\"riskScore\"}]}}]}",
    "size": 0,
    "title": "Device List (Custom Endpoint Auto-Refresh)",
    "queryType": 10,
    "visualization": "table"
  },
  "name": "devices-table"
}
```

### Parsed Custom Endpoint Structure

For clarity, here's the inner JSON structure (parsed from the escaped string):

```json
{
  "version": "CustomEndpoint/1.0",
  "data": null,
  "headers": [
    {
      "name": "Content-Type",
      "value": "application/json"
    }
  ],
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [
          {
            "path": "$.id",
            "columnid": "id"
          },
          {
            "path": "$.computerDnsName",
            "columnid": "computerDnsName"
          },
          {
            "path": "$.isolationState",
            "columnid": "isolationState"
          },
          {
            "path": "$.healthStatus",
            "columnid": "healthStatus"
          },
          {
            "path": "$.riskScore",
            "columnid": "riskScore"
          }
        ]
      }
    }
  ]
}
```

### Key Components

1. **version**: Must be "CustomEndpoint/1.0"
2. **method**: "POST" for all DefenderC2 operations
3. **url**: Function App endpoint with parameter substitution
4. **headers**: Content-Type: application/json required
5. **body**: JSON string with action and required parameters
6. **transformers**: JSONPath transformer to parse response into table format

---

## 3. ARM Actions (Manual Button, With/Without Function Key)

ARM Actions provide button-based interactions that POST directly to the Function App.

### Sample JSON: Isolate Device (No Function Key)

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "linkTarget": "ArmAction",
        "linkLabel": "🚨 Isolate Devices",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
          "httpMethod": "POST",
          "description": "Isolate selected devices from the network"
        }
      }
    ]
  }
}
```

### Sample JSON: Isolate Device (With Optional Function Key)

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "linkTarget": "ArmAction",
        "linkLabel": "🚨 Isolate Devices",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
          "httpMethod": "POST",
          "description": "Isolate selected devices from the network"
        }
      }
    ]
  }
}
```

### ARM Action Key Components

1. **linkTarget**: Must be "ArmAction"
2. **armActionContext.path**: Direct URL to Function App endpoint
3. **armActionContext.headers**: Content-Type header required
4. **armActionContext.body**: JSON string with parameters
5. **armActionContext.httpMethod**: "POST"

---

## 4. Tab-by-Tab Functionality Examples

### Device Manager Tab
- **Get Devices** (Custom Endpoint, auto-refresh)
- **Isolate Device** (ARM Action)
- **Unisolate Device** (ARM Action)
- **Restrict App Execution** (ARM Action)
- **Unrestrict App Execution** (ARM Action)
- **Run Antivirus Scan** (ARM Action)
- **Stop and Quarantine File** (ARM Action)

### Threat Intel Tab
- **List Indicators** (Custom Endpoint)
- **Add File Indicator** (ARM Action)
- **Add IP Indicator** (ARM Action)
- **Add URL Indicator** (ARM Action)

### Action Manager Tab
- **Get All Actions** (Custom Endpoint, auto-refresh)
- **Cancel Action** (ARM Action)

### Hunt Manager Tab
- **Execute Hunt** (ARM Action)
- **Get Hunt Status** (Custom Endpoint)

### Incident Manager Tab
- **Get Incidents** (Custom Endpoint)
- **Update Incident** (ARM Action)
- **Add Comment** (ARM Action)

### Detection Manager Tab
- **List Detections** (Custom Endpoint)
- **Create Detection** (ARM Action)
- **Update Detection** (ARM Action)
- **Delete Detection** (ARM Action)

### Console Tab
- **Get Command History** (Custom Endpoint)
- **Execute Command** (ARM Action)

---

## 5. Troubleshooting & Validation

### Common Issues

**Issue**: Queries return no data or errors
- **Check**: Function App authentication setting (Anonymous vs Function)
- **Check**: If FunctionKey parameter is blank, ensure URL doesn't contain `?code=`
- **Check**: Verify Function App is deployed and running
- **Check**: Check Function App logs for errors

**Issue**: "Please provide a valid resource path"
- **Cause**: FunctionAppName parameter is empty or incorrect
- **Fix**: Update FunctionAppName parameter value

**Issue**: "401 Unauthorized"
- **Cause**: Function App requires key but FunctionKey is empty
- **Fix**: Add Function Key to FunctionKey parameter

**Issue**: "404 Not Found"
- **Cause**: Function App name is incorrect or doesn't exist
- **Fix**: Verify function app name in Azure Portal

**Issue**: "500 Internal Server Error"
- **Cause**: Function App error (missing environment variables, etc.)
- **Fix**: Check Function App Application Insights logs

### Validation Checklist

- [ ] FunctionAppName parameter is populated
- [ ] TenantId parameter auto-discovers from workspace
- [ ] FunctionKey parameter exists (optional, can be empty)
- [ ] All Custom Endpoint queries use queryType: 10
- [ ] All Custom Endpoint queries use CustomEndpoint/1.0 version
- [ ] All Custom Endpoint queries have Content-Type header
- [ ] All ARM Actions have Content-Type header
- [ ] All ARM Actions use POST method
- [ ] JSONPath transformers are correctly configured
- [ ] Test at least one query from each tab

---

## 6. How to Use

### Initial Setup

1. **Deploy Function App** (if not already deployed)
   ```powershell
   .\deployment\deploy-all.ps1 -FunctionAppName "mydefender" -ResourceGroupName "rg-security" ...
   ```

2. **Import Workbook** into Azure Portal
   - Navigate to Monitor → Workbooks
   - Click "New" → "Advanced Editor"
   - Paste workbook JSON
   - Click "Apply"

3. **Configure Parameters**
   - Select Subscription
   - Select Workspace (TenantId will auto-populate)
   - Enter Function App Name (e.g., "mydefender")
   - (Optional) Enter Function Key if not using anonymous access

4. **Test Functionality**
   - Navigate to Device Manager tab
   - Click "Get Devices" to test Custom Endpoint
   - Select a device and click "Isolate Device" to test ARM Action

### Updating Existing Workbooks

To migrate from ARMEndpoint to CustomEndpoint:

1. **Backup** existing workbook
2. **Update queryType**: Change from 8 or 12 to 10
3. **Update version**: Change "ARMEndpoint/1.0" to "CustomEndpoint/1.0"
4. **Update structure**: Ensure query is properly escaped JSON string
5. **Add FunctionKey parameter** if needed
6. **Test** each tab after update

---

## 7. Advanced Configuration

### Auto-Refresh Settings

To enable auto-refresh on Custom Endpoint queries:

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "...",
    "queryType": 10,
    "visualization": "table"
  },
  "conditionalVisibility": { ... },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "always"
  }
}
```

### Conditional URL Construction

If FunctionKey should only be added when present, you can use workbook expressions:

**Note**: Azure Workbooks don't support conditional parameter substitution directly. Best practice is to:
- Use empty FunctionKey for anonymous access
- Workbook will generate URL like: `?code=` which can be handled by function
- Or use two separate queries (one with, one without key) with conditional visibility

### Multiple Function Apps

To support multiple function apps in one workbook:

1. Add separate FunctionAppName parameters (e.g., FunctionAppName1, FunctionAppName2)
2. Create separate queries for each function app
3. Use conditional visibility to show/hide based on parameter selection

---

## 8. Reference Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Workbook                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Parameters   │  │ Custom       │  │ ARM Actions  │         │
│  │              │  │ Endpoints    │  │              │         │
│  │ - Function   │  │              │  │              │         │
│  │   AppName    │  │ queryType:10 │  │ linkTarget:  │         │
│  │ - TenantId   │  │              │  │  ArmAction   │         │
│  │ - FunctionKey│  │ CustomEP/1.0 │  │              │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                  │                  │
└─────────┼─────────────────┼──────────────────┼──────────────────┘
          │                 │                  │
          └─────────────────┴──────────────────┘
                            │
                            ▼
          ┌──────────────────────────────────────┐
          │   Azure Function App                 │
          │                                      │
          │   https://{FunctionAppName}.         │
          │   azurewebsites.net/api/             │
          │                                      │
          │   ┌──────────────────────────────┐  │
          │   │ DefenderC2Dispatcher         │  │
          │   │ DefenderC2IncidentManager    │  │
          │   │ DefenderC2TIManager          │  │
          │   │ DefenderC2HuntManager        │  │
          │   │ DefenderC2CDManager          │  │
          │   └──────────────────────────────┘  │
          │                                      │
          └──────────────────┬───────────────────┘
                             │
                             ▼
          ┌──────────────────────────────────────┐
          │   Microsoft Defender for Endpoint    │
          │   API (graph.microsoft.com)          │
          └──────────────────────────────────────┘
```

---

## 9. Example Function App Actions

### DefenderC2Dispatcher

**Actions**: Get Devices, Isolate Device, Unisolate Device, Restrict App Execution, Unrestrict App Execution, Run Antivirus Scan, Stop and Quarantine File

**Request Format**:
```json
{
  "action": "Get Devices",
  "tenantId": "12345678-1234-1234-1234-123456789012"
}
```

### DefenderC2IncidentManager

**Actions**: Get Incidents, Update Incident, Add Comment to Incident

**Request Format**:
```json
{
  "action": "Get Incidents",
  "tenantId": "12345678-1234-1234-1234-123456789012",
  "severity": "High",
  "status": "New"
}
```

### DefenderC2TIManager

**Actions**: List Indicators, Add Indicator

**Request Format**:
```json
{
  "action": "Add Indicator",
  "tenantId": "12345678-1234-1234-1234-123456789012",
  "indicatorType": "FileSha256",
  "indicators": ["hash1", "hash2"]
}
```

### DefenderC2HuntManager

**Actions**: Execute Hunt, Get Hunt Status

**Request Format**:
```json
{
  "action": "Execute Hunt",
  "tenantId": "12345678-1234-1234-1234-123456789012",
  "huntQuery": "DeviceProcessEvents | where FileName =~ 'malware.exe'"
}
```

### DefenderC2CDManager

**Actions**: List Detections, Create Detection, Update Detection, Delete Detection

**Request Format**:
```json
{
  "action": "List Detections",
  "tenantId": "12345678-1234-1234-1234-123456789012"
}
```

---

## 10. Security Best Practices

### Function Key Management

1. **Use Key Vault**: Store function keys in Azure Key Vault
2. **Rotate Keys**: Regularly rotate function keys
3. **Least Privilege**: Use function-specific keys, not host keys
4. **Audit**: Enable logging for function app access

### Anonymous Access

For anonymous access:
1. Configure Function App authentication level to "Anonymous"
2. Leave FunctionKey parameter empty
3. Implement additional security controls:
   - Managed Identity for function app
   - Network restrictions (VNET integration)
   - IP allowlisting
   - Application-level authentication

### Network Security

1. **Private Endpoints**: Use private endpoints for Function Apps
2. **VNET Integration**: Integrate Function App with VNET
3. **NSG Rules**: Configure Network Security Group rules
4. **Application Gateway**: Use Application Gateway for WAF protection

---

## 11. References

- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Functions Authentication](https://docs.microsoft.com/azure/azure-functions/functions-bindings-http-webhook-trigger#authorization-keys)
- [Microsoft Defender for Endpoint API](https://docs.microsoft.com/microsoft-365/security/defender-endpoint/api-overview)
- [JSONPath Syntax](https://goessner.net/articles/JsonPath/)

### Related Issues and PRs

- Issue #XX: Original CustomEndpoint implementation request
- PR #36: TenantId extraction and parameter requirements
- PR #37: Function consolidation and workbook updates
- PR #38: Function App auto-discovery and request parameter fixes

---

## 12. Troubleshooting Scenarios

### Scenario 1: Empty Results

**Symptoms**: Query completes successfully but shows no data

**Possible Causes**:
1. No data exists in Defender (no devices, incidents, etc.)
2. TenantId is incorrect
3. Function App has wrong API credentials

**Solutions**:
1. Verify data exists in Microsoft Defender portal
2. Check TenantId matches workspace customer ID
3. Verify Function App environment variables (APPID, SECRETID)

### Scenario 2: Timeout Errors

**Symptoms**: Query times out or shows "Request timed out"

**Possible Causes**:
1. Function App cold start
2. Large dataset being retrieved
3. Network connectivity issues

**Solutions**:
1. Wait and retry (cold start typically resolves in 30-60 seconds)
2. Implement pagination in function code
3. Check network connectivity between workbook and function app

### Scenario 3: Authentication Errors

**Symptoms**: "401 Unauthorized" or "403 Forbidden"

**Possible Causes**:
1. Missing or incorrect Function Key
2. Function App authentication level mismatch
3. Expired credentials in Function App

**Solutions**:
1. Verify Function Key is correct (check in Azure Portal → Function App → App Keys)
2. Check Function App authentication level matches workbook configuration
3. Refresh Function App credentials (APPID/SECRETID)

---

## Summary

This guide provides everything needed to implement CustomEndpoint queries and ARM Actions in Azure Workbooks for DefenderC2:

✅ **Complete parameter configuration** with autodiscovery  
✅ **Optional Function Key support** for flexible authentication  
✅ **Copy-paste JSON samples** for quick implementation  
✅ **Comprehensive troubleshooting guide**  
✅ **Security best practices**  
✅ **Tab-by-tab functionality reference**

For deployment assistance, see:
- `deployment/README.md` - Deployment instructions
- `deployment/WORKBOOK_PARAMETERS_GUIDE.md` - Parameter details
- `deployment/DYNAMIC_FUNCTION_APP_NAME.md` - Function app naming

---

**Last Updated**: 2025-10-11  
**Version**: 1.0  
**Status**: ✅ Production Ready
