# ARM Template Deployment Files

This folder contains Azure Resource Manager (ARM) template files for deploying the MDE Automator Function App.

## Files

### azuredeploy.json
The main ARM template that defines the Azure resources to be deployed:
- Azure Function App (PowerShell runtime)
- App Service Plan (Consumption tier)
- Storage Account
- Managed Identity configuration
- CORS settings for Azure Portal

### createUIDefinition.json
Provides a custom user interface in the Azure Portal when deploying via the "Deploy to Azure" button. This file:
- Validates input parameters
- Provides helpful tooltips and descriptions
- Ensures proper format for function app names and GUIDs

### metadata.json
Contains metadata about the template for Azure Quickstart Templates gallery:
- Template description and summary
- Tags and keywords for discoverability
- Cost and complexity level indicators

### azuredeploy.parameters.json
Sample parameters file for command-line deployments using Azure CLI or PowerShell. Contains placeholder values that should be replaced with your actual values.

## Deployment Options

### Option 1: Azure Portal (Recommended)
Click the "Deploy to Azure" button in the main README.md

### Option 2: Azure CLI
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file azuredeploy.json \
  --parameters functionAppName=<your-unique-name> spnId=<your-app-id>
```

### Option 3: PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName <your-resource-group> `
  -TemplateFile azuredeploy.json `
  -functionAppName <your-unique-name> `
  -spnId <your-app-id>
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `functionAppName` | Yes | Globally unique name for your function app (3-60 characters, lowercase letters, numbers, and hyphens only) |
| `spnId` | Yes | Application (client) ID from your multi-tenant app registration |
| `location` | No | Azure region for deployment (defaults to resource group location) |
| `runtime` | No | Function runtime (defaults to "powershell") |
| `enableManagedIdentity` | No | Enable system-assigned managed identity (defaults to true) |

## Post-Deployment

After successful deployment, you'll need to:

1. **Note the outputs:**
   - `functionAppUrl` - Use this in the workbook configuration
   - `managedIdentityPrincipalId` - Use this for federated credentials

2. **Configure federated identity credentials** (see main documentation)

3. **Deploy function code** to the Function App

4. **Deploy the workbook** template

See the main [DEPLOYMENT.md](../DEPLOYMENT.md) for detailed step-by-step instructions.

## Validation

To validate the template before deployment:

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

### "Deploy to Azure" button doesn't work

If you encounter an error like *"There was an error downloading the template from URI"* or CORS-related issues:

**Solution 1: Manual Template Deployment**
1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Deploy a custom template"
3. Click "Build your own template in the editor"
4. Copy the contents of [azuredeploy.json](azuredeploy.json) from this repository
5. Paste into the editor
6. Click "Save"
7. Fill in the required parameters
8. Click "Review + create" > "Create"

**Solution 2: Use Azure CLI or PowerShell**
```bash
# Clone the repository first
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar/deployment

# Then deploy using Azure CLI
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file azuredeploy.json \
  --parameters functionAppName=<your-unique-name> spnId=<your-app-id>
```

**Solution 3: Direct Template Link**
Try accessing the template directly to verify accessibility:
```
https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/refs/heads/main/deployment/azuredeploy.json
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
