# ✅ Minimal Workbook - FINAL WORKING VERSION

## 📥 Download Link

```
https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/workbook/DefenderC2-Workbook-MINIMAL-FIXED.json
```

## 🔧 All Fixes Applied

### **1. Auto-Discovery Parameters - Fixed Query Syntax**
**Issue**: Parameters showing `<unset>`  
**Fix**: Use `project value = field` syntax

```kusto
✅ Resources | where id == '{FunctionApp}' | project value = subscriptionId
❌ Resources | where id == '{FunctionApp}' | project subscriptionId
```

### **2. CustomEndpoint Format - Use URL Params**
**Issue**: "query failed" on CustomEndpoints  
**Fix**: Use `urlParams` array, not POST body

```json
{
  "data": null,
  "headers": [],
  "body": null,
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

### **3. ARM Actions - Use Query Params**
**Issue**: ARM actions failing with malformed subscription  
**Fix**: Use `params` array, not POST body

```json
{
  "headers": [],
  "params": [
    {"key": "api-version", "value": "2022-03-01"},
    {"key": "action", "value": "Isolate Device"},
    {"key": "tenantId", "value": "{TenantId}"},
    {"key": "deviceIds", "value": "{DeviceList}"}
  ],
  "body": null
}
```

### **4. Device Grid QueryType**
**Issue**: "This query could not run because some parameters are not set"  
**Fix**: Use `queryType: 10` for CustomEndpoint displays

```json
{
  "type": 3,
  "content": {
    "queryType": 10  // ✅ CustomEndpoint, not 12
  }
}
```

### **5. Global Parameters**
**Issue**: Parameters not accessible across workbook  
**Fix**: All parameters marked as `isGlobal: true`

---

## 📋 Workbook Structure

| Component | Count | Details |
|-----------|-------|---------|
| **Parameters** | 6 | FunctionApp, Subscription, ResourceGroup, FunctionAppName, TenantId, DeviceList |
| **ARM Actions** | 3 | Isolate, Unisolate, Scan |
| **Displays** | 1 | Device grid with 5 columns |
| **Tabs** | 0 | Single page (can expand later) |

---

## 🚀 Deployment Steps

### **Option 1: Import from GitHub (Recommended)**

1. **Azure Portal** → **Monitor** → **Workbooks**
2. Click **+ New**
3. Click **Advanced Editor** (</> icon)
4. **Paste** the entire JSON from the download link above
5. Click **Apply**
6. Click **Save** (top toolbar)
7. Enter name: `DefenderC2 Command & Control Console`
8. Click **Done**

### **Option 2: Replace Existing Workbook**

1. **Open your existing workbook** in Azure Portal
2. Click **Edit** mode
3. Click **Advanced Editor** (</> icon)
4. **Replace ALL JSON** with content from download link
5. Click **Apply**
6. Click **Done Editing**
7. Click **Save**

---

## ✅ Expected Behavior

### **Parameters (Auto-Population)**
1. ✅ Select **Function App** → Auto-populates Subscription, ResourceGroup, FunctionAppName
2. ✅ Select **Defender XDR Tenant** → Dropdown shows all tenants from Lighthouse
3. ✅ **Select Devices** → Populates within 2-3 seconds, shows "All" option

### **Device Grid**
4. ✅ **Device List** table displays with 5 columns:
   - Device Name
   - Risk Score
   - Health Status
   - IP Address
   - Device ID

### **ARM Actions**
5. ✅ Click **Isolate Devices** → Opens ARM action dialog
6. ✅ Verify URL has **NO `<unset>`** placeholders
7. ✅ URL should show: `/subscriptions/8010e3c-.../resourceGroups/alex-testing-rg/...`

---

## 🧪 Testing Checklist

- [ ] Function App parameter populates automatically
- [ ] Subscription parameter shows correct subscription ID
- [ ] ResourceGroup parameter shows correct resource group name
- [ ] FunctionAppName parameter shows correct function app name
- [ ] Defender XDR Tenant dropdown has options
- [ ] Select Devices dropdown loads and stops (no infinite loop)
- [ ] Device List grid displays device data
- [ ] ARM action buttons are enabled (not grayed out)
- [ ] Clicking ARM action opens dialog with valid URL (no `<unset>`)
- [ ] ARM action can be executed successfully

---

## 🐛 Troubleshooting

### **DeviceList shows "query failed"**
**Cause**: Function app not responding or CORS issue  
**Fix**: 
```bash
# Test function directly
curl "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=YOUR-TENANT-ID"
```

### **ARM action shows `<unset>` in URL**
**Cause**: Parameters not populated correctly  
**Fix**: Check that auto-discovery parameters use `project value = field` syntax

### **"This query could not run because some parameters are not set"**
**Cause**: Wrong queryType or missing criteriaData  
**Fix**: Ensure CustomEndpoint displays use `queryType: 10` and have all required parameters in criteriaData

### **Parameters not accessible in ARM actions**
**Cause**: Parameters not marked as global  
**Fix**: Ensure all parameters have `"isGlobal": true`

---

## 📊 Comparison: Before vs After

| Issue | Before | After |
|-------|--------|-------|
| Subscription | `<unset>` | `8010e3c-3ec4-4567-b06d-7d47...` |
| ResourceGroup | `<unset>` | `alex-testing-rg` |
| DeviceList | Infinite loop | Loads and stops |
| ARM Actions | Failed with malformed subscription | Opens with valid URL |
| Device Grid | "Please provide valid resource path" | Displays devices |

---

## 🎯 Next Steps (Optional Expansion)

Once the minimal workbook works, you can expand it:

1. **Add More ARM Actions**: Copy the working action pattern for other commands
2. **Add Tabs**: Use conditional visibility with a `selectedTab` parameter
3. **Add More Displays**: Add more CustomEndpoint queries for different views
4. **Add Filters**: Add time range, device filters, etc.

**Pattern to follow**: Always use the same structure as the working minimal version!

---

## 📚 Key Learnings

1. **Azure Resource Graph queries** must use `project value = field` for parameter auto-population
2. **Azure Function invocations** via ARM actions use **query string params**, not POST body
3. **CustomEndpoint queries** use **urlParams**, not body JSON
4. **QueryType matters**: Type 10 for CustomEndpoints, Type 1 for Resource Graph
5. **Global parameters** (`isGlobal: true`) are required for cross-component access
6. **CriteriaData** must include ALL parameters referenced in the component

---

## 🆘 Support

If issues persist:
1. Export workbook JSON from Azure Portal
2. Compare against the working version from GitHub
3. Check for differences in:
   - Parameter query syntax (`project value = ...`)
   - CustomEndpoint format (`urlParams` vs `body`)
   - ARM action format (`params` vs `body`)
   - QueryType values
   - CriteriaData completeness

---

**Last Updated**: October 14, 2025  
**Commit**: `233afb8`  
**Status**: ✅ Ready for deployment
