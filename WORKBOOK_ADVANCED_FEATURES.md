# Advanced Workbook Features Implementation

This document describes the advanced features implemented in the MDEAutomatorWorkbook following Microsoft best practices.

## 📋 Overview

The workbook has been completely rebuilt to follow Microsoft's best practices for Azure Workbooks, incorporating:

1. **Azure Resource Graph (ARG) Auto-Discovery**
2. **ARM Actions** for synchronous operations
3. **Custom Endpoints** for asynchronous operations with auto-refresh
4. **JSONPath output parsing** for all responses
5. **Multi-tenancy support** with automatic TenantId injection

Reference: https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-jsonpath

## 🔧 Parameter Auto-Discovery

All key parameters now use Azure Resource Graph queries for automatic discovery:

### Subscription Parameter
```json
{
  "name": "Subscription",
  "type": 6,
  "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | summarize by subscriptionId",
  "crossComponentResources": ["value::all"]
}
```

### Workspace Parameter
```json
{
  "name": "Workspace",
  "type": 5,
  "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | project id, name, location",
  "crossComponentResources": ["{Subscription}"]
}
```

### TenantId Parameter (Auto-Discovered)
```json
{
  "name": "TenantId",
  "type": 1,
  "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | where id == '{Workspace}' | project tenantId",
  "crossComponentResources": ["{Subscription}"],
  "isHiddenWhenLocked": true
}
```

### FunctionKey Parameter
```json
{
  "name": "FunctionKey",
  "type": 1,
  "isRequired": true,
  "description": "Function App host key or function-specific key for authentication"
}
```

## 📑 Tab Implementations

### Tab 1: MDEAutomator - Device Actions

#### Isolate Device (ARM Action)
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "🚨 Isolate Devices",
      "armActionContext": {
        "path": "{FunctionAppUrl}/api/MDEDispatcher?code={FunctionKey}",
        "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"spnId\":\"{SpnId}\",\"deviceIds\":\"{IsolateDeviceIds}\",\"isolationType\":\"{IsolationType}\"}",
        "httpMethod": "POST"
      }
    }]
  }
}
```

#### Get Devices (Custom Endpoint with JSONPath)
```json
{
  "query": "{\"version\":\"ARMEndpoint/1.0\",\"method\":\"POST\",\"path\":\"{FunctionAppUrl}/api/MDEDispatcher?code={FunctionKey}\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\",\\\"spnId\\\":\\\"{SpnId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.deviceName\",\"columnId\":\"Device Name\"},{\"path\":\"$.riskScore\",\"columnId\":\"Risk Score\"}]}}]}"
}
```

**Actions Implemented:**
- ✅ Isolate Device (ARM Action)
- ✅ Unisolate Device (ARM Action)
- ✅ Restrict App Execution (ARM Action)
- ✅ Run Antivirus Scan (ARM Action)
- ✅ Get Devices (Custom Endpoint with JSONPath)

### Tab 2: Threat Intel Manager

#### Add File Indicators (Batch with ARM Action)
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "{FunctionAppUrl}/api/MDETIManager?code={FunctionKey}",
    "body": "{\"action\":\"Add File Indicators\",\"tenantId\":\"{TenantId}\",\"spnId\":\"{SpnId}\",\"indicators\":\"{FileIndicators}\",\"indicatorAction\":\"{FileIndicatorAction}\",\"severity\":\"{FileSeverity}\"}",
    "httpMethod": "POST"
  }
}
```

#### List Indicators (Custom Endpoint with JSONPath)
```json
{
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.indicators[*]",
      "columns": [
        {"path": "$.indicatorValue", "columnId": "Indicator"},
        {"path": "$.indicatorType", "columnId": "Type"},
        {"path": "$.action", "columnId": "Action"},
        {"path": "$.severity", "columnId": "Severity"}
      ]
    }
  }]
}
```

**Actions Implemented:**
- ✅ Add File Indicators (batch)
- ✅ Add IP Indicators (batch)
- ✅ Add URL/Domain Indicators (batch)
- ✅ List All Indicators with JSONPath

### Tab 3: Action Manager

#### Get All Actions (Auto-Refresh)
```json
{
  "query": "{\"version\":\"ARMEndpoint/1.0\",\"autoRefresh\":true,\"refreshInterval\":{RefreshInterval},\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.actions[*]\",\"columns\":[{\"path\":\"$.id\",\"columnId\":\"Action ID\"},{\"path\":\"$.type\",\"columnId\":\"Type\"},{\"path\":\"$.status\",\"columnId\":\"Status\"}]}}]}"
}
```

**Features:**
- ✅ Auto-refresh (10s, 30s, 60s, 300s intervals)
- ✅ Status filtering
- ✅ Get Action Status with JSONPath
- ✅ Cancel Action with ARM Action

### Tab 4: Hunt Manager

#### Execute Hunt (Async with Auto-Refresh)
```json
{
  "query": "{\"version\":\"ARMEndpoint/1.0\",\"autoRefresh\":true,\"refreshInterval\":{HuntRefreshInterval},\"refreshCondition\":\"$.status != 'Completed'\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.results[*]\",\"columns\":[{\"path\":\"$.DeviceName\",\"columnId\":\"Device Name\"},{\"path\":\"$.Timestamp\",\"columnId\":\"Timestamp\"}]}}]}"
}
```

**Features:**
- ✅ Sample query templates dropdown
- ✅ Multi-line KQL editor
- ✅ Async execution with polling
- ✅ Auto-refresh until completion
- ✅ JSONPath result parsing
- ✅ Hunt status monitoring

### Tab 5: Incident Manager

#### Get Incidents (With Filters)
```json
{
  "body": "{\"action\":\"Get Incidents\",\"tenantId\":\"{TenantId}\",\"spnId\":\"{SpnId}\",\"severity\":\"{IncidentSeverity}\",\"status\":\"{IncidentStatus}\"}",
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.incidents[*]",
      "columns": [
        {"path": "$.incidentId", "columnId": "Incident ID"},
        {"path": "$.severity", "columnId": "Severity"},
        {"path": "$.status", "columnId": "Status"}
      ]
    }
  }]
}
```

**Features:**
- ✅ Severity filtering (Informational, Low, Medium, High)
- ✅ Status filtering (Active, Resolved, InProgress, Redirected)
- ✅ Update Incident with ARM Action
- ✅ Add Comment with ARM Action
- ✅ Color-coded severity and status

### Tab 6: Custom Detection Manager

#### List Detections (JSONPath)
```json
{
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.detections[*]",
      "columns": [
        {"path": "$.id", "columnId": "ID"},
        {"path": "$.displayName", "columnId": "Name"},
        {"path": "$.severity", "columnId": "Severity"},
        {"path": "$.enabled", "columnId": "Enabled"}
      ]
    }
  }]
}
```

**Features:**
- ✅ List All Detections with JSONPath
- ✅ Create Detection with ARM Action
- ✅ Update Detection with ARM Action
- ✅ Delete Detection with ARM Action
- ✅ Backup Detections for export

### Tab 7: Interactive Console

**Status:** Already implemented with 11 items (unchanged)

## 🎯 Multi-Tenancy Support

All API calls include automatic TenantId injection:

```json
{
  "body": "{\"action\":\"<ActionType>\",\"tenantId\":\"{TenantId}\",\"spnId\":\"{SpnId}\",\"deviceIds\":\"{DeviceIds}\"}"
}
```

The TenantId is automatically discovered from the selected workspace via Azure Resource Graph and hidden from the user interface.

## 📊 JSONPath Parsing Examples

### Parse Device List
```json
{
  "tablePath": "$.devices[*]",
  "columns": [
    {"path": "$.deviceName", "columnId": "Device Name"},
    {"path": "$.riskScore", "columnId": "Risk Score"},
    {"path": "$.healthStatus", "columnId": "Health Status"},
    {"path": "$.lastIpAddress", "columnId": "Last IP"},
    {"path": "$.lastSeen", "columnId": "Last Seen"}
  ]
}
```

### Parse Action Status
```json
{
  "tablePath": "$.actions[*]",
  "columns": [
    {"path": "$.id", "columnId": "Action ID"},
    {"path": "$.type", "columnId": "Type"},
    {"path": "$.status", "columnId": "Status"},
    {"path": "$.requestor", "columnId": "Requestor"},
    {"path": "$.creationDateTimeUtc", "columnId": "Created"}
  ]
}
```

### Parse Hunt Results with Filtering
```json
{
  "tablePath": "$.results[?(@.AlertSeverity == 'High')]",
  "columns": [
    {"path": "$.DeviceName", "columnId": "Device"},
    {"path": "$.AlertTitle", "columnId": "Alert"},
    {"path": "$.AlertSeverity", "columnId": "Severity"},
    {"path": "$.Timestamp", "columnId": "Time"}
  ]
}
```

## 🔄 Auto-Refresh Implementation

Custom endpoints support auto-refresh with configurable intervals:

```json
{
  "autoRefresh": true,
  "refreshInterval": 30,
  "refreshCondition": "$.status != 'Completed'"
}
```

This enables:
- Automatic polling for async operations
- Configurable refresh rates (10s, 30s, 60s, 300s)
- Conditional refresh (stop when status = Completed)

## 📝 Example Payloads

### Isolate Device
```json
{
  "action": "Isolate Device",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "spnId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  "deviceIds": "device-id-1,device-id-2",
  "isolationType": "Full",
  "comment": "Isolated due to suspicious activity"
}
```

### Add TI Indicators
```json
{
  "action": "Add File Indicators",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "spnId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  "indicators": "hash1,hash2,hash3",
  "indicatorAction": "Block",
  "severity": "High",
  "title": "Malicious files",
  "description": "Known malware hashes"
}
```

### Execute Hunt
```json
{
  "action": "Execute Hunt",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "spnId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  "query": "DeviceEvents | where Timestamp > ago(24h) | where ActionType == 'ProcessCreated' | take 100"
}
```

## ✅ Validation Checklist

- [x] All parameters use ARG queries for auto-discovery
- [x] TenantId automatically populated from workspace
- [x] FunctionKey parameter added for authentication
- [x] All ARM Actions use proper body payloads
- [x] All Custom Endpoints include JSONPath transformers
- [x] Multi-tenancy supported with TenantId injection
- [x] Auto-refresh implemented for async operations
- [x] All 7 tabs fully functional
- [x] JSON structure validated
- [x] Production-ready

## 🚀 Deployment

1. Import the workbook JSON into Azure Portal
2. Configure parameters:
   - Select Subscription (auto-discovered)
   - Select Workspace (auto-discovered)
   - Enter Function App URL
   - Enter Service Principal ID
   - Enter Function Key
3. TenantId will be automatically discovered
4. Start using the workbook!

## 📚 References

- [Workbooks JSONPath Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-jsonpath)
- [Workbooks ARM Actions](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-arm)
- [Azure Workbooks Overview](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Resource Graph Queries](https://learn.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language)
