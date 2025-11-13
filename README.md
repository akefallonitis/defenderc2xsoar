# DefenderC2 - Unified Microsoft Security Orchestration

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Version**: 3.0.1  
**Status**: Production Ready  
**Last Updated**: November 2025

> **Action-Focused XDR Platform** - 187 remediation actions across Microsoft security stack. Zero compliance bloat.

---

## Overview

Enterprise security orchestration for Microsoft XDR with **worker-based architecture**. Deploy automated security actions across Microsoft Defender for Endpoint (MDE), Microsoft Defender for Office 365 (MDO), Microsoft Defender for Cloud Apps (MCAS), Microsoft Defender for Identity (MDI), Entra ID, Intune, and Azure infrastructure.

### What's New in v3.0.1

- **Action-Focused**: Removed 26 read-only/compliance actions - only remediation left
- **Reduced Permissions**: 13 app permissions (down from 15) - removed `Policy.Read.All` and `AuditLog.Read.All`
- **Azure Firewall**: Added network perimeter blocking (BlockIPInFirewall, BlockDomainInFirewall)
- **Cleaner MDI Worker**: Simplified to 1 action (UpdateAlert) - investigation moved to native portals
- **Clean Codebase**: Removed all legacy references and obsolete documentation
- **AIR Complete**: All Microsoft AIR (Automated Investigation & Response) capabilities covered
- **27 Advanced Actions Identified**: See `MISSING_ADVANCED_ACTIONS.md` for infrastructure security roadmap (Azure SQL, WAF, Arc, Cosmos, Storage, Detonation)

### Architecture

```
DefenderXDRGateway (HTTP Entry Point)
        ↓
DefenderXDROrchestrator (Central Router + 47 Platform Actions)
        ↓
    +-----------------------------------------------------------+
    |       |       |       |       |       |        |          |
   MDE     MDO    MCAS    MDI   EntraID  Intune   Azure   [Diagnostic]
  Worker  Worker  Worker Worker  Worker  Worker   Worker     Check
   (61)    (16)    (15)    (1)     (14)    (15)     (18)       (1)
    ↓       ↓       ↓       ↓       ↓       ↓        ↓
  Device  Email   Cloud  Alert  Identity Device   Infra
  Actions  Sec    Apps   Mgmt     Mgmt    Mgmt     Sec

Total: 10 Azure Functions | 187 Actions | Least Privilege Design

Orchestrator "Platform Actions" (47):
  - Unified Incident Management (10)
  - Advanced Hunting (3)
  - Service Routing (7)
  - Managed Identity Auth (27)
```

### Worker Capabilities

| Worker | Actions | Focus | Example Actions |
|--------|---------|-------|-----------------|
| **MDE** | 61 | Endpoint response | IsolateDevice, RestrictApp, RunAVScan, Live Response (15 actions), IOC management (12 actions) |
| **MDO** | 16 | Email security | SoftDeleteEmails, HardDeleteEmails, MoveToJunk, ZAPPhishing, SubmitEmailThreat, RemoveMailForwarding |
| **MCAS** | 15 | Cloud apps | RevokeOAuthApp, TerminateUserSession, QuarantineFile, SuspendUser, UnscheduleReport |
| **MDI** | 1 | Alert management | UpdateAlert (mark resolved/false positive) |
| **Entra ID** | 14 | Identity protection | DisableUser, ResetPassword, RevokeUserSessions, ConfirmCompromised, DismissRisk, CreateNamedLocation |
| **Intune** | 15 | Device management | RemoteLockDevice, WipeDevice, RetireDevice, RunDefenderScan, UpdateDeviceConfiguration |
| **Azure** | 18 | Infrastructure | AddNSGDenyRule, StopVM, AddAzureFirewallDenyRule, RotateKeyVaultSecret, DisableServicePrincipal |
| **Orchestrator** | 47 | Platform actions: Incidents, Alerts, Hunting, Routing, MI Auth | Multi-service (Graph, MDE, Azure) |

---

## Quick Start

### Prerequisites

1. **Azure Subscription** with permissions to create:
   - Function App (PowerShell 7.4)
   - Storage Account
   - Application Insights
   - Managed Identity with VM Contributor + Network Contributor (optional, for Azure Worker)

2. **App Registration** (multi-tenant supported):
   - Create in Azure AD: `App registrations` → `New registration` → `Multitenant`
   - Generate client secret: `Certificates & secrets` → `New client secret`
   - Configure API permissions (see step 2 below)

### Deployment (3 Steps)

#### 1. Configure App Registration Permissions

```powershell
cd deployment
.\Configure-AppPermissions.ps1 -AppId "your-app-id" -TenantId "your-tenant-id"
```

**Configures 13 permissions:**
- Microsoft Graph API: 10 permissions (User, Device, IdentityRisk, Mail, DeviceManagement)
- Microsoft Defender for Endpoint API: 3 permissions (Machine.Read, Machine.Isolate, Machine.RestrictExecution)

**Grant admin consent** at the URL provided by the script.

#### 2. Deploy Azure Infrastructure

Click **Deploy to Azure** button above, or use CLI:

```powershell
cd deployment
.\Deploy-DefenderC2.ps1 `
  -ResourceGroupName "rg-defenderc2" `
  -FunctionAppName "defenderc2-func-prod" `
  -Location "East US" `
  -AppId "your-app-id" `
  -AppSecret "your-app-secret" `
  -EnableManagedIdentity $true
```

**Deploys:**
- ✅ Function App with 10 functions (Gateway, Orchestrator, 7 workers, DiagnosticCheck)
- ✅ Storage Account (blob/queue/table)
- ✅ Application Insights
- ✅ Managed Identity (optional, for Azure Worker same-tenant operations)
- ✅ RBAC role assignments (if Managed Identity enabled)

**Deployment time**: ~5 minutes

#### 3. Test Deployment

```powershell
cd deployment
.\Test-API-Quick.ps1 -FunctionAppName "defenderc2-func-prod"
```

---

## Usage Examples

### MDE Worker - Isolate Compromised Device

```powershell
$response = Invoke-RestMethod `
  -Uri "https://defenderc2-func-prod.azurewebsites.net/api/DefenderXDRMDEWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<your-key>"} `
  -Body (@{
    action = "IsolateDevice"
    tenantId = "your-tenant-id"
    machineId = "device-id-123"
    isolationType = "Full"
    comment = "Ransomware detected - isolating for containment"
  } | ConvertTo-Json) `
  -ContentType "application/json"
```

### MDO Worker - Hard Delete Phishing Emails

```powershell
$response = Invoke-RestMethod `
  -Uri "https://defenderc2-func-prod.azurewebsites.net/api/DefenderXDRMDOWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<your-key>"} `
  -Body (@{
    action = "HardDeleteEmails"
    tenantId = "your-tenant-id"
    messageIds = @("msg-id-1", "msg-id-2")
  } | ConvertTo-Json) `
  -ContentType "application/json"
```

### Entra ID Worker - Disable Compromised User

```powershell
$response = Invoke-RestMethod `
  -Uri "https://defenderc2-func-prod.azurewebsites.net/api/DefenderXDREntraIDWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<your-key>"} `
  -Body (@{
    action = "DisableUser"
    tenantId = "your-tenant-id"
    userId = "user@contoso.com"
  } | ConvertTo-Json) `
  -ContentType "application/json"
```

### Azure Worker - Block Malicious IP at Network Perimeter

```powershell
$response = Invoke-RestMethod `
  -Uri "https://defenderc2-func-prod.azurewebsites.net/api/DefenderXDRAzureWorker" `
  -Method Post `
  -Headers @{"x-functions-key"="<your-key>"} `
  -Body (@{
    action = "AddAzureFirewallDenyRule"
    tenantId = "your-tenant-id"
    subscriptionId = "sub-id"
    resourceGroup = "rg-network"
    firewallName = "azfw-prod"
    sourceIp = "203.0.113.45"
    ruleName = "Block-Malicious-IP"
  } | ConvertTo-Json) `
  -ContentType "application/json"
```

---

## Configuration

### Environment Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `APPID` | App Registration Client ID | Yes | `12345678-1234-1234-1234-123456789abc` |
| `SECRETID` | App Registration Client Secret | Yes | `your-secret-value` |
| `TENANT_ID` | Primary tenant ID | Optional | `87654321-4321-4321-4321-cba987654321` |
| `AzureWebJobsStorage` | Storage connection string | Auto | `DefaultEndpointsProtocol=https;...` |

**Note**: For same-tenant Azure Worker operations, leave `APPID`/`SECRETID` empty to use Managed Identity automatically.

### Managed Identity (Optional)

Enable Managed Identity for **Azure Worker** same-tenant operations:

**Benefits:**
- No credentials to manage for Azure operations
- Automatic token acquisition
- Subscription-scoped RBAC (VM Contributor + Network Contributor)

**Limitations:**
- Same-tenant only (cannot cross tenant boundaries)
- Does not cover Graph/MDE APIs (still requires App Registration)

**When to enable:**
- You manage Azure VMs, NSGs, Azure Firewall in the **same tenant** as the Function App
- You want credential-free VM stop/start, NSG rule management, firewall rule management

**When to disable:**
- Multi-tenant operations
- No Azure infrastructure actions needed

---

## Documentation

### Deployment

- [**Deployment Guide**](deployment/README.md) - Complete deployment walkthrough
- [**ARM Template Reference**](deployment/azuredeploy.json) - Infrastructure as code
- [**Permission Configuration**](deployment/Configure-AppPermissions.ps1) - One-click permission setup
- [**Function App Deployment**](deployment/FUNCTION_APP_DEPLOYMENT.md) - Manual deployment guide

### Worker API Reference

- [**Worker API Reference**](WORKER_API_REFERENCE.md) - Complete API documentation for all 7 workers
- [**Architecture**](workbook/ARCHITECTURE.md) - System design and worker pattern
- [**Action Catalog**](ACTION_CLEANUP_PLAN.md) - Full list of 187 actions with justification

### Operations

- [**Testing Guide**](deployment/tests/) - Automated testing scripts
- [**Troubleshooting**](deployment/diagnose-function-app.ps1) - Diagnostic utilities
- [**Workbook Guide**](workbook/README.md) - Azure Workbook usage

### Migration

- [**Migration from v3.0.0**](ACTION_CLEANUP_PLAN.md) - Breaking changes and removed actions
- [**Permissions Changes**](deployment/Configure-AppPermissions.ps1) - Updated permission list

---

## Architecture Highlights

### Worker Pattern Benefits

- **Isolation**: Each worker handles one service independently
- **Scalability**: Workers scale independently based on load
- **Maintainability**: Service-specific logic contained in dedicated modules
- **Reliability**: Worker failure doesn't affect other services

### Security Features

- **Least Privilege**: 13 app permissions (down from 15) - only action-focused permissions
- **Managed Identity**: Optional credential-free Azure operations (same-tenant)
- **Token Caching**: 1-hour cache per tenant (reduces API calls)
- **Request Validation**: All inputs validated before execution
- **Audit Logging**: Comprehensive logging to Application Insights

### Performance

- **Cold Start**: ~3-5 seconds (PowerShell 7.4 runtime)
- **Warm Execution**: ~200-500ms per action
- **Concurrency**: Auto-scaling based on load (default: 200 instances max)
- **Storage**: Blob/Queue/Table for file operations and status tracking

---

## FAQ

### Why remove read-only actions?

**v3.0.1 focuses on remediation, not monitoring:**
- ❌ Removed: `GetSecureScore`, `GetAuditLogs`, `GetSignInLogs`, `GetIdentitySecureScore`, `GetDeviceComplianceStatus`, etc.
- ✅ Use native portals for compliance/monitoring (Azure Security Center, Azure AD portal, Intune portal)
- ✅ DefenderC2 is for **incident response**, not compliance dashboards

### When to use Managed Identity?

**Enable if:**
- Same-tenant Azure operations (VMs, NSGs, Azure Firewall)
- Want credential-free VM management

**Disable if:**
- Multi-tenant environment
- No Azure infrastructure actions needed
- Cross-tenant operations

### How is this different from native Microsoft solutions?

**DefenderC2 advantages:**
- **Unified API**: Single endpoint for all Microsoft security products
- **Multi-Tenant**: Lighthouse-ready with tenant isolation
- **Custom Logic**: Add your own orchestration/validation
- **SOAR Integration**: Easy integration with Sentinel, XSOAR, Logic Apps
- **Batch Operations**: Bulk actions across multiple devices/users/emails

**Native solutions advantages:**
- **First-party**: No external dependencies
- **Built-in**: Already included with licenses
- **UI**: Rich user interface for manual operations

---

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit pull request

---

## License

MIT License - See [LICENSE](LICENSE) for details

---

## Support

- **Issues**: [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
- **Discussions**: [GitHub Discussions](https://github.com/akefallonitis/defenderc2xsoar/discussions)
- **Documentation**: [Full Documentation Index](DOCUMENTATION_INDEX.md)

---

## Roadmap

### v3.2.0 (Q1 2025) - Infrastructure Security Enhancement
- [ ] **RotateBitLockerKeys / RotateFileVaultKey** (Intune EPM)
- [ ] **RotateStorageAccountKeys / RevokeStorageSAS** (Storage Security)
- [ ] **BlockSQLIP / DisableSQLPublicAccess** (Azure SQL Security)
- [ ] **BlockIPInWAF / AddWAFCustomRule** (Application Gateway WAF)
- [ ] **IsolateArcServer / RunArcCommand** (Azure Arc Hybrid Security)
- [ ] **RotateCosmosKeys / DisableCosmosPublicAccess** (Cosmos DB Security)
- [ ] **DetonateFile / GetDetonationReport** (File Sandbox Analysis)
- [ ] **DismissSecurityAlert / ApplySecurityRecommendation** (MDC Alert Management)
- [ ] **QuarantineMessage / ReleaseFromQuarantine** (Native Email Quarantine)
- [ ] **27 total advanced actions** - See `MISSING_ADVANCED_ACTIONS.md`

### v3.3.0 (Q2 2025) - Integration & Automation
- [ ] Sentinel incident auto-response
- [ ] Logic Apps connectors
- [ ] XSOAR playbook templates
- [ ] Advanced rate limiting
- [ ] Playbook engine with conditional logic
- [ ] Webhook notifications

### v3.2.0 (Planned)
- [ ] Microsoft Copilot for Security integration
- [ ] Custom detection rule deployment
- [ ] Automated investigation approval
- [ ] Unified incident management

---

**Built with ❤️ for Security Operations Teams**
