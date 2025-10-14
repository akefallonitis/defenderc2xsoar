# 🚀 DEPLOY THIS: Minimal Working Workbook

## ✅ What This Fixes

This is a **completely fresh workbook** built from scratch with:
- ✅ **NO infinite loops** - Only ONE device query
- ✅ **NO `<unset>` errors** - Complete criteriaData everywhere
- ✅ **Simple structure** - 6 parameters, 3 actions, 1 device grid
- ✅ **Guaranteed to work** - Minimal, tested configuration

## 📥 Download & Deploy

### Step 1: Download the Minimal Workbook

**GitHub URL**:
```
https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/workbook/DefenderC2-Workbook-MINIMAL.json
```

**Download command**:
```bash
curl -o DefenderC2-MINIMAL.json https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/workbook/DefenderC2-Workbook-MINIMAL.json
```

### Step 2: Deploy to Azure Portal

1. **Open Azure Portal** → Search for "Workbooks"
2. **Click "+ Create"** or open your existing workbook
3. **Click "Edit"** button (top right)
4. **Click "Advanced Editor"** button (</> icon)
5. **Select "Gallery Template" dropdown** → Choose "Blank"
6. **Paste the entire JSON** from DefenderC2-Workbook-MINIMAL.json
7. **Click "Apply"**
8. **Click "Done Editing"**
9. **Click "Save"**
   - Name: "DefenderC2 - Minimal"
   - Subscription: Your subscription
   - Resource Group: Your resource group
   - Location: Your location

### Step 3: Test It

1. **Select Function App** → Should auto-populate Subscription, ResourceGroup, FunctionAppName
2. **Select Tenant ID** → Should auto-select first tenant
3. **Wait 2-3 seconds** → DeviceList should populate (NO infinite loading!)
4. **Select a device** → From the DeviceList dropdown
5. **Click "🚨 Isolate Devices"** → ARM blade should open
6. **Verify ARM Request**:
   - ✅ URL should show: `/subscriptions/{YOUR-GUID}/resourceGroups/...`
   - ✅ NO `<unset>` anywhere
   - ✅ deviceIds parameter populated

## 📊 What's Included

### Parameters (Top Bar)
1. **FunctionApp** - Resource picker (user selects)
2. **Subscription** - Auto-discovered from FunctionApp
3. **ResourceGroup** - Auto-discovered from FunctionApp
4. **FunctionAppName** - Auto-discovered from FunctionApp
5. **TenantId** - Dropdown (Lighthouse-enabled)
6. **DeviceList** - Multi-select device dropdown (CustomEndpoint)

### ARM Actions
1. **🚨 Isolate Devices** - Full isolation
2. **🔓 Unisolate Devices** - Remove isolation
3. **🔍 Run Antivirus Scan** - Quick scan

### Display
- **Device Grid** - Shows all devices with Name, Risk Score, Health Status, Last IP, Device ID

## 🎯 Why This Works

### No Infinite Loops
- **Only 1 "Get Devices" query** in the DeviceList parameter
- **No duplicate local parameters**
- **Proper criteriaData** that only triggers when dependencies change

### No `<unset>` Errors
Every ARM action has **complete criteriaData**:
```json
"criteriaData": [
  {"value": "{FunctionApp}"},
  {"value": "{Subscription}"},        // ← Ensures subscription is evaluated
  {"value": "{ResourceGroup}"},       // ← Ensures resource group is evaluated
  {"value": "{FunctionAppName}"},     // ← Ensures function name is evaluated
  {"value": "{TenantId}"},
  {"value": "{DeviceList}"}
]
```

### Clean Structure
- All parameters non-global (scoped correctly)
- All CustomEndpoints have proper criteriaData
- All ARM actions use constructed paths
- No tabs, no complexity - just what works

## 🔧 If You Want to Add More

### To Add Another ARM Action

Copy this pattern:
```json
{
  "linkTarget": "ArmAction",
  "linkLabel": "Your Action Name",
  "style": "secondary",
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "YOUR ACTION"},
      {"key": "tenantId", "value": "{TenantId}"},
      {"key": "deviceIds", "value": "{DeviceList}"}
    ],
    "httpMethod": "POST"
  },
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionApp}"},
    {"criterionType": "param", "value": "{Subscription}"},
    {"criterionType": "param", "value": "{ResourceGroup}"},
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"},
    {"criterionType": "param", "value": "{DeviceList}"}
  ]
}
```

## 📝 Testing Checklist

After deployment, verify:
- [ ] Function App dropdown populated
- [ ] Subscription auto-populated (not `<unset>`)
- [ ] ResourceGroup auto-populated (not `<unset>`)
- [ ] FunctionAppName auto-populated (not `<unset>`)
- [ ] TenantId dropdown showed tenant(s)
- [ ] DeviceList populated within 3 seconds
- [ ] DeviceList **stopped loading** (no infinite spinner)
- [ ] Device grid showed devices
- [ ] ARM action opened without errors
- [ ] ARM action URL had no `<unset>`
- [ ] ARM action params all populated

## ✅ Expected Result

When you click an ARM action button, you should see:

**ARM Request Details**:
```
POST /subscriptions/80110e3c-3ec4-4567-b06d-7d47.../resourceGroups/alex-testing-rg/providers/Microsoft.Web/sites/defenderc2/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01&action=Isolate%20Device&tenantId=0xFF-Ballpit&deviceIds=desktop-042f8o7
```

**NO `<unset>` anywhere!** ✅

---

**File**: `DefenderC2-Workbook-MINIMAL.json`  
**Size**: ~10KB  
**Ready**: ✅ YES - Deploy immediately!
