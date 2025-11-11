# DefenderC2XSOAR - Required Parameters Guide

## 🎯 PURPOSE

This guide documents which parameters must be passed from the workbook to each service action. The function app is **completely agnostic** - it always expects parameters from the caller.

---

## 📋 UNIVERSAL PARAMETERS

These parameters are **REQUIRED** for ALL requests:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `tenantId` | string (GUID) | Azure AD Tenant ID | `a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9` |
| `service` | string | Service name (uppercase) | `MDE`, `MDC`, `MDI`, `ENTRAID`, `INTUNE`, `AZURE` |
| `action` | string | Action to perform | `GetAllDevices`, `GetSecurityAlerts` |

---

## 🛡️ SERVICE 1: MDE (Microsoft Defender for Endpoint)

### ✅ No Additional Parameters Required
- `GetAllDevices`
- `GetIncidents`
- `GetAllIndicators`

### 📝 Action-Specific Parameters

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `AdvancedHunt` | `query` (KQL string) | None | `query: "DeviceInfo \| take 10"` |
| `GetDeviceInfo` | `machineId` (device ID) | None | `machineId: "013cd622..."` |
| `IsolateDevice` | `machineId`, `isolationType` | `comment` | `isolationType: "Full"` |
| `UnisolateDevice` | `machineId` | `comment` | - |
| `RestrictAppExecution` | `machineId` | `comment` | - |
| `UnrestrictAppExecution` | `machineId` | `comment` | - |
| `RunAntivirusScan` | `machineId`, `scanType` | `comment` | `scanType: "Quick"` or `"Full"` |
| `CollectInvestigationPackage` | `machineId` | `comment` | - |
| `StopAndQuarantineFile` | `machineId`, `sha1` | `comment` | `sha1: "abc123..."` |
| `AddFileIndicator` | `indicatorValue`, `indicatorType`, `action`, `title` | `description`, `severity`, `expirationDateTime` | `indicatorType: "FileSha1"` |

---

## ☁️ SERVICE 2: MDC (Microsoft Defender for Cloud)

### ✅ ALWAYS REQUIRED: `subscriptionId`

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `GetSecurityAlerts` | `subscriptionId` | `filter` | `subscriptionId: "80110e3c-..."` |
| `GetRecommendations` | `subscriptionId` | None | - |
| `GetSecureScore` | `subscriptionId` | None | - |
| `GetDefenderPlans` | `subscriptionId` | None | - |
| `UpdateSecurityAlert` | `subscriptionId`, `alertId`, `status` | None | `status: "Dismissed"` |
| `EnableDefenderPlan` | `subscriptionId`, `defenderPlan` | None | `defenderPlan: "VirtualMachines"` |

**Workbook Implementation**:
```json
{
  "service": "MDC",
  "action": "GetSecurityAlerts",
  "tenantId": "{tenantId}",
  "subscriptionId": "{subscriptionId}"
}
```

---

## 🔐 SERVICE 3: MDI (Microsoft Defender for Identity)

### ✅ No Additional Parameters Required
- `GetAlerts`
- `GetLateralMovementPaths`
- `GetExposedCredentials`
- `GetIdentitySecureScore`

### 📝 Action-Specific Parameters

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `GetAlerts` | None | `filter` | `filter: "severity eq 'High'"` |
| `UpdateAlert` | `alertId`, `status` | None | `status: "Resolved"` |

---

## 👤 SERVICE 4: ENTRAID (Identity & Access Management)

### ✅ Actions WITHOUT userId Parameter
- `GetRiskyUsers` - Lists all risky users
- `GetConditionalAccessPolicies` - Lists CA policies
- `CreateNamedLocation` - Requires `locationName`, `ipRanges`

### 📝 Actions Requiring userId

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `DisableUser` | `userId` (UPN or Object ID) | None | `userId: "user@domain.com"` |
| `EnableUser` | `userId` | None | - |
| `ResetPassword` | `userId` | `newPassword` | Auto-generated if not provided |
| `ConfirmCompromised` | `userId` | None | Marks user as compromised |
| `DismissRisk` | `userId` | None | Dismisses user risk |
| `RevokeSessions` | `userId` | None | Revokes all sign-in sessions |
| `GetRiskDetections` | `userId` | None | Gets risk detections for user |

**Workbook Implementation**:
```json
{
  "service": "ENTRAID",
  "action": "GetRiskyUsers",
  "tenantId": "{tenantId}"
}

// OR for user-specific action:
{
  "service": "ENTRAID",
  "action": "DisableUser",
  "tenantId": "{tenantId}",
  "userId": "compromised.user@domain.com"
}
```

---

## 📱 SERVICE 5: INTUNE (Device Management)

### ✅ Actions WITHOUT deviceId Parameter
- `GetManagedDevices` - Lists all managed devices
- `GetDeviceComplianceStatus` - Lists compliance status

### 📝 Actions Requiring deviceId

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `RemoteLock` | `deviceId` (Intune device ID) | None | `deviceId: "abc-123..."` |
| `WipeDevice` | `deviceId` | None | ⚠️ **DESTRUCTIVE** |
| `RetireDevice` | `deviceId` | None | Removes from management |
| `SyncDevice` | `deviceId` | None | Forces device sync |
| `DefenderScan` | `deviceId` | None | Triggers Defender scan |

**Workbook Implementation**:
```json
{
  "service": "INTUNE",
  "action": "GetManagedDevices",
  "tenantId": "{tenantId}"
}

// OR for device-specific action:
{
  "service": "INTUNE",
  "action": "RemoteLock",
  "tenantId": "{tenantId}",
  "deviceId": "device-guid-here"
}
```

---

## 🏗️ SERVICE 6: AZURE (Infrastructure Security)

### ✅ ALWAYS REQUIRED: `subscriptionId`

### 📝 Actions and Parameters

| Action | Required Parameters | Optional Parameters | Example |
|--------|---------------------|---------------------|---------|
| `GetResourceGroups` | `subscriptionId` | None | Lists all resource groups |
| `GetVirtualMachines` | `subscriptionId`, `resourceGroup` | None | Lists VMs in RG |
| `GetNetworkSecurityGroups` | `subscriptionId`, `resourceGroup` | None | Lists NSGs in RG |
| `GetStorageAccounts` | `subscriptionId`, `resourceGroup` | None | Lists storage in RG |
| `GetKeyVaults` | `subscriptionId`, `resourceGroup` | None | Lists key vaults in RG |
| `AddNSGDenyRule` | `subscriptionId`, `resourceGroup`, `nsgName`, `sourceIP` | None | Blocks IP in NSG |
| `StopVM` | `subscriptionId`, `resourceGroup`, `vmName` | None | Deallocates VM |
| `DisableStoragePublicAccess` | `subscriptionId`, `resourceGroup`, `storageAccountName` | None | Disables public access |
| `RemoveVMPublicIP` | `subscriptionId`, `resourceGroup`, `vmName` | None | Removes public IP |

**Workbook Implementation**:
```json
{
  "service": "AZURE",
  "action": "GetResourceGroups",
  "tenantId": "{tenantId}",
  "subscriptionId": "80110e3c-3ec4-4567-b06d-7d47a72562f5"
}

// For resource group operations:
{
  "service": "AZURE",
  "action": "GetVirtualMachines",
  "tenantId": "{tenantId}",
  "subscriptionId": "80110e3c-3ec4-4567-b06d-7d47a72562f5",
  "resourceGroup": "prod-resources"
}
```

---

## 📊 WORKBOOK PARAMETER PASSING PATTERNS

### Pattern 1: No Additional Parameters (Simple)
```json
{
  "service": "MDE",
  "action": "GetAllDevices",
  "tenantId": "{tenantId}"
}
```

### Pattern 2: Subscription-Scoped Operations
```json
{
  "service": "MDC",
  "action": "GetSecurityAlerts",
  "tenantId": "{tenantId}",
  "subscriptionId": "{subscriptionId}"  // From workbook parameter
}
```

### Pattern 3: User-Scoped Operations
```json
{
  "service": "ENTRAID",
  "action": "DisableUser",
  "tenantId": "{tenantId}",
  "userId": "{UserPrincipalName}"  // From selected row or input
}
```

### Pattern 4: Device-Scoped Operations
```json
{
  "service": "INTUNE",
  "action": "RemoteLock",
  "tenantId": "{tenantId}",
  "deviceId": "{IntuneDeviceId}"  // From selected row
}
```

### Pattern 5: Query-Based Operations
```json
{
  "service": "MDE",
  "action": "AdvancedHunt",
  "tenantId": "{tenantId}",
  "query": "{KQLQuery}"  // From workbook parameter or text box
}
```

### Pattern 6: Multi-Parameter Operations
```json
{
  "service": "AZURE",
  "action": "AddNSGDenyRule",
  "tenantId": "{tenantId}",
  "subscriptionId": "{subscriptionId}",
  "resourceGroup": "{resourceGroup}",
  "nsgName": "{nsgName}",
  "sourceIP": "{maliciousIP}"
}
```

---

## 🎯 WORKBOOK PARAMETER DEFINITIONS

### Global Parameters (Required for ALL queries)

```json
{
  "name": "tenantId",
  "type": "string",
  "label": "Tenant ID",
  "defaultValue": "",
  "required": true
}
```

### Service-Specific Parameters

```json
// For MDC and Azure services
{
  "name": "subscriptionId",
  "type": "string",
  "label": "Azure Subscription ID",
  "defaultValue": "",
  "required": false,
  "description": "Required for MDC and Azure operations"
}

// For EntraID user operations
{
  "name": "userId",
  "type": "string",
  "label": "User ID (UPN or Object ID)",
  "defaultValue": "",
  "required": false,
  "description": "Required for user-specific actions"
}

// For Intune device operations
{
  "name": "deviceId",
  "type": "string",
  "label": "Device ID (Intune)",
  "defaultValue": "",
  "required": false,
  "description": "Required for device-specific actions"
}

// For Azure resource operations
{
  "name": "resourceGroup",
  "type": "string",
  "label": "Resource Group",
  "defaultValue": "",
  "required": false,
  "description": "Required for most Azure operations"
}
```

---

## ⚠️ IMPORTANT NOTES

### 1. **Function App is Agnostic**
- ❌ Does NOT use app settings for subscriptionId
- ✅ ALWAYS expects parameters from request body
- 🎯 Perfect for multi-tenant scenarios

### 2. **Workbook Responsibility**
- Workbook must collect ALL required parameters
- Use dropdowns for subscriptionId, resourceGroup
- Use selected row data for userId, deviceId, machineId
- Validate parameters before sending request

### 3. **Error Handling**
If required parameter missing, function returns:
```json
{
  "status": "error",
  "message": "Subscription ID required for MDC operations. Provide 'subscriptionId' parameter in request.",
  "correlationId": "..."
}
```

### 4. **Parameter Sources**
- **Static**: tenantId (from workbook parameter)
- **User Input**: subscriptionId, userId, query
- **Selected Row**: machineId, deviceId, alertId
- **Dropdown**: resourceGroup, nsgName, vmName

---

## 📚 REFERENCES

- ARM Template: `deployment/azuredeploy.json` (removed AZURE_SUBSCRIPTION_ID from app settings)
- Orchestrator: `functions/DefenderXDROrchestrator/run.ps1` (parameter extraction logic)
- Test Script: `deployment/test-all-services-complete.ps1` (example usage)

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Status**: ✅ Production Ready
