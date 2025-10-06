# Automated Deployment Guide

This guide explains how to set up automated deployments for the Azure Functions and Workbook using GitHub Actions, similar to Azure Sentinel connectors.

## 🎯 Overview

This repository includes automated deployment workflows that:
- ✅ Automatically deploy Azure Functions when code changes in `functions/`
- ✅ Automatically deploy Azure Workbook when changes occur in `workbook/`
- ✅ Support manual deployment via GitHub Actions UI
- ✅ Include fallback scripts for manual deployment

## 📋 Prerequisites

Before setting up automated deployments, you need:

1. **Azure Subscription** - An active Azure subscription
2. **Azure Function App** - Already deployed (use `deployment/azuredeploy.json`)
3. **Azure Log Analytics Workspace** - For workbook deployment
4. **GitHub Repository** - Fork or clone of this repository
5. **Azure Service Principal** - For GitHub Actions authentication

## 🔐 Setup GitHub Secrets

GitHub Actions workflows require the following secrets to be configured in your repository.

### Step 1: Create Azure Service Principal

Create a service principal with contributor access to your resource group:

```bash
# Set variables
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP="<your-resource-group-name>"
SP_NAME="github-actions-defenderc2"

# Create service principal
az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

**Important**: Save the entire JSON output - you'll need it for `AZURE_CREDENTIALS`.

The output should look like:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### Step 2: Get Function App Publish Profile

Get the publish profile for your Function App:

```bash
# Using Azure CLI
az functionapp deployment list-publishing-profiles \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --xml
```

Or via Azure Portal:
1. Navigate to your Function App
2. Click **Get publish profile** in the Overview page
3. Open the downloaded `.PublishSettings` file
4. Copy the entire XML content

### Step 3: Get Workspace Resource ID

Get your Log Analytics workspace resource ID:

```bash
# Using Azure CLI
az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --query id \
  --output tsv
```

Or via Azure Portal:
1. Navigate to your Log Analytics workspace
2. Go to **Properties**
3. Copy the **Resource ID**

### Step 4: Configure GitHub Secrets

Navigate to your GitHub repository settings and add the following secrets:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example/Source |
|------------|-------------|----------------|
| `AZURE_CREDENTIALS` | Service principal JSON output | From Step 1 (entire JSON) |
| `AZURE_FUNCTIONAPP_NAME` | Name of your Function App | `mde-automator-func-prod` |
| `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` | Function App publish profile | From Step 2 (entire XML) |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | From service principal JSON |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-mde-automator` |
| `AZURE_LOCATION` | Azure region | `eastus` |
| `AZURE_WORKSPACE_RESOURCE_ID` | Log Analytics workspace resource ID | From Step 3 |

### Step 5: Verify Secret Configuration

After adding all secrets, verify them in:
**Settings → Secrets and variables → Actions**

You should see all 7 secrets listed.

## 🚀 Automated Deployment Workflows

### Deploy Azure Functions Workflow

**File**: `.github/workflows/deploy-azure-functions.yml`

**Triggers**:
- Push to `main` branch with changes in `functions/`
- Manual trigger via GitHub Actions UI

**What it does**:
1. Checks out the repository
2. Sets up PowerShell environment
3. Authenticates with Azure using service principal
4. Deploys function code to Azure Function App

**Manual Trigger**:
1. Go to **Actions** tab in GitHub
2. Select **Deploy Azure Functions** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### Deploy Workbook Workflow

**File**: `.github/workflows/deploy-workbook.yml`

**Triggers**:
- Push to `main` branch with changes in `workbook/`
- Manual trigger via GitHub Actions UI

**What it does**:
1. Checks out the repository
2. Authenticates with Azure
3. Reads workbook JSON content
4. Deploys workbook using ARM template

**Manual Trigger**:
1. Go to **Actions** tab in GitHub
2. Select **Deploy Azure Workbook** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## 🔧 Manual Deployment Scripts

If automated deployment fails or you prefer manual deployment, use these scripts:

### Quick Deploy Script (Recommended)

Deploy functions using PowerShell:

```powershell
# Navigate to repository root
cd defenderc2xsoar

# Run quick deploy script
./scripts/quick-deploy.ps1 `
  -ResourceGroupName "rg-mde-automator" `
  -FunctionAppName "mde-automator-func-prod"
```

This script:
- ✅ Creates deployment package automatically
- ✅ Verifies Azure CLI authentication
- ✅ Checks function app exists
- ✅ Deploys via ZIP deployment
- ✅ Verifies deployed functions

### Create Deployment Package Only

If you just want to create the deployment package:

```powershell
./scripts/create-deployment-package.ps1
```

Then upload manually via Azure Portal:
1. Navigate to Function App → **Deployment Center**
2. Select **ZIP Deploy**
3. Upload `deploy-package.zip`

### Azure CLI Deployment

Deploy using Azure CLI directly:

```bash
# Create deployment package
cd functions
zip -r ../functions.zip .
cd ..

# Deploy to Azure
az functionapp deployment source config-zip \
  --resource-group rg-mde-automator \
  --name mde-automator-func-prod \
  --src functions.zip
```

### Azure Functions Core Tools

Deploy using Azure Functions Core Tools:

```bash
cd functions
func azure functionapp publish mde-automator-func-prod
```

## 🐛 Troubleshooting

### GitHub Actions Failures

#### Authentication Failed

**Error**: `Login failed with Error: ClientAuthenticationError`

**Solution**:
- Verify `AZURE_CREDENTIALS` secret contains valid service principal JSON
- Ensure service principal has contributor access
- Check service principal hasn't expired

```bash
# Test service principal
az login --service-principal \
  --username <clientId> \
  --password <clientSecret> \
  --tenant <tenantId>
```

#### Function Deployment Failed

**Error**: `Error: Failed to deploy web package to App Service`

**Solution**:
- Verify `AZURE_FUNCTIONAPP_NAME` matches your actual function app name
- Check `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` is valid and not expired
- Ensure function app is running (not stopped)

```bash
# Check function app status
az functionapp show \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --query state
```

#### Workbook Deployment Failed

**Error**: `The template deployment failed with error: 'InvalidTemplate'`

**Solution**:
- Verify `AZURE_WORKSPACE_RESOURCE_ID` is correct and accessible
- Ensure `AZURE_LOCATION` matches your resource group location
- Check service principal has permissions on workspace

```bash
# Test workspace access
az monitor log-analytics workspace show \
  --ids $WORKSPACE_RESOURCE_ID
```

### Manual Deployment Issues

#### PowerShell Script Errors

**Error**: `Az CLI not found`

**Solution**: Install Azure CLI
- Windows: Download from https://aka.ms/installazurecliwindows
- Linux/Mac: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

**Error**: `Not logged in to Azure`

**Solution**: Run `az login` and authenticate

#### Package Too Large

**Error**: `Package size exceeds limit`

**Solution**:
- Verify `.funcignore` is properly excluding unnecessary files
- Remove `node_modules/`, `.git/`, and other large directories
- Check package size: should be under 100 MB

```powershell
# Check what's in the package
Expand-Archive -Path deploy-package.zip -DestinationPath temp-check
Get-ChildItem temp-check -Recurse | Measure-Object -Property Length -Sum
Remove-Item temp-check -Recurse -Force
```

#### Functions Not Appearing

**Error**: Functions deployed but not visible in portal

**Solution**:
- Wait 2-3 minutes for functions to initialize
- Check deployment logs in Azure Portal
- Verify `function.json` exists in each function directory
- Restart function app

```bash
# Restart function app
az functionapp restart \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME
```

## 🔒 Security Best Practices

### Secret Management

1. **Rotate Secrets Regularly**
   - Regenerate publish profile every 90 days
   - Rotate service principal credentials quarterly
   - Update GitHub secrets after rotation

2. **Principle of Least Privilege**
   - Service principal should only have contributor access to specific resource group
   - Don't use subscription-level permissions unless required

3. **Monitor Deployments**
   - Review GitHub Actions logs regularly
   - Enable Azure Activity Log alerts for unauthorized access
   - Use Azure Monitor to track function app changes

### Audit Logging

Enable audit logging for deployments:

```bash
# Enable diagnostic settings for Function App
az monitor diagnostic-settings create \
  --resource $FUNCTION_APP_RESOURCE_ID \
  --name "deployment-audit" \
  --workspace $WORKSPACE_RESOURCE_ID \
  --logs '[{"category": "FunctionAppLogs", "enabled": true}]'
```

## 📊 Monitoring Deployments

### View Deployment Status

**GitHub Actions**:
1. Go to **Actions** tab
2. Select a workflow run
3. View logs for each step

**Azure Portal**:
1. Navigate to Function App
2. Go to **Deployment Center** → **Logs**
3. View deployment history

### Enable Application Insights

Monitor function execution:

```bash
# Enable Application Insights
az functionapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY
```

## 🔄 Continuous Integration Best Practices

### Branch Protection

Protect your `main` branch:

1. **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require conversation resolution before merging

### Pre-deployment Testing

Add testing workflow before deployment:

```yaml
# .github/workflows/test.yml
name: Test Functions

on: [pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test PowerShell Syntax
        run: |
          Get-ChildItem -Path functions -Filter *.ps1 -Recurse | ForEach-Object {
            $errors = $null
            [void][System.Management.Automation.PSParser]::Tokenize(
              (Get-Content $_.FullName -Raw), [ref]$errors
            )
            if ($errors.Count -gt 0) {
              Write-Error "Syntax errors in $($_.FullName)"
            }
          }
```

## 📚 Additional Resources

- [Azure Functions Deployment](https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
- [Azure Workbooks](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Sentinel Data Connectors](https://docs.microsoft.com/en-us/azure/sentinel/connect-data-sources)

## 🤝 Contributing

When contributing changes that affect deployment:

1. Test locally using manual deployment scripts
2. Verify changes don't break automated deployment
3. Update this documentation if adding new secrets or workflows
4. Test GitHub Actions in your fork before submitting PR

## 📞 Support

For issues with automated deployment:

1. Check [troubleshooting section](#-troubleshooting) above
2. Review GitHub Actions logs for error messages
3. Open an issue with:
   - Workflow name and run ID
   - Error messages (redact sensitive info)
   - Steps to reproduce
