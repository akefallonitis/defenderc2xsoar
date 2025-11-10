# DefenderXDRC2XSOAR - Required Permissions (v2.1.0)

This document outlines all required permissions for the DefenderXDRC2XSOAR v2.1.0 solution to function across all Microsoft security services.

**NEW in v2.1.0:**
- ✅ Microsoft Defender for Cloud (MDC) permissions
- ✅ Microsoft Defender for Identity (MDI) permissions
- ✅ Centralized authentication with token caching

## App Registration Requirements

You need to create an Azure AD App Registration with the following permissions:

### Microsoft Graph API Permissions (Application Permissions)

#### Email Remediation (MDO - Microsoft Defender for Office 365)
- `SecurityAnalyzedMessage.ReadWrite.All` - Read and remediate analyzed email messages
- `ThreatSubmission.ReadWrite.All` - Submit threats to Microsoft for analysis
- `ThreatIndicators.ReadWrite.OwnedBy` - Manage threat indicators (URL blocking)
- `MailboxSettings.ReadWrite` - Read and manage mail forwarding rules

#### User & Identity Management (Entra ID & Identity Protection)
- `User.ReadWrite.All` - Read and write all user profile information
- `Directory.ReadWrite.All` - Read and write directory data
- `IdentityRiskyUser.ReadWrite.All` - Read and write risky user information (requires Entra ID P2)
- `UserAuthenticationMethod.ReadWrite.All` - Manage user authentication methods for password resets

#### Conditional Access (Entra ID P1+)
- `Policy.ReadWrite.ConditionalAccess` - Read and write conditional access policies
- `Application.Read.All` - Read applications (for policy configuration)

#### Intune Device Management
- `DeviceManagementManagedDevices.ReadWrite.All` - Read and write managed device information
- `DeviceManagementConfiguration.ReadWrite.All` - Read and write device configurations

#### Additional Graph Permissions
- `SecurityEvents.ReadWrite.All` - Read and write security events
- `SecurityActions.ReadWrite.All` - Read and write security actions

### Microsoft Defender API Permissions (Application Permissions)

Access the Microsoft Defender API permissions at: https://security.microsoft.com

#### Machine Actions
- `Machine.Isolate` - Isolate and unisolate machines
- `Machine.RestrictExecution` - Restrict and unrestrict code execution
- `Machine.Scan` - Run antivirus scans
- `Machine.CollectForensics` - Collect investigation packages
- `Machine.StopAndQuarantine` - Stop and quarantine files
- `Machine.Offboard` - Offboard machines from Defender
- `Machine.LiveResponse` - Execute Live Response sessions
- `Machine.Read.All` - Read all machine information

#### Alerts & Incidents
- `Alert.ReadWrite.All` - Read and write alert information
- `Incident.ReadWrite.All` - Read and write incident information

#### Advanced Hunting
- `AdvancedQuery.Read.All` - Run advanced hunting queries

#### Threat Intelligence
- `Ti.ReadWrite.All` - Read and write threat intelligence indicators

### Azure RBAC Roles

For Azure infrastructure management actions, the App Registration (Service Principal) needs the following Azure RBAC roles:

#### Network Security
- `Network Contributor` - Manage network security groups and rules
  - Or use custom role with: `Microsoft.Network/networkSecurityGroups/*`

#### Virtual Machine Management
- `Virtual Machine Contributor` - Stop and manage VMs
  - Or use custom role with: `Microsoft.Compute/virtualMachines/*`

#### Storage Security
- `Storage Account Contributor` - Manage storage account security settings
  - Or use custom role with: `Microsoft.Storage/storageAccounts/write`

#### General Azure
- `Reader` - Read Azure resources for inventory
- `Security Admin` - Manage security settings across Azure resources

## License Requirements

### Microsoft 365 Licenses
- **Microsoft 365 E5** or **Microsoft 365 E5 Security** - Full XDR capabilities
- **Microsoft Defender for Office 365 Plan 2** - Email remediation features
- **Microsoft Defender for Endpoint P2** - All endpoint actions
- **Microsoft Defender for Identity** - Identity protection features (via E5)

### Azure AD / Entra ID Licenses
- **Entra ID Premium P1** - Conditional Access policies
- **Entra ID Premium P2** - Identity Protection (risk detections, risky users)

### Intune Licenses
- **Microsoft Intune Plan 1** - Basic device management
- **Microsoft Intune Plan 2** - Advanced endpoint analytics

### Azure Subscriptions
- Valid Azure subscription with appropriate resource quotas

## Permission Scopes by Service

### 1. Email Remediation (MDO)
```
Microsoft Graph API (Application):
- SecurityAnalyzedMessage.ReadWrite.All
- ThreatSubmission.ReadWrite.All
- ThreatIndicators.ReadWrite.OwnedBy
- MailboxSettings.ReadWrite
```

**Actions Enabled:**
- Soft delete email messages
- Hard delete email messages
- Move emails to junk folder
- Move emails to inbox (restore)
- Submit email threats to Microsoft
- Submit URL threats to Microsoft
- Block URLs at time-of-click
- Remove external mail forwarding rules

### 2. User & Identity Management (Entra ID)
```
Microsoft Graph API (Application):
- User.ReadWrite.All
- Directory.ReadWrite.All
- IdentityRiskyUser.ReadWrite.All (requires Entra ID P2)
- UserAuthenticationMethod.ReadWrite.All
```

**Actions Enabled:**
- Disable user accounts
- Enable user accounts
- Reset user passwords
- Confirm users as compromised
- Dismiss user risk
- Revoke user sign-in sessions
- Query risk detections

### 3. Conditional Access (Entra ID P1+)
```
Microsoft Graph API (Application):
- Policy.ReadWrite.ConditionalAccess
- Application.Read.All
```

**Actions Enabled:**
- Create named locations (trusted/blocked IPs)
- Update named locations
- Create conditional access policies
- Create sign-in risk policies
- Create user risk policies
- Query conditional access settings

### 4. Device Management (MDE)
```
Microsoft Defender API (Application):
- Machine.Isolate
- Machine.RestrictExecution
- Machine.Scan
- Machine.CollectForensics
- Machine.StopAndQuarantine
- Machine.Offboard
- Machine.LiveResponse
- Machine.Read.All
- Alert.ReadWrite.All
- AdvancedQuery.Read.All
- Ti.ReadWrite.All
```

**Actions Enabled:**
- Isolate devices (full/selective)
- Release devices from isolation
- Restrict application execution
- Unrestrict application execution
- Run antivirus scans (quick/full)
- Collect investigation packages
- Stop and quarantine files
- Offboard machines
- Start automated investigations
- Execute Live Response commands
- Manage threat indicators

### 5. Intune Device Management
```
Microsoft Graph API (Application):
- DeviceManagementManagedDevices.ReadWrite.All
- DeviceManagementConfiguration.ReadWrite.All
```

**Actions Enabled:**
- Remote lock devices
- Wipe devices (full/selective)
- Retire devices (remove company data)
- Sync devices
- Run Windows Defender scans via Intune

### 6. Azure Infrastructure Security
```
Azure RBAC Roles (assigned to Service Principal):
- Network Contributor
- Virtual Machine Contributor
- Storage Account Contributor
- Security Admin
- Reader
```

**Actions Enabled:**
- Add NSG deny rules (block IPs/ports)
- Stop and deallocate VMs
- Disable storage account public access
- Remove public IPs from VMs
- Query Azure resources

### 7. Microsoft Defender for Cloud (MDC) - NEW v2.1.0
```
Azure RBAC Roles (assigned to Service Principal):
- Security Reader (minimum for read operations)
- Security Admin (required for write operations)
- Contributor (for JIT access and infrastructure changes)
```

**API Access:**
- Microsoft.Security/alerts/read
- Microsoft.Security/alerts/write
- Microsoft.Security/assessments/read
- Microsoft.Security/pricings/read
- Microsoft.Security/pricings/write
- Microsoft.Security/secureScores/read
- Microsoft.Security/regulatoryComplianceStandards/read
- Microsoft.Security/jitNetworkAccessPolicies/read
- Microsoft.Security/jitNetworkAccessPolicies/write
- Microsoft.Security/jitNetworkAccessPolicies/initiate/action
- Microsoft.Security/autoProvisioningSettings/read
- Microsoft.Security/autoProvisioningSettings/write

**Actions Enabled:**
- Get and update security alerts
- Retrieve security recommendations
- Get secure score
- Get regulatory compliance status
- Enable/disable Defender plans
- Configure auto-provisioning
- Manage Just-in-Time VM access

### 8. Microsoft Defender for Identity (MDI) - NEW v2.1.0
```
Microsoft Graph API (Application):
- SecurityEvents.Read.All (read MDI alerts)
- SecurityAlert.ReadWrite.All (read/write MDI alerts)
- SecurityEvents.ReadWrite.All (update alerts)
- IdentityRiskyUser.Read.All (read risky users)
```

**Actions Enabled:**
- Get MDI security alerts
- Update alert status and classification
- Detect lateral movement paths
- Get suspicious activities
- Find exposed credentials
- Detect account enumeration
- Detect privilege escalation
- Get reconnaissance activities
- Get identity secure score
- Monitor sensor health
- Check domain controller coverage

## Permission Matrix by Service

| Service | API | Permission Type | Key Permissions |
|---------|-----|-----------------|-----------------|
| **MDE** | Defender API | Application | Machine.*, Alert.*, Ti.*, AdvancedQuery.* |
| **MDO** | Graph API | Application | SecurityAnalyzedMessage.ReadWrite.All, ThreatSubmission.* |
| **MDC** | Azure RM | RBAC Role | Security Admin, Contributor |
| **MDI** | Graph API | Application | SecurityAlert.ReadWrite.All, SecurityEvents.* |
| **Entra ID** | Graph API | Application | User.ReadWrite.All, Directory.ReadWrite.All, IdentityRiskyUser.* |
| **Intune** | Graph API | Application | DeviceManagement*.ReadWrite.All |
| **Azure** | Azure RM | RBAC Role | Network Contributor, VM Contributor, Storage Contributor |

## Admin Consent Requirements

All application permissions require **admin consent** from a Global Administrator or appropriate delegated administrator.

### How to Grant Admin Consent

1. Navigate to Azure Portal → Azure Active Directory → App registrations
2. Select your DefenderXDRC2XSOAR app registration
3. Go to "API permissions"
4. Click "Grant admin consent for [Your Organization]"
5. Confirm the consent

## Security Best Practices

### 1. Use Separate App Registrations
Consider using separate app registrations for different environments:
- Production environment
- Development/testing environment
- One per tenant for MSP scenarios

### 2. Rotate Secrets Regularly
- Rotate client secrets every 90-180 days
- Use Azure Key Vault for secret storage
- Monitor for secret expiration

### 3. Use Managed Identity Where Possible
- Enable managed identity for Azure Functions
- Use federated credentials with managed identity
- Avoid storing secrets in environment variables when possible

### 4. Implement Least Privilege
- Only grant permissions required for your use case
- Remove unused permissions
- Regularly audit permission usage

### 5. Enable Audit Logging
- Enable Azure AD audit logs
- Enable MDE audit logs
- Monitor for anomalous API usage
- Set up alerts for suspicious activities

### 6. Network Security
- Use private endpoints for Azure Functions
- Implement IP restrictions
- Use Azure Front Door or Application Gateway
- Enable Azure DDoS Protection

## Troubleshooting Permissions Issues

### Common Issues

#### 1. "Insufficient privileges to complete the operation"
**Cause:** Missing Graph API permissions or admin consent not granted
**Solution:** Verify all required permissions are added and admin consent is granted

#### 2. "Authorization_RequestDenied"
**Cause:** Service principal doesn't have required Azure RBAC role
**Solution:** Assign appropriate Azure roles to the app's service principal

#### 3. "License required"
**Cause:** Feature requires specific Microsoft 365 or Azure AD license
**Solution:** Verify tenant has required licenses (E5, P1, P2, etc.)

#### 4. "Access denied" for Identity Protection APIs
**Cause:** Requires Entra ID Premium P2 license
**Solution:** Ensure tenant has P2 licenses and assign to users

### Verification Scripts

#### Check Graph API Permissions
```powershell
Connect-AzureAD
$app = Get-AzureADApplication -Filter "DisplayName eq 'DefenderXDRC2XSOAR'"
$app.RequiredResourceAccess | ForEach-Object {
    $resource = Get-AzureADServicePrincipal -Filter "AppId eq '$($_.ResourceAppId)'"
    Write-Host "Resource: $($resource.DisplayName)"
    $_.ResourceAccess | ForEach-Object {
        $permission = $resource.AppRoles | Where-Object { $_.Id -eq $_.Id }
        Write-Host "  - $($permission.Value)"
    }
}
```

#### Check Azure RBAC Roles
```powershell
Connect-AzAccount
$sp = Get-AzADServicePrincipal -DisplayName "DefenderXDRC2XSOAR"
Get-AzRoleAssignment -ObjectId $sp.Id | Select-Object RoleDefinitionName, Scope
```

## Quick Reference Table

| Service | Primary API | Key Permissions | License Required |
|---------|-------------|----------------|------------------|
| Email Remediation | Graph Beta | SecurityAnalyzedMessage.ReadWrite.All | MDO P2 or M365 E5 |
| User Management | Graph v1.0 | User.ReadWrite.All | Any M365 |
| Identity Protection | Graph v1.0 | IdentityRiskyUser.ReadWrite.All | Entra ID P2 |
| Conditional Access | Graph v1.0 | Policy.ReadWrite.ConditionalAccess | Entra ID P1+ |
| MDE Actions | Defender API | Machine.* (multiple) | MDE P2 |
| Intune Actions | Graph v1.0 | DeviceManagement*.ReadWrite.All | Intune Plan 1+ |
| Azure Infrastructure | Azure RM | Network/VM/Storage Contributor | Azure subscription |

## Documentation Links

- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft Defender API Permissions](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure RBAC Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Entra ID Premium Features](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-mfa-licensing)
- [Microsoft 365 Licensing](https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions)

## Support

For issues related to permissions:
1. Verify all permissions are correctly configured in app registration
2. Ensure admin consent has been granted
3. Check audit logs for permission-related errors
4. Verify license assignments for advanced features
5. Open an issue on GitHub with detailed error messages

---

**Last Updated:** 2025-01-10  
**Version:** 2.0.0 (DefenderXDRC2XSOAR)
