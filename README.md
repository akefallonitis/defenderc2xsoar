# Microsoft Defender XDR Integration Platform v3.4.0

**Complete Security Orchestration & Automated Response (SOAR)** for Microsoft 365 Defender

🎯 **246 Actions** | 🔧 **9 Functions** | ⚡ **3 Core Modules** | 🛡️ **7 Security Services**

---

## 🚀 Quick Deploy

```powershell
# 1. Deploy ARM Template
az deployment group create \
  --resource-group your-rg \
  --template-file deployment/azuredeploy.json \
  --parameters deployment/azuredeploy.parameters.json

# 2. Grant API Permissions (see PERMISSIONS.md)
# 3. Test deployment
curl https://your-function-app.azurewebsites.net/api/Gateway?code=YOUR_KEY
```

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

---

## 📊 Platform Overview

### Architecture
```
Azure Sentinel / Custom Client
         ↓ HTTPS
    [Gateway] ← Public API
         ↓
  [Orchestrator] ← Routing + Batch
         ↓
    ┌────┴─────────────────────────┐
    ↓                               ↓
[IncidentWorker] [Service Workers x6]
    ↓                               ↓
Microsoft Graph / Security APIs
```

### Functions (9 Total)

| Function | Purpose | Actions |
|----------|---------|---------|
| **Gateway** | Public HTTP entry | N/A |
| **Orchestrator** | Internal routing | N/A |
| **IncidentWorker** | Incident/alert mgmt | 27 |
| **AzureWorker** | Azure infra security | 52 |
| **MDEWorker** | Endpoint protection | 52 |
| **MDOWorker** | Email security | 25 |
| **MCASWorker** | Cloud app security | 23 |
| **EntraIDWorker** | Identity protection | 34 |
| **IntuneWorker** | Device management | 33 |

**Total: 246 actions** across 7 security services

---

## 🎯 Key Features

✅ **Complete Coverage** - All Microsoft Defender XDR portal capabilities  
✅ **Batch Operations** - Comma-separated values for bulk processing  
✅ **Multi-Tenant** - Isolated tenant-specific authentication  
✅ **High Performance** - ~5s cold start, <300ms warm execution  
✅ **Production Ready** - Application Insights, error handling, logging  
✅ **Zero Config Deploy** - GitHub source control (no zip files)

---

## 🔐 Required Permissions

### Microsoft Graph API
- `SecurityIncident.Read.All` + `SecurityIncident.ReadWrite.All`
- `SecurityAlert.Read.All` + `SecurityAlert.ReadWrite.All`
- `User.ReadWrite.All` + `Directory.ReadWrite.All`
- `DeviceManagementManagedDevices.ReadWrite.All`

### Microsoft Defender ATP API
- `Machine.Isolate` + `Machine.RestrictExecution`
- `Machine.Scan` + `Machine.CollectForensics`
- `Ti.ReadWrite.All` + `AdvancedQuery.Read.All`

**Full list**: See [PERMISSIONS.md](PERMISSIONS.md)

---

## 📝 Usage Example

```bash
POST https://your-function-app.azurewebsites.net/api/Gateway
Content-Type: application/json
x-functions-key: YOUR_FUNCTION_KEY

{
  "service": "MDE",
  "action": "IsolateDevice",
  "tenantId": "your-tenant-id",
  "deviceIds": "device1,device2,device3",
  "comment": "Security incident response"
}
```

---

## 📊 Action Categories

### Incident & Alert Management (27)
Get, Update, Assign, Close, Reopen incidents | Resolve, Suppress, Classify alerts | Bulk operations

### Microsoft Defender for Endpoint (52)
Device isolation, Antivirus scans, Live response | Threat indicators, Vulnerability management

### Microsoft Defender for Office 365 (25)
Email remediation, Quarantine management | Block senders, ZAP operations

### Cloud App Security (23)
OAuth app management, DLP policies | Session control, Activity monitoring

### Entra ID (34)
Password reset, Session revocation | Conditional Access, PIM, Risk management

### Intune (33)
Device wipe/reset/lock | BitLocker encryption, Compliance updates

### Azure Security (52)
VM isolation (NSG rules) | Storage/SQL security | Defender for Cloud automation

---

## 🔍 Monitoring

### Application Insights (Built-in)
```kusto
// Recent requests
requests
| where timestamp > ago(1h)
| project timestamp, name, resultCode, duration

// Errors
exceptions
| where timestamp > ago(1h)
| project timestamp, outerMessage
```

---

## 🚀 Deployment

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

### Quick Start
1. Deploy ARM template (`deployment/azuredeploy.json`)
2. Grant API permissions (use `deployment/Configure-AppPermissions.ps1`)
3. Test via Gateway API
4. (Optional) Deploy workbook (`workbook/DefenderXDR-Complete.json`)

---

## 📚 Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment
- **[PERMISSIONS.md](PERMISSIONS.md)** - Complete API permissions
- **[V3.4.0_RELEASE_NOTES.md](V3.4.0_RELEASE_NOTES.md)** - What's new
- **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** - Full docs catalog

---

## 🔄 Version 3.4.0 (Nov 14, 2025)

✅ Module consolidation (5 → 3 modules)  
✅ New IncidentWorker (27 actions)  
✅ Actions increased (219 → 246)  
✅ Performance improved (-1s cold start)  
✅ Production ready deployment

---

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
- **Documentation**: [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- **Monitoring**: Application Insights logs

---

**Status**: ✅ Production Ready | **Platform**: Azure Functions (PowerShell 7.4) | **License**: MIT
