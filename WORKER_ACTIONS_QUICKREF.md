# DefenderXDR v2.3.0 - Worker Actions Quick Reference

Quick reference for all 50 security automation actions across 6 workers.

---

## 🔵 MDOWorker - Email Security (4 actions)

### RemediateEmail
**Purpose**: Delete malicious emails from mailboxes
```json
{
  "action": "RemediateEmail",
  "tenantId": "xxx",
  "messageId": "AAMkAGI2...",
  "remediationType": "SoftDelete" // or "HardDelete"
}
```

### SubmitEmailThreat
**Purpose**: Submit suspicious email to Microsoft for analysis
```json
{
  "action": "SubmitEmailThreat",
  "tenantId": "xxx",
  "messageId": "AAMkAGI2...",
  "recipientEmail": "user@domain.com"
}
```

### SubmitURLThreat
**Purpose**: Submit suspicious URL to Microsoft for analysis
```json
{
  "action": "SubmitURLThreat",
  "tenantId": "xxx",
  "url": "https://phishing-site.com"
}
```

### RemoveMailForwardingRules
**Purpose**: Remove malicious mail forwarding rules
```json
{
  "action": "RemoveMailForwardingRules",
  "tenantId": "xxx",
  "userId": "user@domain.com",
  "ruleId": "rule-id" // optional, removes all if not specified
}
```

---

## 🟢 MDCWorker - Cloud Security (6 actions)

### GetSecurityAlerts
**Purpose**: Retrieve security alerts from Defender for Cloud
```json
{
  "action": "GetSecurityAlerts",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "filter": "properties/severity eq 'High'", // optional
  "top": 50 // optional
}
```

### UpdateSecurityAlert
**Purpose**: Update alert status (triage)
```json
{
  "action": "UpdateSecurityAlert",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "alertId": "alert-id",
  "status": "Resolved" // Active, Resolved, Dismissed
}
```

### GetRecommendations
**Purpose**: Get security recommendations
```json
{
  "action": "GetRecommendations",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "filter": "properties/state eq 'Active'" // optional
}
```

### GetSecureScore
**Purpose**: Retrieve secure score
```json
{
  "action": "GetSecureScore",
  "tenantId": "xxx",
  "subscriptionId": "sub-id"
}
```

### EnableDefenderPlan
**Purpose**: Enable Defender for specific resource type
```json
{
  "action": "EnableDefenderPlan",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "planType": "VirtualMachines" // VirtualMachines, Storage, SqlServers, etc.
}
```

### GetDefenderPlans
**Purpose**: List all Defender plan statuses
```json
{
  "action": "GetDefenderPlans",
  "tenantId": "xxx",
  "subscriptionId": "sub-id"
}
```

---

## 🟣 MDIWorker - Identity Threats (11 actions)

### GetAlerts
**Purpose**: Retrieve identity security alerts
```json
{
  "action": "GetAlerts",
  "tenantId": "xxx",
  "filter": "severity eq 'high'", // optional
  "top": 50 // optional
}
```

### UpdateAlert
**Purpose**: Update alert status
```json
{
  "action": "UpdateAlert",
  "tenantId": "xxx",
  "alertId": "alert-id",
  "status": "resolved", // newAlert, inProgress, resolved, dismissed
  "assignedTo": "analyst@domain.com", // optional
  "comment": "False positive" // optional
}
```

### GetLateralMovementPaths
**Purpose**: Identify lateral movement attack paths
```json
{
  "action": "GetLateralMovementPaths",
  "tenantId": "xxx",
  "userId": "user@domain.com" // optional
}
```

### GetExposedCredentials
**Purpose**: Find exposed credentials
```json
{
  "action": "GetExposedCredentials",
  "tenantId": "xxx"
}
```

### GetIdentitySecureScore
**Purpose**: Get identity secure score
```json
{
  "action": "GetIdentitySecureScore",
  "tenantId": "xxx"
}
```

### GetSuspiciousActivities
**Purpose**: List suspicious identity activities
```json
{
  "action": "GetSuspiciousActivities",
  "tenantId": "xxx",
  "userId": "user@domain.com", // optional
  "filter": "severity eq 'high'" // optional
}
```

### GetHealthIssues
**Purpose**: Get MDI sensor health issues
```json
{
  "action": "GetHealthIssues",
  "tenantId": "xxx"
}
```

### GetRecommendations
**Purpose**: Get identity security recommendations
```json
{
  "action": "GetRecommendations",
  "tenantId": "xxx"
}
```

### GetSensitiveUsers
**Purpose**: List sensitive/privileged users
```json
{
  "action": "GetSensitiveUsers",
  "tenantId": "xxx"
}
```

### GetAlertStatistics
**Purpose**: Get alert statistics
```json
{
  "action": "GetAlertStatistics",
  "tenantId": "xxx",
  "days": 30 // optional, defaults to 7
}
```

### GetConfiguration
**Purpose**: Get MDI configuration details
```json
{
  "action": "GetConfiguration",
  "tenantId": "xxx"
}
```

---

## 🟡 EntraIDWorker - Identity & Access (13 actions)

### DisableUser
**Purpose**: Disable compromised user account
```json
{
  "action": "DisableUser",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

### EnableUser
**Purpose**: Re-enable user account
```json
{
  "action": "EnableUser",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

### ResetPassword
**Purpose**: Force password reset
```json
{
  "action": "ResetPassword",
  "tenantId": "xxx",
  "userId": "user@domain.com",
  "temporaryPassword": "P@ssw0rd123!", // optional, auto-generated if omitted
  "forceChangePasswordNextSignIn": true // optional
}
```

### RevokeSessions
**Purpose**: Revoke all active sessions
```json
{
  "action": "RevokeSessions",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

### ConfirmCompromised
**Purpose**: Mark user as compromised in Identity Protection
```json
{
  "action": "ConfirmCompromised",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

### DismissRisk
**Purpose**: Dismiss user risk (false positive)
```json
{
  "action": "DismissRisk",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

### GetRiskDetections
**Purpose**: Get risk detections
```json
{
  "action": "GetRiskDetections",
  "tenantId": "xxx",
  "userId": "user@domain.com", // optional
  "filter": "riskLevel eq 'high'", // optional
  "top": 50 // optional
}
```

### GetRiskyUsers
**Purpose**: List risky users
```json
{
  "action": "GetRiskyUsers",
  "tenantId": "xxx",
  "filter": "riskState eq 'atRisk'", // optional
  "top": 50 // optional
}
```

### CreateNamedLocation
**Purpose**: Create IP-based named location for Conditional Access
```json
{
  "action": "CreateNamedLocation",
  "tenantId": "xxx",
  "displayName": "Corporate IPs",
  "ipRanges": "203.0.113.0/24,198.51.100.0/24",
  "isTrusted": true // optional
}
```

### GetConditionalAccessPolicies
**Purpose**: List Conditional Access policies
```json
{
  "action": "GetConditionalAccessPolicies",
  "tenantId": "xxx"
}
```

### GetSignInLogs
**Purpose**: Retrieve sign-in logs
```json
{
  "action": "GetSignInLogs",
  "tenantId": "xxx",
  "userId": "user@domain.com", // optional
  "filter": "status/errorCode ne 0", // optional, failed sign-ins
  "top": 100 // optional
}
```

### GetAuditLogs
**Purpose**: Retrieve audit logs
```json
{
  "action": "GetAuditLogs",
  "tenantId": "xxx",
  "filter": "activityDisplayName eq 'Add user'", // optional
  "top": 100 // optional
}
```

### GetUser
**Purpose**: Get user details
```json
{
  "action": "GetUser",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

---

## 🔴 IntuneWorker - Device Management (8 actions)

### RemoteLock
**Purpose**: Lock device remotely
```json
{
  "action": "RemoteLock",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

### WipeDevice
**Purpose**: Factory reset device
```json
{
  "action": "WipeDevice",
  "tenantId": "xxx",
  "deviceId": "intune-device-id",
  "keepEnrollmentData": false, // optional
  "keepUserData": false // optional
}
```

### RetireDevice
**Purpose**: Remove corporate data only
```json
{
  "action": "RetireDevice",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

### SyncDevice
**Purpose**: Force device sync with Intune
```json
{
  "action": "SyncDevice",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

### DefenderScan
**Purpose**: Trigger Windows Defender scan
```json
{
  "action": "DefenderScan",
  "tenantId": "xxx",
  "deviceId": "intune-device-id",
  "scanType": "Quick" // Quick or Full, optional
}
```

### GetManagedDevices
**Purpose**: List managed devices
```json
{
  "action": "GetManagedDevices",
  "tenantId": "xxx",
  "filter": "operatingSystem eq 'Windows'", // optional
  "top": 100 // optional
}
```

### GetDeviceCompliance
**Purpose**: Check device compliance status
```json
{
  "action": "GetDeviceCompliance",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

### GetDeviceConfiguration
**Purpose**: Get device configuration profiles
```json
{
  "action": "GetDeviceConfiguration",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

---

## 🟠 AzureWorker - Infrastructure Security (8 actions)

### AddNSGDenyRule
**Purpose**: Add deny rule to Network Security Group
```json
{
  "action": "AddNSGDenyRule",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name",
  "nsgName": "nsg-name",
  "sourceIp": "203.0.113.45",
  "ruleName": "BlockMaliciousIP", // optional
  "priority": 100 // optional
}
```

### StopVM
**Purpose**: Stop virtual machine
```json
{
  "action": "StopVM",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name",
  "vmName": "vm-name"
}
```

### DisableStoragePublicAccess
**Purpose**: Disable public access to storage account
```json
{
  "action": "DisableStoragePublicAccess",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name",
  "storageAccountName": "storageaccount"
}
```

### RemoveVMPublicIP
**Purpose**: Remove public IP from VM
```json
{
  "action": "RemoveVMPublicIP",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name",
  "vmName": "vm-name"
}
```

### GetVMs
**Purpose**: List virtual machines
```json
{
  "action": "GetVMs",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name" // optional, lists all if omitted
}
```

### GetResourceGroups
**Purpose**: List resource groups
```json
{
  "action": "GetResourceGroups",
  "tenantId": "xxx",
  "subscriptionId": "sub-id"
}
```

### GetNSGs
**Purpose**: List network security groups
```json
{
  "action": "GetNSGs",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name" // optional
}
```

### GetStorageAccounts
**Purpose**: List storage accounts
```json
{
  "action": "GetStorageAccounts",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name" // optional
}
```

---

## 📝 Common Response Format

All workers return this format:

### Success Response
```json
{
  "success": true,
  "action": "ActionName",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "result": {
    // Action-specific data
  },
  "timestamp": "2025-11-10T12:34:56.789Z"
}
```

### Error Response
```json
{
  "success": false,
  "action": "ActionName",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "error": "Detailed error message",
  "timestamp": "2025-11-10T12:34:56.789Z"
}
```

---

## 🎯 Common Use Cases

### 1. Account Compromise Response
```bash
# 1. Disable user
EntraIDWorker -> DisableUser

# 2. Revoke all sessions
EntraIDWorker -> RevokeSessions

# 3. Mark as compromised
EntraIDWorker -> ConfirmCompromised

# 4. Lock their devices
IntuneWorker -> RemoteLock (for each device)

# 5. Reset password
EntraIDWorker -> ResetPassword
```

### 2. Phishing Email Response
```bash
# 1. Delete phishing email from mailboxes
MDOWorker -> RemediateEmail

# 2. Submit to Microsoft for analysis
MDOWorker -> SubmitEmailThreat

# 3. Remove any forwarding rules
MDOWorker -> RemoveMailForwardingRules

# 4. Check for suspicious sign-ins
EntraIDWorker -> GetSignInLogs
```

### 3. Lateral Movement Detection
```bash
# 1. Get lateral movement paths
MDIWorker -> GetLateralMovementPaths

# 2. Get suspicious activities
MDIWorker -> GetSuspiciousActivities

# 3. Check for exposed credentials
MDIWorker -> GetExposedCredentials

# 4. Disable affected accounts
EntraIDWorker -> DisableUser (for each user)
```

### 4. Compromised Azure Resource
```bash
# 1. Stop compromised VM
AzureWorker -> StopVM

# 2. Remove public IP
AzureWorker -> RemoveVMPublicIP

# 3. Add NSG deny rule for attacker IP
AzureWorker -> AddNSGDenyRule

# 4. Check MDC alerts
MDCWorker -> GetSecurityAlerts
```

### 5. Malware Outbreak Response
```bash
# 1. Isolate infected devices
IntuneWorker -> RemoteLock

# 2. Trigger Defender scan
IntuneWorker -> DefenderScan

# 3. Check device compliance
IntuneWorker -> GetDeviceCompliance

# 4. Wipe if necessary
IntuneWorker -> WipeDevice
```

---

## 🔗 Worker Endpoints

| Worker | Endpoint | Authentication |
|--------|----------|----------------|
| MDOWorker | `https://your-app.azurewebsites.net/api/MDOWorker` | Function key |
| MDCWorker | `https://your-app.azurewebsites.net/api/MDCWorker` | Function key |
| MDIWorker | `https://your-app.azurewebsites.net/api/MDIWorker` | Function key |
| EntraIDWorker | `https://your-app.azurewebsites.net/api/EntraIDWorker` | Function key |
| IntuneWorker | `https://your-app.azurewebsites.net/api/IntuneWorker` | Function key |
| AzureWorker | `https://your-app.azurewebsites.net/api/AzureWorker` | Function key |

---

## 📚 Additional Resources

- **Architecture**: See `WORKER_PATTERN_ARCHITECTURE.md`
- **Implementation**: See `IMPLEMENTATION_COMPLETE.md`
- **Deployment**: See `deployment/README.md`
- **Workbook Integration**: See `docs/WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md`

---

## ✅ Quick Testing

### Using PowerShell
```powershell
$headers = @{
    "x-functions-key" = "your-function-key"
    "Content-Type" = "application/json"
}

$body = @{
    action = "GetUser"
    tenantId = "your-tenant-id"
    userId = "user@domain.com"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "https://your-app.azurewebsites.net/api/EntraIDWorker" `
    -Method Post `
    -Headers $headers `
    -Body $body

$response | ConvertTo-Json -Depth 10
```

### Using cURL
```bash
curl -X POST https://your-app.azurewebsites.net/api/EntraIDWorker \
  -H "x-functions-key: your-function-key" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "GetUser",
    "tenantId": "your-tenant-id",
    "userId": "user@domain.com"
  }'
```

---

## 🎉 Summary

- **6 Workers**: MDO, MDC, MDI, EntraID, Intune, Azure
- **50 Actions**: Complete coverage of Microsoft security stack
- **Consistent API**: Same request/response format across all workers
- **Multi-Tenant**: Pass tenantId in every request
- **Direct Responses**: Workbook compatible JSON
- **Production Ready**: Error handling, logging, validation

Ready for deployment! 🚀
