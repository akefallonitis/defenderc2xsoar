# 🏗️ Workbook Architecture - Two Versions

## Overview

Based on conversation history analysis, we need **TWO distinct workbooks**:

### 1. CustomEndpoint-Only Workbook ✅
**Purpose:** Fully automated, auto-refreshing workbook  
**Status:** Already exists and is CORRECT
**File:** `DeviceManager-CustomEndpoint-Only.workbook.json`

### 2. Hybrid Workbook 🔄
**Purpose:** Mix of auto-refresh (CustomEndpoint) + manual actions (ARM Actions)  
**Status:** Needs to be created/updated  
**File:** `DeviceManager-Hybrid.workbook.json`

---

## CustomEndpoint-Only Architecture

### Query Type
**All queries use:** `CustomEndpoint/1.0`

### Sections

| Section | Function | Query Type | Auto-Refresh |
|---------|----------|------------|--------------|
| Device List | Get Devices | CustomEndpoint | No (parameter dropdown) |
| Pending Actions | Get All Actions (filtered) | CustomEndpoint | ✅ Yes |
| Action Execution | Run/Isolate/Collect/etc | CustomEndpoint | No (manual trigger) |
| Action Status | Get Action Status | CustomEndpoint | ✅ Yes (when LastActionId set) |
| Cancel Action | Cancel Action | CustomEndpoint | No (manual trigger) |
| Machine Actions History | Get All Actions | CustomEndpoint | ✅ Yes |
| Device Inventory | Get Devices | CustomEndpoint | ✅ Yes |

### Key Features
✅ All actions use CustomEndpoint/1.0  
✅ Auto-refresh enabled on monitoring sections  
✅ Action IDs auto-populate from execution results  
✅ Clickable Action IDs link to tracking parameters  
✅ No ARM Actions at all

### Action ID Autopopulation
- Execution results show `$.actionIds` array
- Formatter type 7 (link) populates `LastActionId` parameter
- Users can click "Track" link to auto-populate
- Manual copy/paste also supported

---

## Hybrid Architecture (REQUIRED)

### Query Type Strategy
**Two types mixed:**
- `CustomEndpoint/1.0` for auto-refresh sections
- `ARMEndpoint/1.0` for manual execution sections

### Sections

| Section | Function | Query Type | Auto-Refresh | Reason |
|---------|----------|------------|--------------|--------|
| Device List | Get Devices | **CustomEndpoint** | No | Auto-populate dropdown |
| Pending Actions | Get All Actions (filtered) | **CustomEndpoint** | ✅ Yes | Monitor without manual action |
| **Action Execution** | **Run/Isolate/Collect/etc** | **ARMEndpoint** | **No** | **Manual triggered actions** |
| Action Status | Get Action Status | **CustomEndpoint** | ✅ Yes | Monitor status continuously |
| **Cancel Action** | **Cancel Action** | **ARMEndpoint** | **No** | **Manual triggered** |
| Machine Actions History | Get All Actions | **CustomEndpoint** | ✅ Yes | Monitor all actions |
| Device Inventory | Get Devices | **CustomEndpoint** | ✅ Yes | Monitor devices |

### CustomEndpoint Sections (Auto-Refresh)
```json
// Device List Dropdown
{"version":"CustomEndpoint/1.0", "url":"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "urlParams":[{"key":"action","value":"Get Devices"}]}

// Pending Actions (with filter)
{"version":"CustomEndpoint/1.0", "urlParams":[{"key":"action","value":"Get All Actions"}, {"key":"filter","value":"(status eq 'Pending' or status eq 'InProgress')"}], "timeContextFromParameter":"AutoRefresh"}

// Machine Actions History
{"version":"CustomEndpoint/1.0", "urlParams":[{"key":"action","value":"Get All Actions"}], "timeContextFromParameter":"AutoRefresh"}

// Action Status Tracking
{"version":"CustomEndpoint/1.0", "urlParams":[{"key":"action","value":"Get Action Status"}, {"key":"actionId","value":"{LastActionId}"}], "timeContextFromParameter":"AutoRefresh"}
```

### ARM Actions Sections (Manual Trigger)
```json
// Run Antivirus Scan
{"version":"ARMEndpoint/1.0", "method":"POST", "path":"/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Web/sites/{functionApp}/functions/DefenderC2Dispatcher/invoke", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Run Antivirus Scan"}, {"key":"deviceIds","value":"{DeviceList}"}]}

// Isolate Device
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Isolate Device"}]}

// Unisolate Device
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Unisolate Device"}]}

// Collect Investigation Package
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Collect Investigation Package"}]}

// Restrict App Execution
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Restrict App Execution"}]}

// Unrestrict App Execution
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Unrestrict App Execution"}]}

// Cancel Action
{"version":"ARMEndpoint/1.0", "method":"POST", "urlParams":[{"key":"api-version","value":"2022-03-01"}, {"key":"action","value":"Cancel Action"}, {"key":"actionId","value":"{CancelActionId}"}]}
```

### Key Differences from CustomEndpoint-Only

**Why Hybrid?**
1. **ARM Actions provide better control** for manual execution
2. **CustomEndpoint auto-refresh** keeps monitoring sections up-to-date
3. **Best of both worlds:** Monitoring + Control

**What Changes:**
- Action execution queries change from CustomEndpoint → ARMEndpoint
- Cancel action changes from CustomEndpoint → ARMEndpoint
- Monitoring/listing queries stay CustomEndpoint
- All auto-refresh sections stay CustomEndpoint

---

## Action ID Autopopulation (Both Versions)

### Extraction from Results
```json
// Function returns:
{
  "message": "Action initiated successfully",
  "actionIds": ["abc-123", "def-456"],
  "status": "Initiated"
}

// JSONPath extraction:
{"path": "$.actionIds", "columnid": "Action IDs"}
// Or first item:
{"path": "$.actionIds[0]", "columnid": "Action ID"}
```

### Click-to-Populate
```json
{
  "columnMatch": "Action IDs",
  "formatter": 7,
  "formatOptions": {
    "linkTarget": "parameter",
    "linkLabel": "📋 Track",
    "parameterName": "LastActionId"
  }
}
```

### Formatter Type 7 (Link)
- Converts cell to clickable link
- Sets parameter value on click
- Used for Action IDs → LastActionId
- Used for Action IDs → CancelActionId

---

## Auto-Refresh Configuration

### CustomEndpoint Queries (Both Versions)
```json
{
  "timeContext": {"durationMs": 0},
  "timeContextFromParameter": "AutoRefresh",
  "showRefreshButton": true
}
```

### AutoRefresh Parameter
```json
{
  "name": "AutoRefresh",
  "type": 2,
  "jsonData": [
    {"value": "0", "label": "Off"},
    {"value": "10000", "label": "Every 10 seconds"},
    {"value": "30000", "label": "Every 30 seconds"},
    {"value": "60000", "label": "Every 1 minute"},
    {"value": "300000", "label": "Every 5 minutes"}
  ],
  "value": "30000"
}
```

---

## User Requirements from Conversation History

### From User Quotes:
1. **"autopopulate arction ids!!"** → Action IDs must auto-populate from execution results
2. **"handle list cancel machine actions functionality"** → Must support listing, canceling actions
3. **"1 only with customendpoints autorefresh autopopulation"** → CustomEndpoint-Only version
4. **"1 hybrid with both custom endpoints for autorefreshed sections action list get and arm actions for the manual input machine actions run cancel"** → Hybrid version

### Translation:
- **Workbook 1:** CustomEndpoint/1.0 everywhere (✅ EXISTS)
- **Workbook 2:** CustomEndpoint/1.0 for monitoring + ARMEndpoint/1.0 for execution (🔄 NEEDS CREATION)

---

## Implementation Plan

### ✅ CustomEndpoint-Only (Already Done)
- [x] All queries use CustomEndpoint/1.0
- [x] Auto-refresh enabled on monitoring sections
- [x] Action IDs clickable with formatter type 7
- [x] Correct action names (Get All Actions, Get Action Status, Cancel Action)
- [x] No Content-Type headers
- [x] Correct JSONPath ($.actionIds, $.actions[*])

### 🔄 Hybrid (To Be Created)
- [ ] Device list → CustomEndpoint
- [ ] Pending actions → CustomEndpoint (auto-refresh)
- [ ] Action execution (6 types) → ARMEndpoint (manual)
- [ ] Action status → CustomEndpoint (auto-refresh)
- [ ] Cancel action → ARMEndpoint (manual)
- [ ] Machine actions history → CustomEndpoint (auto-refresh)
- [ ] Action IDs clickable with formatter type 7
- [ ] Auto-refresh parameter controls CustomEndpoint sections only

---

## Testing Checklist

### CustomEndpoint-Only
- [ ] Import to Azure Portal
- [ ] Select Function App → Devices populate
- [ ] Execute action → Action IDs appear
- [ ] Click "Track" link → LastActionId populates
- [ ] Pending actions auto-refresh
- [ ] Machine actions history auto-refresh
- [ ] Cancel action works

### Hybrid
- [ ] Import to Azure Portal
- [ ] Select Function App → Devices populate (CustomEndpoint)
- [ ] Pending actions auto-refresh (CustomEndpoint)
- [ ] Execute scan → ARM Action triggers (ARMEndpoint)
- [ ] Action IDs appear and clickable
- [ ] Action status auto-refreshes (CustomEndpoint)
- [ ] Machine actions history auto-refreshes (CustomEndpoint)
- [ ] Cancel action triggers (ARMEndpoint)

---

## File Locations

```
workbook_tests/
├── DeviceManager-CustomEndpoint-Only.workbook.json  ✅ EXISTS (CORRECT)
├── DeviceManager-Hybrid.workbook.json               🔄 NEEDS UPDATE
├── WORKBOOK_ARCHITECTURE.md                         📄 THIS FILE
├── FIXES_APPLIED.md                                 📄 Previous fixes
├── CRITICAL_FIXES.md                                📄 Root cause analysis
└── README.md                                        📄 User guide
```

---

## Summary

**CustomEndpoint-Only:** Perfect for fully automated monitoring and control with consistent query interface.

**Hybrid:** Best for users who want auto-refreshing monitoring (CustomEndpoint) but prefer ARM Actions for manual execution control (ARMEndpoint).

**Both versions:**
- ✅ Auto-populate action IDs
- ✅ Clickable links for tracking/canceling
- ✅ Auto-refresh where appropriate
- ✅ Correct action names (Get All Actions, Get Action Status, Cancel Action)
- ✅ Clean headers (no Content-Type)
- ✅ Correct JSONPath ($.actionIds, $.actions[*])
