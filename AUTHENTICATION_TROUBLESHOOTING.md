# 🔒 Authentication Troubleshooting Guide

## ✅ Function Configuration Status

All functions are configured with **anonymous authentication**:
- ✅ DefenderC2Dispatcher - `"authLevel": "anonymous"`
- ✅ DefenderC2Orchestrator - `"authLevel": "anonymous"`
- ✅ DefenderC2TIManager - `"authLevel": "anonymous"`
- ✅ DefenderC2HuntManager - `"authLevel": "anonymous"`
- ✅ DefenderC2IncidentManager - `"authLevel": "anonymous"`
- ✅ DefenderC2CDManager - `"authLevel": "anonymous"`

**This means NO function keys are required for HTTP calls.**

---

## 🐛 Why You Might Still Get 401 Unauthorized

Even though functions are configured as anonymous, you can still get 401 errors due to:

### 1. **Azure App Service Authentication (EasyAuth) Enabled**
Your Function App might have Azure AD authentication enabled at the **app level**.

**Check:**
```bash
az webapp auth show \
  --name <function-app-name> \
  --resource-group <resource-group>
```

**Fix:**
```bash
# Disable App Service Authentication
az webapp auth update \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --enabled false
```

Or via Azure Portal:
1. Function App → **Authentication**
2. If you see "Identity provider" configured → **Remove it**
3. Or set to "Allow unauthenticated access"

---

### 2. **CORS Configuration**
CustomEndpoint from Azure Workbooks requires CORS to be configured.

**Check current CORS:**
```bash
az functionapp cors show \
  --name <function-app-name> \
  --resource-group <resource-group>
```

**Fix - Allow Workbook Origins:**
```bash
az functionapp cors add \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --allowed-origins \
    "https://portal.azure.com" \
    "https://ms.portal.azure.com" \
    "https://afd.hosting.portal.azure.net"
```

Or via Azure Portal:
1. Function App → **CORS**
2. Add allowed origins:
   - `https://portal.azure.com`
   - `https://ms.portal.azure.com`
   - `https://afd.hosting.portal.azure.net`
3. Enable "Enable Access-Control-Allow-Credentials" if needed

---

### 3. **IP Restrictions**
Your Function App might have IP restrictions enabled.

**Check:**
```bash
az functionapp config access-restriction show \
  --name <function-app-name> \
  --resource-group <resource-group>
```

**Fix:**
```bash
# Remove all restrictions (or add specific IPs)
az functionapp config access-restriction remove \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --rule-name <rule-name>
```

---

### 4. **Function Not Yet Deployed**
The function package might not be deployed yet.

**Check:**
```bash
# Verify function exists
az functionapp function list \
  --name <function-app-name> \
  --resource-group <resource-group>
```

**Fix:**
```bash
# Restart Function App to pull latest package
az functionapp restart \
  --name <function-app-name> \
  --resource-group <resource-group>
```

---

### 5. **Networking/VNet Integration**
Function App might be in a VNet that blocks external access.

**Check:**
```bash
az functionapp vnet-integration list \
  --name <function-app-name> \
  --resource-group <resource-group>
```

**Fix:**
- Either remove VNet integration
- Or ensure workbook can access the VNet

---

## ✅ Recommended Configuration

### Option 1: Anonymous with CORS (CustomEndpoint) ✅ **CURRENT**
```json
{
  "authLevel": "anonymous"
}
```

**Pros:**
- ✅ Works with CustomEndpoint
- ✅ No function keys needed
- ✅ Simpler workbook configuration

**Cons:**
- ⚠️ Anyone with the URL can call the function
- ⚠️ Need to configure CORS properly

**Security:**
- Function validates `APPID` and `SECRETID` env vars internally
- Requires valid Azure AD tenant credentials
- CORS limits which origins can call

**Use for:** READ operations (Get Devices, List Library, Get Actions)

---

### Option 2: ARM Actions (Management API) ✅ **RECOMMENDED FOR WRITE**
```yaml
linkTarget: ArmAction
armActionContext:
  path: "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01"
  httpMethod: POST
```

**Pros:**
- ✅ Uses Azure Management API authentication
- ✅ User's AAD identity for auth
- ✅ Better for write operations
- ✅ No CORS issues

**Cons:**
- ❌ Cannot be used for parameter dropdowns
- ❌ More complex to set up

**Use for:** WRITE operations (Isolate Device, Upload to Library, Run Scan)

---

## 🔍 Testing Authentication

### Test 1: Direct curl (should work if anonymous)
```bash
curl -X POST "https://<function-app>.azurewebsites.net/api/DefenderC2Dispatcher" \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"<tenant-id>"}'
```

**Expected:**
- ✅ 200 OK with device list
- ❌ 401 Unauthorized → App Service Auth is enabled
- ❌ 403 Forbidden → IP restrictions or CORS
- ❌ 500 Error → Check function logs

### Test 2: From Browser Console (tests CORS)
```javascript
fetch('https://<function-app>.azurewebsites.net/api/DefenderC2Dispatcher', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({action: 'Get Devices', tenantId: '<tenant-id>'})
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

**Expected:**
- ✅ Device list returned
- ❌ CORS error → Configure CORS
- ❌ 401 → App Service Auth enabled

---

## 🛠️ Quick Fix Checklist

If you're getting 401 errors with CustomEndpoint:

- [ ] **Check function.json** - Confirm `"authLevel": "anonymous"`
- [ ] **Check App Service Authentication** - Must be DISABLED
- [ ] **Check CORS** - Add portal.azure.com origins
- [ ] **Check IP Restrictions** - Remove or allow workbook IPs
- [ ] **Check VNet Integration** - Ensure accessible
- [ ] **Restart Function App** - Ensure latest code deployed
- [ ] **Test with curl** - Verify it works outside workbook
- [ ] **Check Function App logs** - See actual errors

---

## 📊 Current Workbook Configuration

### CustomEndpoint Queries (READ - anonymous)
```
✅ Get Devices (device lists, dropdowns)
✅ Get Actions (action history)
✅ Get Action Status (check status)
✅ List Library Files (library browser)
✅ Get Library File (download file)
```

### ARM Actions (WRITE - Management API)
```
✅ Isolate Device
✅ Unisolate Device
✅ Run Antivirus Scan
✅ Collect Investigation Package
✅ Upload to Library
✅ Deploy from Library
```

---

## 🔒 Security Best Practices

1. **Use ARM Actions for Write Operations**
   - Better audit trail
   - Uses user's identity
   - More secure

2. **Use CustomEndpoint for Read Operations**
   - Needed for dropdowns/parameters
   - Configure CORS properly
   - Monitor access logs

3. **Environment Variables Protection**
   - Keep `APPID` and `SECRETID` in Key Vault
   - Use Managed Identity where possible
   - Rotate secrets regularly

4. **Network Security**
   - Use VNet integration if needed
   - Configure firewall rules
   - Enable diagnostic logging

---

## 📞 Still Getting 401?

Run this diagnostic:

```bash
#!/bin/bash
FUNCTION_APP="<your-function-app>"
RG="<your-resource-group>"

echo "🔍 Diagnosing Function App Authentication..."

echo -e "\n1. App Service Authentication:"
az webapp auth show --name $FUNCTION_APP --resource-group $RG --query "enabled"

echo -e "\n2. CORS Configuration:"
az functionapp cors show --name $FUNCTION_APP --resource-group $RG

echo -e "\n3. IP Restrictions:"
az functionapp config access-restriction show --name $FUNCTION_APP --resource-group $RG

echo -e "\n4. Functions List:"
az functionapp function list --name $FUNCTION_APP --resource-group $RG --query "[].name"

echo -e "\n5. VNet Integration:"
az functionapp vnet-integration list --name $FUNCTION_APP --resource-group $RG

echo -e "\n✅ Run these checks to identify the issue!"
```

---

**Last Updated:** October 11, 2025  
**Status:** All functions configured as anonymous ✅  
**Issue:** CustomEndpoint requires proper CORS and no App Service Auth

