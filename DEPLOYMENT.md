# Deployment Guide

This guide provides step-by-step instructions for deploying the defenderc2xsoar workbook-based MDE automation solution.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Deployment Steps](#deployment-steps)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the deployment, ensure you have:

- **Azure Subscription** with permissions to create resources
- **Global Administrator** or **Application Administrator** role in Entra ID
- **Microsoft Defender for Endpoint** (MDE) licenses
- **Azure CLI** or **PowerShell** for deployment (optional)
- **Access to target tenants** for multi-tenant scenarios

### Required Tools

- Azure Portal access
- PowerShell 7.2+ (for local testing)
- Azure CLI (optional, for command-line deployment)
- Git (to clone the repository)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     User Interface                      │
│              Azure Sentinel Workbook                    │
│  (Tenant selector, action buttons, result parsing)     │
└───────────────────────┬─────────────────────────────────┘
                        │ HTTPS
                        │ Parameters: tenantId, spnId, action
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Azure Function App (PowerShell)            │
│  ┌──────────────────────────────────────────────────┐  │
│  │  System-Assigned Managed Identity                │  │
│  │  (No secrets stored in code or config)           │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Functions:                                       │  │
│  │  - MDEDispatcher (device actions)                │  │
│  │  - MDETIManager (threat intel)                   │  │
│  │  - MDEHuntManager (hunting)                      │  │
│  │  - MDEIncidentManager (incidents)                │  │
│  │  - MDECDManager (custom detections)              │  │
│  └──────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │ OAuth 2.0 Token Exchange
                        │ (Federated Identity Credential)
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Multi-Tenant App Registration (Entra ID)        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Federated Credential linked to Managed Identity │  │
│  │  No client secrets required                      │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  API Permissions:                                 │  │
│  │  - WindowsDefenderATP (MDE APIs)                 │  │
│  │  - Microsoft Graph (Custom Detections, etc.)     │  │
│  └──────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │ API Calls
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Microsoft Defender for Endpoint APIs            │
│  - Machine actions (isolate, scan, collect)             │
│  - Threat indicators (IOCs)                             │
│  - Advanced hunting                                     │
│  - Custom detections                                    │
│  - Incident management                                  │
└─────────────────────────────────────────────────────────┘
```

**Key Benefits:**
- No secrets in Key Vault (uses managed identity + federated credentials)
- Multi-tenant support with single deployment
- Tenant ID passed as parameter to each function call
- Workbook-based UI (no web app maintenance)

## Deployment Steps

### Step 1: Create Multi-Tenant App Registration

This app registration will be used across all tenants and function executions.

1. **Navigate to Entra ID**
   - Go to [Azure Portal](https://portal.azure.com)
   - Select **Entra ID** (formerly Azure AD)
   - Click **App registrations** > **New registration**

2. **Configure Registration**
   - **Name**: `MDE-Automator-MultiTenant`
   - **Supported account types**: Select **Accounts in any organizational directory (Any Azure AD directory - Multitenant)**
   - **Redirect URI**: Leave empty
   - Click **Register**

3. **Copy Application ID**
   - On the Overview page, copy the **Application (client) ID**
   - Save this value - you'll need it for deployment and workbook configuration

4. **Create Client Secret**
   - Click **Certificates & secrets** > **New client secret**
   - **Description**: `MDE-Automator-Secret`
   - **Expires**: Choose an appropriate expiration period (e.g., 12 months, 24 months)
   - Click **Add**
   - **IMPORTANT**: Copy the **Value** immediately (you won't be able to see it again)
   - Save this secret value securely - you'll need it during deployment

5. **Configure API Permissions**

   Click **API permissions** > **Add a permission**

   **For WindowsDefenderATP:**
   - Click **APIs my organization uses**
   - Search for `WindowsDefenderATP` or `Microsoft Defender for Endpoint`
   - Select **Application permissions**
   - Add these permissions:
     - `AdvancedQuery.Read.All`
     - `Alert.Read.All`
     - `File.Read.All`
     - `Ip.Read.All`
     - `Library.Manage`
     - `Machine.CollectForensics`
     - `Machine.Isolate`
     - `Machine.StopAndQuarantine`
     - `Machine.LiveResponse`
     - `Machine.Offboard`
     - `Machine.ReadWrite.All`
     - `Machine.RestrictExecution`
     - `Machine.Scan`
     - `Ti.ReadWrite.All`
     - `User.Read.All`

   **For Microsoft Graph:**
   - Click **Add a permission** > **Microsoft Graph**
   - Select **Application permissions**
   - Add these permissions:
     - `CustomDetection.ReadWrite.All`
     - `ThreatHunting.Read.All`
     - `ThreatIndicators.ReadWrite.OwnedBy`
     - `SecurityIncident.ReadWrite.All`

6. **Grant Admin Consent**
   - Click **Grant admin consent for [Your Tenant]**
   - Confirm the consent

   **Note:** For multi-tenant scenarios, you'll need to grant consent in each target tenant as well.

### Step 2: Deploy Function App via ARM Template

You can deploy using the Azure Portal button or CLI/PowerShell.

#### Option A: Deploy via Azure Portal

> **⚠️ IMPORTANT:** The "Deploy to Azure" button below may fail with a template download error if the template hasn't been merged to the main branch yet. If this happens, **use Option D (Manual Template Deployment)** instead - it's equally easy and more reliable.

1. Click the button below:

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

   **If you see an error about downloading the template**, skip to [Option D: Manual Template Deployment](#option-d-manual-template-deployment).

2. Fill in the parameters:
   
   **Basic Settings:**
   - **Function App Name**: Enter a globally unique name (e.g., `mde-automator-func-prod`)
   - **Spn Id**: Paste the Application (client) ID from Step 1
   - **Spn Secret**: Paste the Client Secret value from Step 1
   
   **Function App Settings:**
   - **Enable Managed Identity**: Leave as `true` (recommended)
   
   **Resource Tags** (required by Azure Policy):
   - **Project Tag**: Enter your project name (e.g., `DefenderC2XSOAR`)
   - **CreatedBy Tag**: Enter your name or email (e.g., `john.doe@example.com`)
   - **DeleteAt Tag**: Enter deletion date (YYYY-MM-DD) or `Never`

3. Click **Review + create** > **Create**

4. **Save the outputs**:
   - `functionAppUrl` (e.g., `https://mde-automator-func-prod.azurewebsites.net`)
   - `managedIdentityPrincipalId` (a GUID)

#### Option B: Deploy via Azure CLI

```bash
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Set variables
RG_NAME="rg-mde-automator"
LOCATION="eastus"
FUNCTION_NAME="mde-automator-func-prod"
SPN_ID="<your-app-id-from-step-1>"
SPN_SECRET="<your-client-secret-from-step-1>"
PROJECT_TAG="DefenderC2XSOAR"
CREATED_BY_TAG="john.doe@example.com"
DELETE_AT_TAG="Never"

# Create resource group
az group create --name $RG_NAME --location $LOCATION

# Deploy template
az deployment group create \
  --resource-group $RG_NAME \
  --template-file deployment/azuredeploy.json \
  --parameters functionAppName=$FUNCTION_NAME \
               spnId=$SPN_ID \
               spnSecret=$SPN_SECRET \
               projectTag=$PROJECT_TAG \
               createdByTag=$CREATED_BY_TAG \
               deleteAtTag=$DELETE_AT_TAG

# Get outputs
az deployment group show \
  --resource-group $RG_NAME \
  --name azuredeploy \
  --query properties.outputs
```

#### Option C: Deploy via PowerShell

```powershell
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Set variables
$rgName = "rg-mde-automator"
$location = "eastus"
$functionName = "mde-automator-func-prod"
$spnId = "<your-app-id-from-step-1>"
$spnSecret = ConvertTo-SecureString "<your-client-secret-from-step-1>" -AsPlainText -Force
$projectTag = "DefenderC2XSOAR"
$createdByTag = "john.doe@example.com"
$deleteAtTag = "Never"

# Create resource group
New-AzResourceGroup -Name $rgName -Location $location

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName $rgName `
  -TemplateFile deployment/azuredeploy.json `
  -functionAppName $functionName `
  -spnId $spnId `
  -spnSecret $spnSecret `
  -projectTag $projectTag `
  -createdByTag $createdByTag `
  -deleteAtTag $deleteAtTag

# Get outputs
(Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name azuredeploy).Outputs
```

#### Option D: Manual Template Deployment (Recommended Alternative)

**Use this option if you see:** *"There was an error downloading the template from URI"* or any CORS/accessibility errors when clicking the Deploy button.

**Step-by-step instructions:**

1. Open [deployment/azuredeploy.json](deployment/azuredeploy.json) in this repository
2. Click the **Raw** button to view the raw JSON content
3. Copy all the content (Ctrl+A, Ctrl+C or Cmd+A, Cmd+C)
4. Go to [Azure Portal](https://portal.azure.com)
5. Search for **"Deploy a custom template"** in the search bar at the top
6. Click **"Build your own template in the editor"**
7. Delete the sample template that appears
8. Paste your copied template content (Ctrl+V or Cmd+V)
9. Click **"Save"**
10. Fill in the required parameters:
   - **Subscription**: Your Azure subscription
   - **Resource Group**: Create new or select existing
   - **Region**: Your preferred Azure region
   - **Function App Name**: Globally unique name (e.g., `mde-automator-func-prod`)
   - **Spn Id**: Application (client) ID from Step 1
   - **Spn Secret**: Client Secret value from Step 1
   - **Enable Managed Identity**: `true` (default)
   - **Project Tag**: Your project name (e.g., `DefenderC2XSOAR`)
   - **CreatedBy Tag**: Your name or email
   - **DeleteAt Tag**: Deletion date (YYYY-MM-DD) or `Never`
9. Click **"Review + create"** > **"Create"**
10. Note the deployment outputs after completion

**Why this might be needed:**
- Template not yet published to `main` branch
- GitHub rate limiting or temporary issues
- Browser CORS restrictions
- Repository access issues

### Step 3: Verify Function App Configuration

The function app has been configured with the necessary environment variables for multi-tenant authentication.

**Environment Variables Set:**
- `APPID`: The Application (client) ID from your app registration
- `SECRETID`: The client secret (stored securely)
- `FUNCTIONS_WORKER_RUNTIME`: PowerShell
- `FUNCTIONS_EXTENSION_VERSION`: ~4

**How Authentication Works:**
1. Workbook sends request with `tenantId` parameter to the function
2. Function reads `APPID` and `SECRETID` from environment variables
3. Function authenticates to the specified tenant using client credentials flow
4. Function calls Microsoft Defender for Endpoint APIs with the acquired token

This approach enables:
- ✅ Multi-tenant support (tenant ID passed per request)
- ✅ Secure credential storage (client secret in function app settings)
- ✅ No secrets in workbook or user-facing configuration
- ✅ Single deployment for all tenants

### Step 4: Verify Function Configuration

Before deploying, verify the function app structure is correct:

**Required Files:**
- ✅ `host.json` - Function app configuration (PowerShell 7.4 compatible)
- ✅ `profile.ps1` - Module loading and initialization
- ✅ `requirements.psd1` - PowerShell module dependencies
- ✅ `.funcignore` - Deployment exclusion rules

**Function Structure (each function directory):**
- ✅ `function.json` - HTTP trigger bindings with authLevel 'function'
- ✅ `run.ps1` - Function implementation

**All Functions:**
- ✅ MDEDispatcher - Device actions dispatcher
- ✅ MDECDManager - Custom detection manager
- ✅ MDEHuntManager - Advanced hunting manager
- ✅ MDEIncidentManager - Incident manager
- ✅ MDETIManager - Threat intelligence manager

**Module Directory:**
- ✅ MDEAutomator - PowerShell module with MDE API functions

### Step 5: Deploy Function Code

The function code needs to be deployed to the function app.

1. **Clone or download the repository** (if not already done):
   ```bash
   git clone https://github.com/akefallonitis/defenderc2xsoar.git
   cd defenderc2xsoar/functions
   ```

2. **Deploy using Azure Functions Core Tools**:
   ```bash
   # Install Azure Functions Core Tools if not already installed
   # https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local

   # Deploy the functions
   func azure functionapp publish mde-automator-func-prod
   ```

3. **Or deploy via VS Code**:
   - Install the Azure Functions extension
   - Open the `functions` folder in VS Code
   - Sign in to Azure (View > Command Palette > Azure: Sign In)
   - Right-click on the function app in the Azure pane
   - Select **Deploy to Function App**
   - Select your function app from the list

4. **Or deploy via ZIP deployment**:
   ```bash
   # Create a zip file of the functions folder
   cd functions
   zip -r ../functions.zip .
   cd ..

   # Deploy via Azure CLI
   az functionapp deployment source config-zip \
     --resource-group rg-mde-automator \
     --name mde-automator-func-prod \
     --src functions.zip
   ```

**Important Notes:**
- The `.funcignore` file ensures only necessary files are deployed
- PowerShell 7.4 runtime is configured in `host.json`
- All functions use HTTP trigger with 'function' auth level
- Managed dependencies are enabled for automatic module installation

### Step 6: Deploy Workbook

1. **Navigate to Azure Monitor**
   - Azure Portal > **Monitor** > **Workbooks**
   - Click **New** > **Advanced Editor** (</> icon)

2. **Load Template**
   - Remove the default template
   - Copy the contents of `workbook/MDEAutomatorWorkbook.json`
   - Paste into the editor
   - Click **Apply**

3. **Save Workbook**
   - Click **Done Editing**
   - Click **Save** (💾 icon)
   - **Title**: `MDE Automator`
   - **Subscription**: Select your subscription
   - **Resource Group**: Select or create a resource group
   - **Location**: Select your region
   - Click **Apply**

4. **Pin to Dashboard** (optional)
   - Click the pin icon to add to your Azure dashboard

### Step 7: Configure Workbook Parameters

Open your saved workbook and configure the parameters at the top:

1. **Subscription**: Select your Azure subscription(s)
2. **Workspace**: Select your Log Analytics workspace(s) where MDE data is collected
3. **Target Tenant ID**: Enter the tenant ID where MDE is deployed (this is sent to the function with each request)
4. **Function App Base URL**: Enter the URL from Step 2 (e.g., `https://mde-automator-func-prod.azurewebsites.net`)

**Save the workbook** after configuring parameters.

**Note:** The Application ID and Client Secret are no longer configured in the workbook. They are stored securely as environment variables in the Function App (configured during deployment in Step 2).

## Post-Deployment Configuration

### Enable Function App Authentication (Recommended)

To add an extra layer of security:

1. Go to your Function App > **Authentication**
2. Click **Add identity provider**
3. Select **Microsoft**
4. Configure:
   - **Tenant type**: Workforce
   - **App registration type**: Create new or use existing
   - **Restrict access**: Require authentication
5. Click **Add**

### Configure CORS

1. Go to Function App > **CORS**
2. Add allowed origins:
   - `https://portal.azure.com`
   - Your custom domains if any
3. **Save**

### Configure Application Insights (Recommended)

Application Insights should be automatically configured during deployment. To verify:

1. Go to Function App > **Application Insights**
2. Ensure it's enabled
3. Click **View Application Insights data** to access logs and telemetry

### Multi-Tenant Setup

For each additional tenant where you want to use this solution:

1. **Grant Consent** in the target tenant:
   - As a Global Admin in the target tenant, navigate to:
   ```
   https://login.microsoftonline.com/{TARGET_TENANT_ID}/adminconsent?client_id={YOUR_APP_ID}
   ```
   - Replace `{TARGET_TENANT_ID}` and `{YOUR_APP_ID}` with your values
   - Click **Accept**

2. **Update Workbook**: When using the workbook, set the **Target Tenant ID** parameter to the appropriate tenant

## Testing

### Test Function App Connectivity

1. **Test from Azure Portal**:
   - Go to Function App > Functions > MDEDispatcher
   - Click **Code + Test**
   - Click **Test/Run**
   - Set query parameters:
     ```json
     {
       "action": "GetActions",
       "tenantId": "your-tenant-id",
       "spnId": "your-app-id"
     }
     ```
   - Click **Run**
   - Check the response

2. **Test from Workbook**:
   - Open your workbook
   - Go to **Action Manager** tab
   - Click **Refresh Actions**
   - Verify that the function responds

### Test Device Actions

1. Go to **MDEAutomator** tab
2. Select **Action Type**: `Get Actions` (or similar read-only action)
3. Click **Execute Action**
4. Check the **Action Status** section for results

### Verify Logs

1. Go to Function App > **Log stream**
2. Watch for incoming requests and any errors
3. Or use Application Insights > **Logs**:
   ```kql
   traces
   | where timestamp > ago(1h)
   | where operation_Name == "MDEDispatcher"
   | order by timestamp desc
   ```

## Troubleshooting

### Common Issues

#### Function App Returns 401 Unauthorized

**Cause**: Authentication issue with federated credential or API permissions.

**Solution**:
1. Verify the federated credential is correctly configured
2. Check that the `managedIdentityPrincipalId` matches the function app's identity
3. Ensure API permissions are granted and consented
4. Verify the tenant ID is correct

#### Function App Returns 403 Forbidden

**Cause**: Missing API permissions or consent.

**Solution**:
1. Go to App Registration > API permissions
2. Verify all required permissions are added
3. Click **Grant admin consent**
4. For multi-tenant: Ensure consent is granted in the target tenant

#### Workbook Doesn't Load Data

**Cause**: Workspace doesn't have MDE data or wrong subscription/workspace selected.

**Solution**:
1. Verify MDE is sending data to the workspace:
   ```kql
   DeviceInfo
   | where TimeGenerated > ago(1d)
   | take 10
   ```
2. Check subscription and workspace parameters in the workbook
3. Verify you have read access to the selected workspace

#### Function Times Out

**Cause**: Long-running operations or network issues.

**Solution**:
1. Function timeout is configured in `host.json` (default: 10 minutes)
2. Check function logs for specific error messages
3. Consider using durable functions for very long-running operations
4. Check network connectivity to MDE APIs

#### Function Deployment Fails

**Cause**: Missing files, incorrect structure, or runtime issues.

**Solution**:
1. Verify all required files exist:
   - `host.json` in functions root
   - `function.json` in each function directory
   - `run.ps1` in each function directory
   - `.funcignore` to exclude unnecessary files
2. Check PowerShell runtime version:
   - Ensure FUNCTIONS_WORKER_RUNTIME=powershell
   - Ensure FUNCTIONS_EXTENSION_VERSION=~4
3. Validate function.json structure:
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
4. Check deployment logs in Azure Portal > Function App > Deployment Center

#### Module Not Found Errors

**Cause**: MDEAutomator module not loaded or path incorrect.

**Solution**:
1. Verify `profile.ps1` loads the module correctly
2. Check that MDEAutomator folder is in functions directory
3. Ensure managedDependency is enabled in `host.json`
4. Review function logs for module loading messages
5. Restart the function app after deployment

#### CORS Errors in Workbook

**Cause**: Function app CORS not configured for Azure Portal.

**Solution**:
1. Go to Function App > CORS
2. Add `https://portal.azure.com`
3. Save and refresh the workbook

### Getting Help

- Check function app logs in Application Insights
- Review the [MDEAutomator documentation](https://github.com/msdirtbag/MDEAutomator)
- Open an issue on [GitHub](https://github.com/akefallonitis/defenderc2xsoar/issues)

## Next Steps

After successful deployment:

1. **Import MDEAutomator PowerShell Module**: Add the module to your function app for full functionality
2. **Customize Workbook**: Modify queries and visualizations to fit your needs
3. **Set Up Automation**: Create scheduled hunts or recurring actions
4. **Configure Alerts**: Set up alerts on function failures or specific MDE events
5. **Review Security**: Implement additional security controls as needed

## Maintenance

### Updating Functions

To update function code:

```bash
cd defenderc2xsoar/functions
func azure functionapp publish mde-automator-func-prod
```

### Updating Workbook

1. Open the workbook
2. Click **Edit**
3. Make your changes
4. Click **Done Editing** > **Save**

### Monitoring

- **Function App Metrics**: Monitor execution count, errors, and duration
- **Application Insights**: Set up alerts for failures or performance issues
- **Workbook Usage**: Track which actions are used most frequently

### Cost Management

Monitor costs in Azure Cost Management:
- Function app consumption (typically minimal)
- Storage account (for function app and results)
- Application Insights (data ingestion and retention)

Estimated monthly cost: **~$10-50** (much lower than original MDEAutomator)

---

**Congratulations!** You've successfully deployed the defenderc2xsoar workbook-based MDE automation solution.
