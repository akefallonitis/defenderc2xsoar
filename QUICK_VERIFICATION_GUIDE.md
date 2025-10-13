# Quick Verification Guide: DefenderC2 Workbook

## 🚀 60-Second Health Check

Use this guide to quickly verify your DefenderC2 workbook is correctly configured and working.

---

## ✅ Step 1: Configuration Check (10 seconds)

```bash
python3 scripts/verify_workbook_config.py
```

**Look for:** `🎉 SUCCESS: All workbooks are correctly configured!`

**If you see this:** ✅ Configuration is correct, skip to Step 2  
**If you don't:** ❌ Download latest workbook from GitHub and try again

---

## ✅ Step 2: API Endpoint Test (15 seconds)

Replace values and run:

```bash
curl "https://YOUR-FUNCTION-APP.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=YOUR-TENANT-ID"
```

**Look for:** JSON response with `"status": "Success"` and device list

**If you see this:** ✅ Function App is working, skip to Step 3  
**If you don't:** ❌ Check Function App deployment and CORS settings

---

## ✅ Step 3: CORS Check (10 seconds)

```bash
az functionapp cors show --name YOUR-FUNCTION-APP --resource-group YOUR-RESOURCE-GROUP
```

**Look for:** `"https://portal.azure.com"` in allowedOrigins

**If you see this:** ✅ CORS is configured  
**If you don't:** ❌ Run: `az functionapp cors add --name YOUR-FUNCTION-APP --resource-group YOUR-RESOURCE-GROUP --allowed-origins https://portal.azure.com`

---

## ✅ Step 4: Workbook Test (25 seconds)

1. Open workbook in Azure Portal
2. Select Function App from dropdown
3. Check these auto-populate:
   - Subscription ✅
   - ResourceGroup ✅
   - FunctionAppName ✅
   - TenantId ✅
4. Check "Available Devices" dropdown populates ✅

**If all work:** ✅ Workbook is fully functional!  
**If any fail:** ❌ See troubleshooting section below

---

## 🐛 Quick Troubleshooting

### Problem: Step 1 fails
**Solution:** Download latest DefenderC2-Workbook.json from GitHub main branch

### Problem: Step 2 fails  
**Solution:** Check Function App is running: `az functionapp show --name YOUR-FUNCTION-APP --query state`

### Problem: Step 3 fails
**Solution:** Add CORS: `az functionapp cors add --name YOUR-FUNCTION-APP --resource-group YOUR-RESOURCE-GROUP --allowed-origins https://portal.azure.com`

### Problem: Step 4 fails - FunctionApp dropdown empty
**Solution:** Verify Function App exists: `az functionapp list --query "[].name"`

### Problem: Step 4 fails - Auto-populated fields empty
**Solution:**  
1. Check browser console (F12) for errors
2. Verify you have Reader permissions on Function App
3. Wait 5 seconds and refresh the workbook

### Problem: Step 4 fails - Device dropdown empty
**Solution:**
1. Verify Step 2 passes (API test)
2. Check Microsoft Defender has devices: Sign into https://security.microsoft.com → Devices
3. Verify TenantId is correct

---

## 📊 Expected State After Successful Verification

```
Configuration:     ✅ Passed
API Endpoint:      ✅ Responding  
CORS:              ✅ Configured
Function App:      ✅ Running
Parameter Cascade: ✅ Working
Device List:       ✅ Populated
```

**Status: Ready for use!**

---

## 🆘 Still Having Issues?

**Need detailed help?**
- Read: [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)
- Follow: [DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md)

**Configuration questions?**
- Review: [ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md)
- Review: [ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md](ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md)

**Best practices?**
- Read: [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md)

---

## 🔑 Key Commands Reference

```bash
# Verify workbook configuration
python3 scripts/verify_workbook_config.py

# Test API endpoint
curl "https://${FUNCTION_APP}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"

# Check CORS
az functionapp cors show --name ${FUNCTION_APP} --resource-group ${RESOURCE_GROUP}

# Add CORS
az functionapp cors add --name ${FUNCTION_APP} --resource-group ${RESOURCE_GROUP} --allowed-origins https://portal.azure.com

# List Function Apps
az functionapp list --query "[].{name:name,state:state,resourceGroup:resourceGroup}" -o table

# View Function App logs
az functionapp log tail --name ${FUNCTION_APP} --resource-group ${RESOURCE_GROUP}

# Test ARM invocation
az rest --method post \
  --uri "/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${FUNCTION_APP}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01" \
  --body '{"action":"Get Devices","tenantId":"'${TENANT_ID}'"}'
```

---

## 📝 Checklist

Use this for quick verification:

- [ ] Configuration verification passes
- [ ] API endpoint responds with device data
- [ ] CORS includes https://portal.azure.com
- [ ] FunctionApp dropdown shows Function Apps
- [ ] Auto-populated parameters fill after FunctionApp selection
- [ ] Device dropdown populates with devices
- [ ] Test action button works (try non-destructive action)

**All checked?** ✅ You're ready to use DefenderC2 workbook!

---

**Quick Guide Version:** 1.0  
**Last Updated:** October 13, 2025  
**Estimated Time:** 60 seconds for healthy system  
**Prerequisites:** Azure CLI, curl, Python 3
