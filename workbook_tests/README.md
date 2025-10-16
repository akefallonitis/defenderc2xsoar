# DeviceManager Workbook Versions

## Overview
This folder contains two versions of the DefenderC2 Device Manager workbook, each optimized for different use cases.

## Version 1: CustomEndpoint-Only
**File:** `DeviceManager-CustomEndpoint-Only.workbook.json`

### Features
- ✅ **All CustomEndpoint queries** for maximum compatibility
- ✅ **Auto-refresh capability** for real-time updates
- ✅ **Auto-population** of devices and tenants
- ✅ **Pending action detection** with warnings
- ✅ **Action ID auto-population** for tracking
- ✅ **Cancel functionality** with proper error handling
- ✅ **Full machine actions history**

### Best For
- **Production environments** requiring maximum stability
- **Consistent behavior** across all Azure regions
- **Simplified troubleshooting** (single query type)
- **Auto-refresh requirements** for monitoring dashboards

### How It Works
1. Select Function App → Auto-populates connection parameters
2. Select Tenant → Auto-populates from Azure Resource Graph
3. Select Devices → Auto-populates from Defender XDR API
4. Pending Actions Check → Warns if same action is already running
5. Execute Action → Returns Action IDs for tracking
6. Auto-refresh → Updates every 30 seconds (configurable)

### Key Advantages
- **No ARM routing issues** - Direct HTTPS calls
- **Better error messages** - Clear API responses
- **Easier debugging** - Standard HTTP requests
- **Consistent behavior** - Works the same everywhere

## Version 2: Hybrid (CustomEndpoint + ARM Actions)
**File:** `DeviceManager-Hybrid.workbook.json`

### Features
- ✅ **CustomEndpoints for queries** (device list, history, status)
- ✅ **ARM Actions for execution** (better Azure integration)
- ✅ **Enhanced UI** with action buttons
- ✅ **Same auto-features** as CustomEndpoint version
- ✅ **Better Azure RBAC integration**

### Best For
- **Azure-native workflows** requiring ARM integration
- **RBAC-controlled environments** with strict permissions
- **UI preference** for button-based actions
- **Azure Policy compliance** requirements

### How It Works
1-3. Same as CustomEndpoint version (discovery and selection)
4. Pending Actions Check → CustomEndpoint query
5. Execute Action → ARM Action with confirmation dialog
6. Track Status → CustomEndpoint queries with auto-refresh

### Key Advantages
- **Azure RBAC integration** - Respects Azure permissions
- **Audit trails** - Actions logged in Azure Activity Log
- **Confirmation dialogs** - Built-in ARM action prompts
- **Resource tagging** - Better Azure resource association

## Comparison Table

| Feature | CustomEndpoint-Only | Hybrid Version |
|---------|-------------------|----------------|
| **Device Discovery** | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Action Execution** | ✅ CustomEndpoint | ✅ ARM Actions |
| **Status Tracking** | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Machine History** | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Cancel Actions** | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Auto-refresh** | ✅ Full support | ✅ Full support |
| **Error Handling** | ✅ Inline errors | ✅ ARM dialogs + inline |
| **RBAC Integration** | ⚠️ Function App only | ✅ Full Azure RBAC |
| **Audit Logging** | ⚠️ Function logs only | ✅ Azure Activity Log |
| **Stability** | ✅✅ High | ✅ Good (ARM routing) |
| **Troubleshooting** | ✅✅ Easy | ⚠️ ARM complexities |

## Installation

### For Both Versions
1. Navigate to Azure Portal → Workbooks
2. Click "New" or open existing workbook
3. Click "Advanced Editor" (</> icon)
4. Paste the JSON content
5. Click "Apply"
6. Configure fallbackResourceIds if needed
7. Save the workbook

### Required Permissions
- **Reader** role on subscription (for Resource Graph queries)
- **Function App permissions** for the DefenderC2 Function App
- **Defender XDR permissions** (configured in Function App)

## Configuration

### Update Fallback Resource IDs
Both workbooks contain:
```json
"fallbackResourceIds": [
  "/subscriptions/YOUR-SUBSCRIPTION-ID/resourcegroups/YOUR-RESOURCE-GROUP"
]
```

Update this to match your Azure environment.

### Update Timestamps
Search for `2025-10-16 00:00:00 UTC` and update to current timestamp if desired.

### Update User Attribution
Search for `akefallonitis` and replace with your username if desired.

## Troubleshooting

### Common Issues

#### 1. Device List Shows "<query failed>"
**Cause:** Function App parameters not populated yet  
**Solution:** Select Function App first, wait 2-3 seconds for auto-population

#### 2. 400 Bad Request Error
**Cause:** Attempting to run same action on device with pending action  
**Solution:** Check "Pending Actions" section, wait for completion or cancel existing action

#### 3. Action IDs Not Auto-populating
**Cause:** JSONPath transformer issue  
**Solution:** Check that $.actionIds[*] path is correct in function response

#### 4. ARM Action Not Executing (Hybrid Version Only)
**Cause:** ARM routing issues or insufficient permissions  
**Solution:** Verify RBAC permissions, check Function App invoke permissions

### Debug Mode
To enable detailed logging:
1. Open browser developer tools (F12)
2. Go to Network tab
3. Execute action
4. Inspect request/response in network log

## API Endpoints Reference

### Function Actions
- `Get Devices` - Returns all devices
- `Get All Actions` - Returns machine actions history (supports filter parameter)
- `Get Action Status` - Returns specific action status (requires actionId)
- `Cancel Action` - Cancels specific action (requires actionId)
- `Run Antivirus Scan` - Executes antivirus scan (requires deviceIds)
- `Isolate Device` - Isolates device (requires deviceIds, isolationType)
- `Unisolate Device` - Removes isolation (requires deviceIds)
- `Collect Investigation Package` - Collects forensic package (requires deviceIds)
- `Restrict App Execution` - Restricts apps (requires deviceIds)
- `Unrestrict App Execution` - Removes restrictions (requires deviceIds)

### Parameters
- `action` - Action type (required)
- `tenantId` - Defender XDR tenant ID (required)
- `deviceIds` - Comma-separated device IDs (required for device actions)
- `actionId` - Specific action ID (required for status/cancel)
- `filter` - OData filter for Get All Actions (optional)
- `comment` - Comment for action (optional)
- `scanType` - "Quick" or "Full" (for scans)
- `isolationType` - "Full" or "Selective" (for isolation)

## Best Practices

### 1. Always Check Pending Actions First
Before executing actions, review the "Pending Actions" section to avoid 400 errors.

### 2. Use Auto-refresh Wisely
- **10 seconds** - Active incident response
- **30 seconds** - Normal monitoring (default)
- **1-5 minutes** - Background monitoring
- **Off** - Manual control only

### 3. Copy Action IDs Immediately
After execution, copy Action IDs to track status or enable cancellation if needed.

### 4. Filter Machine History
Use the filter functionality to narrow down results by:
- Device name
- Action type
- Status
- Time range

### 5. Export for Reporting
Both versions support "Export to Excel" for machine actions and device inventory.

## Version History

### v1.0 - 2025-10-16
- Initial release
- CustomEndpoint-Only version with full functionality
- Hybrid version with ARM Actions integration
- Complete documentation and troubleshooting guide

## Support

### Issues
Report issues on GitHub: https://github.com/akefallonitis/defenderc2xsoar/issues

### Conversation History
Full development conversation and requirements: `/workspaces/defenderc2xsoar/conversationfix`

### Sample Workbooks
Additional examples: `/workspaces/defenderc2xsoar/conversationworkbookstests`

## Contributing
Improvements and bug fixes welcome! Please:
1. Test thoroughly in your environment
2. Document any changes
3. Submit pull request with clear description

---

**Maintained by:** akefallonitis  
**Last Updated:** 2025-10-16  
**Repository:** https://github.com/akefallonitis/defenderc2xsoar
