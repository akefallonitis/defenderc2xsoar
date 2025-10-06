# Repository Structure

This document describes the organization of the DefenderC2 XSOAR repository.

## 📁 Root Directory

The root directory contains only essential documentation:

- **README.md** - Main project overview, features, and getting started guide
- **DEPLOYMENT.md** - Complete deployment guide for Azure workbook version
- **QUICKSTART.md** - Quick start guide for rapid deployment
- **CONTRIBUTING.md** - Contributing guidelines and standards
- **LICENSE** - Project license

## 📚 Archive Directory (`/archive`)

Historical and detailed documentation organized by category:

### `/archive/deployment-guides/`
Comprehensive deployment documentation:
- AUTOMATED_DEPLOYMENT.md
- COMPLETE_DEPLOYMENT.md
- DEPLOYMENT_ENHANCEMENTS.md
- DEPLOYMENT_TROUBLESHOOTING.md
- QUICK_DEPLOY_GUIDE.md
- QUICKSTART_FUNCTIONS.md

### `/archive/feature-guides/`
In-depth feature documentation:
- FILE_OPERATIONS_GUIDE.md
- FILE_OPERATIONS_TESTING.md
- INTERACTIVE_CONSOLE_GUIDE.md
- LIBRARY_SETUP.md
- WORKBOOK_ADVANCED_FEATURES.md
- WORKBOOK_EXAMPLES.md
- WORKBOOK_FILE_OPERATIONS.md

### `/archive/technical-docs/`
Technical implementation details:
- ARCHITECTURE.md
- CHANGES.md
- CHANGELOG.md
- FEATURES.md
- FUNCTIONS_REFERENCE.md
- IMPLEMENTATION.md
- LIVE_RESPONSE_IMPLEMENTATION.md
- MIGRATION_NOTES.md

## 🔧 Functions Directory (`/functions`)

Azure Functions implementation (PowerShell):

- **DefenderC2Automator/** - Shared PowerShell module
- **DefenderC2CDManager/** - Custom Detection Manager function
- **DefenderC2Dispatcher/** - Device action dispatcher function
- **DefenderC2HuntManager/** - Advanced Hunting Manager function
- **DefenderC2IncidentManager/** - Incident Manager function
- **DefenderC2Orchestrator/** - **Live Response and Library Operations orchestrator**
- **DefenderC2TIManager/** - Threat Intelligence Manager function

**Note:** Library operations (`ListLibraryFiles`, `GetLibraryFile`, `DeleteLibraryFile`) are consolidated into DefenderC2Orchestrator.

## 📊 Workbook Directory (`/workbook`)

Azure Monitor Workbooks:

- **DefenderC2-Workbook.json** - Main DefenderC2 Command & Control Console with enhanced auto-discovery
- **FileOperations.workbook** - File operations workbook

## 💻 Standalone Directory (`/standalone`)

Local PowerShell framework (no Azure required):

- Menu-driven UI
- Secure credential storage
- All MDE operations
- See `standalone/README.md` for details

## 🚀 Deployment Directory (`/deployment`)

ARM templates and deployment scripts:

- **azuredeploy.json** - Main ARM template
- **azuredeploy.parameters.json** - Parameter template
- **workbook-deploy.json** - Workbook deployment template
- **createUIDefinition.json** - Azure Portal UI definition
- **metadata.json** - Marketplace metadata

## 📝 Example Workbooks (Root)

Example workbooks demonstrating advanced patterns:

- Advanced Workbook Concepts.json
- DefenderC2 Advanced Console.json
- Investigation Insights.json
- Investigation Insights Original.json
- Sentinel360 XDR Investigation-Remediation Console Enhanced.json
- Sentinel360-MDR-Console.json
- Sentinel360-MDR-Console-v1.json
- Sentinel360-XDR-Auditing.json

## 🔍 Key Architectural Decisions

### Library Functions Consolidation

The three library functions were consolidated into `DefenderC2Orchestrator`:
- **ListLibraryFiles** - List all files in Azure Storage library
- **GetLibraryFile** - Retrieve file from library (Base64 encoded)
- **DeleteLibraryFile** - Delete file from library

This consolidation:
- Reduces function count from 11 to 6
- Provides unified interface for Live Response operations
- Simplifies deployment and maintenance
- Follows single responsibility principle at the orchestrator level

### Documentation Organization

Documentation was reorganized to reduce root directory clutter:
- **Before**: 25+ markdown files in root directory
- **After**: 4 core files in root + organized archive

Benefits:
- Easier navigation for new users
- Clear separation of essential vs reference documentation
- Better discoverability through categorization
- Maintains all historical documentation for reference

## 🔗 Navigation

- **Getting Started**: Start with README.md
- **Deployment**: See DEPLOYMENT.md or QUICKSTART.md
- **Contributing**: See CONTRIBUTING.md
- **Detailed Documentation**: Browse `/archive` directory
- **Standalone Version**: See `/standalone/README.md`
