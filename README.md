# DefenderC2 XSOAR

[![Deploy Azure Functions](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-azure-functions.yml/badge.svg)](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-azure-functions.yml)
[![Deploy Workbook](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-workbook.yml/badge.svg)](https://github.com/akefallonitis/defenderc2xsoar/actions/workflows/deploy-workbook.yml)

**Command & Control for Microsoft Defender for Endpoint** - A modern automation platform inspired by [MDEAutomator](https://github.com/msdirtbag/MDEAutomator), offering flexible deployment options for security operations teams.

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

DefenderC2 XSOAR provides comprehensive automation for Microsoft Defender for Endpoint (MDE) through **two flexible deployment approaches**:

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

### 🎯 Core Capabilities

Both deployment options provide comprehensive MDE automation:

#### 1. **Device Actions (Defender C2)**
   - Isolate/Unisolate devices
   - Collect investigation packages
   - Run antivirus scans
   - Restrict/Unrestrict app execution
   - Stop & quarantine files
   - Live Response operations (run scripts, get/put files)

#### 2. **Threat Intelligence Management**
   - File indicators (SHA1/SHA256 hashes)
   - Network indicators (IPs, URLs, domains)
   - Certificate indicators
   - Bulk operations via CSV import
   - Custom detection rule management

#### 3. **Action Management**
   - View recent machine actions
   - Check action status
   - Cancel pending actions (safety switch)
   - View action results and outputs

#### 4. **Advanced Hunting**
   - Execute KQL queries against MDE
   - Scheduled hunting operations
   - Query library management
   - Result analysis and export

#### 5. **Incident Management**
   - View and filter security incidents
   - Update incident status and classification
   - Investigation comments and notes
   - Incident summaries and reports

#### 6. **Custom Detection Rules**
   - List custom detection rules
   - Create/update/delete rules
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

## Example Workbooks

This repository includes several example workbooks demonstrating advanced patterns and features:

- **Advanced Workbook Concepts.json** - Comprehensive feature showcase
- **DefenderC2 Advanced Console.json** - Streamlined C2 interface
- **Investigation Insights.json** - Security investigation workflows
- **Sentinel360 XDR Investigation-Remediation Console Enhanced.json** - XDR console
- **Sentinel360-MDR-Console.json** - MDR analyst interface
- **Sentinel360-XDR-Auditing.json** - Audit and compliance reporting

These examples showcase advanced parameter handling, complex visualizations, multi-step workflows, and investigation consoles that you can adapt for your environment.

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
