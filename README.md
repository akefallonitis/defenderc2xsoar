# DefenderXDRC2XSOAR

**Full Microsoft Defender XDR Command & Control** - A comprehensive automation platform for Microsoft security ecosystem including MDE, MDO, MDI, Entra ID, Intune, and Azure. Inspired by [MDEAutomator](https://github.com/msdirtbag/MDEAutomator), now expanded to cover the entire Microsoft XDR stack.

## ✅ PRODUCTION READY - Version 2.0.0

This package provides full XDR capabilities with validated deployment:
- ✅ **Full XDR Coverage** - 40+ actions across all Microsoft security services
- ✅ **Email Remediation (MDO)** - Soft/hard delete, quarantine, threat submission
- ✅ **Identity Protection** - User management, risk assessment, conditional access
- ✅ **Endpoint Security (MDE)** - Complete device control and investigation
- ✅ **Intune Integration** - Device management and compliance
- ✅ **Azure Security** - Infrastructure protection and network controls
- ✅ **Unified Module** - DefenderXDRC2XSOAR PowerShell module (v2.0.0)

**Quick Start**: See [DEPLOYMENT_READY_FINAL.md](DEPLOYMENT_READY_FINAL.md) for complete deployment guide.

## 🚀 Quick Deploy to Azure

Deploy the complete DefenderC2 solution (Azure Functions + Workbook) with one click:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

This will deploy:
- ✅ Azure Function App (PowerShell 7.4 runtime)
- ✅ 7 DefenderXDR Functions with function-level authentication
  - DefenderC2Dispatcher (MDE actions)
  - DefenderXDRManager (MDO, Entra ID, Intune, Azure)
  - DefenderC2Orchestrator (unified operations)
  - DefenderC2TIManager, HuntManager, IncidentManager, CDManager
- ✅ DefenderXDRC2XSOAR Complete Workbook with ARM actions
- ✅ Storage Account and App Service Plan
- ✅ Managed Identity configuration

> **Note**: You'll need to provide your multi-tenant App Registration credentials with appropriate permissions during deployment. See [PERMISSIONS.md](PERMISSIONS.md) for complete permission requirements.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Deployment Options](#deployment-options)
- [Features](#features)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Architecture](#architecture)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## Overview


---

## Azure Workbook: Custom Endpoint & ARM Action Implementation Guide

This section provides step-by-step reference for implementing fully functional Custom Endpoint auto-refresh queries and ARM Actions in Azure Workbooks for DefenderC2 Function Apps. It includes:
- Copy-paste JSON code samples for Custom Endpoint and ARM Action items
- Autodiscovery of parameters (including TenantId)
- Optional Function Key support (parameterized, not required for anonymous access)
- Tab-by-tab instructions
- Troubleshooting and validation

### 1. Parameter Autodiscovery & Optional Function Key
- **FunctionAppName**: required parameter
- **TenantId**: auto-discovered from the selected Log Analytics Workspace
- **FunctionKey**: optional parameter, only used if Function App requires a key

**Sample parameters section:**
```json
{
   "parameters": [
      { "name": "FunctionAppName", "type": 1, "isRequired": true },
      { "name": "TenantId", "type": 1, "isRequired": true, "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | where id == '{Workspace}' | extend TenantId = tostring(properties.customerId) | project value = TenantId, label = TenantId" },
      { "name": "FunctionKey", "type": 1, "isRequired": false, "description": "Optional. Only needed if Function App is not anonymous."}
   ]
}
```

### 2. Custom Endpoint (Auto-Refresh, With/Without Function Key)
**How to write in Advanced Editor:**
- `queryType`: 10
- `query`: JSON string for CustomEndpoint/1.0
- POST method, correct Function App URL, auto-refresh enabled
- Add `?code={FunctionKey}` to URL only if needed

**Sample JSON (No Function Key):**
```json
{
   "type": 3,
   "content": {
      "version": "KqlItem/1.0",
      "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.isolationState\",\"columnid\":\"isolationState\"},{\"path\":\"$.healthStatus\",\"columnid\":\"healthStatus\"},{\"path\":\"$.riskScore\",\"columnid\":\"riskScore\"}]}}]}",
      "size": 0,
      "title": "Device List (Custom Endpoint Auto-Refresh)",
      "queryType": 10,
      "visualization": "table"
   },
   "name": "devices-table"
}
```

**Sample JSON (With Optional Function Key):**
```json
{
   "type": 3,
   "content": {
      "version": "KqlItem/1.0",
      "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.isolationState\",\"columnid\":\"isolationState\"},{\"path\":\"$.healthStatus\",\"columnid\":\"healthStatus\"},{\"path\":\"$.riskScore\",\"columnid\":\"riskScore\"}]}}]}",
      "size": 0,
      "title": "Device List (Custom Endpoint Auto-Refresh)",
      "queryType": 10,
      "visualization": "table"
   },
   "name": "devices-table"
}
```

### 3. ARM Actions (Manual Button, With/Without Function Key)
**Use direct POST to Function App.**
Add `?code={FunctionKey}` to URL only if needed.

**Sample JSON (No Function Key):**
```json
{
   "type": 11,
   "content": {
      "version": "LinkItem/1.0",
      "links": [{
         "linkTarget": "ArmAction",
         "linkLabel": "🚨 Isolate Devices",
         "armActionContext": {
            "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
            "headers": [{"name": "Content-Type", "value": "application/json"}],
            "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
            "httpMethod": "POST"
         }
      }]
   }
}
```

**Sample JSON (With Optional Function Key):**
```json
{
   "type": 11,
   "content": {
      "version": "LinkItem/1.0",
      "links": [{
         "linkTarget": "ArmAction",
         "linkLabel": "🚨 Isolate Devices",
         "armActionContext": {
            "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}",
            "headers": [{"name": "Content-Type", "value": "application/json"}],
            "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
            "httpMethod": "POST"
         }
      }]
   }
}
```

### 4. Tab-by-Tab Functionality Examples
- **Device Manager**: Get Devices (Custom Endpoint), Isolate Device (ARM Action), Unisolate Device, Restrict App Execution, Run Antivirus Scan
- **Threat Intel**: List Indicators (Custom Endpoint), Add Indicator (ARM Action)
- **Action Manager**: Get All Actions (Custom Endpoint)
- **Hunt Manager**: Get Hunt Status (Custom Endpoint)
- **Incident Manager**: Get Incidents (Custom Endpoint)
- **Detection Manager**: List Detections (Custom Endpoint)
- **Console**: Get Command History (Custom Endpoint)

### 5. Troubleshooting & Validation
- If workbook queries fail, check Function App authentication (Anonymous/Function)
- If FunctionKey is blank, URL must not contain ?code=
- Ensure parameters are passed in body and URL as needed
- Use JSONPath transformers for parsing
- See ![Custom Endpoint JSON in workbook editor](https://github.com/user-attachments/assets/a68ad801-3dfa-40cb-8be4-79f345b74045)

### 6. How to Use
1. Import workbook into Azure Portal
2. Configure parameters (FunctionAppName, TenantId auto-discovered, FunctionKey optional)
3. For each query, use queryType: 10 and the CustomEndpoint JSON as above
4. For ARM Actions, use direct Function App POST as above
5. Test each tab for correct data/actions

### References
- ![Custom Endpoint JSON in workbook editor](https://github.com/user-attachments/assets/a68ad801-3dfa-40cb-8be4-79f345b74045)
- Previous issues for sample code and gotchas
- [Azure Functions authentication docs](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook?tabs=csharp#authorization-keys)

---

### 🌐 Azure Workbook Version (Cloud-Based)
**Best for**: Multi-tenant MSPs, enterprises with Azure infrastructure
- Interactive Azure Monitor Workbooks UI
- Azure Functions backend for processing
- Multi-tenant support out of the box
- Managed identity authentication
- Centralized file library with Azure Storage
- Team collaboration features

**Cost**: ~$50/month | **Setup**: ~1 hour | **[Deployment Guide →](DEPLOYMENT.md)**

### 💻 Standalone PowerShell Version (Local)
**Best for**: Individual analysts, small teams, quick deployments
- Menu-driven PowerShell interface
- Runs entirely on your local machine
- Zero cloud infrastructure required
- Secure credential storage (DPAPI)
- Portable and easy to distribute

**Cost**: Free | **Setup**: ~10 minutes | **[Documentation →](standalone/README.md)**

---

## Features

### 🎯 Full Microsoft Defender XDR Capabilities

DefenderXDRC2XSOAR provides **40+ security actions** across the entire Microsoft security stack:

#### 1. **📧 Email Remediation (MDO - Microsoft Defender for Office 365)** - 8 Actions
   - **Soft/Hard Delete Email** - Remove malicious emails from mailboxes
   - **Move to Junk/Inbox** - Quarantine or restore emails
   - **Submit Email Threats** - Report phishing to Microsoft
   - **Submit URL Threats** - Report malicious URLs
   - **Block URLs** - Add time-of-click URL blocking
   - **Remove Mail Forwarding** - Disable external forwarding rules

#### 2. **👤 Identity & Access Management (Entra ID & Identity Protection)** - 6 Actions
   - **Disable/Enable Users** - Control user account access
   - **Reset Passwords** - Force password resets with next sign-in requirement
   - **Confirm User Compromised** - Mark users as compromised for automated response
   - **Dismiss User Risk** - Clear false positive risk detections
   - **Revoke Sessions** - Force sign-out across all devices
   - **Query Risk Detections** - Investigate identity risks

#### 3. **🖥️ Endpoint Security (MDE - Microsoft Defender for Endpoint)** - 11 Actions
   - **Isolate/Unisolate Devices** - Full or selective network isolation
   - **Restrict/Unrestrict App Execution** - Control code execution
   - **Run Antivirus Scans** - Quick or full scans
   - **Collect Investigation Package** - Gather forensic data
   - **Stop & Quarantine Files** - Block malicious files
   - **Offboard Machines** - Remove devices from MDE
   - **Start Automated Investigation** - Trigger AIR investigations
   - **Live Response Operations** - Run scripts, get/put files
   - **View Device Status** - Query device information
   - **Manage Actions** - Track and cancel actions

#### 4. **🔐 Conditional Access & Policies (Entra ID P1+)** - 6 Actions
   - **Create Named Locations** - Define trusted/blocked IP ranges
   - **Update Named Locations** - Modify IP-based policies
   - **Create CA Policies** - Build conditional access rules
   - **Sign-In Risk Policies** - Respond to risky sign-ins
   - **User Risk Policies** - Handle compromised accounts
   - **Query Locations** - Review location policies

#### 5. **📱 Device Management (Intune)** - 6 Actions
   - **Remote Lock** - Lock devices remotely
   - **Wipe Device** - Full or selective wipe
   - **Retire Device** - Remove company data only
   - **Sync Device** - Force policy sync
   - **Run Defender Scan** - Initiate Windows Defender scan
   - **Query Managed Devices** - Get device inventory

#### 6. **☁️ Azure Infrastructure Security** - 5 Actions
   - **Add NSG Deny Rules** - Block IPs/ports at network level
   - **Stop Azure VMs** - Shut down compromised VMs
   - **Disable Storage Public Access** - Secure storage accounts
   - **Remove VM Public IPs** - Eliminate internet exposure
   - **Query Azure VMs** - Get VM inventory

#### 7. **🔍 Threat Intelligence & Hunting**
   - File indicators (SHA1/SHA256 hashes)
   - Network indicators (IPs, URLs, domains)
   - Certificate indicators
   - Advanced KQL hunting queries
   - Custom detection rules
   - Bulk IOC operations

#### 8. **🎯 Incident Management**
   - View and filter security incidents
   - Update incident status and classification
   - Investigation comments and notes
   - Incident summaries and reports
   - Backup and restore detections
   - Rule management and versioning

### 🌟 Workbook-Specific Features

The Azure Workbook version includes additional capabilities:

#### 7. **🖥️ Interactive Console**
   - Shell-like interface for command execution
   - Async execution with auto-polling
   - Automatic JSON parsing and display
   - Configurable refresh intervals
   - Command history and audit trail
   - Real-time status monitoring

#### 8. **📦 File Library Management**
   - Centralized Azure Storage library
   - Upload files once, deploy many times
   - No manual Base64 encoding required
   - One-click deployment to devices
   - Automatic file downloads
   - Team collaboration features
   - See [archive/feature-guides/FILE_OPERATIONS_GUIDE.md](archive/feature-guides/FILE_OPERATIONS_GUIDE.md) for details

---

## Quick Start

### Azure Workbook Version

1. **Create App Registration** with MDE API permissions
2. **Deploy ARM template** to Azure (automated via button or CLI)
3. **Configure federated identity** for managed identity
4. **Access workbook** in Azure Monitor
5. **Start automating** MDE operations

**[→ Full Deployment Guide](DEPLOYMENT.md)** | **[→ Quick Start](QUICKSTART.md)**

### Standalone PowerShell Version

1. **Download** the standalone framework
2. **Run setup script** with your tenant details
3. **Launch menu** and start automating

**[→ Standalone Documentation](standalone/README.md)**

---

## Documentation

### 📘 Core Documentation
- **[README.md](README.md)** - This file (overview and getting started)
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide for Azure version
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contributing guidelines

### 📚 Additional Resources

#### Deployment Documentation
- **[CUSTOMENDPOINT_GUIDE.md](deployment/CUSTOMENDPOINT_GUIDE.md)** - Complete guide for CustomEndpoint and ARM Actions with optional Function Key support
- **[WORKBOOK_PARAMETERS_GUIDE.md](deployment/WORKBOOK_PARAMETERS_GUIDE.md)** - Parameter configuration reference
- **[DYNAMIC_FUNCTION_APP_NAME.md](deployment/DYNAMIC_FUNCTION_APP_NAME.md)** - Dynamic function app naming patterns

#### Examples
- **[examples/customendpoint-example.json](examples/customendpoint-example.json)** - Example workbook demonstrating CustomEndpoint pattern (queryType: 10)
- **[examples/README.md](examples/README.md)** - Examples documentation and pattern comparison
- **[examples/sample-config.md](examples/sample-config.md)** - Sample configuration values

#### Archive
The `/archive` directory contains supplementary documentation:
- **Deployment Guides** - Advanced deployment scenarios and troubleshooting
- **Feature Guides** - Detailed feature documentation and usage examples
- **Technical Docs** - Architecture, implementation details, and API references

**[→ Browse Archive Documentation](archive/README.md)**

---

## Architecture

### Azure Workbook Version

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

### Standalone PowerShell Version

```
┌─────────────────────┐
│  PowerShell Menu UI │
│  (Local Workstation)│
└──────────┬──────────┘
           │
           │ Direct API Calls
           ▼
┌─────────────────────┐
│  App Registration   │
│  (Client Credentials)│
└──────────┬──────────┘
           │
           │ MDE API
           ▼
┌─────────────────────┐
│  Microsoft Defender │
│  for Endpoint       │
└─────────────────────┘
```

**Key Components:**
- **6 Azure Functions** - Consolidated operations (workbook version)
- **DefenderC2Orchestrator** - Unified interface for Live Response and Library operations
- **Azure Storage** - File library for Live Response (workbook version)
- **Managed Identity** - Secure authentication (workbook version)

**[→ Detailed Architecture Documentation](archive/technical-docs/ARCHITECTURE.md)**

---

## Deployment Options Comparison

| Feature | Azure Workbook | Standalone PowerShell | Original MDEAutomator |
|---------|----------------|----------------------|----------------------|
| **User Interface** | Azure Workbook (web) | PowerShell Menu (CLI) | Flask Web App |
| **Authentication** | Managed Identity + Federated | App Registration + Secret | Key Vault |
| **Deployment Complexity** | ARM template (simple) | Copy & run (simplest) | Complex IaC + VNet |
| **Multi-tenancy** | ✅ Built-in | ❌ Single tenant | ✅ Supported |
| **Infrastructure** | Azure Functions + Storage | None (local only) | Azure + OpenAI |
| **Cost** | ~$50/month | **$0** (no Azure) | ~$220/month |
| **Setup Time** | ~1 hour | **~10 minutes** | ~2 hours |
| **File Library** | ✅ Azure Storage (shared) | ❌ Not applicable | ❌ Not included |
| **Team Collaboration** | ✅ Centralized | ❌ Individual | ✅ Centralized |
| **Best For** | Multi-tenant MSPs, teams | Individual analysts, SOC | Large enterprises |
| **Internet Required** | Yes (Azure Portal) | Yes (MDE API) | Yes (Web UI) |

---

## Deployment

The deployment process varies based on your chosen version:

### Azure Workbook Version

**Prerequisites:**
- Azure subscription with permissions to create resources
- Azure AD tenant with permissions to create app registrations
- Global Administrator or Security Administrator role in target MDE tenant

**High-Level Steps:**
1. Create Azure AD App Registration with MDE API permissions
2. Deploy ARM template (Azure Functions + Storage + Workbook)
3. Configure federated identity credential for managed identity
4. Access and configure workbook parameters

**[→ Complete Deployment Guide (DEPLOYMENT.md)](DEPLOYMENT.md)**
**[→ Quick Start (QUICKSTART.md)](QUICKSTART.md)**

### Standalone PowerShell Version

**Prerequisites:**
- Windows PowerShell 5.1+ or PowerShell 7+
- Azure AD App Registration with MDE API permissions

**High-Level Steps:**
1. Download the standalone framework
2. Run the setup script with your credentials
3. Launch the menu and start automating

**[→ Standalone Documentation](standalone/README.md)**

---

## Archived Example Workbooks

This repository includes several archived example workbooks (located in `archive/old-workbooks/`) that demonstrate advanced patterns and features from previous versions:

- **Advanced Workbook Concepts.json** - Comprehensive feature showcase
- **DefenderC2 Advanced Console.json** - Streamlined C2 interface
- **Investigation Insights.json** - Security investigation workflows
- **Sentinel360 XDR Investigation-Remediation Console Enhanced.json** - XDR console
- **Sentinel360-MDR-Console.json** - MDR analyst interface
- **Sentinel360-XDR-Auditing.json** - Audit and compliance reporting

These examples showcase advanced parameter handling, complex visualizations, multi-step workflows, and investigation consoles. They have been superseded by the current **DefenderC2-Workbook.json** which consolidates and enhances all functionality.

**Current Working Workbooks:**
- **[workbook/DefenderC2-Workbook.json](workbook/DefenderC2-Workbook.json)** - Main operational workbook with auto-discovery
- **[workbook/FileOperations.workbook](workbook/FileOperations.workbook)** - File operations and library management

**[→ Learn More About Example Workbooks](archive/feature-guides/WORKBOOK_EXAMPLES.md)**

---

## Using the Azure Workbook

### Primary Workbook

The main operational workbook is located at `/workbook/DefenderC2-Workbook.json` and includes:

#### Core Tabs:
1. **MDEAutomator (Device Actions)** - Isolate, scan, restrict devices
2. **Threat Intelligence Manager** - Manage file/network/certificate indicators
3. **Action Manager** - View and manage device actions
4. **Hunt Manager** - Execute KQL hunting queries
5. **Incident Manager** - Manage security incidents  
6. **Custom Detection Manager** - Manage detection rules

#### Advanced Features:
7. **🖥️ Interactive Console** - Shell-like command interface with async execution
8. **📦 File Operations** - Library management and Live Response file operations

### Interactive Console Usage Example

1. Go to **🖥️ Interactive Console** tab
2. **Configure Settings:**
   - **Auto Refresh Interval**: Select `30 seconds` (recommended)
   - **Command Type**: Choose operation category (e.g., `Device Actions`)
   - **Action/Command**: Select specific action (e.g., `Isolate Device`)
   - **Target Device IDs**: Enter comma-separated device IDs
   - **Additional Parameters**: Add JSON parameters if needed

3. **Execute Command:**
   - Click **Run Query** in the "Execute Command" section
   - Command execution status displays immediately

4. **Monitor Progress:**
   - Status auto-refreshes based on your interval
   - Status indicators: ✅ Succeeded, ⏳ InProgress, ⏸️ Pending, ❌ Failed
   - No manual polling needed

5. **View Results:**
   - Results display in parsed JSON format
   - Export to Excel available
   - Execution history tracked automatically

## Security

### Security Best Practices

#### Azure Workbook Version
1. **Workbook Access Control** - Restrict access using Azure RBAC
2. **Function App Authentication** - Enable Azure AD authentication
3. **Managed Identity** - Always use managed identity instead of secrets
4. **Audit Logging** - Enable diagnostic logs on function app
5. **Network Security** - Consider private endpoints for function app
6. **Script Signing** - Sign all PowerShell scripts before Live Response deployment

#### Standalone Version
1. **Credential Storage** - Uses Windows DPAPI for encryption
2. **Minimal Permissions** - Follow principle of least privilege
3. **Audit Logging** - Log all operations for compliance
4. **Script Review** - Review all scripts before execution
5. **Access Control** - Restrict file system access to framework

## Troubleshooting

### Common Issues

#### Azure Workbook Version
- **Function App Not Responding** - Check function app status in Azure Portal
- **Authentication Errors** - Verify API permissions and federated credentials
- **Workbook Not Loading Data** - Confirm Log Analytics workspace access
- **Library Operations Failing** - Verify Azure Storage connection string

**[→ Detailed Troubleshooting Guide](archive/deployment-guides/DEPLOYMENT_TROUBLESHOOTING.md)**

#### Standalone Version
- **API Authentication Failures** - Verify app registration credentials
- **Permission Errors** - Check API permissions and admin consent
- **Module Not Found** - Run setup script to install dependencies

---

## Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues** - Open GitHub issues for bugs or feature requests
2. **Submit Pull Requests** - Follow our coding standards and guidelines
3. **Improve Documentation** - Help us keep docs up-to-date
4. **Share Examples** - Contribute example workbooks or scripts

**[→ Contributing Guidelines (CONTRIBUTING.md)](CONTRIBUTING.md)**

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Original Project**: [MDEAutomator](https://github.com/msdirtbag/MDEAutomator) by msdirtbag
- **Inspiration**: Azure Sentinel community and security operations teams
- **Contributors**: See GitHub contributors list

---

## Support

### Documentation
- **Core Docs**: README.md, DEPLOYMENT.md, QUICKSTART.md, CONTRIBUTING.md
- **Archive**: `/archive` directory contains detailed feature guides and technical docs

### Community Support
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share experiences

### Related Projects
- **[MDEAutomator](https://github.com/msdirtbag/MDEAutomator)** - Original Python/Flask implementation
- **Microsoft Defender for Endpoint** - Official documentation

---

## Roadmap

Future enhancements being considered:

- ✅ **Consolidated Library Functions** - Already implemented in DefenderC2Orchestrator
- ✅ **File Operations UI** - Interactive workbook tab for file management
- ✅ **Interactive Console** - Shell-like interface with async execution
- 🔄 **Enhanced Multi-tenancy** - Simplified tenant switching
- 🔄 **Scheduled Operations** - Automated recurring tasks
- 🔄 **Advanced Reporting** - Custom dashboards and exports
- 🔄 **Integration Hub** - SOAR platform connectors

---

**Made with ❤️ for the security community**
