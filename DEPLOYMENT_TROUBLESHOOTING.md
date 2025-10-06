# ARM Template Deployment Troubleshooting Guide

## Overview

This guide addresses the common error: *"There was an error downloading the template from URI"* when using the "Deploy to Azure" button.

## The Problem

When clicking the "Deploy to Azure" button, you may encounter:

```
There was an error downloading the template from URI 
'https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json'. 
Ensure that the template is publicly accessible and that the publisher has enabled CORS policy on the endpoint.
```

## Root Causes

### 1. Template Not on Main Branch
- The template might exist on a feature branch but not yet merged to `main`
- The Deploy button always references the `main` branch
- **Solution**: Use branch-specific URL or wait for merge

### 2. GitHub Rate Limiting
- GitHub API has rate limits for unauthenticated requests
- May affect template downloads during high traffic
- **Solution**: Wait a few minutes and retry, or use manual deployment

### 3. Repository Access
- Repository might be private
- Branch protection rules might restrict access
- **Solution**: Verify repository is public

### 4. Browser CORS Issues
- Some browsers may have strict CORS policies
- Browser extensions might interfere
- **Solution**: Use manual template deployment method

### 5. Network/DNS Issues
- Corporate firewalls might block GitHub raw content
- DNS resolution issues
- **Solution**: Use local deployment with Azure CLI

## Solutions

### Solution 1: Manual Template Deployment (Recommended)

This is the most reliable method when the button fails:

1. **Open Azure Portal**
   - Go to https://portal.azure.com
   - Sign in with your credentials

2. **Navigate to Custom Deployment**
   - Search for "Deploy a custom template" in the search bar
   - Or go directly to: https://portal.azure.com/#create/Microsoft.Template

3. **Build Your Own Template**
   - Click "Build your own template in the editor"
   - You'll see an empty JSON editor

4. **Get Template Content**
   - Open this repository on GitHub
   - Navigate to `deployment/azuredeploy.json`
   - Click "Raw" button
   - Copy all content (Ctrl+A, Ctrl+C)

5. **Paste and Deploy**
   - Paste the content into Azure Portal editor
   - Click "Save"
   - Fill in required parameters:
     - **Subscription**: Your Azure subscription
     - **Resource Group**: Create new or select existing
     - **Region**: Your preferred Azure region
     - **Function App Name**: Globally unique name (e.g., `mde-automator-func-prod`)
     - **Spn Id**: Application (client) ID from your App Registration
     - **Enable Managed Identity**: `true` (default, recommended)
   - Click "Review + create"
   - Review the settings
   - Click "Create"

6. **Monitor Deployment**
   - Wait for deployment to complete (~3-5 minutes)
   - Click "Go to resource group" when done
   - Note the deployment outputs:
     - `functionAppUrl`
     - `managedIdentityPrincipalId`

### Solution 2: Azure CLI Deployment

If you have Azure CLI installed:

```bash
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Set your parameters
RESOURCE_GROUP="rg-mde-automator"
LOCATION="eastus"
FUNCTION_NAME="mde-automator-func-unique"
SPN_ID="your-app-registration-client-id"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Deploy template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file deployment/azuredeploy.json \
  --parameters functionAppName=$FUNCTION_NAME spnId=$SPN_ID

# Get outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name azuredeploy \
  --query properties.outputs
```

### Solution 3: PowerShell Deployment

If you have Azure PowerShell installed:

```powershell
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Set your parameters
$rgName = "rg-mde-automator"
$location = "eastus"
$functionName = "mde-automator-func-unique"
$spnId = "your-app-registration-client-id"

# Create resource group
New-AzResourceGroup -Name $rgName -Location $location

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName $rgName `
  -TemplateFile deployment/azuredeploy.json `
  -functionAppName $functionName `
  -spnId $spnId

# Get outputs
(Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name azuredeploy).Outputs
```

### Solution 4: Branch-Specific URL

If the template is on a different branch:

1. Identify the branch name (e.g., `copilot/fix-31814759-fc89-4714-b324-60e7fff2377f`)
2. Update the URL in the Deploy button:
   ```
   https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/<BRANCH_NAME>/deployment/azuredeploy.json
   ```
3. URL-encode the branch name if it contains special characters (e.g., `/` becomes `%2F`)
4. Use the custom URL with the Deploy button template

### Solution 5: Local Template File

Download and use locally:

```bash
# Download the template
curl -o azuredeploy.json https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json

# Deploy using Azure CLI
az deployment group create \
  --resource-group your-resource-group \
  --template-file azuredeploy.json \
  --parameters functionAppName=your-func-name spnId=your-spn-id
```

## Verification Steps

After deployment, verify the resources:

### 1. Check Resource Group
```bash
az resource list --resource-group your-resource-group --output table
```

You should see:
- Function App (`Microsoft.Web/sites`)
- App Service Plan (`Microsoft.Web/serverfarms`)
- Storage Account (`Microsoft.Storage/storageAccounts`)

### 2. Check Function App
```bash
az functionapp show \
  --name your-function-name \
  --resource-group your-resource-group \
  --query "{name:name,state:state,hostNames:defaultHostName}"
```

### 3. Check Managed Identity
```bash
az functionapp identity show \
  --name your-function-name \
  --resource-group your-resource-group
```

Should return a `principalId` (GUID).

### 4. Test Function App URL
```bash
curl https://your-function-name.azurewebsites.net
```

Should return a response (may be a default page or 404, but confirms it's accessible).

## Template Validation

Before deploying, validate the template:

### Azure CLI
```bash
az deployment group validate \
  --resource-group your-resource-group \
  --template-file deployment/azuredeploy.json \
  --parameters functionAppName=test-func spnId=00000000-0000-0000-0000-000000000000
```

### PowerShell
```powershell
Test-AzResourceGroupDeployment `
  -ResourceGroupName your-resource-group `
  -TemplateFile deployment/azuredeploy.json `
  -functionAppName test-func `
  -spnId 00000000-0000-0000-0000-000000000000
```

## Common Errors

### Error: "Function App Name Already Exists"
**Cause**: Function App names must be globally unique across all of Azure.

**Solution**: 
- Try a different name
- Add a unique suffix (e.g., your initials, random numbers)
- Check naming: lowercase letters, numbers, hyphens only

### Error: "Invalid SPN ID Format"
**Cause**: The Service Principal ID is not a valid GUID.

**Solution**:
- Verify it's in format: `12345678-1234-1234-1234-123456789abc`
- Copy directly from App Registration overview
- Remove any extra spaces or characters

### Error: "Insufficient Permissions"
**Cause**: You don't have permission to create resources.

**Solution**:
- Ensure you have "Contributor" or "Owner" role on the subscription
- Check if there are resource policies blocking creation
- Contact your Azure administrator

### Error: "Storage Account Name Invalid"
**Cause**: Auto-generated storage name doesn't meet requirements.

**Solution**:
- This shouldn't happen with the template, but if it does:
- Re-run deployment (will generate new name)
- Contact repository maintainers if persistent

## CORS Configuration

The ARM template includes CORS settings for the Function App:

```json
"cors": {
  "allowedOrigins": [
    "https://portal.azure.com"
  ]
}
```

This allows the workbook (running in Azure Portal) to call the Function App. If you need additional origins:

1. Go to Function App → CORS in Azure Portal
2. Add additional allowed origins
3. Save changes

## Direct Template Access

To verify the template is accessible:

1. **Browser**: Navigate to:
   ```
   https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json
   ```

2. **curl**:
   ```bash
   curl -I https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json
   ```
   
   Should return `HTTP/2 200`

3. **PowerShell**:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json" -Method Head
   ```

If any of these fail, the issue is with repository access or branch availability.

## Best Practices

1. **Always validate** template before deploying
2. **Use unique names** for Function Apps
3. **Save outputs** immediately after deployment
4. **Test in non-production** first
5. **Keep template locally** for offline deployments
6. **Monitor deployment** logs in Azure Portal
7. **Review CORS settings** for your environment
8. **Document parameters** used for future reference

## Getting Help

If you continue to have issues:

1. **Check Repository Issues**: Search for similar problems
2. **Verify Prerequisites**: Ensure all requirements are met
3. **Review Logs**: Check Azure deployment logs
4. **Validate Template**: Use validation commands
5. **Open Issue**: Provide:
   - Exact error message
   - Deployment method used
   - Azure region
   - Browser/CLI version (if applicable)

## Related Documentation

- [Main README](README.md) - Project overview
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [QUICKSTART.md](QUICKSTART.md) - Quick setup
- [deployment/README.md](deployment/README.md) - ARM template details

---

**Note**: This guide is specifically for ARM template deployment issues. For other deployment problems, see [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting).
