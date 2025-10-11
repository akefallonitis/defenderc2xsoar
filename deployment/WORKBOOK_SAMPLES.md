# DefenderC2 Workbook - Sample Configurations

## Overview
This document provides copy-paste JSON samples for common workbook configurations, including device parameter auto-population, auto-refresh queries, and ARM actions.

---

## Device List Parameter (Auto-Population)

### Full Parameter Configuration
Use this in the main parameters section to create an auto-populated device list:

```json
{
  "id": "devicelist-parameter",
  "version": "KqlParameterItem/1.0",
  "name": "DeviceList",
  "label": "Available Devices",
  "type": 2,
  "isRequired": false,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "query": "{\"version\": \"CustomEndpoint/1.0\", \"data\": null, \"headers\": [{\"name\": \"Content-Type\", \"value\": \"application/json\"}], \"method\": \"POST\", \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\", \"body\": \"{\\\"action\\\": \\\"Get Devices\\\", \\\"tenantId\\\": \\\"{TenantId}\\\"}\", \"transformers\": [{\"type\": \"jsonpath\", \"settings\": {\"tablePath\": \"$.devices[*]\", \"columns\": [{\"path\": \"$.id\", \"columnid\": \"value\"}, {\"path\": \"$.computerDnsName\", \"columnid\": \"label\"}]}}]}",
  "typeSettings": {
    "additionalResourceOptions": [],
    "showDefault": false
  },
  "timeContext": {
    "durationMs": 86400000
  },
  "queryType": 10,
  "description": "Select one or more devices from the list. This list is populated automatically from your Defender environment."
}
```

### Parsed Query Structure
The `query` field above contains this JSON (shown here parsed for clarity):

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
  "body": "{\"action\": \"Get Devices\", \"tenantId\": \"{TenantId}\"}",
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [
          {
            "path": "$.id",
            "columnid": "value"
          },
          {
            "path": "$.computerDnsName",
            "columnid": "label"
          }
        ]
      }
    }
  ]
}
```

---

## Action-Specific Device Parameters

### Isolate Device Parameter
```json
{
  "id": "isolate-deviceids",
  "version": "KqlParameterItem/1.0",
  "name": "IsolateDeviceIds",
  "label": "Device IDs (comma-separated)",
  "type": 2,
  "isRequired": false,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "description": "Select one or more devices. List is auto-populated from Defender environment.",
  "timeContext": {
    "durationMs": 86400000
  },
  "query": "{\"version\": \"CustomEndpoint/1.0\", \"data\": null, \"headers\": [{\"name\": \"Content-Type\", \"value\": \"application/json\"}], \"method\": \"POST\", \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\", \"body\": \"{\\\"action\\\": \\\"Get Devices\\\", \\\"tenantId\\\": \\\"{TenantId}\\\"}\", \"transformers\": [{\"type\": \"jsonpath\", \"settings\": {\"tablePath\": \"$.devices[*]\", \"columns\": [{\"path\": \"$.id\", \"columnid\": \"value\"}, {\"path\": \"$.computerDnsName\", \"columnid\": \"label\"}]}}]}",
  "queryType": 10,
  "typeSettings": {
    "additionalResourceOptions": [],
    "showDefault": false
  }
}
```

### Other Device Parameters
Same structure applies to:
- `UnisolateDeviceIds`
- `RestrictDeviceIds`
- `ScanDeviceIds`

Just change the `id` and `name` fields accordingly.

---

## Auto-Refresh Query Configuration

### Action Manager Auto-Refresh
Add these fields to enable auto-refresh on the action list query:

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"httpBodySchema\":\"{\\\"action\\\":\\\"Get Actions\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[...]}",
    "size": 0,
    "title": "📊 Machine Actions (Auto-refreshing)",
    "queryType": 12,
    "visualization": "table"
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "always"
  },
  "name": "query - actions-list"
}
```

### Key Fields for Auto-Refresh
```json
{
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "always"
  }
}
```

**Refresh Conditions:**
- `"always"` - Refresh continuously at specified interval
- `"<condition>"` - Refresh only when condition is true (e.g., `"$.status != 'Completed'"`)

---

## Device List Query (Table Display)

### Full Query Item
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.deviceName\",\"columnId\":\"Device Name\"},{\"path\":\"$.riskScore\",\"columnId\":\"Risk Score\"},{\"path\":\"$.healthStatus\",\"columnId\":\"Health Status\"},{\"path\":\"$.lastIpAddress\",\"columnId\":\"Last IP\"},{\"path\":\"$.lastSeen\",\"columnId\":\"Last Seen\"},{\"path\":\"$.id\",\"columnId\":\"Device ID\"}]}}],\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\"}",
    "size": 0,
    "title": "💻 Device List",
    "showExportToExcel": true,
    "queryType": 12,
    "visualization": "table"
  },
  "name": "query - get-devices"
}
```

### Parsed Query
```json
{
  "version": "ARMEndpoint/1.0",
  "data": null,
  "headers": [
    {
      "name": "Content-Type",
      "value": "application/json"
    }
  ],
  "method": "POST",
  "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [
          {"path": "$.deviceName", "columnId": "Device Name"},
          {"path": "$.riskScore", "columnId": "Risk Score"},
          {"path": "$.healthStatus", "columnId": "Health Status"},
          {"path": "$.lastIpAddress", "columnId": "Last IP"},
          {"path": "$.lastSeen", "columnId": "Last Seen"},
          {"path": "$.id", "columnId": "Device ID"}
        ]
      }
    }
  ]
}
```

---

## ARM Action Button

### Isolate Device Action
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "list",
    "links": [
      {
        "id": "isolate-action-link",
        "linkTarget": "ArmAction",
        "linkLabel": "🚨 Isolate Device",
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
          "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"isolationType\":\"{IsolationType}\"}",
          "httpMethod": "POST",
          "description": "Isolate selected devices from the network"
        }
      }
    ]
  },
  "name": "links - isolate-action"
}
```

### Key ARM Action Fields
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "headers": [
      {"name": "Content-Type", "value": "application/json"}
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
    "httpMethod": "POST"
  }
}
```

---

## JSONPath Transformers

### Basic Device List Transformer
```json
{
  "type": "jsonpath",
  "settings": {
    "tablePath": "$.devices[*]",
    "columns": [
      {"path": "$.id", "columnid": "value"},
      {"path": "$.computerDnsName", "columnid": "label"}
    ]
  }
}
```

### Advanced Device List with Multiple Columns
```json
{
  "type": "jsonpath",
  "settings": {
    "tablePath": "$.devices[*]",
    "columns": [
      {"path": "$.id", "columnId": "Device ID"},
      {"path": "$.deviceName", "columnId": "Device Name"},
      {"path": "$.riskScore", "columnId": "Risk Score"},
      {"path": "$.healthStatus", "columnId": "Health Status"},
      {"path": "$.isolationState", "columnId": "Isolation State"},
      {"path": "$.lastSeen", "columnId": "Last Seen"},
      {"path": "$.osPlatform", "columnId": "OS Platform"}
    ]
  }
}
```

### Action List Transformer
```json
{
  "type": "jsonpath",
  "settings": {
    "tablePath": "$.actions[*]",
    "columns": [
      {"path": "$.id", "columnId": "Action ID"},
      {"path": "$.type", "columnId": "Type"},
      {"path": "$.status", "columnId": "Status"},
      {"path": "$.requestor", "columnId": "Requestor"},
      {"path": "$.creationDateTimeUtc", "columnId": "Created"},
      {"path": "$.machineId", "columnId": "Device ID"}
    ]
  }
}
```

### Hunt Results Transformer with Filtering
```json
{
  "type": "jsonpath",
  "settings": {
    "tablePath": "$.results[?(@.Severity == 'High')]",
    "columns": [
      {"path": "$.DeviceName", "columnId": "Device"},
      {"path": "$.AlertTitle", "columnId": "Alert"},
      {"path": "$.Severity", "columnId": "Severity"},
      {"path": "$.Timestamp", "columnId": "Time"}
    ]
  }
}
```

---

## Function App Request/Response Examples

### Get Devices Request
```http
POST https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher
Content-Type: application/json

{
  "action": "Get Devices",
  "tenantId": "{TenantId}"
}
```

### Get Devices Response
```json
{
  "devices": [
    {
      "id": "abc123device456",
      "computerDnsName": "DESKTOP-ABC123",
      "deviceName": "DESKTOP-ABC123",
      "isolationState": "NotIsolated",
      "healthStatus": "Active",
      "riskScore": "Medium",
      "exposureLevel": "Medium",
      "lastSeen": "2025-10-11T14:30:00Z",
      "osPlatform": "Windows10",
      "lastIpAddress": "192.168.1.100"
    }
  ]
}
```

### Isolate Device Request
```http
POST https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher
Content-Type: application/json

{
  "action": "Isolate Device",
  "tenantId": "{TenantId}",
  "deviceIds": "abc123device456,def789device012",
  "isolationType": "Full"
}
```

### Isolate Device Response
```json
{
  "status": "success",
  "actionId": "action-12345",
  "message": "Isolation initiated for 2 devices"
}
```

---

## Query Type Reference

| Query Type | Value | Use Case | Key Fields |
|------------|-------|----------|------------|
| Azure Resource Graph | 1 | Query Azure resources | `query` (KQL) |
| Text Input | 1 | Manual parameter entry | `value` |
| Dropdown | 2 | Select from list | `jsonData` or `query` |
| Query | 3 | Display data table | `query`, `visualization` |
| Custom Endpoint | 10 | Call external API | `query` (JSON with url, method, body) |
| ARM Endpoint | 12 | Call Azure ARM API | `query` (JSON with path, method, httpBodySchema) |

---

## Best Practices

### 1. Always Use Content-Type Header
```json
"headers": [
  {"name": "Content-Type", "value": "application/json"}
]
```

### 2. Escape JSON in Query Strings
When embedding JSON in `query` field, escape quotes:
```json
"query": "{\"version\":\"CustomEndpoint/1.0\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\"}\"}"
```

### 3. Use Multi-Select for Device Parameters
```json
{
  "type": 2,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ","
}
```

### 4. Add Descriptive Labels
```json
{
  "name": "DeviceList",
  "label": "Available Devices",
  "description": "Select one or more devices. List is auto-populated from Defender environment."
}
```

### 5. Set Appropriate Time Context
```json
{
  "timeContext": {
    "durationMs": 86400000
  }
}
```

---

## Troubleshooting

### Query Not Returning Data
1. Check `FunctionAppName` parameter is set
2. Verify `TenantId` is auto-populated
3. Test Function App endpoint manually
4. Check Function App logs for errors

### JSONPath Not Parsing
1. Verify response structure matches `tablePath`
2. Check column paths exist in response
3. Use browser console to validate JSON structure
4. Test JSONPath expression online

### Parameter Not Updating
1. Force refresh by changing and reverting another parameter
2. Clear browser cache
3. Check query dependencies
4. Verify `queryType` is correct

---

## References

- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [JSONPath Syntax](https://goessner.net/articles/JsonPath/)
- [CUSTOMENDPOINT_GUIDE.md](CUSTOMENDPOINT_GUIDE.md)
- [DEVICE_PARAMETER_AUTOPOPULATION.md](DEVICE_PARAMETER_AUTOPOPULATION.md)

---

**Last Updated:** 2025-10-11  
**Version:** 1.0
