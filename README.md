# defenderc2xsoar

A port of [MDEAutomator](https://github.com/msdirtbag/MDEAutomator) using Azure Sentinel Workbooks instead of webapp for multi-tenant Microsoft Defender for Endpoint automation.

## Overview

This project provides a workbook-based approach to MDE automation without requiring Azure Key Vault for secrets management. Instead, it uses:
- **Azure Workbooks** - Interactive UI for MDE operations
- **Azure Resource Graph** - Multi-tenant subscription/workspace selection
- **Managed Identity** - Secure authentication without Key Vault
- **ARM Actions/Custom Endpoints** - Function app integration
- **Multi-tenant Support** - Single deployment for multiple tenants

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

## Architecture

```
┌─────────────────────┐
│  Azure Workbook     │
│  (User Interface)   │
└──────────┬──────────┘
           │
           │ Parameters: tenantId, spnId
           ▼
┌─────────────────────┐
│  Azure Function App │
│  (PowerShell)       │
│  + Managed Identity │
└──────────┬──────────┘
           │
           │ Federated Auth
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
3. Configure API Permissions (see [Required Permissions](#required-permissions))
4. Grant admin consent for all permissions
5. Copy the **Application (client) ID** - you'll need this for deployment

### Step 2: Deploy Function App

Click the button below or use the ARM template in `/deployment`:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Parameters:**
- `functionAppName`: Globally unique name for your function app
- `spnId`: Application (client) ID from Step 1
- `enableManagedIdentity`: `true` (recommended)

**Note the outputs:**
- `functionAppUrl` - You'll use this in the workbook
- `managedIdentityPrincipalId` - You'll use this for federated credentials

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
3. **Target Tenant ID** - The tenant where MDE is deployed
4. **Function App Base URL** - From deployment output (e.g., `https://your-function-app.azurewebsites.net`)
5. **Service Principal (App) ID** - From Step 1

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

## Security Considerations

⚠️ **Important Security Notes:**

1. **Workbook Access Control** - Restrict workbook access using Azure RBAC
2. **Function App Authentication** - Enable Azure AD authentication on the function app
3. **Managed Identity** - Always use managed identity instead of secrets
4. **Audit Logging** - Enable diagnostic logs on the function app
5. **Network Security** - Consider using private endpoints for function app
6. **Script Signing** - Sign all PowerShell scripts before uploading to LR library

## Differences from Original MDEAutomator

| Feature | Original MDEAutomator | defenderc2xsoar |
|---------|----------------------|-----------------|
| UI | Python Flask webapp | Azure Workbook |
| Authentication | Key Vault for secrets | Managed Identity + Federated Auth |
| Deployment | Complex IaC with VNet | Simplified ARM template |
| Multi-tenancy | Supported | Supported (simplified) |
| Cost | ~$220/month | ~$50/month (no App Service, OpenAI optional) |

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

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/akefallonitis/defenderc2xsoar/issues)
- Reference the [MDEAutomator documentation](https://github.com/msdirtbag/MDEAutomator)

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. Use at your own risk. Always test in a non-production environment first.
