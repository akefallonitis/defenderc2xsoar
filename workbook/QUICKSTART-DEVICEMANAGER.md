# Quick Start Guide - DeviceManager-Testing Workbook

## Deploy the Fixed Workbook in 5 Minutes

### Step 1: Access Azure Workbooks

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Monitor** > **Workbooks**
3. Click **+ New** to create a new workbook

### Step 2: Load the Fixed Workbook

1. Click the **</>** (Advanced Editor) button in the toolbar
2. Delete all existing JSON in the editor
3. Copy the entire contents of `DeviceManager-Testing.workbook.json`
4. Paste into the Advanced Editor
5. Click **Apply**

### Step 3: Save the Workbook

1. Click **💾 Save** button
2. **Title**: `DefenderC2 Device Manager - Testing`
3. **Subscription**: Select your subscription
4. **Resource Group**: Select the resource group containing your Function App
5. Click **Save**

### Step 4: Configure Parameters

Once the workbook loads, you'll see these parameters at the top:

1. **DefenderC2 Function App**: Select your Function App from the dropdown
2. **Defender XDR Tenant ID**: Select your tenant (auto-populated from subscriptions)
3. **Select Devices for Testing**: Device list will auto-populate after above are selected
4. **Select Action to Test**: Choose an action type
5. **Auto Refresh Interval**: Set to "Every 30 seconds" (recommended)

### Step 5: Run Your First Test

1. Wait for device list to populate (may take 10-30 seconds)
2. Select one or more devices
3. Choose "🔍 Test Antivirus Scan" from action dropdown
4. Expand "🚀 Action Execution Testing" section
5. Click **Refresh** button on the scan result section
6. You should see: ✅ Action initiated with an Action ID
7. Click the **📊 Track** link to monitor progress

## Understanding the Workbook Sections

### 🔍 Device Discovery Test
- **What it does**: Shows all devices in your tenant
- **Auto-refresh**: Yes (based on interval setting)
- **Features**: 
  - Color-coded risk scores (🔴 High, 🟡 Medium, 🟢 Low)
  - Health status indicators
  - Sortable and filterable table
  - Export to Excel

### ⚡ Running Actions Check
- **What it does**: Shows if any actions are currently running
- **When it appears**: Only when you select devices and an action
- **Why it matters**: Prevents 400 errors from conflicting actions
- **Features**:
  - Shows pending/in-progress actions
  - Cancel button for each action
  - Warning message if conflicts detected

### 🚀 Action Execution Testing
- **What it does**: Executes the selected action
- **How to use**: 
  1. Select action type
  2. Click Refresh button
  3. Click "📊 Track" link to monitor
- **Actions available**:
  - 🔍 Antivirus Scan (Quick/Full)
  - 🔒 Device Isolation (Full/Selective)
  - 🔓 Device Unisolation
  - 📦 Investigation Package Collection
  - 🚫 App Execution Restriction
  - ✅ App Execution Unrestriction

### 📊 Action Status Monitoring
- **What it does**: Tracks progress of executed actions
- **Auto-refresh**: Yes - updates every 30 seconds
- **Status indicators**:
  - ✅ Succeeded (green)
  - ⏳ InProgress (yellow)
  - 🔵 Pending (blue)
  - ❌ Failed (red)
  - ⚫ Cancelled (gray)

### ❌ Action Cancellation Test
- **What it does**: Cancels running actions
- **How to use**:
  1. Click "🛑 Cancel" on a running action
  2. Click Refresh in cancellation section
  3. Verify action is cancelled

### 📜 Machine Actions History
- **What it does**: Shows all historical actions
- **Auto-refresh**: Yes
- **Features**:
  - Full action history
  - Sortable by date
  - Filter by status
  - Click Action ID to track

## Common Scenarios

### Scenario 1: Quick Health Check
1. Open workbook
2. Select Function App and Tenant
3. Expand "🔍 Device Discovery Test"
4. Review device health statuses and risk scores
5. Identify high-risk devices (🔴)

### Scenario 2: Scan Multiple Devices
1. Select devices from dropdown (can select multiple)
2. Choose "🔍 Test Antivirus Scan"
3. Check "⚡ Running Actions Check" - ensure no conflicts
4. Expand "🚀 Action Execution Testing"
5. Click Refresh to execute
6. Click "📊 Track" to monitor progress
7. Wait for status to change to ✅ Succeeded

### Scenario 3: Isolate Risky Device
1. Identify high-risk device in Device Discovery
2. Select the device
3. Choose "🔒 Test Device Isolation"
4. Set isolation type (Full recommended)
5. Check for running actions first
6. Execute isolation
7. Monitor in Action Status Monitoring

### Scenario 4: Cancel Stuck Action
1. Go to "⚡ Running Actions Check" section
2. Find the stuck action
3. Click "🛑 Cancel" button
4. Go to "❌ Action Cancellation Test" section
5. Click Refresh
6. Verify cancellation succeeded

### Scenario 5: Track Historical Actions
1. Expand "📜 Machine Actions History"
2. Set Auto Refresh to "Every 30 seconds"
3. Filter by machine name if needed
4. Click "📊 Track" on any action to see details
5. Export to Excel for reporting

## Troubleshooting

### Device List Shows "< query failed >"

**Possible Causes**:
- Function App not selected
- Tenant ID not selected
- Function App not running
- Network connectivity issues

**Solutions**:
1. Ensure Function App is selected first
2. Wait 10-30 seconds after selecting
3. Click Refresh button manually
4. Check Function App is running in Azure Portal
5. Verify CORS settings allow Azure Portal

### Getting 400 Bad Request Errors

**Cause**: Same action already running on device

**Solution**:
1. Check "⚡ Running Actions Check" section
2. Wait for existing action to complete
3. OR click "🛑 Cancel" on the running action
4. Then try again

### Action Status Not Updating

**Possible Causes**:
- Auto-refresh is off
- Action ID not populated

**Solutions**:
1. Set Auto Refresh to "Every 30 seconds"
2. Ensure you clicked "📊 Track" to populate Action ID
3. Manually click Refresh button
4. Check action exists in Machine Actions History

### No Actions Appearing in History

**Possible Causes**:
- No actions executed yet
- Different tenant selected
- Time filter (none in this workbook)

**Solutions**:
1. Execute an action first
2. Verify correct Tenant ID selected
3. Wait a few seconds and refresh
4. Check Function App logs for errors

### Auto-Refresh Not Working

**Solution**:
1. Verify Auto Refresh is not set to "Off"
2. Save the workbook if changes not persisted
3. Refresh browser page
4. Check Azure Portal browser console for errors

## Best Practices

### ✅ DO:
- Always check running actions before executing new ones
- Use auto-refresh for monitoring
- Click "📊 Track" immediately after action execution
- Review warning messages before proceeding
- Export action history regularly
- Test on single device first before bulk actions

### ❌ DON'T:
- Execute same action on device with pending action
- Ignore warning messages
- Set auto-refresh too frequent (< 30 seconds)
- Execute actions without verifying device selection
- Cancel actions unnecessarily
- Run bulk actions without testing first

## Performance Tips

1. **Auto-Refresh Interval**:
   - Use 30 seconds for active monitoring
   - Use 1 minute for background monitoring
   - Use 5 minutes for low-priority checks
   - Turn off when not actively using

2. **Device Selection**:
   - Limit to 10-20 devices for bulk actions
   - Test on 1 device first
   - Monitor performance as you scale

3. **Section Visibility**:
   - Collapse unused sections
   - Only expand what you need
   - Use browser bookmarks for frequently used workbook

## Security Considerations

1. **Access Control**:
   - Only authorized users should access workbook
   - Function App RBAC controls action execution
   - Audit logs track all actions

2. **Action Review**:
   - Review devices before isolation
   - Verify action type before execution
   - Check running actions to avoid conflicts
   - Document reason for actions

3. **Monitoring**:
   - Review Machine Actions History regularly
   - Export logs for compliance
   - Monitor for unusual patterns
   - Alert on failed actions

## Support

For issues or questions:
1. Check [DEVICEMANAGER-FIXES.md](DEVICEMANAGER-FIXES.md) for technical details
2. Review Function App logs in Azure Portal
3. Check PR #93 for discussion history
4. Verify function code in `/functions/DefenderC2Dispatcher/run.ps1`

## Quick Reference

| Parameter | Type | Required | Auto-Populated |
|-----------|------|----------|----------------|
| Function App | Resource | Yes | No |
| Function App Name | Text | Yes | Yes |
| Tenant ID | Dropdown | Yes | Yes |
| Device List | Multi-select | No | Yes |
| Action Type | Dropdown | No | No |
| Scan Type | Dropdown | No | No |
| Isolation Type | Dropdown | No | No |
| Last Action ID | Text | No | Yes (on click) |
| Cancel Action ID | Text | No | Yes (on click) |
| Auto Refresh | Dropdown | No | No |

| Action | Parameters | Response |
|--------|-----------|----------|
| Run Antivirus Scan | deviceIds, scanType, comment | actionIds |
| Isolate Device | deviceIds, isolationType, comment | actionIds |
| Unisolate Device | deviceIds, comment | actionIds |
| Collect Investigation Package | deviceIds, comment | actionIds |
| Restrict App Execution | deviceIds, comment | actionIds |
| Unrestrict App Execution | deviceIds, comment | actionIds |
| Get Action Status | actionId | actionStatus |
| Cancel Action | actionId, comment | cancelResult |

---

**Version**: 1.0  
**Last Updated**: 2025-10-15 17:52:00 UTC  
**Status**: ✅ Ready for Production Use
