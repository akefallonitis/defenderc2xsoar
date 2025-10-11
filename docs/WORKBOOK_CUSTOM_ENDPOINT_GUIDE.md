# DefenderC2 Custom Endpoint Workbook Guide

## Overview

This guide provides comprehensive instructions for using the **DefenderC2-Working-CustomEndpoint.json** workbook, which implements a fully functional DefenderC2 Command & Control Console using **Custom Endpoint** data sources with auto-refresh capabilities and direct Function App HTTP calls for ARM Actions.

## 🎯 Key Features

- ✅ **Custom Endpoint** data source (not ARMEndpoint) for all queries
- ✅ **Auto-refresh** capability (30-second intervals)
- ✅ **Direct Function App calls** for ARM Actions
- ✅ **JSONPath transformers** for response parsing
- ✅ **All core tabs** implemented (7 tabs total)
- ✅ **Proper parameter passing** (action, tenantId, etc.)

## 📋 Requirements

### Azure Resources
- Azure Function App with DefenderC2 functions deployed
- Log Analytics Workspace (for parameter auto-discovery)
- Azure Subscription with appropriate permissions

### Function App Endpoints Used
| Endpoint | Purpose | Used In Tabs |
|----------|---------|--------------|
| `DefenderC2Dispatcher` | Device actions, isolation, scans | Device Manager, Action Manager |
| `DefenderC2TIManager` | Threat intelligence indicators | Threat Intel Manager |
| `DefenderC2HuntManager` | Advanced hunting queries | Hunt Manager |
| `DefenderC2IncidentManager` | Security incidents management | Incident Manager |
| `DefenderC2CDManager` | Custom detection rules | Detection Manager |
| `DefenderC2Orchestrator` | Command orchestration | Console |

## 🚀 Deployment Instructions

### Step 1: Import the Workbook

1. Navigate to **Azure Portal** → **Monitor** → **Workbooks**
2. Click **+ New** or **+ Create**
3. Click **Advanced Editor** (</> icon in toolbar)
4. Replace entire content with `DefenderC2-Working-CustomEndpoint.json`
5. Click **Apply**
6. Click **Done Editing**
7. Click **Save** and provide:
   - **Title**: DefenderC2 Custom Endpoint Console
   - **Subscription**: Your subscription
   - **Resource Group**: Your resource group
   - **Location**: Your region

### Step 2: Configure Parameters

After importing, you need to configure the workbook parameters:

1. **Subscription**: Select your Azure subscription
2. **Workspace**: Select your Log Analytics workspace
3. **TenantId**: Auto-populated from workspace
4. **FunctionAppName**: Enter your Function App name (e.g., `defc2`, `mydefender`)

## 🔧 Custom Endpoint Configuration

### Understanding Custom Endpoint Queries

Unlike ARMEndpoint queries, Custom Endpoint queries require manual configuration in the Azure Portal UI. Each query section needs to be configured with:

#### Required Settings

1. **Query Type**: Custom Endpoint
2. **HTTP Method**: POST
3. **URL**: `https://{FunctionAppName}.azurewebsites.net/api/[EndpointName]`
4. **Headers**: `Content-Type: application/json`
5. **Body**: JSON with `action` and `tenantId` parameters
6. **Result Format**: JSON with JSONPath transformers
7. **Auto-refresh** (optional): Enable with 30-second interval

### Configuration Process (Per Query)

For each Custom Endpoint query in the workbook:

1. **Open Query Editor**:
   - Click the query section you want to configure
   - Click **Edit** (pencil icon)

2. **Settings Tab**:
   - **Query Type**: Select "Custom Endpoint"
   - **Http Method**: Select "POST"
   - **URL**: Enter full URL with parameter interpolation
     - Example: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`

3. **Headers Tab**:
   - Click **+ Add header**
   - **Name**: `Content-Type`
   - **Value**: `application/json`

4. **Body Tab**:
   - **Body format**: Select "JSON"
   - **Body content**: Enter JSON request
     ```json
     {
       "action": "Get Devices",
       "tenantId": "{TenantId}"
     }
     ```

5. **Result Settings Tab**:
   - **Result format**: JSON
   - **JSONPath**: Define table path and columns
     - **Table path**: `$.devices[*]` (adjust based on response structure)
     - **Columns**: Add columns for each field
       - Path: `$.id`, Column ID: `id`
       - Path: `$.computerDnsName`, Column ID: `computerDnsName`
       - etc.

6. **Advanced Settings Tab** (for auto-refresh queries):
   - Enable **Auto-refresh**
   - **Refresh interval**: 30 seconds
   - **Run on load**: Yes

7. **Save Changes**:
   - Click **Done Editing**
   - Verify the query executes successfully

## 📊 Tab-by-Tab Configuration

### 1. 🖥️ Device Manager Tab

**Purpose**: View and manage devices with auto-refresh

#### Device List Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher

Headers:
  Content-Type: application/json

Body:
{
  "action": "Get Devices",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.devices[*]
  Columns:
    - $.id → id
    - $.computerDnsName → computerDnsName
    - $.isolationState → isolationState
    - $.healthStatus → healthStatus
    - $.riskScore → riskScore
    - $.exposureLevel → exposureLevel
    - $.lastSeen → lastSeen
    - $.osPlatform → osPlatform

Auto-refresh: Enabled (30 seconds)
```

#### ARM Actions

**Isolate Device**:
- Direct POST to Function App
- URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`
- Body: `{"action":"Isolate Device","tenantId":"{TenantId}","deviceIds":"{IsolateDeviceIds}","isolationType":"{IsolationType}","comment":"Isolated via Custom Endpoint Workbook"}`

### 2. 🔍 Threat Intel Manager Tab

**Purpose**: Manage threat intelligence indicators

#### List Indicators Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager

Headers:
  Content-Type: application/json

Body:
{
  "action": "List Indicators",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.indicators[*]
  Columns:
    - $.id → id
    - $.indicatorValue → indicatorValue
    - $.indicatorType → indicatorType
    - $.action → action
    - $.severity → severity
    - $.title → title
    - $.creationTime → creationTime

Auto-refresh: Not enabled
```

#### ARM Actions

**Add File Indicators**:
- URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager`
- Body: `{"action":"Add File Indicators","tenantId":"{TenantId}","indicators":"{FileIndicators}","indicatorAction":"{FileIndicatorAction}","severity":"High","title":"File Indicators","description":"Added via Custom Endpoint Workbook"}`

### 3. ⚡ Action Manager Tab

**Purpose**: Track and manage machine actions

#### Get All Actions Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher

Headers:
  Content-Type: application/json

Body:
{
  "action": "Get All Actions",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.actions[*]
  Columns:
    - $.id → id
    - $.type → type
    - $.status → status
    - $.requestor → requestor
    - $.creationDateTimeUtc → created
    - $.lastUpdateDateTimeUtc → lastUpdated

Auto-refresh: Not enabled (can be enabled if desired)
```

### 4. 🎯 Hunt Manager Tab

**Purpose**: Advanced hunting queries

#### Get Hunt Status Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager

Headers:
  Content-Type: application/json

Body:
{
  "action": "Get Hunt Status",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.hunts[*]
  Columns:
    - $.id → id
    - $.query → query
    - $.status → status
    - $.createdTime → createdTime
    - $.resultCount → resultCount

Auto-refresh: Not enabled
```

### 5. 🚨 Incident Manager Tab

**Purpose**: Security incidents management

#### Get Incidents Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager

Headers:
  Content-Type: application/json

Body:
{
  "action": "GetIncidents",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.incidents[*]
  Columns:
    - $.incidentId → incidentId
    - $.incidentName → incidentName
    - $.severity → severity
    - $.status → status
    - $.createdTime → createdTime
    - $.lastUpdateTime → lastUpdateTime

Auto-refresh: Not enabled
```

#### ARM Actions

**Update Incident**:
- URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager`
- Body: `{"action":"Update Incident","tenantId":"{TenantId}","incidentId":"{UpdateIncidentId}","status":"{UpdateStatus}"}`

### 6. 🛡️ Detection Manager Tab

**Purpose**: Custom detection rules management

#### List Detections Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager

Headers:
  Content-Type: application/json

Body:
{
  "action": "List Detections",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.detections[*]
  Columns:
    - $.id → id
    - $.ruleName → ruleName
    - $.severity → severity
    - $.enabled → enabled
    - $.createdBy → createdBy
    - $.lastModified → lastModified

Auto-refresh: Not enabled
```

#### ARM Actions

**Create Detection Rule**:
- URL: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager`
- Body: `{"action":"Create Detection","tenantId":"{TenantId}","ruleName":"{CreateRuleName}","query":"{CreateRuleQuery}","severity":"{CreateRuleSeverity}"}`

### 7. 💻 Console Tab

**Purpose**: Command history and orchestration

#### Get Command History Query Configuration

```json
Query Type: Custom Endpoint
HTTP Method: POST
URL: https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Orchestrator

Headers:
  Content-Type: application/json

Body:
{
  "action": "Get Command History",
  "tenantId": "{TenantId}"
}

JSONPath:
  Table Path: $.commands[*]
  Columns:
    - $.id → id
    - $.command → command
    - $.status → status
    - $.executedBy → executedBy
    - $.executedTime → executedTime
    - $.result → result

Auto-refresh: Not enabled
```

## 🔑 Key Differences from ARMEndpoint

### ARMEndpoint Workbook
- Uses `queryType: 12` with ARMEndpoint/1.0
- Configuration embedded in JSON query string
- Auto-refresh settings in JSON structure
- JSONPath transformers in query definition

### Custom Endpoint Workbook
- Uses `queryType: 0` with `microsoft.customendpoint/endpoints`
- Configuration done via Azure Portal UI
- Must manually set URL, headers, body, JSONPath
- Auto-refresh configured in Advanced Settings

## 📝 Sample Query Structure

Here's the complete structure for a Custom Endpoint query as it appears in the workbook JSON:

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"queryType\":0,\"resourceType\":\"microsoft.customendpoint/endpoints\",\"httpSettings\":{\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"}]}}]},\"refreshSettings\":{\"isAutoRefreshEnabled\":true,\"autoRefreshInterval\":\"30\"}}",
    "size": 0,
    "title": "Device List (Custom HTTP Auto-Refresh)",
    "queryType": 0,
    "resourceType": "microsoft.customendpoint/endpoints",
    "visualization": "table"
  },
  "name": "query - get-devices"
}
```

## 🔍 Troubleshooting

### Query Returns "Please enter a cluster name"
**Solution**: This is expected with Custom Endpoint queries in Azure Portal. Click **Edit** and configure via UI as described above.

### Query Returns "An unknown error has occurred"
**Possible causes**:
1. Function App name is incorrect
2. Function App is not accessible
3. Headers not configured correctly
4. Body format is invalid JSON

**Solution**:
1. Verify FunctionAppName parameter is correct
2. Test Function App URL in browser or Postman
3. Ensure Content-Type header is set
4. Validate JSON body format

### Auto-refresh Not Working
**Solution**:
1. Open query in edit mode
2. Go to **Advanced Settings** tab
3. Enable **Auto-refresh**
4. Set interval to 30 seconds
5. Save changes

### ARM Actions Not Working
**Possible causes**:
1. Parameter values not filled in
2. Function App authentication issues
3. Network connectivity problems

**Solution**:
1. Fill in required parameters before clicking action button
2. Verify Function App allows unauthenticated access or configure authentication
3. Check network security rules

## ✅ Acceptance Criteria Checklist

- ✅ Fully working workbook file using Custom Endpoint
- ✅ Auto-refresh capability (Device Manager tab)
- ✅ Direct Function App calls for ARM Actions
- ✅ All core tabs implemented:
  - ✅ Device Manager (with auto-refresh)
  - ✅ Threat Intel Manager
  - ✅ Action Manager
  - ✅ Hunt Manager
  - ✅ Incident Manager
  - ✅ Detection Manager
  - ✅ Console
- ✅ Correct parameter passing (action, tenantId, etc.)
- ✅ JSONPath transformers for response parsing
- ✅ Sample sections and instructions included
- ✅ Documentation guide created

## 📚 Related Documentation

- [Workbook Parameters Guide](../deployment/WORKBOOK_PARAMETERS_GUIDE.md)
- [Dynamic Function App Name](../deployment/DYNAMIC_FUNCTION_APP_NAME.md)
- [Workbook API Fix Summary](../WORKBOOK_API_FIX_SUMMARY.md)

## 🎓 Learning Resources

### Azure Workbooks Documentation
- [Azure Workbooks Overview](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [Custom Endpoints in Workbooks](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-data-sources#custom-endpoint)
- [JSONPath Transformers](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-transformations)

### DefenderC2 Resources
- [DefenderC2 Repository](https://github.com/akefallonitis/defenderc2xsoar)
- [Deployment Quickstart](../DEPLOYMENT_QUICKSTART.md)
- [Repository Structure](../REPOSITORY_STRUCTURE.md)

## 💡 Tips and Best Practices

1. **Always test queries** in edit mode before saving
2. **Use auto-refresh sparingly** to avoid rate limiting
3. **Monitor Function App logs** for debugging
4. **Keep parameter names consistent** across queries
5. **Document custom modifications** for team members
6. **Test ARM actions** in non-production environment first
7. **Regular backups** of workbook configuration

## 🆘 Support

For issues or questions:
1. Check [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
2. Review existing documentation in `/docs` and `/deployment` folders
3. Submit new issue with workbook configuration and error details

## 📄 License

This workbook is part of the DefenderC2 project and follows the same license terms.

---

**Last Updated**: 2025-10-11  
**Version**: 1.0  
**Author**: DefenderC2 Team
