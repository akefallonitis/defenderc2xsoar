# Deployment Verification Checklist

## Purpose
This checklist ensures the DefenderC2 workbook is properly deployed and all parameter binding works correctly.

---

## Pre-Deployment: Verify Configuration

### ✅ Step 1: Validate Workbook JSON

```bash
cd /path/to/defenderc2xsoar

# Check JSON syntax
python3 -m json.tool workbook/DefenderC2-Workbook.json > /dev/null
echo $?  # Should output: 0
```

**Expected:** No errors, exit code 0

---

### ✅ Step 2: Run Configuration Verification

```bash
python3 scripts/verify_workbook_config.py
```

**Expected Output:**
```
================================================================================
DefenderC2 Workbook Configuration Verification
================================================================================

DefenderC2-Workbook.json:
✅ ARM Actions: 15/15 with api-version in params
✅ ARM Actions: 15/15 with relative paths
✅ ARM Actions: 15/15 without api-version in URL
✅ Device Parameters: 5/5 with CustomEndpoint
✅ CustomEndpoint Queries: 21/21 with parameter substitution

✅✅✅ ALL CHECKS PASSED ✅✅✅

FileOperations.workbook:
✅ ARM Actions: 4/4 with api-version in params
✅ ARM Actions: 4/4 with relative paths
✅ ARM Actions: 4/4 without api-version in URL
✅ CustomEndpoint Queries: 1/1 with parameter substitution

✅✅✅ ALL CHECKS PASSED ✅✅✅

🎉 SUCCESS: All workbooks are correctly configured!
```

**If verification fails:** Do not proceed. Fix configuration issues first.

---

## Deployment: Function App Setup

### ✅ Step 3: Verify Function App Exists

```bash
# Set your values
FUNCTION_APP_NAME="your-defenderc2-app"
RESOURCE_GROUP="your-resource-group"
SUBSCRIPTION_ID="your-subscription-id"

# Check Function App exists
az functionapp show \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --subscription ${SUBSCRIPTION_ID}
```

**Expected:** JSON output with Function App details

---

### ✅ Step 4: Configure CORS

```bash
# Add required CORS origins
az functionapp cors add \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --allowed-origins https://portal.azure.com

az functionapp cors add \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --allowed-origins https://ms.portal.azure.com
```

**Verify CORS settings:**
```bash
az functionapp cors show \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

**Expected:**
```json
{
  "allowedOrigins": [
    "https://portal.azure.com",
    "https://ms.portal.azure.com"
  ]
}
```

---

### ✅ Step 5: Verify Authentication Settings

```bash
# Check authentication
az functionapp auth show \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

**Expected for anonymous access:**
```json
{
  "enabled": false
}
```

**OR for authenticated with anonymous allowed:**
```json
{
  "enabled": true,
  "unauthenticatedClientAction": "AllowAnonymous"
}
```

---

### ✅ Step 6: Test Function App Endpoint

```bash
# Get Function App URL
FUNCTION_APP_URL="https://${FUNCTION_APP_NAME}.azurewebsites.net"

# Test Get Devices endpoint
curl -s "${FUNCTION_APP_URL}/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}" | jq .
```

**Expected Response:**
```json
{
  "action": "Get Devices",
  "status": "Success",
  "timestamp": "2025-10-13T12:00:00Z",
  "devices": [
    {
      "id": "device-id-1",
      "computerDnsName": "DEVICE-001",
      ...
    }
  ]
}
```

**If this fails:** Fix Function App configuration before deploying workbook.

---

## Post-Deployment: Workbook Testing

### ✅ Step 7: Import Workbook to Azure Portal

1. Navigate to: **Azure Portal → Monitor → Workbooks**
2. Click: **+ New**
3. Click: **Advanced Editor** (</> icon)
4. Paste contents of `DefenderC2-Workbook.json`
5. Click: **Apply**
6. Click: **Done Editing**
7. Click: **Save As**
   - Title: `DefenderC2 Command & Control Console`
   - Subscription: Select subscription
   - Resource Group: Select resource group
   - Location: Select location

**Expected:** Workbook saves successfully without errors

---

### ✅ Step 8: Test Parameter Cascade

**Open the workbook and follow these steps:**

#### 8.1: Select Function App
- [ ] FunctionApp dropdown shows Function Apps
- [ ] Select your DefenderC2 Function App

**Expected after selection:**
- [ ] **Subscription** field auto-populates (shows subscription ID)
- [ ] **ResourceGroup** field auto-populates (shows resource group name)
- [ ] **FunctionAppName** field auto-populates (shows function app name)
- [ ] **TenantId** field auto-populates (shows tenant ID GUID)

**Screenshot Location:** (Optional) Take screenshot showing all auto-populated fields

---

#### 8.2: Verify Device List
- [ ] "Available Devices (Auto-populated)" dropdown appears
- [ ] Wait for refresh (spinner icon)
- [ ] Dropdown populates with devices

**Expected:**
```
Available Devices (Auto-populated): [Dropdown with device names]
  ✓ DEVICE-001
  ✓ DEVICE-002
  ...
```

**If empty:** Check Function App logs and verify devices exist in Microsoft Defender

---

#### 8.3: Test Device Selection Parameters
Navigate to "Automator" tab (or relevant tab):

- [ ] **IsolateDeviceIds** dropdown populates
- [ ] **UnisolateDeviceIds** dropdown populates
- [ ] **RestrictDeviceIds** dropdown populates
- [ ] **ScanDeviceIds** dropdown populates

**Expected:** All dropdowns show the same devices as "Available Devices"

---

### ✅ Step 9: Test ARM Action Execution

#### 9.1: Test Get Devices (Query)
- [ ] Navigate to "Get Devices" section
- [ ] Click "Run Query" or similar button
- [ ] Verify grid/table populates with devices

**Expected:** Device list appears in grid format with:
- Device ID
- Device Name
- Status
- Last Seen
- etc.

---

#### 9.2: Test Action Button (Non-destructive)
**Use "Get Device Info" or similar read-only action:**

1. Select a device from dropdown
2. Click action button (e.g., "Get Device Info")
3. Observe:
   - [ ] Loading spinner appears
   - [ ] Action completes (spinner disappears)
   - [ ] Success message or result appears

**Browser Console Check (F12):**
- [ ] No CORS errors
- [ ] No 401/403 authentication errors
- [ ] POST request to `/subscriptions/.../invocations` succeeded
- [ ] Response status: 200

---

#### 9.3: Test Parameter Substitution in Request

**In browser console (F12 → Network tab):**

1. Find the POST request to Function App invocations
2. Click on the request
3. Check "Payload" or "Request" tab

**Verify request body contains:**
```json
{
  "action": "Get Device Info",
  "tenantId": "<actual-tenant-id-guid>",
  "deviceIds": "<actual-device-id>"
}
```

**NOT:**
```json
{
  "action": "Get Device Info",
  "tenantId": "{TenantId}",        ❌ WRONG - parameter not substituted
  "deviceIds": "{IsolateDeviceIds}" ❌ WRONG - parameter not substituted
}
```

---

### ✅ Step 10: Test Auto-Refresh Functionality

#### 10.1: Change FunctionApp Selection
1. Select a different Function App from dropdown
2. Observe auto-populated fields update
3. Wait for device dropdowns to refresh

**Expected:**
- [ ] Subscription changes
- [ ] ResourceGroup changes
- [ ] FunctionAppName changes
- [ ] TenantId changes
- [ ] Device dropdowns refresh and show different devices (if applicable)

---

#### 10.2: Verify criteriaData Triggering
**This tests that parameter dependencies work correctly:**

1. Note current device list
2. Change FunctionApp parameter
3. Device lists should refresh automatically (not manually clicking refresh)

**Expected:** Parameters with `criteriaData` automatically re-query when dependencies change

---

## Troubleshooting Failed Tests

### If Step 2 Fails (Configuration Verification)
- Download latest workbook from GitHub
- Check for merge conflicts if you modified the workbook
- Review: [ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md)

### If Step 6 Fails (Function App Test)
- Check Function App is running: `az functionapp show --name ... --query state`
- Verify DefenderC2Dispatcher function exists
- Check Function App logs: `az functionapp log tail --name ...`
- Review: [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)

### If Step 8.1 Fails (FunctionApp Dropdown Empty)
- Verify Function Apps exist: `az functionapp list`
- Check Azure permissions: Need Reader role
- Ensure Function App kind includes "functionapp"

### If Step 8.2 Fails (Device List Empty)
- Test API endpoint directly (Step 6)
- Check Microsoft Defender has devices
- Verify TenantId is correct
- Check Function App authentication to Microsoft Graph API

### If Step 9.3 Fails (Parameters Not Substituted)
- **This indicates a workbook configuration issue**
- Re-run Step 2 (Configuration Verification)
- Ensure latest workbook version deployed
- Check browser console for JavaScript errors

---

## Success Criteria

### Minimum Requirements (Must Pass)
- [x] Configuration verification passes (Step 2)
- [x] Function App responds to API calls (Step 6)
- [x] Workbook imports without errors (Step 7)
- [x] FunctionApp dropdown populates (Step 8.1)
- [x] Auto-populated parameters fill (Step 8.1)
- [x] At least one device dropdown populates (Step 8.2)

### Full Functionality (Recommended)
- [x] All minimum requirements
- [x] All device dropdowns populate (Step 8.3)
- [x] Query execution works (Step 9.1)
- [x] ARM action execution works (Step 9.2)
- [x] Parameter substitution correct (Step 9.3)
- [x] Auto-refresh triggers on dependency change (Step 10)

---

## Post-Deployment Actions

### ✅ Documentation
- [ ] Update deployment notes with any environment-specific configurations
- [ ] Document any issues encountered and resolutions
- [ ] Create runbook for common operations

### ✅ Monitoring
- [ ] Set up Application Insights alerts for Function App errors
- [ ] Monitor workbook usage analytics
- [ ] Track API call volumes and response times

### ✅ Maintenance
- [ ] Schedule regular validation of workbook configuration
- [ ] Plan for Function App updates
- [ ] Review and update CORS settings if needed

---

## Rollback Procedure

If deployment fails and cannot be fixed:

1. **Export current workbook** (if any changes were made)
2. **Delete deployed workbook** from Azure Portal
3. **Restore previous version** or deploy known-good version
4. **Document issues** for future resolution
5. **Review logs** to understand root cause

---

## Sign-Off

### Deployment Information
- **Deployed By:** ___________________
- **Deployment Date:** ___________________
- **Environment:** ☐ Dev ☐ Test ☐ Staging ☐ Production
- **Workbook Version:** ___________________
- **Function App Name:** ___________________

### Test Results
- **Configuration Validation:** ☐ Pass ☐ Fail
- **Function App Test:** ☐ Pass ☐ Fail
- **Parameter Cascade:** ☐ Pass ☐ Fail
- **Device Population:** ☐ Pass ☐ Fail
- **ARM Actions:** ☐ Pass ☐ Fail

### Approval
- **Tested By:** ___________________
- **Approved By:** ___________________
- **Date:** ___________________

---

**Checklist Version:** 1.0  
**Last Updated:** October 13, 2025  
**Maintained By:** DefenderC2 Project Team
