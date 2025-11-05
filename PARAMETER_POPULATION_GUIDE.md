# DefenderC2 Workbook Parameter Population Guide

Complete guide to how parameters populate and flow through the DefenderC2 workbook.

## Overview

The workbook uses **50 global parameters** to enable cross-tab functionality and data filtering. Understanding how these parameters populate is critical for proper workbook operation.

## Parameter Population Flow

### Level 1: Manual Selection (User Input)

#### 1. FunctionApp Parameter
- **Type**: Resource Picker (type 5)
- **Population**: Manual selection by user
- **Purpose**: Identifies which Azure Function App hosts DefenderC2
- **Triggers**: Auto-discovery of Subscription, ResourceGroup, FunctionAppName

```json
{
  "name": "FunctionApp",
  "type": 5,
  "query": "Resources | where type =~ 'microsoft.web/sites' | where kind contains 'functionapp'"
}
```

**How to populate**: 
1. Open workbook
2. Click "DefenderC2 Function App" dropdown at top
3. Select your function app from the list

---

### Level 2: Auto-Discovery (From FunctionApp)

These parameters automatically populate once FunctionApp is selected:

#### 2. FunctionAppName Parameter
- **Type**: Text (type 1) with Azure Resource Graph query
- **Population**: Auto-discovered from FunctionApp resource ID
- **Purpose**: Extract function app name for API URLs

```json
{
  "name": "FunctionAppName",
  "type": 1,
  "query": "Resources | where id =~ '{FunctionApp}' | project name"
}
```

**Example**: If you select function app `/subscriptions/.../defenderc2`, this parameter becomes `defenderc2`

#### 3. Subscription Parameter
- **Type**: Text (type 1) with Azure Resource Graph query
- **Population**: Auto-discovered from FunctionApp resource ID
- **Purpose**: Identify subscription for RBAC and resource operations

```json
{
  "name": "Subscription",
  "type": 1,
  "query": "Resources | where id =~ '{FunctionApp}' | project subscriptionId"
}
```

#### 4. ResourceGroup Parameter
- **Type**: Text (type 1) with Azure Resource Graph query
- **Population**: Auto-discovered from FunctionApp resource ID
- **Purpose**: Identify resource group for RBAC operations

```json
{
  "name": "ResourceGroup",
  "type": 1,
  "query": "Resources | where id =~ '{FunctionApp}' | project resourceGroup"
}
```

---

### Level 3: Tenant Selection (Manual Dropdown)

#### 5. TenantId Parameter
- **Type**: Dropdown (type 2) with Azure Resource Graph query
- **Population**: User selects from dropdown of available tenants
- **Purpose**: Specify which Microsoft Defender XDR tenant to manage

```json
{
  "name": "TenantId",
  "type": 2,
  "query": "Resources | where id =~ '{FunctionApp}' | project properties.customProperties.tenants"
}
```

**How to populate**:
1. After FunctionApp is selected
2. Click "Tenant ID" dropdown
3. Select target Defender XDR tenant

**Note**: If dropdown is empty, tenant IDs must be configured in Function App's application settings.

---

### Level 4: Click-to-Select (Interactive Table Selection)

#### 6. DeviceList Parameter ⭐ CRITICAL FIX
- **Type**: Text (type 1) - **NOT dropdown**
- **Population**: Click-to-select formatter in device table
- **Purpose**: Accumulate selected device IDs for filtering

**BEFORE (BROKEN)**:
```json
{
  "name": "DeviceList",
  "type": 2,  // ❌ Dropdown with CustomEndpoint query
  "query": "{\"version\":\"CustomEndpoint/1.0\",...}"  // ❌ Conflicts with click
}
```

**AFTER (WORKING)**:
```json
{
  "name": "DeviceList",
  "type": 1,  // ✅ Text input
  "value": "",
  "description": "🖱️ Click devices in the table below to select"
}
```

**How it works**:
1. Navigate to **Automator** tab
2. Device table displays (query - get-devices CustomEndpoint query)
3. Click "✅ Select" button on any device row
4. Click-to-select formatter executes: `{DeviceList},{0}` (appends device ID)
5. DeviceList parameter populates: `device-id-1,device-id-2,device-id-3`
6. All tabs filter by selected devices

**Formatter configuration**:
```json
{
  "columnMatch": "id",
  "formatter": 7,
  "formatOptions": {
    "linkTarget": "parameter",
    "linkLabel": "✅ Select",
    "linkIsContextBlade": false,
    "preText": "{DeviceList},",
    "customColumnWidthSetting": "20ch"
  }
}
```

---

## Parameter Usage in Queries

### CustomEndpoint Queries

All 16 CustomEndpoint queries use parameters via `urlParams`:

```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": null,
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"},
    {"key": "deviceIds", "value": "{DeviceList}"}
  ]
}
```

**Parameter substitution**:
- `{FunctionAppName}` → Function app name (e.g., `defenderc2`)
- `{TenantId}` → Selected tenant ID
- `{DeviceList}` → Comma-separated device IDs

---

### ARM Actions

All 15 ARM actions access parameters via global scope:

```json
{
  "linkTarget": "ArmAction",
  "linkIsContextBlade": true,
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/run",
    "body": {
      "action": "{ActionToExecute}",
      "tenantId": "{TenantId}",
      "deviceIds": "{DeviceList}"
    }
  }
}
```

---

## Tab-Specific Parameters

### Automator Tab
- `IsolationType` - Type of isolation (Full/Selective)
- `ScanType` - Type of scan (Quick/Full)
- `CollectionPackage` - Investigation package to collect

### Threat Intel Tab
- `FileHash` - File hash indicator
- `FileAction` - Action for indicator (Alert/Block/Warn)
- `FileTitle` - Title for indicator
- `IPAddress` - IP address indicator
- `URLValue` - URL indicator

### Actions Tab
- `ActionId` - Action ID for tracking/cancellation
- `StatusFilter` - Filter by action status
- `RefreshInterval` - Auto-refresh interval

### Hunting Tab
- `SampleQuery` - Predefined sample query
- `HuntQuery` - Custom KQL query
- `HuntRefreshInterval` - Auto-refresh interval

### Incidents Tab
- `IncidentId` - Incident ID for operations
- `IncidentSeverity` - Severity filter
- `IncidentStatus` - Status to set (Active/InProgress/Resolved/Redirected)
- `IncidentComment` - Comment to add

### Detections Tab
- `DetectionName` - Detection rule name
- `DetectionQuery` - KQL query for detection
- `DetectionSeverity` - Severity level (High/Medium/Low/Informational)

### Console Tab
- `CommandType` - Type of command (RunScript/GetFile/PutFile)
- `ActionName` - Script/file name
- `CommandParams` - Command parameters
- `LibraryFileNameGet` - File to retrieve from library

---

## Troubleshooting Parameter Population

### Issue: FunctionAppName not populating

**Symptoms**: FunctionAppName parameter is empty after selecting FunctionApp

**Diagnosis**:
```bash
# Check if FunctionApp parameter is set
# In workbook, check if FunctionApp shows selected resource

# Verify Azure Resource Graph can query the resource
az graph query -q "Resources | where type =~ 'microsoft.web/sites' | where kind contains 'functionapp' | project id, name"
```

**Solution**:
- Ensure you have Reader access to the subscription
- Check if Function App still exists
- Verify resource type is `microsoft.web/sites`

---

### Issue: TenantId dropdown is empty

**Symptoms**: TenantId parameter has no options in dropdown

**Diagnosis**:
```bash
# Check Function App configuration
az functionapp config appsettings list --name defenderc2 --resource-group <rg> | grep -i tenant
```

**Solution**:
- Add `TENANTID` application setting to Function App
- Or modify query to use different tenant discovery method
- Or use text input with known tenant ID

---

### Issue: DeviceList not populating when clicking devices

**Symptoms**: Clicking "✅ Select" doesn't add device to DeviceList parameter

**Root Cause**: DeviceList configured as dropdown (type 2) instead of text input (type 1)

**Diagnosis**:
```json
// Check DeviceList parameter configuration
// Should be:
{
  "name": "DeviceList",
  "type": 1,  // ✅ Text input
  "value": ""
}

// NOT:
{
  "name": "DeviceList",
  "type": 2,  // ❌ Dropdown
  "query": "..."
}
```

**Solution**: Use type 1 (text input) - **ALREADY FIXED IN CURRENT WORKBOOK**

---

### Issue: CustomEndpoint queries not returning data

**Symptoms**: Device table and other queries show "No data" despite parameters populated

**Diagnosis**:
1. Check if parameters are actually populated (show values at top)
2. Check Function App status:
   ```bash
   az functionapp show --name defenderc2 --resource-group <rg> --query state
   ```
3. Test API directly:
   ```bash
   curl -X POST "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get+Devices&tenantId=<tenant-id>"
   ```

**Solution**:
- **If parameters empty**: Follow parameter population steps above
- **If parameters populated but queries fail**: Debug Function App backend (see TROUBLESHOOTING.md)

---

## Parameter Dependencies

### Dependency Chain

```
FunctionApp (manual)
  ├─> FunctionAppName (auto)
  ├─> Subscription (auto)
  └─> ResourceGroup (auto)

TenantId (manual dropdown)

DeviceList (click-to-select)
  └─> Requires: query - get-devices to display device table
      └─> Requires: FunctionAppName, TenantId

All CustomEndpoint Queries
  └─> Require: FunctionAppName, TenantId
      └─> Optional: DeviceList (for filtering)

All ARM Actions
  └─> Require: Subscription, ResourceGroup, FunctionAppName, TenantId
      └─> Optional: Tab-specific parameters
```

---

## Best Practices

### 1. Always Select in Order
1. ✅ Select FunctionApp first
2. ✅ Wait for FunctionAppName to populate
3. ✅ Select TenantId
4. ✅ Wait for device table to load
5. ✅ Click devices to select

### 2. Verify Parameters Populated
- Check top menu shows all values
- FunctionApp: Should show resource path
- FunctionAppName: Should show app name (e.g., `defenderc2`)
- TenantId: Should show GUID
- DeviceList: Initially empty, populates after clicking devices

### 3. Use Click-to-Select
- ✅ DO: Click "✅ Select" buttons in tables
- ❌ DON'T: Try to manually type device IDs (though it works)
- ✅ DO: Select multiple devices by clicking multiple rows
- ❌ DON'T: Expect DeviceList to auto-populate from dropdown

### 4. Monitor Auto-Refresh
- Listing queries auto-refresh every 30 seconds
- Parameter changes trigger immediate re-query
- Can disable auto-refresh by setting RefreshInterval to 0

---

## Summary

**Critical Configuration**:
- ✅ All 50 parameters marked as `isGlobal: true`
- ✅ DeviceList is type 1 (text input) for click-to-select
- ✅ All queries use `urlParams` for parameter substitution
- ✅ All ARM actions reference global parameters

**Parameter Flow**:
1. User selects FunctionApp → Auto-discovers name/subscription/RG
2. User selects TenantId → Enables API queries
3. Device table loads → User clicks to select devices
4. DeviceList populates → All tabs filter by selected devices
5. User executes actions → ARM actions access all parameters

**If queries don't work**: The workbook configuration is correct. Debug the Function App backend per TROUBLESHOOTING.md.
