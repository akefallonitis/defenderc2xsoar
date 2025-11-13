# XDR-Focused Action Analysis & Consolidation Plan

## 🎯 XDR Mission: Detect → Investigate → Respond → Remediate

**Focus**: Security incident response actions that SOAR playbooks need
**Remove**: Compliance reporting, management queries, non-incident-response features

---

## 📊 Current Action Inventory by Service

### **MDE (Microsoft Defender for Endpoint)** - 17 Actions

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `IsolateDevice` | Quarantine compromised endpoint | **Respond** | ✅ **KEEP** |
| `UnIsolateDevice` | Restore connectivity after remediation | **Remediate** | ✅ **KEEP** |
| `RestrictAppExecution` | Prevent malware execution | **Respond** | ✅ **KEEP** |
| `UnrestrictAppExecution` | Remove execution restrictions | **Remediate** | ✅ **KEEP** |
| `RunAntivirusScan` | Scan for malware | **Investigate/Respond** | ✅ **KEEP** |
| `GetAllAlerts` | Retrieve security alerts for investigation | **Detect/Investigate** | ✅ **KEEP** |
| `GetAllIncidents` | Retrieve XDR incidents | **Detect/Investigate** | ✅ **KEEP** |
| `RunAdvancedQuery` | Threat hunting across endpoints | **Investigate** | ✅ **KEEP** |
| `GetAllDevices` | Enumerate endpoints for investigation | **Investigate** | ✅ **KEEP** |
| `GetDeviceInfo` | Get device details for context | **Investigate** | ✅ **KEEP** |

#### ✅ **CRITICAL XDR ACTIONS - KEEP** (Threat Intelligence Automation)
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `SubmitIndicator` | Block file hash/IP/URL/domain across endpoints | **RESPOND** | ✅ **KEEP** - Automated threat blocking |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `CollectForensics` | Evidence collection | **Investigate** | ⚠️ **CONSIDER** - Rarely used |
| `LiveResponse` | Interactive shell access | **Investigate** | ⚠️ **CONSIDER** - Complex, security risk |
| `GetAllIndicators` | List all IOCs | Management | ❌ **REMOVE** - Not incident response |
| `DeleteIndicator` | Remove IOC | Management | ❌ **REMOVE** - Administrative |
| `GetVulnerabilities` | Vulnerability management | Compliance | ❌ **REMOVE** - Not incident response |
| `GetRecommendations` | Security recommendations | Compliance | ❌ **REMOVE** - Not incident response |

**MDE Recommended Actions**: **11 core** (SubmitIndicator added, remove 6 compliance/management actions)

---

### **EntraID (Identity Protection)** - 9 Actions

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `DisableUser` | Block compromised account | **Respond** | ✅ **KEEP** |
| `EnableUser` | Restore account access | **Remediate** | ✅ **KEEP** |
| `ResetUserPassword` | Force password change | **Respond** | ✅ **KEEP** |
| `RevokeUserSessions` | Kill active sessions | **Respond** | ✅ **KEEP** |
| `ConfirmUserCompromised` | Mark user as compromised | **Respond** | ✅ **KEEP** |
| `DismissUserRisk` | Clear false positive | **Remediate** | ✅ **KEEP** |
| `GetRiskyUsers` | Find compromised accounts | **Investigate** | ✅ **KEEP** |
| `GetRiskDetections` | Get risk events | **Investigate** | ✅ **KEEP** |

#### ✅ **CRITICAL XDR ACTIONS - KEEP** (Network-Level Threat Blocking)
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `AddIPToNamedLocation` | Block malicious IP at identity layer (Conditional Access) | **RESPOND** | ✅ **KEEP** - Block attacker IPs across M365 |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `GetUserById` | User lookup | Supporting | ⚠️ **KEEP** - Useful for context |
| `GetConditionalAccessPolicies` | Policy query | Management | ⚠️ **KEEP** - Needed to manage named locations |
| `GetNamedLocations` | List named locations | Supporting | ✅ **KEEP** - Required for IP blocking |

**EntraID Recommended Actions**: **12 core** (added 3 critical threat blocking actions)

---

### **Intune (Device Management)** - 7 Actions

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `RemoteLockDevice` | Lock compromised mobile device | **Respond** | ✅ **KEEP** |
| `WipeDevice` | Factory reset compromised device | **Respond** | ✅ **KEEP** |
| `RetireDevice` | Remove corporate data | **Respond** | ✅ **KEEP** |
| `SyncDevice` | Force policy sync | **Remediate** | ✅ **KEEP** |
| `RunDefenderScan` | Scan mobile device | **Investigate/Respond** | ✅ **KEEP** |
| `GetManagedDevices` | Enumerate mobile devices | **Investigate** | ✅ **KEEP** |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `GetDeviceComplianceStatus` | Compliance reporting | Compliance | ❌ **REMOVE** - Not incident response |

**Intune Recommended Actions**: **6 core** (remove 1 compliance action)

---

### **Azure (Infrastructure Security)** - 12 Actions (including MDC)

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `AddNSGDenyRule` | Block malicious IP/network | **Respond** | ✅ **KEEP** |
| `StopVM` | Shut down compromised VM | **Respond** | ✅ **KEEP** |
| `RemoveVMPublicIP` | Isolate VM from internet | **Respond** | ✅ **KEEP** |
| `DisableStoragePublicAccess` | Secure exposed storage | **Respond** | ✅ **KEEP** |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `GetVMs` | List VMs | Supporting | ⚠️ **KEEP** - Context for response |
| `GetResourceGroups` | List resource groups | Management | ❌ **REMOVE** - Not incident response |
| `GetNSGs` | List network security groups | Management | ❌ **REMOVE** - Not incident response |
| `GetStorageAccounts` | List storage accounts | Management | ❌ **REMOVE** - Not incident response |
| `GetKeyVaults` | List key vaults | Management | ❌ **REMOVE** - Not incident response |
| `GetSecurityRecommendations` | Security posture | Compliance | ❌ **REMOVE** - Not incident response |
| `GetSecureScore` | Compliance score | Compliance | ❌ **REMOVE** - Not incident response |
| `GetDefenderPlans` | MDC subscription info | Management | ❌ **REMOVE** - Not incident response |
| `EnableDefenderPlan` | Enable MDC | Management | ❌ **REMOVE** - Not incident response |
| `GetRegulatoryCompliance` | Compliance reporting | Compliance | ❌ **REMOVE** - Not incident response |
| `GetJitAccessPolicies` | JIT policy query | Management | ❌ **REMOVE** - Not incident response |

**Azure Recommended Actions**: **5 core** (remove 10 compliance/management actions)

---

### **MDI (Microsoft Defender for Identity)** - 5 Actions

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `GetAlerts` | Identity-based threats | **Detect/Investigate** | ✅ **KEEP** |
| `UpdateAlert` | Mark alerts as resolved | **Remediate** | ✅ **KEEP** |
| `GetLateralMovementPaths` | Detect attacker movement | **Investigate** | ✅ **KEEP** |
| `GetExposedCredentials` | Find credential exposure | **Investigate** | ✅ **KEEP** |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `GetIdentitySecureScore` | Compliance score | Compliance | ❌ **REMOVE** - Not incident response |

**MDI Recommended Actions**: **4 core** (remove 1 compliance action)

---

### **MDO (Microsoft Defender for Office 365)** - 4 Actions

#### ✅ **CORE XDR ACTIONS - KEEP**
| Action | Purpose | XDR Phase | Keep/Remove |
|--------|---------|-----------|-------------|
| `QuarantineEmail` | Quarantine phishing email | **Respond** | ✅ **KEEP** |
| `DeleteEmail` | Remove malicious email | **Respond** | ✅ **KEEP** |
| `SubmitPhishingReport` | Report phishing to Microsoft | **Respond** | ✅ **KEEP** |

#### ⚠️ **NON-ESSENTIAL ACTIONS - EVALUATE**
| Action | Purpose | XDR Relevance | Keep/Remove |
|--------|---------|---------------|-------------|
| `GetEmailMetadata` | Email investigation | **Investigate** | ⚠️ **KEEP** - Useful for context |

**MDO Recommended Actions**: **4 core** (all actions are XDR-relevant)

---

## 📈 Consolidation Summary

| Service | Current Actions | Core XDR Actions | Actions Added | Actions to Remove | Net Change |
|---------|----------------|------------------|---------------|-------------------|-----------|
| **MDE** | 17 | 11 | +1 (SubmitIndicator) | 6 | -35% |
| **EntraID** | 9 | 12 | +3 (IP blocking) | 0 | +33% |
| **Intune** | 7 | 6 | 0 | 1 | -14% |
| **Azure** | 12 | 5 | 0 | 10 | -58% |
| **MDI** | 5 | 4 | 0 | 1 | -20% |
| **MDO** | 4 | 4 | 0 | 0 | 0% |
| **TOTAL** | **54** | **42** | **+4** | **18** | **-22%** |

**Result**: **42 core XDR actions** including critical threat intelligence automation (IOC submission, IP blocking)

---

## 🎯 XDR Action Categories (Post-Consolidation)

### **1. Detect (6 actions)**
- `GetAllAlerts` - Unified XDR alerts
- `GetAllIncidents` - XDR incidents
- `GetRiskyUsers` - Identity risks
- `GetRiskDetections` - Risk events
- `GetAlerts` (MDI) - Identity threats
- `GetLateralMovementPaths` - Attack chains

### **2. Investigate (10 actions)**
- `RunAdvancedQuery` - Threat hunting
- `GetAllDevices` - Device inventory
- `GetDeviceInfo` - Device details
- `GetManagedDevices` - Mobile devices
- `GetExposedCredentials` - Credential leaks
- `GetUserById` - User context
- `GetVMs` - Infrastructure context
- `GetEmailMetadata` - Email investigation
- `GetNamedLocations` - **NEW** List IP-based blocking policies
- `GetConditionalAccessPolicies` - **NEW** List Conditional Access rules

### **3. Respond (18 actions)**
- `IsolateDevice` - Endpoint quarantine
- `RestrictAppExecution` - Block execution
- `RunAntivirusScan` - Malware scan
- `SubmitIndicator` - **NEW** Block file hash/IP/URL/domain across endpoints
- `DisableUser` - Block account
- `ResetUserPassword` - Force password change
- `RevokeUserSessions` - Kill sessions
- `ConfirmUserCompromised` - Mark compromised
- `AddIPToNamedLocation` - **NEW** Block malicious IP across all M365 services
- `RemoteLockDevice` - Lock mobile device
- `WipeDevice` - Factory reset
- `RetireDevice` - Remove corporate data
- `RunDefenderScan` - Mobile scan
- `AddNSGDenyRule` - Block network traffic
- `StopVM` - Shut down VM
- `RemoveVMPublicIP` - Isolate VM
- `DisableStoragePublicAccess` - Secure storage
- `QuarantineEmail` - Quarantine phishing

### **4. Remediate (8 actions)**
- `UnIsolateDevice` - Restore connectivity
- `UnrestrictAppExecution` - Remove restrictions
- `EnableUser` - Restore account
- `DismissUserRisk` - Clear false positive
- `SyncDevice` - Force policy sync
- `UpdateAlert` - Mark resolved
- `DeleteEmail` - Remove phishing
- `SubmitPhishingReport` - Report to Microsoft

---

## 🔒 Permission Consolidation

### **Graph API Permissions (Core XDR)**

#### **KEEP - Essential for XDR**
```powershell
# Security Operations
"SecurityEvents.Read.All"           # Unified alerts/incidents
"SecurityEvents.ReadWrite.All"      # Update incidents
"SecurityIncident.Read.All"         # XDR incidents
"SecurityIncident.ReadWrite.All"    # Manage incidents

# Identity Protection
"IdentityRiskEvent.Read.All"        # Risk detections
"IdentityRiskyUser.Read.All"        # Risky users
"User.ReadWrite.All"                # Disable/enable users
"UserAuthenticationMethod.ReadWrite.All"  # Password reset
"User.RevokeSessions.All"           # Kill sessions

# Device Management
"DeviceManagementManagedDevices.ReadWrite.All"  # Intune actions

# Email Security
"Mail.ReadWrite"                    # Email quarantine/delete

# Supporting
"User.Read.All"                     # User context
"Directory.Read.All"                # Directory context
```

#### **REMOVE - Not XDR-focused**
```powershell
# Compliance/Reporting
"AuditLog.Read.All"                 # Audit logs (reporting)
"Reports.Read.All"                  # Compliance reports
"Policy.Read.All"                   # Policy queries
"SecurityRecommendation.Read.All"   # Posture management

# Threat Intelligence Management
"ThreatIndicators.ReadWrite.OwnedBy"  # IOC management (rarely used)

# Advanced Configuration
"DeviceManagementConfiguration.Read.All"  # Config queries
"Application.Read.All"              # App queries
"Group.Read.All"                    # Group queries
"GroupMember.Read.All"              # Group membership
```

### **MDE API Permissions (Core XDR)**

#### **KEEP - Essential for XDR**
```powershell
"Alert.Read.All"                    # MDE alerts
"Alert.ReadWrite.All"               # Update alerts
"Machine.ReadWrite.All"             # Device actions
"Machine.Isolate"                   # Device isolation
"Machine.RestrictExecution"         # App restriction
"Machine.Scan"                      # AV scan
"AdvancedQuery.Read.All"            # Threat hunting
"Machine.Read.All"                  # Device inventory
```

#### **REMOVE - Not XDR-focused**
```powershell
"SecurityRecommendation.Read.All"   # Recommendations
"Vulnerability.Read.All"            # Vuln management
"Ti.ReadWrite.All"                  # IOC management
"Machine.LiveResponse"              # Live response (security risk)
"Machine.CollectForensics"          # Forensics (rarely used)
"File.Read.All"                     # File queries
"Ip.Read.All"                       # IP queries
"Url.Read.All"                      # URL queries
"User.Read.All" (duplicate)         # Already in Graph API
```

---

## 📝 Implementation Plan

### **Phase 1: Remove Non-XDR Actions from Orchestrator** ⏳
- [ ] Remove 7 MDE compliance/management actions
- [ ] Remove 1 EntraID management action
- [ ] Remove 1 Intune compliance action
- [ ] Remove 10 Azure compliance/management actions
- [ ] Remove 1 MDI compliance action
- [ ] Update action validation lists

### **Phase 2: Update Permissions Script** ⏳
- [ ] Update `Set-DefenderC2XSOARPermissions.ps1` to only include core XDR permissions
- [ ] Remove 12 non-essential Graph API permissions
- [ ] Remove 9 non-essential MDE API permissions
- [ ] Update documentation with new permission list

### **Phase 3: Simplify Modules** ⏳
- [ ] Remove unused functions from modules (e.g., `Get-Recommendations`, `Get-Vulnerabilities`)
- [ ] Remove `DefenderForCloud.psm1` (already consolidated)
- [ ] Clean up unused helper functions

### **Phase 4: Documentation** ⏳
- [ ] Create XDR playbook examples for each core action
- [ ] Update README with focused action list (38 actions instead of 54)
- [ ] Add "What to expect" section (what we DON'T support)
- [ ] Create migration guide for removed actions

### **Phase 5: Testing** ⏳
- [ ] Test all 38 core XDR actions
- [ ] Verify removed actions return "not supported" errors
- [ ] Validate permission script grants only needed permissions

---

## 🎉 Benefits of XDR-Focused Consolidation

✅ **Clarity**: 38 focused actions vs 54 mixed-purpose actions
✅ **Security**: Fewer permissions = smaller attack surface
✅ **Performance**: Faster API responses (fewer unnecessary queries)
✅ **Maintenance**: Less code to maintain and test
✅ **User Experience**: Clearer documentation, easier to understand
✅ **Compliance**: Minimal permissions principle

---

## 🚀 Next Steps

1. **Review this analysis** - Confirm which actions to keep/remove
2. **Update Orchestrator** - Remove non-XDR actions
3. **Update permissions script** - Remove non-essential permissions
4. **Update documentation** - Reflect XDR focus
5. **Deploy and test** - Verify all core actions work

**Estimated Time**: 2-3 hours to implement, test, and deploy
**Breaking Changes**: Yes (removed actions will return errors)
**Migration Path**: Remove playbooks that use deprecated actions
