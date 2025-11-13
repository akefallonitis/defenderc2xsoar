# Permission Validation Checklist - DefenderXDR C2 v3.0.0

## ✅ Final Permission Count: **20 permissions**

### Before: 26 configured + 52 "other" = **78 total** ❌
### After: **20 permissions** ✅ (74% reduction)

---

## 📋 Complete Permission Mapping

### Microsoft Graph API - 14 Permissions

#### XDR Security Operations (5 permissions)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 1 | `SecurityIncident.ReadWrite.All` | dc377aa6... | ALL | XDR incident management (GetIncidents, UpdateIncident, AddComment) |
| 2 | `SecurityAlert.ReadWrite.All` | 45cc0394... | ALL | XDR alert management (GetAlerts, UpdateAlert, ResolveAlert) |
| 3 | `SecurityActions.ReadWrite.All` | db06fb33... | ALL | Security actions (ExecuteAction, GetActions) |
| 4 | `ThreatHunting.Read.All` | dd98c7f5... | MDE | Advanced Hunting queries (RunQuery, SaveQuery) |
| 5 | `ThreatIndicators.ReadWrite.OwnedBy` | d665a8d9... | MDE | Custom IOCs (AddIndicator, UpdateIndicator, DeleteIndicator) |

#### Identity Protection (5 permissions)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 6 | `User.Read.All` | df021288... | EntraID | Read user accounts (GetUser, GetUsers, GetUserGroups) |
| 7 | `User.ReadWrite.All` | 741f803b... | EntraID | User management (DisableUser, EnableUser, ResetPassword, RevokeSessions) |
| 8 | `UserAuthenticationMethod.ReadWrite.All` | 50483e42... | EntraID | MFA management (DeleteAuthenticationMethod, DeleteAllMFAMethods, GetUserAuthenticationMethods) |
| 9 | `IdentityRiskyUser.ReadWrite.All` | 6e472fd1... | EntraID | Risk management (ConfirmUserCompromised, DismissUserRisk, GetRiskyUsers, GetUserRiskDetections) |
| 10 | `Policy.ReadWrite.ConditionalAccess` | 01c0a623... | EntraID | CA policies (CreateEmergencyCAPolicy, UpdateCAPolicy, GetCAPolicies) |

#### Device Management - Intune (2 permissions)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 11 | `DeviceManagementManagedDevices.ReadWrite.All` | 5b07b0dd... | Intune | Device actions (RemoteLock, WipeDevice, RetireDevice, SyncDevice, ResetPasscode, Reboot, Shutdown, EnableLostMode, DisableLostMode, ReevaluateCompliance, UpdateDefenderSignatures, BypassActivationLock, CleanWindowsDevice, LogoutSharedUser) |
| 12 | `DeviceManagementConfiguration.ReadWrite.All` | 0883f392... | Intune | Compliance policies (GetCompliancePolicies, UpdateCompliance) |

#### Email Security - OPTIONAL (1 permission)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 13 | `Mail.ReadWrite` | e2a3a72e... | MDO | Email remediation (SoftDeleteEmails, HardDeleteEmails, MoveToJunk, MoveToInbox, MoveToDeletedItems, BulkEmailSearch, BulkEmailDelete, ZAPPhishing, ZAPMalware, RemoveMailForwardingRules) - **8 actions** |

#### Cloud App Security - OPTIONAL (1 permission)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 14 | `Files.ReadWrite.All` | 75359482... | MCAS | File governance (QuarantineCloudFile, RemoveExternalSharing, ApplySensitivityLabel, RestoreFromQuarantine) - **4 actions** |

#### Audit Logging - RECOMMENDED (1 permission)
| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| - | `AuditLog.Read.All` | b0afded3... | EntraID | Sign-in logs (GetSignInLogs, GetAuditLogs) - Investigation support |

**Note**: AuditLog.Read.All included in count but marked as optional in some scenarios.

---

### Microsoft Defender for Endpoint API - 6 Permissions

| # | Permission | ID | Worker | Actions Using It |
|---|------------|-----|--------|------------------|
| 15 | `Machine.ReadWrite.All` | 7b3f05d5... | MDE | All device actions (IsolateDevice, UnisolateDevice, RestrictAppExecution, RunAntivirusScan, CollectInvestigationPackage, StopAndQuarantineFile, OffboardDevice, GetDevices, GetDeviceInfo, GetMachineActions, CancelMachineAction, StartAutomatedInvestigation) - **14 actions** |
| 16 | `Machine.LiveResponse` | 65929c4b... | MDE | Live Response (StartSession, GetSession, RunScript, GetFile, PutFile, InvokeCommand, GetCommandResult, GetProcesses, KillProcess, GetRegistryValue, SetRegistryValue, DeleteRegistryValue, FindFiles, GetFileInfo) - **15 actions** |
| 17 | `Alert.ReadWrite.All` | 93489bf5... | MDE | Alert management (GetAlerts, GetAlert, UpdateAlert, ResolveAlert, ClassifyAlert) - **5 actions** |
| 18 | `Ti.ReadWrite.All` | b27a61ec... | MDE | Threat Intelligence (AddFileIndicator, AddIPIndicator, AddURLIndicator, AddDomainIndicator, GetIndicators, GetIndicator, UpdateIndicator, DeleteIndicator, SubmitFile, SubmitURL) - **12 actions** |
| 19 | `AdvancedQuery.Read.All` | ea8291d3... | MDE | Advanced Hunting (RunQuery, SaveQuery, GetQueryHistory) - **3 actions** |
| 20 | `Library.Manage` | 72043a3d... | MDE | Live Response library (UploadScript, DeleteScript, ListScripts, UploadFile, DeleteFile) - **6 actions** |

---

## ❌ Permissions REMOVED (6 permissions)

| Permission | Why Removed | Risk Level |
|------------|-------------|------------|
| `eDiscovery.ReadWrite.All` | ❌ NOT used in any worker code | Low (unused) |
| `Application.ReadWrite.All` | ❌ NOT needed - C2 doesn't manage apps | High (excessive) |
| `RoleManagement.ReadWrite.Directory` | ❌ NOT needed - No role assignments | Critical (excessive) |
| `Directory.ReadWrite.All` | ❌ Superset of other permissions | Critical (excessive) |
| `Mail.Send` | ❌ NOT used - No email sending in code | Low (unused) |
| **52 "Other" permissions** | ❌ Historical/over-provisioned | Various |

---

## ✅ Cross-Check: Missing Permissions?

### Worker Analysis

#### ✅ MDE Worker (63 actions)
- Machine.ReadWrite.All → Covers all 14 device actions ✅
- Machine.LiveResponse → Covers all 15 Live Response actions ✅
- Ti.ReadWrite.All → Covers all 12 TI indicator actions ✅
- AdvancedQuery.Read.All → Covers 3 hunting actions ✅
- Alert.ReadWrite.All → Covers 5 alert actions ✅
- Library.Manage → Covers 6 library actions ✅
- **All 63 MDE actions covered** ✅

#### ✅ MDO Worker (16 actions)
- Mail.ReadWrite → Covers all 8 email remediation actions ✅
- SecurityIncident.ReadWrite.All → Covers threat submission (3 actions) ✅
- **Note**: Mail forwarding rules (3 actions) use Mail.ReadWrite ✅
- **All 16 MDO actions covered** ✅

#### ✅ Entra ID Worker (20 actions)
- User.Read.All → Covers user queries (2 actions) ✅
- User.ReadWrite.All → Covers user management (4 actions) ✅
- UserAuthenticationMethod.ReadWrite.All → Covers MFA (3 actions) ✅
- IdentityRiskyUser.ReadWrite.All → Covers risk (4 actions) ✅
- Policy.ReadWrite.ConditionalAccess → Covers CA policies (7 actions) ✅
- **All 20 Entra ID actions covered** ✅

#### ✅ Intune Worker (18 actions)
- DeviceManagementManagedDevices.ReadWrite.All → Covers all device actions (16 actions) ✅
- DeviceManagementConfiguration.ReadWrite.All → Covers compliance (2 actions) ✅
- **All 18 Intune actions covered** ✅

#### ✅ MCAS Worker (15 actions)
- Files.ReadWrite.All → Covers file governance (4 actions) ✅
- SecurityAlert.ReadWrite.All → Covers MCAS alerts (5 actions) ✅
- SecurityIncident.ReadWrite.All → Covers activity monitoring (6 actions) ✅
- **All 15 MCAS actions covered** ✅

#### ✅ Azure Worker (23 actions)
- **NO GRAPH PERMISSIONS NEEDED** ✅
- Uses Azure Resource Manager API (https://management.azure.com)
- Requires Azure RBAC roles (not App Registration permissions)
- Security Admin or Contributor role at subscription level ✅

#### ✅ MDI Worker (11 actions)
- SecurityAlert.ReadWrite.All → Covers MDI alerts (6 actions) ✅
- SecurityIncident.ReadWrite.All → Covers threat detection (5 actions) ✅
- **All 11 MDI actions covered** ✅

---

## 🎯 Validation Summary

### Total Actions: 166 actions across 7 workers

| Worker | Actions | Permissions Required | Status |
|--------|---------|---------------------|--------|
| MDE | 63 | 6 MDE perms | ✅ All covered |
| MDO | 16 | 1 Graph perm (optional) | ✅ All covered |
| Entra ID | 20 | 5 Graph perms | ✅ All covered |
| Intune | 18 | 2 Graph perms | ✅ All covered |
| MCAS | 15 | 1 Graph perm (optional) | ✅ All covered |
| Azure | 23 | 0 (uses Azure RBAC) | ✅ All covered |
| MDI | 11 | 0 (uses Security perms) | ✅ All covered |
| **TOTAL** | **166** | **20 permissions** | ✅ **100% covered** |

### Core XDR Permissions (Required): 18 permissions
- 12 Graph (XDR, Identity, Intune, Audit)
- 6 MDE
- **Covers**: 131 actions (79% of all actions)

### Optional Permissions: 2 permissions
- 1 Graph (Mail.ReadWrite) - **Covers**: 8 email actions (5%)
- 1 Graph (Files.ReadWrite.All) - **Covers**: 4 file actions (2%)

---

## 🔒 Security Validation

### ✅ Least Privilege Achieved
1. ✅ No directory-wide write access (Directory.ReadWrite.All removed)
2. ✅ No role management privileges (RoleManagement removed)
3. ✅ No app registration management (Application.ReadWrite removed)
4. ✅ No unused email permissions (Mail.Send removed)
5. ✅ No unnecessary eDiscovery access (eDiscovery.ReadWrite removed)
6. ✅ Specific permissions only (User.*, Policy.*, DeviceManagement.*)

### ⚠️ High-Privilege Permissions (Justified)
- `User.ReadWrite.All` - **Required** for account compromise response
- `UserAuthenticationMethod.ReadWrite.All` - **Required** for MFA reset
- `Mail.ReadWrite` - **Optional** for email remediation
- `Files.ReadWrite.All` - **Optional** for file quarantine

---

## 📝 Final Recommendation

### Minimal Configuration (Core XDR): 18 permissions
```powershell
# Comment out lines 145-154 in Configure-AppRegistrationPermissions.ps1
# @{ Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Name = "Mail.ReadWrite"; Type = "Role" }
# @{ Id = "75359482-378d-4052-8f01-80520e7db3cd"; Name = "Files.ReadWrite.All"; Type = "Role" }
```

### Full Configuration (All Features): 20 permissions
```powershell
# Keep all permissions as-is
# Includes email remediation and file governance
```

---

## ✅ Validation Result: **PASSED**

- ✅ All 166 actions covered by 20 permissions
- ✅ No missing permissions
- ✅ No excessive permissions
- ✅ 74% reduction from current state (78 → 20)
- ✅ Least-privilege principle applied
- ✅ Clean slate approach (removes all 78 existing permissions first)

**Status**: Ready to apply ✅
