# DefenderC2 Workbook Deployment Guide

## 🚀 Quick Deployment

### Option 1: Azure Portal (Recommended)

1. **Navigate to Azure Portal**
   - Go to [portal.azure.com](https://portal.azure.com)
   - Navigate to: **Monitor** → **Workbooks** → **+ New**

2. **Import Workbook**
   - Click the **</>** (Advanced Editor) button in toolbar
   - Select **Gallery Template** tab
   - Paste the entire contents of `workbook/DefenderC2-Workbook.json`
   - Click **Apply**

3. **Save Workbook**
   - Click **Save** (💾 icon)
   - **Title:** DefenderC2 Command & Control Console
   - **Subscription:** Select your subscription
   - **Resource Group:** Select or create resource group
   - **Location:** Select location
   - Click **Apply**

4. **Initial Configuration**
   - **DefenderC2 Function App:** Select your Function App from dropdown
   - **Log Analytics Workspace:** Select your workspace
   - Wait for auto-discovery (2-3 seconds)
   - **Defender XDR Tenant:** Select target tenant
   - **Available Devices:** Wait for device list to load (should be fast!)
   - Select device(s) for testing

5. **Test Functionality**
   - Navigate through all 8 tabs
   - Verify DeviceList doesn't cause infinite loop ⚠️ **KEY TEST**
   - Test an ARM action (e.g., Isolate a test device)
   - Confirm action executes successfully

---

### Option 2: ARM Template Deployment

```bash
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Deploy using ARM template
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file deployment/workbook-deploy.json \
  --parameters deployment/workbook-deploy.parameters.json

# Or use PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "deployment/workbook-deploy.json" `
  -TemplateParameterFile "deployment/workbook-deploy.parameters.json"
```

---

## 🧪 Post-Deployment Testing

### Critical Tests (Must Pass)

#### ✅ Test 1: DeviceList Loads Without Infinite Loop
**MOST IMPORTANT TEST - This was the main issue fixed!**

1. Open workbook
2. Select Function App and Workspace
3. Select Tenant ID
4. Watch DeviceList parameter dropdown
5. **Expected:** Loads once, shows devices, stops loading
6. **❌ Failure:** Continuous spinning/loading, never completes
7. **✅ Success:** List populates and stops loading

**If this test fails, the reorganization didn't work!**

#### ✅ Test 2: All Tabs Load
Navigate to each tab and verify it loads:
- [ ] 🏠 Overview
- [ ] 💻 Device Management
- [ ] 🔍 Threat Intelligence
- [ ] 🚨 Incident Response
- [ ] 🎯 Custom Detections
- [ ] 🔎 Advanced Hunting
- [ ] 💬 Interactive Console
- [ ] 📚 Library Operations

#### ✅ Test 3: Device Actions Work
1. Navigate to **Device Management** tab
2. Select a test device from DeviceList
3. Click **🚨 Isolate Devices** (use a test device!)
4. Verify ARM action dialog appears
5. Check parameters are pre-populated:
   - TenantId: ✅ Filled
   - DeviceIds: ✅ Filled (from DeviceList)
   - IsolationType: Select Full or Selective
6. Click **Run**
7. Verify action completes successfully

**Expected:** Parameters auto-populate, no manual input needed  
**❌ Failure:** Empty parameters, requires manual input  
**✅ Success:** All parameters filled, just click Run

### Optional Tests

#### Test 4: Threat Intelligence
1. Navigate to **Threat Intelligence** tab
2. Add a test file indicator
3. Verify indicator is added successfully

#### Test 5: Advanced Hunting
1. Navigate to **Advanced Hunting** tab
2. Enter a simple KQL query: `DeviceInfo | take 10`
3. Execute hunt
4. Verify results are displayed

#### Test 6: Interactive Console
1. Navigate to **Interactive Console** tab
2. Select a command type
3. Execute a test command
4. Verify command executes

---

## 🔍 Troubleshooting

### Issue: DeviceList Infinite Loop (Not Fixed)

**Symptoms:**
- DeviceList dropdown continuously spins
- Never completes loading
- Browser becomes slow/unresponsive
- Network tab shows repeated API calls to Get Devices

**Causes:**
1. DeviceList parameter not marked as `isGlobal: true`
2. Duplicate device parameters still exist
3. Incorrect criteriaData configuration

**Solution:**
```bash
# Run validation script to check
python3 scripts/validate_workbook_reorganization.py

# If validation fails, the workbook wasn't properly updated
# Check the deployed workbook against the source file
```

**Verification:**
1. Open browser DevTools (F12)
2. Go to Network tab
3. Filter: `DefenderC2Dispatcher`
4. Watch for repeated calls to `action=Get Devices`
5. Should see only 1-2 calls, not continuous calls

---

### Issue: DeviceList Empty

**Symptoms:**
- DeviceList parameter shows "No data"
- Dropdown is empty

**Causes:**
1. TenantId not selected
2. Function App not configured (APPID/SECRETID missing)
3. No devices in Defender for Endpoint
4. Network/authentication issues

**Solution:**
1. Verify TenantId is selected
2. Check Function App environment variables:
   ```bash
   az functionapp config appsettings list \
     --name <function-app-name> \
     --resource-group <resource-group> \
     --query "[?name=='APPID' || name=='SECRETID']"
   ```
3. Test Function App directly:
   ```bash
   curl -X POST "https://<function-app>.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=<tenant-id>"
   ```
4. Check Defender for Endpoint portal for devices

---

### Issue: ARM Actions Fail

**Symptoms:**
- Click action button, nothing happens
- Error message appears
- Action doesn't execute

**Causes:**
1. Parameters not auto-populating
2. Function App authentication issues
3. Missing permissions

**Solution:**
1. Check ARM action dialog - are parameters filled?
2. Verify Function App is running:
   ```bash
   az functionapp show --name <function-app-name> --resource-group <resource-group> --query "state"
   ```
3. Check Function App logs:
   ```bash
   az functionapp log tail --name <function-app-name> --resource-group <resource-group>
   ```
4. Verify App Registration has correct permissions (SecurityEvents.ReadWrite.All, etc.)

---

### Issue: Tabs Not Showing

**Symptoms:**
- Some tabs don't appear
- Tab navigation incomplete

**Causes:**
1. Incorrect conditional visibility
2. selectedTab parameter issue
3. Workbook not properly saved

**Solution:**
1. Check tab navigation works (click different tabs)
2. Verify selectedTab parameter exists
3. Re-import workbook from source

---

## 📊 Monitoring & Validation

### Browser DevTools Checks

**Network Tab:**
```
✅ Good: 1-2 calls to Get Devices when loading
❌ Bad: Continuous calls to Get Devices (infinite loop)
```

**Console Tab:**
```
✅ Good: No errors, clean console
❌ Bad: Errors about parameters, infinite loops
```

### Azure Portal Checks

**Function App:**
- Status: ✅ Running
- Environment Variables: ✅ APPID, SECRETID set
- Authentication: ✅ Configured

**Workbook:**
- Saved: ✅ Yes
- Location: ✅ Correct resource group
- Permissions: ✅ Can read Function App

---

## 🎯 Success Indicators

### ✅ Everything Working
- DeviceList loads **once** and stops (no infinite loop)
- All 8 tabs load successfully
- ARM actions execute with auto-populated parameters
- No browser console errors
- Network tab shows minimal API calls
- Actions complete successfully in Defender portal

### ⚠️ Partial Success
- DeviceList loads (no infinite loop) ✅
- Some tabs don't work ⚠️
- ARM actions need manual parameter input ⚠️
- Review warnings in validation script

### ❌ Failure
- DeviceList infinite loop persists ❌
- Workbook doesn't load ❌
- All ARM actions fail ❌
- Re-deploy from source, check configuration

---

## 📝 Rollback Procedure

If the reorganized workbook has issues:

### Option 1: Restore from Backup
```bash
# Copy backup to main workbook
cp workbook/DefenderC2-Workbook-backup-20251013-205950.json workbook/DefenderC2-Workbook.json

# Re-import to Azure Portal
```

### Option 2: Use Previous Workbook
The previous workbook is available at:
- `workbook/DefenderC2-Workbook-backup-20251013-211249.json` (before reorganization)

**Note:** Previous workbook still has the infinite loop issue, so only use temporarily.

---

## 🆘 Support

### Getting Help

1. **Check Documentation:**
   - `WORKBOOK_REORGANIZATION_COMPLETE.md` - Full details
   - `AZURE_WORKBOOK_BEST_PRACTICES.md` - Best practices
   - `ARM_ACTION_FINAL_SOLUTION.md` - ARM action patterns

2. **Run Validation:**
   ```bash
   python3 scripts/validate_workbook_reorganization.py
   ```

3. **Check Logs:**
   - Browser DevTools Console
   - Browser DevTools Network tab
   - Azure Function App logs

4. **Review Changes:**
   ```bash
   git log --oneline workbook/DefenderC2-Workbook.json
   git show <commit-hash>
   ```

### Common Questions

**Q: Why does DeviceList need to be global?**  
A: Local parameters re-query every time they're referenced. Global parameters query once and cache the result, preventing infinite loops.

**Q: Can I add custom tabs?**  
A: Yes! Follow the pattern of existing tabs, use conditional visibility with selectedTab parameter.

**Q: Can I use multiple tenants?**  
A: Yes! Select different TenantId from the dropdown. DeviceList will refresh automatically.

**Q: How do I add more devices?**  
A: Devices come from Defender for Endpoint. Add them there, they'll appear in DeviceList automatically.

---

## 📅 Maintenance

### Regular Checks
- [ ] Verify DeviceList still loads correctly (weekly)
- [ ] Test ARM actions work (weekly)
- [ ] Check for new devices appearing (as added)
- [ ] Validate tabs load (monthly)

### Updates
When updating the workbook:
1. Always backup current version first
2. Test in non-production environment
3. Run validation script
4. Deploy to production
5. Verify no regressions

---

*Last Updated: 2025-10-13*  
*Version: 2.0 (Reorganized)*  
*Status: Production Ready*
