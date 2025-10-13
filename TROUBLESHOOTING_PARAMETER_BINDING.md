# Troubleshooting: Parameter Binding Issues in DefenderC2 Workbook

## Overview

This guide helps diagnose and resolve issues where Azure Workbook parameters appear to not be binding correctly, causing "stuck in refreshing" states or empty parameter values in API calls.

## ✅ Configuration Status

As of the latest update, **all parameter binding issues have been fixed** in the DefenderC2 workbook configuration:

- ✅ All CustomEndpoint queries have proper `criteriaData` dependencies
- ✅ All device parameters auto-populate correctly
- ✅ All ARM actions use correct paths and parameter substitution
- ✅ All parameters properly cascade from FunctionApp selection

**If you're experiencing issues, they are likely environmental rather than configuration-related.**

---

## 🔍 Diagnostic Checklist

### Step 1: Verify You Have the Latest Workbook

```bash
# Check your workbook file date
ls -l workbook/DefenderC2-Workbook.json

# Verify configuration
python3 scripts/verify_workbook_config.py
```

**Expected Output:**
```
✅ ARM Actions: 15/15 with api-version in params
✅ ARM Actions: 15/15 with relative paths
✅ ARM Actions: 15/15 without api-version in URL
✅ Device Parameters: 5/5 with CustomEndpoint
✅ CustomEndpoint Queries: 21/21 with parameter substitution

🎉 SUCCESS: All workbooks are correctly configured!
```

**If this fails:** You have an old version. Download the latest from GitHub.

---

### Step 2: Verify Function App is Deployed

**Test the API endpoint directly:**

```bash
# Replace with your values
FUNCTION_APP_NAME="your-function-app"
TENANT_ID="your-tenant-id"

# Test Get Devices action
curl "https://${FUNCTION_APP_NAME}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"
```

**Expected Response:**
```json
{
  "action": "Get Devices",
  "status": "Success",
  "devices": [...]
}
```

**If this fails:**
- Function App is not deployed
- Function App name is incorrect
- Network connectivity issues
- Function requires authentication (should be anonymous)

---

### Step 3: Check Function App CORS Settings

**Azure Portal → Function App → CORS**

**Required Setting:**
```
Allowed Origins:
  https://portal.azure.com
```

**Additional recommended origins:**
```
  https://ms.portal.azure.com
  https://preview.portal.azure.com
```

**If CORS is not configured:** Workbook API calls will fail with CORS errors.

---

### Step 4: Verify Authentication Settings

**Azure Portal → Function App → Authentication**

**Required Setting:**
```
Authentication: Disabled (Anonymous access allowed)
```

OR if using managed identity:
```
Authentication: Microsoft Identity Platform
- Allow anonymous access: Yes
- Unauthenticated requests: Allow (no action)
```

**If authentication blocks anonymous access:** Workbook CustomEndpoint queries will fail with 401 errors.

---

### Step 5: Check Azure Portal Console for Errors

**Open workbook in Azure Portal → Press F12 → Console tab**

Look for:
- ❌ CORS errors: `blocked by CORS policy`
- ❌ 401 errors: Authentication issues
- ❌ 404 errors: Function not found
- ❌ 500 errors: Function App errors
- ❌ Timeout errors: Function taking too long to respond

---

### Step 6: Verify Parameter Cascade

**In the workbook:**

1. **Select FunctionApp** from dropdown
   - ✅ Should show all Function Apps in your subscriptions
   - ❌ If empty: Check Azure permissions to list resources

2. **After selecting FunctionApp:**
   - ✅ Subscription should auto-populate
   - ✅ ResourceGroup should auto-populate  
   - ✅ FunctionAppName should auto-populate
   - ✅ TenantId should auto-populate

3. **After auto-population:**
   - ✅ "Available Devices" dropdown should populate
   - ✅ Other device dropdowns should populate

**If auto-population fails:**
- Check console for Resource Graph query errors
- Verify you have Reader permissions on the Function App
- Check if Function App exists in listed subscription

---

## 🐛 Common Issues and Solutions

### Issue: "Parameters stuck in refreshing"

**Symptoms:**
- Spinner never stops
- Dropdown stays in loading state
- No error messages

**Causes:**
1. Function App not responding
2. CORS blocking requests
3. Query timeout
4. Invalid JSON response

**Solutions:**
```bash
# Test the endpoint directly
curl -v "https://${FUNCTION_APP_NAME}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"

# Check Function App logs
az functionapp log tail --name ${FUNCTION_APP_NAME} --resource-group ${RESOURCE_GROUP}
```

---

### Issue: "FunctionApp dropdown is empty"

**Symptoms:**
- First dropdown has no options
- Cannot proceed with workbook

**Causes:**
1. No Function Apps in subscription
2. Function App in different subscription
3. Insufficient Azure permissions

**Solutions:**
1. Verify Function App exists:
```bash
az functionapp list --query "[].{name:name,resourceGroup:resourceGroup}" -o table
```

2. Check if it's a Function App:
```bash
az functionapp show --name ${FUNCTION_APP_NAME} --resource-group ${RESOURCE_GROUP} --query "kind"
# Should return: "functionapp,linux" or similar
```

3. Verify permissions:
```bash
az role assignment list --assignee $(az ad signed-in-user show --query objectId -o tsv) --query "[].roleDefinitionName"
# Should include Reader or higher
```

---

### Issue: "Device dropdowns are empty"

**Symptoms:**
- FunctionApp selected and auto-populated correctly
- But device dropdowns show no devices

**Causes:**
1. No devices in Microsoft Defender
2. Function App not querying correct tenant
3. API authentication issues with Microsoft Graph
4. Incorrect TenantId

**Solutions:**
1. Verify devices exist in Microsoft Defender:
   - Navigate to Microsoft 365 Defender portal
   - Check Devices inventory

2. Test API call manually:
```bash
curl "https://${FUNCTION_APP_NAME}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"
```

3. Check Function App environment variables:
```bash
az functionapp config appsettings list --name ${FUNCTION_APP_NAME} --resource-group ${RESOURCE_GROUP}
```

Should include:
- `TENANT_ID`
- `CLIENT_ID`
- `CLIENT_SECRET` or managed identity configuration

---

### Issue: "ARM actions fail or hang"

**Symptoms:**
- Clicking action button shows loading spinner
- Action never completes
- No success/error message

**Causes:**
1. Incorrect ARM action paths
2. Missing api-version
3. Parameter substitution failing
4. Function App invocation failing

**Solutions:**
1. Verify workbook configuration:
```bash
python3 scripts/verify_workbook_config.py
```

2. Check ARM action in browser console (F12):
   - Look for POST request to `/subscriptions/...`
   - Check request body has all required parameters
   - Verify response status code

3. Test Function App invocation manually:
```bash
az rest --method post \
  --uri "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${FUNCTION_APP_NAME}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01" \
  --body '{"action":"Get Devices","tenantId":"'${TENANT_ID}'"}'
```

---

## 📋 Pre-Deployment Checklist

Before deploying the workbook, verify:

### Function App
- [ ] Function App deployed and running
- [ ] DefenderC2Dispatcher function exists
- [ ] CORS configured with `https://portal.azure.com`
- [ ] Authentication set to Anonymous or allows anonymous
- [ ] Environment variables configured (TENANT_ID, CLIENT_ID, etc.)
- [ ] Managed identity configured (if using managed identity auth)

### Azure Permissions
- [ ] User has Reader permissions on Function App
- [ ] User has permissions to query Azure Resource Graph
- [ ] User has permissions to invoke Function App

### Workbook Configuration
- [ ] Using latest workbook from main branch
- [ ] Verification script passes all checks
- [ ] JSON is valid

### Testing
- [ ] Can select Function App from dropdown
- [ ] Auto-populated parameters fill correctly
- [ ] Device dropdowns populate
- [ ] ARM actions execute successfully

---

## 🔧 Advanced Diagnostics

### Enable Detailed Logging in Function App

```bash
# Enable Application Insights
az functionapp config appsettings set \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="${INSTRUMENTATION_KEY}"

# Set logging level
az functionapp config appsettings set \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --settings AzureFunctionsJobHost__logging__logLevel__default="Information"
```

### View Live Logs

```bash
# Stream logs
az functionapp log tail \
  --name ${FUNCTION_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

### Test with curl (detailed)

```bash
# Test with verbose output
curl -v \
  -H "Content-Type: application/json" \
  "https://${FUNCTION_APP_NAME}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"

# Expected response:
# < HTTP/2 200
# < content-type: application/json
# < access-control-allow-origin: https://portal.azure.com
# {
#   "devices": [...]
# }
```

---

## 📚 Additional Resources

### Official Documentation
- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Functions CORS](https://docs.microsoft.com/azure/azure-functions/functions-how-to-use-azure-function-app-settings#cors)
- [Azure Resource Graph](https://docs.microsoft.com/azure/governance/resource-graph/)

### DefenderC2 Documentation
- [ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md) - Technical details
- [ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md](ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md) - Previous fixes
- [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md) - Best practices
- [PROJECT_COMPLETE.md](PROJECT_COMPLETE.md) - Complete project summary

### Verification Tools
- `scripts/verify_workbook_config.py` - Automated configuration validation
- Azure Portal browser console (F12) - Real-time error inspection

---

## 🆘 Still Having Issues?

If you've followed all steps above and issues persist:

1. **Collect diagnostic information:**
   - Workbook verification output
   - Browser console errors (F12)
   - Function App logs
   - Network tab showing failed requests

2. **Create a GitHub issue with:**
   - Detailed symptom description
   - Steps to reproduce
   - Diagnostic information collected
   - Screenshots of errors

3. **Temporary workarounds:**
   - Test with simple curl commands
   - Verify Function App works standalone
   - Use Azure CLI to perform actions manually

---

**Last Updated:** October 13, 2025  
**Applies to:** DefenderC2-Workbook.json v2.0 and later  
**Status:** Configuration verified correct, issues are environmental
