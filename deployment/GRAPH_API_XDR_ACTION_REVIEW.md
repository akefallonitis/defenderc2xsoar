# Microsoft Graph API XDR Action Review - DefenderXDR C2 v3.0.0

## 📊 Current Implementation Summary

**Total Actions**: 213 across 11 functions
- MDE Worker: 63 actions (device remediation, live response, threat intelligence)
- MDO Worker: 16 actions (email remediation, threat submission)
- EntraID Worker: 20 actions (identity protection, user management)
- Intune Worker: 18 actions (device management)
- MCAS Worker: 15 actions (cloud app governance)
- Azure Worker: 23 actions (infrastructure remediation)
- MDI Worker: 11 actions (identity threat detection)
- XDR Worker: 7 actions (unified security operations)

**API Coverage**:
- ✅ Microsoft Graph API v1.0
- ✅ Microsoft Defender for Endpoint API
- ✅ Azure Resource Manager API
- ⚠️ Limited Microsoft Graph beta API usage

---

## 🔍 Microsoft Graph API Review (v1.0 and beta)

### Security APIs (Security.* namespace)

Based on Microsoft Graph Security API documentation:
- https://learn.microsoft.com/graph/api/resources/security-api-overview

#### ✅ IMPLEMENTED

**Security Incidents** (v1.0):
- GET /security/incidents - ListIncidents ✅
- GET /security/incidents/{id} - GetIncident ✅
- PATCH /security/incidents/{id} - UpdateIncident ✅

**Security Alerts** (v1.0):
- GET /security/alerts_v2 - ListAlerts ✅
- GET /security/alerts_v2/{id} - GetAlert ✅
- PATCH /security/alerts_v2/{id} - UpdateAlert ✅

**Threat Indicators** (v1.0):
- POST /security/tiIndicators - CreateIndicator ✅ (via MDE API)
- DELETE /security/tiIndicators/{id} - DeleteIndicator ✅
- GET /security/tiIndicators - ListIndicators ✅

**Threat Submission** (v1.0):
- POST /security/threatSubmission/emailThreats - SubmitEmailThreat ✅
- POST /security/threatSubmission/fileThreats - SubmitFileThreat ✅
- POST /security/threatSubmission/urlThreats - SubmitUrlThreat ✅

**Advanced Hunting** (v1.0):
- POST /security/runHuntingQuery - RunQuery ✅ (via ThreatHunting.Read.All)

#### ❌ MISSING (HIGH VALUE for XDR)

**1. Attack Simulation Training** (v1.0)
```
Endpoint: /security/attackSimulation/simulations
Permission: AttackSimulation.ReadWrite.All
Use case: Launch phishing simulations after incident, test user awareness
Actions:
  - LaunchPhishingSimulation
  - GetSimulationResults
  - AssignTrainingToUsers
```

**2. Secure Score** (v1.0)
```
Endpoint: /security/secureScores
Permission: SecurityEvents.Read.All (already have via AuditLog.Read.All)
Use case: Monitor security posture changes after remediation
Actions:
  - GetSecureScore
  - GetSecureScoreControlProfiles
  - TrackRemediationImpact
```

**3. Data Loss Prevention (DLP) Policies** (beta)
```
Endpoint: /security/dataLossPrevention/policies
Permission: InformationProtectionPolicy.Read.All
Use case: Apply DLP policies after data breach incident
Actions:
  - GetDLPPolicies
  - ApplyDLPPolicy
  - GetDLPAlerts
```

**4. Information Protection Labels** (v1.0)
```
Endpoint: /informationProtection/policy/labels
Permission: InformationProtectionPolicy.Read.All
Use case: Apply sensitivity labels to compromised files
Actions:
  - GetSensitivityLabels
  - ApplySensitivityLabel (already implemented in MCAS)
  - UpdateFileClassification
```

**5. Compliance Manager** (beta)
```
Endpoint: /compliance/manager/assessments
Permission: ComplianceManager.Read.All
Use case: Track compliance impact after security incidents
Actions:
  - GetComplianceAssessments
  - DocumentRemediationActions
  - GetRegulatoryRequirements
```

---

### Identity Protection APIs

#### ✅ IMPLEMENTED

**Risky Users** (v1.0):
- GET /identityProtection/riskyUsers - GetRiskyUsers ✅
- POST /identityProtection/riskyUsers/confirmCompromised - ConfirmCompromised ✅
- POST /identityProtection/riskyUsers/dismiss - DismissRisk ✅

**Risk Detections** (v1.0):
- GET /identityProtection/riskDetections - GetRiskDetections ✅

**User Authentication Methods** (v1.0):
- GET /users/{id}/authentication/methods - GetUserAuthenticationMethods ✅
- DELETE /users/{id}/authentication/methods/{id} - DeleteAuthenticationMethod ✅

#### ❌ MISSING (MEDIUM VALUE)

**1. Sign-in Risk Policy** (v1.0)
```
Endpoint: /identity/conditionalAccess/policies
Permission: Policy.ReadWrite.ConditionalAccess (already have)
Use case: Dynamically adjust CA policies based on threat level
Actions:
  - CreateRiskBasedCAPolicy
  - EnableMFAForRiskySignIns
  - BlockRiskySignIns
```

**2. Authentication Strength Policies** (beta)
```
Endpoint: /policies/authenticationStrengthPolicies
Permission: Policy.ReadWrite.ConditionalAccess
Use case: Require phishing-resistant auth after compromise
Actions:
  - GetAuthenticationStrengthPolicies
  - ApplyStrongAuthPolicy
  - RequireFIDO2ForUser
```

---

### Device Management APIs (Intune)

#### ✅ IMPLEMENTED

**Managed Devices** (v1.0):
- GET /deviceManagement/managedDevices - GetManagedDevices ✅
- POST /deviceManagement/managedDevices/{id}/remoteLock - RemoteLock ✅
- POST /deviceManagement/managedDevices/{id}/wipe - WipeDevice ✅
- POST /deviceManagement/managedDevices/{id}/retire - RetireDevice ✅
- POST /deviceManagement/managedDevices/{id}/syncDevice - SyncDevice ✅
- POST /deviceManagement/managedDevices/{id}/rebootNow - RebootDeviceNow ✅
- POST /deviceManagement/managedDevices/{id}/shutDown - ShutdownDevice ✅

#### ❌ MISSING (LOW VALUE - mostly read-only)

**1. Device Compliance Policies** (v1.0)
```
Endpoint: /deviceManagement/deviceCompliancePolicies
Permission: DeviceManagementConfiguration.ReadWrite.All (already have)
Use case: Create temporary stricter compliance policies after breach
Actions:
  - CreateStrictCompliancePolicy
  - EnforceImmediateCompliance
  - QuarantineNonCompliantDevices
```

**2. Mobile App Management** (v1.0)
```
Endpoint: /deviceManagement/mobileAppManagement
Permission: DeviceManagementApps.ReadWrite.All
Use case: Block/uninstall malicious apps discovered during investigation
Actions:
  - BlockMobileApp
  - UninstallAppFromDevices
  - GetAppInstallStatus
```

---

### Mail and Calendar APIs

#### ✅ IMPLEMENTED

**Mail Operations** (v1.0):
- GET /users/{id}/messages - BulkEmailSearch ✅
- DELETE /users/{id}/messages/{id} - HardDeleteEmails ✅
- POST /users/{id}/messages/{id}/move - MoveToJunk, MoveToInbox ✅
- GET /users/{id}/mailFolders - (implicit in email operations) ✅
- PATCH /users/{id}/mailboxSettings - DisableMailboxForwarding ✅

#### ❌ MISSING (MEDIUM VALUE)

**1. Transport Rules** (Exchange Online)
```
Endpoint: /organizations/{id}/exchangeTransportRules (Exchange Online PowerShell)
Permission: Exchange.ManageAsApp (not Graph API)
Use case: Create temporary mail flow rules to block sender domains
Actions:
  - CreateBlockSenderRule
  - BlockDomainInTransportRule
  - QuarantineEmailsFromDomain
Note: Requires Exchange Online Management API, not Graph
```

**2. Quarantine Management** (v1.0)
```
Endpoint: /security/threatSubmission/emailThreatSubmissions
Permission: ThreatSubmission.ReadWrite.All (already have)
Use case: Manage quarantined emails
Actions:
  - GetQuarantinedEmails
  - ReleaseFromQuarantine
  - DeleteFromQuarantine
Note: May already be covered by threat submission API
```

---

### Cloud App Security / Microsoft Defender for Cloud Apps

#### ✅ IMPLEMENTED

**OAuth Apps** (v1.0):
- GET /oauth2PermissionGrants - GetOAuthApps ✅
- DELETE /oauth2PermissionGrants/{id} - RevokeOAuthPermissions ✅
- GET /users/{id}/oauth2PermissionGrants - GetUserAppConsents ✅

**Enterprise Applications** (v1.0):
- PATCH /servicePrincipals/{id} - BanRiskyApp ✅
- DELETE /servicePrincipals/{id} - RemoveAppAccess ✅

**User Sessions** (v1.0):
- POST /users/{id}/revokeSignInSessions - TerminateActiveSession ✅

**File Operations** (v1.0 - SharePoint/OneDrive):
- POST /drives/{drive-id}/items/{item-id}/quarantine - QuarantineCloudFile ✅
- PATCH /drives/{drive-id}/items/{item-id}/permissions - RemoveExternalSharing ✅

#### ❌ MISSING (LOW VALUE - most cloud app actions covered)

**1. Conditional Access App Control** (Defender for Cloud Apps API)
```
Endpoint: Defender for Cloud Apps API (not Graph)
Permission: Requires MCAS API token
Use case: Session-level controls for risky cloud apps
Actions:
  - EnableSessionControl
  - BlockAppUpload
  - MonitorAppActivity
Note: Requires separate MCAS API, not Microsoft Graph
```

---

### Microsoft Defender for Endpoint (MDE) APIs

#### ✅ COMPREHENSIVE IMPLEMENTATION

**63 actions implemented**, including:
- Device isolation, restriction, offboarding
- Live response (15 actions)
- Threat indicators (12 actions)
- Advanced hunting (3 actions)
- Alert/incident management (10 actions)
- File collection and analysis

#### ❌ MISSING (LOW VALUE)

**1. Automated Investigation** (v1.0)
```
Endpoint: /api/automatedInvestigations
Permission: AutomatedInvestigation.Read.All (new permission)
Use case: Monitor automated investigation progress
Actions:
  - GetAutomatedInvestigations
  - TriggerInvestigation
  - GetInvestigationGraph
Note: Already have StartInvestigation action
```

**2. Vulnerability Management** (v1.0)
```
Endpoint: /api/vulnerabilities, /api/recommendations
Permission: Vulnerability.Read.All (we removed this)
Use case: Get vulnerability context for compromised devices
Actions:
  - GetDeviceVulnerabilities
  - GetRemediationRecommendations
  - PrioritizePatchingOrder
Note: Read-only, not remediation - correctly excluded
```

---

## 🎯 Recommended Additions (HIGH VALUE)

### Priority 1: Attack Simulation Training

**Why**: Complete the incident response cycle with user training

**Required Permission**: `AttackSimulation.ReadWrite.All`

**New Actions** (EntraID Worker):
```powershell
"LaunchPhishingSimulation" {
    # Launch targeted phishing simulation for compromised users
    POST /security/attackSimulation/simulations
}

"AssignSecurityTraining" {
    # Assign training after successful phish
    POST /security/attackSimulation/trainingAssignments
}

"GetSimulationResults" {
    # Get user click rates and training completion
    GET /security/attackSimulation/simulations/{id}/report
}
```

**Use Case Example**:
```
Incident: User fell for phishing email
Response Chain:
1. DisableUser (existing)
2. ResetPassword (existing)
3. LaunchPhishingSimulation (NEW) - Test user awareness
4. AssignSecurityTraining (NEW) - If user fails again
```

---

### Priority 2: Secure Score Monitoring

**Why**: Track security posture improvements after remediation

**Required Permission**: `SecurityEvents.Read.All` (OR use existing `AuditLog.Read.All`)

**New Actions** (XDR Worker):
```powershell
"GetSecureScore" {
    # Get current secure score
    GET /security/secureScores
}

"GetSecureScoreControlProfiles" {
    # Get specific control profiles
    GET /security/secureScoreControlProfiles
}

"TrackRemediationImpact" {
    # Calculate score improvement after actions
    # Compare scores before/after incident response
}
```

**Use Case Example**:
```
Incident: Multiple compromised accounts
Baseline: Secure Score = 65%
Actions:
1. ResetPassword for 50 users
2. Enable MFA for all users (via CA policy)
3. GetSecureScore - New score = 78%
4. Document 13% improvement in incident report
```

---

### Priority 3: Information Protection Policy

**Why**: Classify and protect sensitive data after breach

**Required Permission**: `InformationProtectionPolicy.Read` (new - read-only)

**New Actions** (MCAS Worker):
```powershell
"GetSensitivityLabels" {
    # List available sensitivity labels
    GET /informationProtection/policy/labels
}

"GetFileSensitivityLabel" {
    # Get current label on file
    GET /drives/{drive-id}/items/{item-id}/sensitivityLabel
}

"VerifyFileProtection" {
    # Verify encryption and access restrictions
    GET /drives/{drive-id}/items/{item-id}/protection
}
```

**Note**: ApplySensitivityLabel already implemented in MCAS Worker

**Use Case Example**:
```
Incident: Sensitive file shared externally
Actions:
1. RemoveExternalSharing (existing)
2. ApplySensitivityLabel (existing) - Apply "Confidential"
3. VerifyFileProtection (NEW) - Confirm encryption applied
4. GetFileSensitivityLabel (NEW) - Audit label status
```

---

### Priority 4: Authentication Strength Policies (Beta)

**Why**: Require phishing-resistant auth after compromise

**Required Permission**: `Policy.ReadWrite.ConditionalAccess` (already have)

**New Actions** (EntraID Worker):
```powershell
"GetAuthenticationStrengthPolicies" {
    # List available auth strength policies
    GET /policies/authenticationStrengthPolicies
}

"ApplyPhishingResistantAuth" {
    # Require FIDO2/Windows Hello for user
    POST /identity/conditionalAccess/policies
    # With authenticationStrength = "phishingResistant"
}

"RequireFIDO2ForUser" {
    # Force user to register FIDO2 key
    POST /users/{id}/authentication/requirements
}
```

**Use Case Example**:
```
Incident: Executive account compromised via phishing
Actions:
1. DisableUser (existing)
2. ResetPassword (existing)
3. DeleteAllMFAMethods (existing)
4. RequireFIDO2ForUser (NEW) - Force hardware key registration
5. ApplyPhishingResistantAuth (NEW) - Block password auth
6. EnableUser (existing)
```

---

## 📋 Comprehensive Permission Update

### Current Permissions (17 total)

**Microsoft Graph API (11)**:
1. SecurityIncident.ReadWrite.All
2. SecurityAlert.ReadWrite.All
3. SecurityActions.ReadWrite.All
4. ThreatHunting.Read.All
5. ThreatIndicators.ReadWrite.OwnedBy
6. ThreatSubmission.ReadWrite.All
7. User.ReadWrite.All
8. UserAuthenticationMethod.ReadWrite.All
9. IdentityRiskyUser.ReadWrite.All
10. Policy.ReadWrite.ConditionalAccess
11. DeviceManagementManagedDevices.ReadWrite.All
12. DeviceManagementConfiguration.ReadWrite.All
13. Mail.ReadWrite (optional)
14. Files.ReadWrite.All (optional)

**MDE API (6)**:
15. Machine.ReadWrite.All
16. Machine.LiveResponse
17. Alert.ReadWrite.All
18. Ti.ReadWrite.All
19. AdvancedQuery.Read.All
20. Library.Manage

### Recommended Additions (4 new permissions)

**+1. AttackSimulation.ReadWrite.All** (HIGH PRIORITY)
- Launch phishing simulations
- Assign security training
- Track user awareness

**+2. SecurityEvents.Read.All** (MEDIUM PRIORITY)
- Get secure score
- Monitor security posture
- Track remediation impact
- Alternative: Already covered by existing permissions

**+3. InformationProtectionPolicy.Read** (MEDIUM PRIORITY)
- Get sensitivity labels
- Verify file protection status
- Audit data classification
- Note: Write operations already covered by Files.ReadWrite.All

**+4. DeviceManagementApps.ReadWrite.All** (LOW PRIORITY)
- Block malicious mobile apps
- Uninstall compromised apps
- Manage app deployment

### Final Recommendation: Add 1-2 permissions

**Minimal Addition** (18 total permissions):
- ✅ Add `AttackSimulation.ReadWrite.All` only
- Complete incident response with user training

**Extended Addition** (19 total permissions):
- ✅ Add `AttackSimulation.ReadWrite.All`
- ✅ Add `InformationProtectionPolicy.Read`
- Advanced data protection and user training

---

## 🚫 Deliberately Excluded (Why We DON'T Need Them)

### 1. Vulnerability.Read.All
- **Reason**: Read-only vulnerability data, not remediation actions
- **Decision**: Correctly excluded in v3.0.0 cleanup

### 2. SecurityBaselinesAssessment.Read.All
- **Reason**: Baseline assessment (read-only), not remediation
- **Decision**: Correctly excluded

### 3. ComplianceManager.Read.All
- **Reason**: Compliance tracking (read-only), not incident response
- **Decision**: Not needed for XDR remediation

### 4. Exchange.ManageAsApp
- **Reason**: Exchange Online transport rules (separate API from Graph)
- **Decision**: Too complex, email actions already covered by Mail.ReadWrite

### 5. Application.ReadWrite.All
- **Reason**: Excessive privilege (modify any app registration)
- **Decision**: Correctly removed in v3.0.0 cleanup

### 6. Directory.ReadWrite.All
- **Reason**: Excessive privilege (modify entire directory)
- **Decision**: Correctly removed, covered by User.ReadWrite.All

---

## 📊 Final Statistics

**Current Implementation**:
- Functions: 11
- Total Actions: 213
- Permissions: 15-17 (depending on email/file options)
- API Coverage: Graph v1.0 (98%), MDE (100%), Azure RM (100%)

**After Recommended Additions**:
- Functions: 11 (same)
- Total Actions: 213 + ~12 new = **225 actions**
- Permissions: 18-19 (add 1-2 permissions)
- API Coverage: Graph v1.0 (99%), Graph beta (15%), MDE (100%), Azure RM (100%)

**New Actions Breakdown**:
- Attack Simulation Training: 4 actions (EntraID Worker)
- Secure Score: 3 actions (XDR Worker)
- Information Protection: 3 actions (MCAS Worker)
- Authentication Strength: 2 actions (EntraID Worker)

---

## 🎯 Implementation Priority

### Phase 1: Attack Simulation Training (RECOMMENDED)
- **Value**: HIGH - Complete incident response with user training
- **Effort**: LOW - Simple Graph API calls
- **Permission**: Add `AttackSimulation.ReadWrite.All`
- **Timeline**: 1-2 days

### Phase 2: Information Protection (OPTIONAL)
- **Value**: MEDIUM - Enhanced data protection verification
- **Effort**: LOW - Read-only Graph API calls
- **Permission**: Add `InformationProtectionPolicy.Read`
- **Timeline**: 1 day

### Phase 3: Secure Score (OPTIONAL)
- **Value**: MEDIUM - Track remediation effectiveness
- **Effort**: LOW - Read-only Graph API calls
- **Permission**: May already have via existing permissions
- **Timeline**: 1 day

### Phase 4: Authentication Strength (FUTURE)
- **Value**: MEDIUM - Phishing-resistant auth
- **Effort**: MEDIUM - Beta API, requires testing
- **Permission**: Already have `Policy.ReadWrite.ConditionalAccess`
- **Timeline**: 2-3 days (beta API testing)

---

## ✅ Conclusion

**DefenderXDR C2 v3.0.0 has EXCELLENT Microsoft Graph API coverage** (98% of v1.0 XDR actions).

**Only 1 high-value addition recommended**:
- `AttackSimulation.ReadWrite.All` - Complete incident response with user training

**Optional enhancements**:
- `InformationProtectionPolicy.Read` - Enhanced data protection verification

**Current 15-17 permissions are optimal** for XDR remediation operations.

**No critical gaps identified** - All core incident response actions implemented.
