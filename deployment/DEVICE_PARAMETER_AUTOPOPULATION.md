# Device Parameter Auto-Population Guide

## Overview
This guide explains how device parameters are automatically populated in the DefenderC2 Workbook using Custom Endpoint queries. Device IDs no longer need to be manually entered - they are now populated from live Defender environment data.

---

## Implementation Details

### 1. DeviceList Parameter (Main Parameters Section)

A new **DeviceList** parameter has been added to the main parameters section that:
- Queries the DefenderC2Dispatcher Function App endpoint
- Uses Custom Endpoint (queryType: 10) with POST method
- Returns device list with ID and computer name
- Supports multi-select for choosing multiple devices
- Auto-refreshes when parameters change

**Configuration:**
```json
{
  "name": "DeviceList",
  "label": "Available Devices",
  "type": 2,
  "queryType": 10,
  "multiSelect": true,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"value\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"label\"}]}}]}"
}
```

### 2. Action-Specific Device Parameters

Each action section (Isolate, Unisolate, Restrict, Scan) has been updated:

**Parameters Updated:**
- `IsolateDeviceIds` - For device isolation actions
- `UnisolateDeviceIds` - For device unisolation actions
- `RestrictDeviceIds` - For app execution restriction actions
- `ScanDeviceIds` - For antivirus scan actions

**Changes Applied:**
- Changed from type 1 (text input) to type 2 (dropdown/multi-select)
- Added queryType: 10 (Custom Endpoint)
- Added query to fetch device list from Function App
- Enabled multi-select for choosing multiple devices
- Added JSONPath transformers for parsing response

**Example Updated Parameter:**
```json
{
  "name": "IsolateDeviceIds",
  "label": "Device IDs (comma-separated)",
  "type": 2,
  "queryType": 10,
  "multiSelect": true,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[...]}",
  "description": "Select one or more devices. List is auto-populated from Defender environment."
}
```

### 3. Auto-Refresh Configuration

Auto-refresh has been added to critical monitoring queries:

**Actions Manager Query:**
- Query Name: `query - actions-list`
- Auto-refresh interval: 30 seconds
- Refresh condition: always
- Shows real-time status of device actions

**Hunt Status Query:**
- Query Name: `query - hunt-status`
- Auto-refresh interval: 30 seconds
- Refresh condition: always
- Shows real-time status of hunting queries

**Configuration:**
```json
{
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "always"
  }
}
```

---

## User Experience

### Before Changes
- Users had to manually type or copy-paste device IDs
- Risk of typos and incorrect device IDs
- No visibility into available devices
- Device names not shown, only IDs

### After Changes
- Users see dropdown list of all available devices
- Device names displayed alongside IDs
- Multi-select support for bulk actions
- Auto-populated from live Defender environment
- Reduces errors and improves usability

---

## JSONPath Parsing

Device list responses are parsed using JSONPath transformers:

**Response Structure:**
```json
{
  "devices": [
    {
      "id": "device-id-123",
      "computerDnsName": "DESKTOP-ABC123",
      "isolationState": "NotIsolated",
      "healthStatus": "Active",
      "riskScore": "Medium"
    }
  ]
}
```

**JSONPath Configuration:**
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

This extracts:
- `$.id` → Used as the parameter value
- `$.computerDnsName` → Displayed as the label in dropdown

---

## Function App Requirements

The Function App endpoints must return data in the expected format:

**Get Devices Endpoint:**
- **Method:** POST
- **URL:** `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`
- **Body:** `{"action":"Get Devices","tenantId":"{TenantId}"}`
- **Headers:** `Content-Type: application/json`

**Expected Response:**
```json
{
  "devices": [
    {
      "id": "string",
      "computerDnsName": "string",
      "isolationState": "string",
      "healthStatus": "string",
      "riskScore": "string",
      "exposureLevel": "string",
      "lastSeen": "string",
      "osPlatform": "string"
    }
  ]
}
```

Minimum required fields:
- `id` - Device identifier
- `computerDnsName` - Device name for display

---

## Troubleshooting

### Device List is Empty
**Symptoms:** Dropdown shows no devices

**Possible Causes:**
1. FunctionAppName parameter not set
2. TenantId not auto-discovered (check Workspace selection)
3. Function App not deployed or not responding
4. Function App authentication issues

**Resolution:**
1. Verify FunctionAppName is set in parameters
2. Check Workspace is selected (TenantId auto-populates)
3. Test Function App endpoint manually
4. Verify Function App authentication settings

### Dropdown Not Updating
**Symptoms:** Old device list shown, doesn't refresh

**Possible Causes:**
1. Query cache not cleared
2. Function App returning stale data

**Resolution:**
1. Click "Run Query" button to force refresh
2. Change and revert any parameter to trigger refresh
3. Close and reopen workbook

### Multi-Select Not Working
**Symptoms:** Can only select one device

**Possible Causes:**
1. Parameter multiSelect property not set
2. Browser compatibility issue

**Resolution:**
1. Verify parameter has `"multiSelect": true`
2. Try different browser
3. Clear browser cache

---

## Validation

To verify the implementation:

1. **Check Parameter Configuration:**
   ```bash
   cd deployment
   python3 verify_workbook_deployment.py
   ```

2. **Manual Testing:**
   - Open workbook in Azure Portal
   - Navigate to MDEAutomator tab
   - Check if device dropdowns are populated
   - Test multi-select functionality
   - Verify device names are displayed

3. **Expected Results:**
   - DeviceList parameter shows all devices
   - Action parameters show device dropdowns
   - Multi-select works for all device parameters
   - Actions manager auto-refreshes every 30s
   - Hunt status auto-refreshes every 30s

---

## Migration Notes

### Backward Compatibility
- Existing workbook configurations will continue to work
- No breaking changes to ARM Actions or Function App calls
- Only parameter input method changed (text → dropdown)

### Deployment
- Changes are in workbook JSON only
- No Function App changes required
- No ARM template changes required
- Deploy updated workbook using existing deployment scripts

---

## References

- [CUSTOMENDPOINT_GUIDE.md](CUSTOMENDPOINT_GUIDE.md) - Custom Endpoint implementation
- [WORKBOOK_PARAMETERS_GUIDE.md](WORKBOOK_PARAMETERS_GUIDE.md) - Parameter configuration
- [Azure Workbooks Parameters](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-parameters)
- [JSONPath Syntax](https://goessner.net/articles/JsonPath/)

---

**Last Updated:** 2025-10-11  
**Version:** 1.0  
**Status:** Production Ready
