# DefenderXDR v3.0.0 - Deployment Guide

## 🚀 Quick Deploy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Deployment Time:** ~5 minutes  
**Prerequisites:** App Registration with required permissions (see [PERMISSIONS.md](PERMISSIONS.md))

---

## 📋 What Gets Deployed

### **Azure Resources (All Auto-Created)**

1. **Function App** (Consumption or Premium Plan)
   - 13 Azure Functions deployed
   - System-assigned Managed Identity enabled
   - Application Insights integrated

2. **Storage Account**
   - **Queue Storage** - Bulk operation batching (`xdr-{tenantId}-bulk-ops`)
   - **Table Storage** - Operation status tracking (`XDROperationStatus`)
   - **Blob Storage** - Function deployment package

3. **Application Insights**
   - Real-time monitoring
   - Performance metrics
   - Distributed tracing

4. **RBAC Assignments**
   - Function App Identity → Storage Queue Data Contributor
   - Function App Identity → Storage Table Data Contributor

### **Functions Deployed (13 Total)**

**Tier 1 - Gateway:**
- `DefenderXDRGateway` - Optional single entry point with bulk ops

**Tier 2 - Orchestrator & Managers:**
- `DefenderXDROrchestrator` - Central routing hub
- `DefenderXDRHuntManager` - Advanced Hunting (KQL)
- `DefenderXDRIncidentManager` - Incident lifecycle
- `DefenderXDRThreatIntelManager` - Threat intelligence
- `DefenderXDRCustomDetectionManager` - Custom rules

**Tier 3 - Workers (Security Service Modules):**
- `DefenderXDRMDEWorker` - Microsoft Defender for Endpoint (52 actions)
- `DefenderXDRMDOWorker` - Microsoft Defender for Office 365 (25 actions)
- `DefenderXDRMCASWorker` - Microsoft Cloud App Security (23 actions)
- `DefenderXDREntraIDWorker` - EntraID/Azure AD Identity (34 actions)
- `DefenderXDRIntuneWorker` - Microsoft Intune (33 actions)
- `DefenderXDRAzureWorker` - Azure Security (52 actions)

**Total**: 8 Azure Functions, 219 remediation actions, 5 core modules

---

## 🔧 Pre-Deployment Requirements

### **1. App Registration Setup**

Create multi-tenant App Registration with required permissions:

**Microsoft Graph API (Application Permissions):**
- `User.ReadWrite.All`
- `Directory.ReadWrite.All`
- `IdentityRiskyUser.ReadWrite.All` (requires Entra ID P2)
- `Policy.ReadWrite.ConditionalAccess` (requires Entra ID P1+)
- `DeviceManagementManagedDevices.ReadWrite.All`
- `DeviceManagementConfiguration.ReadWrite.All`
- `SecurityAnalyzedMessage.ReadWrite.All`
- `ThreatSubmission.ReadWrite.All`
- `SecurityEvents.ReadWrite.All`
- `SecurityActions.ReadWrite.All`

**Microsoft Defender API (Application Permissions):**
- `Machine.Isolate`, `Machine.RestrictExecution`, `Machine.Scan`
- `Machine.CollectForensics`, `Machine.StopAndQuarantine`
- `Machine.LiveResponse`, `Machine.Read.All`
- `Alert.ReadWrite.All`, `Incident.ReadWrite.All`
- `AdvancedQuery.Read.All`, `Ti.ReadWrite.All`

**Azure RBAC Roles (Assign to App's Service Principal):**
- `Network Contributor` (for NSG rules)
- `Virtual Machine Contributor` (for VM operations)
- `Storage Account Contributor` (for storage security)
- `Security Admin` (for security settings)
- `Reader` (for resource inventory)

**Grant Admin Consent:**
```powershell
# In Azure Portal
Azure AD → App Registrations → [Your App] → API Permissions → Grant admin consent
```

### **2. Required Information**

Before clicking "Deploy to Azure", gather:

- [ ] **Function App Name** (must be globally unique, e.g., `defenderxdr-prod-001`)
- [ ] **App Registration Client ID** (from App Registration Overview)
- [ ] **App Registration Client Secret** (create in Certificates & Secrets)
- [ ] **Azure Location** (e.g., `eastus`, `westeurope`)
- [ ] **Tags** (Project, CreatedBy, DeleteAt)

---

## 📦 Deployment Steps

### **Option 1: One-Click Deployment (Recommended)**

1. Click the "Deploy to Azure" button above
2. Sign in to Azure Portal
3. Fill in the deployment form:
   - **Subscription**: Select your Azure subscription
   - **Resource Group**: Create new or use existing
   - **Function App Name**: Enter unique name (e.g., `defenderxdr-prod-001`)
   - **SPN ID**: Paste App Registration Client ID
   - **SPN Secret**: Paste App Registration Client Secret
   - **Location**: Select Azure region
   - **Project Tag**: Enter project name
   - **Created By Tag**: Enter your name/team
   - **Delete At Tag**: Enter date (e.g., `2026-12-31`) or `Never`
4. Check "I agree to the terms and conditions"
5. Click "Review + create"
6. Click "Create"
7. Wait ~5 minutes for deployment to complete

### **Option 2: Azure CLI Deployment**

```powershell
# Login to Azure
az login

# Set variables
$resourceGroup = "rg-defenderxdr-prod"
$location = "eastus"
$functionAppName = "defenderxdr-prod-001"
$appId = "YOUR_APP_REGISTRATION_CLIENT_ID"
$appSecret = "YOUR_APP_REGISTRATION_SECRET"

# Create resource group
az group create --name $resourceGroup --location $location

# Deploy ARM template
az deployment group create `
  --resource-group $resourceGroup `
  --template-file "deployment/azuredeploy.json" `
  --parameters `
    functionAppName=$functionAppName `
    spnId=$appId `
    spnSecret=$appSecret `
    projectTag="DefenderXDR" `
    createdByTag="YourName" `
    deleteAtTag="Never"
```

### **Option 3: PowerShell Deployment**

```powershell
# Connect to Azure
Connect-AzAccount

# Set variables
$resourceGroupName = "rg-defenderxdr-prod"
$location = "eastus"
$functionAppName = "defenderxdr-prod-001"
$appId = "YOUR_APP_REGISTRATION_CLIENT_ID"
$appSecret = ConvertTo-SecureString "YOUR_APP_REGISTRATION_SECRET" -AsPlainText -Force

# Create resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy ARM template
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile "deployment/azuredeploy.json" `
  -functionAppName $functionAppName `
  -spnId $appId `
  -spnSecret $appSecret `
  -projectTag "DefenderXDR" `
  -createdByTag "YourName" `
  -deleteAtTag "Never"
```

---

## ✅ Post-Deployment Verification

### **1. Verify Function App Deployment**

```powershell
# Get Function App details
$functionAppName = "defenderxdr-prod-001"
$resourceGroup = "rg-defenderxdr-prod"

# Check if Function App exists
az functionapp show --name $functionAppName --resource-group $resourceGroup

# List all functions
az functionapp function list --name $functionAppName --resource-group $resourceGroup
```

**Expected Output:** 13 functions listed

### **2. Test Gateway Health Endpoint**

```powershell
# Get function key
$functionKey = az functionapp function keys list `
  --name $functionAppName `
  --resource-group $resourceGroup `
  --function-name DefenderXDRGateway `
  --query "default" -o tsv

# Test health endpoint
$healthUrl = "https://$functionAppName.azurewebsites.net/api/DefenderXDRGateway/health?code=$functionKey"
Invoke-RestMethod -Uri $healthUrl -Method Get
```

**Expected Response:**
```json
{
  "status": "Healthy",
  "version": "3.0.0",
  "timestamp": "2025-11-11T10:00:00Z",
  "functions": {
    "gateway": "Available",
    "orchestrator": "Available",
    "workers": 7,
    "managers": 4
  },
  "infrastructure": {
    "storage": "Connected",
    "queueStorage": "Available",
    "tableStorage": "Available",
    "managedIdentity": "Enabled"
  }
}
```

### **3. Test MDE Worker**

```powershell
# Test getting devices from MDE
$tenantId = "YOUR_TENANT_ID"

$body = @{
    action = "GetDevices"
    tenantId = $tenantId
    top = 5
} | ConvertTo-Json

$workerUrl = "https://$functionAppName.azurewebsites.net/api/DefenderXDRMDEWorker?code=$functionKey"
Invoke-RestMethod -Uri $workerUrl -Method Post -Body $body -ContentType "application/json"
```

### **4. Test Orchestrator Routing**

```powershell
# Test Orchestrator routing to MDE Worker
$body = @{
    service = "MDE"
    action = "GetDevices"
    tenantId = $tenantId
    top = 5
} | ConvertTo-Json

$orchestratorUrl = "https://$functionAppName.azurewebsites.net/api/DefenderXDROrchestrator?code=$functionKey"
Invoke-RestMethod -Uri $orchestratorUrl -Method Post -Body $body -ContentType "application/json"
```

### **5. Verify Storage Account**

```powershell
# Get Storage Account details
$storageAccount = az storage account list `
  --resource-group $resourceGroup `
  --query "[?contains(name, 'storage')]" -o json | ConvertFrom-Json

# Check Queue Service
az storage queue list --account-name $storageAccount.name --auth-mode login

# Check Table Service  
az storage table list --account-name $storageAccount.name --auth-mode login
```

### **6. Verify Managed Identity RBAC**

```powershell
# Get Function App Managed Identity
$functionApp = az functionapp show --name $functionAppName --resource-group $resourceGroup | ConvertFrom-Json
$principalId = $functionApp.identity.principalId

# List role assignments
az role assignment list --assignee $principalId --all -o table
```

**Expected Roles:**
- Storage Queue Data Contributor (on Storage Account)
- Storage Table Data Contributor (on Storage Account)

---

## 🔧 Configuration

### **Environment Variables (Auto-Configured)**

The ARM template automatically configures these environment variables:

| Variable | Source | Description |
|----------|--------|-------------|
| `APPID` | Deployment parameter `spnId` | App Registration Client ID |
| `SECRETID` | Deployment parameter `spnSecret` | App Registration Client Secret (secure) |
| `AZURE_STORAGE_CONNECTION_STRING` | Auto-generated from Storage Account | Storage access (or use Managed Identity) |
| `WEBSITE_RUN_FROM_PACKAGE` | GitHub package URL | Deployment package location |
| `FUNCTIONS_WORKER_RUNTIME` | `powershell` | PowerShell runtime |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | Auto-generated | Application Insights key |

### **Manual Configuration (Optional)**

If you need to update settings after deployment:

```powershell
# Update App Registration credentials
az functionapp config appsettings set `
  --name $functionAppName `
  --resource-group $resourceGroup `
  --settings APPID="NEW_CLIENT_ID" SECRETID="NEW_CLIENT_SECRET"

# Restart Function App
az functionapp restart --name $functionAppName --resource-group $resourceGroup
```

---

## 🐛 Troubleshooting

### **Issue: Functions not loading**

**Solution:**
```powershell
# Check deployment status
az functionapp deployment list-publishing-profiles `
  --name $functionAppName --resource-group $resourceGroup

# Restart Function App
az functionapp restart --name $functionAppName --resource-group $resourceGroup

# Check logs
az functionapp log tail --name $functionAppName --resource-group $resourceGroup
```

### **Issue: Authentication errors**

**Solution:**
- Verify App Registration permissions are granted with admin consent
- Check APPID and SECRETID are correct in Function App settings
- Verify tenant ID in requests matches App Registration tenant

### **Issue: Storage access errors**

**Solution:**
- Verify Managed Identity is enabled
- Check RBAC role assignments (Storage Queue/Table Data Contributor)
- Test storage access:
  ```powershell
  # Get Function App identity
  $identity = az functionapp identity show --name $functionAppName --resource-group $resourceGroup
  
  # Assign roles if missing
  az role assignment create `
    --assignee $identity.principalId `
    --role "Storage Queue Data Contributor" `
    --scope "/subscriptions/{subscription}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{storage}"
  ```

### **Issue: Workbook ARM Actions failing**

**Solution:**
- Verify users have Contributor role on Function App resource
- Check function keys are not expired
- Ensure `authLevel: "function"` in all function.json files (automatically configured)

---

## 📊 Monitoring

### **Application Insights Queries**

```kusto
// Function execution count by function name
requests
| where timestamp > ago(1h)
| summarize count() by cloud_RoleName
| order by count_ desc

// Failed requests
requests
| where success == false
| where timestamp > ago(1h)
| project timestamp, cloud_RoleName, name, resultCode, customDimensions

// Performance metrics
requests
| where timestamp > ago(1h)
| summarize avg(duration), max(duration), min(duration) by cloud_RoleName
| order by avg_duration desc
```

### **Azure Monitor Alerts (Recommended)**

Create alerts for:
- Function execution failures (>5% error rate)
- High response times (>5 seconds)
- Storage queue depth (>1000 messages)
- Missing Managed Identity permissions

---

## 🔄 Updating Deployment

### **Update Functions**

```powershell
# 1. Create new deployment package
cd deployment
.\create-deployment-package.ps1

# 2. Upload to GitHub or Azure Blob Storage
# (ARM template will pick up from WEBSITE_RUN_FROM_PACKAGE)

# 3. Restart Function App
az functionapp restart --name $functionAppName --resource-group $resourceGroup
```

### **Update ARM Template**

```powershell
# Redeploy with updated template
az deployment group create `
  --resource-group $resourceGroup `
  --template-file "deployment/azuredeploy.json" `
  --parameters @deployment/azuredeploy.parameters.json `
  --mode Incremental  # Only updates changed resources
```

---

## 📚 Additional Resources

- [Architecture Documentation](V3_FINAL_ARCHITECTURE.md)
- [API Permissions Guide](PERMISSIONS.md)
- [Workbook Integration Guide](docs/WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

---

## 🆘 Support

For issues or questions:
1. Check [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
2. Review [V3_ARCHITECTURE_ANALYSIS.md](V3_ARCHITECTURE_ANALYSIS.md)
3. Open new issue with:
   - Deployment logs
   - Function error messages
   - Architecture version (v3.0.0)

---

**Last Updated:** November 11, 2025  
**Version:** 3.0.0 (Worker Architecture)
