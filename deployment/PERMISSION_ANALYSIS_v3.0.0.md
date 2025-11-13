# DefenderXDR C2 - Permission Analysis & Optimization

**Version**: 3.0.0 (Least-Privilege Edition)  
**Date**: November 13, 2025

---

## 🎯 Summary

**Optimized from 26 → 17 permissions** (35% reduction)

### Current Permissions (What You Have)
- **Microsoft Graph**: 20 permissions
- **Microsoft Defender for Endpoint**: 6 permissions (+ 24 already granted)
- **Total**: 26 configured permissions + 52 "other" permissions = **78 total**

### Recommended Permissions (Least-Privilege)
- **Microsoft Graph**: 15 permissions (CORE) + 2 optional
- **Microsoft Defender for Endpoint**: 6 permissions (unchanged)
- **Total**: **17-19 permissions** (based on use case)

**Reduction**: 35% fewer permissions, focused on **XDR C2 operations only**

---

## ✅ What We KEPT (Core XDR Operations)

### Microsoft Graph API (15 CORE + 2 Optional)

#### **XDR Security Operations (5 permissions)**
| Permission | Why We Need It |
|------------|---------------|
| `SecurityIncident.ReadWrite.All` | **CRITICAL** - Manage XDR incidents (update status, assign, comment) |
| `SecurityAlert.ReadWrite.All` | **CRITICAL** - Manage security alerts across all services |
| `SecurityActions.ReadWrite.All` | **CRITICAL** - Execute security actions (remediate, investigate) |
| `ThreatHunting.Read.All` | **CRITICAL** - Run advanced hunting queries (KQL) across XDR |
| `ThreatIndicators.ReadWrite.OwnedBy` | **IMPORTANT** - Manage custom threat indicators (IOCs) |

#### **Identity Protection (5 permissions)**
| Permission | Why We Need It |
|------------|---------------|
| `User.Read.All` | **CRITICAL** - Read user account info for investigation |
| `User.ReadWrite.All` | **CRITICAL** - Disable compromised accounts, reset passwords |
| `UserAuthenticationMethod.ReadWrite.All` | **CRITICAL** - Reset MFA, force re-authentication |
| `IdentityRiskyUser.ReadWrite.All` | **CRITICAL** - Manage risky users (confirm/dismiss risk) |
| `Policy.ReadWrite.ConditionalAccess` | **IMPORTANT** - Create emergency CA policies (block user access) |

#### **Device Management (2 permissions)**
| Permission | Why We Need It |
|------------|---------------|
| `DeviceManagementManagedDevices.ReadWrite.All` | **CRITICAL** - Remote lock, wipe, retire devices (Intune) |
| `DeviceManagementConfiguration.ReadWrite.All` | **IMPORTANT** - Manage compliance policies |

#### **Email Security (2 permissions - OPTIONAL)**
| Permission | Why We Need It | When to Use |
|------------|---------------|-------------|
| `Mail.ReadWrite` | Delete phishing emails, ZAP | ⚠️ **ONLY if using MDO email remediation** |
| `Mail.Send` | Send notifications | ⚠️ **ONLY if using email notifications** |

#### **Cloud App Security (1 permission - OPTIONAL)**
| Permission | Why We Need It | When to Use |
|------------|---------------|-------------|
| `Files.ReadWrite.All` | Quarantine malicious files, remove sharing | ⚠️ **ONLY if using MCAS file actions** |

#### **Audit Logging (1 permission - RECOMMENDED)**
| Permission | Why We Need It |
|------------|---------------|
| `AuditLog.Read.All` | **RECOMMENDED** - Sign-in logs, audit logs for investigation |

### Microsoft Defender for Endpoint API (6 permissions)
| Permission | Why We Need It |
|------------|---------------|
| `Machine.ReadWrite.All` | **CRITICAL** - All device actions (isolate, scan, etc.) |
| `Machine.LiveResponse` | **CRITICAL** - Live Response sessions (critical for IR) |
| `Alert.ReadWrite.All` | **CRITICAL** - Manage MDE alerts |
| `Ti.ReadWrite.All` | **IMPORTANT** - Manage threat intelligence indicators |
| `AdvancedQuery.Read.All` | **IMPORTANT** - Run advanced hunting queries |
| `Library.Manage` | **IMPORTANT** - Manage Live Response library files |

---

## ❌ What We REMOVED (Excessive Privileges)

### Microsoft Graph API (5 permissions removed)

| ❌ REMOVED Permission | Why We Don't Need It |
|----------------------|---------------------|
| `eDiscovery.ReadWrite.All` | ❌ **NOT USED** - No eDiscovery actions in v3.0.0 code |
| `Application.ReadWrite.All` | ❌ **NOT NEEDED** - C2 doesn't manage app registrations |
| `RoleManagement.ReadWrite.Directory` | ❌ **EXCESSIVE** - Too much privilege, not used |
| `Directory.ReadWrite.All` | ❌ **EXCESSIVE** - Superset of other permissions, not needed |
| *(removed Mail.* if not using email)* | ⚠️ **OPTIONAL** - Only if you do email remediation |

### Justification
- **eDiscovery**: No `eDiscovery` string found in any worker code
- **Application management**: C2 is a consumer, not a manager of apps
- **Directory.ReadWrite.All**: Too broad - specific permissions are better (User.*, Policy.*)
- **RoleManagement**: Not managing RBAC roles in C2 operations

---

## 🔍 About "Unnamed" Permissions (UIDs)

You're seeing UIDs like:
- `0883f392-0a7a-443d-8c76-16a6d39c7b63`
- `d665a8d9-5a5b-4ce1-88f8-7f7b0e8e3e0f`
- `65929c4b-e30c-4c97-a9b8-2c2c19e4a2a8`
- `72043a3d-f54e-4988-8c3e-d5dd8a5c4799`
- `7b3f05d5-f68c-4b8d-8c59-a2ecd12f24af`

### Why UIDs Show Up
These are **valid permissions** but appear as UIDs when:
1. **Preview/Beta APIs** - Not yet in GA, Azure Portal doesn't have display names
2. **Recently added** - New permissions not yet in Portal metadata cache
3. **Portal cache issue** - Azure Portal hasn't updated permission names

### How to Decode Them
Match UIDs to our script:

| UID | Permission Name |
|-----|----------------|
| `0883f392-0a7a-443d-8c76-16a6d39c7b63` | `DeviceManagementConfiguration.ReadWrite.All` |
| `d665a8d9-5a5b-4ce1-88f8-7f7b0e8e3e0f` | `ThreatIndicators.ReadWrite.OwnedBy` |
| `65929c4b-e30c-4c97-a9b8-2c2c19e4a2a8` | `Machine.LiveResponse` |
| `72043a3d-f54e-4988-8c3e-d5dd8a5c4799` | `Library.Manage` |
| `7b3f05d5-f68c-4b8d-8c59-a2ecd12f24af` | `Machine.ReadWrite.All` |
| `b27a61ec-b99c-4d6a-b126-c4375d08ae30` | `Ti.ReadWrite.All` |

**All are legitimate permissions** - the Portal just doesn't show names yet.

---

## 🌐 Azure Operations via Graph API?

### ❓ Question: Can Azure infrastructure operations use Graph API?

**Answer**: **NO** - Azure infrastructure requires **Azure Resource Manager (ARM) API**

### Why Two APIs?

| API | Scope | Authentication Scope | Use Case |
|-----|-------|---------------------|----------|
| **Microsoft Graph** | `https://graph.microsoft.com` | `https://graph.microsoft.com/.default` | Identity, Security, Devices, Email, Files |
| **Azure Resource Manager** | `https://management.azure.com` | `https://management.azure.com/.default` | VMs, NSGs, Storage, Subscriptions, Resource Groups |

### Current Architecture (Correct)

```powershell
# In Orchestrator (line 796-820)
"AZURE" {
    # Authenticate to Azure RM (NOT Graph)
    $armToken = Get-OAuthToken `
        -TenantId $tenantId `
        -AppId $appId `
        -SecretId $secretId `
        -Service "Azure"  # ← Uses ARM scope, not Graph
    
    # Call Azure Worker
    $result = Invoke-AzureWorker -Token $armToken -Action $action -Data $data
}
```

### Azure Operations Supported
- Get/Stop/Start/Restart VMs
- Add/Remove NSG rules
- Get Security Center alerts
- Get resource groups
- Get subscriptions
- Tag resources

### Required Permissions (Azure RBAC, NOT Graph)
**None in App Registration** - Azure permissions are granted via:
1. **Azure RBAC roles** (e.g., "Security Admin", "Contributor")
2. **Subscription-level** or **Resource Group-level** assignments
3. NOT configured in App Registration API permissions

**How to grant**:
```bash
# Grant Security Admin role to App Registration
az role assignment create \
  --assignee <app-id> \
  --role "Security Admin" \
  --scope /subscriptions/<subscription-id>
```

---

## 📋 "Other Permissions Granted" (52 permissions)

### Why So Many?
You have **52 "other" permissions granted** but not in configured list because:
1. **Historical grants** - Previous versions of C2 or other apps
2. **Admin over-provisioning** - Someone granted more than needed
3. **Inherited from other apps** - Shared service principal

### Should You Remove Them?
**YES** - The `Configure-AppRegistrationPermissions.ps1` script:
1. **Removes ALL existing permissions** (clean slate)
2. **Adds ONLY the 17-19 permissions** we defined
3. **Result**: Clean, least-privilege configuration

### After Running Script
- **Before**: 78 total permissions (26 configured + 52 other)
- **After**: 17-19 permissions (clean slate)
- **Reduction**: 76% fewer permissions

---

## 🔧 How to Apply Optimized Permissions

### Step 1: Review Optional Permissions
**Edit the script** to comment out permissions you don't need:

```powershell
# If NOT using email remediation, comment out:
# @{ Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Name = "Mail.ReadWrite"; Type = "Role" }
# @{ Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96"; Name = "Mail.Send"; Type = "Role" }

# If NOT using MCAS file actions, comment out:
# @{ Id = "75359482-378d-4052-8f01-80520e7db3cd"; Name = "Files.ReadWrite.All"; Type = "Role" }
```

### Step 2: Run Permission Script
```powershell
cd deployment
.\Configure-AppRegistrationPermissions.ps1 `
    -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
    -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
```

### Step 3: Grant Admin Consent
**In Azure Portal**:
1. Navigate to App Registrations → Your App → API permissions
2. Click **"Grant admin consent for [Tenant]"**
3. Confirm the consent

### Step 4: Verify in Portal
- **Expected configured**: 17-19 permissions
- **Expected granted**: 17-19 permissions (same as configured)
- **"Other permissions"**: 0 (all removed)

---

## 🎯 Final Recommendations

### Minimum Configuration (XDR Core Only)
**15 permissions** - Remove email, files, audit logging:
- 10 Graph permissions (XDR Security + Identity + Intune)
- 6 MDE permissions
- **Use case**: Pure XDR C2 without email remediation or file operations

### Recommended Configuration (Full XDR + Audit)
**17 permissions** - Add audit logging, remove optional:
- 12 Graph permissions (XDR Security + Identity + Intune + Audit)
- 6 MDE permissions
- **Use case**: Most deployments (includes audit trail)

### Full Configuration (All Features)
**19 permissions** - Everything enabled:
- 15 Graph permissions (includes Mail.* and Files.*)
- 6 MDE permissions
- **Use case**: Need email remediation AND file operations

---

## 📊 Comparison Table

| Scenario | Graph Permissions | MDE Permissions | Total | Use Case |
|----------|------------------|-----------------|-------|----------|
| **Current (Your Portal)** | 20 | 6 | **26** | Over-provisioned |
| **Minimum (XDR Core)** | 10 | 6 | **16** | Pure endpoint + identity C2 |
| **Recommended (+ Audit)** | 12 | 6 | **18** | Best for most deployments |
| **Full (All Features)** | 15 | 6 | **21** | Email + files + audit |

---

## 🔒 Security Impact

### Before Optimization
- ❌ `Directory.ReadWrite.All` - Can modify ALL directory objects
- ❌ `RoleManagement.ReadWrite.Directory` - Can assign admin roles
- ❌ `Application.ReadWrite.All` - Can modify all apps
- ❌ `eDiscovery.ReadWrite.All` - Unused permission
- ⚠️ **High risk** if app is compromised

### After Optimization
- ✅ Only specific permissions needed for XDR operations
- ✅ No directory-wide write access
- ✅ No role management privileges
- ✅ No app registration management
- ✅ **Low risk** - follows principle of least privilege

---

## 📝 Next Steps

1. **Review your usage**:
   - Do you use MDO email remediation? Keep `Mail.*`
   - Do you use MCAS file actions? Keep `Files.*`
   - Remove if not needed

2. **Run the optimized script**:
   ```powershell
   .\Configure-AppRegistrationPermissions.ps1 -AppId <your-app-id> -TenantId <your-tenant-id>
   ```

3. **Grant admin consent** in Azure Portal

4. **Test your C2 operations** to ensure everything works with fewer permissions

5. **Monitor** - If you get 403 errors, you may need to add a permission back

---

## 🆘 Troubleshooting

### "Permission not granted" errors after applying
- **Cause**: Forgot to grant admin consent
- **Fix**: Azure Portal → App Registrations → API permissions → Grant admin consent

### "403 Forbidden" after optimization
- **Cause**: Removed a permission that IS actually used
- **Fix**: Check error message for required permission, add it back, grant consent

### UIDs still showing in Portal
- **Expected**: Some permissions are new/preview and show as UIDs
- **Fix**: None needed - they work fine, just cosmetic issue

---

## 📚 References

- [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft Defender for Endpoint API permissions](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure RBAC roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Least privilege access principle](https://learn.microsoft.com/en-us/azure/active-directory/develop/secure-least-privileged-access)
