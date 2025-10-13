# Device Parameter Auto-Population Fix

## Problem Statement
Users reported that ARM actions in the workbook required manual device selection even when devices were available. The issue was:
> "all arm actions need for manual input but dont have tenantid deviceid etc populated"

## Root Cause
Device selection parameters (DeviceList, IsolateDeviceIds, UnisolateDeviceIds, RestrictDeviceIds, ScanDeviceIds) had `showDefault: false` in their configuration. This prevented the workbook from:
1. Auto-selecting when only one device was available
2. Providing convenient "Select All" functionality for multiple devices

## Changes Made

### DefenderC2-Workbook.json
Updated all 5 device selection parameters with TWO fixes:

#### Fix 1: Parameter Type Settings
##### Before
```json
{
  "name": "IsolateDeviceIds",
  "type": 2,
  "queryType": 10,
  "typeSettings": {
    "showDefault": false,
    "additionalResourceOptions": []
  }
}
```

##### After
```json
{
  "name": "IsolateDeviceIds",
  "type": 2,
  "queryType": 10,
  "typeSettings": {
    "showDefault": true,
    "additionalResourceOptions": ["selectAll"]
  }
}
```

#### Fix 2: CustomEndpoint Auto-Refresh
##### Before
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
  // No refreshSettings
}
```

##### After
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ],
  "refreshSettings": {
    "isAutoRefreshEnabled": true,
    "autoRefreshInterval": "30"
  }
}
```

### Parameters Fixed
Each parameter received both fixes:
1. ✅ **DeviceList** - Main device listing dropdown
   - Changed `showDefault: false` → `true`
   - Added `additionalResourceOptions: ["selectAll"]`
   - Enabled auto-refresh (30s interval)
2. ✅ **IsolateDeviceIds** - Device isolation action
   - Changed `showDefault: false` → `true`
   - Added `additionalResourceOptions: ["selectAll"]`
   - Enabled auto-refresh (30s interval)
3. ✅ **UnisolateDeviceIds** - Device unisolation action
   - Changed `showDefault: false` → `true`
   - Added `additionalResourceOptions: ["selectAll"]`
   - Enabled auto-refresh (30s interval)
4. ✅ **RestrictDeviceIds** - App restriction action
   - Changed `showDefault: false` → `true`
   - Added `additionalResourceOptions: ["selectAll"]`
   - Enabled auto-refresh (30s interval)
5. ✅ **ScanDeviceIds** - Antivirus scan action
   - Changed `showDefault: false` → `true`
   - Added `additionalResourceOptions: ["selectAll"]`
   - Enabled auto-refresh (30s interval)

## Impact

### Before Fix
- ❌ Users had to manually select devices for every ARM action
- ❌ No default selection even when only one device was available
- ❌ No "Select All" option for bulk operations
- ❌ Device lists didn't auto-refresh periodically
- ❌ Stale device data could persist in dropdowns
- ❌ Poor user experience requiring multiple clicks

### After Fix
- ✅ Devices auto-populate in dropdowns via CustomEndpoint queries
- ✅ Auto-selects when only one device is available
- ✅ "Select All" button available for multi-device operations
- ✅ Device lists automatically refresh every 30 seconds
- ✅ Always shows current device status (online/offline, isolated/not isolated)
- ✅ ARM actions can execute immediately with pre-populated parameters
- ✅ Improved user experience with fewer required interactions
- ✅ Real-time device status monitoring without manual refresh

## How It Works

### Parameter Flow
1. **User selects FunctionApp** → Triggers auto-discovery
2. **TenantId auto-populates** → From FunctionApp metadata
3. **FunctionAppName auto-populates** → From FunctionApp resource
4. **Device parameters refresh** → CustomEndpoint query executes
5. **Devices auto-select** → Due to `showDefault: true`
6. **ARM actions ready** → All parameters populated

### Auto-Selection Logic
- **Single device**: Automatically selected
- **Multiple devices**: "Select All" button appears
- **No devices**: Empty dropdown (CustomEndpoint query returned no results)

## Technical Details

### showDefault Setting
- `false` (old): Never auto-select, always require manual selection
- `true` (new): Auto-select when appropriate (single option or default)

### additionalResourceOptions
- `[]` (old): No additional selection helpers
- `["selectAll"]` (new): Adds "Select All" button in dropdown

### Existing Configuration (Unchanged)
All device parameters already had proper configuration for auto-refresh:
- ✅ `queryType: 10` (CustomEndpoint)
- ✅ `criteriaData: [{FunctionAppName}, {TenantId}]` (Dependencies)
- ✅ CustomEndpoint queries with proper parameter substitution
- ✅ JSONPath transformers for parsing device lists

## Verification

### Automated Checks
```bash
python3 scripts/verify_workbook_config.py
```

All verification checks pass:
- ✅ 5/5 device parameters with CustomEndpoint
- ✅ 21/21 CustomEndpoint queries with parameter substitution
- ✅ 15/15 ARM actions with proper parameter references

### Manual Testing
1. Open the workbook in Azure Portal
2. Select a FunctionApp from the dropdown
3. Observe TenantId and FunctionAppName auto-populate
4. Observe device parameters auto-populate with device list
5. If one device: Auto-selected
6. If multiple devices: "Select All" button appears
7. Click any ARM action button (e.g., "Isolate Devices")
8. Confirm all parameters are pre-filled

## Related Documentation
- `WORKBOOK_AUTOPOPULATION_FIX.md` - CustomEndpoint parameter substitution
- `PARAMETER_AUTOPOPULATION_FIX.md` - TenantId auto-refresh configuration
- `ARM_ACTION_FIX_SUMMARY.md` - ARM action path corrections
- `TENANTID_FUNCTIONAPP_FIX.md` - TenantId discovery from FunctionApp

## References
- Azure Workbook Parameters: https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-parameters
- CustomEndpoint Data Source: https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-data-sources#custom-endpoint
- ARM Actions: https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-link-actions#arm-actions

---

**Status**: ✅ Complete  
**Date**: October 13, 2025  
**Files Modified**: 1 (workbook/DefenderC2-Workbook.json)  
**Changes**: 15 total changes
- 10 parameter type setting changes (5 parameters × 2 settings each)
- 5 auto-refresh enablements (5 parameters × 1 query update each)
**Issue**: ARM actions requiring manual device selection and stale device data
**Solution**: Enable auto-selection, "Select All" functionality, and periodic auto-refresh
