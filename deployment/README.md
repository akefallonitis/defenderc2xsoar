# ARM Template Deployment Files

This folder contains Azure Resource Manager (ARM) template files for deploying the DefenderC2 Function App and Workbooks.

## Files

### Function App Deployment

#### azuredeploy.json
The main ARM template that defines the Azure resources to be deployed:
- Azure Function App (PowerShell runtime)
- App Service Plan (Consumption tier)
- Storage Account
- Managed Identity configuration
- CORS settings for Azure Portal
- Environment variables (APPID, SECRETID)

#### createUIDefinition.json
Provides a custom user interface in the Azure Portal when deploying via the "Deploy to Azure" button. This file:
- Validates input parameters
- Provides helpful tooltips and descriptions
- Ensures proper format for function app names and GUIDs

#### metadata.json
Contains metadata about the template for Azure Quickstart Templates gallery:
- Template description and summary
- Tags and keywords for discoverability
- Cost and complexity level indicators

#### azuredeploy.parameters.json
Sample parameters file for command-line deployments using Azure CLI or PowerShell. Contains placeholder values that should be replaced with your actual values.

### Workbook Deployment

#### workbook-deploy.json
ARM template for deploying DefenderC2 workbooks to Azure Monitor:
- Deploys workbook resources
- Configures workbook parameters
- Links to Log Analytics workspace

#### deploy-workbook.ps1
PowerShell script for automated workbook deployment:
- Loads workbook JSON content automatically
- Sets Function App Name parameter
- Deploys to Azure Monitor with proper configuration
- **Recommended method** for workbook deployment

#### WORKBOOK_DEPLOYMENT.md
Comprehensive guide for deploying workbooks:
- Automated deployment with PowerShell script
- Manual Azure Portal import
- Azure CLI deployment
- Troubleshooting and best practices

### Validation Scripts

#### test_azuredeploy.py
Automated validation script that verifies the ARM template is syntactically correct and has complete `listKeys` function calls. Run with `python3 test_azuredeploy.py`.

#### VALIDATION_REPORT.md
Detailed validation report documenting that lines 132 and 136 contain complete `listKeys` function calls and the template is ready for deployment.

## Deployment Options

> **⚠️ COMMON ISSUE:** The "Deploy to Azure" button may fail with a template download error. If this happens, use the **Manual Template Deployment** method described in the [Troubleshooting](#troubleshooting) section below - it's reliable and just as easy.

### Option 1: Azure Portal - Deploy Button
Click the "Deploy to Azure" button in the main README.md (may fail if template not on main branch - see troubleshooting)

### Option 2: Azure CLI
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file azuredeploy.json \
  --parameters functionAppName=<your-unique-name> \
               spnId=<your-app-id> \
               spnSecret=<your-client-secret> \
               projectTag=<project-name> \
               createdByTag=<your-email> \
               deleteAtTag=<date-or-Never>
```

### Option 3: PowerShell
```powershell
$spnSecret = ConvertTo-SecureString "<your-client-secret>" -AsPlainText -Force

New-AzResourceGroupDeployment `
  -ResourceGroupName <your-resource-group> `
  -TemplateFile azuredeploy.json `
  -functionAppName <your-unique-name> `
  -spnId <your-app-id> `
  -spnSecret $spnSecret `
  -projectTag <project-name> `
  -createdByTag <your-email> `
  -deleteAtTag <date-or-Never>
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `functionAppName` | Yes | Globally unique name for your function app (3-60 characters, lowercase letters, numbers, and hyphens only) |
| `spnId` | Yes | Application (client) ID from your multi-tenant app registration |
| `spnSecret` | Yes | Client secret from your multi-tenant app registration (stored securely) |
| `projectTag` | Yes | Value for the 'Project' tag required by Azure Policy |
| `createdByTag` | Yes | Value for the 'CreatedBy' tag required by Azure Policy |
| `deleteAtTag` | Yes | Value for the 'DeleteAt' tag required by Azure Policy (e.g., '2025-12-31' or 'Never') |
| `location` | No | Azure region for deployment (defaults to resource group location) |
| `runtime` | No | Function runtime (defaults to "powershell") |
| `enableManagedIdentity` | No | Enable system-assigned managed identity (defaults to true) |

## Post-Deployment

After successful deployment, you'll need to:

1. **Note the outputs:**
   - `functionAppUrl` - Use this in the workbook configuration
   - `storageAccountName` - Automatically created and configured
   - `managedIdentityPrincipalId` - System-assigned managed identity (if enabled)

2. **Verify environment variables** are set in the Function App:
   - `APPID` - Application (client) ID
   - `SECRETID` - Client secret (stored securely)
   - `FUNCTIONS_WORKER_RUNTIME` - PowerShell
   - `FUNCTIONS_EXTENSION_VERSION` - ~4

3. **Deploy function code** to the Function App:
   - All function directories have required `function.json` and `run.ps1` files
   - `host.json` configured for PowerShell 7.4 runtime compatibility
   - `.funcignore` ensures only necessary files are deployed
   - Functions use HTTP trigger with 'function' auth level

4. **Deploy the workbooks** (see [Workbook Deployment](#workbook-deployment) below)

See the main [DEPLOYMENT.md](../DEPLOYMENT.md) for detailed step-by-step instructions.

## Workbook Deployment

After deploying the Function App, deploy the DefenderC2 workbooks to Azure Monitor:

### Quick Start (Recommended)

```powershell
# Deploy both workbooks with one command
.\deploy-workbook.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -WorkspaceResourceId "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}" `
    -FunctionAppName "defc2" `
    -DeployMainWorkbook `
    -DeployFileOpsWorkbook
```

### What This Does

The deployment script:
- ✅ Loads workbook JSON content from `../workbook/` directory
- ✅ Automatically sets the **Function App Name** parameter in both workbooks
- ✅ Deploys workbooks to Azure Monitor with proper configuration
- ✅ Links workbooks to your Log Analytics workspace

### Important: Function App Name Parameter

The workbooks require a **Function App Name** parameter to work correctly:
- **What it is**: The name of your Azure Function App (e.g., `defc2`, `mydefender`)
- **How it's used**: Constructs the full URL as `https://{FunctionAppName}.azurewebsites.net`
- **Why it matters**: All API calls to your functions depend on this being correct

**The deployment script automatically sets this parameter**, ensuring the workbooks work immediately after deployment.

### Manual Deployment Alternative

If you prefer manual deployment, see [WORKBOOK_DEPLOYMENT.md](WORKBOOK_DEPLOYMENT.md) for:
- Azure Portal import instructions
- Azure CLI deployment commands
- Troubleshooting guide
- Advanced configuration options

### Verifying Workbook Deployment

After deployment:
1. Go to **Azure Portal** → **Monitor** → **Workbooks**
2. Find `DefenderC2 Command & Control Console`
3. Click to open
4. Verify parameters:
   - ✅ **Function App Name** = your function app name
   - ✅ **Subscription** = select your subscription
   - ✅ **Workspace** = select your Log Analytics workspace
   - ✅ **Tenant ID** = auto-populated from workspace

### Troubleshooting Workbook Issues

**Issue**: "Please provide a valid resource path" errors

**Solution**: Verify the Function App Name parameter is correct (must match your function app exactly)

**Issue**: Queries return no data

**Solution**: 
1. Check function app is running
2. Verify `APPID` and `SECRETID` environment variables are set
3. Ensure app registration has Defender API permissions

For more help, see [WORKBOOK_DEPLOYMENT.md](WORKBOOK_DEPLOYMENT.md).

## Function Configuration

The repository includes properly configured Azure Functions with:

### Required Files Structure
```
functions/
├── host.json                    # Function app config (PowerShell 7.4 compatible)
├── profile.ps1                  # Module loading script
├── requirements.psd1            # PowerShell dependencies
├── .funcignore                  # Deployment exclusions
├── MDEAutomator/               # PowerShell module directory
│   └── *.psm1                  # Module files
├── MDEDispatcher/
│   ├── function.json           # HTTP trigger bindings
│   └── run.ps1                 # Function implementation
├── MDECDManager/
│   ├── function.json
│   └── run.ps1
├── MDEHuntManager/
│   ├── function.json
│   └── run.ps1
├── MDEIncidentManager/
│   ├── function.json
│   └── run.ps1
└── MDETIManager/
    ├── function.json
    └── run.ps1
```

### host.json Features
- PowerShell 7.4 runtime compatibility
- Enhanced logging (file logging, Application Insights)
- 10-minute function timeout for long operations
- Health monitoring enabled
- Automatic retry with fixed delay strategy
- Managed dependency support for PowerShell modules

### function.json Configuration
All functions use identical HTTP trigger configuration:
```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "Request",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "Response"
    }
  ]
}
```

## Validation

### Quick Validation (Recommended)

Run the automated validation script:

```bash
cd deployment
python3 test_azuredeploy.py
```

This script validates:
- ✅ JSON syntax
- ✅ Required ARM template sections
- ✅ Complete listKeys function calls (lines 132 & 136)
- ✅ Connection string format

See `VALIDATION_REPORT.md` for detailed validation results.

### Azure Validation

To validate the template with Azure before deployment:

```bash
# Azure CLI
az deployment group validate \
  --resource-group <your-resource-group> \
  --template-file azuredeploy.json \
  --parameters functionAppName=test spnId=00000000-0000-0000-0000-000000000000

# PowerShell
Test-AzResourceGroupDeployment `
  -ResourceGroupName <your-resource-group> `
  -TemplateFile azuredeploy.json `
  -functionAppName test `
  -spnId 00000000-0000-0000-0000-000000000000
```

## Troubleshooting

### "Deploy to Azure" button doesn't work ⚠️ COMMON ISSUE

**Error Message:** *"There was an error downloading the template from URI 'https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json'. Ensure that the template is publicly accessible and that the publisher has enabled CORS policy on the endpoint."*

**Root Cause:** The template file hasn't been merged to the `main` branch yet, so it returns a 404 error when Azure tries to download it.

**Solution 1: Manual Template Deployment (RECOMMENDED - Works Every Time)**

This is the most reliable method:

1. Open [azuredeploy.json](azuredeploy.json) in this repository on GitHub
2. Click the **"Raw"** button to view the raw JSON
3. Press Ctrl+A (or Cmd+A) to select all, then Ctrl+C (or Cmd+C) to copy
4. Go to [Azure Portal](https://portal.azure.com)
5. In the search bar at the top, search for **"Deploy a custom template"**
6. Click the result: "Deploy a custom template"
7. Click **"Build your own template in the editor"**
8. Delete the sample JSON that appears
9. Press Ctrl+V (or Cmd+V) to paste your copied template
10. Click **"Save"**
11. Fill in the required parameters (functionAppName, spnId, spnSecret, tags)
12. Click **"Review + create"** then **"Create"**

**Solution 2: Use Azure CLI or PowerShell**
```bash
# Clone the repository first
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar/deployment

# Then deploy using Azure CLI
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file azuredeploy.json \
  --parameters functionAppName=<your-unique-name> \
               spnId=<your-app-id> \
               spnSecret=<your-client-secret> \
               projectTag=<project-name> \
               createdByTag=<your-email> \
               deleteAtTag=<date-or-Never>
```

**Solution 3: Direct Template Link**
Try accessing the template directly to verify accessibility:
```
https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json
```

**Common Causes:**
- Template not yet merged to `main` branch (use the branch-specific URL instead)
- GitHub rate limiting or temporary unavailability
- Browser CORS restrictions (use manual deployment instead)
- Private repository (ensure repository is public)

### Template validation fails
- Verify all required parameters are provided
- Check that the function app name is globally unique (3-60 characters, lowercase letters, numbers, and hyphens only)
- Ensure the spnId is a valid GUID format (e.g., `12345678-1234-1234-1234-123456789abc`)
- Verify you have Owner or Contributor permissions on the subscription

### Deployment fails
- Check Azure subscription quotas (Function Apps, Storage Accounts)
- Verify you have permissions to create resources in the resource group
- Review deployment logs in the Azure Portal for specific error messages
- Ensure the storage account name is globally unique (automatically generated)
- Check that the selected region supports Azure Functions with PowerShell runtime
