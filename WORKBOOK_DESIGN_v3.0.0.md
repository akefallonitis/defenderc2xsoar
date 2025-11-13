# DefenderXDR C2 XSOAR - v3.0.0 Workbook Design
**Document Version:** 3.0.0  
**Status:** Production Ready  
**Last Updated:** 2024-11-14

---

## Executive Summary

The v3.0.0 workbook implements an **incident/alert/entity-centric investigation and remediation console** with full multi-tenant Lighthouse support. It combines:
- **CustomEndpoint queries** for auto-refresh data (30-second intervals)
- **ARM Actions** for manual remediation operations
- **Console UI** for Live Response and Advanced Hunting
- **Lighthouse integration** for seamless multi-tenant operations

### Key Features Analysis from Reference Materials

From analyzing the reference workbooks, we've identified proven patterns:

**From Advanced Workbook Concepts.json:**
- Azure Resource Graph for dynamic resource dropdowns (Subscriptions → Workspaces → Resources)
- ARM Endpoint with JSONPath transformers for parsing responses
- Custom Endpoint for external data sources
- Conditional visibility based on parameter values
- Link items for tab navigation
- Parameter cascading (parent → child relationships)

**From Sentinel360 XDR Console:**
- Entity-centric tabs (IP, Account, Host, URL, FileHash)
- PowerShell remediation scripts embedded in markdown cells
- Location maps for geographic analysis
- Multi-tenant parameter selection (Subscriptions → Workspaces)
- Bearer token authentication pattern
- Tab-based navigation with conditional visibility

---

## Architecture Overview

### 1. **Parameter Layer** (Global State Management)

```json
{
  "parameters": [
    // === MULTI-TENANT LIGHTHOUSE ===
    {
      "name": "LighthouseTenantId",
      "type": "subscription",
      "description": "Azure Lighthouse delegated tenant",
      "multiSelect": false,
      "includeAll": false
    },
    {
      "name": "Subscription",
      "type": "resourceGraph",
      "query": "resources | where type =~ 'microsoft.operationalinsights/workspaces' | project subscriptionId | distinct subscriptionId",
      "crossComponentResources": ["{LighthouseTenantId}"]
    },
    {
      "name": "ResourceGroup",
      "type": "resourceGraph",
      "query": "resources | where subscriptionId == '{Subscription}' and type =~ 'microsoft.web/sites' | project resourceGroup | distinct resourceGroup",
      "crossComponentResources": ["{LighthouseTenantId}"]
    },
    {
      "name": "FunctionAppName",
      "type": "resourceGraph",
      "query": "resources | where resourceGroup == '{ResourceGroup}' and type =~ 'microsoft.web/sites' | project name, id",
      "crossComponentResources": ["{LighthouseTenantId}"]
    },
    
    // === INCIDENT/ALERT/ENTITY CONTEXT ===
    {
      "name": "SelectedIncidentId",
      "type": "text",
      "description": "Selected incident from table"
    },
    {
      "name": "SelectedAlertId",
      "type": "text",
      "description": "Selected alert from table"
    },
    {
      "name": "SelectedEntityId",
      "type": "text",
      "description": "Selected entity from table"
    },
    {
      "name": "SelectedEntityType",
      "type": "dropdown",
      "options": ["Device", "User", "File", "IP", "URL"]
    }
  ]
}
```

### 2. **Navigation Structure**

```
┌─────────────────────────────────────────────────────────────┐
│                    DEFENDERXDR C2 XSOAR                     │
│                         v3.0.0                              │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ [Dashboard] [Incidents] [Entities] [Workers] [Console]      │
└─────────────────────────────────────────────────────────────┘

┌───────── Dashboard Tab ─────────┐
├── Overview Metrics (tiles)
├── Incident Distribution (chart)
├── Alert Timeline (chart)
└── Quick Actions (ARM buttons)

┌───────── Incidents Tab ─────────┐
├── Incident Selector (CustomEndpoint, auto-refresh 30s)
├── Alert Details (conditional on incident)
├── Entity List (conditional on incident/alert)
└── Remediation Actions (ARM Actions)

┌───────── Entities Tab ──────────┐
├── Entity Type Selector (Device/User/File/IP/URL)
├── Entity Search (CustomEndpoint)
├── Entity Details (conditional on selection)
└── Entity-specific Actions (ARM Actions)

┌───────── Workers Tab ───────────┐
├── MDE Operations
├── MDO Operations
├── MDI Operations
├── Entra ID Operations
├── Intune Operations
├── Azure Operations
└── MCAS Operations

┌───────── Console Tab ───────────┐
├── Live Response Shell
│   ├── Session Selector
│   ├── Command Input
│   └── Output Display
└── Advanced Hunting
    ├── KQL Editor
    ├── Execute Button
    └── Results Grid
```

---

## 3. **Data Query Patterns**

### **CustomEndpoint Pattern** (Auto-Refresh Listing)

```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderXDRGateway",
  "headers": [
    {"name": "Content-Type", "value": "application/json"}
  ],
  "body": "{\"service\":\"MDE\",\"action\":\"GetDevices\",\"tenantId\":\"{LighthouseTenantId}\"}",
  "refreshConfig": {
    "enabled": true,
    "intervalSeconds": 30
  },
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [
          {"path": "$.id", "columnid": "DeviceId"},
          {"path": "$.computerDnsName", "columnid": "DeviceName"},
          {"path": "$.riskScore", "columnid": "RiskScore"},
          {"path": "$.healthStatus", "columnid": "HealthStatus"},
          {"path": "$.lastSeen", "columnid": "LastSeen"}
        ]
      }
    }
  ]
}
```

**CustomEndpoint Queries to Implement:**
- **MDE**: GetDevices, GetIncidents, GetAlerts, GetIndicators, GetLiveResponseSessions
- **MDO**: BulkEmailSearch, GetMailboxForwarders, GetThreatSubmissions
- **MDI**: GetAlerts, GetRiskyUsers, GetLateralMovementPaths
- **Entra ID**: GetRiskDetections, GetRiskyUsers, GetSignInLogs, GetAuditLogs
- **Intune**: GetManagedDevices, GetDeviceConfigurations
- **Azure**: GetVMs, GetNSGs, GetStorageAccounts
- **MCAS**: GetOAuthApps, GetUserAppConsents, GetCloudFiles

### **ARM Action Pattern** (Manual Operations)

```json
{
  "type": "LinkItem/1.0",
  "links": [
    {
      "linkTarget": "ArmAction",
      "linkLabel": "🔒 Isolate Device",
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/DefenderXDRGateway",
        "headers": [
          {"name": "Content-Type", "value": "application/json"}
        ],
        "body": "{\"service\":\"MDE\",\"action\":\"IsolateDevice\",\"tenantId\":\"{LighthouseTenantId}\",\"parameters\":{\"machineId\":\"{SelectedDeviceId}\",\"isolationType\":\"Full\",\"comment\":\"Isolated via Workbook\"}}",
        "httpMethod": "POST",
        "description": "# ⚠️ Device Isolation\n\nThis will **fully isolate** the selected device from the network.\n\n**Device:** {SelectedDeviceName}\n**Action:** Full network isolation\n\n⚠️ This operation is **irreversible** until manually unisolated.\n\n**Confirm to proceed.**"
      }
    }
  ]
}
```

**ARM Actions to Implement (High Priority):**

**MDE:**
- IsolateDevice, UnisolateDevice, RunAVScan, StopAndQuarantineFile, CollectInvestigationPackage
- RestrictCodeExecution, UnrestrictCodeExecution, RunScript (Live Response)

**MDO:**
- SoftDeleteEmails, HardDeleteEmails, RemoveMailForwardingRules, QuarantineEmail

**Entra ID:**
- DisableUser, ResetPassword, RevokeSessions, RemoveAdminRole, ConfirmCompromised

**Intune:**
- RemoteLock, WipeDevice, RetireDevice, SyncDevice, RebootDevice

**Azure:**
- StopVM, AddNSGDenyRule, DisableServicePrincipal, RevokeStorageAccountKeys

**MCAS:**
- RevokeOAuthPermissions, QuarantineCloudFile, UnsanctionApp

---

## 4. **Multi-Tenant Lighthouse Implementation**

### **Parameter Cascading Logic**

```javascript
// Step 1: Lighthouse Tenant Selection
LighthouseTenantId (from Azure delegated subscriptions)
  ↓
// Step 2: Subscription Query (filtered by tenant)
Subscription (Azure Resource Graph: subscriptionId | distinct)
  ↓
// Step 3: Resource Group Query (filtered by subscription)
ResourceGroup (Azure Resource Graph: where subscriptionId == '{Subscription}')
  ↓
// Step 4: Function App Query (filtered by resource group)
FunctionAppName (Azure Resource Graph: where resourceGroup == '{ResourceGroup}' and type =~ 'microsoft.web/sites')
  ↓
// Step 5: All operations pass tenantId parameter
{
  "tenantId": "{LighthouseTenantId}",
  "service": "MDE",
  "action": "GetDevices"
}
```

### **Cross-Tenant Authentication**

The Gateway function handles authentication:
```powershell
# Gateway automatically uses correct tenant context
$tenantId = $Request.Body.tenantId
$token = Get-MsalToken -TenantId $tenantId -Scopes "https://api.securitycenter.microsoft.com/.default"
```

---

## 5. **Console UI Design**

### **Live Response Console**

```
┌─────────────────────────────────────────────────────────────┐
│ 🖥️ Live Response Console                                    │
├─────────────────────────────────────────────────────────────┤
│ Device: [Dropdown: GetDevices] ⟳                            │
│ Session: [Dropdown: GetSessions for device] ⟳               │
├─────────────────────────────────────────────────────────────┤
│ Command:                                                    │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ > _                                                   │   │
│ └───────────────────────────────────────────────────────┘   │
│ [Execute Command] [Get File from Library] [Upload File]    │
├─────────────────────────────────────────────────────────────┤
│ Output:                                                     │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ [Auto-refresh output from GetSession API]            │   │
│ │                                                       │   │
│ └───────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│ Command History (last 10 commands):                        │
│ • processes                          [14:23:15]            │
│ • getfile "C:\temp\malware.exe"      [14:22:08]            │
│ • registry                           [14:20:45]            │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**
- Device dropdown: CustomEndpoint → GetDevices (auto-refresh 30s)
- Session dropdown: CustomEndpoint → GetSessions (filtered by device)
- Command input: Text parameter
- Execute: ARM Action → RunScript with command input
- Output: CustomEndpoint → GetSession (auto-refresh 5s during active session)
- History: Parse session data for last 10 commands

### **Advanced Hunting Console**

```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Advanced Hunting Console                                 │
├─────────────────────────────────────────────────────────────┤
│ KQL Query:                                                  │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ DeviceProcessEvents                                   │   │
│ │ | where Timestamp > ago(7d)                           │   │
│ │ | where ProcessCommandLine has "powershell"           │   │
│ │ | summarize count() by DeviceName                     │   │
│ └───────────────────────────────────────────────────────┘   │
│ [Run Query] [Save Query] [Load Template]                   │
├─────────────────────────────────────────────────────────────┤
│ Results:                                                    │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ DeviceName                    Count                   │   │
│ │ ─────────────────────────────────────────────         │   │
│ │ DESKTOP-ABC123                42                      │   │
│ │ LAPTOP-XYZ789                 28                      │   │
│ │ SERVER-DEF456                 156                     │   │
│ └───────────────────────────────────────────────────────┘   │
│ [Export to CSV] [Create Alert Rule]                        │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**
- KQL Editor: Multi-line text parameter
- Run Query: ARM Action → AdvancedHuntingRunQuery with KQL parameter
- Results: JSONPath transformer with dynamic columns from $.Schema
- Save Query: ARM Action → SaveQuery
- Templates: Dropdown parameter with pre-built queries

---

## 6. **File Operations Workaround**

Since workbooks don't support native file upload/download:

### **File Upload (Two-Step Process)**

```
Step 1: Upload to Storage Account
┌─────────────────────────────────────────────────────────────┐
│ 📁 File Upload (via Azure Portal)                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Navigate to Storage Account: {StorageAccountName}        │
│ 2. Container: liveresponse                                  │
│ 3. Upload your file to /library/ folder                     │
│ 4. Copy file path (e.g., library/forensics-tool.exe)        │
└─────────────────────────────────────────────────────────────┘

Step 2: Reference in PutFile Command
┌─────────────────────────────────────────────────────────────┐
│ File Path: [text input: library/forensics-tool.exe]         │
│ Target Path on Device: [text input: C:\temp\tool.exe]       │
│ [Execute PutFile Command]                                   │
└─────────────────────────────────────────────────────────────┘
```

### **File Download**

```
┌─────────────────────────────────────────────────────────────┐
│ 📥 File Download                                            │
├─────────────────────────────────────────────────────────────┤
│ 1. Execute GetFile command                                  │
│ 2. File is downloaded to Storage Account                    │
│ 3. Get download link: [ARM Action: GenerateSASToken]        │
│ 4. Click link to download: [Dynamic link display]           │
└─────────────────────────────────────────────────────────────┘
```

### **Library File Manager**

```
CustomEndpoint Query:
{
  "version": "AzureStorage/1.0",
  "accountName": "{StorageAccountName}",
  "container": "liveresponse",
  "prefix": "library/",
  "listFiles": true
}

Displays:
┌─────────────────────────────────────────────────────────────┐
│ 📚 File Library                                             │
├─────────────────────────────────────────────────────────────┤
│ File Name                    Size        Last Modified       │
│ ────────────────────────────────────────────────────────    │
│ forensics-tool.exe           2.3 MB      2024-11-14 14:30   │
│ malware-scanner.ps1          45 KB       2024-11-13 09:15   │
│ config-backup.xml            12 KB       2024-11-12 16:45   │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. **Conditional Visibility & Grouping**

### **Entity-Specific Action Visibility**

```json
{
  "conditionalVisibility": {
    "parameterName": "SelectedEntityType",
    "comparison": "isEqualTo",
    "value": "Device"
  }
}
```

**Example: Device Actions Only Show When Device Selected**

- IsolateDevice → visible only if SelectedEntityType == "Device"
- DisableUser → visible only if SelectedEntityType == "User"
- BlockIP → visible only if SelectedEntityType == "IP"

### **Nested Visibility (Parent-Child)**

```json
{
  "conditionalVisibility": {
    "parameterName": "SelectedIncidentId",
    "comparison": "isNotEqualTo",
    "value": ""
  }
}
```

**Example: Alert Details Only Show When Incident Selected**

### **Advanced Grouping**

```
┌─────────────────────────────────────────────────────────────┐
│ ▼ Device Operations (Collapsible Group)                     │
│   ├── 🔒 Isolation                                          │
│   │   ├── Isolate Device                                    │
│   │   └── Unisolate Device                                  │
│   ├── 🦠 Antivirus                                          │
│   │   ├── Run Quick Scan                                    │
│   │   └── Run Full Scan                                     │
│   └── 📦 Investigation                                      │
│       ├── Collect Investigation Package                     │
│       └── Run Script                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. **Implementation Checklist**

### **Phase 1: Foundation** (2 hours)
- [x] Multi-tenant parameter layer (Lighthouse → Subscription → RG → FunctionApp)
- [ ] Tab navigation structure
- [ ] Global parameter state management

### **Phase 2: Dashboard & Incidents** (2 hours)
- [ ] Overview metrics tiles
- [ ] Incident list (CustomEndpoint: GetIncidents, auto-refresh 30s)
- [ ] Alert details (conditional on incident selection)
- [ ] Entity list (conditional on incident/alert)

### **Phase 3: Entity Investigation** (2 hours)
- [ ] Entity type tabs (Device/User/IP/File/URL)
- [ ] Entity search (CustomEndpoint per type)
- [ ] Entity details display (conditional visibility)
- [ ] Entity-specific actions (ARM Actions)

### **Phase 4: Worker Operations** (3 hours)
- [ ] MDE tab (63 actions)
- [ ] MDO tab (16 actions)
- [ ] MDI tab (11 actions)
- [ ] Entra ID tab (20 actions)
- [ ] Intune tab (18 actions)
- [ ] Azure tab (23 actions)
- [ ] MCAS tab (15 actions)

### **Phase 5: Console** (2 hours)
- [ ] Live Response shell UI
- [ ] Command input and execution
- [ ] Output auto-refresh
- [ ] Advanced Hunting KQL editor
- [ ] Query execution and results display

### **Phase 6: File Operations** (1 hour)
- [ ] File library browser (Storage Account)
- [ ] Upload instructions
- [ ] Download link generation

### **Phase 7: Polish** (1 hour)
- [ ] Conditional visibility refinement
- [ ] Help text and tooltips
- [ ] Styling and spacing
- [ ] Testing across scenarios

---

## 9. **Success Metrics**

- ✅ Auto-refresh works for all CustomEndpoint queries (30s interval)
- ✅ ARM Actions execute successfully with confirmation dialogs
- ✅ Multi-tenant switching works seamlessly (Lighthouse)
- ✅ Conditional visibility shows/hides sections correctly
- ✅ Console commands execute and display output
- ✅ File operations have clear workaround instructions
- ✅ All 166 worker actions are accessible via UI

---

## 10. **Next Steps**

1. Create workbook JSON file (DefenderXDR-v3.0.0.workbook)
2. Implement parameter layer and navigation
3. Build CustomEndpoint queries for each worker
4. Implement ARM Actions for high-priority operations
5. Create console UI sections
6. Test multi-tenant operations
7. Add to ARM template as base64 resource

**Estimated Total Time:** 13 hours
**Priority:** Critical (blocking v3.0.0 release)
