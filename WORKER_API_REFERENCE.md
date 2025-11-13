# DefenderXDR C2 XSOAR - Worker API Reference

**Version**: 3.0.0  
**Last Updated**: November 13, 2025

---

## Overview

This document provides comprehensive API reference for all 7 DefenderXDR workers. Each worker is a self-contained Azure Function that handles a specific Microsoft security service.

### Architecture

```
Gateway → Orchestrator → 7 Self-Contained Workers
                           ├── MDEWorker (63 actions)
                           ├── MDOWorker (16 actions)
                           ├── MDIWorker (11 actions)
                           ├── EntraIDWorker (20 actions)
                           ├── IntuneWorker (18 actions)
                           ├── AzureWorker (23 actions)
                           └── MCASWorker (15 actions)
```

**Total Actions**: 166

---

## Table of Contents

1. [MDE Worker - Microsoft Defender for Endpoint](#1-mde-worker---microsoft-defender-for-endpoint) (63 actions)
2. [MDO Worker - Microsoft Defender for Office 365](#2-mdo-worker---microsoft-defender-for-office-365) (16 actions)
3. [MDI Worker - Microsoft Defender for Identity](#3-mdi-worker---microsoft-defender-for-identity) (11 actions)
4. [Entra ID Worker - Azure Active Directory](#4-entra-id-worker---azure-active-directory) (20 actions)
5. [Intune Worker - Mobile Device Management](#5-intune-worker---mobile-device-management) (18 actions)
6. [Azure Worker - Cloud Infrastructure Security](#6-azure-worker---cloud-infrastructure-security) (23 actions)
7. [MCAS Worker - Microsoft Defender for Cloud Apps](#7-mcas-worker---microsoft-defender-for-cloud-apps) (15 actions)
8. [API Usage Examples](#8-api-usage-examples)
9. [Workbook Integration Patterns](#9-workbook-integration-patterns)

---

## 1. MDE Worker - Microsoft Defender for Endpoint

**Total Actions**: 63  
**API Base**: `https://api.securitycenter.microsoft.com/api`  
**Authentication**: OAuth2 (MDE API scope)

### 1.1 Device Actions (14)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **IsolateDevice** | Manual | `machineId`, `isolationType` ("Full"/"Selective"), `comment` | Isolate device from network |
| **UnisolateDevice** | Manual | `machineId`, `comment` | Remove network isolation |
| **RestrictApp** | Manual | `machineId`, `comment` | Allow only Microsoft-signed binaries |
| **UnrestrictApp** | Manual | `machineId`, `comment` | Remove app execution restrictions |
| **RunAVScan** | Manual | `machineId`, `scanType` ("Quick"/"Full"), `comment` | Execute antivirus scan |
| **CollectInvestigationPackage** | Manual | `machineId`, `comment` | Collect forensic package (logs, registry, memory) |
| **OffboardDevice** | Manual | `machineId`, `comment` | Remove device from MDE |
| **StopAndQuarantineFile** | Manual | `machineId`, `sha1`, `comment` | Stop and quarantine file by hash |
| **GetDevices** | Query | `filter` (optional) | List all devices with optional OData filter |
| **GetDeviceInfo** | Query | `machineId` | Get specific device details |
| **GetActionStatus** | Query | `actionId` | Get device action status |
| **GetAllActions** | Query | `filter` (optional) | List all device actions with optional filter |
| **CancelAction** | Manual | `actionId`, `comment` | Cancel pending/in-progress action |
| **StartInvestigation** | Manual | `machineId`, `comment` | Start automated investigation |

**Response Format** (Device List):
```json
{
  "success": true,
  "action": "GetDevices",
  "data": {
    "value": [{
      "id": "abc123...",
      "computerDnsName": "DESKTOP-WIN10",
      "osPlatform": "Windows10",
      "riskScore": "High",
      "healthStatus": "Active",
      "isolationStatus": "NotIsolated",
      "lastSeen": "2025-11-13T10:30:00Z"
    }]
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

### 1.2 Live Response Actions (15)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **StartSession** | Manual | `machineId`, `comment` | Start live response session |
| **GetSession** | Query | `sessionId` | Get session status and commands |
| **RunScript** | Manual | `sessionId`, `scriptName`, `arguments`, `timeout` | Execute PowerShell script from library |
| **GetFile** | Manual | `sessionId`, `filePath` | Download file from device |
| **PutFile** | Manual | `sessionId`, `fileName` | Upload file to device (from library) |
| **InvokeCommand** | Manual | `sessionId`, `command`, `timeout` | Execute live response command |
| **GetCommandResult** | Query | `sessionId`, `commandId` | Get command output |
| **GetProcesses** | Query | `sessionId` | List running processes |
| **KillProcess** | Manual | `sessionId`, `processId` | Terminate process by ID |
| **GetRegistryValue** | Query | `sessionId`, `keyPath`, `valueName` | Read registry value |
| **SetRegistryValue** | Manual | `sessionId`, `keyPath`, `valueName`, `value`, `valueType` | Write registry value |
| **DeleteRegistryValue** | Manual | `sessionId`, `keyPath`, `valueName` | Delete registry value |
| **FindFiles** | Query | `sessionId`, `fileName`, `folderPath` | Search for files |
| **GetFileInfo** | Query | `sessionId`, `filePath` | Get file metadata (hash, size, attributes) |
| **GetLibraryFiles** | Query | - | List all Live Response library files |

**Response Format** (Live Response Command):
```json
{
  "success": true,
  "action": "InvokeCommand",
  "data": {
    "commandId": "cmd-12345",
    "status": "Completed",
    "exitCode": 0,
    "output": "C:\\Users\\admin\\Desktop\n"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

### 1.3 Threat Intelligence Indicators (12)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **AddIndicator** | Manual | `indicatorValue`, `indicatorType` ("FileSha1"/"IpAddress"/"DomainName"/"Url"), `action` ("Alert"/"Block"), `severity`, `title`, `description`, `expirationTime` | Add generic threat indicator |
| **RemoveIndicator** | Manual | `indicatorId` | Remove indicator by ID |
| **GetIndicators** | Query | `filter` (optional) | List all indicators |
| **GetIndicator** | Query | `indicatorId` | Get indicator details |
| **UpdateIndicator** | Manual | `indicatorId`, `expirationTime`, `severity`, `description` | Update indicator properties |
| **BulkAddIndicators** | Manual | `indicators[]` (array of indicator objects) | Add multiple indicators |
| **BulkRemoveIndicators** | Manual | `indicatorIds[]` | Remove multiple indicators |
| **AddFileIndicator** | Manual | `sha1`, `action`, `severity`, `title`, `description` | Add file hash indicator (shorthand) |
| **AddIPIndicator** | Manual | `ipAddress`, `action`, `severity`, `title`, `description` | Add IP address indicator (shorthand) |
| **AddURLIndicator** | Manual | `url`, `action`, `severity`, `title`, `description` | Add URL indicator (shorthand) |
| **AddDomainIndicator** | Manual | `domain`, `action`, `severity`, `title`, `description` | Add domain indicator (shorthand) |
| **RemoveDomainIndicator** | Manual | `domain` | Remove domain indicator |

**Response Format** (Indicator):
```json
{
  "success": true,
  "action": "AddFileIndicator",
  "data": {
    "id": "12345",
    "indicatorValue": "275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f",
    "indicatorType": "FileSha1",
    "action": "Block",
    "severity": "High",
    "expirationTime": "2025-12-13T10:00:00Z"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

### 1.4 Advanced Hunting (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **RunQuery** | Manual | `query` (KQL), `timeRange` (optional) | Execute KQL query against MDE Advanced Hunting schema |
| **SaveQuery** | Manual | `queryName`, `query`, `description` | Save query template |
| **GetQueryHistory** | Query | - | List saved queries |

**Response Format** (Advanced Hunting):
```json
{
  "success": true,
  "action": "RunQuery",
  "data": {
    "Schema": [
      {"Name": "Timestamp", "Type": "DateTime"},
      {"Name": "DeviceName", "Type": "String"},
      {"Name": "ActionType", "Type": "String"}
    ],
    "Results": [
      {
        "Timestamp": "2025-11-13T09:45:00Z",
        "DeviceName": "DESKTOP-WIN10",
        "ActionType": "ProcessCreated"
      }
    ]
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

### 1.5 Incident Management (6)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetIncidents** | Query | `filter` (optional) | List incidents with optional OData filter |
| **GetIncident** | Query | `incidentId` | Get incident details |
| **UpdateIncident** | Manual | `incidentId`, `status` ("Active"/"Resolved"), `classification` ("TruePositive"/"FalsePositive"), `determination`, `assignedTo` | Update incident properties |
| **AddComment** | Manual | `incidentId`, `comment` | Add comment to incident |
| **AssignIncident** | Manual | `incidentId`, `assignedTo` | Assign to user |
| **ResolveIncident** | Manual | `incidentId`, `classification`, `determination` | Resolve with classification |

### 1.6 Alert Management (5)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetAlerts** | Query | `filter` (optional) | List alerts with optional filter |
| **GetAlert** | Query | `alertId` | Get alert details |
| **UpdateAlert** | Manual | `alertId`, `status`, `assignedTo`, `classification` | Update alert properties |
| **ResolveAlert** | Manual | `alertId`, `status` ("Resolved") | Resolve alert |
| **ClassifyAlert** | Manual | `alertId`, `classification` ("TruePositive"/"FalsePositive"), `determination` | Classify alert |

---

## 2. MDO Worker - Microsoft Defender for Office 365

**Total Actions**: 16  
**API Base**: `https://graph.microsoft.com/beta` (Email), `https://security.microsoft.com` (Threat Submission)  
**Authentication**: OAuth2 (Graph Mail.ReadWrite, ThreatSubmission.ReadWrite)

### 2.1 Email Remediation (Graph Beta) (5)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **SoftDeleteEmails** | Manual | `emailIds[]`, `comment` | Move emails to Deleted Items folder |
| **HardDeleteEmails** | Manual | `emailIds[]`, `comment` | Permanently delete emails (recoverable from RecoverableItemsDeletion) |
| **MoveToJunk** | Manual | `emailIds[]`, `comment` | Move emails to Junk folder |
| **MoveToInbox** | Manual | `emailIds[]`, `comment` | Restore emails to Inbox |
| **MoveToDeletedItems** | Manual | `emailIds[]`, `comment` | Move to Deleted Items |

### 2.2 Email Search & ZAP (5)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **BulkEmailSearch** | Query | `sender`, `subject`, `dateRange`, `mailboxes[]` | Search emails across multiple mailboxes |
| **BulkEmailDelete** | Manual | `emailIds[]`, `deleteType` ("Soft"/"Hard") | Delete multiple emails by ID |
| **ZAPPhishing** | Manual | `emailIds[]`, `tenantId` | Zero-Hour Auto Purge for phishing |
| **ZAPMalware** | Manual | `emailIds[]`, `tenantId` | Zero-Hour Auto Purge for malware |
| **GetAnalyzedEmails** | Query | `filter` (optional) | Query analyzed email threats (Graph Beta) |

### 2.3 Threat Submission (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **SubmitEmailThreat** | Manual | `emailNetworkMessageId`, `recipientEmailAddress`, `category` ("Spam"/"Phishing"/"Malware") | Submit email to Microsoft for analysis |
| **SubmitURLThreat** | Manual | `url`, `category` | Submit malicious URL to Microsoft |
| **SubmitFileThreat** | Manual | `fileHash`, `fileName`, `category` | Submit malicious file to Microsoft |

### 2.4 Mail Flow & Rules (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **RemoveMailForwardingRules** | Manual | `userPrincipalName` | Remove all forwarding rules for user |
| **GetMailboxForwarders** | Query | - | List mailboxes with forwarding enabled |
| **DisableMailboxForwarding** | Manual | `userPrincipalName` | Disable mailbox forwarding |

**Response Format** (Email Remediation):
```json
{
  "success": true,
  "action": "SoftDeleteEmails",
  "data": {
    "processedCount": 5,
    "successCount": 5,
    "failedCount": 0,
    "emailIds": ["id1", "id2", "id3", "id4", "id5"]
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 3. MDI Worker - Microsoft Defender for Identity

**Total Actions**: 11  
**API Base**: `https://graph.microsoft.com/v1.0/identityProtection` + `https://api.aatp.azure.com/api`  
**Authentication**: OAuth2 (IdentityRiskEvent.Read.All)

### 3.1 Alert Management (2)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetAlerts** | Query | `filter` (optional) | Get MDI security alerts |
| **UpdateAlert** | Manual | `alertId`, `status`, `assignedTo` | Update alert status/assignment |

### 3.2 Identity Threat Detection (4)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetLateralMovementPaths** | Query | `userId` | Identify lateral movement attack paths |
| **GetExposedCredentials** | Query | `filter` (optional) | Find exposed credentials |
| **GetSuspiciousActivities** | Query | `userId`, `timeRange` | Query suspicious user activities |
| **GetSensitiveUsers** | Query | - | List sensitive user accounts (Domain Admins, etc.) |

### 3.3 Identity Security (5)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetIdentitySecureScore** | Query | - | Get identity security score |
| **GetHealthIssues** | Query | - | List MDI health issues (sensor connectivity, permissions) |
| **GetRecommendations** | Query | - | Get security recommendations |
| **GetAlertStatistics** | Query | `timeRange` | Get alert statistics |
| **GetConfiguration** | Query | - | Retrieve MDI configuration settings |

**Response Format** (Lateral Movement):
```json
{
  "success": true,
  "action": "GetLateralMovementPaths",
  "data": {
    "paths": [
      {
        "source": "user@domain.com",
        "destination": "DOMAIN-CONTROLLER-01",
        "pathLength": 3,
        "risk": "High",
        "devices": ["WORKSTATION-01", "SERVER-02", "DOMAIN-CONTROLLER-01"]
      }
    ]
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 4. Entra ID Worker - Azure Active Directory

**Total Actions**: 20  
**API Base**: `https://graph.microsoft.com/v1.0`  
**Authentication**: OAuth2 (User.ReadWrite.All, RoleManagement.ReadWrite.All, IdentityRiskEvent.ReadWrite.All)

### 4.1 User Account Management (6)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **DisableUser** | Manual | `userPrincipalName` | Disable user account (blocks sign-in) |
| **EnableUser** | Manual | `userPrincipalName` | Enable user account |
| **ResetPassword** | Manual | `userPrincipalName`, `newPassword` (optional) | Reset password (auto-generated if not provided) |
| **RevokeSessions** | Manual | `userPrincipalName` | Revoke all active refresh tokens/sessions |
| **ConfirmCompromised** | Manual | `userPrincipalName` | Mark user as compromised (triggers risk policies) |
| **DismissRisk** | Manual | `userPrincipalName` | Dismiss user risk detection |

### 4.2 Emergency Response Actions (7)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **DeleteAuthenticationMethod** | Manual | `userPrincipalName`, `methodId` | Delete specific MFA method (phone, authenticator app) |
| **DeleteAllMFAMethods** | Manual | `userPrincipalName` | Remove all MFA methods except password |
| **CreateEmergencyCAPolicy** | Manual | `userPrincipalName`, `policyName` | Create emergency Conditional Access block policy |
| **RemoveAdminRole** | Manual | `userPrincipalName` | Remove all admin role assignments |
| **RevokePIMActivation** | Manual | `userPrincipalName` | Revoke active PIM role activations |
| **GetUserAuthenticationMethods** | Query | `userPrincipalName` | List user's MFA methods |
| **GetUserRoleAssignments** | Query | `userPrincipalName` | List user's role assignments |

### 4.3 Identity Protection & Monitoring (7)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **GetRiskDetections** | Query | `filter` (optional) | Query risk detections (impossible travel, anonymous IP, etc.) |
| **GetRiskyUsers** | Query | `filter` (optional) | List risky users (aggregate risk level) |
| **CreateNamedLocation** | Manual | `locationName`, `ipRanges[]`, `isTrusted` | Create named location for Conditional Access |
| **GetConditionalAccessPolicies** | Query | - | List all CA policies |
| **GetSignInLogs** | Query | `userPrincipalName`, `timeRange` | Query sign-in logs |
| **GetAuditLogs** | Query | `filter`, `timeRange` | Query audit logs |
| **GetUser** | Query | `userPrincipalName` | Get user details |

**Response Format** (Emergency Response):
```json
{
  "success": true,
  "action": "DeleteAllMFAMethods",
  "data": {
    "deletedMethods": [
      {"type": "phoneAuthentication", "id": "method1"},
      {"type": "microsoftAuthenticator", "id": "method2"}
    ],
    "remainingMethods": [
      {"type": "password"}
    ]
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 5. Intune Worker - Mobile Device Management

**Total Actions**: 18  
**API Base**: `https://graph.microsoft.com/beta/deviceManagement`  
**Authentication**: OAuth2 (DeviceManagementManagedDevices.ReadWrite.All)

### 5.1 Device Management (8)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **RemoteLock** | Manual | `deviceId` | Lock device remotely (requires unlock PIN) |
| **WipeDevice** | Manual | `deviceId`, `keepEnrollmentData` (optional) | Factory reset device |
| **RetireDevice** | Manual | `deviceId` | Remove device from management (keeps user data) |
| **SyncDevice** | Manual | `deviceId` | Force device sync with Intune |
| **DefenderScan** | Manual | `deviceId`, `scanType` ("Quick"/"Full") | Run Defender scan (Windows only) |
| **GetManagedDevices** | Query | `filter` (optional) | List managed devices |
| **GetDeviceCompliance** | Query | `deviceId` | Get compliance status |
| **GetDeviceConfiguration** | Query | `deviceId` | Get configuration profile status |

### 5.2 Enhanced Device Actions (10)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **ResetDevicePasscode** | Manual | `deviceId` | Reset device passcode/PIN (auto-generated) |
| **RebootDeviceNow** | Manual | `deviceId` | Reboot device immediately |
| **ShutdownDevice** | Manual | `deviceId` | Shutdown device remotely |
| **EnableLostMode** | Manual | `deviceId`, `message`, `phoneNumber` | Enable iOS/macOS lost mode |
| **DisableLostMode** | Manual | `deviceId` | Disable lost mode |
| **TriggerComplianceEvaluation** | Manual | `deviceId` | Force compliance policy re-evaluation |
| **UpdateDefenderSignatures** | Manual | `deviceId` | Update antivirus definitions (Windows) |
| **BypassActivationLock** | Manual | `deviceId` | Bypass iOS activation lock (supervised devices) |
| **CleanWindowsDevice** | Manual | `deviceId`, `keepUserData` | Clean Windows device (keep enrollment) |
| **LogoutSharedAppleDevice** | Manual | `deviceId` | Logout current user on shared iPad |

**Response Format** (Remote Lock):
```json
{
  "success": true,
  "action": "RemoteLock",
  "data": {
    "deviceId": "device-12345",
    "actionId": "action-67890",
    "status": "Pending",
    "unlockPIN": "123456"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 6. Azure Worker - Cloud Infrastructure Security

**Total Actions**: 23  
**API Base**: `https://management.azure.com`  
**Authentication**: OAuth2 (Azure Resource Manager scope)

### 6.1 Network Security (4)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **AddNSGDenyRule** | Manual | `subscriptionId`, `resourceGroup`, `nsgName`, `ruleName`, `priority`, `sourceAddressPrefix`, `destinationAddressPrefix`, `destinationPortRange` | Add Network Security Group deny rule |
| **GetNSGs** | Query | `subscriptionId`, `resourceGroup` (optional) | List network security groups |
| **RemoveVMPublicIP** | Manual | `subscriptionId`, `resourceGroup`, `vmName` | Remove public IP from VM NIC |
| **ApplyIsolationNSG** | Manual | `subscriptionId`, `resourceGroup`, `vmName`, `isolationNSGName` | Apply isolation NSG to VM (blocks all traffic) |

### 6.2 VM Operations (8)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **StopVM** | Manual | `subscriptionId`, `resourceGroup`, `vmName` | Stop VM (deallocates resources) |
| **DeallocateVM** | Manual | `subscriptionId`, `resourceGroup`, `vmName` | Deallocate VM (releases public IP) |
| **RestartVM** | Manual | `subscriptionId`, `resourceGroup`, `vmName` | Restart VM |
| **RedeployVM** | Manual | `subscriptionId`, `resourceGroup`, `vmName` | Redeploy VM to new Azure host |
| **TakeVMSnapshot** | Manual | `subscriptionId`, `resourceGroup`, `vmName`, `snapshotName` | Create disk snapshot for forensics |
| **GetVMs** | Query | `subscriptionId`, `resourceGroup` (optional) | List virtual machines |
| **GetResourceGroups** | Query | `subscriptionId` | List resource groups |
| **GetStorageAccounts** | Query | `subscriptionId`, `resourceGroup` (optional) | List storage accounts |

### 6.3 Azure Firewall (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **BlockIPInFirewall** | Manual | `subscriptionId`, `resourceGroup`, `firewallName`, `ipAddress`, `ruleName` | Block malicious IP in Azure Firewall |
| **BlockDomainInFirewall** | Manual | `subscriptionId`, `resourceGroup`, `firewallName`, `domain`, `ruleName` | Block malicious domain |
| **EnableThreatIntel** | Manual | `subscriptionId`, `resourceGroup`, `firewallName`, `mode` ("Alert"/"Deny") | Enable threat intelligence mode |

### 6.4 Key Vault Security (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **DisableKeyVaultSecret** | Manual | `subscriptionId`, `resourceGroup`, `keyVaultName`, `secretName` | Disable compromised secret |
| **RotateKeyVaultKey** | Manual | `subscriptionId`, `resourceGroup`, `keyVaultName`, `keyName` | Rotate encryption key |
| **PurgeDeletedSecret** | Manual | `subscriptionId`, `resourceGroup`, `keyVaultName`, `secretName` | Permanently purge deleted secret |

### 6.5 Service Principal Management (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **DisableServicePrincipal** | Manual | `servicePrincipalId` | Disable compromised service principal |
| **RemoveAppCredentials** | Manual | `appId` | Remove all application credentials |
| **RevokeAppCertificates** | Manual | `appId` | Revoke all application certificates |

### 6.6 Storage Security (2)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **DisableStoragePublicAccess** | Manual | `subscriptionId`, `resourceGroup`, `storageAccountName` | Disable storage account public access |
| **GetStorageAccountKeys** | Query | `subscriptionId`, `resourceGroup`, `storageAccountName` | Get storage account access keys |

**Response Format** (NSG Rule):
```json
{
  "success": true,
  "action": "AddNSGDenyRule",
  "data": {
    "ruleName": "BlockMaliciousIP",
    "priority": 100,
    "access": "Deny",
    "direction": "Inbound",
    "sourceAddressPrefix": "203.0.113.45",
    "destinationAddressPrefix": "*",
    "destinationPortRange": "*",
    "protocol": "*"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 7. MCAS Worker - Microsoft Defender for Cloud Apps

**Total Actions**: 15  
**API Base**: `https://portal.cloudappsecurity.com/api`  
**Authentication**: OAuth2 (CloudApp.ReadWrite.All) + MCAS API Token

### 7.1 OAuth App Management (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **RevokeOAuthPermissions** | Manual | `userPrincipalName`, `appId` | Revoke OAuth permissions for specific user/app |
| **BanRiskyApp** | Manual | `appId`, `reason` | Ban risky OAuth app tenant-wide |
| **RevokeUserConsent** | Manual | `userPrincipalName` | Revoke all user OAuth app consents |

### 7.2 Session Management (3)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **TerminateActiveSession** | Manual | `userPrincipalName`, `sessionId` | Terminate active cloud app session |
| **BlockUserFromApp** | Manual | `userPrincipalName`, `appId` | Block user from specific app via CA |
| **RequireReauthentication** | Manual | `userPrincipalName`, `appId` | Force re-authentication for app |

### 7.3 File Management (4)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **QuarantineCloudFile** | Manual | `fileId`, `serviceName` ("OneDrive"/"SharePoint") | Quarantine malicious file |
| **RemoveExternalSharing** | Manual | `fileId`, `serviceName` | Remove external sharing links |
| **ApplySensitivityLabel** | Manual | `fileId`, `labelId` | Apply Microsoft Information Protection label |
| **RestoreFromQuarantine** | Manual | `fileId` | Restore file from quarantine |

### 7.4 Governance & Discovery (5)

| Action | Type | Parameters | Description |
|--------|------|------------|-------------|
| **BlockUnsanctionedApp** | Manual | `appId`, `reason` | Block unsanctioned cloud app via CA |
| **RemoveAppAccess** | Manual | `userPrincipalName`, `appId` | Remove all user access to app |
| **GetOAuthApps** | Query | `filter` (optional) | List all OAuth apps with consents |
| **GetUserAppConsents** | Query | `userPrincipalName` | Get user's OAuth app consents |
| **GetShadowITApps** | Query | `riskScore` (optional) | List discovered cloud apps (Shadow IT) |

**Response Format** (OAuth App Ban):
```json
{
  "success": true,
  "action": "BanRiskyApp",
  "data": {
    "appId": "12345-app-67890",
    "appName": "SuspiciousThirdPartyApp",
    "status": "Banned",
    "affectedUsers": 25,
    "reason": "Excessive permissions requested"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 8. API Usage Examples

### 8.1 Standard HTTP Request Format

All workers accept the same request format from the Orchestrator:

```http
POST https://{FunctionAppName}.azurewebsites.net/api/DefenderXDRMDEWorker
Content-Type: application/json

{
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "action": "IsolateDevice",
  "parameters": {
    "machineId": "abc123def456...",
    "isolationType": "Full",
    "comment": "Suspected ransomware infection"
  },
  "correlationId": "request-12345"
}
```

### 8.2 Response Format

All workers return consistent response structure:

```json
{
  "success": true,
  "action": "IsolateDevice",
  "data": {
    "id": "action-67890",
    "type": "Isolate",
    "machineId": "abc123def456...",
    "status": "Pending",
    "requestor": "admin@contoso.com",
    "creationDateTime": "2025-11-13T10:35:00Z"
  },
  "timestamp": "2025-11-13T10:35:00Z"
}
```

### 8.3 Error Response Format

```json
{
  "success": false,
  "action": "IsolateDevice",
  "error": "Device not found: abc123def456...",
  "timestamp": "2025-11-13T10:35:00Z"
}
```

---

## 9. Workbook Integration Patterns

### 9.1 CustomEndpoint Pattern (Auto-Refresh Queries)

**Use Case**: List operations that need auto-refresh (devices, indicators, incidents)

```json
{
  "version": "CustomEndpoint/1.0",
  "data": null,
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderXDRGateway",
  "body": "{\"service\":\"MDE\",\"action\":\"GetDevices\",\"tenantId\":\"{TenantId}\"}",
  "headers": [{"name": "Content-Type", "value": "application/json"}],
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.devices[*]",
      "columns": [
        {"path": "$.id", "columnid": "Device ID"},
        {"path": "$.computerDnsName", "columnid": "Device Name"},
        {"path": "$.riskScore", "columnid": "Risk Score"}
      ]
    }
  }]
}
```

**Gateway Response Transformation**:
- Input: `$.data.value[*]` (from MDE API)
- Output: `$.devices[*]` (workbook-friendly)

### 9.2 ARM Action Pattern (Manual Operations)

**Use Case**: Manual operations that require user confirmation (isolate, delete, remediate)

```json
{
  "type": "LinkItem/1.0",
  "links": [{
    "linkTarget": "ArmAction",
    "linkLabel": "🔒 Isolate Device",
    "armActionContext": {
      "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/DefenderXDRGateway",
      "headers": [
        {"name": "Content-Type", "value": "application/json"}
      ],
      "body": "{\"service\":\"MDE\",\"action\":\"IsolateDevice\",\"tenantId\":\"{TenantId}\",\"parameters\":{\"machineId\":\"{DeviceId}\",\"isolationType\":\"Full\"}}",
      "httpMethod": "POST"
    }
  }]
}
```

### 9.3 Multi-Tenant Pattern (Lighthouse)

```json
{
  "tenantId": "{LighthouseTenantId}",
  "action": "GetDevices",
  "parameters": {}
}
```

The worker automatically switches authentication context to the specified tenant.

---

## Summary Statistics

| Category | Actions | Workers |
|----------|---------|---------|
| **Device Security** | 32 | MDE (14) + Intune (18) |
| **Identity Security** | 31 | Entra ID (20) + MDI (11) |
| **Cloud Security** | 38 | Azure (23) + MCAS (15) |
| **Email Security** | 16 | MDO (16) |
| **Threat Intelligence** | 12 | MDE Indicators (12) |
| **Investigation & Hunting** | 12 | MDE Live Response (15) + Advanced Hunting (3) |
| **Incident Response** | 25 | Alerts (10) + Incidents (6) + Emergency CA (7) |

**Total Actions**: 166  
**Total Workers**: 7  
**Average Actions per Worker**: 23.7

---

## API Design Principles

1. **Self-Contained Workers**: Each worker is independent (no cross-worker dependencies)
2. **Consistent Interface**: All workers accept same request format (tenantId, action, parameters)
3. **Uniform Responses**: All workers return same response structure (success, action, data, timestamp)
4. **Workbook Optimized**: Gateway transforms responses for Azure Workbook JSONPath compatibility
5. **Multi-Tenant**: All workers support Lighthouse delegation via tenantId parameter
6. **Defensive Coding**: Parameter validation, error handling, correlation IDs
7. **Performance**: Parallel operations support, efficient token caching

---

**Version**: 3.0.0  
**Documentation Date**: November 13, 2025  
**Repository**: https://github.com/akefallonitis/defenderc2xsoar