# Email & File Permission Usage Analysis

## 📧 Mail.ReadWrite (Graph API)

**Permission Scope**: `Mail.ReadWrite`  
**Type**: Application permission (works without user)

### Used By: MDO Worker - 8 Actions

| Action | Operation | API Endpoint | Why Needed |
|--------|-----------|--------------|------------|
| **SoftDeleteEmails** | Move emails to Deleted Items | `POST /beta/security/collaboration/analyzedEmails/remediate` | Requires read/write to mailbox |
| **HardDeleteEmails** | Permanently delete emails | `POST /beta/security/collaboration/analyzedEmails/remediate` | Requires delete permission |
| **MoveToJunk** | Move phishing to Junk folder | `POST /beta/security/collaboration/analyzedEmails/remediate` | Requires move permission |
| **MoveToInbox** | Restore false positives | `POST /beta/security/collaboration/analyzedEmails/remediate` | Requires move permission |
| **MoveToDeletedItems** | Soft quarantine | `POST /beta/security/collaboration/analyzedEmails/remediate` | Requires move permission |
| **BulkEmailSearch** | Search all mailboxes | `GET /v1.0/users/{id}/messages?$search="query"` | Requires read across all mailboxes |
| **BulkEmailDelete** | Delete multiple emails | `DELETE /v1.0/users/{id}/messages/{id}` | Requires delete permission |
| **RemoveMailForwardingRules** | Remove forwarding rules | `DELETE /v1.0/users/{id}/mailFolders/inbox/messageRules/{id}` | Requires read/write to rules |

**API Used**:
- Graph Beta: `/beta/security/collaboration/analyzedEmails/remediate` (new unified API)
- Graph v1.0: `/v1.0/users/{id}/messages` (direct mailbox access)

### More Specific Alternatives?

**NO** - There are no more granular permissions for email operations. Options are:
1. `Mail.ReadWrite` (Application) - ✅ What we use
2. `Mail.Read` (Application) - Too restrictive (read-only)
3. `Mail.ReadWrite` (Delegated) - Requires user login
4. `Mail.ReadBasic.All` - Too restrictive (metadata only)

**Conclusion**: `Mail.ReadWrite` is already the most appropriate permission.

---

## 📧 Mail.Send (Graph API)

**Permission Scope**: `Mail.Send`  
**Type**: Application permission

### NOT Currently Used in Code

**Status**: ⚠️ **OPTIONAL - Currently unused**

**Potential Use Cases** (not implemented):
- Send email notifications to users
- Send incident reports
- Send threat summaries

**Recommendation**: 
- ✅ **Remove if NOT planning to add email notifications**
- ✅ **Keep if you want to add notification features later**

---

## 📁 Files.ReadWrite.All (Graph API)

**Permission Scope**: `Files.ReadWrite.All`  
**Type**: Application permission (works without user)

### Used By: MCAS Worker - 4 Actions

| Action | Operation | API Endpoint | Why Needed |
|--------|-----------|--------------|------------|
| **QuarantineCloudFile** | Move file to quarantine folder | `PATCH /v1.0/drives/{id}/items/{id}` | Requires move/rename permission |
| **RemoveExternalSharing** | Revoke sharing links | `DELETE /v1.0/drives/{id}/items/{id}/permissions/{id}` | Requires permission management |
| **ApplySensitivityLabel** | Apply MIP label | `POST /v1.0/drives/{id}/items/{id}/assignSensitivityLabel` | Requires label permission |
| **RestoreFromQuarantine** | Restore quarantined file | `PATCH /v1.0/drives/{id}/items/{id}` | Requires move permission |

**API Used**:
- Graph v1.0: `/v1.0/drives/{id}/items/{id}` (OneDrive/SharePoint files)
- Graph v1.0: `/v1.0/drives/{id}/items/{id}/permissions` (sharing management)

### More Specific Alternatives?

**YES** - More granular options exist:

| Permission | Scope | Use Case |
|------------|-------|----------|
| `Files.ReadWrite.All` | **All sites, all users** | ✅ Current (most flexible) |
| `Files.Read.All` | Read-only | ❌ Too restrictive (can't quarantine) |
| `Sites.ReadWrite.All` | SharePoint sites only | ⚠️ Alternative (SharePoint-focused) |
| `Sites.Selected` | Specific sites only | 🔒 Most restrictive (requires site selection) |

**Conclusion**: 
- `Files.ReadWrite.All` is appropriate for MCAS file governance
- More specific options like `Sites.Selected` would require pre-configuration of sites
- Current permission is **least-privilege for the use case**

---

## 🎯 Optimization Recommendations

### Scenario 1: Pure XDR C2 (No Email, No Files)
**Remove**:
- ❌ `Mail.ReadWrite`
- ❌ `Mail.Send`
- ❌ `Files.ReadWrite.All`

**Result**: 12 Graph permissions (from 15)

### Scenario 2: XDR + Email Remediation (No Files)
**Keep**:
- ✅ `Mail.ReadWrite` (required for email actions)
- ❌ `Mail.Send` (optional, not used)
- ❌ `Files.ReadWrite.All` (not needed)

**Result**: 13 Graph permissions

### Scenario 3: XDR + File Governance (No Email)
**Keep**:
- ❌ `Mail.ReadWrite` (not needed)
- ❌ `Mail.Send` (not needed)
- ✅ `Files.ReadWrite.All` (required for file actions)

**Result**: 13 Graph permissions

### Scenario 4: Full XDR + Email + Files (Current)
**Keep**:
- ✅ `Mail.ReadWrite` (email remediation)
- ⚠️ `Mail.Send` (optional, for future notifications)
- ✅ `Files.ReadWrite.All` (file governance)

**Result**: 15 Graph permissions

---

## 🔒 Security Considerations

### Mail.ReadWrite Risk
- **High** - Can read/write ALL mailboxes in tenant
- **Mitigation**: App is service account, no user context
- **Audit**: All operations logged in Unified Audit Log
- **Detection**: Monitor Graph API calls to email endpoints

### Files.ReadWrite.All Risk
- **High** - Can read/write ALL files in OneDrive/SharePoint
- **Mitigation**: App only acts on explicit file IDs from MCAS alerts
- **Audit**: All operations logged in SharePoint audit log
- **Detection**: Monitor Graph API calls to drives endpoints

### Least-Privilege Best Practices
1. ✅ Remove `Mail.Send` if not using notifications
2. ✅ Remove `Mail.ReadWrite` if not doing email remediation
3. ✅ Remove `Files.ReadWrite.All` if not doing file governance
4. ✅ Use Azure AD Conditional Access to restrict app to specific networks
5. ✅ Enable Privileged Identity Management (PIM) for app credentials

---

## 📊 Current Permission Count

| Scenario | Graph Perms | MDE Perms | Total | Use Case |
|----------|-------------|-----------|-------|----------|
| **Minimal** | 12 | 6 | **18** | XDR incidents/alerts/hunting only |
| **+ Email** | 13 | 6 | **19** | XDR + email remediation |
| **+ Files** | 13 | 6 | **19** | XDR + file governance |
| **Full** | 15 | 6 | **21** | XDR + email + files |

---

## 🛠️ How to Apply

### Remove Email Permissions
Edit `Configure-AppRegistrationPermissions.ps1` and comment out lines 136-145:

```powershell
# ===================================================================
# EMAIL SECURITY (MDO WORKER - OPTIONAL)
# ===================================================================
# @{ Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Name = "Mail.ReadWrite"; Type = "Role" }
# @{ Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96"; Name = "Mail.Send"; Type = "Role" }
```

### Remove File Permissions
Comment out lines 147-155:

```powershell
# ===================================================================
# CLOUD APP SECURITY (MCAS WORKER - OPTIONAL)
# ===================================================================
# @{ Id = "75359482-378d-4052-8f01-80520e7db3cd"; Name = "Files.ReadWrite.All"; Type = "Role" }
```

### Run Script
```powershell
.\Configure-AppRegistrationPermissions.ps1 -AppId <id> -TenantId <id>
```

### Grant Admin Consent
Azure Portal → App Registrations → API permissions → Grant admin consent
