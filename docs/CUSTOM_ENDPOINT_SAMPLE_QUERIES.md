# DefenderC2 Workbook: Custom Endpoint & ARM Action Sample Queries

This document provides example JSON queries and UI setup for each functional tab in the DefenderC2 workbook.

---

## Device Manager Tab
### Custom Endpoint Query (with autopopulated parameters)
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

### ARM Action (Isolate Device, autopopulated)
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

### ARM Action (Management API, with api-version)
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

## Threat Intel Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
    "body": "{\"action\":\"List Indicators\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.indicators[*]",
          "columns": [
            {"path": "$.indicatorId", "columnid": "indicatorId"},
            {"path": "$.type", "columnid": "type"},
            {"path": "$.value", "columnid": "value"},
            {"path": "$.threatType", "columnid": "threatType"},
            {"path": "$.lastUpdated", "columnid": "lastUpdated"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## Action Manager Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2ActionManager",
    "body": "{\"action\":\"List Actions\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.actions[*]",
          "columns": [
            {"path": "$.actionId", "columnid": "actionId"},
            {"path": "$.name", "columnid": "name"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.created", "columnid": "created"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## Hunt Manager Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager",
    "body": "{\"action\":\"List Hunts\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.hunts[*]",
          "columns": [
            {"path": "$.huntId", "columnid": "huntId"},
            {"path": "$.name", "columnid": "name"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.started", "columnid": "started"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## Incident Manager Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager",
    "body": "{\"action\":\"List Incidents\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.incidents[*]",
          "columns": [
            {"path": "$.incidentId", "columnid": "incidentId"},
            {"path": "$.title", "columnid": "title"},
            {"path": "$.severity", "columnid": "severity"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.created", "columnid": "created"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## Detection Manager Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2DetectionManager",
    "body": "{\"action\":\"List Detections\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.detections[*]",
          "columns": [
            {"path": "$.detectionId", "columnid": "detectionId"},
            {"path": "$.type", "columnid": "type"},
            {"path": "$.status", "columnid": "status"},
            {"path": "$.created", "columnid": "created"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

## Console Tab
### Custom Endpoint Query (with autopopulated parameters)
```json
{
  "queryType": 0,
  "resourceType": "microsoft.customendpoint/endpoints",
  "httpSettings": {
    "method": "POST",
    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Console",
    "body": "{\"action\":\"Get Console Status\",\"tenantId\":\"{TenantId}\"}",
    "headers": [ { "name": "Content-Type", "value": "application/json" } ],
    "transformers": [
      {
        "type": "jsonpath",
        "settings": {
          "tablePath": "$.console[*]",
          "columns": [
            {"path": "$.status", "columnid": "status"},
            {"path": "$.lastUpdated", "columnid": "lastUpdated"}
          ]
        }
      }
    ]
  },
  "refreshSettings": { "isAutoRefreshEnabled": true, "autoRefreshInterval": "30" }
}
```

---

**Reference this file for sample queries and UI setup for each tab.**
