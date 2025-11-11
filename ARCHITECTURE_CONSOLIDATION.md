# DefenderC2XSOAR Architecture Consolidation Analysis

## Executive Summary

**Current State**: 7 services with potential duplication
**Recommendation**: Consolidate to 5 core services + 1 optional infrastructure service

---

## Service Analysis

### ✅ **CORE SERVICES - KEEP AS-IS**

#### 1. **MDE (Microsoft Defender for Endpoint)**
- **API**: Microsoft Graph `security/alerts_v2` + MDE-specific API (`api.securitycenter.microsoft.com`)
- **Scope**: Endpoint/device security, threat hunting, device isolation, live response
- **Unique Actions**: Device isolation, app execution restriction, antivirus scans, forensics collection
- **serviceSource**: `microsoftDefenderForEndpoint`
- **Status**: ✅ **KEEP** - Core endpoint security

#### 2. **EntraID (Azure AD Identity Protection)**
- **API**: Microsoft Graph `identityProtection` + `users`
- **Scope**: User identity management, risky users, password reset, account disable
- **Unique Actions**: Password reset, revoke sessions, confirm compromised, dismiss risk
- **Status**: ✅ **KEEP** - Core identity security

#### 3. **Intune (Mobile Device Management)**
- **API**: Microsoft Graph `deviceManagement`
- **Scope**: Intune-managed devices (mobile, BYOD), remote lock, wipe, retire
- **Unique Actions**: Remote lock, device wipe, device retire, compliance status
- **Status**: ✅ **KEEP** - Core MDM (distinct from MDE endpoints)

#### 4. **MDI (Microsoft Defender for Identity)**
- **API**: Microsoft Graph `security/alerts_v2` (filtered by MDI)
- **Scope**: Identity attacks, lateral movement, credential theft, domain controller security
- **Unique Actions**: Lateral movement paths, exposed credentials, privilege escalation, reconnaissance
- **serviceSource**: `microsoftDefenderForIdentity`
- **Status**: ✅ **KEEP** - Specialized identity threat detection

#### 5. **Azure (Infrastructure Management)**
- **API**: Azure Resource Manager `management.azure.com`
- **Scope**: Azure infrastructure security (NSG rules, VM management, storage accounts)
- **Unique Actions**: Add NSG rules, stop VMs, disable storage public access, remove public IPs
- **Status**: ✅ **KEEP** - Critical infrastructure remediation

---

### ⚠️ **DUPLICATE/CONSOLIDATE**

#### 6. **MDC (Microsoft Defender for Cloud)** - CONSOLIDATE
- **API**: Azure Resource Manager `management.azure.com/providers/Microsoft.Security`
- **Scope**: Cloud security posture, compliance, infrastructure recommendations
- **Current Actions**:
  - ✅ Get security alerts → **DUPLICATE** (available in Graph API `security/alerts_v2` with `serviceSource eq 'microsoftDefenderForCloud'`)
  - ✅ Get recommendations → **INFRASTRUCTURE-SPECIFIC** (keep)
  - ✅ Secure score → **INFRASTRUCTURE-SPECIFIC** (keep)
  - ✅ Defender plans → **INFRASTRUCTURE-SPECIFIC** (keep)
  - ✅ JIT access → **INFRASTRUCTURE-SPECIFIC** (keep)

**Recommendation**: 
- **MERGE MDC alerts into unified GetAllAlerts** (already accessible via Graph API)
- **MOVE infrastructure-specific actions to Azure service** (recommendations, secure score, JIT access)
- **DEPRECATE standalone MDC service**

#### 7. **MDO (Microsoft Defender for Office 365)** - WRITE-ONLY
- **API**: Microsoft Graph `mail` + `security/threatSubmission`
- **Scope**: Email remediation, phishing submissions
- **Status**: ⚠️ **WRITE-ONLY** - No read/query actions, primarily remediation

---

## Unified Security Alerts Architecture

### **Current Problem**: Fragmented Alert Sources
```
MDE Worker    → MDE API → Devices/Endpoints alerts
MDI Worker    → Graph API → Identity alerts (filtered)
MDC Worker    → Azure RM API → Cloud infrastructure alerts
```

### **Solution**: Unified Graph API `security/alerts_v2`
```
Unified GetAllAlerts → Microsoft Graph security/alerts_v2
  ├── Filter: serviceSource eq 'microsoftDefenderForEndpoint'  (MDE)
  ├── Filter: serviceSource eq 'microsoftDefenderForIdentity'  (MDI)
  ├── Filter: serviceSource eq 'microsoftDefenderForCloud'      (MDC)
  ├── Filter: serviceSource eq 'microsoftDefenderForOffice365'  (MDO)
  └── Filter: (none) → ALL Defender XDR alerts
```

**Benefits**:
- ✅ Single API call for all security alerts
- ✅ Consistent alert schema across all Defender products
- ✅ Reduced complexity and maintenance
- ✅ Microsoft's recommended approach (Defender XDR portal unification)

---

## Recommended Consolidation Plan

### **Phase 1: Unify Alert Retrieval** ✅ ALREADY DONE
- [x] `GetAllAlerts` uses Graph API `security/alerts_v2`
- [x] Returns all Defender XDR alerts (MDE, MDI, MDC, MDO)
- [x] Supports filtering by `serviceSource`

### **Phase 2: Move MDC Infrastructure Actions to Azure Service**
- [ ] Move `GetSecurityRecommendations` to Azure service
- [ ] Move `GetSecureScore` to Azure service
- [ ] Move `GetDefenderPlans`/`EnableDefenderPlan` to Azure service
- [ ] Move `GetJitAccessPolicy`/`NewJitAccessRequest` to Azure service

### **Phase 3: Deprecate MDC Worker**
- [ ] Remove `DefenderXDRMDCWorker` function
- [ ] Remove `DefenderForCloud.psm1` module
- [ ] Update Orchestrator to remove MDC service routing
- [ ] Update documentation

### **Phase 4: Update Tests**
- [ ] Remove MDC-specific tests
- [ ] Add Azure infrastructure tests
- [ ] Verify unified alerts include all sources

---

## Final Architecture (Post-Consolidation)

### **5 Core Services**
1. **MDE** - Endpoint security, device management, threat hunting
2. **EntraID** - Identity management, risky users, password security
3. **Intune** - Mobile device management (distinct from MDE endpoints)
4. **MDI** - Identity attack detection, lateral movement
5. **Azure** - Infrastructure security (NSG, VMs, storage, MDC recommendations/compliance)

### **Optional Service**
6. **MDO** - Email remediation (write-only, no read actions)

### **Alert Retrieval**
- **Unified**: `GetAllAlerts` via Graph API `security/alerts_v2`
- **Filtered**: Support `serviceSource` parameter to filter by product

---

## Migration Impact

### **Breaking Changes**: None
- MDC alerts still accessible via unified `GetAllAlerts`
- Infrastructure actions moved to Azure service (same functionality, different service name)

### **API Changes**: None
- Gateway API unchanged
- Request format: `{ service: 'Azure', action: 'GetSecureScore' }` instead of `{ service: 'MDC', action: 'GetSecureScore' }`

### **Performance**: Improved
- Fewer API calls (unified alerts)
- Reduced token acquisitions
- Simpler routing logic

---

## Implementation Checklist

- [ ] Create backup of current MDC module
- [ ] Add MDC infrastructure functions to `AzureInfrastructure.psm1`
- [ ] Update Orchestrator Azure service actions
- [ ] Remove MDC service routing from Orchestrator
- [ ] Delete `DefenderXDRMDCWorker` function
- [ ] Delete `DefenderForCloud.psm1` module
- [ ] Update documentation (README, deployment guides)
- [ ] Update test scripts
- [ ] Create deployment package and push to GitHub
- [ ] Test all infrastructure actions via Azure service
- [ ] Verify unified alerts include MDC alerts

---

## Conclusion

**Consolidating MDC into Azure service aligns with Microsoft's Defender XDR unification strategy while maintaining full functionality and improving architecture clarity.**

**Key Benefits**:
- ✅ Reduced complexity (5 services instead of 7)
- ✅ Unified alert retrieval (Graph API standard)
- ✅ Clearer separation: Security operations (MDE/MDI/EntraID/Intune) vs Infrastructure (Azure)
- ✅ Easier maintenance and testing
- ✅ Follows Microsoft's recommended architecture

**Timeline**: 1-2 hours to implement, test, and deploy
