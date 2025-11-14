# DefenderC2 Device Manager Workbooks - Documentation

**Created:** 2025-10-16  
**Author:** GitHub Copilot for akefallonitis  
**Related PR:** #93

## Overview

This document describes two new Azure Workbook implementations for DefenderC2 Device Manager that address the following requirements:

1. **Error handling** for duplicate machine actions (400 Bad Request)
2. **Auto-population** of action IDs and device lists
3. **Warning messages** for pending actions on selected devices
4. **List and cancel** machine actions functionality
5. **Auto-refresh** capability for real-time monitoring
6. **Conditional visibility** for improved UX

## Workbook Versions

### 1. DeviceManager-CustomEndpoint.json

**Approach:** Uses CustomEndpoint for ALL operations (data retrieval AND action execution)

#### Features
- ✅ Full CustomEndpoint implementation
- ✅ Auto-refresh (configurable: 30s, 1m, 5m, or off)
- ✅ Auto-populated device selection from Defender XDR
- ✅ Auto-populated action IDs (click to copy)
- ✅ Pending action warning system
- ✅ List all pending/running actions
- ✅ List full machine action history
- ✅ Track specific action status
- ✅ Cancel actions
- ✅ Device inventory with risk scoring
- ✅ All 6 machine actions supported

#### Supported Actions
1. 🔍 Run Antivirus Scan (Quick/Full)
2. 🔒 Isolate Device (Full/Selective)
3. 🔓 Unisolate Device
4. 📦 Collect Investigation Package
5. 🚫 Restrict App Execution
6. ✅ Unrestrict App Execution

#### Pros
- Simple, consistent architecture
- All operations use the same pattern
- Easier to debug and troubleshoot
- Direct JSON responses visible

#### Cons
- May require more permissions for Azure Functions
- CustomEndpoint queries are triggered on parameter changes
- Less native Azure integration

### 2. DeviceManager-Hybrid.json

**Approach:** Uses ARM Actions for machine action execution + CustomEndpoint for data retrieval

#### Features
- ✅ ARM Actions for reliable machine action execution
- ✅ CustomEndpoint for data queries and monitoring
- ✅ Auto-refresh (configurable: 30s, 1m, 5m, or off)
- ✅ Auto-populated device selection from Defender XDR
- ✅ Auto-populated action IDs (click to copy)
- ✅ Pending action warning system
- ✅ List all pending/running actions
- ✅ List full machine action history
- ✅ Track specific action status
- ✅ Cancel actions
- ✅ Device inventory with risk scoring
- ✅ All 6 machine actions supported

#### Supported Actions
1. 🔍 Run Antivirus Scan (Quick/Full) - **ARM Action**
2. 🔒 Isolate Device (Full/Selective) - **ARM Action**
3. 🔓 Unisolate Device - **ARM Action**
4. 📦 Collect Investigation Package - **ARM Action**
5. 🚫 Restrict App Execution - **ARM Action**
6. ✅ Unrestrict App Execution - **ARM Action**

#### Pros
- ARM Actions are native Azure operations (better trust/permissions)
- More reliable for critical actions (isolation, restrictions)
- Better integration with Azure RBAC
- Confirmation dialogs built-in

#### Cons
- Mixed architecture (ARM + CustomEndpoint)
- ARM Actions can be more restrictive
- Slightly more complex to debug

## Common Features

Both versions include:

### Auto-Population
- **Device List:** Automatically populated from Defender XDR API
- **Action IDs:** Click any Action ID in tables to auto-populate tracking/cancellation fields
- **Connection Parameters:** Auto-extracted from selected Function App

### Error Handling
- **Pending Action Detection:** Shows all pending actions before execution
- **Warning System:** Displays warning when pending actions exist
- **400 Error Prevention:** Warns users about duplicate actions
- **Visual Indicators:** Color-coded status (success, failed, pending, etc.)

### Auto-Refresh
Configurable intervals:
- Off (manual refresh only)
- 30 seconds (default)
- 1 minute
- 5 minutes

### Conditional Visibility
- Action execution sections only show when devices are selected
- Track action section only shows when Action ID is entered
- Cancel action section only shows when Action ID is entered
- Warning section only shows when devices are selected

### Visual Enhancements
- 🔴 High risk devices
- 🟡 Medium risk devices
- 🟢 Low risk devices
- ✅ Succeeded actions
- ❌ Failed actions
- ⏳ Pending actions
- 🔄 In Progress actions
- 🚫 Cancelled actions

## Usage Guide

### Initial Setup

1. **Select Function App**
   - Choose your DefenderC2 Function App from the dropdown
   - Connection parameters auto-populate

2. **Select Tenant**
   - Choose your Defender XDR tenant ID
   - This determines which devices you'll see

3. **Select Devices**
   - Device list auto-populates from Defender XDR
   - Multi-select supported
   - Shows computer DNS name

### Executing Actions

#### CustomEndpoint Version
1. Select devices
2. Choose action from dropdown
3. Configure action parameters (scan type, isolation type)
4. Review pending actions warning if displayed
5. Result appears in execution section

#### Hybrid Version
1. Select devices
2. Configure action parameters (scan type, isolation type)
3. Review pending actions warning if displayed
4. Click action button (e.g., "🔒 Isolate Devices")
5. Confirm in ARM Action dialog
6. Result appears in ARM Action output

### Tracking Actions

1. View action ID in "Currently Running Actions" or "Machine Actions History"
2. Click the Action ID to copy
3. It auto-populates the "Track Action ID" field
4. View detailed status in the "Track Action Status" section
5. Auto-refresh keeps status updated

### Cancelling Actions

1. View pending action ID in "Currently Running Actions"
2. Click the Action ID to copy
3. It auto-populates the "Cancel Action ID" field
4. Cancellation result appears immediately

## Error Prevention

### 400 Bad Request Error

**Problem:** Running the same action on a device that already has a pending action of that type

**Solution:**
1. Check "Pending Actions Warning" section before executing
2. Review "Currently Running Actions" table
3. Filter by your selected devices
4. Wait for pending actions to complete or cancel them first

### Example Scenario

**Scenario:** You want to isolate `device-123`, but it already has a pending isolation action

**Steps:**
1. Warning section shows: "Pending Isolation on device-123"
2. Go to "Currently Running Actions"
3. Find the action ID for device-123
4. Option A: Wait for it to complete (monitor via auto-refresh)
5. Option B: Cancel it via "Cancel Action" section
6. Then execute new isolation

## API Reference

### Function App Endpoints

All operations call: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher`

#### Get Devices
```
POST ?action=Get Devices&tenantId={TenantId}
```

#### Execute Action
```
POST ?action={ActionType}&tenantId={TenantId}&deviceIds={DeviceIds}&comment={Comment}
```

#### Get All Actions
```
POST ?action=Get All Actions&tenantId={TenantId}&filter={ODataFilter}
```

#### Get Action Status
```
POST ?action=Get Action Status&tenantId={TenantId}&actionId={ActionId}
```

#### Cancel Action
```
POST ?action=Cancel Action&tenantId={TenantId}&actionId={ActionId}&comment={Comment}
```

## Deployment

### Prerequisites
- Azure subscription with DefenderC2 Function App deployed
- Microsoft Defender XDR with devices onboarded
- Appropriate permissions to view/create Azure Workbooks

### Import Steps

1. Navigate to Azure Portal > Monitor > Workbooks
2. Click "New"
3. Click "Advanced Editor" (</> icon)
4. Paste the JSON content from either:
   - `DeviceManager-CustomEndpoint.json`
   - `DeviceManager-Hybrid.json`
5. Click "Apply"
6. Configure and save

## Troubleshooting

### Device List Not Populating
- Verify Function App is running
- Check Function App has correct permissions
- Verify Tenant ID is correct
- Check browser console for errors

### Actions Failing with 400 Error
- Check "Pending Actions Warning" section
- Verify no duplicate pending actions exist
- Cancel existing pending actions if needed

### Auto-Refresh Not Working
- Check AutoRefreshInterval parameter is not "Off"
- Verify network connectivity
- Check Function App is responsive

### Action IDs Not Showing
- Verify action was executed successfully
- Check "Machine Actions History" section
- Use auto-refresh to update data

## Version Comparison

| Feature | CustomEndpoint | Hybrid |
|---------|----------------|--------|
| Device Query | CustomEndpoint | CustomEndpoint |
| Action Execution | CustomEndpoint | ARM Actions |
| Status Tracking | CustomEndpoint | CustomEndpoint |
| Cancel Actions | CustomEndpoint | CustomEndpoint |
| Auto-Refresh | ✅ | ✅ |
| Auto-Population | ✅ | ✅ |
| Error Handling | ✅ | ✅ |
| Confirmation Dialogs | ❌ | ✅ |
| Native Azure Integration | Partial | Full |
| Debugging Ease | Easier | Moderate |
| RBAC Integration | Good | Better |

## Recommendations

### Use CustomEndpoint Version When:
- You want simpler, more consistent architecture
- You need to see raw JSON responses
- You're debugging or testing
- You want all operations to follow the same pattern

### Use Hybrid Version When:
- You need better Azure RBAC integration
- You want native ARM action confirmation dialogs
- You're in a production environment
- You want separation of concerns (queries vs. actions)

## Security Considerations

1. **Function App Authentication:** Ensure Function App has proper authentication configured
2. **RBAC Permissions:** Users need appropriate permissions to execute actions
3. **Audit Trail:** All actions are logged with user and timestamp
4. **Tenant Isolation:** Each tenant's data is isolated via tenantId parameter

## Future Enhancements

Potential improvements for future versions:
- Advanced filtering for machine actions history
- Bulk action cancellation
- Export action history to CSV
- Custom action templates
- Scheduled action execution
- Integration with Azure Logic Apps
- Multi-tenant comparison views
- Device group management

## Support

For issues or questions:
- Review this documentation
- Check the conversation logs in `/conversationfix` and `/conversationworkbookstests`
- Refer to PR #93 for implementation details
- Review Azure Function logs for API errors

---

**Last Updated:** 2025-10-16 00:00:00 UTC  
**Version:** 1.0  
**Maintainer:** akefallonitis
