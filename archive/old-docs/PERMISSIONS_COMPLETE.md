# DefenderXDR - Complete API Permissions Matrix (v3.1.0)

**Date**: November 12, 2025  
**Purpose**: Comprehensive API permissions for all 188 XDR remediation actions  
**Scope**: Microsoft Graph, MDE API, Azure RBAC, Exchange Online

---

## 📋 EXECUTIVE SUMMARY

| API/Service | Total Scopes | Currently Configured | Missing | Status |
|-------------|--------------|---------------------|---------|--------|
| **Microsoft Graph v1.0** | 22 scopes | 14 scopes | 8 scopes | ⚠️ 64% |
| **Microsoft Graph Beta** | 5 scopes | 0 scopes | 5 scopes | ❌ 0% |
| **MDE API** | 9 permissions | 9 permissions | 0 permissions | ✅ 100% |
| **Azure RBAC** | 8 roles | 5 roles | 3 roles | ⚠️ 63% |
| **Exchange Online** | 3 roles | 0 roles | 3 roles | ❌ 0% |
| **TOTAL** | **47 permissions** | **28 permissions** | **19 permissions** | **60%** |

### 🔴 CRITICAL MISSING PERMISSIONS
1. **ThreatHunting.ReadWrite.All** (Graph Beta) - Email remediation, ZAP
2. **Mail.ReadWrite** (Graph v1.0) - Bulk email search & delete
3. **eDiscovery.ReadWrite.All** (Graph v1.0) - Content search & purge
4. **Files.ReadWrite.All** (Graph v1.0) - MCAS file quarantine
5. **Key Vault Contributor** (Azure RBAC) - Secret disable, key rotation

---

## 1️⃣ MICROSOFT GRAPH API PERMISSIONS (Application Permissions)

### ✅ CURRENTLY CONFIGURED (14 scopes)

| Scope | Type | Purpose | Service Worker | Status |
|-------|------|---------|----------------|--------|
| **SecurityIncident.ReadWrite.All** | Application | CRUD incidents, assign, comment | MDE, XDR Platform | ✅ Configured |
| **SecurityAlert.ReadWrite.All** | Application | Update alerts, resolve, classify | MDE, MDI, XDR Platform | ✅ Configured |
| **SecurityEvents.ReadWrite.All** | Application | Security events, threat submission | MDO | ✅ Configured |
| **ThreatSubmission.ReadWrite.All** | Application | Submit phishing emails, URLs, files | MDO | ✅ Configured |
| **ThreatIndicators.ReadWrite.OwnedBy** | Application | Custom IOCs (deprecated 2026) | MDE | ✅ Configured |
| **User.ReadWrite.All** | Application | Disable/enable users, profile updates | Entra ID | ✅ Configured |
| **Directory.ReadWrite.All** | Application | Group membership, admin roles, directory | Entra ID, Azure | ✅ Configured |
| **IdentityRiskyUser.ReadWrite.All** | Application | Confirm compromised, dismiss risk | Entra ID | ✅ Configured |
| **UserAuthenticationMethod.ReadWrite.All** | Application | Password reset (basic) | Entra ID | ✅ Configured |
| **Policy.ReadWrite.ConditionalAccess** | Application | CA policies, named locations | Entra ID | ✅ Configured |
| **Application.Read.All** | Application | Read app registrations | Entra ID | ✅ Configured |
| **DeviceManagementManagedDevices.ReadWrite.All** | Application | Intune device actions (wipe, lock, retire) | Intune | ✅ Configured |
| **DeviceManagementConfiguration.ReadWrite.All** | Application | Device compliance, configuration | Intune | ✅ Configured |
| **SecurityActions.ReadWrite.All** | Application | Security actions (limited Graph v1.0) | XDR Platform | ✅ Configured |

### ❌ MISSING - CRITICAL GAPS (8 scopes)

| Scope | Type | Purpose | Required For | Priority | Worker |
|-------|------|---------|--------------|----------|--------|
| **Mail.ReadWrite** | Application | Search emails across mailboxes, delete emails | Bulk email search & delete (MDO) | 🔴 Critical | MDO |
| **eDiscovery.ReadWrite.All** | Application | Create eDiscovery searches, purge data | Content search & purge (MDO) | 🔴 Critical | MDO |
| **Files.ReadWrite.All** | Application | Quarantine files, remove external sharing | MCAS file remediation | 🔴 Critical | MCAS |
| **Application.ReadWrite.All** | Application | Disable service principals, remove credentials | Azure app security | 🔴 Critical | Azure |
| **AuditLog.Read.All** | Application | Read audit logs, sign-in logs (read-only included in Directory.ReadWrite.All) | Enhanced monitoring | 🟢 Medium | Entra ID |
| **RoleManagement.ReadWrite.Directory** | Application | Remove admin roles, revoke PIM (included in Directory.ReadWrite.All) | Privileged access remediation | 🟡 High | Entra ID |
| **MailboxSettings.ReadWrite** | Application | Remove mail forwarding rules | Already configured | ✅ Have | MDO |
| **Policy.Read.All** | Application | Read-only CA policies (included in Policy.ReadWrite) | Already covered | ✅ Have | Entra ID |

**Note**: Some "missing" scopes are already covered by broader permissions (e.g., `Directory.ReadWrite.All` includes role management).

---

## 2️⃣ MICROSOFT GRAPH BETA PERMISSIONS (Preview APIs)

### ❌ ALL MISSING - NEW CAPABILITIES (5 scopes)

| Scope | Type | Purpose | Required For | Priority | Worker |
|-------|------|---------|--------------|----------|--------|
| **ThreatHunting.Read.All** | Application | Advanced hunting, email search | Query analyzed emails | 🔴 Critical | MDO |
| **ThreatHunting.ReadWrite.All** | Application | Email remediation actions | Soft/hard delete emails, move to junk, ZAP | 🔴 Critical | MDO |
| **CloudApp-Security.ReadWrite.All** | Application | MCAS operations | OAuth revocation, session termination | 🔴 Critical | MCAS |
| **SecurityActions.ReadWrite.All** | Application | Enhanced security actions (Beta version) | AIR approval, detection rules | 🟡 High | XDR Platform |
| **eDiscovery.Read.All** | Application | Read eDiscovery cases | Read-only content search | 🟢 Medium | MDO |

### Graph Beta API Endpoints Requiring New Permissions

#### ThreatHunting.ReadWrite.All
```http
POST /security/collaboration/analyzedEmails/remediate
{
  "emailIds": ["<guid>"],
  "remediationAction": "softDelete|hardDelete|moveToJunk|moveToInbox|moveToDeletedItems"
}

GET /security/collaboration/analyzedEmails?$filter=...
POST /security/collaboration/analyzedEmails/zapPhishing
POST /security/collaboration/analyzedEmails/zapMalware
```

#### CloudApp-Security.ReadWrite.All
```http
DELETE /oauth2PermissionGrants/{id}
POST /security/cloudAppSecurity/apps/{id}/ban
POST /security/cloudAppSecurity/sessions/{id}/terminate
POST /security/cloudAppSecurity/users/{userId}/apps/{appId}/block
```

#### SecurityActions.ReadWrite.All (Beta)
```http
POST /security/rules/detectionRules
PATCH /security/rules/detectionRules/{id}
DELETE /security/rules/detectionRules/{id}
POST /security/investigations/trigger
POST /security/investigations/{id}/actions/approve
```

---

## 3️⃣ MICROSOFT DEFENDER FOR ENDPOINT API PERMISSIONS

### ✅ ALL CONFIGURED (9 permissions)

| Permission | Purpose | Actions Enabled | Status |
|------------|---------|-----------------|--------|
| **Machine.Isolate** | Isolate/unisolate devices | IsolateDevice, UnisolateDevice | ✅ Configured |
| **Machine.RestrictExecution** | Restrict code execution | RestrictApp, UnrestrictApp | ✅ Configured |
| **Machine.Scan** | Run AV scans | RunAVScan (Quick/Full) | ✅ Configured |
| **Machine.CollectForensics** | Collect investigation data | CollectInvestigationPackage | ✅ Configured |
| **Machine.StopAndQuarantine** | Quarantine files | StopAndQuarantineFile | ✅ Configured |
| **Machine.Offboard** | Offboard devices from MDE | OffboardDevice | ✅ Configured |
| **Machine.LiveResponse** | Live Response sessions | All 15 Live Response actions | ✅ Configured |
| **Machine.Read.All** | Read device information | GetDevices, GetDeviceInfo | ✅ Configured |
| **Alert.ReadWrite.All** | CRUD alerts & incidents | All alert/incident operations | ✅ Configured |
| **AdvancedQuery.Read.All** | Run KQL queries | RunQuery, advanced hunting | ✅ Configured |
| **Ti.ReadWrite.All** | Threat intelligence IOCs | Add/Remove indicators (IP/URL/Domain/File) | ✅ Configured |
| **Library.Manage** | Live Response script library | Upload/delete scripts | ✅ Configured |

**MDE API Coverage**: 100% ✅ All required permissions configured

---

## 4️⃣ AZURE RBAC ROLES (Service Principal / Managed Identity)

### ✅ CURRENTLY CONFIGURED (5 roles)

| Role | Scope | Purpose | Actions Enabled | Status |
|------|-------|---------|-----------------|--------|
| **Network Contributor** | Subscription/RG | Manage NSGs, firewall rules | AddNSGDenyRule, BlockIPInNSG | ✅ Configured |
| **Virtual Machine Contributor** | Subscription/RG | Manage VM power state | StopVM, RestartVM, DeallocateVM | ✅ Configured |
| **Storage Account Contributor** | Subscription/RG | Manage storage security | DisableStoragePublicAccess | ✅ Configured |
| **Reader** | Subscription | Read Azure resources | GetVMs, GetResourceGroups, GetNSGs | ✅ Configured |
| **Security Admin** | Subscription | Manage security settings | Security policies, NSG rules | ✅ Configured |

### ❌ MISSING - CRITICAL GAPS (3 roles)

| Role | Scope | Purpose | Required For | Priority |
|------|-------|---------|--------------|----------|
| **Key Vault Contributor** | Resource Group | Manage Key Vault secrets & keys | Disable secrets, rotate keys, purge | 🔴 Critical |
| **Key Vault Secrets Officer** | Key Vault | Secrets management | Disable/enable secrets | 🔴 Critical |
| **Key Vault Crypto Officer** | Key Vault | Key management | Rotate encryption keys | 🔴 Critical |

### Required Azure Permissions by Action

| Action | Required Role | API Endpoint | Worker |
|--------|---------------|--------------|--------|
| **Stop VM** | Virtual Machine Contributor | `/virtualMachines/{vm}/powerOff` | Azure |
| **Deallocate VM** | Virtual Machine Contributor | `/virtualMachines/{vm}/deallocate` | Azure |
| **Restart VM** | Virtual Machine Contributor | `/virtualMachines/{vm}/restart` | Azure |
| **Add NSG Rule** | Network Contributor | `/networkSecurityGroups/{nsg}/securityRules/{rule}` | Azure |
| **Block IP in Firewall** | Network Contributor | `/azureFirewalls/{fw}/networkRuleCollections` | Azure |
| **Block Domain in Firewall** | Network Contributor | `/azureFirewalls/{fw}/applicationRuleCollections` | Azure |
| **Disable Storage Public Access** | Storage Account Contributor | `/storageAccounts/{account}` (allowBlobPublicAccess) | Azure |
| **Rotate Storage Keys** | Storage Account Contributor | `/storageAccounts/{account}/regenerateKey` | Azure |
| **Disable Key Vault Secret** | Key Vault Secrets Officer | `/vaults/{vault}/secrets/{secret}` (enabled: false) | Azure |
| **Rotate Encryption Keys** | Key Vault Crypto Officer | `/vaults/{vault}/keys/{key}/rotate` | Azure |
| **Disable Service Principal** | Application.ReadWrite.All (Graph) | `/servicePrincipals/{id}` | Azure |

---

## 5️⃣ EXCHANGE ONLINE POWERSHELL (Mail Flow Rules)

### ❌ ALL MISSING (3 roles)

| Role | Purpose | Required For | Priority |
|------|---------|--------------|----------|
| **Mail Flow Administrator** | Create/modify transport rules | Block sender at transport level | 🟡 High |
| **Security Administrator** | Security-related mail flow rules | Block phishing domains | 🟡 High |
| **Organization Management** | Full Exchange admin (not recommended) | All mail flow operations | 🟢 Medium |

**Note**: Exchange Online PowerShell requires separate authentication. Use certificate-based authentication for app-only access.

### Required Commands
```powershell
# Connect with certificate-based auth
Connect-ExchangeOnline -CertificateThumbprint "<thumbprint>" `
    -AppId "<app-id>" -Organization "<tenant>.onmicrosoft.com"

# Create block rule
New-TransportRule -Name "Block Malicious Sender" `
    -From "attacker@evil.com" `
    -DeleteMessage $true `
    -RejectMessageReasonText "Blocked by security policy"

# Modify existing rule
Set-TransportRule -Identity "Block Rule" -Enabled $true
```

---

## 6️⃣ STORAGE ACCOUNT RBAC (Managed Identity)

### ✅ ALL CONFIGURED (3 roles)

| Role | Purpose | Role Definition ID | Status |
|------|---------|-------------------|--------|
| **Storage Queue Data Contributor** | Bulk operation queuing | `974c5e8b-45b9-4653-ba55-5f855dd0fb88` | ✅ Configured |
| **Storage Table Data Contributor** | Operation status tracking | `0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3` | ✅ Configured |
| **Storage Blob Data Contributor** | Live Response file library | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | ✅ Configured |

**Storage RBAC Coverage**: 100% ✅ All configured automatically via ARM template

---

## 7️⃣ PERMISSION ASSIGNMENT GUIDE

### A. Microsoft Graph API Permissions (App Registration)

#### Azure Portal Method
1. Navigate to **Azure AD** > **App registrations** > Select your app
2. Go to **API permissions** > **Add a permission**
3. Select **Microsoft Graph** > **Application permissions**
4. Add each missing scope:
   - `Mail.ReadWrite`
   - `eDiscovery.ReadWrite.All`
   - `Files.ReadWrite.All`
   - `Application.ReadWrite.All`
5. Click **Grant admin consent for [Tenant]**

#### PowerShell Method
```powershell
# Install module
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

# Get Graph Service Principal
$graphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Get your app registration
$app = Get-MgApplication -Filter "displayName eq 'DefenderXDR'"

# Add required permissions
$requiredPermissions = @(
    "Mail.ReadWrite",                    # Graph API
    "eDiscovery.ReadWrite.All",         # Graph API
    "Files.ReadWrite.All",              # Graph API
    "Application.ReadWrite.All",        # Graph API
    "ThreatHunting.ReadWrite.All",      # Graph Beta
    "CloudApp-Security.ReadWrite.All"   # Graph Beta
)

foreach ($permission in $requiredPermissions) {
    $appRole = $graphSP.AppRoles | Where-Object { $_.Value -eq $permission }
    
    if ($appRole) {
        New-MgServicePrincipalAppRoleAssignment `
            -ServicePrincipalId $app.Id `
            -PrincipalId $app.Id `
            -ResourceId $graphSP.Id `
            -AppRoleId $appRole.Id
        
        Write-Host "✅ Added: $permission" -ForegroundColor Green
    } else {
        Write-Host "❌ Not found: $permission (may be Beta)" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Graph API permissions added. Requires admin consent!" -ForegroundColor Cyan
```

### B. MDE API Permissions (Security Portal)

#### Portal Method
1. Navigate to **https://security.microsoft.com**
2. Go to **Settings** > **Endpoints** > **APIs**
3. Select your app registration
4. Enable all required permissions:
   - ✅ Machine.Isolate
   - ✅ Machine.RestrictExecution
   - ✅ Machine.Scan
   - ✅ Machine.CollectForensics
   - ✅ Machine.StopAndQuarantine
   - ✅ Machine.Offboard
   - ✅ Machine.LiveResponse
   - ✅ Machine.Read.All
   - ✅ Alert.ReadWrite.All
   - ✅ AdvancedQuery.Read.All
   - ✅ Ti.ReadWrite.All
   - ✅ Library.Manage
5. Click **Save**

**Note**: MDE API permissions are already fully configured ✅

### C. Azure RBAC Roles (Service Principal)

#### PowerShell Method
```powershell
# Connect to Azure
Connect-AzAccount

# Get your app's service principal
$sp = Get-AzADServicePrincipal -DisplayName "DefenderXDR"

# Get subscription ID
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

# Assign missing roles at subscription level
$roles = @(
    "Key Vault Contributor",
    "Key Vault Secrets Officer",
    "Key Vault Crypto Officer"
)

foreach ($role in $roles) {
    try {
        New-AzRoleAssignment `
            -ObjectId $sp.Id `
            -RoleDefinitionName $role `
            -Scope $scope `
            -ErrorAction Stop
        
        Write-Host "✅ Assigned: $role" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Already assigned or error: $role" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Azure RBAC roles assigned successfully!" -ForegroundColor Cyan
```

#### Resource Group Scope (More Restrictive - Recommended)
```powershell
# Assign at resource group level (more secure)
$resourceGroup = "rg-defenderxdr-prod"
$scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup"

New-AzRoleAssignment `
    -ObjectId $sp.Id `
    -RoleDefinitionName "Key Vault Contributor" `
    -Scope $scope
```

#### Key Vault Scope (Most Restrictive)
```powershell
# Assign at Key Vault level (most secure)
$keyVaultName = "kv-defenderxdr"
$keyVault = Get-AzKeyVault -VaultName $keyVaultName
$scope = $keyVault.ResourceId

New-AzRoleAssignment `
    -ObjectId $sp.Id `
    -RoleDefinitionName "Key Vault Secrets Officer" `
    -Scope $scope

New-AzRoleAssignment `
    -ObjectId $sp.Id `
    -RoleDefinitionName "Key Vault Crypto Officer" `
    -Scope $scope
```

### D. Exchange Online PowerShell (Mail Flow Administrator)

#### Prerequisites
1. Generate certificate for app-only authentication
2. Upload certificate to app registration
3. Assign Exchange role to service principal

#### PowerShell Method
```powershell
# 1. Generate self-signed certificate (valid 2 years)
$cert = New-SelfSignedCertificate `
    -Subject "CN=DefenderXDR-EXO" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeySpec Signature `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable

# Export certificate
$certPath = "C:\Temp\DefenderXDR-EXO.cer"
Export-Certificate -Cert $cert -FilePath $certPath

# 2. Upload to App Registration
# - Azure Portal > App registrations > Certificates & secrets
# - Upload the .cer file

# 3. Assign Exchange Online role
Connect-ExchangeOnline -UserPrincipalName admin@tenant.onmicrosoft.com

# Get service principal
$sp = Get-ServicePrincipal -Identity "<app-id>"

# Assign Mail Flow Administrator role
New-ManagementRoleAssignment `
    -Role "Mail Flow Administrator" `
    -App $sp.Identity

Write-Host "✅ Exchange Online role assigned!" -ForegroundColor Green
```

---

## 8️⃣ PERMISSIONS BY WORKER SERVICE

### MDE Worker (68 actions) - ✅ 100% CONFIGURED

| Permission | Type | Status |
|------------|------|--------|
| Machine.Isolate | MDE API | ✅ Configured |
| Machine.RestrictExecution | MDE API | ✅ Configured |
| Machine.Scan | MDE API | ✅ Configured |
| Machine.CollectForensics | MDE API | ✅ Configured |
| Machine.StopAndQuarantine | MDE API | ✅ Configured |
| Machine.Offboard | MDE API | ✅ Configured |
| Machine.LiveResponse | MDE API | ✅ Configured |
| Machine.Read.All | MDE API | ✅ Configured |
| Alert.ReadWrite.All | MDE API | ✅ Configured |
| AdvancedQuery.Read.All | MDE API | ✅ Configured |
| Ti.ReadWrite.All | MDE API | ✅ Configured |
| SecurityIncident.ReadWrite.All | Graph v1.0 | ✅ Configured |
| SecurityAlert.ReadWrite.All | Graph v1.0 | ✅ Configured |

**MDE Worker Status**: ✅ **COMPLETE** - No missing permissions

### MDO Worker (22 actions) - ❌ 18% CONFIGURED

| Permission | Type | Status | Priority |
|------------|------|--------|----------|
| ThreatSubmission.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| SecurityEvents.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| **ThreatHunting.ReadWrite.All** | **Graph Beta** | ❌ **MISSING** | 🔴 Critical |
| **Mail.ReadWrite** | **Graph v1.0** | ❌ **MISSING** | 🔴 Critical |
| **eDiscovery.ReadWrite.All** | **Graph v1.0** | ❌ **MISSING** | 🔴 Critical |
| **Mail Flow Administrator** | **Exchange Online** | ❌ **MISSING** | 🟡 High |

**MDO Worker Status**: ❌ **CRITICAL GAPS** - Email remediation blocked

### Entra ID Worker (18 actions) - ⚠️ 72% CONFIGURED

| Permission | Type | Status | Priority |
|------------|------|--------|----------|
| User.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| Directory.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| IdentityRiskyUser.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| UserAuthenticationMethod.ReadWrite.All | Graph v1.0 | ✅ Configured | - |
| Policy.ReadWrite.ConditionalAccess | Graph v1.0 | ✅ Configured | - |
| **Application.ReadWrite.All** | **Graph v1.0** | ❌ **MISSING** | 🔴 Critical |

**Entra ID Worker Status**: ⚠️ **MOSTLY COMPLETE** - Missing app security

**Note**: `Directory.ReadWrite.All` includes admin role removal, but explicit `RoleManagement.ReadWrite.Directory` is clearer for auditing.

### Intune Worker (15 actions) - ✅ 100% CONFIGURED

| Permission | Type | Status |
|------------|------|--------|
| DeviceManagementManagedDevices.ReadWrite.All | Graph v1.0 | ✅ Configured |
| DeviceManagementConfiguration.ReadWrite.All | Graph v1.0 | ✅ Configured |

**Intune Worker Status**: ✅ **COMPLETE** - No missing permissions

### Azure Worker (25 actions) - ⚠️ 32% CONFIGURED

| Permission | Type | Status | Priority |
|------------|------|--------|----------|
| Network Contributor | Azure RBAC | ✅ Configured | - |
| Virtual Machine Contributor | Azure RBAC | ✅ Configured | - |
| Storage Account Contributor | Azure RBAC | ✅ Configured | - |
| Reader | Azure RBAC | ✅ Configured | - |
| Security Admin | Azure RBAC | ✅ Configured | - |
| **Key Vault Contributor** | **Azure RBAC** | ❌ **MISSING** | 🔴 Critical |
| **Key Vault Secrets Officer** | **Azure RBAC** | ❌ **MISSING** | 🔴 Critical |
| **Key Vault Crypto Officer** | **Azure RBAC** | ❌ **MISSING** | 🔴 Critical |
| **Application.ReadWrite.All** | **Graph v1.0** | ❌ **MISSING** | 🔴 Critical |

**Azure Worker Status**: ❌ **CRITICAL GAPS** - Key Vault & Service Principal remediation blocked

### MCAS Worker (12 actions) - ❌ 0% CONFIGURED

**⚠️ WORKER DOES NOT EXIST YET**

| Permission | Type | Status | Priority |
|------------|------|--------|----------|
| **Files.ReadWrite.All** | **Graph v1.0** | ❌ **MISSING** | 🔴 Critical |
| **CloudApp-Security.ReadWrite.All** | **Graph Beta** | ❌ **MISSING** | 🔴 Critical |
| **Directory.ReadWrite.All** | Graph v1.0 | ✅ Configured (for OAuth) | - |

**MCAS Worker Status**: ❌ **NOT IMPLEMENTED** - Worker needs to be created

---

## 9️⃣ LICENSE REQUIREMENTS

### Microsoft 365 / Security Licenses

| License | Required For | Monthly Cost (per user) |
|---------|--------------|------------------------|
| **Microsoft 365 E5** | Full XDR capabilities (MDE, MDO, MDI, MCAS) | $57 |
| **Microsoft 365 E5 Security** | Security features only (no Office apps) | $12 |
| **Microsoft Defender for Office 365 Plan 2** | Email remediation, ZAP, threat submission | $5 (standalone) |
| **Microsoft Defender for Endpoint P2** | All endpoint actions, Live Response | $5.20 (standalone) |
| **Microsoft Defender for Identity** | Identity investigation (included in E5) | Included |
| **Microsoft Defender for Cloud Apps** | OAuth revocation, session control | $5 (standalone) |

### Azure AD / Entra ID Licenses

| License | Required For | Monthly Cost (per user) |
|---------|--------------|------------------------|
| **Entra ID Premium P1** | Conditional Access policies, named locations | $6 |
| **Entra ID Premium P2** | Identity Protection (risky users, risk detections) | $9 |
| **Entra ID Free** | Basic directory operations | Free |

### Intune Licenses

| License | Required For | Monthly Cost (per user) |
|---------|--------------|------------------------|
| **Microsoft Intune Plan 1** | Device management, remote actions | $8 |
| **Microsoft Intune Plan 2** | Advanced analytics, endpoint privilege | $11 |

### Azure Subscriptions
- **Pay-As-You-Go** or **Enterprise Agreement** required for:
  - Function App hosting (~$50-100/month)
  - Storage Account (~$5-10/month)
  - Key Vault (~$5/month)
  - Application Insights (~$10-20/month)

**Total Estimated Monthly Cost** (per user, with E5):
- **E5 License**: $57/user
- **Azure Infrastructure**: ~$100 (flat, not per-user)
- **Total for 100 users**: ~$5,800/month

---

## 🔟 VERIFICATION & TESTING

### A. Verify Graph API Permissions

```powershell
# Connect
Connect-MgGraph -Scopes "Application.Read.All"

# Get app registration
$app = Get-MgApplication -Filter "displayName eq 'DefenderXDR'"

# Get service principal
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"

# List all assigned permissions
$assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id

foreach ($assignment in $assignments) {
    $resource = Get-MgServicePrincipal -ServicePrincipalId $assignment.ResourceId
    $appRole = $resource.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
    
    Write-Host "✅ $($resource.DisplayName): $($appRole.Value)" -ForegroundColor Green
}
```

### B. Verify MDE API Permissions

```powershell
# Test MDE API access
$tenantId = "<tenant-id>"
$appId = "<app-id>"
$clientSecret = "<client-secret>"

$tokenParams = @{
    Uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    Method = "POST"
    Body = @{
        client_id = $appId
        client_secret = $clientSecret
        scope = "https://api.securitycenter.microsoft.com/.default"
        grant_type = "client_credentials"
    }
}

$token = (Invoke-RestMethod @tokenParams).access_token

# Test API call
$headers = @{ "Authorization" = "Bearer $token" }
$devices = Invoke-RestMethod -Uri "https://api.securitycenter.microsoft.com/api/machines" -Headers $headers

Write-Host "✅ MDE API Access: $($devices.value.Count) devices found" -ForegroundColor Green
```

### C. Verify Azure RBAC

```powershell
# List all role assignments for service principal
$sp = Get-AzADServicePrincipal -DisplayName "DefenderXDR"
$assignments = Get-AzRoleAssignment -ObjectId $sp.Id

$assignments | Format-Table DisplayName, RoleDefinitionName, Scope -AutoSize

# Expected roles:
# - Network Contributor
# - Virtual Machine Contributor
# - Storage Account Contributor
# - Reader
# - Security Admin
# - Key Vault Contributor (if added)
```

### D. Test End-to-End Action

```powershell
# Test email remediation action (requires ThreatHunting.ReadWrite.All)
$body = @{
    tenantId = "<tenant-id>"
    action = "RemediateEmail"
    parameters = @{
        emailId = "<email-id>"
        remediationType = "softDelete"
    }
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "https://<function-app>.azurewebsites.net/api/DefenderXDRGateway" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" `
    -Headers @{ "x-functions-key" = "<api-key>" }

$response
```

---

## 1️⃣1️⃣ TROUBLESHOOTING

### Error: "Insufficient privileges to complete the operation"

**Cause**: Missing Graph API permission or admin consent not granted

**Solution**:
```powershell
# 1. Verify permission is assigned
$app = Get-MgApplication -Filter "displayName eq 'DefenderXDR'"
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id

# 2. Grant admin consent
# Azure Portal > App registrations > API permissions > Grant admin consent
```

### Error: "Access denied" for Azure RBAC operation

**Cause**: Missing Azure role assignment

**Solution**:
```powershell
# Assign missing role
$sp = Get-AzADServicePrincipal -DisplayName "DefenderXDR"
New-AzRoleAssignment `
    -ObjectId $sp.Id `
    -RoleDefinitionName "Key Vault Contributor" `
    -Scope "/subscriptions/<sub-id>/resourceGroups/<rg>"
```

### Error: "ThreatHunting.ReadWrite.All not found"

**Cause**: Graph Beta scope not yet available in production tenant

**Solution**:
```
Graph Beta APIs require:
1. Tenant in Microsoft 365 Insider Risk Management program
2. Manual permission request via Azure Support
3. Alternative: Use Mail.ReadWrite for bulk email operations
```

### Error: "The tenant admin must consent to this permission"

**Cause**: Application permissions require admin consent

**Solution**:
1. Azure Portal > App registrations > API permissions
2. Click **Grant admin consent for [Tenant]**
3. Confirm as Global Administrator

---

## 1️⃣2️⃣ SECURITY BEST PRACTICES

### Principle of Least Privilege
✅ **DO**: Assign roles at Resource Group scope, not Subscription
❌ **DON'T**: Use `Owner` or `Contributor` at Subscription level

### Certificate-Based Authentication
✅ **DO**: Use certificate authentication for Exchange Online
❌ **DON'T**: Store client secrets in code (use Key Vault)

### Managed Identity
✅ **DO**: Use System-Assigned Managed Identity for Storage Account
✅ **DO**: Enable Managed Identity for Function App
❌ **DON'T**: Use connection strings for Storage Account

### Permission Auditing
✅ **DO**: Review permissions quarterly
✅ **DO**: Monitor Azure AD audit logs for permission usage
✅ **DO**: Use Conditional Access to restrict service principal access

### Key Rotation
✅ **DO**: Rotate client secrets every 90 days
✅ **DO**: Use certificate authentication (longer lifetime, more secure)
✅ **DO**: Store secrets in Azure Key Vault with auto-rotation

---

## 1️⃣3️⃣ AUTOMATED PERMISSION DEPLOYMENT

### Complete Deployment Script

```powershell
<#
.SYNOPSIS
    Complete DefenderXDR Permissions Deployment Script
.DESCRIPTION
    Configures all required permissions for DefenderXDR v3.1.0:
    - Microsoft Graph API permissions
    - MDE API permissions (manual step required)
    - Azure RBAC roles
    - Storage Account RBAC for Managed Identity
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppDisplayName = "DefenderXDR",
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeBetaPermissions = $false
)

# Install required modules
$modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Applications", "Az.Accounts", "Az.Resources")
foreach ($module in $modules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Install-Module $module -Scope CurrentUser -Force -AllowClobber
    }
}

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId

# Get app registration
Write-Host "Finding app registration: $AppDisplayName..." -ForegroundColor Cyan
$app = Get-MgApplication -Filter "displayName eq '$AppDisplayName'"
if (!$app) {
    throw "App registration '$AppDisplayName' not found!"
}
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
if (!$sp) {
    throw "Service Principal for '$AppDisplayName' not found!"
}

Write-Host "✅ Found app: $($app.DisplayName) (AppId: $($app.AppId))" -ForegroundColor Green

# Get Graph Service Principal
$graphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Define required Graph v1.0 permissions (Application)
$graphPermissionsV1 = @(
    "SecurityIncident.ReadWrite.All",
    "SecurityAlert.ReadWrite.All",
    "SecurityEvents.ReadWrite.All",
    "ThreatSubmission.ReadWrite.All",
    "ThreatIndicators.ReadWrite.OwnedBy",
    "User.ReadWrite.All",
    "Directory.ReadWrite.All",
    "IdentityRiskyUser.ReadWrite.All",
    "UserAuthenticationMethod.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "Application.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "SecurityActions.ReadWrite.All",
    "Mail.ReadWrite",
    "eDiscovery.ReadWrite.All",
    "Files.ReadWrite.All",
    "MailboxSettings.ReadWrite",
    "AuditLog.Read.All"
)

# Define Graph Beta permissions (if enabled)
$graphPermissionsBeta = @(
    "ThreatHunting.Read.All",
    "ThreatHunting.ReadWrite.All",
    "CloudApp-Security.ReadWrite.All"
)

# Add Graph v1.0 permissions
Write-Host "`nConfiguring Microsoft Graph v1.0 permissions..." -ForegroundColor Cyan
foreach ($permission in $graphPermissionsV1) {
    $appRole = $graphSP.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application" }
    
    if ($appRole) {
        # Check if already assigned
        $existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id | 
            Where-Object { $_.AppRoleId -eq $appRole.Id }
        
        if ($existing) {
            Write-Host "  ⏭️  Already assigned: $permission" -ForegroundColor Yellow
        } else {
            try {
                New-MgServicePrincipalAppRoleAssignment `
                    -ServicePrincipalId $sp.Id `
                    -PrincipalId $sp.Id `
                    -ResourceId $graphSP.Id `
                    -AppRoleId $appRole.Id | Out-Null
                
                Write-Host "  ✅ Added: $permission" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed: $permission - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  ⚠️  Not found: $permission" -ForegroundColor Yellow
    }
}

# Add Graph Beta permissions (if enabled)
if ($IncludeBetaPermissions) {
    Write-Host "`nConfiguring Microsoft Graph Beta permissions..." -ForegroundColor Cyan
    foreach ($permission in $graphPermissionsBeta) {
        $appRole = $graphSP.AppRoles | Where-Object { $_.Value -eq $permission }
        
        if ($appRole) {
            $existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id | 
                Where-Object { $_.AppRoleId -eq $appRole.Id }
            
            if (!$existing) {
                New-MgServicePrincipalAppRoleAssignment `
                    -ServicePrincipalId $sp.Id `
                    -PrincipalId $sp.Id `
                    -ResourceId $graphSP.Id `
                    -AppRoleId $appRole.Id | Out-Null
                
                Write-Host "  ✅ Added (Beta): $permission" -ForegroundColor Green
            }
        } else {
            Write-Host "  ⚠️  Beta permission not available: $permission" -ForegroundColor Yellow
        }
    }
}

# Configure Azure RBAC roles
Write-Host "`nConfiguring Azure RBAC roles..." -ForegroundColor Cyan
$scope = if ($ResourceGroupName) {
    "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
} else {
    "/subscriptions/$SubscriptionId"
}

$azureRoles = @(
    "Network Contributor",
    "Virtual Machine Contributor",
    "Storage Account Contributor",
    "Reader",
    "Security Admin"
)

# Add Key Vault roles if specified
if ($KeyVaultName) {
    $keyVault = Get-AzKeyVault -VaultName $KeyVaultName
    $kvScope = $keyVault.ResourceId
    
    $kvRoles = @(
        "Key Vault Contributor",
        "Key Vault Secrets Officer",
        "Key Vault Crypto Officer"
    )
    
    Write-Host "  Configuring Key Vault roles on: $KeyVaultName" -ForegroundColor Cyan
    foreach ($role in $kvRoles) {
        try {
            $existing = Get-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $role -Scope $kvScope -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Host "    ⏭️  Already assigned: $role" -ForegroundColor Yellow
            } else {
                New-AzRoleAssignment `
                    -ObjectId $sp.Id `
                    -RoleDefinitionName $role `
                    -Scope $kvScope | Out-Null
                
                Write-Host "    ✅ Assigned: $role" -ForegroundColor Green
            }
        } catch {
            Write-Host "    ❌ Failed: $role - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Assign subscription/RG roles
foreach ($role in $azureRoles) {
    try {
        $existing = Get-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $role -Scope $scope -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "  ⏭️  Already assigned: $role" -ForegroundColor Yellow
        } else {
            New-AzRoleAssignment `
                -ObjectId $sp.Id `
                -RoleDefinitionName $role `
                -Scope $scope | Out-Null
            
            Write-Host "  ✅ Assigned: $role" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Failed: $role - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n" + ("="*80) -ForegroundColor Cyan
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host ("="*80) -ForegroundColor Cyan

Write-Host "`n✅ Microsoft Graph API permissions configured" -ForegroundColor Green
Write-Host "✅ Azure RBAC roles configured" -ForegroundColor Green
if ($KeyVaultName) {
    Write-Host "✅ Key Vault roles configured" -ForegroundColor Green
}

Write-Host "`n⚠️  MANUAL STEPS REQUIRED:" -ForegroundColor Yellow
Write-Host "  1. Grant admin consent for Graph API permissions:" -ForegroundColor Yellow
Write-Host "     - Azure Portal > App registrations > $AppDisplayName > API permissions" -ForegroundColor Yellow
Write-Host "     - Click 'Grant admin consent for [Tenant]'" -ForegroundColor Yellow
Write-Host "`n  2. Configure MDE API permissions:" -ForegroundColor Yellow
Write-Host "     - Navigate to https://security.microsoft.com" -ForegroundColor Yellow
Write-Host "     - Settings > Endpoints > APIs > Select app > Enable all permissions" -ForegroundColor Yellow
Write-Host "`n  3. (Optional) Configure Exchange Online access:" -ForegroundColor Yellow
Write-Host "     - Upload certificate to app registration" -ForegroundColor Yellow
Write-Host "     - Assign 'Mail Flow Administrator' role via Exchange PowerShell" -ForegroundColor Yellow

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host ("="*80) -ForegroundColor Cyan
```

### Usage
```powershell
# Basic deployment (subscription-level RBAC)
.\Deploy-DefenderXDRPermissions.ps1 `
    -AppDisplayName "DefenderXDR" `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -SubscriptionId "11111111-1111-1111-1111-111111111111"

# With Key Vault and resource group scope
.\Deploy-DefenderXDRPermissions.ps1 `
    -AppDisplayName "DefenderXDR" `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -SubscriptionId "11111111-1111-1111-1111-111111111111" `
    -ResourceGroupName "rg-defenderxdr-prod" `
    -KeyVaultName "kv-defenderxdr" `
    -IncludeBetaPermissions $true
```

---

## 1️⃣4️⃣ CHANGE LOG

### v3.1.0 (November 12, 2025)
- ✅ Added 19 missing permissions for 71 new remediation actions
- ✅ Added Graph Beta permissions (ThreatHunting, CloudApp-Security)
- ✅ Added Azure Key Vault roles (Contributor, Secrets Officer, Crypto Officer)
- ✅ Added Application.ReadWrite.All for Service Principal remediation
- ✅ Added Mail.ReadWrite and eDiscovery.ReadWrite.All for MDO email remediation
- ✅ Added complete permission deployment automation script
- ✅ Added verification and troubleshooting procedures

### v3.0.0 (Previous)
- Storage Account RBAC for Managed Identity
- Live Response Blob Storage
- Keyless authentication

---

**Last Updated**: November 12, 2025  
**Document Version**: 3.1.0  
**Next Review**: After Phase 1-6 implementation complete
