# Quick Start Guide

Get up and running with defenderc2xsoar in under 30 minutes!

## Prerequisites

- Azure subscription with Contributor access
- Global Administrator or Application Administrator in Entra ID
- Microsoft Defender for Endpoint deployed

## Step-by-Step Setup

### 1. Create App Registration (5 minutes)

1. Go to [Azure Portal](https://portal.azure.com) > Entra ID > App registrations
2. Click **New registration**
3. Name: `MDE-Automator-MultiTenant`
4. Supported account types: **Multitenant**
5. Click **Register**
6. **Copy the Application (client) ID** - save this!

### 2. Add API Permissions (5 minutes)

In your app registration:

1. Go to **API permissions** > **Add a permission**

**WindowsDefenderATP Permissions:**
- Select "WindowsDefenderATP" (or search for it)
- Choose **Application permissions**
- Add ALL these (you can search and select multiple):
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

**Microsoft Graph Permissions:**
- Click **Add a permission** again > **Microsoft Graph**
- Choose **Application permissions**
- Add these:
  - `CustomDetection.ReadWrite.All`
  - `ThreatHunting.Read.All`
  - `ThreatIndicators.ReadWrite.OwnedBy`
  - `SecurityIncident.ReadWrite.All`

2. Click **Grant admin consent for [Your Tenant]**

### 3. Deploy Function App (5 minutes)

> **⚠️ DEPLOY BUTTON OFTEN FAILS**: If you get a template download error, skip the button below and follow the **Manual Deployment Steps** instead.

#### Quick Deploy Button (if available):

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

#### Manual Deployment Steps (recommended):

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for **"Deploy a custom template"**
3. Click **"Build your own template in the editor"**
4. Open [deployment/azuredeploy.json](deployment/azuredeploy.json) from this GitHub repository
5. Copy the entire JSON content and paste it into the editor
6. Click **"Save"**

Then continue with the parameters below:

Fill in:
- **Function App Name**: `mde-automator-yourname` (must be globally unique)
- **Spn Id**: Paste your Application ID from step 1
- **Enable Managed Identity**: Leave as `true`

Click **Review + create** > **Create**

Wait for deployment to complete (~3 minutes), then:
- Copy the **functionAppUrl** from the Outputs tab
- Copy the **managedIdentityPrincipalId** from the Outputs tab

### 4. Link Managed Identity (5 minutes)

Back in your App Registration:

1. Go to **Certificates & secrets** > **Federated credentials**
2. Click **Add credential**
3. Scenario: **Other issuer**
4. Fill in:
   - **Issuer**: `https://login.microsoftonline.com/YOUR-TENANT-ID/v2.0`
     - Replace `YOUR-TENANT-ID` with your actual tenant ID
   - **Subject identifier**: Paste the `managedIdentityPrincipalId` from step 3
   - **Name**: `FunctionAppManagedIdentity`
   - **Audience**: `api://AzureADTokenExchange`
5. Click **Add**

### 5. Deploy Workbook (5 minutes)

1. Go to Azure Portal > **Monitor** > **Workbooks**
2. Click **New** > Click the **Advanced Editor** button (`</>`)
3. Delete the default JSON
4. Copy all content from [workbook/MDEAutomatorWorkbook.json](workbook/MDEAutomatorWorkbook.json)
5. Paste it into the editor
6. Click **Apply**
7. Click **Done Editing**
8. Click **Save** (💾 icon)
9. Give it a name: `Defender C2`
10. Click **Apply**

### 6. Configure Workbook (2 minutes)

In your workbook, fill in the parameters at the top:

1. **Subscription**: Select your subscription
2. **Workspace**: Select your Log Analytics workspace (where MDE sends data)
3. **Target Tenant ID**: Your tenant ID (where MDE is deployed)
4. **Function App Base URL**: The `functionAppUrl` from step 3 (e.g., `https://mde-automator-yourname.azurewebsites.net`)
5. **Service Principal (App) ID**: Your Application ID from step 1

**Save the workbook**

### 7. Deploy Function Code (5 minutes)

You need to deploy the PowerShell function code. Choose one method:

#### Option A: Azure CLI

```bash
# Clone the repo
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar/functions

# Zip the functions
zip -r ../functions.zip .
cd ..

# Deploy
az functionapp deployment source config-zip \
  --resource-group YOUR-RESOURCE-GROUP \
  --name mde-automator-yourname \
  --src functions.zip
```

#### Option B: VS Code

1. Install the Azure Functions extension for VS Code
2. Open the `functions` folder in VS Code
3. Click the Azure icon in the sidebar
4. Find your function app
5. Right-click > **Deploy to Function App**

### 8. Test It! (3 minutes)

1. Open your workbook
2. Go to the **Action Manager** tab
3. Click **Refresh Actions**
4. You should see a response!

If you see an error, check the [Troubleshooting](#troubleshooting) section below.

## What You Can Do Now

### View Devices

Go to **MDEAutomator** tab to see all your MDE-managed devices.

### Manage Threat Indicators

1. Go to **Threat Intel Manager** tab
2. Select **Add File Indicators**
3. Enter some SHA256 hashes (comma-separated)
4. Click **Execute TI Action**

### Hunt for Threats

1. Go to **Hunt Manager** tab
2. Enter a KQL query, for example:
   ```kql
   DeviceProcessEvents
   | where Timestamp > ago(7d)
   | where FileName =~ "powershell.exe"
   | where ProcessCommandLine has "downloadstring"
   | take 100
   ```
3. Give it a name: `Suspicious PowerShell`
4. Click **Execute Hunt**

### View Incidents

1. Go to **Incident Manager** tab
2. Click **Refresh Incidents**
3. View all your MDE incidents

## Troubleshooting

### Function Returns 401 Unauthorized

**Problem**: Federated credential not configured correctly.

**Solution**:
1. Verify you completed Step 4 exactly as written
2. Check that the `managedIdentityPrincipalId` is correct
3. Wait 5 minutes for credential to propagate
4. Try again

### Function Returns 403 Forbidden

**Problem**: Missing API permissions or consent.

**Solution**:
1. Go to your App Registration > API permissions
2. Verify all permissions are listed
3. Click **Grant admin consent** again
4. Wait 2 minutes
5. Try again

### Workbook Shows "No Data"

**Problem**: MDE data not flowing to Log Analytics workspace.

**Solution**:
1. Verify MDE is connected to your workspace
2. In Log Analytics, run this query:
   ```kql
   DeviceInfo
   | where TimeGenerated > ago(1d)
   | take 10
   ```
3. If no results, check your MDE connector configuration

### Function Not Found

**Problem**: Function code not deployed.

**Solution**: Complete Step 7 to deploy the function code.

## Next Steps

Now that you're set up:

1. **Explore the Tabs**: Each tab has different functionality
2. **Run Test Actions**: Try isolating a test device (then unisolate it!)
3. **Create Custom Detections**: Build your own detection rules
4. **Schedule Hunts**: Set up recurring threat hunting queries
5. **Multi-Tenant Setup**: Follow the [DEPLOYMENT.md](DEPLOYMENT.md) guide for additional tenants

## Getting Help

- Review the full [README.md](README.md) for detailed documentation
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for advanced configuration
- Open an issue on [GitHub](https://github.com/akefallonitis/defenderc2xsoar/issues)

## Common Use Cases

### Isolate High-Risk Devices

1. Go to **MDEAutomator** tab
2. Action: `Isolate Device`
3. Device Filter: `riskScore eq 'High'`
4. Execute

### Block Malicious Hashes

1. Go to **Threat Intel Manager** tab
2. Action: `Add File Indicators`
3. Indicators: `<sha256>,<sha256>`
4. Severity: `High`
5. Action: `Block`
6. Execute

### Investigate an Incident

1. Go to **Incident Manager** tab
2. Find your incident
3. Click to view details
4. Add comments
5. Update status when resolved

Congratulations! You now have a fully functional MDE automation platform! 🎉
