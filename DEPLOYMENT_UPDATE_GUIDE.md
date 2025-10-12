# Deployment Update Guide - Fix CustomEndpoint Queries

This guide explains how to deploy the fixed workbooks to resolve the "query failed" and "api-version" errors.

## What Was Fixed

The CustomEndpoint queries were updated to use the correct parameter passing method:
- Changed from `urlParams` array (incorrect) to `body` JSON (correct)
- Fixed 21 queries in DefenderC2-Workbook.json
- Fixed 1 query in FileOperations.workbook

## Prerequisites

- Azure subscription with existing DefenderC2 deployment
- Appropriate permissions to edit Azure Workbooks
- Function App already deployed and configured

## Option 1: Update via Azure Portal (Recommended)

### Step 1: Update DefenderC2 Main Workbook

1. **Navigate to the Workbook**
   - Open Azure Portal: https://portal.azure.com
   - Go to **Monitor** → **Workbooks**
   - Find and open **"DefenderC2 Command & Control Console"** workbook

2. **Enter Edit Mode**
   - Click **Edit** button in the toolbar
   - Click **Advanced Editor** (</> icon) in the toolbar

3. **Replace Workbook Content**
   - The Advanced Editor shows the current JSON
   - **Select All** (Ctrl+A or Cmd+A) and **Delete**
   - Copy the entire content from `workbook/DefenderC2-Workbook.json`
   - **Paste** into the Advanced Editor

4. **Apply and Save**
   - Click **Apply** button
   - Review the workbook preview (should show no errors)
   - Click **Save** button
   - Add a comment like "Fix CustomEndpoint query parameters"
   - Click **Save** to confirm

5. **Verify**
   - Click **Done Editing**
   - Verify the "Available Devices" dropdown loads successfully
   - Navigate through tabs and verify no error messages

### Step 2: Update FileOperations Workbook

1. **Navigate to the Workbook**
   - In Azure Portal, go to **Monitor** → **Workbooks**
   - Find and open **"File Operations"** workbook

2. **Repeat Steps 2-5** from above
   - Use content from `workbook/FileOperations.workbook`

## Option 2: Deploy via ARM Template

If you're deploying a new instance or want to redeploy:

### Using Azure CLI

```bash
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Checkout the fixed branch
git checkout <branch-name>

# Deploy using Azure CLI
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file deployment/azuredeploy.json \
  --parameters deployment/azuredeploy.parameters.json
```

### Using Azure Portal

1. **Upload Template**
   - Go to Azure Portal → **Create a resource**
   - Search for "Template deployment (deploy using custom templates)"
   - Click **Build your own template in the editor**
   - Copy content from `deployment/azuredeploy.json`
   - Click **Save**

2. **Configure Parameters**
   - Fill in required parameters:
     - Subscription
     - Resource Group
     - Function App Name
     - Tenant ID
     - App ID (Service Principal)
     - Secret ID (Service Principal Secret)
   - Click **Review + create**
   - Click **Create**

## Verification Steps

After deploying the updates:

### 1. Check Parameter Population

1. Open the DefenderC2 workbook
2. Verify parameters at the top:
   - ✅ **FunctionApp**: Should be selectable from dropdown
   - ✅ **Subscription**: Should auto-populate after selecting FunctionApp
   - ✅ **Resource Group**: Should auto-populate
   - ✅ **FunctionAppName**: Should auto-populate
   - ✅ **TenantId**: Should auto-populate
   - ✅ **Available Devices**: Should load device list (not "<query failed>")

### 2. Check Queries Load Successfully

Navigate through each tab and verify data loads:

| Tab | What to Check |
|-----|---------------|
| **Device Manager** | Device list table populates with devices |
| **Threat Intel** | Indicators table shows threat indicators |
| **Action Manager** | Actions table shows machine actions |
| **Hunt Manager** | Hunt results load when executed |
| **Incident Manager** | Incidents table loads (no "api-version" error) |
| **Detection Manager** | Detection rules table populates |
| **Interactive Console** | Commands can be executed |

### 3. Check Actions Work

1. Select one or more devices from "Available Devices"
2. Try an action:
   - Click **🚨 Isolate Devices** button
   - Verify confirmation dialog appears
   - Verify action executes successfully
   - Check Action Manager tab for action status

### 4. Run Verification Script (Optional)

If you have the repository cloned locally:

```bash
cd defenderc2xsoar/deployment
python3 verify_workbook_deployment.py
```

Expected output:
```
✅ ALL VERIFICATION CHECKS PASSED ✅
```

## Troubleshooting

### Issue: "Available Devices" still shows "<query failed>"

**Possible Causes:**
1. Workbook not saved properly
2. Function App not deployed or misconfigured
3. Service Principal permissions missing

**Solutions:**
1. Re-apply the workbook update following Step 1 above
2. Verify Function App is running: Azure Portal → Function App → Check status
3. Check Function App logs: Function App → Monitor → Logs
4. Verify Service Principal has Microsoft Graph API permissions

### Issue: Still seeing "api-version" errors

**Possible Causes:**
1. Old workbook version still loaded in browser cache
2. Workbook update didn't apply correctly

**Solutions:**
1. Clear browser cache and reload the workbook
2. Re-apply the workbook update
3. Check that you copied the entire workbook JSON content

### Issue: Parameters not populating

**Possible Causes:**
1. Function App resource not found
2. Resource Graph query permissions missing
3. Subscription not selected

**Solutions:**
1. Verify you're in the correct Azure subscription
2. Select a Function App from the dropdown
3. Verify your account has Reader access to the Function App resource
4. Try refreshing the workbook

### Issue: Actions fail to execute

**Possible Causes:**
1. Service Principal not configured
2. Function App environment variables not set
3. Wrong API permissions

**Solutions:**
1. Verify environment variables in Function App:
   - Go to Function App → Configuration → Application settings
   - Check `APPID` and `SECRETID` are set
2. Verify Service Principal permissions:
   - Microsoft Defender ATP: SecurityActions.ReadWrite.All
   - Microsoft Graph: ThreatHunting.Read.All
3. Check Function App logs for detailed error messages

## Getting Help

If you encounter issues after following this guide:

1. **Check the logs**:
   - Function App logs: Function App → Monitor → Logs
   - Workbook errors: Browser Developer Console (F12)

2. **Review documentation**:
   - `CUSTOMENDPOINT_FIX_SUMMARY.md` - Technical details about the fix
   - `deployment/CUSTOMENDPOINT_GUIDE.md` - CustomEndpoint implementation guide
   - `README.md` - Full project documentation

3. **GitHub Issues**:
   - Open an issue at: https://github.com/akefallonitis/defenderc2xsoar/issues
   - Include:
     - Error messages
     - Screenshots
     - Function App logs
     - Browser console errors

## What's Next

After successful deployment:

1. **Test All Features**: Go through each tab and test functionality
2. **Review Parameters**: Verify all auto-discovered parameters are correct
3. **Configure Function Keys** (if needed): Add FunctionKey parameter for authenticated access
4. **Set Up Auto-Refresh** (optional): Configure auto-refresh for specific queries
5. **Customize**: Adjust queries and visualizations to your needs

## Summary

✅ **Step 1**: Update DefenderC2-Workbook.json via Azure Portal  
✅ **Step 2**: Update FileOperations.workbook via Azure Portal  
✅ **Step 3**: Verify parameters populate correctly  
✅ **Step 4**: Verify queries load data successfully  
✅ **Step 5**: Test actions execute successfully  

**Expected Result**: No more "query failed" or "api-version" errors!
