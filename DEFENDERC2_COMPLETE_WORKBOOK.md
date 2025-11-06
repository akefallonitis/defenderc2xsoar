# 🛡️ DefenderC2 Complete Workbook - Full Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Features by Module](#features-by-module)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Function App Integration](#function-app-integration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## 🎯 Overview

The **DefenderC2 Complete Workbook** is a comprehensive command and control interface for Microsoft Defender XDR operations, built entirely within Azure Workbooks. It provides a unified console for device management, threat hunting, incident response, and threat intelligence operations without requiring any external web applications.

### ✨ Key Capabilities

- **🖥️ Device Management** - Full device control with ARM actions
- **🎮 Live Response Console** - Interactive command execution on endpoints
- **📚 File Library** - Azure Storage-backed file management
- **🔍 Advanced Hunting** - KQL query console with templates
- **🛡️ Threat Intelligence** - IOC management (files, IPs, URLs, domains)
- **🚨 Incident Management** - Security incident tracking
- **🎯 Custom Detections** - Detection rule management
- **📊 Dashboard** - Real-time operational overview

### 🎨 Design Principles

1. **CustomEndpoint for Listing** - All data retrieval operations use CustomEndpoint queries with auto-refresh support
2. **ARM Actions for Execution** - All control operations use ARM invocation endpoints for proper RBAC enforcement
3. **Conditional Visibility** - Each module is isolated with tab-based navigation
4. **Auto-population** - Smart defaults and parameter passing between components
5. **Console-like UX** - Terminal-style interfaces for security operations

---

## 🏗️ Architecture

### Function Apps Mapping

The workbook integrates with 6 Azure Function Apps:

| Function App | Purpose | Operations | Query Type |
|--------------|---------|------------|------------|
| **DefenderC2Dispatcher** | Device Management | Get devices, isolate, scan, restrict, quarantine | CustomEndpoint (list), ARM (actions) |
| **DefenderC2Orchestrator** | Live Response & Library | Execute commands, upload/download files, manage sessions | CustomEndpoint (list), ARM (actions) |
| **DefenderC2HuntManager** | Advanced Hunting | Execute KQL queries across Defender XDR | ARM (execute) |
| **DefenderC2TIManager** | Threat Intelligence | Manage file/IP/URL/domain indicators | CustomEndpoint (list), ARM (add/remove) |
| **DefenderC2IncidentManager** | Incident Management | View and update security incidents | CustomEndpoint (list/get) |
| **DefenderC2CDManager** | Custom Detections | Create and manage detection rules | CustomEndpoint (list), ARM (create) |

### Data Flow

```
┌─────────────────────┐
│  Azure Workbook     │
│  (User Interface)   │
└──────────┬──────────┘
           │
           ├─── CustomEndpoint ──→ Function App ──→ Defender XDR API
           │    (Auto-refresh)       (Read ops)      (GET requests)
           │
           └─── ARM Actions ────→ Function App ──→ Defender XDR API
                (Manual confirm)    (Write ops)     (POST requests)
```

### Authentication Flow

```
User → Azure Workbook → ARM/CustomEndpoint → Function App
                                                  ↓
                                            App Registration
                                         (Client ID + Secret)
                                                  ↓
                                            Azure AD Token
                                                  ↓
                                         Defender XDR API
```

---

## 🎪 Features by Module

### 📊 Dashboard Module

**Purpose:** Real-time operational overview and quick access

**Features:**
- Device fleet health metrics (tiles)
- Recent action summary (tiles)
- Top 10 devices by risk (table with filtering)
- Auto-refresh support (configurable interval)

**CustomEndpoint Queries:**
- `Get Devices` - All devices with health/risk/exposure
- `Get All Actions` - Recent machine actions

**Use Cases:**
- Morning security briefings
- Quick status checks during incidents
- Executive dashboards

---

### 🖥️ Device Management Module

**Purpose:** Complete device lifecycle management

**Features:**
- **Device Inventory** - Full device list with selection
- **Conflict Detection** - Warns about pending actions
- **ARM Actions** - Execute with Azure confirmation
  - 🔍 Run Antivirus Scan
  - 🔒 Isolate Device (network isolation)
  - 🔓 Unisolate Device
  - 📦 Collect Investigation Package
  - 🚫 Restrict App Execution
  - ✅ Unrestrict App Execution
  - 🦠 Stop & Quarantine File (by hash)
- **Action Monitoring** - Real-time tracking with auto-refresh
- **Smart Filtering** - Auto-filters by selected devices

**CustomEndpoint Queries:**
- `Get Devices` - Device inventory
- `Get All Actions` - Conflict detection and monitoring

**ARM Actions:**
- All device operations route through `DefenderC2Dispatcher`

**Workflow:**
1. Select devices from inventory (click ✅ Select)
2. Review conflict detection (pending actions)
3. Choose and execute ARM action (Azure confirmation)
4. Monitor in real-time (action history with auto-refresh)

**Parameters:**
- `DeviceList` - Comma-separated device IDs (auto-populated)
- `FileHash` - SHA1 hash for quarantine operations

---

### 🎮 Live Response Console Module

**Purpose:** Interactive command execution on remote devices

**Features:**
- **Device Selection** - Choose target for Live Response
- **Library Script Execution** - Run pre-uploaded PowerShell scripts
- **File Download** - Retrieve files from devices
- **File Upload** - Deploy files to devices
- **Session Management** - View active Live Response sessions

**CustomEndpoint Queries:**
- `Get Devices` - Device selection
- `GetLiveResponseSessions` - Active sessions with auto-refresh

**ARM Actions:**
- `InvokeLiveResponseScript` - Execute script from library
- `GetLiveResponseFile` - Download file from device
- `PutLiveResponseFile` - Upload file to device (requires Base64)

**Workflow - Execute Script:**
1. Select target device
2. Enter script name from library
3. Execute ARM action (creates session, runs script)
4. Monitor session status

**Workflow - Download File:**
1. Select target device
2. Enter full file path (e.g., `C:\temp\file.txt`)
3. Execute ARM action
4. Response contains Base64-encoded file content

**Parameters:**
- `LRDeviceId` - Target device ID
- `LRScript` - Script name from library
- `LRFilePath` - Full path to file on device
- `LRCommand` - Command to execute (future feature)

**Limitations:**
- File upload requires Base64-encoded content
- Large files may time out
- Sessions have 10-minute timeout

---

### 📚 File Library Module

**Purpose:** Manage files for Live Response operations using Azure Storage

**Features:**
- **File Listing** - All files in Azure Storage library container
- **File Download** - Retrieve files with Base64 encoding
- **File Delete** - Remove files from library
- **Storage Integration** - Backed by Azure Blob Storage

**CustomEndpoint Queries:**
- `ListLibraryFiles` - All files with metadata (auto-refresh)

**ARM Actions:**
- `GetLibraryFile` - Download file (returns Base64)
- `DeleteLibraryFile` - Delete file from library
- `UploadToLibrary` - Upload file (requires Base64 content)

**File Metadata:**
- FileName
- Size (bytes)
- LastModified (ISO 8601)
- ContentType (MIME)
- ETag

**Workflow - Download File:**
1. Select file from list
2. Execute download ARM action
3. Response contains Base64-encoded file content
4. Decode Base64 to retrieve original file

**Workflow - Delete File:**
1. Select file from list
2. Execute delete ARM action (confirmation dialog)
3. File permanently removed

**Azure Storage Structure:**
```
Storage Account: (Function App's AzureWebJobsStorage)
Container: library
Files: stored as blobs with original filenames
```

**Supported Operations:**
- List files (read-only query)
- Download files (Base64 encoded)
- Delete files (permanent)
- Upload files (requires external tool for Base64 encoding)

---

### 🔍 Advanced Hunting Module

**Purpose:** KQL query console for threat hunting across Defender XDR

**Features:**
- **Query Editor** - Multi-line KQL query input
- **Query Templates** - Pre-built queries for common scenarios
- **Execute ARM Action** - Run queries with Azure confirmation
- **Hunt Naming** - Descriptive names for query tracking

**ARM Actions:**
- `ExecuteHunt` - Runs KQL query, returns up to 1000 results

**Query Templates:**

**Device Queries:**
```kql
-- Device Summary
DeviceInfo
| where Timestamp > ago(7d)
| summarize Count=count() by DeviceName, OSPlatform
| top 10 by Count

-- PowerShell Activity
DeviceProcessEvents
| where Timestamp > ago(1d)
| where ProcessCommandLine has 'powershell'
| take 100

-- Public Network Connections
DeviceNetworkEvents
| where Timestamp > ago(1d)
| where RemoteIPType == 'Public'
| take 100
```

**Security Queries:**
```kql
-- Alerts by Severity
AlertInfo
| where Timestamp > ago(7d)
| summarize Count=count() by Severity
| order by Count desc

-- Phishing Emails
EmailEvents
| where Timestamp > ago(7d)
| where ThreatTypes has 'Phish'
| take 100

-- Failed Logons
IdentityLogonEvents
| where Timestamp > ago(1d)
| where ActionType == 'LogonFailed'
| take 100
```

**Available Tables:**
- Device: `DeviceInfo`, `DeviceProcessEvents`, `DeviceNetworkEvents`, `DeviceFileEvents`, `DeviceLogonEvents`
- Alerts: `AlertInfo`, `AlertEvidence`
- Email: `EmailEvents`, `EmailAttachmentInfo`, `EmailUrlInfo`
- Identity: `IdentityLogonEvents`, `IdentityQueryEvents`, `IdentityDirectoryEvents`
- Cloud: `CloudAppEvents`

**Workflow:**
1. Enter or select KQL query
2. Give hunt a descriptive name
3. Execute ARM action (Azure confirmation)
4. Review results in response (up to 1000 rows)

**Parameters:**
- `HuntQuery` - Multi-line KQL query
- `HuntName` - Descriptive name for tracking

**Best Practices:**
- Use time filters (`ago(7d)`) to limit data
- Use `take` or `top` to limit results
- Test queries in Defender portal first
- Save successful queries externally

---

### 🛡️ Threat Intelligence Module

**Purpose:** Manage indicators of compromise (IOCs)

**Features:**
- **IOC Listing** - All indicators with filtering (auto-refresh)
- **Add Indicators** - File hashes, IPs, URLs, domains
- **Multi-indicator Support** - Comma-separated values
- **Action Configuration** - Alert, Block, or Allow
- **Severity Assignment** - Informational, Low, Medium, High

**CustomEndpoint Queries:**
- `List All Indicators` - All IOCs with metadata

**ARM Actions:**
- `Add File Indicators` - Add file hash IOCs (SHA256)
- `Add IP Indicators` - Add IP address IOCs
- `Add URL/Domain Indicators` - Add URL/domain IOCs
- `Remove File Indicators` - Remove indicators by ID
- `Remove IP Indicators` - Remove indicators by ID
- `Remove URL/Domain Indicators` - Remove indicators by ID

**Indicator Types:**

| Type | Format | Example |
|------|--------|---------|
| **File Hash** | SHA256 (64 chars) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| **IP Address** | IPv4 or IPv6 | `192.168.1.100`, `2001:db8::1` |
| **URL** | Full URL | `https://malicious.com/path` |
| **Domain** | FQDN | `malicious.com` |

**Recommended Actions:**
- **Alert** - Generate alert when matched
- **Block** - Block and generate alert
- **Allow** - Explicitly allow (whitelist)

**Severity Levels:**
- **Informational** - Low impact, tracking only
- **Low** - Minor threat
- **Medium** - Moderate threat
- **High** - Critical threat

**Workflow - Add Indicator:**
1. Select indicator type (File, IP, URL)
2. Enter indicator value (can be comma-separated for multiple)
3. Enter title/description
4. Select severity and action
5. Execute appropriate ARM action

**Workflow - Bulk Add:**
```
Indicator Value: hash1,hash2,hash3,hash4
Title: Malware Campaign X IOCs
Severity: High
Action: Block
→ Executes: Add File Indicators
```

**Parameters:**
- `TIType` - Indicator type selector
- `TIValue` - Indicator value(s), comma-separated
- `TITitle` - Indicator title/description
- `TISeverity` - Informational, Low, Medium, High
- `TIAction` - Alert, Block, Allow

**Integration:**
- Indicators apply across all Defender XDR
- Matches generate alerts based on action
- Block actions prevent execution/access
- Synchronized with Microsoft Threat Intelligence

---

### 🚨 Incident Management Module

**Purpose:** View and manage security incidents from Defender XDR

**Features:**
- **Incident Listing** - All incidents with filtering (auto-refresh)
- **Severity Filter** - Informational, Low, Medium, High
- **Status Filter** - Active, Resolved, InProgress
- **Incident Details** - Full incident metadata

**CustomEndpoint Queries:**
- `GetIncidents` - All incidents with optional filters

**Incident Fields:**
- **IncidentID** - Unique identifier
- **Name** - Incident title
- **Severity** - Informational, Low, Medium, High
- **Status** - Active, Resolved, InProgress, Redirected
- **Classification** - TruePositive, FalsePositive, BenignPositive
- **Created** - ISO 8601 timestamp

**Filters:**

**Severity:**
- All Severities (default)
- Informational - Low-priority events
- Low - Minor security issues
- Medium - Moderate threats
- High - Critical incidents

**Status:**
- All Statuses (default)
- Active - New, unassigned incidents
- InProgress - Under investigation
- Resolved - Closed incidents

**Workflow - Triage:**
1. Set severity filter to "High"
2. Set status filter to "Active"
3. Review high-priority, unhandled incidents
4. Investigate in Defender portal

**Workflow - Monitoring:**
1. Leave filters on "All"
2. Enable auto-refresh (30 seconds)
3. Monitor for new high-severity incidents
4. Quick triage directly from workbook

**Parameters:**
- `IncidentSeverity` - Filter dropdown
- `IncidentStatus` - Filter dropdown

**Future Enhancements:**
- Update incident status (ARM action)
- Assign incidents (ARM action)
- Add comments (ARM action)
- Link to Defender portal

---

### 🎯 Custom Detections Module

**Purpose:** Create and manage custom detection rules

**Features:**
- **Detection Listing** - All rules with status (auto-refresh)
- **Create Rules** - New detection with KQL query
- **Rule Management** - Enable/disable, update, delete
- **Sample Queries** - Pre-built detection templates

**CustomEndpoint Queries:**
- `List All Detections` - All custom detection rules

**ARM Actions:**
- `Create Detection` - New detection rule with KQL
- `Update Detection` - Modify existing rule (future)
- `Delete Detection` - Remove rule (future)

**Detection Fields:**
- **RuleID** - Unique identifier
- **Name** - Detection rule name
- **Severity** - Informational, Low, Medium, High
- **Enabled** - true/false
- **CreatedBy** - UPN of creator
- **Query** - KQL detection logic

**Sample Detection Queries:**

**Suspicious PowerShell:**
```kql
DeviceProcessEvents
| where Timestamp > ago(1h)
| where ProcessCommandLine has_any ('bypass', 'encodedcommand', 'invoke-expression')
| where InitiatingProcessFileName !in ('explorer.exe', 'services.exe')
```

**Unusual Network Connections:**
```kql
DeviceNetworkEvents
| where Timestamp > ago(1h)
| where RemoteIPType == 'Public'
| where RemotePort in (4444, 5555, 6666, 7777, 8888)
```

**Credential Access:**
```kql
DeviceProcessEvents
| where Timestamp > ago(1h)
| where ProcessCommandLine has_any ('mimikatz', 'sekurlsa', 'lsadump')
```

**Workflow - Create Detection:**
1. Enter detection name (e.g., "Suspicious PowerShell Bypass")
2. Paste KQL query (see samples)
3. Select severity (usually Medium or High)
4. Execute ARM action (Azure confirmation)
5. Rule immediately active in Defender XDR

**Best Practices:**
- Test queries in Advanced Hunting first
- Use time windows (`ago(1h)`) to prevent backfill
- Include `where` clauses to reduce false positives
- Start with informational severity for tuning
- Document detections externally

**Parameters:**
- `DetectionName` - Rule name
- `DetectionQuery` - KQL detection logic
- `DetectionSeverity` - Severity level

---

## 🚀 Installation

### Prerequisites

1. **Azure Subscription** with:
   - Microsoft Sentinel (optional, for workspace)
   - Azure Workbooks access
   - Function App deployment permissions

2. **Defender XDR** with:
   - Active licenses (E5 or Defender for Endpoint P2)
   - Global Administrator or Security Administrator role

3. **App Registration** in Azure AD with:
   - Client ID and Secret
   - API Permissions (see below)

### Required API Permissions

Configure your App Registration with these Microsoft Defender API permissions (Application type):

```
Machine.Isolate
Machine.RestrictExecution
Machine.Scan
Machine.CollectForensics
Machine.StopAndQuarantine
Machine.Read.All
Machine.ReadWrite.All
Ti.ReadWrite.All
AdvancedQuery.Read.All
SecurityIncident.Read.All
SecurityIncident.ReadWrite.All
CustomDetections.ReadWrite.All
```

**Grant admin consent** for all permissions.

### Deploy Function Apps

1. **Clone Repository:**
   ```powershell
   git clone https://github.com/akefallonitis/defenderc2xsoar.git
   cd defenderc2xsoar
   ```

2. **Deploy via ARM Template:**
   ```powershell
   cd deployment
   .\deploy-all.ps1
   ```

   Or manually:
   ```powershell
   # Deploy ARM template
   az deployment group create \
     --resource-group YOUR-RG \
     --template-file azuredeploy.json \
     --parameters @azuredeploy.parameters.json
   ```

3. **Configure Function App Settings:**
   ```powershell
   # Set environment variables
   az functionapp config appsettings set \
     --name YOUR-FUNCTION-APP \
     --resource-group YOUR-RG \
     --settings \
       APPID="your-app-id" \
       SECRETID="your-client-secret"
   ```

### Deploy Workbook

**Method 1: Azure Portal**

1. Navigate to **Azure Portal → Workbooks**
2. Click **+ New**
3. Click **Advanced Editor** (</> icon in toolbar)
4. Paste contents of `workbook/DefenderC2-Complete.json`
5. Click **Apply**
6. Update `fallbackResourceIds` with your subscription/resource group
7. Click **Save** → Choose name, location, resource group

**Method 2: ARM Template**

1. Use `deployment/workbook-deploy.json`:
   ```powershell
   az deployment group create \
     --resource-group YOUR-RG \
     --template-file workbook-deploy.json \
     --parameters workbookDisplayName="DefenderC2 Complete"
   ```

**Method 3: PowerShell Script**

```powershell
# Use deployment script
.\deployment\deploy-workbook.ps1 `
  -ResourceGroupName "YOUR-RG" `
  -WorkbookName "DefenderC2-Complete" `
  -Location "eastus"
```

---

## ⚙️ Configuration

### Update Fallback Resource IDs

In the workbook JSON, find and update:

```json
"fallbackResourceIds": [
  "/subscriptions/YOUR-SUBSCRIPTION-ID/resourcegroups/YOUR-RESOURCE-GROUP"
]
```

Replace with your actual subscription ID and resource group.

### Configure Parameters

After deployment, the workbook will prompt for:

1. **Function App** - Select your DefenderC2 function app
2. **Tenant ID** - Your Defender XDR tenant ID
3. **Auto Refresh** - Choose refresh interval (default: 30 seconds)

These are saved in workbook parameters and persist across sessions.

### Set Default Tenant

To pre-populate tenant ID, modify the `TenantId` parameter value:

```json
{
  "id": "tid",
  "name": "TenantId",
  "value": "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"  // ← Your tenant ID
}
```

### Configure Auto-Refresh

Default is 30 seconds. To change:

```json
{
  "id": "ref",
  "name": "AutoRefresh",
  "value": "30000"  // ← Milliseconds (30000 = 30s)
}
```

Options:
- `0` - Off
- `30000` - 30 seconds
- `60000` - 1 minute
- `300000` - 5 minutes

---

## 📖 Usage Guide

### Quick Start Workflow

1. **Open Workbook** in Azure Portal
2. **Select Function App** from dropdown (required)
3. **Select Tenant** from dropdown (auto-populated)
4. **Choose Module** from tab selector
5. **Execute Operations** using ARM actions or view data

### Common Scenarios

#### Scenario 1: Isolate Compromised Device

```
1. Go to: 🖥️ Device Management
2. Select device from inventory
3. Check conflict detection (pending actions)
4. Click: 🔒 Isolate Device
5. Confirm in Azure dialog
6. Monitor in action history
```

#### Scenario 2: Hunt for Suspicious Activity

```
1. Go to: 🔍 Advanced Hunting
2. Enter KQL query or use template
3. Name your hunt
4. Click: 🔍 Execute Advanced Hunting Query
5. Confirm in Azure dialog
6. Review results in response
```

#### Scenario 3: Block Malicious File

```
1. Go to: 🖥️ Device Management
2. Enter file hash (SHA1) in FileHash parameter
3. Click: 🦠 Stop & Quarantine File
4. Confirm in Azure dialog
5. File blocked across all devices
```

#### Scenario 4: Deploy File via Live Response

```
1. Go to: 📚 File Library
2. Verify file exists in library
3. Go to: 🎮 Live Response Console
4. Select target device
5. Enter file name
6. Click: 📤 Put File to Device
7. Confirm in Azure dialog
```

#### Scenario 5: Create Detection Rule

```
1. Go to: 🎯 Custom Detections
2. Review sample queries
3. Enter detection name
4. Paste KQL query
5. Select severity
6. Click: ➕ Create Detection Rule
7. Confirm in Azure dialog
```

### Parameter Management

**Global Parameters** (available in all modules):
- `FunctionApp` - Function app resource
- `Subscription` - Auto-populated from Function App
- `ResourceGroup` - Auto-populated from Function App
- `FunctionAppName` - Auto-populated from Function App
- `TenantId` - Defender XDR tenant
- `AutoRefresh` - Refresh interval for CustomEndpoint queries

**Module-Specific Parameters:**

| Module | Parameters | Purpose |
|--------|-----------|---------|
| Devices | `DeviceList`, `FileHash` | Device selection, file quarantine |
| Live Response | `LRDeviceId`, `LRScript`, `LRFilePath` | Target device, script, file operations |
| Library | `LibraryFileName` | File selection |
| Hunting | `HuntQuery`, `HuntName` | KQL query, hunt tracking |
| Threat Intel | `TIType`, `TIValue`, `TITitle`, `TISeverity`, `TIAction` | IOC management |
| Incidents | `IncidentSeverity`, `IncidentStatus` | Filtering |
| Detections | `DetectionName`, `DetectionQuery`, `DetectionSeverity` | Rule creation |

### Auto-Refresh Behavior

**Modules with Auto-Refresh:**
- Dashboard (device health, recent actions)
- Device Management (device inventory, pending actions, action history)
- Live Response (active sessions)
- File Library (file list)
- Threat Intelligence (indicator list)
- Incidents (incident list)
- Custom Detections (detection rules)

**Modules without Auto-Refresh:**
- Advanced Hunting (manual execution only)
- All ARM actions (manual trigger only)

**Recommendation:**
- Active incident response: 10-30 seconds
- Normal monitoring: 30-60 seconds
- Background monitoring: 5 minutes
- Resource conservation: Off

---

## 🔧 Function App Integration

### API Endpoints

**DefenderC2Dispatcher:**
```
GET  /api/DefenderC2Dispatcher?action=Get Devices&tenantId={tenantId}
POST /api/DefenderC2Dispatcher?action=Isolate Device&tenantId={tenantId}&deviceIds={ids}
POST /api/DefenderC2Dispatcher?action=Run Antivirus Scan&tenantId={tenantId}&deviceIds={ids}
```

**DefenderC2Orchestrator:**
```
GET  /api/DefenderC2Orchestrator?Function=GetLiveResponseSessions&tenantId={tenantId}
POST /api/DefenderC2Orchestrator?Function=InvokeLiveResponseScript&tenantId={tenantId}&DeviceIds={id}&scriptName={name}
GET  /api/DefenderC2Orchestrator?Function=ListLibraryFiles&tenantId={tenantId}
```

**DefenderC2HuntManager:**
```
POST /api/DefenderC2HuntManager?action=ExecuteHunt&tenantId={tenantId}&huntQuery={kql}&huntName={name}
```

**DefenderC2TIManager:**
```
GET  /api/DefenderC2TIManager?action=List All Indicators&tenantId={tenantId}
POST /api/DefenderC2TIManager?action=Add File Indicators&tenantId={tenantId}&indicators={hashes}
```

**DefenderC2IncidentManager:**
```
GET  /api/DefenderC2IncidentManager?action=GetIncidents&tenantId={tenantId}&severity={sev}&status={status}
```

**DefenderC2CDManager:**
```
GET  /api/DefenderC2CDManager?action=List All Detections&tenantId={tenantId}
POST /api/DefenderC2CDManager?action=Create Detection&tenantId={tenantId}&detectionName={name}&detectionQuery={kql}
```

### ARM Invocation Paths

All ARM actions use this pattern:
```
POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Web/sites/{functionApp}/functions/{functionName}/invocations?api-version=2022-03-01
```

Example:
```
POST /subscriptions/abc-123/resourceGroups/rg-defender/providers/Microsoft.Web/sites/defenderc2/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01&action=Isolate Device&tenantId=xyz-789&deviceIds=device-123
```

### Response Formats

**Success Response:**
```json
{
  "status": "Success",
  "action": "Isolate Device",
  "tenantId": "xyz-789",
  "details": "Device isolation initiated for 1 device(s)",
  "actionIds": ["action-abc-123"],
  "timestamp": "2025-11-05T12:34:56.789Z"
}
```

**Error Response:**
```json
{
  "error": "Missing required parameters: deviceIds",
  "status": "BadRequest"
}
```

### Rate Limiting

**Defender XDR API Limits:**
- 45 calls per minute per tenant
- 1500 calls per hour per tenant

**Function App Handles:**
- Automatic retry with exponential backoff
- Rate limit detection (HTTP 429)
- Retry-After header parsing

**Best Practices:**
- Use auto-refresh wisely (30-60 seconds recommended)
- Avoid simultaneous operations on many devices
- Monitor function app logs for rate limit errors

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "Function App not found" or Empty Dropdown

**Cause:** Resource Graph query not returning results

**Solution:**
```
1. Verify you have Reader role on subscription
2. Confirm function app exists and is running
3. Check function app has kind='functionapp'
4. Refresh workbook page
```

#### 2. "Missing required parameters: tenantId"

**Cause:** Tenant parameter not populated

**Solution:**
```
1. Select Function App first (required)
2. Wait 2-3 seconds for auto-population
3. Manually select tenant from dropdown
4. Verify dropdown shows "Tenant: {id}"
```

#### 3. ARM Action Shows "Forbidden" or "Unauthorized"

**Cause:** Insufficient RBAC permissions

**Solution:**
```
1. Verify you have Microsoft.Web/sites/functions/invoke/action permission
2. Check you have Contributor or higher on Function App
3. Confirm App Registration has required API permissions
4. Verify admin consent granted
```

#### 4. CustomEndpoint Query Returns Empty

**Cause:** Function app not responding or authentication failure

**Solution:**
```
1. Check function app is running (not stopped)
2. Verify APPID and SECRETID environment variables set
3. Test function app directly:
   curl "https://{app}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get Devices&tenantId={id}"
4. Check function app logs in Azure Portal
```

#### 5. Auto-Refresh Not Working

**Cause:** TimeContext not configured or refresh disabled

**Solution:**
```
1. Set AutoRefresh parameter to non-zero value
2. Verify query has timeContext property
3. Check timeContextFromParameter: "AutoRefresh"
4. Refresh workbook page
```

#### 6. Device Selection Not Working

**Cause:** Parameter value formatting issue

**Solution:**
```
1. Clear DeviceList parameter manually
2. Click Select on one device to test
3. Verify parameter shows comma-separated IDs
4. Check for trailing commas
```

#### 7. Live Response Session Timeout

**Cause:** Session expires after 10 minutes of inactivity

**Solution:**
```
1. Execute commands promptly after session creation
2. Monitor session status in Active Sessions
3. Create new session if timeout occurs
4. Consider automating multi-step operations
```

#### 8. File Library Operations Fail

**Cause:** Azure Storage not configured or container missing

**Solution:**
```
1. Verify AzureWebJobsStorage configured in function app
2. Check 'library' container exists in storage account
3. Confirm function app has storage permissions
4. Review function app logs for storage errors
```

### Debug Mode

**Enable Detailed Logging:**

1. **Browser DevTools:**
   ```
   F12 → Network tab → Execute operation → Inspect request/response
   ```

2. **Function App Logs:**
   ```
   Azure Portal → Function App → Log stream
   ```

3. **Application Insights:**
   ```
   Azure Portal → Application Insights → Logs
   query: traces | where severityLevel >= 2
   ```

### Validation Checklist

Before opening a support ticket:

- [ ] Function app is running (green in portal)
- [ ] APPID and SECRETID environment variables set
- [ ] App Registration has required API permissions
- [ ] Admin consent granted for API permissions
- [ ] You have RBAC permissions on function app
- [ ] TenantId parameter is populated
- [ ] FunctionApp parameter is selected
- [ ] Tested function app directly with curl
- [ ] Reviewed function app logs
- [ ] Cleared browser cache
- [ ] Tested in incognito/private mode

---

## ✅ Best Practices

### Security

1. **RBAC Enforcement**
   - Use ARM actions (not CustomEndpoint) for write operations
   - Leverage Azure RBAC for access control
   - Audit ARM invocations in Azure Activity Log

2. **Credential Management**
   - Store App Registration secrets in Key Vault
   - Rotate secrets regularly (every 90 days)
   - Use Managed Identity where possible

3. **Least Privilege**
   - Grant minimum required API permissions
   - Use read-only accounts for monitoring
   - Separate admin accounts for control operations

### Performance

1. **Auto-Refresh Tuning**
   - Active IR: 10-30 seconds
   - Normal monitoring: 30-60 seconds
   - Background: 5 minutes
   - Off when not monitoring

2. **Query Optimization**
   - Use time filters in KQL (`ago(7d)`)
   - Limit results with `take` or `top`
   - Avoid `select *` in large tables

3. **Batch Operations**
   - Select multiple devices for bulk actions
   - Use comma-separated indicators for TI
   - Leverage parallel ARM invocations

### Operational

1. **Monitoring**
   - Enable auto-refresh on Dashboard
   - Set alerts on high-severity incidents
   - Monitor function app health metrics

2. **Documentation**
   - Document custom detections externally
   - Save successful hunting queries
   - Track IOC sources and context

3. **Testing**
   - Test detections in lab environment
   - Validate queries before execution
   - Use test devices for Live Response

4. **Backup**
   - Export workbook JSON regularly
   - Save custom detections as code
   - Document hunting playbooks

### Compliance

1. **Audit Logging**
   - All ARM actions logged in Azure Activity Log
   - Function app logs in Application Insights
   - Defender XDR audit log for API calls

2. **Change Management**
   - Review ARM confirmations before approval
   - Document reason for control actions
   - Follow incident response procedures

3. **Data Handling**
   - Defender XDR data subject to Microsoft DPA
   - Function app logs contain sensitive data
   - Workbook parameters may contain IOCs

---

## 📚 Additional Resources

### Documentation

- **Project Repository:** https://github.com/akefallonitis/defenderc2xsoar
- **Defender XDR API:** https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro
- **Azure Workbooks:** https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview
- **Advanced Hunting:** https://docs.microsoft.com/en-us/microsoft-365/security/defender/advanced-hunting-overview

### Support

- **Issues:** https://github.com/akefallonitis/defenderc2xsoar/issues
- **Discussions:** https://github.com/akefallonitis/defenderc2xsoar/discussions

### Related Projects

- **MDEAutomator:** https://github.com/msdirtbag/MDEAutomator (original inspiration)

---

## 📝 Changelog

### Version 1.0 (2025-11-05)

**Initial Release:**
- ✅ Complete 8-module workbook
- ✅ Dashboard overview
- ✅ Device management with ARM actions
- ✅ Live Response console
- ✅ File library integration
- ✅ Advanced Hunting console
- ✅ Threat Intelligence management
- ✅ Incident tracking
- ✅ Custom detection rules
- ✅ Conditional visibility per module
- ✅ Auto-refresh for monitoring
- ✅ ARM actions for control operations
- ✅ Parameter auto-population
- ✅ Smart filtering and conflict detection

---

**Created by:** akefallonitis  
**Last Updated:** 2025-11-05  
**License:** MIT  
**Repository:** https://github.com/akefallonitis/defenderc2xsoar
