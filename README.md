# defenderc2xsoar

[![Deploy Azure Functions](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-azure-functions.yml/badge.svg)](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-azure-functions.yml)
[![Deploy Workbook](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-workbook.yml/badge.svg)](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-workbook.yml)

A port of [MDEAutomator](https://github.com/msdirtbag/MDEAutomator) using Azure Sentinel Workbooks instead of webapp for multi-tenant Microsoft Defender for Endpoint automation.

## 🆕 Standalone PowerShell Version Available!

> **New!** Looking for a local version that doesn't require Azure infrastructure? Check out the **[Standalone PowerShell Framework](standalone/README.md)** - a menu-driven UI that runs entirely on your local machine with zero cloud dependencies!

## Overview

This project provides **two deployment options** for MDE automation:

### Azure-based Version (This README)
- **Azure Workbooks** - Interactive UI for MDE operations
- **Azure Resource Graph** - Multi-tenant subscription/workspace selection
- **Managed Identity** - Secure authentication without Key Vault
- **ARM Actions/Custom Endpoints** - Function app integration
- **Multi-tenant Support** - Single deployment for multiple tenants

### Standalone PowerShell Version ([Documentation](standalone/README.md))
- **Local PowerShell Framework** - Runs on your workstation
- **Menu-driven UI** - Similar to original MDEAutomator
- **No Azure Required** - Zero cloud infrastructure costs
- **Secure Credential Storage** - Encrypted using Windows DPAPI
- **Quick Setup** - Ready in 10 minutes

## Features

### Core Functionality

All MDEAutomator capabilities replicated through Azure Workbooks:

1. **Defender C2 (Device Actions)**
   - Isolate/Unisolate devices
   - Collect investigation packages
   - Run antivirus scans
   - Restrict/Unrestrict app execution
   - Stop & quarantine files
   - Live Response operations (run scripts, get/put files)

2. **Threat Intelligence Manager**
   - Manage file indicators (SHA1/SHA256 hashes)
   - Manage network indicators (IPs, URLs, domains)
   - Manage certificate indicators
   - Bulk operations via CSV import
   - Custom detection rule management

3. **Action Manager**
   - View recent machine actions
   - Check action status
   - Cancel all pending actions (safety switch)
   - View action results and outputs

4. **Hunt Manager**
   - Execute KQL queries against MDE Advanced Hunting
   - Scheduled hunting operations
   - Query library management
   - Result analysis and export
   - Azure Storage integration

5. **Incident Manager**
   - View and filter security incidents
   - Update incident status and classification
   - Add investigation comments
   - Generate incident summaries

6. **Custom Detection Manager**
   - List custom detection rules
   - Create/update/delete detection rules
   - Backup and restore detections
   - Azure Storage integration

7. **🖥️ Interactive Console** *(New!)*
   - Shell-like interface for command execution
   - Async command execution with auto-polling
   - Automatic JSON parsing and result display
   - Configurable refresh intervals (10s/30s/1m/5m/manual)
   - Command history and audit trail
   - Support for all MDE actions, hunting, TI, incidents, and detections
   - Real-time status monitoring with visual indicators

8. **📦 File Library Management** *(New!)*
   - Centralized file library using Azure Storage
   - Upload files once, deploy to devices many times
   - No manual Base64 encoding required
   - Deploy files via Live Response with one click
   - Download files from devices with automatic browser download
   - Team collaboration with shared file library
   - Helper scripts for bulk upload and sync operations
   - See [FILE_OPERATIONS_GUIDE.md](FILE_OPERATIONS_GUIDE.md) for details

## Architecture

```
┌─────────────────────┐
│  Azure Workbook     │
│  (User Interface)   │
└──────────┬──────────┘
           │
           │ Parameters: tenantId
           ▼
┌─────────────────────┐
│  Azure Function App │
│  (PowerShell)       │
│  Env: APPID,        │
│       SECRETID      │
└──────────┬──────────┘
           │
           │ Client Credentials Auth
           ▼
┌─────────────────────┐
│  Multi-tenant       │
│  App Registration   │
└──────────┬──────────┘
           │
           │ API Calls
           ▼
┌─────────────────────┐
│  Microsoft Defender │
│  for Endpoint       │
└─────────────────────┘
```

## Deployment

> **Simplified Deployment:** Unlike the original MDEAutomator's complex Infrastructure-as-Code setup, this project uses a single ARM template that deploys only the essential resources. Setup takes about 1 hour compared to 2+ hours for the original. See the [comparison table](#differences-from-original-mdeautomator) below for more details.

### 🚀 Automated Deployment with GitHub Actions

This repository includes automated deployment workflows similar to Azure Sentinel connectors:

- **Azure Functions**: Automatically deploy when code changes in `functions/` directory
- **Workbook**: Automatically deploy when changes occur in `workbook/` directory
- **Manual Deployment**: Trigger deployments via GitHub Actions UI
- **Fallback Scripts**: PowerShell scripts for manual deployment when needed

**Quick Setup**:
1. Deploy infrastructure using ARM template (see below)
2. Configure GitHub Secrets (see [AUTOMATED_DEPLOYMENT.md](AUTOMATED_DEPLOYMENT.md))
3. Push changes to `main` branch - functions and workbook deploy automatically!

For detailed instructions on setting up automated deployments, see **[AUTOMATED_DEPLOYMENT.md](AUTOMATED_DEPLOYMENT.md)**.

### Prerequisites

1. **Azure Subscription** - For deploying function apps
2. **Multi-tenant App Registration** - With required API permissions
3. **Azure Workbook** - Deploy the workbook template
4. **Managed Identity** - System-assigned identity for function app

### Step 1: Create Multi-tenant App Registration

1. Navigate to Azure Portal > Entra ID > App Registrations
2. Click "New registration"
   - Name: `MDE-Automator-MultiTenant`
   - Supported account types: **Accounts in any organizational directory (Any Azure AD directory - Multitenant)**
3. Create a Client Secret:
   - Click "Certificates & secrets" > "New client secret"
   - Copy the **secret value** immediately (you won't see it again)
4. Configure API Permissions (see [Required Permissions](#required-permissions))
5. Grant admin consent for all permissions
6. Copy the **Application (client) ID** - you'll need this for deployment

### Step 2: Deploy Everything in One Click

> **🎯 NEW:** Complete one-click deployment now includes infrastructure + function code + workbook automatically!

#### Option 1: Deploy to Azure Button ⭐ RECOMMENDED

Click the button below to deploy **EVERYTHING** (Infrastructure + Code + Workbook):

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**What gets deployed:**
- ✅ Function App with all 11 functions (from GitHub package)
- ✅ Storage Account (automatically configured)
- ✅ Workbook (Defender C2 Workbook)
- ✅ All configuration and environment variables

**Note:** Functions are deployed from a pre-packaged zip file hosted on GitHub. Wait 2-3 minutes after deployment for all functions to appear in the portal.

#### Option 2: PowerShell Complete Deployment Script

For automated deployment with verification:

```powershell
cd deployment
./deploy-complete.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -FunctionAppName "mde-automator-prod" `
    -AppId "your-app-id" `
    -ClientSecret "your-client-secret" `
    -Location "westeurope"
```

This script:
- Creates deployment package
- Deploys ARM template
- Verifies all resources
- Lists deployed functions

#### Option 3: Manual Template Deployment

If the button doesn't work:

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for **"Deploy a custom template"**
3. Click **"Build your own template in the editor"**
4. Copy the template from [deployment/azuredeploy.json](deployment/azuredeploy.json)
5. Paste the content into the editor and click **"Save"**
6. Fill in the parameters below

#### Option 4: Azure CLI Deployment

```bash
cd deployment
az deployment group create \
  --resource-group rg-defenderc2 \
  --template-file azuredeploy.json \
  --parameters \
    functionAppName=mde-automator-prod \
    spnId=your-app-id \
    spnSecret=your-client-secret \
    projectTag=DefenderC2 \
    createdByTag=your-email \
    deleteAtTag=Never
```

---

**Required Parameters:**
- `functionAppName`: Globally unique name for your function app
- `spnId`: Application (client) ID from Step 1
- `spnSecret`: Client secret from Step 1
- `projectTag`: Project name (required by Azure Policy)
- `createdByTag`: Your name/email (required by Azure Policy)
- `deleteAtTag`: Deletion date or 'Never' (required by Azure Policy)

**Optional Parameters:**
- `location`: Azure region (default: resource group location)
- `enableManagedIdentity`: Enable system-assigned identity (default: `true`)

📚 **For detailed deployment instructions and troubleshooting, see [COMPLETE_DEPLOYMENT.md](COMPLETE_DEPLOYMENT.md)**

**Note the deployment outputs:**
- `functionAppUrl` - You'll use this in the workbook
- `storageAccountName` - Automatically created

### Step 3: Configure Federated Identity

1. Go to your App Registration > Certificates & secrets > Federated credentials
2. Click "Add credential"
3. Select "Other issuer"
4. Configure:
   - **Issuer**: `https://login.microsoftonline.com/{TENANT_ID}/v2.0`
   - **Subject identifier**: The managed identity principal ID from deployment output
   - **Name**: `FunctionAppManagedIdentity`
   - **Audience**: `api://AzureADTokenExchange`
5. Click "Add"

### Step 4: Access and Configure Workbook

The workbook is **automatically deployed** with the ARM template. To access it:

1. Navigate to Azure Portal > Monitor > Workbooks
2. Look for "Defender C2 Workbook" (it may be in "My workbooks" or the resource group)
3. Open the workbook and configure these parameters:
   - **Function App Base URL**: Your function app URL from deployment outputs
   - **Target Tenant ID**: The tenant ID where you want to manage MDE
   - **Service Principal ID**: Your app registration client ID

**Alternative:** If you want to customize the workbook:
1. Click "Edit" in the workbook
2. Modify as needed
3. Save to your preferred location

**Manual Deployment** (if needed):
1. Navigate to Azure Portal > Monitor > Workbooks > New > Advanced Editor
2. Paste contents from `/workbook/MDEAutomatorWorkbook.json`
3. Click "Apply" and save

### Step 5: Verify Functions Deployed

The function code is **automatically deployed** from a pre-packaged zip file. Wait 2-3 minutes, then verify:

**Via Azure Portal:**
1. Navigate to your Function App
2. Click "Functions" in the left menu
3. You should see all 9 functions:
   - ✅ **DefenderC2Dispatcher** - Handle device action requests
   - ✅ **DefenderC2Orchestrator** - Orchestrate complex operations
   - ✅ **DefenderC2TIManager** - Handle threat intelligence operations
   - ✅ **DefenderC2HuntManager** - Handle hunting queries
   - ✅ **DefenderC2IncidentManager** - Handle incident operations
   - ✅ **DefenderC2CDManager** - Handle custom detection operations
   - ✅ **ListLibraryFiles** - List files in Azure Storage library
   - ✅ **GetLibraryFile** - Retrieve file from library
   - ✅ **DeleteLibraryFile** - Remove file from library

**Via Azure CLI:**
```bash
az functionapp function list \
  --resource-group your-rg \
  --name your-function-app \
  --query "[].name" -o table
```

**If functions don't appear:** Check Application Insights logs or see [COMPLETE_DEPLOYMENT.md](COMPLETE_DEPLOYMENT.md) troubleshooting section.

### Step 6: Configure Workbook Parameters

Open your deployed workbook and configure:

1. **Subscription** - Select your Azure subscriptions
2. **Workspace** - Select your Log Analytics workspace(s)
3. **Target Tenant ID** - The tenant where MDE is deployed (can be changed per request)
4. **Function App Base URL** - From deployment output (e.g., `https://your-function-app.azurewebsites.net`)

**Note:** The Application ID and Client Secret are securely stored in the Function App's environment variables and are not entered in the workbook.

## Required Permissions

### WindowsDefenderATP API

Configure these permissions for the multi-tenant app registration:

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

### Microsoft Graph API

- `CustomDetection.ReadWrite.All`
- `ThreatHunting.Read.All`
- `ThreatIndicators.ReadWrite.OwnedBy`
- `SecurityIncident.ReadWrite.All`

**Important:** After adding permissions, grant admin consent for each tenant where you'll use this solution.

## Usage

### Basic Workflow

1. **Configure** - Set parameters at the top of the workbook
2. **Select Tab** - Choose the operation category (Defender C2, Threat Intel, etc.)
3. **Configure Action** - Fill in action-specific parameters
4. **Execute** - Click the action button to trigger the function app
5. **View Results** - See results in the query panels below

### Example: Isolate High-Risk Devices

1. Go to **Defender C2** tab
2. Select **Action Type**: `Isolate Device`
3. Set **Device Filter**: `riskScore eq 'High'`
4. Click **Execute Action**
5. View results in the **Device List** section

### Example: Add Threat Indicators

1. Go to **Threat Intel Manager** tab
2. Select **Action**: `Add File Indicators`
3. Enter **Indicators**: `<sha256>,<sha256>,<sha256>` (comma-separated)
4. Set **Title**: `Malware Campaign X`
5. Set **Severity**: `High`
6. Set **Recommended Action**: `Block`
7. Click **Execute TI Action**

### Example: Hunt for Threats

1. Go to **Hunt Manager** tab
2. Enter your **KQL Query**:
   ```kql
   DeviceProcessEvents
   | where Timestamp > ago(7d)
   | where ProcessCommandLine has "powershell"
   | where ProcessCommandLine has_any ("-enc", "downloadstring")
   | project Timestamp, DeviceName, AccountName, ProcessCommandLine
   ```
3. Set **Hunt Name**: `Suspicious PowerShell Activity`
4. Enable **Save Results to Storage** if desired
5. Click **Execute Hunt**

### Example: Using Interactive Console 🖥️

The **Interactive Console** tab provides a shell-like interface for executing commands with automatic async polling:

1. Go to **🖥️ Interactive Console** tab
2. **Configure Settings:**
   - **Auto Refresh Interval**: Select `30 seconds` (recommended for active monitoring)
   - **Command Type**: Choose the operation category (e.g., `Device Actions`)
   - **Action/Command**: Select specific action (e.g., `Isolate Device`)
   - **Target Device IDs**: Enter comma-separated device IDs (optional for queries)
   - **Additional Parameters**: Add JSON parameters if needed

3. **Execute Command:**
   - Click **Run Query** in the "Execute Command" section
   - The Function App processes the request asynchronously
   - Command execution status displays immediately

4. **Monitor Progress:**
   - The "Action Status" section auto-refreshes based on your interval
   - Status indicators show: ✅ Succeeded, ⏳ InProgress, ⏸️ Pending, ❌ Failed
   - No manual polling needed - results update automatically

5. **View Results:**
   - Once complete, the "Command Results" section displays parsed JSON data
   - Results shown in table format for easy analysis
   - Export to Excel available for further processing

6. **Review History:**
   - "Execution History" section tracks last 20 commands
   - Includes timestamps, status, and action IDs
   - Useful for audit and troubleshooting

**Key Benefits:**
- ✅ **No manual polling** - automatic status updates
- ✅ **Real-time feedback** - visual status indicators
- ✅ **Structured results** - JSON parsed into tables
- ✅ **Command history** - complete audit trail
- ✅ **Configurable refresh** - from 10 seconds to manual

## Workbook Examples

This repository includes several example workbooks that demonstrate advanced functionality and patterns you can incorporate into your own workbooks. These examples showcase:

- Advanced parameter handling and cascading
- Complex visualizations and dashboards
- Multi-step workflows and guided processes
- Investigation and remediation consoles
- Audit and compliance tracking
- MDR/SOC analyst workflows

**Available Examples:**
- `Advanced Workbook Concepts.json` - Comprehensive feature showcase
- `DefenderC2 Advanced Console.json` - Streamlined C2 interface
- `Investigation Insights.json` - Security investigation workflows
- `Sentinel360 XDR Investigation-Remediation Console Enhanced.json` - XDR console
- `Sentinel360-MDR-Console.json` - MDR analyst interface
- `Sentinel360-XDR-Auditing.json` - Audit and compliance reporting

**Learn More:** See [WORKBOOK_EXAMPLES.md](WORKBOOK_EXAMPLES.md) for detailed descriptions, usage instructions, and integration tips.

## Security Considerations

⚠️ **Important Security Notes:**

1. **Workbook Access Control** - Restrict workbook access using Azure RBAC
2. **Function App Authentication** - Enable Azure AD authentication on the function app
3. **Managed Identity** - Always use managed identity instead of secrets
4. **Audit Logging** - Enable diagnostic logs on the function app
5. **Network Security** - Consider using private endpoints for function app
6. **Script Signing** - Sign all PowerShell scripts before uploading to LR library

## Differences from Original MDEAutomator

| Feature | Original MDEAutomator | defenderc2xsoar (Azure) | defenderc2xsoar (Standalone) |
|---------|----------------------|------------------------|------------------------------|
| UI | Python Flask webapp | Azure Workbook | PowerShell Menu |
| Authentication | Key Vault for secrets | Managed Identity + Federated Auth | App Registration + Secret |
| Deployment | Complex IaC with VNet | Simplified ARM template | Copy files + Run |
| Multi-tenancy | Supported | Supported (simplified) | Single tenant |
| Infrastructure | Azure + OpenAI | Azure Functions | None (local) |
| Cost | ~$220/month | ~$50/month | **Free** (no Azure costs) |
| Setup Time | ~2 hours | ~1 hour | **~10 minutes** |
| Best For | Large enterprises | Multi-tenant MSPs | SOC analysts, small teams |

## Troubleshooting

### Function App Not Responding

- Check function app is running: Azure Portal > Function App > Overview
- Verify managed identity is configured: App Registration > Federated credentials
- Check CORS settings: Function App > CORS > Add `https://portal.azure.com`

### Authentication Errors

- Verify SPN ID is correct in workbook parameters
- Check API permissions are granted and consented
- Confirm federated credential is properly configured
- Verify tenant ID matches the target MDE tenant

### Workbook Not Loading Data

- Confirm workspace has MDE data: Log Analytics > Logs > Query `DeviceInfo`
- Check subscription/workspace parameters are set
- Verify you have read access to the selected resources

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project inherits the license from the original MDEAutomator project.

## Acknowledgements

- Original [MDEAutomator](https://github.com/msdirtbag/MDEAutomator) by msdirtbag and the BlueVoyant DFIR team
- Microsoft Defender for Endpoint team
- Azure Workbooks team

## Documentation

### Main Guides
- [QUICKSTART.md](QUICKSTART.md) - Get started in 30 minutes
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [FEATURES.md](FEATURES.md) - Detailed feature documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture overview

### Feature-Specific Guides
- [INTERACTIVE_CONSOLE_GUIDE.md](INTERACTIVE_CONSOLE_GUIDE.md) - 🖥️ Interactive Console usage and examples
- [WORKBOOK_EXAMPLES.md](WORKBOOK_EXAMPLES.md) - Workbook examples and patterns
- [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md) - ARM template deployment fixes

### Additional Resources
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG.md](CHANGELOG.md) - Project changelog
- [deployment/README.md](deployment/README.md) - ARM template documentation

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/akefallonitis/defenderc2xsoar/issues)
- Check [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md) for common deployment issues
- Reference the [INTERACTIVE_CONSOLE_GUIDE.md](INTERACTIVE_CONSOLE_GUIDE.md) for console features
- See original [MDEAutomator documentation](https://github.com/msdirtbag/MDEAutomator)

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. Use at your own risk. Always test in a non-production environment first.
