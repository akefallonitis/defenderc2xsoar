# DefenderXDR - Unified Microsoft Security Operations Platform

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

# DefenderC2 for Azure Sentinel / XSOAR

**Version**: 3.0.1  
**Last Updated**: November 2025  
**Status**: Production Ready

**Focus**: Action-oriented XDR remediation (187 actions) - no compliance/monitoring bloat

Enterprise unified security orchestration platform for Microsoft XDR. Deploy **213+ automated security actions** across Microsoft Defender for Endpoint, Office 365, Cloud Apps, Identity, Entra ID, Intune, and Azure with **Worker-based architecture** and **Live Response file library**.

---

##  Overview

DefenderXDR v3.0.0 provides unified orchestration with **Worker-based architecture**:

- **?? Central Gateway** - Single authenticated entry point
- **?? Service Orchestrator** - Intelligent routing to specialized Workers
- **?? 9 Service Workers** - Dedicated processors for each Microsoft security product
- **?? Multi-Tenant** - Lighthouse-ready with tenant isolation
- **?? Live Response Library** - Blob Storage for scripts, tools, forensic files
- **?? Interactive Workbook** - Command & control console with live operations

### v3.0.0 Architecture (Worker Pattern)

```
DefenderXDRGateway (Entry Point)
        ?
DefenderXDROrchestrator (Central Routing)
        ?
    +------------------------------------------------------------------+
    ?       ?       ?       ?       ?         ?        ?        ?      ?
   MDE     MDO    MCAS    MDI   EntraID   Intune   Azure   (2 more)
  Worker  Worker  Worker Worker  Worker   Worker  Worker
   (52)    (12)    (14)   (11)    (20)     (18)    (22)
    ?       ?       ?       ?       ?         ?        ?
  Device  Email   Cloud  Identity  IAM    Device    Infra
  Actions Security Apps   Threats  Mgmt    Mgmt     Sec

Shared Infrastructure:
+- Storage Account (Managed Identity secured)
¦  +- Blob Storage     ? Live Response file library (scripts/uploads/downloads)
¦  +- Queue Storage    ? Bulk operation queuing
¦  +- Table Storage    ? Status tracking (XDROperationStatus)
+- IntegrationBridge   ? 21 shared modules (Auth, Validation, Logging, Service-specific)
+- AuthManager         ? OAuth token caching (per tenant, 1-hour cache)
```

**Total: 11 Functions | 213 Actions | Managed Identity Secured**

**Action Breakdown**:
- **MDE Worker**: 52 actions (device, investigation, Live Response, indicators, hunting)
- **Azure Worker**: 22 actions (resources, NSG, VMs, Security Center, Key Vault)
- **Entra ID Worker**: 20 actions (users, groups, risky sign-ins, conditional access)
- **Intune Worker**: 18 actions (devices, compliance, remote actions, BitLocker)
- **MCAS Worker**: 14 actions (alerts, activities, files, governance, policies)
- **MDO Worker**: 12 actions (email remediation, quarantine, threats)
- **MDI Worker**: 11 actions (alerts, lateral movement, exposed credentials)

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

### 3. Test MDE Worker with Live Response

```powershell
# Upload script to Live Response library
$scriptContent = Get-Content "forensics.ps1" -Raw
$scriptBytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
$scriptBase64 = [Convert]::ToBase64String($scriptBytes)

$uploadResponse = Invoke-RestMethod `
  -Uri "https://<your-app>.azurewebsites.net/api/DefenderXDRMDEWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<key>"} `
  -Body (@{
    action="UploadScript"
    tenantId="xxx"
    fileName="forensics.ps1"
    content=$scriptBase64
  }|ConvertTo-Json) `
  -ContentType "application/json"

# Run script on device via Live Response
$runResponse = Invoke-RestMethod `
  -Uri "https://<your-app>.azurewebsites.net/api/DefenderXDRMDEWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<key>"} `
  -Body (@{
    action="RunScript"
    tenantId="xxx"
    machineId="device-id"
    scriptName="forensics.ps1"
  }|ConvertTo-Json) `
  -ContentType "application/json"

# Download file from device
$getFileResponse = Invoke-RestMethod `
  -Uri "https://<your-app>.azurewebsites.net/api/DefenderXDRMDEWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<key>"} `
  -Body (@{
    action="GetFile"
    tenantId="xxx"
    machineId="device-id"
    filePath="C:\Windows\System32\winevt\Logs\Security.evtx"
  }|ConvertTo-Json) `
  -ContentType "application/json"

# Response includes 24-hour SAS URL for download
$sasUrl = $getFileResponse.data.blobDownloadUrl
Invoke-WebRequest -Uri $sasUrl -OutFile "Security.evtx"
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
