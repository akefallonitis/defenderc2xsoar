# DefenderC2 Action Cleanup Plan
**Date**: November 13, 2025  
**Purpose**: Remove read-only monitoring actions and focus on actual XDR remediation

---

## ❌ ACTIONS TO REMOVE (Read-Only / Monitoring Only)

### MDI Worker - Remove 7 monitoring actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetAlerts` | Read-only alert viewing | Keep permission for UpdateAlert |
| `GetIdentitySecureScore` | Compliance monitoring, not remediation | No permission impact |
| `GetSuspiciousActivities` | Read-only investigation | No permission impact |
| `GetHealthIssues` | System health monitoring | No permission impact |
| `GetRecommendations` | Compliance recommendations | No permission impact |
| `GetSensitiveUsers` | Read-only user list | No permission impact |
| `GetAlertStatistics` | Reporting/dashboards | No permission impact |
| `GetConfiguration` | Read configuration | No permission impact |
| `GetLateralMovementPaths` | Investigation only, no remediation action | No permission impact |
| `GetExposedCredentials` | Investigation only, no remediation action | No permission impact |

**KEEP ONLY**: `UpdateAlert` (actual remediation - mark as resolved/false positive)  
**Result**: 11 actions → 1 action

### Entra ID Worker - Remove 6 monitoring/read actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetRiskDetections` | Read-only risk viewing | Keep IdentityRiskEvent.Read.All for ConfirmCompromised |
| `GetRiskyUsers` | Read-only risk viewing | Keep IdentityRiskyUser.Read.All for DismissRisk |
| `GetConditionalAccessPolicies` | Read-only policy viewing | Keep Policy.Read.All? NO - remove |
| `GetSignInLogs` | Audit log viewing, not remediation | Remove AuditLog.Read.All |
| `GetAuditLogs` | Audit log viewing, not remediation | Remove AuditLog.Read.All |
| `GetUser` | Read-only user info | Keep User.Read.All for other actions |

**KEEP**: DisableUser, EnableUser, ResetPassword, RevokeUserSessions, ConfirmCompromised, DismissRisk, CreateNamedLocation, GetNamedLocations  
**Result**: 20 actions → 14 actions (remove 6 read-only)

### Intune Worker - Remove 3 monitoring actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetManagedDevices` | Read-only device list | Keep Device.Read.All for other actions |
| `GetDeviceCompliance` | Compliance monitoring | No permission impact |
| `GetDeviceConfiguration` | Read configuration | No permission impact |

**KEEP**: RemoteLockDevice, WipeDevice, RetireDevice, SyncDevice, RunDefenderScan, UpdateDeviceConfiguration  
**Result**: 18 actions → 15 actions (remove 3 read-only)

### Azure Worker - Remove 7 compliance/monitoring actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetVMs` | Read-only VM list | No impact - uses Managed Identity |
| `GetResourceGroups` | Read-only RG list | No impact |
| `GetNSGs` | Read-only NSG list | No impact |
| `GetStorageAccounts` | Read-only storage list | No impact |
| `GetSecurityRecommendations` | Compliance monitoring | No impact |
| `GetSecureScore` | Compliance monitoring | No impact |
| `GetDefenderPlans` | Read subscription info | No impact |
| `GetRegulatoryCompliance` | Compliance reporting | No impact |
| `GetJitAccessPolicies` | Read JIT policies | No impact |

**KEEP**: AddNSGDenyRule, StopVM, StartVM, RestartVM, AddFirewallRule (NEW), RotateKeyVaultSecret, DisableServicePrincipal  
**Result**: 23 actions → 16 actions (remove 7, add 2 firewall actions)

### MDE Worker - Remove 10 read/query actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetDevices` | Read-only device list | Keep Machine.Read.All for other actions |
| `GetDeviceInfo` | Read-only device info | Keep Machine.Read.All |
| `GetActionStatus` | Status checking (can be async) | Keep for user experience |
| `GetAllActions` | Administrative query | Remove this |
| `GetSession` | Live Response session status | Keep for UX |
| `GetFile` | Live Response file download | Keep - actual data collection |
| `GetCommandResult` | Live Response command output | Keep for UX |
| `GetProcesses` | Live Response process list | Keep - investigation |
| `GetRegistryValue` | Live Response registry read | Keep - investigation |
| `GetFileInfo` | Live Response file metadata | Keep - investigation |
| `FindFiles` | Live Response file search | Keep - investigation |
| `GetIndicators` | Read IOC list | Keep for context |
| `GetIndicator` | Read single IOC | Keep for verification |
| `GetQueryHistory` | Advanced Hunting history | Remove |
| `GetIncidents` | Read incidents list | Keep for context |
| `GetIncident` | Read single incident | Keep for context |
| `GetAlerts` | Read alerts list | Keep for context |
| `GetAlert` | Read single alert | Keep for context |

**REMOVE ONLY**: `GetAllActions`, `GetQueryHistory`  
**Result**: 63 actions → 61 actions (remove 2 query/admin actions)

### MDO Worker - NO CHANGES
All 16 actions are actual remediation (email delete, move, quarantine, threat submission, mail forwarding)  
**Result**: 16 actions → 16 actions ✅

### MCAS Worker - Remove 2 read actions
| Action | Reason | Permission Impact |
|--------|--------|-------------------|
| `GetOAuthApps` | Read OAuth app list | Keep for context |
| `GetUserAppConsents` | Read user consents | Keep for RevokeOAuthApp |

**REMOVE**: None (keep for context before revocation)  
**Result**: 15 actions → 15 actions ✅

---

## ✅ NEW ACTIONS TO ADD

### Azure Worker - Azure Firewall (2 actions)
| Action | Purpose | API | Permission |
|--------|---------|-----|------------|
| `AddAzureFirewallDenyRule` | Block malicious IP at network perimeter | Azure RM API | Managed Identity: Network Contributor |
| `RemoveAzureFirewallDenyRule` | Remove IP block after investigation | Azure RM API | Managed Identity: Network Contributor |

---

## 📊 FINAL ACTION COUNT

| Worker | Before | Remove | Add | **After** | Change |
|--------|--------|--------|-----|-----------|--------|
| MDE | 63 | -2 | 0 | **61** | -2 |
| MDO | 16 | 0 | 0 | **16** | ✅ |
| Entra ID | 20 | -6 | 0 | **14** | -6 |
| Intune | 18 | -3 | 0 | **15** | -3 |
| MDI | 11 | -10 | 0 | **1** | -10 |
| MCAS | 15 | 0 | 0 | **15** | ✅ |
| Azure | 23 | -7 | +2 | **18** | -5 |
| **TOTAL** | **166** | **-28** | **+2** | **140** | **-26** |

**Platform Actions** (via Managed Identity): 47 → 47 (no change)  
**GRAND TOTAL**: 213 → **187 actions** (-26 monitoring/read actions)

---

## 🔒 UPDATED PERMISSION REQUIREMENTS

### Microsoft Graph API (10 permissions, down from 12)
✅ **KEEP**:
1. `User.Read.All` - Entra ID: Read users for DisableUser, EnableUser, ResetPassword
2. `Group.Read.All` - Entra ID: Read groups (supporting)
3. `IdentityRiskyUser.Read.All` - Entra ID: Read risky users for DismissRisk
4. `IdentityRiskEvent.Read.All` - Entra ID: Read risk events for ConfirmCompromised
5. `ThreatIndicators.ReadWrite.OwnedBy` - MDO: Manage threat indicators
6. `Mail.ReadWrite` - MDO: Email remediation (delete, move, quarantine)
7. `Device.Read.All` - Intune: Read devices
8. `DeviceManagementManagedDevices.Read.All` - Intune: Read managed devices
9. `DeviceManagementConfiguration.Read.All` - Intune: Read configs
10. `DeviceManagementConfiguration.ReadWrite.All` - Intune: Update configs

❌ **REMOVE**:
1. ~~`Policy.Read.All`~~ - Not needed for remediation (only read CA policies)
2. ~~`AuditLog.Read.All`~~ - Not needed for remediation (only read audit/signin logs)

### Microsoft Defender for Endpoint API (3 permissions, unchanged)
1. `Machine.Read.All` - MDE: Read machines
2. `Machine.Isolate` - MDE: Isolate machines
3. `Machine.RestrictExecution` - MDE: Restrict execution

### Azure Managed Identity RBAC (2 roles, unchanged)
1. `Virtual Machine Contributor` - Subscription scope
2. `Network Contributor` - Subscription scope (includes NSG + Azure Firewall)

**TOTAL PERMISSIONS**: 15 → **13 permissions** (-2)

---

## 🎯 BENEFITS OF CLEANUP

### 1. **Reduced Permission Surface Area**
- Remove 2 Graph API permissions (Policy.Read.All, AuditLog.Read.All)
- Clearer permission justification (all action-focused, not monitoring)

### 2. **Simplified Action Catalog**
- 187 actions (down from 213) = 12% reduction
- Focus on actual remediation, not compliance dashboards
- Easier to understand and maintain

### 3. **Better Security Posture**
- Least privilege: Only permissions needed for response actions
- No compliance/monitoring read access (use native portals for that)

### 4. **Clearer Use Cases**
- **MDI Worker**: 1 action (UpdateAlert - mark as resolved/false positive)
- **Entra ID Worker**: 14 actions (identity protection, credential reset, session revocation, named locations)
- **Azure Worker**: 18 actions (VM stop/start, NSG deny, Azure Firewall deny, Key Vault rotation)

---

## 📝 IMPLEMENTATION CHECKLIST

- [ ] Remove 28 actions from worker run.ps1 files
- [ ] Remove 10 MDI worker actions (keep only UpdateAlert)
- [ ] Remove 6 Entra ID read actions
- [ ] Remove 3 Intune read actions
- [ ] Remove 7 Azure compliance/read actions
- [ ] Remove 2 MDE query actions
- [ ] Add 2 Azure Firewall actions (AddAzureFirewallDenyRule, RemoveAzureFirewallDenyRule)
- [ ] Update Configure-AppPermissions.ps1 (15 → 13 permissions)
- [ ] Remove Policy.Read.All and AuditLog.Read.All permissions
- [ ] Update README with 187 total actions
- [ ] Update ARM template descriptions
- [ ] Remove all "DefenderC2" references
- [ ] Create one-click deployment package

---

## 🔄 MIGRATION NOTES

### For Existing Deployments
- **Breaking Change**: 28 actions removed
- **Action Required**: Update any playbooks/workflows using removed actions
- **Removed Actions**: All Get*/Query* monitoring actions except essential context actions
- **New Permissions**: -2 (Policy.Read.All, AuditLog.Read.All removed)

### Recommended Alternatives for Removed Actions
- **SecureScore/Compliance**: Use native Azure Security Center portal
- **Audit Logs**: Use Azure AD portal or Log Analytics
- **Device Lists**: Use native MDE/Intune portals
- **Recommendations**: Use Microsoft Defender for Cloud portal

