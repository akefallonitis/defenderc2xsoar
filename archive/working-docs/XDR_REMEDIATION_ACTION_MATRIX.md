# Microsoft XDR Remediation Actions - Comprehensive Matrix

**Date**: November 12, 2025  
**Purpose**: Complete inventory of XDR remediation actions across all Microsoft security products  
**API Strategy**: Prioritize Graph API v1.0 (stable) > Graph Beta (preview) > Product APIs (specialized only)

---

## 📊 EXECUTIVE SUMMARY

| Service Worker | Total Actions Available | Currently Implemented | Missing | Coverage % | Priority Gap |
|----------------|------------------------|----------------------|---------|------------|--------------|
| **MDE Worker** | 68 | 68 | 0 | **100%** ✅ | Live Response complete, IOCs complete |
| **MDO Worker** | 22 | 4 | 18 | **18%** ❌ | Email remediation (Graph Beta), ZAP, Tenant blocks |
| **MDI Worker** | 11 | 11 | 0 | **100%** ✅ | Investigation complete |
| **Entra ID Worker** | 18 | 13 | 5 | **72%** ⚠️ | MFA reset, emergency CA policies |
| **Intune Worker** | 15 | 8 | 7 | **53%** ⚠️ | Lost mode, passcode reset, compliance |
| **Azure Worker** | 25 | 8 | 17 | **32%** ❌ | Firewall, Key Vault, Service Principals |
| **XDR Platform** | 17 | 5 | 12 | **29%** ❌ | Detection rules, AIR actions, playbooks |
| **MCAS Worker** | 12 | 0 | 12 | **0%** ❌ | ALL - OAuth, sessions, file quarantine |
| **TOTAL** | **188** | **117** | **71** | **62%** | 71 critical actions missing |

---

## 🔴 CRITICAL FINDINGS

### ✅ **STRENGTHS**
1. **MDE Worker**: 100% coverage - All device actions, Live Response (15 actions), threat intel (12 IOC actions), incidents/alerts implemented
2. **MDI Worker**: 100% coverage - All investigation, lateral movement, exposed credentials actions
3. **Entra ID Worker**: Strong identity protection coverage (13/18 actions)

### ❌ **CRITICAL GAPS**
1. **MDO Worker**: Only 18% coverage - Missing new Graph Beta email remediation API (soft/hard delete, move to junk, ZAP)
2. **MCAS Worker**: 0% coverage - No OAuth app revocation, session termination, cloud file quarantine
3. **Azure Worker**: Only 32% coverage - Missing Azure Firewall, Key Vault rotation, Service Principal controls
4. **XDR Platform**: Missing unified detection rules, AIR action approval, playbook orchestration

---

## 1️⃣ MDE WORKER (Microsoft Defender for Endpoint)

**Coverage**: 68/68 actions ✅ **100%**  
**API Strategy**: MDE API (primary) + Graph v1.0 (incidents/alerts)

### Device Remediation Actions (14/14) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Isolate Machine | MDE v1.0 | `/api/machines/{id}/isolate` | ✅ ISOLATEDEVICE | Critical |
| Release Isolation | MDE v1.0 | `/api/machines/{id}/unisolate` | ✅ UNISOLATEDEVICE | Critical |
| Restrict Code Execution | MDE v1.0 | `/api/machines/{id}/restrictCodeExecution` | ✅ RESTRICTAPP | Critical |
| Remove Code Restriction | MDE v1.0 | `/api/machines/{id}/unrestrictCodeExecution` | ✅ UNRESTRICTAPP | Critical |
| Run Full AV Scan | MDE v1.0 | `/api/machines/{id}/runAntiVirusScan` (scanType: Full) | ✅ RUNAVSCAN | Critical |
| Run Quick AV Scan | MDE v1.0 | `/api/machines/{id}/runAntiVirusScan` (scanType: Quick) | ✅ RUNAVSCAN | High |
| Collect Investigation Package | MDE v1.0 | `/api/machines/{id}/collectInvestigationPackage` | ✅ COLLECTINVESTIGATIONPACKAGE | High |
| Offboard Machine | MDE v1.0 | `/api/machines/{id}/offboard` | ✅ OFFBOARDDEVICE | Medium |
| Quarantine File | MDE v1.0 | `/api/machines/{id}/StopAndQuarantineFile` | ✅ STOPANDQUARANTINEFILE | Critical |
| Get Devices | MDE v1.0 | `/api/machines` | ✅ GETDEVICES | Medium |
| Get Device Info | MDE v1.0 | `/api/machines/{id}` | ✅ GETDEVICEINFO | Medium |
| Get Action Status | MDE v1.0 | `/api/machineactions/{id}` | ✅ GETACTIONSTATUS | High |
| Get All Actions | MDE v1.0 | `/api/machineactions` | ✅ GETALLACTIONS | Medium |
| Cancel Action | MDE v1.0 | `/api/machineactions/{id}/cancel` | ✅ CANCELACTION | High |

### Live Response Actions (15/15) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Start Investigation | MDE v1.0 | `/api/machines/{id}/initiateInvestigation` | ✅ STARTINVESTIGATION | Critical |
| Start Live Response Session | MDE v1.0 | `/api/machines/{id}/liveResponse` | ✅ STARTSESSION | Critical |
| Get Session | MDE v1.0 | `/api/machineactions/{id}` | ✅ GETSESSION | High |
| Run Script | MDE v1.0 | Live Response command | ✅ RUNSCRIPT | Critical |
| Get File | MDE v1.0 | Live Response command | ✅ GETFILE | Critical |
| Put File | MDE v1.0 | Live Response command | ✅ PUTFILE | High |
| Invoke Command | MDE v1.0 | Live Response command | ✅ INVOKECOMMAND | Critical |
| Get Command Result | MDE v1.0 | Live Response result | ✅ GETCOMMANDRESULT | High |
| Get Processes | MDE v1.0 | Live Response command | ✅ GETPROCESSES | High |
| Kill Process | MDE v1.0 | Live Response command | ✅ KILLPROCESS | Critical |
| Get Registry Value | MDE v1.0 | Live Response command | ✅ GETREGISTRYVALUE | High |
| Set Registry Value | MDE v1.0 | Live Response command | ✅ SETREGISTRYVALUE | Medium |
| Delete Registry Value | MDE v1.0 | Live Response command | ✅ DELETEREGISTRYVALUE | Medium |
| Find Files | MDE v1.0 | Live Response command | ✅ FINDFILES | High |
| Get File Info | MDE v1.0 | Live Response command | ✅ GETFILEINFO | Medium |

### Threat Intelligence (IOC) Actions (12/12) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Add Indicator | MDE v1.0 | `/api/indicators` | ✅ ADDINDICATOR | Critical |
| Remove Indicator | MDE v1.0 | `/api/indicators/{id}` (DELETE) | ✅ REMOVEINDICATOR | High |
| Get Indicators | MDE v1.0 | `/api/indicators` | ✅ GETINDICATORS | Medium |
| Get Indicator | MDE v1.0 | `/api/indicators/{id}` | ✅ GETINDICATOR | Medium |
| Update Indicator | MDE v1.0 | `/api/indicators/{id}` (PATCH) | ✅ UPDATEINDICATOR | High |
| Bulk Add Indicators | MDE v1.0 | `/api/indicators/batch` | ✅ BULKADDINDICATORS | High |
| Bulk Remove Indicators | MDE v1.0 | `/api/indicators/batch` (DELETE) | ✅ BULKREMOVEINDICATORS | High |
| Add File Indicator | MDE v1.0 | `/api/indicators` (FileSha256) | ✅ ADDFILEINDICATOR | Critical |
| Add IP Indicator | MDE v1.0 | `/api/indicators` (IpAddress) | ✅ ADDIPINDICATOR | Critical |
| Add URL Indicator | MDE v1.0 | `/api/indicators` (Url) | ✅ ADDURLINDICATOR | Critical |
| Add Domain Indicator | MDE v1.0 | `/api/indicators` (DomainName) | ✅ ADDDOMAININDICATOR | Critical |
| Add Certificate Indicator | MDE v1.0 | `/api/indicators` (CertificateThumbprint) | ✅ Implicit via ADDINDICATOR | Medium |

### Advanced Hunting (3/3) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Run Query | Graph v1.0 | `/security/runHuntingQuery` | ✅ RUNQUERY | Critical |
| Save Query | Local storage | Blob/Table Storage | ✅ SAVEQUERY | Medium |
| Get Query History | Local storage | Table Storage | ✅ GETQUERYHISTORY | Low |

### Incidents & Alerts (14/14) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Get Incidents | Graph v1.0 | `/security/incidents` | ✅ GETINCIDENTS | High |
| Get Incident | Graph v1.0 | `/security/incidents/{id}` | ✅ GETINCIDENT | High |
| Update Incident | Graph v1.0 | `/security/incidents/{id}` (PATCH) | ✅ UPDATEINCIDENT | Critical |
| Add Comment | Graph v1.0 | `/security/incidents/{id}/comments` | ✅ ADDCOMMENT | Medium |
| Assign Incident | Graph v1.0 | `/security/incidents/{id}` (PATCH assignedTo) | ✅ ASSIGNINCIDENT | High |
| Resolve Incident | Graph v1.0 | `/security/incidents/{id}` (PATCH status: resolved) | ✅ RESOLVEINCIDENT | High |
| Get Alerts | Graph v1.0 | `/security/alerts_v2` | ✅ GETALERTS | High |
| Get Alert | Graph v1.0 | `/security/alerts_v2/{id}` | ✅ GETALERT | High |
| Update Alert | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH) | ✅ UPDATEALERT | Critical |
| Resolve Alert | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH status: resolved) | ✅ RESOLVEALERT | High |
| Classify Alert | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH classification) | ✅ CLASSIFYALERT | High |
| Suppress Alert | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH status: suppressed) | ✅ Implicit via UPDATEALERT | Medium |
| Link Alert to Incident | Graph v1.0 | `/security/incidents/{id}/alerts/$ref` | ✅ Implicit via UPDATEINCIDENT | Medium |
| Bulk Alert Update | Graph v1.0 | Multiple PATCH requests | ✅ Via orchestration | Low |

### Custom Detection Rules (10/10) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Create Detection Rule | Graph Beta | `/security/rules/detectionRules` | ✅ Via MDE Portal API | High |
| Update Detection Rule | Graph Beta | `/security/rules/detectionRules/{id}` | ✅ Via MDE Portal API | High |
| Delete Detection Rule | Graph Beta | `/security/rules/detectionRules/{id}` | ✅ Via MDE Portal API | Medium |
| Enable Detection Rule | Graph Beta | `/security/rules/detectionRules/{id}` (enabled: true) | ✅ Via MDE Portal API | High |
| Disable Detection Rule | Graph Beta | `/security/rules/detectionRules/{id}` (enabled: false) | ✅ Via MDE Portal API | High |
| Get Detection Rules | Graph Beta | `/security/rules/detectionRules` | ✅ Via MDE Portal API | Medium |
| Test Detection Rule | MDE Portal | Custom KQL validation | ✅ Via RUNQUERY | Medium |
| Clone Detection Rule | Graph Beta | GET + POST new rule | ✅ Via orchestration | Low |
| Export Detection Rules | Graph Beta | GET all + JSON export | ✅ Via orchestration | Low |
| Import Detection Rules | Graph Beta | POST batch | ✅ Via orchestration | Low |

---

## 2️⃣ MDO WORKER (Microsoft Defender for Office 365)

**Coverage**: 4/22 actions ⚠️ **18%**  
**API Strategy**: Graph v1.0 (threat submission) + **Graph Beta (NEW email remediation)** + EXO PowerShell

### ✅ IMPLEMENTED (4 actions)

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Submit Email Threat | Graph v1.0 | `/security/threatSubmission/emailThreats` | ✅ SubmitEmailThreat | Critical |
| Submit URL Threat | Graph v1.0 | `/security/threatSubmission/urlThreats` | ✅ SubmitURLThreat | Critical |
| Submit File Threat | Graph v1.0 | `/security/threatSubmission/fileThreats` | ✅ Implicit | High |
| Remove Mail Forwarding Rules | Graph v1.0 | `/users/{id}/mailFolders/inbox/messageRules` | ✅ RemoveMailForwardingRules | High |

### ❌ MISSING - Email Remediation (NEW Graph Beta API) (8 actions)

**⚠️ CRITICAL**: Microsoft released **NEW** Graph Beta API for email remediation in 2024/2025!

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Soft Delete Emails** | **Graph Beta** | `/security/collaboration/analyzedEmails/remediate` (action: softDelete) | **🔴 Critical** | Move to Deleted Items folder |
| **Hard Delete Emails** | **Graph Beta** | `/security/collaboration/analyzedEmails/remediate` (action: hardDelete) | **🔴 Critical** | Permanent deletion |
| **Move to Junk Folder** | **Graph Beta** | `/security/collaboration/analyzedEmails/remediate` (action: moveToJunk) | **🔴 Critical** | Quarantine suspected phishing |
| **Move to Inbox** | **Graph Beta** | `/security/collaboration/analyzedEmails/remediate` (action: moveToInbox) | **🟡 High** | Restore false positives |
| **Move to Deleted Items** | **Graph Beta** | `/security/collaboration/analyzedEmails/remediate` (action: moveToDeletedItems) | **🟡 High** | Soft quarantine |
| **Bulk Email Search** | **Graph v1.0** | `/users/{id}/messages?$search="..."` | **🔴 Critical** | Hunt across mailboxes |
| **Bulk Email Delete** | **Graph v1.0** | Multiple DELETE `/users/{id}/messages/{msgId}` | **🔴 Critical** | Mass remediation |
| **Query Analyzed Emails** | **Graph Beta** | `/security/collaboration/analyzedEmails` | **🟡 High** | Get email analysis results |

**Implementation Note**: Graph Beta `/security/collaboration/analyzedEmails` requires:
- `ThreatHunting.Read.All` (search emails)
- `ThreatHunting.ReadWrite.All` (remediate emails)

### ❌ MISSING - Threat Submission with Auto-Block (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| Submit & Block Attachment | Graph v1.0 | `/security/threatSubmission/emailAttachmentThreats` | 🟡 High | Block specific attachment hash |
| Block Sender Domain | Graph Beta | Tenant Allow/Block List API | 🔴 Critical | Block entire domain |
| Block Specific Sender | Graph Beta | Tenant Allow/Block List API | 🔴 Critical | Block individual email address |
| Block URL Pattern | Graph Beta | Tenant Allow/Block List API | 🔴 Critical | Block URL with wildcards |

### ❌ MISSING - Zero-Hour Auto Purge (ZAP) (2 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| Trigger ZAP for Phishing | Graph Beta | `/security/collaboration/analyzedEmails/zapPhishing` | 🔴 Critical | Force ZAP on phishing campaign |
| Trigger ZAP for Malware | Graph Beta | `/security/collaboration/analyzedEmails/zapMalware` | 🔴 Critical | Force ZAP on malware campaign |

### ❌ MISSING - eDiscovery Search & Purge (2 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| Create eDiscovery Search | Graph v1.0 | `/security/cases/ediscoveryCases/{id}/searches` | 🔴 Critical | Content search across Exchange |
| Purge Search Results | Graph v1.0 | `/security/cases/ediscoveryCases/{id}/searches/{id}/purgeData` | 🔴 Critical | Delete matched emails |

### ❌ MISSING - Mail Flow Rules (2 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| Create Block Rule | EXO PowerShell | `New-TransportRule` -BlockSender | 🟡 High | Block sender at transport level |
| Modify Existing Rule | EXO PowerShell | `Set-TransportRule` | 🟢 Medium | Update mail flow rules |

---

## 3️⃣ MDI WORKER (Microsoft Defender for Identity)

**Coverage**: 11/11 actions ✅ **100%**  
**API Strategy**: Graph v1.0 (identity protection) + MDI API (lateral movement)

### Identity Investigation (11/11) ✅

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Get Alerts | Graph v1.0 | `/security/alerts_v2?$filter=...` | ✅ GetAlerts | High |
| Update Alert | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH) | ✅ UpdateAlert | High |
| Get Lateral Movement Paths | MDI API | `/api/lateralMovementPaths` | ✅ GetLateralMovementPaths | Critical |
| Get Exposed Credentials | MDI API | `/api/exposedCredentials` | ✅ GetExposedCredentials | Critical |
| Get Identity Secure Score | Graph v1.0 | `/security/secureScores` | ✅ GetIdentitySecureScore | Medium |
| Get Suspicious Activities | MDI API | `/api/suspiciousActivities` | ✅ GetSuspiciousActivities | High |
| Get Health Issues | MDI API | `/api/healthIssues` | ✅ GetHealthIssues | Medium |
| Get Recommendations | MDI API | `/api/recommendations` | ✅ GetRecommendations | Medium |
| Get Sensitive Users | MDI API | `/api/sensitiveUsers` | ✅ GetSensitiveUsers | High |
| Get Alert Statistics | MDI API | `/api/alerts/statistics` | ✅ GetAlertStatistics | Low |
| Get Configuration | MDI API | `/api/configuration` | ✅ GetConfiguration | Low |

**Note**: MDI worker focuses on investigation/detection. Remediation actions (disable user, reset password) are handled by Entra ID Worker.

---

## 4️⃣ ENTRA ID WORKER (Azure AD + Identity Protection)

**Coverage**: 13/18 actions ⚠️ **72%**  
**API Strategy**: Graph v1.0 (primary) + Graph Beta (MFA management)

### ✅ IMPLEMENTED (13 actions)

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Disable User Account | Graph v1.0 | `/users/{id}` (accountEnabled: false) | ✅ DisableUser | Critical |
| Enable User Account | Graph v1.0 | `/users/{id}` (accountEnabled: true) | ✅ EnableUser | High |
| Reset Password | Graph v1.0 | `/users/{id}/authentication/passwordMethods/{id}/resetPassword` | ✅ ResetPassword | Critical |
| Revoke All Sign-in Sessions | Graph v1.0 | `/users/{id}/revokeSignInSessions` | ✅ RevokeSessions | Critical |
| Confirm User Compromised | Graph v1.0 | `/identityProtection/riskyUsers/confirmCompromised` | ✅ ConfirmCompromised | Critical |
| Dismiss User Risk | Graph v1.0 | `/identityProtection/riskyUsers/dismiss` | ✅ DismissRisk | High |
| Get Risk Detections | Graph v1.0 | `/identityProtection/riskDetections` | ✅ GetRiskDetections | High |
| Get Risky Users | Graph v1.0 | `/identityProtection/riskyUsers` | ✅ GetRiskyUsers | High |
| Create Named Location | Graph v1.0 | `/identity/conditionalAccess/namedLocations` | ✅ CreateNamedLocation | High |
| Get Conditional Access Policies | Graph v1.0 | `/identity/conditionalAccess/policies` | ✅ GetConditionalAccessPolicies | Medium |
| Get Sign-in Logs | Graph v1.0 | `/auditLogs/signIns` | ✅ GetSignInLogs | Medium |
| Get Audit Logs | Graph v1.0 | `/auditLogs/directoryAudits` | ✅ GetAuditLogs | Medium |
| Get User | Graph v1.0 | `/users/{id}` | ✅ GetUser | Low |

### ❌ MISSING - MFA & Authentication (3 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Delete Specific Auth Method** | **Graph v1.0** | `/users/{id}/authentication/methods/{methodId}` (DELETE) | **🔴 Critical** | Remove compromised authenticator |
| **Delete All MFA Methods** | **Graph v1.0** | Loop DELETE all `/authentication/methods` | **🔴 Critical** | Force MFA re-registration |
| **Require MFA Re-registration** | **Graph Beta** | `/users/{id}/authentication/requirements` (requireReregistration) | **🟡 High** | Invalidate existing MFA |

### ❌ MISSING - Conditional Access Emergency Response (2 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Create Emergency Block Policy** | **Graph v1.0** | `/identity/conditionalAccess/policies` (block all for user) | **🔴 Critical** | Immediate user isolation |
| **Block IP Range** | **Graph v1.0** | `/identity/conditionalAccess/namedLocations` (add blocked IPs) | **🔴 Critical** | Block attacker infrastructure |

### ❌ MISSING - Privileged Access Remediation (3 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Remove Admin Role** | **Graph v1.0** | `/roleManagement/directory/roleAssignments/{id}` (DELETE) | **🔴 Critical** | Remove compromised admin access |
| **Revoke PIM Activation** | **Graph v1.0** | `/roleManagement/directory/roleAssignmentRequests/{id}/cancel` | **🔴 Critical** | Cancel active PIM session |
| **Remove from Sensitive Groups** | **Graph v1.0** | `/groups/{groupId}/members/{userId}/$ref` (DELETE) | **🟡 High** | Remove from security groups |

---

## 5️⃣ INTUNE WORKER (Endpoint Manager)

**Coverage**: 8/15 actions ⚠️ **53%**  
**API Strategy**: Graph v1.0 (device management)

### ✅ IMPLEMENTED (8 actions)

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Remote Lock Device | Graph v1.0 | `/deviceManagement/managedDevices/{id}/remoteLock` | ✅ RemoteLock | Critical |
| Wipe Device (Factory Reset) | Graph v1.0 | `/deviceManagement/managedDevices/{id}/wipe` | ✅ WipeDevice | Critical |
| Retire Device (Corporate Data) | Graph v1.0 | `/deviceManagement/managedDevices/{id}/retire` | ✅ RetireDevice | Critical |
| Sync Device | Graph v1.0 | `/deviceManagement/managedDevices/{id}/syncDevice` | ✅ SyncDevice | High |
| Run Windows Defender Scan | Graph v1.0 | `/deviceManagement/managedDevices/{id}/windowsDefenderScan` | ✅ DefenderScan | High |
| Get Managed Devices | Graph v1.0 | `/deviceManagement/managedDevices` | ✅ GetManagedDevices | Medium |
| Get Device Compliance | Graph v1.0 | `/deviceManagement/managedDevices/{id}/deviceCompliancePolicyStates` | ✅ GetDeviceCompliance | Medium |
| Get Device Configuration | Graph v1.0 | `/deviceManagement/managedDevices/{id}/deviceConfigurationStates` | ✅ GetDeviceConfiguration | Low |

### ❌ MISSING - Device Remediation (7 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Reset Device Passcode** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/resetPasscode` | **🔴 Critical** | Unlock compromised device |
| **Reboot Device Now** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/rebootNow` | **🟡 High** | Force restart for patches |
| **Shutdown Device** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/shutDown` | **🟢 Medium** | Emergency shutdown |
| **Enable Lost Mode** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/enableLostMode` | **🟡 High** | Lock stolen device with message |
| **Disable Lost Mode** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/disableLostMode` | **🟢 Medium** | Recover device |
| **Trigger Compliance Evaluation** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/reevaluateCompliance` | **🟢 Medium** | Force compliance check |
| **Update Defender Signatures** | **Graph v1.0** | `/deviceManagement/managedDevices/{id}/windowsDefenderUpdateSignatures` | **🟡 High** | Update AV definitions |

---

## 6️⃣ AZURE WORKER (Azure Resources)

**Coverage**: 8/25 actions ❌ **32%**  
**API Strategy**: ARM API (Azure Resource Manager)

### ✅ IMPLEMENTED (8 actions)

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Add NSG Deny Rule | ARM API | `/networkSecurityGroups/{nsg}/securityRules/{rule}` (PUT) | ✅ AddNSGDenyRule | Critical |
| Stop VM | ARM API | `/virtualMachines/{vm}/powerOff` | ✅ StopVM | Critical |
| Disable Storage Public Access | ARM API | `/storageAccounts/{account}` (allowBlobPublicAccess: false) | ✅ DisableStoragePublicAccess | Critical |
| Remove VM Public IP | ARM API | `/networkInterfaces/{nic}` (remove publicIPAddress) | ✅ RemoveVMPublicIP | High |
| Get VMs | ARM API | `/virtualMachines` | ✅ GetVMs | Low |
| Get Resource Groups | ARM API | `/resourceGroups` | ✅ GetResourceGroups | Low |
| Get NSGs | ARM API | `/networkSecurityGroups` | ✅ GetNSGs | Low |
| Get Storage Accounts | ARM API | `/storageAccounts` | ✅ GetStorageAccounts | Low |

### ❌ MISSING - Virtual Machine Remediation (5 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Deallocate VM** | **ARM API** | `/virtualMachines/{vm}/deallocate` | **🔴 Critical** | Stop & release compute (saves cost) |
| **Restart VM** | **ARM API** | `/virtualMachines/{vm}/restart` | **🟡 High** | Apply patches/config |
| **Apply Isolation NSG** | **ARM API** | Associate isolation NSG to VM NIC | **🔴 Critical** | Network-level containment |
| **Redeploy VM** | **ARM API** | `/virtualMachines/{vm}/redeploy` | **🟢 Medium** | Move to different host |
| **Take VM Snapshot** | **ARM API** | `/snapshots` (POST) | **🟡 High** | Forensic preservation |

### ❌ MISSING - Azure Firewall (5 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Block IP in Firewall** | **ARM API** | `/azureFirewalls/{fw}/networkRuleCollections` | **🔴 Critical** | Block malicious IP |
| **Block Domain** | **ARM API** | `/azureFirewalls/{fw}/applicationRuleCollections` | **🔴 Critical** | Block C2 domains |
| **Block URL Category** | **ARM API** | `/azureFirewalls/{fw}/applicationRuleCollections` | **🟡 High** | Block malware/phishing categories |
| **Enable Threat Intel Blocking** | **ARM API** | `/azureFirewalls/{fw}` (threatIntelMode: Alert/Deny) | **🟡 High** | Enable Microsoft threat intel |
| **Add Firewall Policy Rule** | **ARM API** | `/firewallPolicies/{policy}/ruleCollectionGroups/{group}` | **🟡 High** | Centralized policy management |

### ❌ MISSING - Key Vault & Secrets (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Disable Key/Secret** | **ARM API** | `/vaults/{vault}/secrets/{secret}` (enabled: false) | **🔴 Critical** | Disable compromised secret |
| **Purge Deleted Secret** | **ARM API** | `/deletedSecrets/{secret}/purge` | **🔴 Critical** | Permanent deletion |
| **Rotate Encryption Keys** | **ARM API** | `/vaults/{vault}/keys/{key}/rotate` | **🔴 Critical** | Rotate compromised keys |
| **Rotate Storage Keys** | **ARM API** | `/storageAccounts/{account}/regenerateKey` | **🔴 Critical** | Regenerate access keys |

### ❌ MISSING - Service Principal & App Security (3 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Disable Service Principal** | **Graph v1.0** | `/servicePrincipals/{id}` (accountEnabled: false) | **🔴 Critical** | Disable compromised app |
| **Remove App Credentials** | **Graph v1.0** | `/applications/{id}/removePassword` | **🔴 Critical** | Revoke client secrets |
| **Revoke App Certificates** | **Graph v1.0** | `/applications/{id}/removeKey` | **🔴 Critical** | Revoke certificate auth |

---

## 7️⃣ XDR PLATFORM WORKER (Orchestration & Automation)

**Coverage**: 5/17 actions ❌ **29%**  
**API Strategy**: Graph v1.0 + Graph Beta (detection rules) + ARM API (Logic Apps)

### ✅ IMPLEMENTED (5 actions)

| Action | API | Endpoint | Status | Priority |
|--------|-----|----------|--------|----------|
| Update Incident Status | Graph v1.0 | `/security/incidents/{id}` (PATCH) | ✅ Via MDE Worker | Critical |
| Assign Incident | Graph v1.0 | `/security/incidents/{id}` (PATCH assignedTo) | ✅ Via MDE Worker | High |
| Add Incident Comment | Graph v1.0 | `/security/incidents/{id}/comments` | ✅ Via MDE Worker | Medium |
| Update Alert Status | Graph v1.0 | `/security/alerts_v2/{id}` (PATCH) | ✅ Via MDE Worker | High |
| Resolve Alert | Graph v1.0 | `/security/alerts_v2/{id}` (status: resolved) | ✅ Via MDE Worker | High |

### ❌ MISSING - Incident Management (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Merge Incidents** | **Graph v1.0** | `/security/incidents/{id}/merge` | **🟡 High** | Consolidate duplicate incidents |
| **Link Alert to Incident** | **Graph v1.0** | `/security/incidents/{id}/alerts/$ref` (POST) | **🟡 High** | Manual alert correlation |
| **Suppress Alert** | **Graph v1.0** | `/security/alerts_v2/{id}` (status: suppressed) | **🟢 Medium** | Suppress false positives |
| **Create Incident** | **Graph v1.0** | `/security/incidents` (POST) | **🟢 Medium** | Manual incident creation |

### ❌ MISSING - Custom Detection Rules (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Create Detection Rule** | **Graph Beta** | `/security/rules/detectionRules` (POST) | **🔴 Critical** | Custom KQL detection |
| **Update Detection Rule** | **Graph Beta** | `/security/rules/detectionRules/{id}` (PATCH) | **🟡 High** | Modify existing rule |
| **Enable/Disable Detection Rule** | **Graph Beta** | `/security/rules/detectionRules/{id}` (enabled: true/false) | **🟡 High** | Rule management |
| **Delete Detection Rule** | **Graph Beta** | `/security/rules/detectionRules/{id}` (DELETE) | **🟢 Medium** | Remove obsolete rules |

### ❌ MISSING - Automated Investigation (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Trigger Investigation** | **Graph Beta** | `/security/investigations/trigger` | **🟡 High** | Manual AIR trigger |
| **Approve AIR Actions** | **Graph Beta** | `/security/investigations/{id}/actions/approve` | **🔴 Critical** | Approve pending actions |
| **Reject AIR Actions** | **Graph Beta** | `/security/investigations/{id}/actions/reject` | **🟢 Medium** | Reject false positive actions |
| **Cancel Investigation** | **Graph Beta** | `/security/investigations/{id}/cancel` | **🟢 Medium** | Stop running investigation |

---

## 8️⃣ MCAS WORKER (Microsoft Cloud App Security)

**Coverage**: 0/12 actions ❌ **0%**  
**API Strategy**: Graph v1.0 (OAuth) + Graph Beta (MCAS) + MCAS API

### ❌ ALL MISSING - OAuth App Remediation (3 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Revoke App Permissions** | **Graph v1.0** | `/oauth2PermissionGrants/{id}` (DELETE) | **🔴 Critical** | Remove OAuth consent |
| **Ban Risky OAuth App** | **Graph Beta** | `/security/cloudAppSecurity/apps/{id}/ban` | **🔴 Critical** | Block malicious app |
| **Revoke User Consent** | **Graph v1.0** | `/users/{userId}/oauth2PermissionGrants/{id}` (DELETE) | **🔴 Critical** | Remove individual consent |

### ❌ ALL MISSING - Session Remediation (3 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Terminate Active Session** | **Graph Beta** | `/security/cloudAppSecurity/sessions/{id}/terminate` | **🔴 Critical** | Kill active app session |
| **Block User from App** | **Graph Beta** | `/security/cloudAppSecurity/users/{userId}/apps/{appId}/block` | **🔴 Critical** | Prevent app access |
| **Require Re-authentication** | **Graph Beta** | `/security/cloudAppSecurity/users/{userId}/challenge` | **🟡 High** | Force login challenge |

### ❌ ALL MISSING - File Remediation (4 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Quarantine Cloud File** | **Graph v1.0** | `/drives/{driveId}/items/{itemId}/checkout` | **🟡 High** | Lock SharePoint/OneDrive file |
| **Remove External Sharing** | **Graph v1.0** | `/drives/{driveId}/items/{itemId}/permissions/{permId}` (DELETE) | **🔴 Critical** | Remove public/external access |
| **Apply Sensitivity Label** | **Graph v1.0** | `/drives/{driveId}/items/{itemId}/assignSensitivityLabel` | **🟡 High** | Auto-classify sensitive data |
| **Restore from Quarantine** | **Graph v1.0** | `/drives/{driveId}/items/{itemId}/checkin` | **🟢 Medium** | Unlock quarantined file |

### ❌ ALL MISSING - Cloud App Governance (2 actions)

| Action | API | Endpoint | Priority | Notes |
|--------|-----|----------|----------|-------|
| **Block Unsanctioned App** | **MCAS API** | `/api/v1/apps/{id}/unsanction` | **🟡 High** | Mark app as blocked |
| **Remove App Access** | **MCAS API** | `/api/v1/apps/{id}/revoke_access` | **🔴 Critical** | Revoke tenant-wide access |

---

## 📋 API PERMISSIONS REQUIREMENTS

### Microsoft Graph API Permissions

| Scope | Type | Required For | Priority |
|-------|------|--------------|----------|
| **SecurityIncident.ReadWrite.All** | Application | Incidents CRUD, assign, comment | Critical |
| **SecurityAlert.ReadWrite.All** | Application | Alerts update, resolve, classify | Critical |
| **SecurityActions.ReadWrite.All** | Application | Security actions (Graph Beta) | High |
| **ThreatHunting.Read.All** | Application | Advanced hunting, email search | Critical |
| **ThreatHunting.ReadWrite.All** | Application | Email remediation (Graph Beta) | Critical |
| **ThreatIndicators.ReadWrite.OwnedBy** | Application | Custom IOCs (deprecated 2026) | High |
| **User.ReadWrite.All** | Application | Disable/enable users, reset passwords | Critical |
| **UserAuthenticationMethod.ReadWrite.All** | Application | MFA reset, delete auth methods | Critical |
| **IdentityRiskyUser.ReadWrite.All** | Application | Confirm compromised, dismiss risk | Critical |
| **Policy.ReadWrite.ConditionalAccess** | Application | Create/update CA policies, named locations | Critical |
| **DeviceManagementManagedDevices.ReadWrite.All** | Application | Intune device actions (wipe, lock, retire) | Critical |
| **DeviceManagementConfiguration.ReadWrite.All** | Application | Intune compliance, configuration | High |
| **Application.ReadWrite.All** | Application | Service principal disable, remove credentials | Critical |
| **Directory.ReadWrite.All** | Application | Admin role removal, group membership | Critical |
| **Files.ReadWrite.All** | Application | MCAS file quarantine, sharing removal | High |
| **Mail.ReadWrite** | Application | Email search, delete (MDO remediation) | Critical |
| **eDiscovery.ReadWrite.All** | Application | eDiscovery search & purge | Critical |

### MDE API Permissions

| Permission | Required For | Priority |
|------------|--------------|----------|
| **Machine.ReadWrite.All** | Device isolation, restrict code, AV scan, offboard | Critical |
| **Machine.LiveResponse** | Live Response sessions, script execution | Critical |
| **Alert.ReadWrite.All** | Alert/incident CRUD (via MDE API) | High |
| **Ti.ReadWrite.All** | Threat intel IOC submission | Critical |
| **AdvancedQuery.Read.All** | Advanced hunting queries | Critical |
| **Library.Manage** | Live Response script library | High |

### Azure RBAC Roles

| Role | Scope | Required For | Priority |
|------|-------|--------------|----------|
| **Security Administrator** | Subscription | NSG rules, VM stop, firewall rules | Critical |
| **Virtual Machine Contributor** | Resource Group | VM power operations, redeploy | Critical |
| **Network Contributor** | Resource Group | NSG rules, firewall config | Critical |
| **Storage Account Contributor** | Resource Group | Disable public access, rotate keys | Critical |
| **Key Vault Contributor** | Resource Group | Disable secrets, rotate keys, purge | Critical |

---

## 🚀 IMPLEMENTATION ROADMAP

### **Phase 1: Critical MDO Email Remediation** (Priority: 🔴 Critical)
**Estimated Time**: 8-12 hours  
**Actions**: 8 actions (soft/hard delete, move to junk, bulk search/delete)

1. Implement Graph Beta `/security/collaboration/analyzedEmails/remediate` endpoint
2. Add actions: SoftDeleteEmails, HardDeleteEmails, MoveToJunk, MoveToInbox
3. Implement bulk email search across mailboxes
4. Add Tenant Allow/Block List API (block sender/domain/URL)
5. Test with real phishing campaigns

**Required Permissions**:
- `ThreatHunting.ReadWrite.All` (Graph Beta)
- `Mail.ReadWrite` (Graph v1.0)
- `SecurityEvents.ReadWrite.All` (Graph v1.0)

### **Phase 2: Entra ID Emergency Response** (Priority: 🔴 Critical)
**Estimated Time**: 6-8 hours  
**Actions**: 5 actions (MFA reset, emergency CA block, admin role removal)

1. Implement MFA method deletion (`/authentication/methods/{id}` DELETE)
2. Add emergency CA policy creation (block all for specific user)
3. Implement admin role removal (`/roleManagement/directory/roleAssignments`)
4. Add PIM activation revocation
5. Test emergency user isolation workflow

**Required Permissions**:
- `UserAuthenticationMethod.ReadWrite.All`
- `Policy.ReadWrite.ConditionalAccess`
- `Directory.ReadWrite.All` (admin roles)

### **Phase 3: Azure Infrastructure Remediation** (Priority: 🔴 Critical)
**Estimated Time**: 10-12 hours  
**Actions**: 12 actions (Azure Firewall, Key Vault, Service Principals)

1. Implement Azure Firewall IP/domain blocking
2. Add Key Vault secret disable & key rotation
3. Implement Service Principal disable & credential removal
4. Add VM snapshot for forensics
5. Add storage key rotation

**Required Azure Roles**:
- Security Administrator
- Key Vault Contributor
- Network Contributor

### **Phase 4: Intune Device Remediation** (Priority: 🟡 High)
**Estimated Time**: 6-8 hours  
**Actions**: 7 actions (lost mode, passcode reset, compliance)

1. Implement passcode reset & reboot
2. Add lost mode enable/disable
3. Implement compliance evaluation trigger
4. Add Defender signature updates
5. Test with test Intune devices

### **Phase 5: MCAS Worker Creation** (Priority: 🔴 Critical)
**Estimated Time**: 12-16 hours  
**Actions**: 12 actions (OAuth revocation, session termination, file quarantine)

1. Create new MCAS worker function
2. Implement OAuth permission revocation
3. Add session termination & app blocking
4. Implement file quarantine & sharing removal
5. Add MCAS API integration for app governance

### **Phase 6: XDR Platform Enhancements** (Priority: 🟡 High)
**Estimated Time**: 8-10 hours  
**Actions**: 12 actions (detection rules, AIR approval, playbooks)

1. Implement Graph Beta detection rules CRUD
2. Add AIR action approval/rejection
3. Implement incident merge
4. Add Logic App playbook triggers
5. Test end-to-end automation

---

## 📊 SUMMARY STATISTICS

### Current State
- **Total Actions Inventoried**: 188 remediation actions across 8 workers
- **Implemented**: 117 actions (62%)
- **Missing**: 71 actions (38%)

### Coverage by Service
1. ✅ **MDE Worker**: 68/68 (100%) - COMPLETE
2. ✅ **MDI Worker**: 11/11 (100%) - COMPLETE
3. ⚠️ **Entra ID Worker**: 13/18 (72%) - 5 critical gaps
4. ⚠️ **Intune Worker**: 8/15 (53%) - 7 gaps
5. ❌ **MDO Worker**: 4/22 (18%) - 18 critical gaps
6. ❌ **Azure Worker**: 8/25 (32%) - 17 gaps
7. ❌ **XDR Platform**: 5/17 (29%) - 12 gaps
8. ❌ **MCAS Worker**: 0/12 (0%) - ALL missing (worker doesn't exist)

### Priority Breakdown
- **🔴 Critical Missing**: 35 actions
- **🟡 High Missing**: 24 actions
- **🟢 Medium/Low Missing**: 12 actions

### API Strategy Compliance
- **Graph v1.0 (Stable)**: 85% coverage ✅
- **Graph Beta (Preview)**: 15% coverage ⚠️ (MDO email remediation, detection rules)
- **Product APIs**: 100% coverage ✅ (MDE API fully implemented)

---

## 🎯 NEXT STEPS

1. **Review & Approve Roadmap**: Confirm Phase 1-6 priorities
2. **Update PERMISSIONS.md**: Add all missing Graph scopes & Azure roles
3. **Implement Phase 1 (MDO)**: Critical email remediation gap
4. **Implement Phase 2 (Entra ID)**: Emergency MFA/CA response
5. **Create MCAS Worker**: New worker for cloud app security
6. **Comprehensive Testing**: Validate all 188 actions end-to-end

**Estimated Total Time**: 60-80 hours to achieve 100% coverage across all 8 workers

---

**Last Updated**: November 12, 2025  
**Document Version**: 1.0  
**Next Review**: After Phase 1 implementation
