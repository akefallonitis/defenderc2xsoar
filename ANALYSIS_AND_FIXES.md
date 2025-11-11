# DefenderC2XSOAR - Analysis, Issues, and Fixes

**Date:** November 11, 2025  
**Tenant ID:** a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9  
**Function App:** sentryxdr.azurewebsites.net  
**App Registration ID:** 0b75d6c4-8466-420c-bfc3-8c0c4fadae24

## Executive Summary

The DefenderC2XSOAR solution is a comprehensive Microsoft Defender XDR integration platform with Azure Functions and Workbooks. Analysis reveals a solid architecture with some critical issues that need immediate attention.

---

## 1. Current Architecture

### Function App Structure
- **13 Specialized Functions** designed for different Microsoft security services:
  1. `DefenderXDROrchestrator` - Main entry point (✅ IMPLEMENTED)
  2. `DefenderXDRGateway` - Secondary routing (❌ EMPTY - NEEDS IMPLEMENTATION)
  3. `DefenderXDRMDEWorker` - Defender for Endpoint operations (✅ IMPLEMENTED)
  4. `DefenderXDRMDOWorker` - Defender for Office 365 (✅ IMPLEMENTED)
  5. `DefenderXDRMDCWorker` - Defender for Cloud (✅ IMPLEMENTED)
  6. `DefenderXDRMDIWorker` - Defender for Identity (✅ IMPLEMENTED)
  7. `DefenderXDREntraIDWorker` - Entra ID operations (✅ IMPLEMENTED)
  8. `DefenderXDRIntuneWorker` - Intune device management (✅ IMPLEMENTED)
  9. `DefenderXDRAzureWorker` - Azure infrastructure (✅ IMPLEMENTED)
  10. `DefenderXDRHuntManager` - Advanced hunting (✅ IMPLEMENTED)
  11. `DefenderXDRIncidentManager` - Incident management (✅ IMPLEMENTED)
  12. `DefenderXDRThreatIntelManager` - Threat intelligence (✅ IMPLEMENTED)
  13. `DefenderXDRCustomDetectionManager` - Custom detections (✅ IMPLEMENTED)

### Module Architecture
- **16 PowerShell Modules** in `functions/modules/DefenderXDRIntegrationBridge/`:
  - `AuthManager.psm1` - Centralized OAuth with token caching ✅
  - `BlobManager.psm1` - Azure Storage operations ✅
  - `MDEDevice.psm1` - MDE device actions ✅
  - `MDELiveResponse.psm1` - Live response operations ✅
  - `MDEHunting.psm1` - Advanced hunting ✅
  - `MDEIncident.psm1` - Incident management ✅
  - `MDEThreatIntel.psm1` - Threat intelligence indicators ✅
  - `MDEDetection.psm1` - Custom detections ✅
  - `MDOEmailRemediation.psm1` - Email operations ✅
  - `EntraIDIdentity.psm1` - Identity management ✅
  - `IntuneDeviceManagement.psm1` - Device management ✅
  - `DefenderForCloud.psm1` - Cloud security ✅
  - `DefenderForIdentity.psm1` - Identity threat detection ✅
  - `AzureInfrastructure.psm1` - Infrastructure operations ✅
  - `ValidationHelper.psm1` - Input validation ✅
  - `LoggingHelper.psm1` - Structured logging ✅

---

## 2. Critical Issues Found

### 🔴 Issue #1: Empty Gateway Function
**Severity:** HIGH  
**Impact:** Secondary API endpoint non-functional

**Details:**
- `DefenderXDRGateway/run.ps1` is completely empty
- `DefenderXDRGateway/function.json` is also empty
- This prevents the Gateway function from working

**Fix Required:** Implement Gateway as a lightweight proxy to Orchestrator

### 🔴 Issue #2: Storage Account Using Connection Strings (NOT Managed Identity)
**Severity:** CRITICAL - SECURITY RISK  
**Impact:** Credentials exposed in environment variables

**Current Configuration (from screenshot):**
```
AzureWebJobsStorage = "DefaultEndpointsProtocol=https;AccountName=storagejyx3tuczh6pc;EndpointSuffix=core.windows.net;AccountKey=Npu+HIKE..."
WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=storagejyx3tuczh6pc;EndpointSuffix=core.windows.net;AccountKey=Npu+HIKE..."
```

**Security Issues:**
- Account keys stored in plain text
- Keys can be accidentally exposed in logs
- Keys don't rotate automatically
- No audit trail for key usage

**Recommended Configuration:**
```
AzureWebJobsStorage__accountName = "storagejyx3tuczh6pc"
AzureWebJobsStorage__credential = "managedidentity"
WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "" (remove)
```

### 🔴 Issue #3: Function Package Not Updated
**Severity:** HIGH  
**Impact:** Deployed functions may not match current code

**Details:**
- Package URL: `https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip`
- Local package exists but may be outdated
- 404 errors when testing suggest package mismatch

**Fix Required:** Rebuild and redeploy package

### 🟡 Issue #4: Missing Function App Permissions Documentation
**Severity:** MEDIUM  
**Impact:** Difficult for users to know what permissions to assign

**Current State:** App registration permissions not clearly documented

---

## 3. Required API Permissions for App Registration

### For MDE (Microsoft Defender for Endpoint)
**API:** WindowsDefenderATP (https://api.securitycenter.microsoft.com)

| Permission | Type | Purpose |
|------------|------|---------|
| `Alert.Read.All` | Application | Read all alerts |
| `Alert.ReadWrite.All` | Application | Update alert status, comments |
| `Machine.Read.All` | Application | Read device information |
| `Machine.ReadWrite.All` | Application | Isolate, scan, restrict devices |
| `Machine.Isolate` | Application | Isolate devices |
| `Machine.RestrictExecution` | Application | Restrict app execution |
| `Machine.Scan` | Application | Run antivirus scans |
| `Machine.CollectForensics` | Application | Collect investigation packages |
| `Machine.LiveResponse` | Application | Live response sessions |
| `AdvancedQuery.Read.All` | Application | Advanced hunting queries |
| `Incident.Read.All` | Application | Read incidents |
| `Incident.ReadWrite.All` | Application | Update incidents |
| `Ti.ReadWrite.All` | Application | Manage threat indicators |
| `SecurityRecommendation.Read.All` | Application | Read security recommendations |

### For Graph API (MDO, Entra ID, Intune, MDI)
**API:** Microsoft Graph (https://graph.microsoft.com)

| Permission | Type | Purpose |
|------------|------|---------|
| `User.Read.All` | Application | Read user profiles |
| `User.ReadWrite.All` | Application | Manage user accounts |
| `Directory.Read.All` | Application | Read directory data |
| `Directory.ReadWrite.All` | Application | Manage directory |
| `UserAuthenticationMethod.ReadWrite.All` | Application | Reset passwords, MFA |
| `IdentityRiskEvent.Read.All` | Application | Read risk detections |
| `IdentityRiskEvent.ReadWrite.All` | Application | Manage user risk |
| `IdentityRiskyUser.ReadWrite.All` | Application | Confirm compromise, dismiss risk |
| `User.RevokeSessions.All` | Application | Revoke user sessions |
| `SecurityEvents.Read.All` | Application | Read security events |
| `SecurityEvents.ReadWrite.All` | Application | Update security events |
| `ThreatSubmission.ReadWrite.All` | Application | Submit threats for analysis |
| `Mail.ReadWrite` | Application | Email remediation |
| `DeviceManagementManagedDevices.Read.All` | Application | Read Intune devices |
| `DeviceManagementManagedDevices.ReadWrite.All` | Application | Manage Intune devices |
| `DeviceManagementConfiguration.Read.All` | Application | Read Intune configuration |
| `SecurityActions.ReadWrite.All` | Application | Security actions |
| `ThreatIndicators.ReadWrite.OwnedBy` | Application | Manage threat indicators |

### For Azure Resource Manager (MDC, Azure)
**API:** Azure Service Management (https://management.azure.com)

| Permission | Type | Purpose |
|------------|------|---------|
| `user_impersonation` | Delegated | **OR use RBAC roles below** |

**Recommended RBAC Roles (per subscription):**
- **Security Admin** - Manage security policies and alerts
- **Security Reader** - Read security data
- **Contributor** - Manage resources (for NSG rules, VM actions)

### Summary - Minimum Required Permissions
To minimize permissions while maintaining functionality:

1. **Microsoft Defender for Endpoint API:**
   - `Alert.ReadWrite.All`
   - `Machine.ReadWrite.All`
   - `Machine.Isolate`
   - `Machine.RestrictExecution`
   - `Machine.Scan`
   - `Machine.LiveResponse`
   - `AdvancedQuery.Read.All`
   - `Incident.ReadWrite.All`
   - `Ti.ReadWrite.All`

2. **Microsoft Graph API:**
   - `User.ReadWrite.All`
   - `Directory.ReadWrite.All`
   - `IdentityRiskyUser.ReadWrite.All`
   - `SecurityEvents.ReadWrite.All`
   - `DeviceManagementManagedDevices.ReadWrite.All`
   - `ThreatSubmission.ReadWrite.All`

3. **Azure RBAC (per subscription):**
   - Security Admin role
   - Contributor role (for infrastructure actions)

---

## 4. Functionality Testing Results

### ❌ XDROrchestrator Endpoint Test
```powershell
Invoke-RestMethod -Uri "https://sentryxdr.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -Method Get
```
**Result:** 404 Not Found

**Root Causes:**
1. Package deployment issue
2. Function not properly deployed from GitHub package
3. Potential Azure Functions cold start issue

**Testing Strategy:**
- Fix Gateway function
- Rebuild package  
- Redeploy package to GitHub
- Restart Function App
- Retest with authentication key

---

## 5. Fixes to Implement

### Fix #1: Implement Gateway Function

Create `DefenderXDRGateway/run.ps1` as a simple proxy/router to Orchestrator with public-facing, simpler API.

### Fix #2: Migrate to Managed Identity for Storage

**Steps:**
1. Enable System-Assigned Managed Identity on Function App
2. Assign "Storage Blob Data Contributor" role to MI
3. Update app settings:
   ```
   AzureWebJobsStorage__accountName = storagejyx3tuczh6pc
   AzureWebJobsStorage__credential = managedidentity
   ```
4. Remove connection string settings

### Fix #3: Rebuild Function Package

Run:
```powershell
cd deployment
.\create-deployment-package.ps1
```

Push to GitHub and let Function App pull new package.

### Fix #4: Document Permissions

Create comprehensive permissions guide (see Section 3 above).

---

## 6. Workbook Requirements Analysis

### Criteria for Success

#### 1. Main Dashboard - Incidents/Alerts/Entities
- **Incident Grid** with auto-refresh (Custom Endpoint)
- **Alert Grid** with filtering
- **Entity Selection** (Devices, Users, IPs, Files)
- **Action Buttons** per entity type using ARM Actions
- **Details Panel** showing selected item

#### 2. Multi-Tenant Support
- Lighthouse environment dropdown
- Tenant ID auto-population
- Cross-tenant operations

#### 3. Advanced UI Concepts
- Grouping and nesting
- Conditional visibility per tab/group
- Dropdown menus with auto-population
- Text inputs for parameters
- ARM actions for manual operations
- Custom endpoints for auto-refresh data

#### 4. File Operations Workarounds
- **Download:** Direct SAS URL from workbook parameter
- **Upload:** Upload to storage account, reference in actions
- **List Library:** Custom endpoint returning file list

#### 5. Console-Like UI
- **Live Response Console:**
  - Text input for commands
  - ARM action to execute
  - Output display area
- **Advanced Hunting Console:**
  - KQL query text box
  - Execute button (ARM action)
  - Results grid

#### 6. Functionality per Tab
- **Incidents Tab:** List, filter, select, update status, add comments
- **Devices Tab:** List devices, isolate, scan, restrict, live response
- **Users Tab:** List risky users, disable, reset password, revoke sessions
- **Hunting Tab:** KQL query console, saved queries, results export
- **Threat Intel Tab:** Add indicators, list indicators, delete
- **Email Tab:** Submit threats, remediate emails
- **Azure Tab:** NSG rules, stop VMs, security recommendations

---

## 7. Implementation Plan

### Phase 1: Fix Critical Issues (IMMEDIATE)
1. ✅ Analyze current state
2. ⏳ Create Gateway function
3. ⏳ Rebuild function package
4. ⏳ Test all endpoints
5. ⏳ Document permissions

### Phase 2: Security Enhancements (HIGH PRIORITY)
1. Enable Managed Identity
2. Update storage configuration
3. Remove connection strings
4. Verify RBAC assignments

### Phase 3: Workbook Development (NEXT)
1. Create base workbook structure
2. Implement main dashboard
3. Add incident/alert/entity grids
4. Implement ARM actions
5. Add custom endpoints
6. Create console UI
7. Add file operations
8. Test multi-tenant support

### Phase 4: Testing & Validation
1. Test all function endpoints
2. Test all workbook actions
3. Validate multi-tenant operations
4. Performance testing
5. Security review

---

## 8. Next Steps

### Immediate Actions Required:
1. **Fix Gateway Function** - Implement run.ps1 and function.json
2. **Rebuild Package** - Ensure all functions are included
3. **Test Orchestrator** - Verify it responds correctly
4. **Deploy Workbook** - Start with basic dashboard
5. **Migrate to Managed Identity** - Remove connection strings

### Testing Commands:
```powershell
# Test Orchestrator - Get All Devices
$headers = @{"x-functions-key" = "IM4G-JE3r1vDk35ZmAlmZIv8muL7-vTkjlKczXFJikAzFuLkGIQ=="}
Invoke-RestMethod -Uri "https://sentryxdr.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -Headers $headers | ConvertTo-Json

# Test Orchestrator - Get Incidents
Invoke-RestMethod -Uri "https://sentryxdr.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetIncidents&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -Headers $headers | ConvertTo-Json

# Test Orchestrator - Advanced Hunting
$body = @{
    service = "MDE"
    action = "AdvancedHunt"
    tenantId = "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
    query = "DeviceInfo | take 10"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://sentryxdr.azurewebsites.net/api/XDROrchestrator" -Method Post -Headers $headers -Body $body -ContentType "application/json" | ConvertTo-Json
```

---

## Conclusion

The DefenderC2XSOAR solution has a solid architectural foundation with comprehensive functionality across all Microsoft security services. The main issues are:

1. **Gateway function is empty** - Easy fix
2. **Storage using connection strings** - Security risk requiring managed identity migration
3. **Package needs rebuild** - Simple rebuild and redeploy
4. **Missing permissions documentation** - Now documented above

Once these issues are resolved, the solution will be production-ready and can support the advanced workbook implementation.
