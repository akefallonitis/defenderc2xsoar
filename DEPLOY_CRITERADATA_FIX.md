# Quick Deploy Guide: CriteriaData Fix for MINIMAL-FIXED Workbook

## 🎯 What This Fixes

- ✅ ARM actions no longer show `<unset>` for parameter values
- ✅ Device List loads correctly without getting stuck
- ✅ Parameters populate properly when dependencies are met
- ✅ All actions execute successfully

## 🚀 Deploy in 5 Minutes

### Step 1: Backup Current Workbook (30 seconds)

1. Open Azure Portal → **Workbooks**
2. Find "DefenderC2-Workbook-MINIMAL-FIXED"
3. Click **Edit**
4. Click **Advanced Editor** (</> icon)
5. **Copy entire JSON** to a text file as backup
6. Click **Cancel** (don't save yet)

### Step 2: Get Fixed Workbook (1 minute)

Download from GitHub:
```bash
# Option A: Direct download
https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/copilot/fix-device-list-autorefresh/workbook/DefenderC2-Workbook-MINIMAL-FIXED.json

# Option B: Clone repo
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar
git checkout copilot/fix-device-list-autorefresh
# File is at: workbook/DefenderC2-Workbook-MINIMAL-FIXED.json
```

### Step 3: Deploy Fixed Version (2 minutes)

1. Open Azure Portal → **Workbooks**
2. Find "DefenderC2-Workbook-MINIMAL-FIXED"
3. Click **Edit**
4. Click **Advanced Editor** (</> icon)
5. **Select All** (Ctrl+A) → **Delete**
6. **Paste** the fixed JSON from downloaded file
7. Click **Apply**
8. Click **Done Editing**
9. Click **Save**
10. Wait for save confirmation ✅

### Step 4: Test (1.5 minutes)

#### Quick Test - Parameter Population
1. Click **Parameters** (if not already visible)
2. **Select Function App** from resource picker
3. Wait 2-3 seconds
4. Verify these populate automatically:
   - ✅ Subscription
   - ✅ ResourceGroup
   - ✅ FunctionAppName

#### Quick Test - Device List
1. **Select Tenant ID** from dropdown
2. Wait 2-3 seconds
3. Verify "💻 Device List - Live Data" shows devices
4. Should display within 3 seconds (not stuck loading)

#### Quick Test - ARM Action
1. **Select one or more devices** from DeviceList
2. Click **"🔒 Isolate Devices"** button
3. ARM dialog opens
4. **Verify NO `<unset>` values** - should show:
   - ✅ tenantId: (your tenant GUID)
   - ✅ deviceIds: (selected device IDs)
   - ✅ isolationType: Full
   - ✅ comment: Isolated via Workbook
5. Click **Cancel** (or Run if you want to execute)

✅ **If all 3 tests pass, deployment is successful!**

## 🔍 What Changed?

### Technical Details

Each ARM action now has **6 parameters** in `criteriaData` instead of 3:

```json
// BEFORE (broken)
"criteriaData": [
  {"{FunctionApp}"},
  {"{TenantId}"},
  {"{DeviceList}"}
]

// AFTER (fixed)
"criteriaData": [
  {"{FunctionApp}"},
  {"{TenantId}"},
  {"{DeviceList}"},
  {"{Subscription}"},      // ← ADDED
  {"{ResourceGroup}"},     // ← ADDED
  {"{FunctionAppName}"}    // ← ADDED
]
```

**Why?** Azure Workbook needs to wait for ALL derived parameters to be resolved before executing ARM actions. Without this, it tries to construct the ARM path before parameters are ready, resulting in `<unset>` errors.

## 📊 Actions Fixed

| Action | Status |
|--------|--------|
| 🔒 Isolate Devices | ✅ Fixed |
| 🔓 Unisolate Devices | ✅ Fixed |
| 🔍 Run Antivirus Scan | ✅ Fixed |

## 🐛 Troubleshooting

### Issue: Still seeing `<unset>` values

**Solution:**
```
1. Clear browser cache (Ctrl+Shift+Delete)
2. Close workbook completely
3. Reopen workbook
4. Wait for parameters to populate before clicking actions
```

### Issue: Device List still stuck loading

**Possible causes:**
- Function App not accessible
- Tenant ID not selected
- Function App authentication issues

**Solution:**
```
1. Check Function App is running
2. Verify Tenant ID is selected
3. Open browser console (F12) → Check for errors
4. Verify Function App CORS settings allow Azure Portal
```

### Issue: Parameters not auto-populating

**Solution:**
```
1. Verify Function App is selected
2. Wait 3-5 seconds for ARG queries to complete
3. Check browser console for errors
4. Refresh workbook
```

## 📞 Support

### If Issues Persist

1. **Check browser console** (F12 → Console tab)
   - Look for errors when loading parameters
   - Look for errors when clicking actions
   - Report any red errors

2. **Verify Function App**
   - Function App must be running
   - CORS must be configured
   - Authentication must be working

3. **Provide Details**
   ```
   - Browser: Chrome/Edge/Firefox/Safari
   - Error message from console:
   - Which step failed:
   - Screenshot of issue:
   ```

## 📚 More Information

- **MINIMAL_FIXED_CRITERADATA_FIX.md**: Full technical documentation
- **BEFORE_AFTER_CRITERADATA_FIX.md**: Visual comparison
- **PR_86_SUMMARY.md**: Original issue details

## ✅ Success Checklist

Deployment is successful when:
- [ ] Parameters auto-populate after selecting Function App
- [ ] Device List displays within 3 seconds
- [ ] ARM actions show actual values (no `<unset>`)
- [ ] Actions can be executed successfully

---

**Status**: Ready for Production  
**Date**: October 14, 2025  
**Branch**: `copilot/fix-device-list-autorefresh`  
**Estimated Deploy Time**: 5 minutes  
**Risk Level**: Low (only fixes parameter resolution)
