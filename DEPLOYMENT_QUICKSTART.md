# DefenderC2 Deployment Quick Start Guide

## 🚀 One-Command Deployment (Recommended)

Deploy everything (Function App + Workbooks) in one command:

```powershell
cd deployment

.\deploy-all.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -FunctionAppName "defc2" `
    -AppId "12345678-1234-1234-1234-123456789012" `
    -ClientSecret "your-client-secret-here" `
    -WorkspaceResourceId "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}" `
    -ProjectTag "DefenderC2" `
    -CreatedByTag "john.doe@example.com" `
    -DeleteAtTag "Never"
```

**That's it!** Everything is deployed and configured automatically.

## 📋 Prerequisites

Before running the deployment:

1. **Azure CLI** installed and logged in:
   ```powershell
   az login
   ```

2. **Azure AD App Registration** with:
   - Multi-tenant configuration
   - Microsoft Defender API permissions
   - Admin consent granted
   - Client secret created

3. **Log Analytics Workspace** created

4. **Resource Group** exists:
   ```powershell
   az group create --name rg-defenderc2 --location eastus
   ```

## 🎯 What Gets Deployed

### Function App Infrastructure
- ✅ Azure Function App (PowerShell runtime)
- ✅ Storage Account
- ✅ App Service Plan (Consumption)
- ✅ Managed Identity (optional)
- ✅ Environment variables (APPID, SECRETID)

### Azure Monitor Workbooks
- ✅ DefenderC2 Command & Control Console
- ✅ DefenderC2 File Operations
- ✅ Function App Name parameter **automatically set**
- ✅ All parameters correctly configured

## 📝 Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `ResourceGroupName` | Azure resource group | `rg-defenderc2` |
| `FunctionAppName` | Unique function app name | `defc2` |
| `AppId` | App registration client ID | `12345678-1234-...` |
| `ClientSecret` | App registration secret | `your-secret` |
| `WorkspaceResourceId` | Log Analytics workspace ID | `/subscriptions/.../workspaces/...` |
| `ProjectTag` | Project tag (Azure Policy) | `DefenderC2` |
| `CreatedByTag` | Creator tag (Azure Policy) | `john.doe@example.com` |
| `DeleteAtTag` | Expiration tag (Azure Policy) | `Never` or `2025-12-31` |

### How to Get Workspace Resource ID

**Option 1: Azure Portal**
1. Go to Log Analytics workspace
2. Click **Properties**
3. Copy **Resource ID**

**Option 2: Azure CLI**
```powershell
az monitor log-analytics workspace show `
    --resource-group rg-monitoring `
    --workspace-name myworkspace `
    --query id --output tsv
```

## ✅ Post-Deployment Verification

### 1. Check Function App

```powershell
az functionapp show -n defc2 -g rg-defenderc2 --query state
# Should return: "Running"
```

### 2. Check Workbooks

1. Open **Azure Portal** → **Monitor** → **Workbooks**
2. Find `DefenderC2 Command & Control Console`
3. Click to open

### 3. Configure Workbook Parameters

When you open the workbook:
1. **Function App Name**: Should already be set to your function app ✅
2. **Subscription**: Select your subscription
3. **Workspace**: Select your Log Analytics workspace
4. **Tenant ID**: Auto-populated ✅

### 4. Test Functionality

1. Go to **Defender C2** tab
2. Click **Get Devices** button
3. Should see device list (if devices exist)
4. No error messages ✅

## 🔧 Alternative Deployment Methods

### Deploy Only Function App

```powershell
.\deploy-complete.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -FunctionAppName "defc2" `
    -AppId "..." `
    -ClientSecret "..." `
    -ProjectTag "DefenderC2" `
    -CreatedByTag "john.doe@example.com" `
    -DeleteAtTag "Never"
```

### Deploy Only Workbooks

If Function App already exists:

```powershell
.\deploy-workbook.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -WorkspaceResourceId "/subscriptions/.../workspaces/..." `
    -FunctionAppName "defc2" `
    -DeployMainWorkbook `
    -DeployFileOpsWorkbook
```

## 🐛 Troubleshooting

### Issue: "Not logged in to Azure"
```powershell
az login
```

### Issue: "Function app name already in use"
Function app names must be globally unique. Try a different name like `defc2-prod` or `mycompany-defc2`.

### Issue: "Workbook shows errors"
1. Check Function App Name parameter matches your function app
2. Verify function app is running: `az functionapp show -n {name} -g {rg}`
3. Check environment variables: `az functionapp config appsettings list -n {name} -g {rg}`

### Issue: "No data in workbook"
This is normal if:
- No devices registered in Defender
- No incidents created
- No threat indicators configured

Test with "Get Devices" - if it returns empty array `[]`, it's working correctly.

## 📚 Detailed Documentation

For more information, see:

- **[deployment/README.md](deployment/README.md)** - Complete deployment options
- **[deployment/WORKBOOK_DEPLOYMENT.md](deployment/WORKBOOK_DEPLOYMENT.md)** - Detailed workbook guide
- **[deployment/WORKBOOK_PARAMETERS_GUIDE.md](deployment/WORKBOOK_PARAMETERS_GUIDE.md)** - Parameter reference
- **[deployment/DEPLOYMENT_FLOW.md](deployment/DEPLOYMENT_FLOW.md)** - Visual diagrams
- **[DEPLOYMENT_FIX_SUMMARY.md](DEPLOYMENT_FIX_SUMMARY.md)** - What was fixed

## 🎉 Success!

After successful deployment:

✅ Function App running with correct environment variables  
✅ Workbooks deployed with Function App Name parameter set  
✅ All queries configured correctly  
✅ Ready to use immediately

**Next Steps:**
1. Pin workbook to your dashboard
2. Explore different tabs (Device Actions, Threat Intel, Incidents, etc.)
3. Start automating Defender for Endpoint operations!

## 💡 Tips

- **Function App Name**: Choose something memorable and short (e.g., `defc2`, `defender`, `mde-auto`)
- **Tags**: Use meaningful values for tags to help with Azure governance
- **Workspace**: Use the same workspace where Defender data is sent
- **Testing**: Test with a single device action first before rolling out widely

## 🆘 Need Help?

1. Check [Troubleshooting](#troubleshooting) section above
2. Review detailed guides in `deployment/` directory
3. Check [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
4. Open a new issue with:
   - Command you ran
   - Error messages
   - Screenshot of the issue

---

**Happy Deploying! 🚀**

*Last Updated: 2024-01-08*
