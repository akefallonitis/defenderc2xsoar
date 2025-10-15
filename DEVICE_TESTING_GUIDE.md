# Device Functionality Testing Guide

## Overview

This guide provides comprehensive instructions for testing all device-related functionality in the DefenderC2 workbook. The DeviceManager-Testing workbook is specifically designed to test every aspect of device management.

## Test Workbook Features

### Core Functionality
- ✅ **Device Discovery Testing** - Auto-population of device lists from Defender XDR
- ✅ **Device Action Testing** - All 6 action types
  - Antivirus Scan (Quick/Full)
  - Device Isolation (Full/Selective)
  - Device Unisolation
  - Investigation Package Collection
  - App Execution Restriction
  - App Execution Unrestriction
- ✅ **Status Monitoring** - Real-time action tracking with auto-refresh
- ✅ **Action Cancellation** - Cancel running/pending actions
- ✅ **Error Prevention** - Check for conflicting actions before execution
- ✅ **Conditional Visibility** - Smart UI that shows only relevant sections

## Prerequisites

Before starting tests:

1. **Azure Resources**
   - DefenderC2 Function App deployed and running
   - Valid Azure subscription
   - Log Analytics Workspace configured
   - Workbook deployed to Azure

2. **Permissions**
   - Reader access to Function App
   - Workbook Contributor role
   - Defender XDR API permissions

3. **Test Environment**
   - Valid Tenant ID for Defender XDR
   - At least one test device enrolled in Defender
   - Network connectivity to Azure services

## Deployment Instructions

### Step 1: Upload Workbook to Azure

```bash
# Using Azure Portal
1. Navigate to Azure Portal > Workbooks
2. Click "New" > "Advanced Editor"
3. Paste content from DeviceManager-Testing.workbook.json
4. Click "Apply"
5. Save workbook with name "DefenderC2 Device Testing"
```

### Step 2: Configure Parameters

1. **Function App Selection**
   - Select your DefenderC2 Function App from dropdown
   - Verify FunctionAppName auto-populates

2. **Tenant ID Configuration**
   - Enter your Defender XDR Tenant ID
   - Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

3. **Auto-Refresh Settings**
   - Recommended: "Every 30 seconds" for testing
   - Can adjust based on test requirements

## Test Procedures

### Test 1: Device Discovery

**Objective:** Verify device list auto-population

**Steps:**
1. Open DeviceManager-Testing workbook
2. Navigate to "🔍 Device Discovery Test" section
3. Expand the section
4. Observe the "Device Inventory - Live Test Data" table

**Expected Results:**
- ✅ Table displays all enrolled devices
- ✅ Device names show correctly (not just IDs)
- ✅ Risk scores display with color coding (🔴 High, 🟡 Medium, 🟢 Low/None)
- ✅ Health status shows with icons (✅ Active, ❌ Inactive)
- ✅ Last IP and Last Seen information populated
- ✅ Can filter and sort data
- ✅ Export to Excel works

**Pass Criteria:**
- All enrolled devices appear in list
- No `<query failed>` errors
- Data refreshes correctly

**Troubleshooting:**
- **No devices shown:** Check Function App is running
- **Query failed:** Verify Tenant ID is correct
- **Timeout:** Check Function App logs for errors

---

### Test 2: Running Actions Check

**Objective:** Verify detection of currently running actions

**Steps:**
1. Select an action from "Select Action to Test" dropdown
2. Observe "⚙️ Running Actions Check" section appears
3. Review the table of currently running actions

**Expected Results:**
- ✅ Section becomes visible when action selected
- ✅ Shows all currently pending/in-progress actions
- ✅ Displays device ID, name, action type, action ID, status, and start time
- ✅ Status indicators work (⏳ Pending, ⚙️ InProgress, ✅ Succeeded, ❌ Failed)
- ✅ If no actions running, shows "✅ No actions currently running. Safe to proceed with tests."
- ✅ Auto-refreshes based on configured interval

**Pass Criteria:**
- Accurately reflects current action state
- Updates automatically
- No false positives or negatives

**Troubleshooting:**
- **Section not visible:** Ensure action is selected
- **Old data showing:** Verify auto-refresh is enabled
- **Missing actions:** Check API response in Function App logs

---

### Test 3: Antivirus Scan

**Objective:** Test antivirus scan functionality

**Steps:**
1. Select one or more devices from "💻 Select Devices for Testing"
2. Select scan type (Quick or Full)
3. Select "🔍 Test Antivirus Scan" from action dropdown
4. Observe "🔍 Test: Antivirus Scan" section expands
5. Review test execution information
6. Check test result table

**Expected Results:**
- ✅ Section expands automatically
- ✅ Shows selected devices and scan type
- ✅ Test result table appears
- ✅ Result shows "Initiated" or "success" status
- ✅ Action ID is displayed and can be copied
- ✅ Details column shows relevant information
- ✅ If no devices selected, shows warning message

**Pass Criteria:**
- Action initiates successfully
- Returns valid action ID
- Status indicates successful initiation
- No 400 errors (unless duplicate action)

**Troubleshooting:**
- **400 Error:** Check if scan already running on device
- **No result:** Verify devices are selected
- **Timeout:** Check Function App processing time

---

### Test 4: Device Isolation

**Objective:** Test device isolation functionality

**Steps:**
1. Select test device(s)
2. Select isolation type (Full or Selective)
3. Select "🔒 Test Device Isolation" from action dropdown
4. Observe "🔒 Test: Device Isolation" section
5. Review test results

**Expected Results:**
- ✅ Isolation action initiates successfully
- ✅ Returns action ID for tracking
- ✅ Status shows "Initiated" or "success"
- ✅ Can copy action ID for monitoring
- ✅ Device state will update to isolated (verify in Defender portal)

**Pass Criteria:**
- Action executes without errors
- Device becomes isolated (check in Defender XDR)
- Action ID can be tracked

**Important Notes:**
- **⚠️ This is a real action!** Device will actually be isolated
- Only test on non-production devices
- Have a plan to unisolate after testing

---

### Test 5: Device Unisolation

**Objective:** Test device unisolation functionality

**Steps:**
1. Select a previously isolated device
2. Select "🔓 Test Device Unisolation" from action dropdown
3. Observe "🔓 Test: Device Unisolation" section
4. Review test results

**Expected Results:**
- ✅ Unisolation action initiates successfully
- ✅ Returns action ID
- ✅ Status indicates success
- ✅ Device isolation is removed (verify in Defender portal)

**Pass Criteria:**
- Action completes successfully
- Device returns to unisolated state
- Network connectivity restored

**Important Notes:**
- Test this after isolation test
- Verify device can communicate normally after unisolation

---

### Test 6: Investigation Package Collection

**Objective:** Test investigation package collection

**Steps:**
1. Select test device(s)
2. Select "📦 Test Investigation Package Collection"
3. Review test execution section
4. Check results

**Expected Results:**
- ✅ Collection action initiates
- ✅ Returns action ID
- ✅ Package collection begins on device
- ✅ Can track status using action ID

**Pass Criteria:**
- Action starts successfully
- Investigation package is collected
- Package becomes available in Defender portal

**Important Notes:**
- Collection may take several minutes
- Use action monitoring to track progress
- Package will appear in Defender Action Center when complete

---

### Test 7: App Execution Restriction

**Objective:** Test app execution restriction

**Steps:**
1. Select test device(s)
2. Select "🚫 Test App Execution Restriction"
3. Review results

**Expected Results:**
- ✅ Restriction action initiates
- ✅ Returns action ID
- ✅ Status shows success
- ✅ Device enters restricted execution mode

**Pass Criteria:**
- Action completes successfully
- Only authorized apps can run on device
- Can be verified in Defender portal

**Important Notes:**
- **⚠️ Real action!** This will restrict app execution
- Test only on non-production devices
- Plan to unrestrict after testing

---

### Test 8: App Execution Unrestriction

**Objective:** Test removing app execution restrictions

**Steps:**
1. Select a device with active restrictions
2. Select "✅ Test App Execution Unrestriction"
3. Review results

**Expected Results:**
- ✅ Unrestriction action initiates
- ✅ Returns action ID
- ✅ Restrictions are removed
- ✅ Normal app execution resumes

**Pass Criteria:**
- Action completes successfully
- Device returns to normal execution mode
- Can run all apps normally

---

### Test 9: Action Status Monitoring

**Objective:** Verify real-time action tracking

**Steps:**
1. Execute any action from tests above (e.g., scan)
2. Copy the returned Action ID
3. Paste Action ID into "Last Action ID (for tracking)" parameter
4. Expand "📊 Action Status Monitoring" section
5. Observe the status table

**Expected Results:**
- ✅ Table displays action details
- ✅ Shows current status (Pending → InProgress → Succeeded/Failed)
- ✅ Auto-refreshes every 30 seconds (or configured interval)
- ✅ Displays: Action ID, Type, Status, Device Name, Device ID, Requestor, Started, Last Updated
- ✅ Status has color coding (✅ Succeeded, ⚙️ InProgress, ⏳ Pending, ❌ Failed)
- ✅ Updates reflect real-time changes

**Pass Criteria:**
- Status updates automatically
- Transitions through states correctly
- Final status matches actual result

**Troubleshooting:**
- **Not updating:** Check auto-refresh is enabled
- **Wrong status:** Verify correct Action ID entered
- **No data:** Ensure action was actually initiated

---

### Test 10: Action Cancellation

**Objective:** Test ability to cancel running actions

**Steps:**
1. Execute a long-running action (e.g., Investigation Package Collection)
2. Copy the Action ID while action is Pending or InProgress
3. Paste into "Action ID to Cancel" parameter
4. Expand "❌ Action Cancellation Test" section
5. Observe cancellation result

**Expected Results:**
- ✅ Cancellation request submits successfully
- ✅ Returns cancellation status
- ✅ Action status changes to "Cancelled"
- ✅ Operation stops on device

**Pass Criteria:**
- Cancellation succeeds
- Action stops executing
- Status reflects cancellation in Defender portal

**Important Notes:**
- Can only cancel actions in Pending or InProgress state
- Completed actions cannot be cancelled
- Some actions may take time to fully cancel

---

## Advanced Testing Scenarios

### Scenario 1: Duplicate Action Prevention

**Purpose:** Verify error handling when attempting duplicate actions

**Steps:**
1. Execute an antivirus scan on a device
2. While scan is running, attempt another scan on same device
3. Observe error handling

**Expected Behavior:**
- Should show error indicating action already running
- 400 Bad Request error with descriptive message
- Running Actions Check should show conflicting action

### Scenario 2: Multi-Device Operations

**Purpose:** Test bulk operations across multiple devices

**Steps:**
1. Select 3-5 devices
2. Execute any action (e.g., scan)
3. Verify action initiates on all devices

**Expected Behavior:**
- Single API call handles multiple devices
- Returns action IDs for all devices
- All devices show in action monitoring

### Scenario 3: Auto-Refresh Validation

**Purpose:** Verify auto-refresh maintains data currency

**Steps:**
1. Set auto-refresh to 30 seconds
2. Execute an action
3. Track action through different states
4. Observe refresh timing

**Expected Behavior:**
- Data updates every 30 seconds
- No manual refresh needed
- Status transitions visible in real-time

### Scenario 4: Error Recovery

**Purpose:** Test recovery from API errors

**Steps:**
1. Temporarily break connectivity (invalid tenant ID)
2. Attempt action
3. Observe error
4. Fix connectivity
5. Retry action

**Expected Behavior:**
- Clear error messages
- Can retry after fix
- No persistent failed state

---

## Validation Checklist

Use this checklist to verify complete testing:

### Device Discovery
- [ ] Device list auto-populates
- [ ] All enrolled devices appear
- [ ] Device details display correctly
- [ ] Risk scores show with colors
- [ ] Health status displays
- [ ] Can export data

### Action Execution
- [ ] Antivirus scan works (Quick & Full)
- [ ] Device isolation works (Full & Selective)
- [ ] Device unisolation works
- [ ] Investigation package collection works
- [ ] App execution restriction works
- [ ] App execution unrestriction works

### Monitoring & Control
- [ ] Running actions check displays correctly
- [ ] Action status tracking updates in real-time
- [ ] Action cancellation works
- [ ] Auto-refresh maintains current data

### Error Handling
- [ ] Duplicate action errors display clearly
- [ ] Missing device selection shows warning
- [ ] Invalid action IDs handled gracefully
- [ ] API errors show helpful messages

### UI Behavior
- [ ] Conditional visibility works correctly
- [ ] Sections expand/collapse properly
- [ ] Parameters flow correctly
- [ ] No unexpected errors or warnings

---

## Troubleshooting Guide

### Common Issues

#### Issue: Device List Not Populating

**Symptoms:**
- Dropdown shows `<query failed>`
- No devices appear in inventory

**Possible Causes:**
1. Function App not running
2. Incorrect Tenant ID
3. Network connectivity issues
4. Function App permissions

**Solutions:**
1. Verify Function App status in Azure Portal
2. Check Tenant ID format and validity
3. Test Function App endpoint directly
4. Review Function App logs
5. Verify API permissions in Defender XDR

#### Issue: Actions Fail with 400 Error

**Symptoms:**
- "400 Bad Request" error message
- "Response status code does not indicate success"

**Possible Causes:**
1. Duplicate action already running
2. Invalid device ID
3. Missing required parameters
4. API throttling

**Solutions:**
1. Check Running Actions section for conflicts
2. Wait for current action to complete
3. Verify device IDs are correct
4. Check Function App logs for details
5. Wait and retry if throttled

#### Issue: Action Status Not Updating

**Symptoms:**
- Status stuck on "Pending" or "InProgress"
- No updates despite auto-refresh

**Possible Causes:**
1. Auto-refresh disabled
2. Invalid Action ID
3. Action actually stuck in Defender
4. Query timeout

**Solutions:**
1. Verify auto-refresh setting
2. Double-check Action ID
3. Check action status in Defender portal
4. Manually refresh
5. Review Function App logs

#### Issue: Conditional Visibility Not Working

**Symptoms:**
- Sections don't appear when expected
- Wrong sections visible

**Possible Causes:**
1. Parameter not set correctly
2. Parameter name mismatch
3. Browser cache issue

**Solutions:**
1. Verify parameter selection
2. Refresh workbook
3. Clear browser cache
4. Re-save workbook if edited

---

## Performance Considerations

### Auto-Refresh Impact
- **30 seconds:** Good for active testing, higher API usage
- **1 minute:** Balanced approach for most scenarios
- **5 minutes:** Light usage, suitable for long-running operations
- **Off:** Lowest impact, manual refresh only

### Best Practices
1. Use appropriate refresh intervals for task duration
2. Limit device selection for bulk operations
3. Close workbook when not in use to reduce API calls
4. Monitor Function App consumption

---

## Security Considerations

### Important Warnings

⚠️ **Production Environment:** Do not test on production devices without approval

⚠️ **Isolation Actions:** Device will actually be isolated - have recovery plan

⚠️ **Restriction Actions:** Apps will be restricted - test on non-critical systems

⚠️ **Investigation Packages:** May contain sensitive data - handle appropriately

### Testing Best Practices

1. **Use Test Devices:** Dedicated test devices for functionality testing
2. **Document Tests:** Record all test actions and results
3. **Clean Up:** Remove test actions and restore device states
4. **Monitor Impact:** Watch for unintended effects on devices
5. **Limit Scope:** Test one feature at a time for clarity

---

## Success Criteria

The testing workbook is considered fully functional when:

✅ **All Tests Pass:**
- Device discovery works reliably
- All 6 action types execute successfully
- Status monitoring tracks correctly
- Action cancellation functions
- Error handling works as expected

✅ **UI Functions Correctly:**
- Conditional visibility operates properly
- Parameters flow correctly
- Auto-refresh maintains data
- No unexpected errors

✅ **Performance Acceptable:**
- Queries complete in reasonable time
- Auto-refresh doesn't cause issues
- Function App handles load

✅ **Documentation Complete:**
- All tests documented
- Issues recorded and resolved
- Results validated

---

## Appendix

### A. Parameter Reference

| Parameter | Type | Purpose |
|-----------|------|---------|
| FunctionApp | Resource Selector | Select DefenderC2 Function App |
| FunctionAppName | Hidden Text | Auto-populated app name |
| TenantId | Text | Defender XDR Tenant ID |
| DeviceList | Multi-Select Dropdown | Select test devices |
| ActionToExecute | Dropdown | Choose action to test |
| ScanType | Dropdown | Quick or Full scan |
| IsolationType | Dropdown | Full or Selective isolation |
| LastActionId | Text | Action ID for tracking |
| CancelActionId | Text | Action ID to cancel |
| AutoRefresh | Dropdown | Refresh interval |

### B. Action Type Reference

| Action | API Call | Parameters | Duration |
|--------|----------|------------|----------|
| Antivirus Scan | Run Antivirus Scan | deviceIds, scanType, comment | 5-30 minutes |
| Isolate | Isolate Device | deviceIds, isolationType, comment | Immediate |
| Unisolate | Unisolate Device | deviceIds, comment | Immediate |
| Collect Package | Collect Investigation Package | deviceIds, comment | 10-30 minutes |
| Restrict Apps | Restrict App Execution | deviceIds, comment | Immediate |
| Unrestrict Apps | Unrestrict App Execution | deviceIds, comment | Immediate |

### C. Status Values

| Status | Meaning | Color | Icon |
|--------|---------|-------|------|
| Pending | Queued for execution | Blue | ⏳ |
| InProgress | Currently executing | Yellow | ⚙️ |
| Succeeded | Completed successfully | Green | ✅ |
| Failed | Execution failed | Red | ❌ |
| Cancelled | Cancelled by user | Gray | ⚫ |

### D. Error Codes

| Error | Meaning | Solution |
|-------|---------|----------|
| 400 Bad Request | Invalid request or duplicate action | Check for running actions |
| 401 Unauthorized | Authentication failed | Verify Function App permissions |
| 404 Not Found | Resource doesn't exist | Check device/action IDs |
| 429 Too Many Requests | API throttling | Wait and retry |
| 500 Internal Server Error | Function App error | Check Function App logs |

---

## Support

For issues or questions:

1. Check Function App logs in Azure Portal
2. Review Defender XDR Action Center
3. Consult DefenderC2 repository documentation
4. Open GitHub issue with details

---

**Last Updated:** 2025-10-15 14:20:00 UTC  
**Version:** 1.0  
**Author:** akefallonitis
