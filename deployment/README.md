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
- Ensure you're accessing the template from a public GitHub repository
- Check that the URL encoding in the button is correct
- Try accessing the raw JSON file directly to verify it's accessible

### Template validation fails
- Verify all required parameters are provided
- Check that the function app name is globally unique
- Ensure the spnId is a valid GUID format

### Deployment fails
- Check Azure subscription quotas
- Verify you have permissions to create resources in the resource group
- Review deployment logs in the Azure Portal for specific error messages
