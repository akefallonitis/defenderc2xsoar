# DefenderC2XSOAR - API Permissions Analysis

## 🎯 EXECUTIVE SUMMARY

**Current**: 46 permissions (17 MDE + 29 Graph)  
**Recommended**: **36 permissions** (17 MDE + 19 Graph)  
**Reduction**: 10 unused Graph permissions removed

---

## ✅ REQUIRED PERMISSIONS

### Microsoft Defender for Endpoint (17 permissions) - ✅ ALL NEEDED

| Permission | Usage | Status |
|------------|-------|--------|
| `Alert.Read.All` | MDE alerts reading | ✅ Used |
| `Alert.ReadWrite.All` | MDE alerts management | ✅ Used |
| `Machine.Read.All` | Device information | ✅ Used |
| `Machine.ReadWrite.All` | Device management actions | ✅ Used |
| `Machine.Isolate` | Isolate/unisolate devices | ✅ Used |
| `Machine.RestrictExecution` | App restriction | ✅ Used |
| `Machine.Scan` | Antivirus scans | ✅ Used |
| `Machine.CollectForensics` | Investigation package | ✅ Used |
| `Machine.LiveResponse` | Live response sessions | ✅ Used |
| `AdvancedQuery.Read.All` | KQL hunting queries | ✅ Used |
| `Ti.ReadWrite.All` | Threat indicators | ✅ Used |
| `SecurityRecommendation.Read.All` | Security recommendations | ✅ Used |
| `Vulnerability.Read.All` | Vulnerability data | ✅ Used |
| `File.Read.All` | File information | ✅ Used |
| `Ip.Read.All` | IP information | ✅ Used |
| `Url.Read.All` | URL information | ✅ Used |
| `User.Read.All` | User context | ✅ Used |

**Verdict**: ✅ **Keep all 17 MDE permissions**

---

### Microsoft Graph (29 currently, 19 recommended)

#### ✅ KEEP - Identity & Access Management (9 permissions)

| Permission | Usage | Endpoints | Status |
|------------|-------|-----------|--------|
| `User.Read.All` | Read user profiles | `/users/{id}` | ✅ Used |
| `User.ReadWrite.All` | Disable/enable users | `/users/{id}` PATCH | ✅ Used |
| `Directory.Read.All` | Read directory data | Various | ✅ Used |
| `UserAuthenticationMethod.ReadWrite.All` | Reset passwords | `/users/{id}` password reset | ✅ Used |
| `User.RevokeSessions.All` | Revoke user sessions | `/users/{id}/revokeSignInSessions` | ✅ Used |
| `IdentityRiskEvent.Read.All` | Read risk detections | `/identityProtection/riskDetections` | ✅ Used |
| `IdentityRiskyUser.Read.All` | Read risky users | `/identityProtection/riskyUsers` | ✅ Used |
| `IdentityRiskyUser.ReadWrite.All` | Confirm/dismiss risk | `/identityProtection/riskyUsers/confirmCompromised` | ✅ Used |
| `Policy.Read.All` | Read conditional access | `/identity/conditionalAccess/policies` | ✅ Used |

#### ✅ KEEP - Security (4 permissions)

| Permission | Usage | Endpoints | Status |
|------------|-------|-----------|--------|
| `SecurityIncident.Read.All` | Read XDR incidents | `/security/incidents` | ✅ Used |
| `SecurityIncident.ReadWrite.All` | Update incidents | `/security/incidents/{id}` PATCH | ✅ Used |
| `SecurityEvents.Read.All` | Read security alerts | `/security/alerts_v2` (MDI) | ✅ Used |
| `ThreatIndicators.ReadWrite.OwnedBy` | Threat intel indicators | Graph threat intel | ✅ Used |

#### ✅ KEEP - Device Management (3 permissions)

| Permission | Usage | Endpoints | Status |
|------------|-------|-----------|--------|
| `DeviceManagementManagedDevices.Read.All` | Read Intune devices | `/deviceManagement/managedDevices` | ✅ Used |
| `DeviceManagementManagedDevices.ReadWrite.All` | Intune device actions | `/deviceManagement/managedDevices/{id}/remoteLock` | ✅ Used |
| `DeviceManagementConfiguration.Read.All` | Device compliance | `/deviceManagement/managedDevices` compliance | ✅ Used |

#### ✅ KEEP - Audit & Reporting (3 permissions)

| Permission | Usage | Endpoints | Status |
|------------|-------|-----------|--------|
| `AuditLog.Read.All` | Audit logs | `/auditLogs/signIns` | ✅ Used |
| `Reports.Read.All` | Security reports | `/reports` | ✅ Used |
| `Group.Read.All` | Group membership | `/groups` | ✅ Used |

#### ❌ REMOVE - Unused Permissions (10 permissions)

| Permission | Reason to Remove | Alternative |
|------------|------------------|-------------|
| `Directory.ReadWrite.All` | ❌ Never writes to directory | Use `User.ReadWrite.All` for user ops |
| `UserAuthenticationMethod.Read.All` | ❌ Duplicate (ReadWrite includes Read) | Keep ReadWrite only |
| `IdentityRiskEvent.ReadWrite.All` | ❌ Never writes risk events | Use Read.All only |
| `SecurityEvents.ReadWrite.All` | ❌ Never writes security events | Use Read.All only |
| `ThreatSubmission.ReadWrite.All` | ❌ MDO not implemented (email submission) | Remove |
| `SecurityActions.Read.All` | ❌ Not used | Remove |
| `SecurityActions.ReadWrite.All` | ❌ Not used | Remove |
| `Mail.ReadWrite` | ❌ MDO not implemented (email operations) | Remove |
| `GroupMember.Read.All` | ❌ Duplicate (Group.Read.All includes members) | Remove |
| `Application.Read.All` | ❌ Not used | Remove |

---

## 📊 RECOMMENDED PERMISSIONS LIST

### Microsoft Defender for Endpoint (17) ✅
```powershell
"Alert.Read.All"
"Alert.ReadWrite.All"
"Machine.Read.All"
"Machine.ReadWrite.All"
"Machine.Isolate"
"Machine.RestrictExecution"
"Machine.Scan"
"Machine.CollectForensics"
"Machine.LiveResponse"
"AdvancedQuery.Read.All"
"Ti.ReadWrite.All"
"SecurityRecommendation.Read.All"
"Vulnerability.Read.All"
"File.Read.All"
"Ip.Read.All"
"Url.Read.All"
"User.Read.All"
```

### Microsoft Graph (19) ⚡ OPTIMIZED
```powershell
# Identity & Access Management
"User.Read.All"
"User.ReadWrite.All"
"Directory.Read.All"
"UserAuthenticationMethod.ReadWrite.All"
"User.RevokeSessions.All"
"IdentityRiskEvent.Read.All"
"IdentityRiskyUser.Read.All"
"IdentityRiskyUser.ReadWrite.All"
"Policy.Read.All"

# Security
"SecurityIncident.Read.All"
"SecurityIncident.ReadWrite.All"
"SecurityEvents.Read.All"
"ThreatIndicators.ReadWrite.OwnedBy"

# Device Management
"DeviceManagementManagedDevices.Read.All"
"DeviceManagementManagedDevices.ReadWrite.All"
"DeviceManagementConfiguration.Read.All"

# Audit & Reporting
"AuditLog.Read.All"
"Reports.Read.All"
"Group.Read.All"
```

---

## 🔒 AZURE RBAC (SUBSCRIPTION-LEVEL)

**Required for MDC and Azure Infrastructure services**

| Role | Scope | Purpose |
|------|-------|---------|
| **Security Reader** | Subscription | Read MDC alerts, recommendations, secure score |
| **Contributor** | Subscription | Manage NSG rules, stop VMs, modify storage |

**Assignment**:
```powershell
# Service Principal ID from permissions script output
$spnId = "<service-principal-object-id>"
$subscriptionId = "80110e3c-3ec4-4567-b06d-7d47a72562f5"

# Assign Security Reader
az role assignment create `
  --assignee $spnId `
  --role "Security Reader" `
  --scope "/subscriptions/$subscriptionId"

# Assign Contributor (if infrastructure management needed)
az role assignment create `
  --assignee $spnId `
  --role "Contributor" `
  --scope "/subscriptions/$subscriptionId"
```

---

## 📝 SERVICE-SPECIFIC REQUIREMENTS

### MDE (Microsoft Defender for Endpoint)
- **API**: `api.securitycenter.microsoft.com`
- **Permissions**: All 17 MDE permissions
- **Parameters**: None (uses tenantId from request)

### MDC (Microsoft Defender for Cloud)
- **API**: `management.azure.com`
- **Permissions**: Azure RBAC (Security Reader)
- **Parameters**: ✅ **`subscriptionId` (required)**

### MDI (Microsoft Defender for Identity)
- **API**: `graph.microsoft.com/v1.0/security/alerts_v2`
- **Permissions**: `SecurityEvents.Read.All`, `SecurityIncident.Read.All`
- **Parameters**: None (uses tenantId from request)

### EntraID (Identity Protection)
- **API**: `graph.microsoft.com/v1.0/identityProtection`
- **Permissions**: `IdentityRiskyUser.*`, `User.*`, `Policy.Read.All`
- **Parameters**: `userId` (for user-specific actions), none for GetRiskyUsers/GetPolicies

### Intune (Device Management)
- **API**: `graph.microsoft.com/v1.0/deviceManagement`
- **Permissions**: `DeviceManagementManagedDevices.*`
- **Parameters**: `deviceId` (for device-specific actions), none for GetManagedDevices

### Azure (Infrastructure)
- **API**: `management.azure.com`
- **Permissions**: Azure RBAC (Contributor)
- **Parameters**: ✅ **`subscriptionId` (required)**, `resourceGroup` (for most operations)

---

## 🎯 IMPLEMENTATION PLAN

### Step 1: Update Permissions Script
Update `Set-DefenderC2XSOARPermissions.ps1` to remove 10 unused permissions:

```powershell
# REMOVE these from MicrosoftGraph permissions array:
# "Directory.ReadWrite.All"
# "UserAuthenticationMethod.Read.All"
# "IdentityRiskEvent.ReadWrite.All"
# "SecurityEvents.ReadWrite.All"
# "ThreatSubmission.ReadWrite.All"
# "SecurityActions.Read.All"
# "SecurityActions.ReadWrite.All"
# "Mail.ReadWrite"
# "GroupMember.Read.All"
# "Application.Read.All"
```

### Step 2: Reapply Permissions
```powershell
.\Set-DefenderC2XSOARPermissions.ps1 `
  -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
  -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
```

### Step 3: Assign Azure RBAC
```powershell
# Use service principal ID from script output
az role assignment create `
  --assignee "<spn-object-id>" `
  --role "Security Reader" `
  --scope "/subscriptions/80110e3c-3ec4-4567-b06d-7d47a72562f5"
```

---

## ✅ BENEFITS OF OPTIMIZATION

1. **Reduced Attack Surface**: 22% fewer permissions (46 → 36)
2. **Principle of Least Privilege**: Only permissions actually used
3. **Easier Compliance**: Simpler to audit and justify
4. **Clearer Intent**: Each permission has clear purpose
5. **Better Security Posture**: No unused high-privilege permissions

---

## 📚 REFERENCES

- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Defender for Endpoint API Permissions](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure RBAC Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

---

**Analysis Date**: November 11, 2025  
**Reviewed By**: Code Analysis  
**Status**: ✅ Ready for Implementation
