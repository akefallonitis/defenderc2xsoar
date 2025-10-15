# DeviceManager-Testing Workbook Fixes

## Date: 2025-10-15 17:52:00 UTC
## Author: Copilot (akefallonitis)

## Overview

This document details the comprehensive fixes applied to the DefenderC2 Device Manager Testing Workbook to resolve auto-population issues, error handling, and improve functionality.

## Issues Identified

Based on PR #93 and the conversation history:

1. **Device List Not Auto-Populating** - The device dropdown showed "< query failed >" instead of loading devices
2. **400 Bad Request Errors** - When trying to execute the same action on a device that already has it pending
3. **Missing Error Handling** - No warning when conflicting actions exist
4. **Action IDs Not Auto-Populating** - Manual entry required for tracking/cancellation
5. **Conditional Visibility Issues** - Sections showing when they shouldn't
6. **Missing Auto-Refresh** - No automatic updates for action status

## Solutions Implemented

### 1. Fixed Device List Auto-Population

**Problem**: CustomEndpoint query wasn't working due to:
- Missing `criteriaData` to ensure parameters are ready
- Incorrect parameter dependencies

**Solution**:
```json
{
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}],\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"value\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"label\"}]}}]}",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{FunctionAppName}"
    },
    {
      "criterionType": "param",
      "value": "{TenantId}"
    }
  ]
}
```

### 2. Added Error Handling for Conflicting Actions

**Problem**: Function returns 400 error when the same action is already running on a device

**Solution**:
- Added "Running Actions Check" section that queries for pending/in-progress actions
- Shows only when devices are selected and action is chosen
- Displays warning message with instructions
- Provides "Cancel" button for each running action

**Implementation**:
```json
{
  "type": 3,
  "content": {
    "query": "{\"version\":\"CustomEndpoint/1.0\",...\"filter\":\"status eq 'InProgress' or status eq 'Pending'\"}",
    "title": "⚠️ Currently Running Actions on Selected Devices",
    "noDataMessage": "✅ No actions currently running on selected devices. Safe to proceed with tests."
  },
  "conditionalVisibilities": [
    {
      "parameterName": "DeviceList",
      "comparison": "isNotEqualTo",
      "value": ""
    },
    {
      "parameterName": "ActionToExecute",
      "comparison": "isNotEqualTo",
      "value": "none"
    }
  ]
}
```

### 3. Implemented Auto-Population of Action IDs

**Problem**: Manual entry required for tracking and cancellation

**Solution**:
- Added clickable links in result tables that auto-populate the `LastActionId` parameter
- Added clickable "Cancel" buttons in running actions that auto-populate `CancelActionId`
- Uses grid formatters with Parameter linkTarget

**Implementation**:
```json
{
  "columnMatch": "Action ID",
  "formatter": 13,
  "formatOptions": {
    "linkTarget": "Parameter",
    "parameterName": "LastActionId",
    "parameterValue": "{0}",
    "linkLabel": "📊 Track",
    "linkIsContextBlade": false
  }
}
```

### 4. Fixed Conditional Visibility

**Problem**: Sections showing when parameters not ready or irrelevant

**Solution**:
- Each action execution block only shows when that specific action is selected
- Running actions check only shows when devices selected AND action chosen
- Status monitoring only shows when LastActionId is populated
- Cancellation only shows when CancelActionId is populated

**Example**:
```json
{
  "conditionalVisibilities": [
    {
      "parameterName": "ActionToExecute",
      "comparison": "isEqualTo",
      "value": "Run Antivirus Scan"
    },
    {
      "parameterName": "DeviceList",
      "comparison": "isNotEqualTo",
      "value": ""
    }
  ]
}
```

### 5. Added Auto-Refresh Capability

**Problem**: No automatic updates for action status

**Solution**:
- Added global `AutoRefresh` parameter with options: Off, 30s, 1min, 5min
- Applied `timeContextFromParameter` to all live data queries
- Default set to 30 seconds for optimal balance

**Implementation**:
```json
{
  "timeContext": {
    "durationMs": 0
  },
  "timeContextFromParameter": "AutoRefresh"
}
```

### 6. Proper Function Call Parameters

**Problem**: Incorrect parameter names and structure

**Solution**:
- Verified against DefenderC2Dispatcher/run.ps1
- Using correct action names: "Run Antivirus Scan", "Isolate Device", "Get All Actions", etc.
- Using `deviceIds` (plural) for multiple devices (comma-separated)
- Using `actionId` (singular) for status/cancellation
- All parameters passed via `urlParams` in CustomEndpoint queries

## Function App Integration

### Supported Actions

Based on `/functions/DefenderC2Dispatcher/run.ps1`:

1. **Run Antivirus Scan** - Parameters: `deviceIds`, `scanType`, `comment`
2. **Isolate Device** - Parameters: `deviceIds`, `isolationType`, `comment`
3. **Unisolate Device** - Parameters: `deviceIds`, `comment`
4. **Collect Investigation Package** - Parameters: `deviceIds`, `comment`
5. **Restrict App Execution** - Parameters: `deviceIds`, `comment`
6. **Unrestrict App Execution** - Parameters: `deviceIds`, `comment`
7. **Get Devices** - Parameters: `deviceFilter` (optional)
8. **Get Action Status** - Parameters: `actionId`
9. **Get All Actions** - Parameters: `filter` (optional)
10. **Cancel Action** - Parameters: `actionId`, `comment`

### Response Structure

The function returns:
```json
{
  "action": "Run Antivirus Scan",
  "status": "Initiated",
  "tenantId": "...",
  "timestamp": "2025-10-15T17:52:00.0000000Z",
  "message": "Action 'Run Antivirus Scan' initiated successfully",
  "actionIds": ["action-id-1", "action-id-2"],
  "details": "Antivirus scan initiated for 2 device(s)"
}
```

### Error Handling

For 400 errors (conflicting actions), the function returns:
```json
{
  "error": "Response status code does not indicate success: 400 (Bad Request).",
  "details": "Microsoft.PowerShell.Commands.HttpResponseException: ..."
}
```

The workbook now proactively checks for these conflicts before execution.

## Testing Sections

### 1. Device Discovery Test
- **Objective**: Verify device list auto-population
- **Expected**: Table shows all devices with risk scores, health status, IP addresses
- **Format**: Auto-refreshing with color-coded risk scores

### 2. Running Actions Check
- **Objective**: Verify no conflicting actions
- **Expected**: Shows any pending/in-progress actions OR confirmation none are running
- **Features**: Cancel buttons, warning messages, auto-refresh

### 3. Action Execution Testing
- **Objective**: Execute selected action
- **Expected**: Action initiates successfully, returns action ID
- **Features**: Separate test for each action type, auto-population of tracking ID

### 4. Action Status Monitoring
- **Objective**: Track action progress
- **Expected**: Shows real-time status updates
- **Features**: Auto-refresh, color-coded statuses, expandable section

### 5. Action Cancellation Test
- **Objective**: Cancel running actions
- **Expected**: Action cancelled successfully
- **Features**: Auto-populated from running actions table

### 6. Machine Actions History
- **Objective**: View all historical actions
- **Expected**: Comprehensive list with filtering
- **Features**: Export to Excel, auto-refresh, sortable columns

## Parameters

### Global Parameters (isGlobal: true)

1. **FunctionApp** - Azure resource selector for Function App
2. **FunctionAppName** - Auto-populated from FunctionApp, hidden
3. **TenantId** - Defender XDR Tenant ID dropdown
4. **DeviceList** - Multi-select device dropdown (auto-populated)
5. **ActionToExecute** - Action type selector
6. **LastActionId** - For tracking (auto-populated or manual)
7. **CancelActionId** - For cancellation (auto-populated or manual)
8. **AutoRefresh** - Refresh interval selector

### Local Parameters

1. **ScanType** - Quick or Full scan
2. **IsolationType** - Full or Selective isolation

## Visual Enhancements

### Status Icons and Colors

- ✅ Green: Succeeded/Initiated
- ⏳ Yellow: InProgress
- 🔵 Blue: Pending
- ❌ Red: Failed
- ⚫ Gray: Cancelled

### Risk Score Indicators

- 🔴 Red: High risk
- 🟡 Yellow: Medium risk
- 🟢 Green: Low/No risk

### Health Status Icons

- ✅ Success: Active
- ❌ Failed: Inactive
- ❓ Unknown: Other states

## File Structure

```
workbook/
├── DeviceManager-Testing.workbook.json          # Original file (kept for reference)
├── DeviceManager-Testing-FIXED.workbook.json    # Fixed version (THIS FILE)
└── DEVICEMANAGER-FIXES.md                       # This documentation
```

## Deployment

### To Use the Fixed Workbook:

1. In Azure Portal, navigate to Azure Monitor > Workbooks
2. Click "New" or edit existing "DeviceManager-Testing" workbook
3. Switch to "Advanced Editor" mode
4. Replace entire JSON with contents of `DeviceManager-Testing-FIXED.workbook.json`
5. Click "Apply" and "Save"

### Required Configuration:

1. **Function App**: Must have DefenderC2Dispatcher function deployed
2. **Environment Variables**: APPID and SECRETID must be configured
3. **Permissions**: User must have access to:
   - Read Function App resources
   - Query Azure Resource Graph
   - Execute Function App functions

## Testing Checklist

- [ ] Device list auto-populates correctly
- [ ] All 6 action types execute successfully
- [ ] Running actions check shows conflicts
- [ ] Warning message displays when appropriate
- [ ] Action IDs auto-populate on click
- [ ] Status monitoring updates automatically
- [ ] Cancellation works from running actions
- [ ] History shows all actions with correct formatting
- [ ] Auto-refresh works at selected interval
- [ ] Conditional visibility works for all sections
- [ ] Error messages display clearly
- [ ] No 400 errors when actions already running

## Known Limitations

1. **Client-Side Filtering**: Azure Workbooks cannot filter CustomEndpoint results by device ID client-side. The running actions check shows all running actions, not just for selected devices. This is a platform limitation.

2. **Manual Refresh**: Some CustomEndpoint queries require manual refresh click to execute (by design for cost/performance)

3. **CORS**: If function app has CORS restrictions, some queries may fail. Ensure CORS is configured to allow Azure Portal access.

## Future Enhancements

Potential improvements for future versions:

1. Add filter in function to return only actions for specific devices
2. Implement smart retry logic for failed actions
3. Add bulk action execution with progress tracking
4. Include action execution history charts/metrics
5. Add notification/alert integration
6. Implement action approval workflow

## References

- **PR**: #93
- **Issue**: Fixing correct autopopulation and functionality
- **Conversation**: conversationfix and conversationworkbookstests
- **Function Code**: `/functions/DefenderC2Dispatcher/run.ps1`
- **Microsoft Docs**: [Azure Workbooks Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)

## Change Log

### 2025-10-15 17:52:00 UTC - Initial Fixed Version
- Fixed device list auto-population with criteriaData
- Added running actions check with warnings
- Implemented action ID auto-population
- Fixed all conditional visibility rules
- Added auto-refresh capability
- Updated all timestamps
- Verified against function code
- Added comprehensive error handling
- Improved visual indicators
- Added detailed documentation

---

**Status**: ✅ Ready for Testing and Deployment
**Testing Required**: Yes - Full end-to-end testing in Azure environment
**Breaking Changes**: None - Backward compatible with existing function code
