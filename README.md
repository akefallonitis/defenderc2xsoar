# DefenderXDR - Unified Microsoft Security Operations Platform

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Version:** 2.4.0 | **Status:** Production Ready | **Last Updated:** November 11, 2025

Enterprise unified security orchestration platform for Microsoft XDR. Deploy 227 automated security actions across Microsoft Defender for Endpoint, Office 365, Cloud, Identity, Entra ID, Intune, and Azure with a single click.

---

##  Overview

DefenderXDR provides a unified orchestration layer for all Microsoft security products with:

- **🎯 Master Orchestrator** - Single API endpoint for cross-product operations
- **📋 Specialized Managers** - Purpose-built functions for each security domain
- **⚙️ Service Workers** - Product-specific automation engines
- **🔄 Multi-Tenant** - Lighthouse-ready with tenant isolation
- **📊 Interactive Workbook** - Command & control console with live operations

### Architecture

```
DefenderXDROrchestrator (Master)
├── DefenderXDRDispatcher         → Device Actions (Isolate, Scan, Restrict)
├── DefenderXDRManager             → Multi-Product Operations (MDO, EntraID, Intune, Azure)
├── DefenderXDRLiveResponseManager → Live Response & Library Operations
├── DefenderXDRCustomDetectionManager → Custom Detection Rules
├── DefenderXDRHuntManager         → Advanced Hunting (KQL)
├── DefenderXDRIncidentManager     → Incident Management
├── DefenderXDRThreatIntelManager  → Threat Intelligence Indicators
├── DefenderXDREndpointManager     → Extended MDE Operations
└── Workers (6 specialized)
    ├── AzureWorker        → Azure infrastructure (8 actions)
    ├── EntraIDWorker      → Identity & access (13 actions)
    ├── IntuneWorker       → Device management (8 actions)
    ├── MDCWorker          → Cloud security (6 actions)
    ├── MDIWorker          → Identity threats (11 actions)
    └── MDOWorker          → Email security (4 actions)
```

**Total: 15 Functions | 227 Actions | 100% DefenderXDR Branded**

---

##  Quick Start

### 1. Prerequisites

Create **Multi-Tenant App Registration** with API permissions:
- Microsoft Graph (Security, User, Device)
- Windows Defender ATP (Machine, Alert, Incident)
- Azure Service Management
- Office 365 Exchange

> **Note**: Youll need to provide your multi-tenant App Registration credentials with appropriate permissions during deployment. See [PERMISSIONS.md](PERMISSIONS.md) for complete permission requirements.

[Complete Permissions List ](PERMISSIONS.md)

### 2. Deploy

Click **Deploy to Azure** button above or use Azure CLI:

```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file deployment/azuredeploy.json \
  --parameters \
    functionAppName=<unique-name> \
    spnId=<app-id> \
    spnSecret=<secret>
```

**Deploys:** Function App + Application Insights + Storage + Workbook

### 3. Test

```powershell
$response = Invoke-RestMethod `
  -Uri "https://<your-app>.azurewebsites.net/api/EntraIDWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<key>"} `
  -Body (@{
    action="GetUser"
    tenantId="xxx"
    userId="user@domain.com"
  }|ConvertTo-Json) `
  -ContentType "application/json"
```

---

##  Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Architecture](#architecture)
- [Usage Examples](#usage-examples)
- [Security](#security)
- [Monitoring](#monitoring)
- [Updates](#updates)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

##  Documentation

| Guide | Description |
|-------|-------------|
| **[Deployment Guide](deployment/V2.3.0_DEPLOYMENT_GUIDE.md)** | Complete deployment walkthrough |
| **[API Reference](WORKER_ACTIONS_QUICKREF.md)** | All 50 actions with examples |
| **[Architecture](WORKER_PATTERN_ARCHITECTURE.md)** | Design patterns & scaling |
| **[Permissions](PERMISSIONS.md)** | Required API permissions |
| **[Updates](deployment/PACKAGE_UPDATE_PROCESS.md)** | Update deployed functions |
| **[Migration](MIGRATION_GUIDE.md)** | Upgrade from v2.x |

---

##  Architecture

```
Client  Worker Functions  Shared Modules  Microsoft APIs
         (MDO, MDC, MDI,    (Auth, Validation,
          EntraID, Intune,   Logging)
          Azure)
```

**Key Features:**
-  Direct HTTP responses (workbook compatible)
-  Independent scaling per product
-  Centralized authentication with token caching
-  Multi-tenant support
-  Auto-update via WEBSITE_RUN_FROM_PACKAGE

---

##  Usage Examples

### Email Remediation

```json
POST /api/MDOWorker
{
  "action": "RemediateEmail",
  "tenantId": "xxx",
  "messageId": "AAMkAGI2...",
  "remediationType": "SoftDelete"
}
```

### Account Compromise Response

```json
POST /api/EntraIDWorker
{
  "action": "RevokeSessions",
  "tenantId": "xxx",
  "userId": "compromised@domain.com"
}
```

### Cloud Alert Management

```json
POST /api/MDCWorker
{
  "action": "GetSecurityAlerts",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "filter": "properties/severity eq ''High''"
}
```

[All 50 Actions ](WORKER_ACTIONS_QUICKREF.md)

---

##  Security

- **Service Principal Auth** - Least privilege permissions
- **Function Keys** - Per-function authentication
- **Token Caching** - Secure in-memory with tenant isolation
- **Managed Identity** - Optional for Azure resources
- **Network Restrictions** - Production environment recommended

[Security Best Practices ](deployment/V2.3.0_DEPLOYMENT_GUIDE.md#security-best-practices)

---

##  Monitoring

### Application Insights

```kql
// Worker performance
requests
| where name endswith "Worker"
| summarize Count=count(), AvgDuration=avg(duration) by name

// Error tracking
exceptions
| where cloud_RoleName contains "Worker"
| summarize Count=count() by type, outerMessage
```

---

##  Updates

### Update Function Code

1. Edit code in `functions/` directory
2. Create package: `deployment\create-package.ps1`
3. Commit: `git add deployment/function-package.zip && git commit && git push`
4. Auto-deploy: Function apps update in 5-10 minutes

[Update Process ](deployment/PACKAGE_UPDATE_PROCESS.md)

---

##  Repository Structure

```
defenderc2xsoar/
 functions/               # Worker functions
    MDOWorker/          # Email security
    MDCWorker/          # Cloud security
    MDIWorker/          # Identity threats
    EntraIDWorker/      # IAM
    IntuneWorker/       # Device management
    AzureWorker/        # Infrastructure
    DefenderXDRC2XSOAR/ # Shared modules
 deployment/              # ARM templates & package
 workbook/               # Azure Workbook definitions
 docs/                   # Documentation
```

---

##  Troubleshooting

| Issue | Solution |
|-------|----------|
| Function not appearing | Check Application Insights logs, verify function.json |
| Auth errors | Verify API permissions granted, check app settings |
| Package not updating | Restart function app, verify GitHub URL accessible |

[Full Troubleshooting Guide ](deployment/V2.3.0_DEPLOYMENT_GUIDE.md#troubleshooting)

---

##  Contributing

1. Fork repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request

**Guidelines:**
- PowerShell best practices
- Error handling for external calls
- Update documentation
- Application Insights logging

---

##  Support

- **Documentation:** [Full Index](DOCUMENTATION_INDEX.md)
- **Issues:** [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
- **Discussions:** [GitHub Discussions](https://github.com/akefallonitis/defenderc2xsoar/discussions)

---

##  Roadmap

### v2.3.x (Current)
-  6 specialized workers
-  50 security actions
-  One-click deployment
-  Auto-update mechanism

### v2.4.0 (Planned)
- Microsoft Purview integration
- Sentinel native connector
- Enhanced workbook dashboards
- Rate limiting per tenant

### v3.0.0 (Future)
- GraphQL API
- Custom action framework
- Workflow orchestration
- Multi-cloud support

---

##  License

MIT License - See [LICENSE](LICENSE) file

---

##  Statistics

- **50 Actions** across 6 Microsoft products
- **6 Workers** for product-specific operations
- **19 Service Modules** for API integrations
- **Multi-Tenant** with token caching
- **Auto-Scaling** per worker
- **Production Ready** with error handling

---

**Built for security teams who automate. Deploy in minutes, respond in seconds.** 
