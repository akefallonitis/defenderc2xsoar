# Microsoft Defender XDR to Azure Sentinel SOAR Integration

**Version 3.4.0** - Complete XDR Remediation + Incident/Alert Management

## Overview

Comprehensive Azure Function App integrating Microsoft Defender XDR with Azure Sentinel, providing **246 automated remediation actions** across the entire Microsoft security stack. This solution enables Security Operations Centers (SOCs) to orchestrate automated response workflows directly from Azure Sentinel.

### Key Capabilities

- ✅ **246 Total Actions** - Complete coverage of Microsoft Defender XDR + incident/alert management
- ✅ **7 Security Services** - Incidents/Alerts, MDE, MDO, MCAS, EntraID, Intune, Azure Security
- ✅ **Batch Processing** - Comma-separated values for bulk operations on all actions
- ✅ **Unified Architecture** - 9 functions, 3 streamlined modules, optimized cold start
- ✅ **Multi-Tenant** - Isolated execution with tenant-specific authentication
- ✅ **Workbook Integration** - Azure Sentinel Workbook for visual management
- ✅ **Enterprise Ready** - Production-grade error handling, Application Insights tracking

## Architecture

```
Azure Sentinel Playbooks
         ↓
    HTTP Request
         ↓
   [DefenderXDRGateway] ← Entry point + Action Tracking
         ↓
 [DefenderXDROrchestrator] ← Routing logic
         ↓
    ┌────┴────────────────────────────────┐
    ↓              ↓              ↓       ↓
[MDE Worker] [MDO Worker] [MCAS Worker] ...
    ↓              ↓              ↓       ↓
Microsoft Graph API / Security APIs
```

### Components

| Component | Purpose | Actions |
|-----------|---------|---------|
| **Gateway** | HTTP entry, routing | N/A |
| **Orchestrator** | Service routing, batch processing | N/A |
| **Incident Worker** | Incident/alert management | 27 |
| **MDE Worker** | Endpoint security operations | 52 |
| **MDO Worker** | Email security operations | 25 |
| **MCAS Worker** | Cloud app security | 23 |
| **EntraID Worker** | Identity protection, PIM, CA | 34 |
| **Intune Worker** | Device management | 33 |
| **Azure Worker** | Azure infrastructure security | 52 |

**Total**: 246 remediation actions (219 existing + 27 incident/alert)  
**Modules**: 3 core modules (AuthManager, ValidationHelper, LoggingHelper)  
**Batch Support**: ✅ All actions support comma-separated values for bulk operations

## Action Coverage by Service

### Microsoft Defender for Endpoint (MDE) - 52 Actions

**Device Isolation & Remediation**
- Device isolation/unisolation, containment, antivirus scans
- Live response command execution, file operations
- Machine restart, app restriction, network isolation

**Vulnerability Management (TVM)**
- Trigger vulnerability scans, apply security baselines
- Remediate vulnerabilities, exclude false positives
- Deploy security updates, block vulnerable software

**Network Protection**
- Enable network protection, block certificates
- Block ports/protocols, web content filtering
- Network destination blocking

**Custom Detection**
- Create/update/delete custom detection rules
- Enable/disable detection rules

**File & URL Management**
- Block/unblock files, URLs, IP addresses
- Certificate management, indicator operations

### Microsoft Defender for Office 365 (MDO) - 25 Actions

**Email Remediation**
- Soft/hard delete emails, move to junk/inbox
- Bulk email search and deletion
- ZAP (Zero-hour Auto Purge) for phishing/malware

**Quarantine Management**
- Release/delete quarantined emails
- Bulk quarantine operations
- Export quarantine reports, update policies

**Advanced Email Security**
- Block sender domains, manage safe sender lists
- Update spam filter policies
- Enable ATP Safe Attachments

**Phishing Response**
- Report phishing campaigns, block phishing URLs
- Remove phishing emails by subject/sender
- Trace email delivery paths
- Create phishing simulations

### Microsoft Cloud App Security (MCAS) - 23 Actions

**OAuth & App Management**
- Revoke OAuth permissions, ban risky apps
- Revoke user consent, remove app access

**Session Management**
- Terminate active sessions, block users from apps
- Require re-authentication

**Data Loss Prevention (DLP)**
- Apply DLP policies to cloud apps
- Block file downloads, revoke file sharing
- Delete sensitive files

**Shadow IT Control**
- Ban/sanction cloud applications
- Block app categories, enable app governance

**Session Policies**
- Create session control policies
- Block downloads during sessions
- Enable monitor-only mode, force re-authentication

**File Management**
- Quarantine cloud files, remove external sharing
- Apply sensitivity labels, restore from quarantine

### EntraID (Azure AD) - 34 Actions

**Identity Protection**
- Confirm user compromised/safe, dismiss risky users
- Force password reset, block sign-ins
- Revoke user sessions, reset MFA registration
- Disable user risk, enable identity protection

**Privileged Identity Management (PIM)**
- Revoke PIM activations, deny PIM requests
- Remove from PIM roles, audit PIM activations
- Enable PIM alerts, expire PIM assignments

**Conditional Access**
- Create emergency break-glass policies
- Block country/locations, require MFA for roles
- Block legacy authentication, enable risk policies
- Simulate CA policies (What-If analysis)

**Emergency Response**
- Delete authentication methods, create named locations
- Remove admin roles, delete all MFA methods
- Create emergency CA policies

### Microsoft Intune - 33 Actions

**Device Management**
- Remote lock, wipe, retire, sync devices
- Defender scans, reset passcode
- Reboot, shutdown, enable lost mode

**Encryption Management**
- Enable/disable BitLocker, rotate recovery keys
- Get BitLocker recovery keys
- Enable/rotate FileVault (macOS)

**Device Configuration**
- Deploy/remove configuration profiles
- Enable firewall, disable USB storage
- Enable device encryption, block camera

**App Management**
- Uninstall apps, block app execution
- Wipe app data, remove managed apps

**Endpoint Privilege Management (EPM)**
- Revoke elevations, block elevation requests

### Azure Security - 52 Actions

**Storage Account Security**
- Rotate storage keys, revoke SAS tokens
- Enable storage firewall, Defender for Storage
- Block container access, disable soft delete

**SQL Security**
- Block SQL IPs, disable public access
- Rotate SQL passwords, enable auditing
- Enable Transparent Data Encryption (TDE)

**Azure Arc**
- Isolate Arc servers, run commands
- Enable Defender for Arc, disconnect servers

**Web Application Firewall (WAF)**
- Block IPs in WAF, add custom rules
- Enable prevention mode, block geo-locations

**App Service**
- Stop/restart app services
- Enable Defender for App Service
- Disable authentication (emergency)

**Containers**
- Quarantine container images
- Delete pods, restart AKS nodes

**Microsoft Defender for Cloud (MDC)**
- Enable Defender plans, apply recommendations
- Exclude vulnerabilities, enable JIT VM access
- Block JIT requests, enable adaptive network hardening

**Azure Sentinel**
- Add to watchlists, enable playbooks

## Action Tracking & Auditing

Built-in comprehensive action tracking system:

- **Action History**: Complete audit trail of all operations
- **Progress Monitoring**: Real-time progress for long-running actions
- **Cancellation Support**: Request cancellation of in-flight operations
- **Audit Logging**: Export logs in JSON, CSV, or SIEM (CEF) format
- **Correlation IDs**: Track related operations across services
- **Tenant Isolation**: Multi-tenant tracking with data segregation

Storage: Azure Table Storage (PartitionKey=TenantId, RowKey=ActionId)

## Deployment

### Prerequisites

- Azure Subscription
- Azure Sentinel workspace
- App Registration with required permissions (see PERMISSIONS.md)
- PowerShell 7.2+ (local deployment)

### Quick Deploy - Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

### Manual Deployment

1. **Create App Registration**
   ```powershell
   # See deployment/Configure-AppPermissions.ps1
   .\deployment\Configure-AppPermissions.ps1 -TenantId "your-tenant-id"
   ```

2. **Deploy Function App**
   ```powershell
   # See deployment/Deploy-DefenderC2.ps1
   .\deployment\Deploy-DefenderC2.ps1 `
       -ResourceGroupName "rg-defenderxdr" `
       -Location "eastus" `
       -AppId "app-registration-id" `
       -ClientSecret "app-secret"
   ```

3. **Deploy Workbook**
   ```powershell
   # Deploy Azure Sentinel Workbook
   az deployment group create `
       --resource-group "rg-sentinel" `
       --template-file "workbook/workbook-deploy.json" `
       --parameters "@workbook/workbook-deploy.parameters.json"
   ```

### Configuration

**Required App Settings**:
```json
{
  "APPID": "your-app-registration-id",
  "SECRETID": "your-client-secret",
  "AzureWebJobsStorage": "storage-connection-string"
}
```

**Required API Permissions**:
- Microsoft Graph: SecurityEvents.ReadWrite.All, User.ReadWrite.All, Directory.ReadWrite.All
- Microsoft Threat Protection: SecurityIncident.ReadWrite.All, Machine.ReadWrite.All
- See PERMISSIONS.md for complete list

## Usage

### Direct API Calls

```bash
# Isolate a device
POST https://your-function-app.azurewebsites.net/api/Gateway
{
  "action": "IsolateDevice",
  "tenantId": "your-tenant-id",
  "service": "MDE",
  "body": {
    "deviceId": "device-id",
    "isolationType": "Full",
    "comment": "Ransomware detected"
  }
}
```

### Azure Sentinel Playbook

```json
{
  "type": "Http",
  "inputs": {
    "method": "POST",
    "uri": "https://your-function-app.azurewebsites.net/api/Gateway",
    "body": {
      "action": "@{variables('action')}",
      "tenantId": "@{variables('tenantId')}",
      "service": "MDE",
      "body": {
        "deviceId": "@{triggerBody()?['SystemAlertId']}"
      }
    }
  }
}
```

### Azure Sentinel Workbook

1. Navigate to Azure Sentinel → Workbooks
2. Open "Defender XDR Remediation Actions"
3. Select service, action, and parameters
4. Click "Execute Action"
5. Monitor progress in Action History tab

## Monitoring & Troubleshooting

### Application Insights

All operations logged to Application Insights:
- Request/response traces
- Performance metrics
- Error tracking
- Dependency calls

### Diagnostic Endpoint

```bash
GET https://your-function-app.azurewebsites.net/api/DiagnosticCheck
```

Returns:
- Environment configuration
- Module status
- Credential validation
- Runtime version

### Common Issues

**Authentication Failures**
- Verify App Registration permissions
- Check client secret expiration
- Confirm tenant ID correctness

**Module Import Errors**
- Verify functions/modules/ directory structure
- Check PowerShell runtime version (7.2+)

**Action Failures**
- Check Application Insights for detailed errors
- Verify target resource exists
- Confirm API permissions granted

## Security Considerations

- **Least Privilege**: Grant only required API permissions
- **Secret Management**: Use Azure Key Vault for production
- **Network Security**: Enable Function App private endpoints
- **Audit Logging**: Enable all diagnostic logs
- **RBAC**: Restrict Function App access with Azure RBAC

## Project Structure

```
defenderc2xsoar/
├── deployment/              # ARM templates, deployment scripts
├── functions/              # Azure Function App code
│   ├── DefenderXDRGateway/     # HTTP entry + tracking
│   ├── DefenderXDROrchestrator/ # Routing logic
│   ├── DefenderXDRAzureWorker/  # Azure security (52 actions)
│   ├── DefenderXDRMDEWorker/    # MDE endpoint (52 actions)
│   ├── DefenderXDRMDOWorker/    # MDO email (25 actions)
│   ├── DefenderXDRMCASWorker/   # MCAS cloud apps (23 actions)
│   ├── DefenderXDREntraIDWorker/ # EntraID identity (34 actions)
│   ├── DefenderXDRIntuneWorker/  # Intune devices (33 actions)
│   └── modules/            # Shared modules
│       ├── AuthManager.psm1      # OAuth authentication
│       ├── ValidationHelper.psm1 # Input validation
│       ├── LoggingHelper.psm1    # Structured logging
│       ├── ActionTracker.psm1    # Action tracking/audit
│       └── BatchHelper.psm1      # Batch processing
├── workbook/               # Azure Sentinel Workbook
├── PERMISSIONS.md          # Required API permissions
├── DEPLOYMENT_GUIDE.md     # Detailed deployment guide
└── README.md              # This file
```

## API Reference

### Gateway Endpoint

**POST** `/api/Gateway`

**Request Body**:
```json
{
  "action": "string (required)",
  "tenantId": "string (required)",
  "service": "string (MDE|MDO|MCAS|EntraID|Intune|Azure)",
  "body": {
    // Action-specific parameters
  }
}
```

**Response**:
```json
{
  "success": true,
  "action": "IsolateDevice",
  "tenantId": "tenant-id",
  "actionId": "unique-action-id",
  "result": {
    // Action-specific results
  },
  "timestamp": "2025-11-13T10:30:00.000Z"
}
```

### Action Tracking Endpoints

**Get Action History**
```powershell
Get-ActionHistory -TenantId "tenant-id" -Service "MDE" -StartDate "2025-11-01"
```

**Get Action Status**
```powershell
Get-ActionAuditTrail -ActionId "unique-action-id"
```

**Request Cancellation**
```powershell
Request-ActionCancellation -ActionId "unique-action-id" -Reason "Manual intervention required"
```

## Version History

### v3.3.0 (2025-11-13) - Current
- ✅ Comprehensive batch processing (comma-separated values)
- ✅ Simplified module structure (removed IntegrationBridge folder)
- ✅ Removed DiagnosticCheck (use Application Insights)
- ✅ Removed MDIWorker (not integrated)
- ✅ Added BatchHelper.psm1 module
- ✅ Net reduction: 742 lines of code

### v3.2.0 (2025-11-13)
- ✅ 116 new remediation actions added
- ✅ Total 219 actions (100% XDR coverage)
- ✅ Action tracking infrastructure
- ✅ All 6 security services enhanced
- ✅ Comprehensive audit logging

### v3.0.0 (Previous)
- Initial release with 103 actions
- Basic Gateway/Orchestrator/Workers architecture
- Azure Sentinel Workbook integration

## Contributing

This is a production solution. For issues or enhancements:
1. Open an issue on GitHub
2. Provide detailed repro steps
3. Include Application Insights correlation ID

## License

MIT License - See LICENSE file

## Support

- **Documentation**: See docs/ folder
- **Issues**: GitHub Issues
- **Contact**: Repository owner

## Acknowledgments

Built for Security Operations Centers managing Microsoft security stack at scale.

---

**Microsoft Defender XDR to Sentinel SOAR Integration v3.2.0**  
*Complete XDR Remediation Action Coverage - 219 Actions*
