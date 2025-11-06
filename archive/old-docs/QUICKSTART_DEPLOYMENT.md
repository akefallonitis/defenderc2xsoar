# 🚀 DefenderC2 Complete Workbook - Quick Deployment Guide

## ⚡ 5-Minute Setup

### Prerequisites
- Azure subscription with Workbooks access
- DefenderC2 function apps deployed (see main README if not)
- Contributor role on resource group

### Step 1: Get the Workbook

**Download the workbook JSON:**
```
Location: workbook/DefenderC2-Complete.json
```

### Step 2: Deploy to Azure

**Option A: Azure Portal (Recommended)**

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Workbooks** (search in top bar)
3. Click **+ New**
4. Click **Advanced Editor** (</> icon in top toolbar)
5. Delete existing content
6. Paste contents from `workbook/DefenderC2-Complete.json`
7. Click **Apply**
8. Update `fallbackResourceIds` at bottom:
   ```json
   "fallbackResourceIds": [
     "/subscriptions/YOUR-SUBSCRIPTION-ID/resourcegroups/YOUR-RESOURCE-GROUP"
   ]
   ```
9. Click **Done Editing**
10. Click **Save** icon
11. Enter:
    - Title: `DefenderC2 Complete`
    - Subscription: Your subscription
    - Resource Group: Your RG
    - Location: Same as function app
12. Click **Save**

**Option B: PowerShell**

```powershell
# Deploy using provided script
cd deployment
.\deploy-workbook.ps1 `
  -ResourceGroupName "your-rg-name" `
  -WorkbookName "DefenderC2-Complete" `
  -Location "eastus" `
  -WorkbookPath "../workbook/DefenderC2-Complete.json"
```

**Option C: Azure CLI**

```bash
# Set variables
RG="your-rg-name"
LOCATION="eastus"
WORKBOOK_NAME="DefenderC2-Complete"

# Deploy
az deployment group create \
  --resource-group $RG \
  --template-file deployment/workbook-deploy.json \
  --parameters \
    workbookDisplayName="$WORKBOOK_NAME" \
    location="$LOCATION"
```

### Step 3: Configure Workbook

1. **Open Workbook** in Azure Portal
2. **Select Function App** from dropdown (top parameter)
   - Wait 2-3 seconds for auto-population
3. **Verify Tenant ID** populated automatically
4. **Set Auto-Refresh** (optional, default 30s is good)
5. **Test Navigation:**
   - Click **📊 Dashboard** - should see device metrics
   - Click **🖥️ Device Management** - should see device list
   - Click other tabs to verify

### Step 4: Verify Functionality

**Test Device Listing (CustomEndpoint):**
```
1. Go to: 🖥️ Device Management
2. Wait for device inventory to load
3. Should see all devices with health/risk
4. Click ✅ Select on a device
5. DeviceList parameter should populate
```

**Test ARM Action:**
```
1. Keep device selected
2. Scroll to "Execute ARM Actions"
3. Click: 🔍 Run Antivirus Scan
4. Azure confirmation dialog appears
5. Click "Run" to test (safe operation)
6. Check response for success
```

### Step 5: Customize (Optional)

**Update Default Tenant:**
```json
// In workbook JSON, find TenantId parameter:
{
  "name": "TenantId",
  "value": "YOUR-TENANT-ID-HERE"  // ← Update this
}
```

**Update Default Auto-Refresh:**
```json
{
  "name": "AutoRefresh",
  "value": "60000"  // ← 60 seconds (60000 ms)
}
```

**Add Custom Branding:**
```json
// In main header section, update markdown:
{
  "json": "# 🛡️ YOUR COMPANY - DefenderC2 Console\n\n..."
}
```

---

## 🎯 Module-Specific Setup

### Live Response Console

**Enable Live Response Library:**

1. Ensure function app has Azure Storage configured
2. Create `library` container:
   ```powershell
   # Get storage account from function app
   $storageAccount = az functionapp config appsettings list \
     --name YOUR-FUNCTION-APP \
     --resource-group YOUR-RG \
     --query "[?name=='AzureWebJobsStorage'].value" -o tsv
   
   # Extract account name
   $accountName = ($storageAccount -split 'AccountName=')[1] -split ';' | Select-Object -First 1
   
   # Create container
   az storage container create \
     --name library \
     --account-name $accountName
   ```

### Advanced Hunting

**Test KQL Access:**

1. Go to **🔍 Advanced Hunting** tab
2. Use default query (already populated)
3. Click **🔍 Execute Advanced Hunting Query**
4. Confirm in Azure dialog
5. Check response for results

**If Errors:**
- Verify `AdvancedQuery.Read.All` permission granted
- Check admin consent applied
- Test query in Defender portal first

### Threat Intelligence

**Verify TI Permissions:**

1. Go to **🛡️ Threat Intelligence** tab
2. Review existing indicators (should auto-load)
3. If empty but you have indicators:
   - Check `Ti.ReadWrite.All` permission
   - Verify admin consent

**Test Adding Indicator:**

```
1. Select indicator type: 📄 File Hash
2. Enter test hash: 0000000000000000000000000000000000000000000000000000000000000000
3. Title: "Test Indicator - Safe to Delete"
4. Severity: Informational
5. Action: Alert
6. Click: ➕ Add File Indicator
7. Confirm and execute
8. Remove afterwards using Defender portal
```

---

## 🔧 Troubleshooting

### "Function App not found"
**Fix:** Verify you have Reader role on subscription
```powershell
az role assignment create \
  --assignee YOUR-EMAIL \
  --role Reader \
  --scope /subscriptions/YOUR-SUBSCRIPTION-ID
```

### "Missing required parameters: tenantId"
**Fix:** Select Function App first, wait 3 seconds, then proceed

### "ARM action fails with 403"
**Fix:** Add invoke permission
```powershell
# Get your object ID
$objectId = az ad user show --id YOUR-EMAIL --query objectId -o tsv

# Create custom role (if needed)
az role assignment create \
  --assignee $objectId \
  --role Contributor \
  --scope /subscriptions/YOUR-SUB/resourceGroups/YOUR-RG/providers/Microsoft.Web/sites/YOUR-FUNCTION-APP
```

### "CustomEndpoint returns no data"
**Fix:** Check function app is running
```powershell
# Start function app if stopped
az functionapp start \
  --name YOUR-FUNCTION-APP \
  --resource-group YOUR-RG

# Verify app settings
az functionapp config appsettings list \
  --name YOUR-FUNCTION-APP \
  --resource-group YOUR-RG \
  --query "[?name=='APPID' || name=='SECRETID']"
```

### "Auto-refresh not working"
**Fix:** Set AutoRefresh parameter to non-zero value (e.g., 30000 for 30 seconds)

---

## 📋 Post-Deployment Checklist

- [ ] Workbook opens without errors
- [ ] Function App parameter populates
- [ ] Tenant ID auto-populates
- [ ] Dashboard shows device tiles
- [ ] Device Management shows device inventory
- [ ] ARM action (Run Scan) executes successfully
- [ ] Live Response shows device list
- [ ] File Library shows library files (or empty if none)
- [ ] Advanced Hunting executes test query
- [ ] Threat Intelligence shows indicators
- [ ] Incidents shows incidents (or empty)
- [ ] Custom Detections shows rules
- [ ] Auto-refresh works (check timestamps)

---

## 🎓 Training & Onboarding

### Day 1: Device Management
```
Morning:
- Introduction to workbook interface
- Device inventory navigation
- Parameter selection
- Conflict detection

Afternoon:
- Execute first ARM action (Scan)
- Monitor action history
- Practice device selection
- Review auto-refresh
```

### Day 2: Threat Hunting
```
Morning:
- Advanced Hunting module
- KQL query basics
- Sample query walkthrough
- Execute hunts

Afternoon:
- Threat Intelligence module
- Add/remove indicators
- Severity and action types
- IOC lifecycle
```

### Day 3: Incident Response
```
Morning:
- Incident Management module
- Filtering and triage
- Live Response console
- Session management

Afternoon:
- File Library operations
- Custom Detections
- End-to-end IR scenario
- Best practices
```

---

## 🔗 Quick Reference Links

**Documentation:**
- Full Documentation: `DEFENDERC2_COMPLETE_WORKBOOK.md`
- Function App Code: `functions/`
- Deployment Scripts: `deployment/`

**Azure Portal:**
- [Workbooks](https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/workbooks)
- [Function Apps](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2Fsites/kind/functionapp)
- [Azure AD App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)

**Microsoft Docs:**
- [Defender XDR API](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Advanced Hunting](https://docs.microsoft.com/en-us/microsoft-365/security/defender/advanced-hunting-overview)
- [Live Response](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/live-response)

---

## 📞 Support

**Issues:** https://github.com/akefallonitis/defenderc2xsoar/issues  
**Questions:** https://github.com/akefallonitis/defenderc2xsoar/discussions

---

**Deployment Time:** ~5 minutes  
**Testing Time:** ~10 minutes  
**Full Onboarding:** ~3 days  

**Good luck! 🚀**
