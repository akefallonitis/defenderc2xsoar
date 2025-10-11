# DefenderC2 Workbook - Custom Endpoint Auto-Refresh & ARM Actions Guide

## 📋 Overview

This comprehensive guide provides step-by-step instructions for implementing **Custom Endpoint** queries with auto-refresh and **ARM Actions** for direct Function App HTTP calls in the DefenderC2 workbook.

### What You'll Learn
- How to configure Custom Endpoint queries for auto-refresh
- How to configure ARM Actions for direct Function App HTTP calls
- How to pass correct parameters (action, tenantId, etc.)
- How to set up JSONPath transformers for output parsing
- How to implement all 7 functional tabs
- How to enable auto-refresh (recommended: 30s interval)
- Troubleshooting and validation steps

### Prerequisites
- Azure subscription with appropriate permissions
- DefenderC2 Function App deployed and running
- Log Analytics workspace configured
- Microsoft Defender for Endpoint API permissions granted

---

## 🎯 Quick Start

### Step 1: Import the Workbook
1. Navigate to **Azure Portal** → **Monitor** → **Workbooks**
2. Click **+ New** or open existing DefenderC2 workbook
3. Click **Edit** → **Advanced Editor**

### Step 2: Configure Parameters
The workbook requires these parameters to be configured:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| **FunctionAppName** | Text | Yes | Name of your Azure Function App (e.g., `defc2`) |
| **Subscription** | Dropdown | Yes | Azure subscription (auto-discovered) |
| **Workspace** | Dropdown | Yes | Log Analytics workspace (auto-discovered) |
| **TenantId** | Text | Auto | Azure AD Tenant ID (auto-discovered from workspace) |

**Example**: If your Function App URL is `https://mydefenderc2.azurewebsites.net`, enter `mydefenderc2` as the **FunctionAppName**.

---

## 📡 Custom Endpoint Configuration

### What is Custom Endpoint?

Custom Endpoint is a query type in Azure Workbooks that allows you to call external HTTP endpoints (like Azure Functions) and display the results in the workbook. It supports:
- Auto-refresh for real-time data updates
- JSONPath transformers for parsing complex JSON responses
- POST/GET/PUT/DELETE methods
- Custom headers and request bodies

### Basic Custom Endpoint Structure

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
            {"path": "$.computerDnsName", "columnid": "computerDnsName"}
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

To configure a Custom Endpoint query in the Azure Workbook UI:

1. **Add a new query item** or edit existing query
2. **Change Query Type** to `Custom Endpoint`
3. **Configure HTTP Settings**:
   - **HTTP Method**: `POST`
   - **URL**: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`
   - **Headers**: Add `Content-Type: application/json`
   - **Body**: `{"action":"Get Devices","tenantId":"{TenantId}"}`

4. **Configure Result Settings** (JSONPath):
   - Click **Result Settings** tab
   - Set **Table Path**: `$.devices[*]`
   - Define columns:
     - Column 1: Path `$.id`, Column ID `id`
     - Column 2: Path `$.computerDnsName`, Column ID `computerDnsName`
     - Column 3: Path `$.isolationState`, Column ID `isolationState`
     - (Add more columns as needed)

5. **Enable Auto-Refresh**:
   - Toggle **Auto-refresh** to ON
   - Set **Interval**: `30` seconds

6. Click **Done Editing** → **Save**

### Screenshots Reference

![Custom Endpoint Configuration](https://github.com/user-attachments/assets/97097e6b-64a7-454c-85ac-8ed4603ba822)
*Figure 1: Custom Endpoint query editor showing URL, Headers, and Body configuration*

---

## 🎯 ARM Actions Configuration

### What are ARM Actions?

ARM Actions are clickable buttons in Azure Workbooks that trigger HTTP requests to Azure Functions or other endpoints. Unlike Custom Endpoints (which display data), ARM Actions are used for:
- Device isolation/unisolation
- Running antivirus scans
- Submitting threat indicators
- Managing incidents
- Creating/updating custom detections

### Basic ARM Action Structure

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "isolate-device-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🚨 Isolate Devices",
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
          "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
          "httpMethod": "POST"
        }
      }
    ]
  }
}
```

### UI Configuration Steps

To configure an ARM Action in the Azure Workbook UI:

1. **Add a new Links item** or edit existing link
2. **Set Link Target** to `ARM Action`
3. **Configure ARM Action Context**:
   - **Path**: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`
   - **HTTP Method**: `POST`
   - **Headers**: Add `Content-Type: application/json`
   - **Body**: `{"action":"Isolate Device","tenantId":"{TenantId}","deviceIds":"{DeviceIds}"}`

4. **Customize Button**:
   - **Label**: `🚨 Isolate Devices`
   - **Style**: `primary` (blue) or `secondary` (gray)

5. Click **Done Editing** → **Save**

### Critical: Content-Type Header

⚠️ **IMPORTANT**: The `Content-Type: application/json` header is **REQUIRED** for all ARM Actions. Without it, Azure Functions cannot parse the JSON body and all requests will fail silently.

**Correct Configuration:**
```json
"headers": [
  {
    "name": "Content-Type",
    "value": "application/json"
  }
]
```

**Incorrect Configuration (will fail):**
```json
"headers": []  // ❌ Empty - Missing Content-Type
```

### Screenshots Reference

![ARM Action Configuration](https://github.com/user-attachments/assets/d113dfc8-e263-4201-8ba5-7626da2d8e39)
*Figure 2: ARM Action dialog showing the Isolate Devices action with error handling*

---

## 🔄 Auto-Refresh Configuration

### Why Auto-Refresh?

Auto-refresh is essential for:
- **Real-time monitoring** of device status and security posture
- **Tracking long-running operations** (e.g., antivirus scans, advanced hunting queries)
- **Detecting changes** in incidents, alerts, or threat indicators
- **Continuous updates** without manual page refresh

### Recommended Auto-Refresh Intervals

| Query Type | Interval | Use Case |
|------------|----------|----------|
| Device List | 30s | Real-time device status monitoring |
| Machine Actions | 30s | Track action progress (pending → completed) |
| Security Incidents | 60s | Monitor new and updated incidents |
| Threat Indicators | 60s | Track indicator submissions |
| Hunt Results | 30s | Monitor query execution until completion |
| Custom Detections | 120s | Monitor detection rule changes |

### Enabling Auto-Refresh in UI

1. Edit the query item
2. Go to **Settings** tab
3. Toggle **Auto-refresh** to **ON**
4. Set **Interval** to `30` seconds (or as needed)
5. (Optional) Set **Condition** to stop refresh after specific criteria

### Auto-Refresh JSON Configuration

```json
{
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": ""  // Leave empty for continuous refresh
  }
}
```

### Conditional Auto-Refresh

Stop refreshing when a specific condition is met (e.g., hunt query completed):

```json
{
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "{Status} == 'Completed'"
  }
}
```

---

## 📊 JSONPath Transformers

### What is JSONPath?

JSONPath is a query language for JSON, similar to XPath for XML. Azure Workbooks use JSONPath to extract and transform data from API responses into tabular format for display.

### Basic JSONPath Syntax

| Expression | Description | Example |
|------------|-------------|---------|
| `$` | Root object | `$` |
| `$.field` | Field access | `$.deviceName` |
| `$[*]` | All array elements | `$[*]` |
| `$.array[*]` | All elements in array | `$.devices[*]` |
| `$.array[0]` | First element | `$.devices[0]` |
| `$..field` | Recursive descent | `$..id` |

### JSONPath Transformer Structure

```json
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
```

### Example API Responses and JSONPath

**Example Response: Get Devices**
```json
{
  "devices": [
    {
      "id": "abc123",
      "computerDnsName": "DESKTOP-001",
      "isolationState": "NotIsolated",
      "healthStatus": "Active",
      "riskScore": "High",
      "exposureLevel": "Medium",
      "lastSeen": "2025-10-11T12:00:00Z",
      "osPlatform": "Windows10"
    }
  ]
}
```

**JSONPath Configuration:**
- **Table Path**: `$.devices[*]` (iterate through all devices)
- **Columns**: Extract specific fields using `$.fieldName`

### Configuring JSONPath in UI

1. Edit Custom Endpoint query
2. Go to **Result Settings** tab
3. Select **Transformer Type**: `JSONPath`
4. Set **Table Path**: `$.devices[*]`
5. Click **+ Add Column** for each field:
   - **Path**: `$.id`
   - **Column ID**: `id`
   - **Display Name**: `Device ID`
6. Repeat for all fields
7. Click **Done**

---

## 🗂️ Function Endpoints Reference

### Endpoint Overview

The DefenderC2 solution uses multiple Azure Function endpoints, each handling specific operations:

| Function Endpoint | Purpose | Used In Tabs |
|-------------------|---------|--------------|
| **DefenderC2Dispatcher** | Device actions, isolation, scans | Device Manager, Action Manager, Console |
| **DefenderC2TIManager** | Threat intelligence indicators | Threat Intel Manager |
| **DefenderC2IncidentManager** | Security incidents management | Incident Manager |
| **DefenderC2HuntManager** | Advanced hunting queries | Hunt Manager |
| **DefenderC2CDManager** | Custom detection rules | Detection Manager |
| **DefenderC2Orchestrator** | File operations (FileOps workbook) | File Operations |

### DefenderC2Dispatcher Actions

```json
// Get Devices
{"action": "Get Devices", "tenantId": "{TenantId}"}

// Isolate Device
{"action": "Isolate Device", "tenantId": "{TenantId}", "deviceIds": "{DeviceIds}"}

// Release from Isolation
{"action": "Release Device", "tenantId": "{TenantId}", "deviceIds": "{DeviceIds}"}

// Run Antivirus Scan
{"action": "Run Antivirus Scan", "tenantId": "{TenantId}", "deviceIds": "{DeviceIds}"}

// Stop and Quarantine File
{"action": "Stop and Quarantine File", "tenantId": "{TenantId}", "deviceIds": "{DeviceIds}", "sha1": "{SHA1}"}

// Get Machine Actions
{"action": "Get Machine Actions", "tenantId": "{TenantId}"}

// Cancel Action
{"action": "Cancel Action", "tenantId": "{TenantId}", "actionId": "{ActionId}"}
```

### DefenderC2TIManager Actions

```json
// List Indicators
{"action": "List Indicators", "tenantId": "{TenantId}"}

// Submit File Indicator
{"action": "Submit Indicator", "tenantId": "{TenantId}", "indicatorType": "FileSha1", "indicatorValue": "{SHA1}", "action": "Alert", "severity": "High"}

// Submit IP Indicator
{"action": "Submit Indicator", "tenantId": "{TenantId}", "indicatorType": "IpAddress", "indicatorValue": "{IPAddress}", "action": "AlertAndBlock", "severity": "High"}

// Submit URL Indicator
{"action": "Submit Indicator", "tenantId": "{TenantId}", "indicatorType": "Url", "indicatorValue": "{URL}", "action": "Alert", "severity": "Medium"}
```

### DefenderC2IncidentManager Actions

```json
// List Incidents
{"action": "List Incidents", "tenantId": "{TenantId}"}

// Update Incident
{"action": "Update Incident", "tenantId": "{TenantId}", "incidentId": "{IncidentId}", "status": "Resolved"}

// Add Comment
{"action": "Add Comment", "tenantId": "{TenantId}", "incidentId": "{IncidentId}", "comment": "{Comment}"}
```

### DefenderC2HuntManager Actions

```json
// Run Hunt Query
{"action": "Run Hunt", "tenantId": "{TenantId}", "huntQuery": "{HuntQuery}"}

// Get Hunt Results
{"action": "Get Hunt Results", "tenantId": "{TenantId}", "huntId": "{HuntId}"}
```

### DefenderC2CDManager Actions

```json
// List Custom Detections
{"action": "List Detections", "tenantId": "{TenantId}"}

// Create Detection
{"action": "Create Detection", "tenantId": "{TenantId}", "displayName": "{Name}", "query": "{KQL}", "severity": "High"}

// Update Detection
{"action": "Update Detection", "tenantId": "{TenantId}", "ruleId": "{RuleId}", "enabled": true}

// Delete Detection
{"action": "Delete Detection", "tenantId": "{TenantId}", "ruleId": "{RuleId}"}
```

---

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. "No Log Analytics workspace resources are selected"

**Cause**: Workspace parameter not selected  
**Solution**: 
1. Ensure you have selected a **Subscription** from the dropdown
2. Select a **Workspace** from the dropdown
3. TenantId should auto-populate from the workspace

#### 2. Custom Endpoint returns "An unknown error has occurred"

**Causes**:
- Missing or incorrect Function App Name
- Function App not running or unreachable
- Missing Content-Type header
- Invalid JSON in request body
- Function App authentication issues

**Solution**:
1. Verify **FunctionAppName** parameter is correct
2. Test Function App endpoint directly:
   ```bash
   curl -X POST https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher \
     -H "Content-Type: application/json" \
     -d '{"action":"Get Devices","tenantId":"{TenantId}"}'
   ```
3. Check Function App logs in Application Insights
4. Verify `APPID` and `SECRETID` environment variables are set
5. Confirm API permissions granted and admin consent given

#### 3. ARM Actions fail silently (button does nothing)

**Cause**: Missing `Content-Type: application/json` header  
**Solution**: 
1. Edit the ARM Action
2. Ensure headers array contains:
   ```json
   "headers": [
     {"name": "Content-Type", "value": "application/json"}
   ]
   ```
3. Save and test again

#### 4. "todynamic(): function expects 1 argument(s)"

**Cause**: Using KQL functions in Custom Endpoint context  
**Solution**: This is expected - Custom Endpoints don't use KQL. Ignore this error if data displays correctly.

#### 5. JSONPath returns no data

**Causes**:
- Incorrect table path
- API response structure doesn't match JSONPath
- Column paths don't match actual JSON fields

**Solution**:
1. Test the API endpoint manually and inspect response:
   ```bash
   curl -X POST https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher \
     -H "Content-Type: application/json" \
     -d '{"action":"Get Devices","tenantId":"{TenantId}"}' | jq
   ```
2. Verify the response structure matches your JSONPath
3. Adjust `tablePath` and column paths accordingly

#### 6. Auto-refresh not working

**Causes**:
- Auto-refresh not enabled
- Interval too long
- Workbook in read-only mode

**Solution**:
1. Edit the query
2. Enable **Auto-refresh** toggle
3. Set interval to 30 seconds
4. Ensure workbook is saved (not in preview mode)

#### 7. Parameters not populating (e.g., {TenantId} shows as literal text)

**Cause**: Parameter not defined or misspelled  
**Solution**:
1. Go to **Parameters** section in workbook
2. Verify parameter exists with exact name `TenantId`
3. Check parameter is set to visible or hidden (not removed)
4. Parameter names are case-sensitive

---

## ✅ Validation Steps

### Pre-Deployment Validation

Before deploying the workbook, validate these items:

- [ ] Function App deployed and running
- [ ] Function App has `APPID` and `SECRETID` environment variables configured
- [ ] App Registration has Microsoft Defender for Endpoint API permissions
- [ ] Admin consent granted for API permissions
- [ ] Function App is accessible (not in VNet without proper access)
- [ ] Log Analytics workspace exists and is accessible

### Post-Deployment Validation

After deploying the workbook, validate functionality:

1. **Parameter Validation**
   - [ ] Subscription dropdown shows available subscriptions
   - [ ] Workspace dropdown shows workspaces in selected subscription
   - [ ] TenantId auto-populates after selecting workspace
   - [ ] FunctionAppName is set correctly (e.g., `defc2`)

2. **Device Manager Tab**
   - [ ] Device List query shows devices with real-time data
   - [ ] Auto-refresh indicator shows (30s countdown)
   - [ ] Isolate Devices button is clickable
   - [ ] Clicking Isolate Devices shows confirmation dialog
   - [ ] Successfully isolates selected devices

3. **Threat Intel Tab**
   - [ ] Active Threat Indicators query shows indicators
   - [ ] Submit Indicator buttons are functional
   - [ ] New indicators appear after submission

4. **Action Manager Tab**
   - [ ] Machine Actions query shows recent actions
   - [ ] Auto-refresh updates action status (pending → completed)
   - [ ] Action details expand correctly
   - [ ] Cancel Action button works

5. **Hunt Manager Tab**
   - [ ] Hunt query input accepts KQL queries
   - [ ] Run Hunt button triggers query execution
   - [ ] Hunt Results auto-refresh until completion
   - [ ] Results display correctly in grid

6. **Incident Manager Tab**
   - [ ] Security Incidents query shows incidents
   - [ ] Update Incident button changes status
   - [ ] Add Comment button adds comments successfully

7. **Detection Manager Tab**
   - [ ] Custom Detection Rules query shows rules
   - [ ] Create Detection button creates new rules
   - [ ] Update Detection button modifies existing rules
   - [ ] Delete Detection button removes rules

8. **Console Tab**
   - [ ] All 11 console items are visible
   - [ ] Quick action buttons work
   - [ ] Links open correctly

### Performance Validation

- [ ] Queries complete within 5-10 seconds
- [ ] Auto-refresh doesn't cause UI lag or freezing
- [ ] Large result sets (100+ devices) display correctly
- [ ] Multiple tabs can be used simultaneously

### Error Handling Validation

Test error scenarios:

- [ ] Invalid device IDs show appropriate error messages
- [ ] Network errors display user-friendly messages
- [ ] Missing permissions show clear guidance
- [ ] Empty results show "No data" instead of errors

---

## 📚 Additional Resources

### Official Documentation
- [Azure Workbooks Overview](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Workbooks JSONPath](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-jsonpath)
- [Microsoft Defender for Endpoint API Reference](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api-reference)

### DefenderC2 Documentation
- [WORKBOOK_PARAMETERS_GUIDE.md](../deployment/WORKBOOK_PARAMETERS_GUIDE.md) - Parameter configuration reference
- [WORKBOOK_ARM_ACTION_FIX.md](../WORKBOOK_ARM_ACTION_FIX.md) - ARM Action headers fix
- [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](./CUSTOM_ENDPOINT_SAMPLE_QUERIES.md) - Complete code samples

### Screenshots
- [Figure 1: Custom Endpoint Configuration](https://github.com/user-attachments/assets/97097e6b-64a7-454c-85ac-8ed4603ba822)
- [Figure 2: ARM Action Dialog](https://github.com/user-attachments/assets/d113dfc8-e263-4201-8ba5-7626da2d8e39)
- [Figure 3: Device List with Auto-Refresh](https://github.com/user-attachments/assets/9c4a6c6f-9f91-45d8-a4b4-3e920b711265)

---

## 🤝 Support

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting](#-troubleshooting) section above
2. Review Function App logs in Application Insights
3. Open an issue on the GitHub repository with:
   - Error messages or screenshots
   - Function App name and region
   - Workbook configuration (sanitized)
   - Steps to reproduce

---

**Last Updated**: 2025-10-11  
**Version**: 2.0  
**Maintainer**: DefenderC2 Team
