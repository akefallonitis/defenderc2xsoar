# Quick Test Guide - DeviceManager Workbooks

## 🚀 Deploy & Test Hybrid Workbook (5 Minutes)

### Prerequisites
- Azure Subscription with Workbooks enabled
- DefenderC2 Function App deployed
- Defender XDR tenant configured

### Step 1: Import Workbook (1 min)

**Option A: Azure Portal UI**
1. Navigate to Azure Portal → **Workbooks**
2. Click **+ New**
3. Click **Advanced Editor** (code icon `</>`)
4. Copy contents of `workbook/DeviceManager-Hybrid.json`
5. Paste into editor
6. Click **Apply**
7. Click **Save** → Name: "DefenderC2-DeviceManager-Hybrid"

**Option B: Azure CLI**
```bash
az account set --subscription "<your-subscription-id>"

az resource create \
  --resource-group "<your-rg>" \
  --resource-type "microsoft.insights/workbooks" \
  --name "defenderc2-devicemanager-hybrid-$(uuidgen)" \
  --properties @workbook/DeviceManager-Hybrid.json \
  --location "westus2"
```

### Step 2: Configure Parameters (1 min)

1. Open the workbook
2. **Select Subscription** (🔑 Subscription dropdown)
3. **Select Resource Group** (📦 Resource Group dropdown)
4. **Select Function App** (🔧 DefenderC2 Function App dropdown)
5. **Select Tenant** (🏢 Defender XDR Tenant dropdown)
6. **Wait for DeviceList to auto-populate** (💻 Select Devices)
   - Should show device names from your Defender tenant
   - If empty, check Function App logs

### Step 3: Verify ARM Action Buttons (30 seconds)

Expand each section and verify buttons are visible:

```
✅ 🔬 Run Antivirus Scan
   └─ Button: "🔬 Execute Antivirus Scan"

✅ 🔒 Isolate Device
   └─ Button: "🔒 Execute Isolate Device"

✅ 🔓 Unisolate Device
   └─ Button: "🔓 Execute Unisolate Device"

✅ 📦 Collect Investigation Package
   └─ Button: "📦 Execute Collect Investigation Package"

✅ 🚫 Restrict App Execution
   └─ Button: "🚫 Execute Restrict App Execution"

✅ ✅ Unrestrict App Execution
   └─ Button: "✅ Execute Unrestrict App Execution"
```

**Expected**: All 6 buttons visible immediately (NO loading spinners)

**If you see loading spinners instead of buttons:**
- ❌ Wrong file deployed (old CustomEndpoint-only version)
- ❌ Import failed partially
- 🔄 Re-import from `workbook/DeviceManager-Hybrid.json`

### Step 4: Test Execution (2 minutes)

1. **Select test device(s)** from DeviceList dropdown
2. **Click "🔬 Execute Antivirus Scan"**
3. **Verify confirmation dialog appears:**
   ```
   ┌────────────────────────────────────┐
   │  ⚠️  Run Antivirus Scan           │
   │                                    │
   │  Execute Run Antivirus Scan on:   │
   │  - DESKTOP-TEST                   │
   │                                    │
   │  ┌────────┐  ┌────────┐           │
   │  │ Cancel │  │   OK   │           │
   │  └────────┘  └────────┘           │
   └────────────────────────────────────┘
   ```
4. **Click OK**
5. **Scroll to "📊 Action Status Tracking"**
6. **Verify new action appears** with status "⏳ Pending" or "⚙️ InProgress"
7. **Wait 30 seconds** (auto-refresh)
8. **Verify status updates** to "✅ Succeeded"

### Step 5: Test Pending Actions Warning (1 min)

1. **Execute scan on device** (from Step 4)
2. **While action is pending**, scroll to "⚠️ Pending Actions Check"
3. **Verify table shows pending action:**
   ```
   Device ID | Device Name    | Action Type | Action ID     | Status
   ───────────────────────────────────────────────────────────────────
   abc123... | DESKTOP-TEST  | Scan        | def456...     | ⏳ Pending
   ```
4. **Attempt to execute SAME action again** on same device
5. **Expected**: 400 error from API (duplicate action prevention working)

---

## 🐛 Troubleshooting

### Issue: DeviceList Not Populating

**Symptoms:**
- DeviceList dropdown is empty
- Shows no devices from Defender tenant

**Diagnosis:**
```bash
# Test Function App directly
curl -X POST \
  "https://<functionapp>.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=<tenant-id>"

# Expected response:
{
  "devices": [
    {"id": "abc123...", "computerDnsName": "DESKTOP-001"},
    {"id": "def456...", "computerDnsName": "SERVER-002"}
  ]
}
```

**Fixes:**
1. **Function App authentication issue:**
   ```bash
   az functionapp identity show --name <functionapp> --resource-group <rg>
   # If no identity, assign one:
   az functionapp identity assign --name <functionapp> --resource-group <rg>
   ```

2. **Defender XDR permissions:**
   - Grant Function App managed identity "Machine.Read" permission in Defender XDR
   - Or use Function Key in URL (less secure)

3. **CORS settings:**
   ```bash
   az functionapp cors add \
     --name <functionapp> \
     --resource-group <rg> \
     --allowed-origins "https://portal.azure.com"
   ```

### Issue: ARM Action Buttons Not Visible (Loading Spinners)

**Symptoms:**
- See [Loading...] ⏳ instead of buttons
- Sections never finish loading

**Diagnosis:**
```bash
# Verify workbook content
grep -o '"type":[[:space:]]*11' workbook/DeviceManager-Hybrid.json | wc -l
# Expected output: 6
# If output is 0, wrong file deployed
```

**Fix:**
```bash
# Re-deploy correct file
cat workbook/DeviceManager-Hybrid.json
# Look for "type": 11 and "armActionContext"
# If not found, file is wrong - re-import from main branch
```

### Issue: Confirmation Dialog Not Appearing

**Symptoms:**
- Click button, nothing happens
- Or page refreshes instead of showing dialog

**Diagnosis:**
- Check browser console for JavaScript errors
- Verify Azure Workbooks service is working

**Fix:**
1. Clear browser cache
2. Try in different browser
3. Ensure `linkTarget: "ArmAction"` is set in JSON

### Issue: "400 Bad Request" on Execution

**Symptoms:**
- Confirmation dialog appears
- Click OK → Error: "400 Bad Request"

**Diagnosis:**
```bash
# Check Function App logs
az functionapp log tail --name <functionapp> --resource-group <rg>
# Look for error details
```

**Common Causes:**
1. **Duplicate action pending** → ✅ Expected behavior (warning should prevent)
2. **Missing parameters** → Check if deviceIds, tenantId passed correctly
3. **Defender API error** → Check Defender XDR service health

### Issue: Actions Not Updating in Status Table

**Symptoms:**
- Execute action successfully
- "📊 Action Status Tracking" doesn't show new action
- Or shows old data

**Diagnosis:**
```bash
# Test Get All Actions endpoint
curl -X POST \
  "https://<functionapp>.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20All%20Actions&tenantId=<tenant-id>"
```

**Fix:**
1. **Check auto-refresh setting** → Set to "Every 30 seconds"
2. **Manual refresh** → Click refresh button on status table
3. **JSONPath issue** → Verify response has `actions` array
4. **Filter issue** → Remove any filters on status table

---

## 📊 Success Criteria Checklist

### Deployment Success
- [ ] Workbook opens in Azure Portal
- [ ] Parameters load without errors
- [ ] DeviceList auto-populates with devices
- [ ] All 6 ARM Action buttons visible (no loading spinners)

### Functional Success
- [ ] Scan button shows confirmation dialog
- [ ] Executing scan creates new action in status table
- [ ] Status updates from Pending → InProgress → Succeeded
- [ ] Pending Actions Check shows running actions
- [ ] Cancel button populates CancelActionId parameter
- [ ] Cancelling action succeeds and updates status

### User Experience Success
- [ ] Buttons render instantly (<1 second)
- [ ] Confirmation dialogs are clear and descriptive
- [ ] Auto-refresh works (30 second interval)
- [ ] No infinite loading spinners
- [ ] Error messages are clear and actionable

---

## 🎯 Quick Test Script (PowerShell)

```powershell
# Quick smoke test for DeviceManager Hybrid workbook
$subscriptionId = "<your-subscription-id>"
$resourceGroup = "<your-rg>"
$functionApp = "<your-function-app>"
$tenantId = "<your-tenant-id>"

Write-Host "Testing DefenderC2 Function App..." -ForegroundColor Cyan

# Test 1: Get Devices
Write-Host "`nTest 1: Get Devices" -ForegroundColor Yellow
$devicesUrl = "https://$functionApp.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=$tenantId"
$devices = Invoke-RestMethod -Uri $devicesUrl -Method Post
Write-Host "✅ Devices found: $($devices.devices.Count)" -ForegroundColor Green
$devices.devices | Select-Object -First 3 | Format-Table id, computerDnsName

# Test 2: Get All Actions
Write-Host "`nTest 2: Get All Actions" -ForegroundColor Yellow
$actionsUrl = "https://$functionApp.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20All%20Actions&tenantId=$tenantId"
$actions = Invoke-RestMethod -Uri $actionsUrl -Method Post
Write-Host "✅ Actions found: $($actions.actions.Count)" -ForegroundColor Green
$actions.actions | Select-Object -First 3 | Format-Table type, status, computerDnsName

# Test 3: Workbook file verification
Write-Host "`nTest 3: Workbook Structure" -ForegroundColor Yellow
$workbookPath = "workbook/DeviceManager-Hybrid.json"
$content = Get-Content $workbookPath -Raw | ConvertFrom-Json
$armActions = ($content.items | ForEach-Object { 
    if ($_.type -eq 12 -and $_.content.items) {
        $_.content.items | Where-Object { $_.type -eq 11 }
    }
}).Count
Write-Host "✅ ARM Actions in workbook: $armActions" -ForegroundColor Green

if ($armActions -eq 6) {
    Write-Host "`n🎉 All tests passed! Workbook is ready for deployment." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Warning: Expected 6 ARM Actions, found $armActions" -ForegroundColor Red
}
```

---

## 📝 Summary

**Hybrid Workbook Features:**
- ✅ 6 ARM Action buttons (Type 11 LinkItem)
- ✅ 4 CustomEndpoint queries (monitoring only)
- ✅ Auto-refresh every 30 seconds
- ✅ Pending actions warning
- ✅ Action cancellation
- ✅ Native Azure confirmation dialogs

**Expected Deployment Time:** 5 minutes  
**Expected Test Time:** 5 minutes  
**Total Time to Verify:** 10 minutes

**If all tests pass:**
- Workbook is ready for production use
- Close PR #93 with ✅ Success

**If tests fail:**
- Check troubleshooting section
- Review `PR93_HYBRID_FIX.md` for detailed diagnostics
- Verify Function App logs for API errors
