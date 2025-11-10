# DefenderXDRC2XSOAR API Documentation v2.1.0

Complete API reference for all 68+ security actions across Microsoft Defender XDR stack.

---

## 📋 Table of Contents

1. [Authentication](#authentication)
2. [MDE Actions](#mde-microsoft-defender-for-endpoint)
3. [MDO Actions](#mdo-microsoft-defender-for-office-365)
4. [MDC Actions](#mdc-microsoft-defender-for-cloud)
5. [MDI Actions](#mdi-microsoft-defender-for-identity)
6. [Entra ID Actions](#entra-id-identity--access)
7. [Intune Actions](#intune-device-management)
8. [Azure Actions](#azure-infrastructure-security)
9. [Error Handling](#error-handling)
10. [Rate Limiting](#rate-limiting)

---

## Authentication

All API endpoints require multi-tenant Azure AD app registration credentials.

### **Environment Variables**
```
APPID=your-app-id
SECRETID=your-client-secret
```

### **Token Types by Service**
| Service | API Endpoint | Scope |
|---------|--------------|-------|
| MDE | `https://api.securitycenter.microsoft.com` | `https://api.securitycenter.microsoft.com/.default` |
| Graph (MDO/Entra/Intune/MDI) | `https://graph.microsoft.com` | `https://graph.microsoft.com/.default` |
| Azure RM (MDC/Azure) | `https://management.azure.com` | `https://management.azure.com/.default` |

### **Token Caching**
Tokens are automatically cached and refreshed by `AuthManager.psm1`. Cache key format:
```
{tenantId}|{service}|{appId}
```

---

## MDE (Microsoft Defender for Endpoint)

### **Base Endpoints**
- `/api/DefenderC2Dispatcher` - Device actions
- `/api/DefenderC2Orchestrator` - Live Response
- `/api/DefenderC2IncidentManager` - Incidents
- `/api/DefenderC2TIManager` - Threat Intelligence
- `/api/DefenderC2HuntManager` - Advanced Hunting
- `/api/DefenderC2CDManager` - Custom Detections

### **1. Isolate Device**
```http
POST /api/DefenderC2Dispatcher
Content-Type: application/json

{
  "action": "Isolate Device",
  "tenantId": "your-tenant-id",
  "deviceIds": "device-id-1,device-id-2",
  "isolationType": "Full",  // or "Selective"
  "comment": "Isolated due to suspicious activity"
}
```

**Response:**
```json
{
  "action": "Isolate Device",
  "status": "Initiated",
  "tenantId": "your-tenant-id",
  "timestamp": "2025-11-10T12:00:00Z",
  "details": "Device isolation (Full) initiated for 2 device(s)",
  "actionIds": ["action-guid-1", "action-guid-2"]
}
```

### **2. Run Antivirus Scan**
```http
POST /api/DefenderC2Dispatcher

{
  "action": "Run Antivirus Scan",
  "tenantId": "your-tenant-id",
  "deviceIds": "device-id",
  "scanType": "Quick",  // or "Full"
  "comment": "Scheduled scan"
}
```

### **3. Start Live Response Session**
```http
POST /api/DefenderC2Orchestrator

{
  "function": "GetLiveResponseSessions",
  "tenantId": "your-tenant-id"
}
```

### **4. Execute Live Response Script**
```http
POST /api/DefenderC2Orchestrator

{
  "function": "InvokeLiveResponseScript",
  "tenantId": "your-tenant-id",
  "DeviceIds": "device-id",
  "scriptName": "collect-logs.ps1",
  "arguments": "-Path C:\\Temp"
}
```

### **5. Get Incidents**
```http
POST /api/DefenderC2IncidentManager

{
  "action": "GetIncidents",
  "tenantId": "your-tenant-id",
  "severity": "High",  // optional: Low, Medium, High, Informational
  "status": "Active"   // optional: Active, Resolved, InProgress
}
```

### **6. Add File Indicator**
```http
POST /api/DefenderC2TIManager

{
  "action": "Add File Indicators",
  "tenantId": "your-tenant-id",
  "indicators": "sha256-hash-1,sha256-hash-2",
  "title": "Malicious file detected",
  "severity": "High",
  "recommendedAction": "Block"  // Block, Alert, Warn, Allowed
}
```

### **7. Execute Advanced Hunting Query**
```http
POST /api/DefenderC2HuntManager

{
  "action": "ExecuteHunt",
  "tenantId": "your-tenant-id",
  "huntQuery": "DeviceProcessEvents | where FileName == 'powershell.exe' | take 100",
  "huntName": "PowerShell Investigation"
}
```

---

## MDO (Microsoft Defender for Office 365)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Soft Delete Email**
```http
POST /api/DefenderXDRManager

{
  "service": "MDO",
  "action": "Soft Delete Email",
  "tenantId": "your-tenant-id",
  "networkMessageId": "message-id",
  "recipientEmail": "user@domain.com"
}
```

### **2. Hard Delete Email**
```http
POST /api/DefenderXDRManager

{
  "service": "MDO",
  "action": "Hard Delete Email",
  "tenantId": "your-tenant-id",
  "networkMessageId": "message-id",
  "recipientEmail": "user@domain.com"
}
```

### **3. Submit Email Threat**
```http
POST /api/DefenderXDRManager

{
  "service": "MDO",
  "action": "Submit Email Threat",
  "tenantId": "your-tenant-id",
  "category": "phishing",  // phishing, spam, malware
  "recipientEmail": "user@domain.com",
  "messageUrl": "https://outlook.office365.com/owa/?ItemID=..."
}
```

### **4. Remove Mail Forwarding**
```http
POST /api/DefenderXDRManager

{
  "service": "MDO",
  "action": "Remove Mail Forwarding",
  "tenantId": "your-tenant-id",
  "userId": "user@domain.com"
}
```

---

## MDC (Microsoft Defender for Cloud)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Get Security Alerts**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Get Security Alerts",
  "tenantId": "your-tenant-id",
  "subscriptionId": "azure-subscription-id",
  "filter": "properties/status eq 'Active'"  // optional
}
```

**Response:**
```json
{
  "service": "MDC",
  "status": "Initiated",
  "details": "MDC security alerts retrieved",
  "alerts": [
    {
      "name": "alert-name",
      "properties": {
        "alertDisplayName": "Suspicious network activity",
        "severity": "High",
        "status": "Active",
        "startTimeUtc": "2025-11-10T10:00:00Z",
        "compromisedEntity": "vm-name"
      }
    }
  ]
}
```

### **2. Update Security Alert**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Update Security Alert",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "resourceGroupName": "rg-name",
  "alertName": "alert-resource-name",
  "status": "Dismissed"  // Active, InProgress, Dismissed, Resolved
}
```

### **3. Get Security Recommendations**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Get Recommendations",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "filter": "properties/state eq 'Unhealthy'"
}
```

### **4. Get Secure Score**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Get Secure Score",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id"
}
```

### **5. Enable Defender Plan**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Enable Defender Plan",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "planName": "VirtualMachines",  // VirtualMachines, SqlServers, AppServices, etc.
  "pricingTier": "Standard"  // Standard (enabled) or Free (disabled)
}
```

### **6. Request JIT VM Access**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Request JIT Access",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "resourceGroupName": "rg-name",
  "location": "eastus",
  "policyName": "jit-policy-name",
  "virtualMachineId": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}",
  "port": 3389,
  "allowedSourceAddress": "203.0.113.5"
}
```

### **7. Get Regulatory Compliance**
```http
POST /api/DefenderXDRManager

{
  "service": "MDC",
  "action": "Get Compliance",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "standard": "Azure-CIS-1.3.0"  // optional
}
```

---

## MDI (Microsoft Defender for Identity)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Get MDI Alerts**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Alerts",
  "tenantId": "your-tenant-id",
  "filter": "severity eq 'high'",  // optional
  "top": 100
}
```

**Response:**
```json
{
  "service": "MDI",
  "status": "Initiated",
  "details": "MDI alerts retrieved",
  "alerts": [
    {
      "id": "alert-guid",
      "title": "Suspected brute force attack",
      "severity": "high",
      "status": "new",
      "category": "CredentialAccess",
      "serviceSource": "microsoftDefenderForIdentity"
    }
  ]
}
```

### **2. Update MDI Alert**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Update Alert",
  "tenantId": "your-tenant-id",
  "alertId": "alert-guid",
  "status": "resolved",  // new, inProgress, resolved
  "classification": "truePositive",  // unknown, falsePositive, truePositive, benignPositive
  "comment": "Investigated and remediated - credential reset enforced"
}
```

### **3. Get Lateral Movement Paths**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Lateral Movement",
  "tenantId": "your-tenant-id",
  "entityId": "user-or-device-guid"  // optional
}
```

### **4. Get Suspicious Activities**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Suspicious Activities",
  "tenantId": "your-tenant-id",
  "severity": "high",  // optional: low, medium, high, informational
  "status": "new",     // optional: new, inProgress, resolved
  "days": 7            // optional: lookback period (default 7)
}
```

### **5. Get Exposed Credentials**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Exposed Credentials",
  "tenantId": "your-tenant-id"
}
```

### **6. Get Account Enumeration**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Account Enumeration",
  "tenantId": "your-tenant-id",
  "sourceIP": "192.168.1.100"  // optional
}
```

### **7. Get Privilege Escalation**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Privilege Escalation",
  "tenantId": "your-tenant-id"
}
```

### **8. Get Reconnaissance Activities**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Reconnaissance",
  "tenantId": "your-tenant-id"
}
```

### **9. Get Identity Secure Score**
```http
POST /api/DefenderXDRManager

{
  "service": "MDI",
  "action": "Get Identity Secure Score",
  "tenantId": "your-tenant-id"
}
```

---

## Entra ID (Identity & Access)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Disable User Account**
```http
POST /api/DefenderXDRManager

{
  "service": "EntraID",
  "action": "Disable User",
  "tenantId": "your-tenant-id",
  "userId": "user@domain.com"
}
```

### **2. Reset User Password**
```http
POST /api/DefenderXDRManager

{
  "service": "EntraID",
  "action": "Reset User Password",
  "tenantId": "your-tenant-id",
  "userId": "user@domain.com",
  "newPassword": "TempP@ss123!",  // optional, auto-generated if not provided
  "forceChange": true
}
```

### **3. Confirm User Compromised**
```http
POST /api/DefenderXDRManager

{
  "service": "EntraID",
  "action": "Confirm User Compromised",
  "tenantId": "your-tenant-id",
  "userIds": "user-guid-1,user-guid-2"
}
```

### **4. Revoke User Sessions**
```http
POST /api/DefenderXDRManager

{
  "service": "EntraID",
  "action": "Revoke User Sessions",
  "tenantId": "your-tenant-id",
  "userId": "user@domain.com"
}
```

### **5. Create Named Location (IP Block)**
```http
POST /api/DefenderXDRManager

{
  "service": "ConditionalAccess",
  "action": "Create Named Location",
  "tenantId": "your-tenant-id",
  "displayName": "Blocked IPs - Threat Actor",
  "ipRanges": "192.0.2.0/24,198.51.100.50",
  "isTrusted": false
}
```

---

## Intune (Device Management)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Remote Lock Device**
```http
POST /api/DefenderXDRManager

{
  "service": "Intune",
  "action": "Remote Lock Device",
  "tenantId": "your-tenant-id",
  "deviceId": "intune-device-guid"
}
```

### **2. Wipe Device**
```http
POST /api/DefenderXDRManager

{
  "service": "Intune",
  "action": "Wipe Device",
  "tenantId": "your-tenant-id",
  "deviceId": "intune-device-guid",
  "keepEnrollmentData": false,
  "keepUserData": false
}
```

### **3. Retire Device**
```http
POST /api/DefenderXDRManager

{
  "service": "Intune",
  "action": "Retire Device",
  "tenantId": "your-tenant-id",
  "deviceId": "intune-device-guid"
}
```

---

## Azure (Infrastructure Security)

### **Base Endpoint**
`/api/DefenderXDRManager`

### **1. Add NSG Deny Rule**
```http
POST /api/DefenderXDRManager

{
  "service": "Azure",
  "action": "Add NSG Deny Rule",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "resourceGroupName": "rg-name",
  "nsgName": "nsg-name",
  "ruleName": "Block-Attacker-IP",
  "sourceAddressPrefix": "192.0.2.50",
  "destinationPortRange": "*",
  "priority": 100,
  "protocol": "*"
}
```

### **2. Stop Azure VM**
```http
POST /api/DefenderXDRManager

{
  "service": "Azure",
  "action": "Stop Azure VM",
  "tenantId": "your-tenant-id",
  "subscriptionId": "subscription-id",
  "resourceGroupName": "rg-name",
  "vmName": "compromised-vm"
}
```

---

## Error Handling

All endpoints return consistent error formats:

### **Success Response**
```json
{
  "status": "Initiated" or "Success",
  "action": "action-name",
  "service": "service-name",
  "tenantId": "tenant-id",
  "timestamp": "2025-11-10T12:00:00Z",
  "details": "Action completed successfully",
  ... additional response data ...
}
```

### **Error Response**
```json
{
  "error": "Error message",
  "details": "Detailed error information",
  "action": "action-name",
  "service": "service-name"
}
```

### **Common HTTP Status Codes**
- `200 OK` - Request successful
- `400 Bad Request` - Missing or invalid parameters
- `401 Unauthorized` - Authentication failed
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

---

## Rate Limiting

### **Token Rate Limits**
Authentication tokens are cached to minimize rate limit impact:
- Token cache duration: Until 5 minutes before expiration
- Typical token lifetime: 1 hour
- Auto-refresh on 401 responses

### **API Rate Limits by Service**
| Service | Rate Limit | Scope |
|---------|------------|-------|
| MDE API | 100 calls/minute | Per tenant |
| Graph API | 10,000 calls/10 minutes | Per app per tenant |
| Azure RM | Varies by operation | Per subscription |

### **Rate Limit Handling**
All functions include automatic retry logic for 429 responses:
- Honors `Retry-After` header
- Exponential backoff for 5xx errors
- Maximum 3 retry attempts

---

## Best Practices

### **1. Batch Operations**
When performing multiple operations, batch them where possible:
```javascript
// Good: Batch device isolation
deviceIds: "device-1,device-2,device-3"

// Bad: Individual calls for each device
```

### **2. Use Filters**
Always filter results to reduce response size:
```javascript
filter: "properties/status eq 'Active' and properties/severity eq 'High'"
```

### **3. Specify Top Parameter**
Limit response sizes with `top` parameter:
```javascript
top: 100  // Retrieve only 100 items
```

### **4. Multi-Tenant Isolation**
Always include `tenantId` to ensure proper tenant isolation:
```javascript
tenantId: "tenant-specific-id"
```

### **5. Monitor Token Cache**
Periodically check cache health:
```powershell
Get-TokenCacheStats | ConvertTo-Json
```

---

**DefenderXDRC2XSOAR API Documentation v2.1.0** - Complete reference for 68+ security actions
