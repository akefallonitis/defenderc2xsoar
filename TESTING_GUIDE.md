# Testing Guide for DefenderC2 Workbook Fixes

## Overview
This guide provides step-by-step instructions for testing the fixes applied to resolve DeviceId autopopulation and ARM endpoint configuration issues.

## What Was Fixed

### 1. ARMEndpoint Queries (15 total)
- **Issue:** Missing `api-version` URL parameter causing "Please provide the api-version URL parameter" errors
- **Fix:** Added `urlParams` with `api-version=2022-03-01` to all ARMEndpoint queries
- **Files:** DefenderC2-Workbook.json (14), FileOperations.workbook (1)

### 2. ARM Actions (17 total)
- **Issue:** Missing `api-version` parameter potentially causing API errors
- **Fix:** Added `params` with `api-version=2022-03-01` to all ARM Actions
- **Files:** DefenderC2-Workbook.json (13), FileOperations.workbook (4)

### 3. Device Parameters (5 total)
- **Status:** Already correctly configured - no changes needed
- **Configuration:** All use CustomEndpoint/1.0 with proper JSONPath parsing
- **Parameters:** DeviceList, IsolateDeviceIds, UnisolateDeviceIds, RestrictDeviceIds, ScanDeviceIds

## Prerequisites

Before testing:
1. Deploy the updated workbooks to your Azure environment
2. Ensure your DefenderC2 Function App is running and accessible
3. Have valid credentials for accessing Azure Workbooks
4. Log Analytics Workspace should be configured

## Testing Procedures

### Pre-Deployment Verification

Run the verification script to ensure all configurations are correct:

```bash
cd /path/to/repository
python3 scripts/verify_workbook_config.py
```

Expected output:
```
🎉 SUCCESS: All workbooks are correctly configured!
```

### Test 1: Device Parameter Auto-Population

**Objective:** Verify DeviceList dropdown populates correctly

**Steps:**
1. Open DefenderC2 Workbook in Azure Portal
2. Navigate to the parameters section at the top
3. Locate the "Available Devices" dropdown
4. Click the dropdown

**Expected Results:**
- ✅ Dropdown shows list of devices
- ✅ Device names are displayed (not just IDs)
- ✅ No `<query failed>` error
- ✅ Can select multiple devices

**Troubleshooting:**
- If empty: Check Function App is running and TenantId is correct
- If error: Verify Function App URL is correct
- If shows IDs only: Check JSONPath columns are configured (should show computerDnsName)

### Test 2: Device Manager Tab - Device List Query

**Objective:** Verify device list table displays without api-version errors

**Steps:**
1. Navigate to "Device Manager" tab (or "Defender C2" tab)
2. Look for the "Device List" table/grid
3. Wait for data to load (should be automatic)

**Expected Results:**
- ✅ Table displays device information
- ✅ No error message about api-version
- ✅ Shows columns: Device Name, Risk Score, Health Status, Last IP, Last Seen, Device ID

**Troubleshooting:**
- If api-version error: Verify ARMEndpoint query has urlParams (should be fixed)
- If no data: Check Function App logs for errors
- If timeout: Increase query timeout in workbook settings

### Test 3: Device Isolation Action

**Objective:** Verify ARM Action executes without api-version errors

**Steps:**
1. Navigate to "Device Manager" or "Device Actions" section
2. Select one or more devices from the "Device IDs" dropdown
3. Choose isolation type (if applicable)
4. Click "🚨 Isolate Devices" button
5. Confirm the action when prompted

**Expected Results:**
- ✅ Action executes without errors
- ✅ Success/status message is displayed
- ✅ No "api-version URL parameter" error
- ✅ Isolation result table updates (if present)

**Troubleshooting:**
- If api-version error: Verify ARM Action has params array with api-version
- If action fails: Check Function App logs and device IDs are valid
- If no response: Verify Function App endpoint is accessible

### Test 4: Threat Intel Manager Tab

**Objective:** Verify threat indicator queries work

**Steps:**
1. Navigate to "Threat Intel Manager" tab
2. Wait for "Active Threat Indicators" table to load
3. Verify table displays indicator data

**Expected Results:**
- ✅ Table displays indicators
- ✅ Shows columns: Indicator, Type, Action, Severity, Title, Created By, Created
- ✅ No api-version errors

### Test 5: Action Manager Tab - Auto-Refresh

**Objective:** Verify auto-refresh queries work correctly

**Steps:**
1. Navigate to "Action Manager" tab
2. Wait for "Machine Actions" table to load
3. Observe if table refreshes automatically (every 30 seconds)
4. Look for refresh indicator or timestamp updates

**Expected Results:**
- ✅ Table loads initially without errors
- ✅ Auto-refresh works (every 30s)
- ✅ No api-version errors on refresh
- ✅ Data updates are visible

**Troubleshooting:**
- If auto-refresh stops: Check ARMEndpoint query has valid refreshInterval
- If errors on refresh: Verify urlParams with api-version is present

### Test 6: Incident Manager Tab

**Objective:** Verify incident queries and update actions work

**Steps:**
1. Navigate to "Incident Manager" tab
2. Verify "Security Incidents" table loads
3. Test filtering (if available)
4. Try "Update Incident" or "Add Comment" action (if applicable)

**Expected Results:**
- ✅ Incidents table displays without errors
- ✅ Filters work correctly
- ✅ Update actions execute without api-version errors

**Troubleshooting:**
- If error shown in screenshot matches: Should be fixed now
- If still errors: Check Function App IncidentManager endpoint

### Test 7: Custom Detection Manager

**Objective:** Verify detection rule queries work

**Steps:**
1. Navigate to "Custom Detection Manager" tab
2. Wait for detection rules table to load
3. Try CRUD operations if available (Create, Update, Delete)

**Expected Results:**
- ✅ Detection rules table loads
- ✅ Shows columns: ID, Name, Severity, Enabled, Created By, Modified
- ✅ Actions execute without errors

### Test 8: Interactive Console

**Objective:** Verify command execution and history queries work

**Steps:**
1. Navigate to "Interactive Console" tab
2. Try executing a simple command (if available)
3. Check execution history table

**Expected Results:**
- ✅ Command execution works
- ✅ Status and results display
- ✅ History table loads without errors

### Test 9: FileOperations Workbook

**Objective:** Verify FileOperations workbook functionality

**Steps:**
1. Open FileOperations workbook in Azure Portal
2. Check file list loads
3. Try file operations: Deploy, Download, Delete

**Expected Results:**
- ✅ File list query works
- ✅ All 4 ARM Actions work without api-version errors:
  - 📤 Deploy to Device
  - 📥 Download from Library
  - 🗑️ Delete from Library
  - 📥 Download File from Device

## Common Issues and Solutions

### Issue: "Please provide the api-version URL parameter"

**Cause:** ARMEndpoint query or ARM Action missing api-version

**Solution:** This should be fixed by the changes. If you still see this error:
1. Verify you deployed the updated workbook
2. Check the specific query/action has urlParams or params with api-version
3. Run the verification script to confirm all fixes are present

### Issue: Device dropdown shows `<query failed>`

**Possible Causes:**
1. Function App is not running
2. Function App URL is incorrect
3. TenantId is incorrect
4. Network/firewall blocking access

**Solutions:**
1. Verify Function App is running in Azure Portal
2. Check FunctionAppName parameter matches your Function App
3. Verify TenantId (should auto-populate from Workspace)
4. Check Function App logs for errors

### Issue: Tables not loading or showing errors

**Possible Causes:**
1. API version mismatch (should be fixed)
2. Function endpoint errors
3. Authentication issues
4. Network/timeout issues

**Solutions:**
1. Check Function App logs for specific errors
2. Verify Function App endpoints are working (test with Postman/curl)
3. Check if Function App requires authentication (add FunctionKey if needed)
4. Increase query timeout if needed

## Validation Checklist

After testing, verify:

- [ ] All device dropdowns populate correctly
- [ ] No api-version errors in any tab
- [ ] All tables/queries load successfully
- [ ] ARM Actions execute without errors
- [ ] Auto-refresh works where configured
- [ ] FileOperations workbook fully functional
- [ ] No regression in existing functionality

## Automated Validation

Run the verification script before and after deployment:

```bash
# Before deployment - verify workbook files
python3 scripts/verify_workbook_config.py

# Expected output:
# 🎉 SUCCESS: All workbooks are correctly configured!
```

## Performance Considerations

1. **Auto-refresh intervals:** Some queries refresh every 30 seconds
2. **Large datasets:** May take longer to load in tables
3. **Function App cold starts:** First query might be slower

## Rollback Procedure

If issues occur after deployment:

1. Identify the problematic workbook
2. Restore previous version from git history:
   ```bash
   git checkout HEAD~1 workbook/DefenderC2-Workbook.json
   ```
3. Redeploy the previous version
4. Report the issue with details

## Support

For issues or questions:
1. Check Function App logs in Azure Portal
2. Review WORKBOOK_FIXES_SUMMARY.md for details
3. Run verification script to check configuration
4. Check repository issues for similar problems

---

**Last Updated:** 2025-10-11  
**Version:** 1.0  
**Related Documents:** WORKBOOK_FIXES_SUMMARY.md
