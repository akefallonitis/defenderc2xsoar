# Custom Endpoint Sample Queries

This document provides sample Custom Endpoint query configurations for reference when manually configuring queries in the Azure Workbooks UI.

## Device List Query (With Auto-Refresh)

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
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
  "refreshSettings": {
    "isAutoRefreshEnabled": true,
    "autoRefreshInterval": "30"
  }
}
```

### UI Configuration Steps
1. **Settings Tab**:
   - Query Type: `Custom Endpoint`
   - Http Method: `POST`
   - URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`

2. **Headers Tab**:
   - Name: `Content-Type`
   - Value: `application/json`

3. **Body Tab**:
   - Body format: `JSON`
   - Body content:
     ```json
     {
       "action": "Get Devices",
       "tenantId": "{TenantId}"
     }
     ```

4. **Result Settings Tab**:
   - Result format: `JSON`
   - JSONPath Table: `$.devices[*]`
   - Columns:
     | Path | Column ID | Column Name |
     |------|-----------|-------------|
     | $.id | id | Device ID |
     | $.computerDnsName | computerDnsName | Computer Name |
     | $.isolationState | isolationState | Isolation State |
     | $.healthStatus | healthStatus | Health Status |
     | $.riskScore | riskScore | Risk Score |
     | $.exposureLevel | exposureLevel | Exposure Level |
     | $.lastSeen | lastSeen | Last Seen |
     | $.osPlatform | osPlatform | OS Platform |

5. **Advanced Settings Tab**:
   - ✅ Enable Auto-refresh
   - Refresh interval: `30` seconds
   - ✅ Run on load

## Threat Indicators Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
    "body": "{\"action\":\"List Indicators\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.indicators[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.indicatorValue", "columnid": "indicatorValue"},
            {"path": "$.indicatorType", "columnid": "indicatorType"},
            {"path": "$.action", "columnid": "action"},
            {"path": "$.severity", "columnid": "severity"},
            {"path": "$.title", "columnid": "title"},
            {"path": "$.creationTime", "columnid": "creationTime"}
          ]
        }
      }
    ]
  }
}
```

### UI Configuration Steps
1. **Settings Tab**:
   - Query Type: `Custom Endpoint`
   - Http Method: `POST`
   - URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager`

2. **Headers Tab**:
   - Name: `Content-Type`
   - Value: `application/json`

3. **Body Tab**:
   - Body format: `JSON`
   - Body content:
     ```json
     {
       "action": "List Indicators",
       "tenantId": "{TenantId}"
     }
     ```

4. **Result Settings Tab**:
   - Result format: `JSON`
   - JSONPath Table: `$.indicators[*]`
   - Columns:
     | Path | Column ID | Column Name |
     |------|-----------|-------------|
     | $.id | id | Indicator ID |
     | $.indicatorValue | indicatorValue | Value |
     | $.indicatorType | indicatorType | Type |
     | $.action | action | Action |
     | $.severity | severity | Severity |
     | $.title | title | Title |
     | $.creationTime | creationTime | Created |

## Machine Actions Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "body": "{\"action\":\"Get All Actions\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.actions[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.type", "columnid": "type"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.requestor", "columnid": "requestor"},
            {"path": "$.creationDateTimeUtc", "columnid": "created"},
            {"path": "$.lastUpdateDateTimeUtc", "columnid": "lastUpdated"}
          ]
        }
      }
    ]
  }
}
```

### UI Configuration Steps
1. **Settings Tab**:
   - Query Type: `Custom Endpoint`
   - Http Method: `POST`
   - URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`

2. **Headers Tab**:
   - Name: `Content-Type`
   - Value: `application/json`

3. **Body Tab**:
   - Body format: `JSON`
   - Body content:
     ```json
     {
       "action": "Get All Actions",
       "tenantId": "{TenantId}"
     }
     ```

4. **Result Settings Tab**:
   - Result format: `JSON`
   - JSONPath Table: `$.actions[*]`
   - Columns:
     | Path | Column ID | Column Name |
     |------|-----------|-------------|
     | $.id | id | Action ID |
     | $.type | type | Action Type |
     | $.status | status | Status |
     | $.requestor | requestor | Requestor |
     | $.creationDateTimeUtc | created | Created |
     | $.lastUpdateDateTimeUtc | lastUpdated | Last Updated |

## Hunt Status Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager",
    "body": "{\"action\":\"Get Hunt Status\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.hunts[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.query", "columnid": "query"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.createdTime", "columnid": "createdTime"},
            {"path": "$.resultCount", "columnid": "resultCount"}
          ]
        }
      }
    ]
  }
}
```

## Incidents Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager",
    "body": "{\"action\":\"GetIncidents\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.incidents[*]",
          "columns": [
            {"path": "$.incidentId", "columnid": "incidentId"},
            {"path": "$.incidentName", "columnid": "incidentName"},
            {"path": "$.severity", "columnid": "severity"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.createdTime", "columnid": "createdTime"},
            {"path": "$.lastUpdateTime", "columnid": "lastUpdateTime"}
          ]
        }
      }
    ]
  }
}
```

## Detection Rules Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager",
    "body": "{\"action\":\"List Detections\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.detections[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.ruleName", "columnid": "ruleName"},
            {"path": "$.severity", "columnid": "severity"},
            {"path": "$.enabled", "columnid": "enabled"},
            {"path": "$.createdBy", "columnid": "createdBy"},
            {"path": "$.lastModified", "columnid": "lastModified"}
          ]
        }
      }
    ]
  }
}
```

## Command History Query

### Complete JSON Structure
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Orchestrator",
    "body": "{\"action\":\"Get Command History\",\"tenantId\":\"{TenantId}\"}",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.commands[*]",
          "columns": [
            {"path": "$.id", "columnid": "id"},
            {"path": "$.command", "columnid": "command"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.executedBy", "columnid": "executedBy"},
            {"path": "$.executedTime", "columnid": "executedTime"},
            {"path": "$.result", "columnid": "result"}
          ]
        }
      }
    ]
  }
}
```

## ARM Action Examples

### Isolate Device Action

```json
{
  "linkTarget": "ArmAction",
  "linkLabel": "🔒 Isolate Devices",
  "style": "primary",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"isolationType\":\"{IsolationType}\",\"comment\":\"Isolated via Custom Endpoint Workbook\"}",
    "httpMethod": "POST",
    "title": "Isolate Devices",
    "description": "Initiating device isolation...",
    "actionName": "IsolateDevice",
    "runLabel": "Isolate"
  }
}
```

### Add File Indicators Action

```json
{
  "linkTarget": "ArmAction",
  "linkLabel": "➕ Add File Indicators",
  "style": "primary",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [],
    "body": "{\"action\":\"Add File Indicators\",\"tenantId\":\"{TenantId}\",\"indicators\":\"{FileIndicators}\",\"indicatorAction\":\"{FileIndicatorAction}\",\"severity\":\"High\",\"title\":\"File Indicators\",\"description\":\"Added via Custom Endpoint Workbook\"}",
    "httpMethod": "POST",
    "title": "Add File Indicators",
    "description": "Adding file indicators...",
    "actionName": "AddFileIndicators",
    "runLabel": "Add"
  }
}
```

### Update Incident Action

```json
{
  "linkTarget": "ArmAction",
  "linkLabel": "✏️ Update Incident",
  "style": "primary",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [],
    "body": "{\"action\":\"Update Incident\",\"tenantId\":\"{TenantId}\",\"incidentId\":\"{UpdateIncidentId}\",\"status\":\"{UpdateStatus}\"}",
    "httpMethod": "POST",
    "title": "Update Incident",
    "description": "Updating incident status...",
    "actionName": "UpdateIncident",
    "runLabel": "Update"
  }
}
```

### Create Detection Rule Action

```json
{
  "linkTarget": "ArmAction",
  "linkLabel": "➕ Create Detection Rule",
  "style": "primary",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ],
    "params": [],
    "body": "{\"action\":\"Create Detection\",\"tenantId\":\"{TenantId}\",\"ruleName\":\"{CreateRuleName}\",\"query\":\"{CreateRuleQuery}\",\"severity\":\"{CreateRuleSeverity}\"}",
    "httpMethod": "POST",
    "title": "Create Detection Rule",
    "description": "Creating custom detection rule...",
    "actionName": "CreateDetection",
    "runLabel": "Create"
  }
}
```

## Common JSONPath Patterns

### Array of Objects
```json
"tablePath": "$.devices[*]"
```

### Nested Objects
```json
"tablePath": "$.data.results[*]"
```

### Single Object (wrap in array)
```json
"tablePath": "$[*]"
```

### Root Array
```json
"tablePath": "$[*]"
```

## Parameter Interpolation

All queries support parameter interpolation using `{ParameterName}` syntax:

- `{FunctionAppName}` - Function App name parameter
- `{TenantId}` - Tenant ID parameter
- `{IsolateDeviceIds}` - Device IDs to isolate (user input)
- `{IsolationType}` - Isolation type selection (dropdown)
- `{FileIndicators}` - File hashes (user input)
- `{UpdateIncidentId}` - Incident ID (user input)
- etc.

## Notes

1. **Query Type**: Always use `0` for Custom Endpoint queries
2. **Resource Type**: Always use `microsoft.customendpoint/endpoints`
3. **Headers**: Always include `Content-Type: application/json`
4. **Body**: Must be valid JSON with escaped quotes in the workbook JSON
5. **JSONPath**: Table path must point to an array (use `[*]` selector)
6. **Column IDs**: Must be unique and match the column path
7. **Auto-refresh**: Optional, only enable for queries that benefit from polling
8. **Parameters**: Use `{ParameterName}` syntax for dynamic values

## References

- [Main Documentation](./WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md)
- [Azure Workbooks JSONPath](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-transformations)
- [Custom Endpoints](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-data-sources#custom-endpoint)

---

**Version**: 1.0  
**Last Updated**: 2025-10-11
