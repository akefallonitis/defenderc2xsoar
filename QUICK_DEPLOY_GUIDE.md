# Quick Deploy Guide - DefenderC2xSOAR

## ⚡ 5-Minute Deployment

### Step 1: Create App Registration (2 minutes)

1. Azure Portal → Entra ID → App Registrations → New
2. Name: `MDE-Automator`
3. Account type: **Multitenant**
4. Create **Client Secret** (save it!)
5. Add API Permissions:
   - **WindowsDefenderATP API:**
     - `AdvancedQuery.Read.All`
     - `Machine.ReadWrite.All`
     - `Ti.ReadWrite.All`
     - `Machine.CollectForensics`
     - `Machine.Isolate`
     - `Machine.Scan`
     - etc.
   - **Microsoft Graph API:**
     - `SecurityIncident.ReadWrite.All`
6. **Grant admin consent** ✅

### Step 2: One-Click Deploy (2 minutes)

Click here 👇

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Fill in:**
- Function App Name: `mde-automator-prod` (must be globally unique)
- SPN ID: Your app client ID from Step 1
- SPN Secret: Your client secret from Step 1
- Project Tag: `DefenderC2`
- Created By: Your email
- Delete At: `Never` or date like `2026-12-31`

Click **Review + Create** → **Create**

### Step 3: Wait (1 minute)

Deployment takes 2-3 minutes. Azure will deploy:
- ✅ Function App
- ✅ Storage Account
- ✅ 5 Functions (auto-deployed!)
- ✅ Workbook

### Step 4: Access Workbook (1 minute)

1. Azure Portal → Monitor → Workbooks
2. Find "MDE Automator Workbook"
3. Configure:
   - Function App URL: `https://your-app-name.azurewebsites.net`
   - Target Tenant ID: Your tenant ID
   - SPN ID: Your app client ID

### Step 5: Test! ✅

In workbook, try:
1. Go to "MDEAutomator" tab
2. Select action: "Isolate Device"
3. Enter device IDs
4. Click "Execute"

## 🎉 Done!

You now have:
- ✅ Working function app with all 5 functions
- ✅ Workbook for managing MDE
- ✅ Auto-updating deployment (via GitHub Actions)

## 🔍 Verify Deployment

### Check Functions Deployed

```bash
# Azure CLI
az functionapp function list \
  --resource-group your-rg \
  --name your-app \
  --query "[].name" -o table
```

**Expected output:**
```
MDECDManager
MDEDispatcher
MDEHuntManager
MDEIncidentManager
MDETIManager
```

### Check Function App is Running

```bash
# Test endpoint
curl https://your-app-name.azurewebsites.net
```

Should return function app info page.

### Check Workbook

Azure Portal → Monitor → Workbooks → "MDE Automator Workbook"

## 🆘 Troubleshooting

### Functions Not Appearing?

**Wait 2-3 minutes** - Functions deploy from package after infrastructure.

Still not there?
```bash
# Check logs
az webapp log tail -g your-rg -n your-app
```

### Can't Find Workbook?

1. Check Azure Monitor → Workbooks
2. Look in resource group's workbooks
3. Search for "MDE Automator"

### 401 Unauthorized Error?

1. Verify app registration permissions
2. Check admin consent was granted
3. Verify client secret hasn't expired
4. Check APPID and SECRETID in function app settings

### Package Download Failed?

Verify package is accessible:
```bash
curl -I https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
```

Should return `HTTP/1.1 200 OK`

## 📚 More Help

- **Full Guide:** [COMPLETE_DEPLOYMENT.md](COMPLETE_DEPLOYMENT.md)
- **Troubleshooting:** [COMPLETE_DEPLOYMENT.md#troubleshooting](COMPLETE_DEPLOYMENT.md#troubleshooting)
- **API Reference:** [FUNCTIONS_REFERENCE.md](FUNCTIONS_REFERENCE.md)

## 🔄 Update Functions

After making changes to functions:

1. Push to GitHub
2. GitHub Actions auto-creates new package
3. Restart function app to pick up changes:
   ```bash
   az functionapp restart -g your-rg -n your-app
   ```

Or manually:
```bash
cd deployment
./create-package.ps1
# Commit and push
git add deployment/function-package.zip
git commit -m "Update functions"
git push
```

## 💡 Pro Tips

1. **Use Tags:** Helps track resources and costs
2. **Enable Monitoring:** Application Insights is your friend
3. **Rotate Secrets:** Update client secret every 6-12 months
4. **Test First:** Use test tenant before production
5. **Document:** Keep track of your app registration IDs

## 🎯 Quick Links

- [Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json) - One-click deployment
- [GitHub Repository](https://github.com/akefallonitis/defenderc2xsoar) - Source code
- [Report Issues](https://github.com/akefallonitis/defenderc2xsoar/issues) - Bug reports

---

**Need help?** Open an issue on GitHub with:
- Error messages
- Deployment method used
- Function app logs
- ARM template output
