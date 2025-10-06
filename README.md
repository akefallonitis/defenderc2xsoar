# defenderc2xsoar

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

1. **MDEAutomator (Device Actions)**
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

### Step 2: Deploy Function App

Click the button below or use the ARM template in `/deployment`:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Parameters:**
- `functionAppName`: Globally unique name for your function app
- `spnId`: Application (client) ID from Step 1
- `spnSecret`: Client secret from Step 1
- `projectTag`: Project name (required by Azure Policy)
- `createdByTag`: Your name/email (required by Azure Policy)
- `deleteAtTag`: Deletion date or 'Never' (required by Azure Policy)
- `enableManagedIdentity`: `true` (recommended)

**Note the outputs:**
- `functionAppUrl` - You'll use this in the workbook
- `storageAccountName` - Automatically created

**For other deployment methods** (Azure CLI, PowerShell, or manual template deployment), see the [deployment folder documentation](deployment/README.md).

> **⚠️ Troubleshooting Deploy Button:** If you encounter an error downloading the template, you can:
> 1. **Manual Deployment**: Copy the template content from [deployment/azuredeploy.json](deployment/azuredeploy.json) and paste it into Azure Portal's "Build your own template in the editor" option
> 2. **CLI Deployment**: Clone this repo and use `az deployment group create` command (see [deployment/README.md](deployment/README.md))
> 3. **Direct Access**: Verify template accessibility at https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/deployment/azuredeploy.json

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

### Step 4: Deploy Workbook

1. Navigate to Azure Portal > Monitor > Workbooks
2. Click "New" > "Advanced Editor"
3. Paste the contents of `/workbook/MDEAutomatorWorkbook.json`
4. Click "Apply"
5. Save the workbook to your desired location

### Step 5: Deploy Function Code

You'll need to deploy the PowerShell function code to your function app. The functions should implement:

- **MDEDispatcher** - Handle device action requests
- **MDETIManager** - Handle threat intelligence operations
- **MDEHuntManager** - Handle hunting queries
- **MDEIncidentManager** - Handle incident operations
- **MDECDManager** - Handle custom detection operations

See the [MDEAutomator PowerShell module documentation](https://github.com/msdirtbag/MDEAutomator#module-introduction) for function implementation details.

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
2. **Select Tab** - Choose the operation category (MDEAutomator, Threat Intel, etc.)
3. **Configure Action** - Fill in action-specific parameters
4. **Execute** - Click the action button to trigger the function app
5. **View Results** - See results in the query panels below

### Example: Isolate High-Risk Devices

1. Go to **MDEAutomator** tab
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
