# DefenderC2 Workbook Reorganization Plan

## 🎯 Objective
Create a user-friendly, function-based workbook that mirrors MDE Automator UI and eliminates all infinite loading issues.

## 📋 Current Issues Fixed
1. ❌ Duplicate local device parameters causing infinite loops → ✅ Single global DeviceList
2. ❌ Complex nested parameter structure → ✅ Flat, simple parameters
3. ❌ Redundant API calls → ✅ Single device query, reused everywhere
4. ❌ Confusing tab organization → ✅ Function-based tabs
5. ❌ No interactive console → ✅ Live Response shell UI
6. ❌ No library management → ✅ Orchestrator operations tab

## 🏗️ New Structure

### Global Parameters (Top Bar)
```
┌─────────────────────────────────────────────────────────────────────┐
│ 🔧 DefenderC2 Function App: [defenderc2 ▼]                          │
│ 📊 Log Analytics Workspace: [Ballpit-Sentinel ▼]                    │
│ 🏢 Defender XDR Tenant: [a92a42cd... ▼]                             │
│ 💻 Available Devices: [dc2-jay.jay.lan, srv01... ▼] (Multi-select)  │
│ 📅 Time Range: [Last 30 days ▼]                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Tab Structure

#### 1. 🏠 **Overview**
- **Purpose**: Dashboard with quick stats and status
- **Content**:
  - Connected devices count
  - Recent actions summary
  - Health status overview
  - Quick action buttons

#### 2. 💻 **Device Management**
- **Purpose**: All device response actions in ONE place
- **Content**:
  - Device list grid (from CustomEndpoint)
  - Action buttons (ARM Actions):
    - 🚨 Isolate Devices
    - ✅ Unisolate Devices
    - 🔒 Restrict App Execution
    - 🔓 Unrestrict App Execution
    - 🔍 Run Antivirus Scan (Full/Quick dropdown)
    - 📦 Collect Investigation Package
    - 🛑 Stop & Quarantine File (with file hash input)
  - Action status tracker grid

#### 3. 🔍 **Threat Intelligence**
- **Purpose**: TI Manager operations
- **Content**:
  - Indicator list (CustomEndpoint)
  - Add indicator form (ARM Action)
  - Remove indicator (ARM Action)
  - Bulk import/export

#### 4. 🚨 **Incident Response**
- **Purpose**: Incident Manager operations
- **Content**:
  - Incidents list grid
  - Create/Update incident forms
  - Link devices to incidents
  - Incident timeline

#### 5. 🎯 **Custom Detections**
- **Purpose**: CD Manager operations
- **Content**:
  - Detection rules list
  - Create/Edit detection rules
  - Backup/Restore detections
  - Test detection queries

#### 6. 🔎 **Advanced Hunting**
- **Purpose**: Hunt Manager operations
- **Content**:
  - KQL query editor (text area)
  - Execute hunt button (ARM Action)
  - Results grid
  - Query history

#### 7. 💬 **Interactive Console**
- **Purpose**: Live Response shell-like interface
- **Content**:
  ```
  ┌─────────────────────────────────────────────────┐
  │ DefenderC2> _                                    │
  │                                                   │
  │ Available Commands:                               │
  │ - getfile <path>                                 │
  │ - putfile <name>                                 │
  │ - runscript <name>                               │
  │ - remediate <hash>                               │
  │                                                   │
  │ Command History:                                 │
  │ [Previous commands grid]                         │
  └─────────────────────────────────────────────────┘
  ```
  - Command input text box
  - Execute button (ARM Action to Orchestrator)
  - Terminal-style output display
  - Command history grid

#### 8. 📚 **Library Operations**
- **Purpose**: Orchestrator script/file management
- **Content**:
  - Library files list (CustomEndpoint)
  - Upload script button (ARM Action)
  - Download script button
  - Delete script button
  - Script metadata grid

## 🔄 Parameter Flow

```mermaid
User Selects FunctionApp
  ↓
Auto-populate: Subscription, ResourceGroup, FunctionAppName
  ↓
User Selects TenantId (Lighthouse dropdown)
  ↓
DeviceList CustomEndpoint executes ONCE
  ↓
User Selects Device(s) from DeviceList
  ↓
ALL ARM Actions use {DeviceList} - no local queries
  ↓
No infinite loops! ✅
```

## 📝 Implementation Notes

### CustomEndpoint Pattern (Used for data display)
```json
{
  "type": 3,
  "content": {
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":null,\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}],\"transformers\":[...]}",
    "queryType": 10
  }
}
```

### ARM Action Pattern (Used for action buttons)
```json
{
  "type": 11,
  "content": {
    "links": [{
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
        "params": [
          {"key": "api-version", "value": "2022-03-01"},
          {"key": "action", "value": "Isolate Device"},
          {"key": "tenantId", "value": "{TenantId}"},
          {"key": "deviceIds", "value": "{DeviceList}"}
        ],
        "httpMethod": "POST"
      },
      "criteriaData": [
        {"criterionType": "param", "value": "{FunctionApp}"},
        {"criterionType": "param", "value": "{TenantId}"},
        {"criterionType": "param", "value": "{DeviceList}"}
      ]
    }]
  }
}
```

## ✅ Benefits

1. **No Infinite Loops**: Single global DeviceList, no local duplicates
2. **Clear Organization**: Function-based tabs match backend capabilities
3. **User-Friendly**: MDE Automator-style UI, familiar to SOC teams
4. **Efficient**: One API call for devices, reused everywhere
5. **Feature-Complete**: Includes Interactive Console and Library Operations
6. **Extensible**: Easy to add new functions/actions

## 🚀 Next Steps

1. ✅ Backup existing workbook
2. 🔄 Create new workbook JSON with this structure
3. 🧪 Test each tab individually
4. 📦 Deploy and validate
5. 📖 Update documentation
