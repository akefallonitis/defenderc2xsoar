# Quick Start Guide

Get up and running with DefenderC2 in under 15 minutes using one-click deployment!

## 🚀 Fastest Way: One-Click Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Prerequisites:**
- Azure subscription with Contributor access
- Global Administrator or Application Administrator in Entra ID
- Microsoft Defender for Endpoint deployed
- Multi-tenant App Registration (see setup below)

**What you'll get:**
- ✅ Complete DefenderC2 deployment in Azure
- ✅ Auto-discovery workbook (zero manual configuration!)
- ✅ Ready to use in 15 minutes

---

## Prerequisites

Before clicking "Deploy to Azure", you need:

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

### 3. Create Client Secret (2 minutes)

In your app registration:

1. Go to **Certificates & secrets** > **Client secrets**
2. Click **New client secret**
3. Description: `DefenderC2-Secret`
4. Expires: Choose duration (recommended: 24 months)
5. Click **Add**
6. **Copy the secret Value immediately** - you won't be able to see it again!

### 4. Deploy DefenderC2 to Azure (5 minutes)

Now click the Deploy to Azure button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

Fill in the deployment form:
- **Subscription**: Select your subscription
- **Resource Group**: Create new or select existing
- **Region**: Choose your preferred Azure region
- **Function App Name**: `defenderc2-yourname` (must be globally unique)
- **Spn Id**: Paste your Application (Client) ID from step 1
- **Spn Secret**: Paste your Client Secret from step 3
- **Project Tag**: `DefenderC2`
- **Created By Tag**: Your email
- **Delete At Tag**: `Never` (or a date like `2025-12-31`)

Click **Review + create** > **Create**

**Wait for deployment** (~5 minutes). This deploys:
- Azure Function App with 6 functions
- DefenderC2 Command & Control Workbook
- Storage Account and App Service Plan
- All configuration and settings

### 5. Open Your Workbook (2 minutes)

**🎉 The workbook was automatically deployed!**

Once deployment completes:

1. Go to **Azure Portal** > **Monitor** > **Workbooks**
2. Look for **"DefenderC2 Command & Control Console"**
3. Click to open it
4. Pin it to your dashboard for quick access

### 6. Start Using DefenderC2! (Zero Configuration)

**That's it!** The workbook uses auto-discovery for everything:

**You only need to select:**
1. **Subscription**: Choose your Azure subscription from dropdown
2. **Workspace**: Choose your Log Analytics workspace from dropdown

**Everything else is automatic:**
- ✅ Tenant ID: Auto-extracted from workspace
- ✅ Function App URL: Auto-discovered via resource tags
- ✅ Service Principal ID: Read from Function App environment
- ✅ Authentication: Anonymous (no keys needed!)

**Now you can:**
- Isolate/unisolate devices
- Run antivirus scans
- Execute advanced hunting queries
- Manage threat indicators
- Handle incidents
- Create custom detections
- And much more!

---

## Alternative: Manual Function Deployment

If you need to update function code manually, you can use:

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
  --name defenderc2-yourname \
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
