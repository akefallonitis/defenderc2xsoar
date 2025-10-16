# 🎯 FINAL IMPLEMENTATION PLAN

## Current Status (After Analysis)

### CustomEndpoint-Only Workbook ✅
**File:** `DeviceManager-CustomEndpoint-Only.workbook.json`  
**Status:** UPDATED with action ID autopopulation  
**Changes Made:**
- ✅ Added `parameterName: "LastActionId"` and `parameterValue: "{0}"` to Action IDs formatter in execution results
- ✅ Changed Pending Actions formatter from "Copy" to "Cancel" with `parameterName: "CancelActionId"`  
- ✅ Changed Machine Actions History formatter to "Track" with `parameterName: "LastActionId"`
- ✅ All formatters now use type 7 with proper parameter population
- ✅ JSON validated successfully

### "Hybrid" Workbook ⚠️
**File:** `DeviceManager-Hybrid.workbook.json`  
**Status:** MISNAMED - Currently ALL CustomEndpoint (not truly hybrid)  
**Issues:**
- All queries use `CustomEndpoint/1.0` (lines 134, 258, 364, 449, 534, 619, 704, 789, 893, 985, 1028, 1141)
- No ARM Actions despite the name "Hybrid"
- Has problematic Content-Type headers that we previously fixed
- Missing proper action ID autopopulation formatters

## User Requirements

From latest request:
1. **"1 only with customendpoints autorefresh autopopulation and machine action list get cancel run etc"**  
   → CustomEndpoint-Only version ✅ DONE

2. **"1 hybrid with both custom endpoints for autorefreshed sections action list get and arm actions for the manual input machine actions run cancel"**  
   → Need TRUE Hybrid: CustomEndpoint for monitoring + ARMEndpoint for execution

## What Needs to Be Done

### Option 1: Rename Current "Hybrid" 
Since the current "Hybrid" workbook is actually all CustomEndpoint, we could:
- Rename it to something like `DeviceManager-CustomEndpoint-EnhancedUI.workbook.json`
- Keep it as an alternative CustomEndpoint version with different UI

### Option 2: Create TRUE Hybrid ✅ RECOMMENDED
Create a new proper hybrid workbook that uses:

**CustomEndpoint Sections (Auto-Refresh):**
- Device List dropdown
- Pending Actions monitor
- Action Status tracking  
- Machine Actions History

**ARM Actions Sections (Manual Trigger):**
- Run Antivirus Scan
- Isolate Device
- Unisolate Device
- Collect Investigation Package
- Restrict App Execution
- Unrestrict App Execution
- Cancel Action

## ARM Actions Implementation Pattern

Based on conversationworkbookstests lines 865-906, the working ARM Action pattern is:

```json
{
  "version": "ARMEndpoint/1.0",
  "data": null,
  "headers": [],
  "method": "POST",
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invoke",
  "urlParams": [
    {"key": "api-version", "value": "2022-03-01"},
    {"key": "action", "value": "Run Antivirus Scan"},
    {"key": "tenantId", "value": "{TenantId}"},
    {"key": "deviceIds", "value": "{DeviceList}"},
    {"key": "scanType", "value": "{ScanType}"},
    {"key": "comment", "value": "Scan via DefenderC2 Workbook"}
  ],
  "batchDisabled": false,
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "columns": [
        {"path": "$.message", "columnid": "Result"},
        {"path": "$.actionIds[0]", "columnid": "Action ID"},
        {"path": "$.status", "columnid": "Status"},
        {"path": "$.details", "columnid": "Details"}
      ]
    }
  }]
}
```

**Key Points:**
- Uses `ARMEndpoint/1.0` not `CustomEndpoint/1.0`
- `method: "POST"` for execution actions
- `path` includes full ARM resource path with `/invoke` endpoint
- `urlParams` includes `api-version: 2022-03-01` as FIRST parameter
- Empty headers array `[]`
- `$.actionIds[0]` extracts first action ID from array
- `batchDisabled: false`
- `queryType: 12` (ARM Endpoint query type)

## Action ID Autopopulation Pattern

From conversationworkbookstests line 885:

```json
{
  "columnMatch": "Action ID",
  "formatter": 13,  // Note: formatter 13 for ARM, formatter 7 for CustomEndpoint
  "formatOptions": {
    "linkTarget": "Parameter",
    "showIcon": true,
    "parameterName": "LastActionID",
    "parameterValue": "{0}",
    "linkLabel": "Track Status",
    "linkIsContextBlade": false
  }
}
```

**Note:** ARM Actions seem to use formatter **13** while CustomEndpoint uses formatter **7**. Both work for parameter population.

## Implementation Steps

1. ✅ **CustomEndpoint-Only**: Already updated with proper autopopulation
2. 🔄 **Create TRUE Hybrid**: Build new workbook from scratch combining:
   - CustomEndpoint monitoring sections from current CustomEndpoint-Only
   - ARM Action execution sections from conversationworkbookstests patterns
   - Proper action ID autopopulation for both types
   - Clean headers (no Content-Type)
   - Correct action names (Get All Actions, Get Action Status, Cancel Action)

## Key Differences: CustomEndpoint vs ARM Actions

| Feature | CustomEndpoint/1.0 | ARMEndpoint/1.0 |
|---------|-------------------|-----------------|
| **Query Type** | `queryType: 10` | `queryType: 12` |
| **Formatter** | Type 7 (link) | Type 13 (parameter link) |
| **URL** | Full HTTPS URL | ARM resource path |
| **Method** | POST with URL | POST with path |
| **Headers** | Empty array `[]` | Empty array `[]` |
| **API Version** | In URL params | In URL params (first) |
| **Auto-Refresh** | ✅ Supported | ❌ Not supported (manual trigger) |
| **Use Case** | Monitoring, lists, status | Execution, manual actions |

## Next Actions

1. Clean up current Hybrid workbook: Remove Content-Type headers, fix action names, add autopopulation
2. Convert execution sections to ARM Actions with proper paths
3. Keep monitoring sections as CustomEndpoint
4. Validate JSON
5. Test both workbooks
6. Commit and push

---

**Decision:** Create TRUE Hybrid workbook as requested by user.
