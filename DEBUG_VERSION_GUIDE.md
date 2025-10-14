# 🔍 DEBUG VERSION - All Parameters Visible

## 🎯 What Changed (Commit `c27cfc4`)

Made ALL parameters **visible** so we can see what's happening with auto-discovery.

### Parameters Now Visible

| Parameter | Label | Type | Source |
|-----------|-------|------|--------|
| FunctionApp | DefenderC2 Function App | Resource Picker | User selects |
| Subscription | 📋 Subscription ID | Text (Auto) | From FunctionApp |
| ResourceGroup | 📦 Resource Group | Text (Auto) | From FunctionApp |
| FunctionAppName | ⚡ Function App Name | Text (Auto) | From FunctionApp |
| TenantId | 🏢 Defender XDR Tenant | Dropdown (Auto) | Auto-query + select |
| DeviceList | 💻 Select Devices | Dropdown (CustomEP) | From Function |

---

## 📥 Deploy & Test

### Download
```bash
curl -o workbook.json https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/workbook/DefenderC2-Workbook-MINIMAL-FIXED.json
```

### Import
1. Azure Portal → Sentinel → Workbooks → **+ New**
2. Advanced Editor → Paste JSON
3. Apply → Save As "DefenderC2 Debug Version"

---

## 🔍 What to Check After Deploy

### Step 1: Select Function App
- Click the **DefenderC2 Function App** dropdown
- Select your function app
- **WATCH THE PARAMETERS SECTION**

### Step 2: Check Auto-Discovery
After selecting Function App, these should **auto-populate**:

- [ ] **📋 Subscription ID** - Should show UUID
- [ ] **📦 Resource Group** - Should show resource group name
- [ ] **⚡ Function App Name** - Should show function app name (e.g., "defenderc2")
- [ ] **🏢 Defender XDR Tenant** - Should auto-select first tenant

### Step 3: Check Device List
Once the above 4 parameters have values:

- [ ] **💻 Select Devices** - Should stop showing "Waiting for parameters"
- [ ] Device dropdown should populate with devices
- [ ] Device grid below should display table

---

## 🐛 Troubleshooting

### If Subscription/ResourceGroup/FunctionAppName Are Empty

**Problem:** Resource Graph queries not working

**Check:**
1. You have permissions to query Azure Resource Graph
2. The Function App resource exists in Azure
3. Browser console (F12) for errors

**Fix:** Run this in Azure Cloud Shell to test:
```bash
az graph query -q "Resources | where type == 'microsoft.web/sites' and name == 'YOUR-FUNCTION-NAME' | project subscriptionId, resourceGroup, name"
```

### If TenantId Is Empty

**Problem:** No subscriptions found

**Check:**
1. You have access to subscriptions
2. Azure Lighthouse is configured

**Fix:** Run this:
```bash
az graph query -q "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId"
```

### If DeviceList Shows "Waiting for parameters: FunctionAppName"

**Problem:** FunctionAppName parameter is empty

**Solution:** This debug version will show you exactly which parameter is missing - look at the parameters section!

### If DeviceList Is Empty But Parameters Are Populated

**Problem:** Function not responding or returning empty data

**Test directly:**
```bash
curl "https://YOUR-FUNCTION.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=YOUR-TENANT-ID"
```

Expected response:
```json
{
  "devices": [
    {"id": "...", "computerDnsName": "PC-001", ...}
  ]
}
```

---

## ✅ Success Criteria

After deploying, you should see:

1. ✅ All 6 parameters visible in parameters section
2. ✅ First 4 parameters auto-populate immediately after FunctionApp selection
3. ✅ TenantId auto-selects first tenant
4. ✅ DeviceList stops showing "Waiting" and populates with devices
5. ✅ Device grid displays device table
6. ✅ ARM action buttons work when devices selected

---

## 📸 What You Should See

**Parameters section should look like:**
```
DefenderC2 Function App: [your-function-app] ✓
📋 Subscription ID: [guid] ✓
📦 Resource Group: [rg-name] ✓
⚡ Function App Name: [function-name] ✓
🏢 Defender XDR Tenant: [tenant-id] ✓
💻 Select Devices: [loading...] → [device list]
```

---

## 🎯 Next Steps

**If everything works:**
- We can hide the parameters again (make them isHiddenWhenLocked: true)
- Polish the UI
- Deploy final version

**If something doesn't populate:**
- Screenshot the parameters section
- Share any browser console errors
- Test the Resource Graph queries directly

---

**Deploy now and let me know what you see in the parameters section!** 🚀
