# DefenderC2 Enhanced Workbook Guide

## Overview

The DefenderC2 Enhanced Workbook provides a comprehensive, production-ready interface for managing Microsoft Defender for Endpoint through Azure Workbooks. It combines Custom Endpoints for auto-refresh data queries with ARM Actions for manual operations, creating a seamless command-and-control experience.

## 🚀 Quick Start

### Deployment

1. **Deploy the Workbook:**
   - Navigate to Azure Portal → Monitor → Workbooks
   - Click "+ New"
   - Open Advanced Editor (</> icon)
   - Paste contents of `workbook/DefenderC2-Workbook.json`
   - Click "Apply"
   - Save the workbook

2. **Configure Parameters:**
   - Select your **DefenderC2 Function App** from the dropdown
   - Select your **Log Analytics Workspace**
   - All other parameters auto-discover (Subscription, Resource Group, TenantId)

3. **Start Using:**
   - Navigate to tabs to access different functionality
   - All auto-refresh queries update every 30-60 seconds
   - Click "Select" on devices to add them to operations

## 📊 Architecture

### Component Structure

```
DefenderC2-Workbook.json
├── Header (Retro Terminal Theme)
├── Parameters (11 auto-discoverable)
├── Tabs (7 functional tabs)
└── Groups (7 conditional groups)
    ├── Custom Endpoints (9) - Auto-refresh queries
    └── ARM Actions (16) - Manual operations
```

### Technical Stack

- **Custom Endpoints (queryType: 10):** Auto-refresh data queries with JSONPath transformers
- **ARM Actions (linkTarget: ArmAction):** Manual operations with Azure RBAC enforcement
- **Conditional Visibility:** Tab-specific content based on user selection
- **Parameter Binding:** Global parameters for cross-tab workflows

## 🎯 Tabs & Features

### 1. Device Manager (12 items)

**Purpose:** Manage device inventory and execute response actions

**Features:**
- 📊 **Device Inventory** (Custom Endpoint)
  - Auto-refresh device list
  - Click-to-select workflow
  - Health, risk, and exposure visualization
  
- ⚠️ **Conflict Detection** (Custom Endpoint)
  - Shows running actions on selected devices
  - Prevents duplicate operations
  
- ⚡ **ARM Actions:**
  - Run Antivirus Scan
  - Isolate Device
  - Unisolate Device
  - Collect Investigation Package
  - Restrict App Execution
  - Unrestrict App Execution
  - Stop & Quarantine File

**Workflow:**
1. Device list populates automatically
2. Click "✅ Select" to add devices
3. Review conflict detection (running actions)
4. Execute ARM Action with Azure confirmation
5. Monitor in Action Manager tab

### 2. Threat Intel Manager (11 items)

**Purpose:** Manage threat indicators (File, IP, URL/Domain)

**Features:**
- 📋 **All Indicators** (Custom Endpoint)
  - Real-time indicator list
  - Filter by type, severity, action
  
- 📄 **File Indicators:**
  - Add SHA256 hashes with severity and action
  - ARM Action: Add File Indicators
  
- 🌐 **IP Indicators:**
  - Add IPv4/IPv6 addresses
  - ARM Action: Add IP Indicators
  
- 🌍 **URL/Domain Indicators:**
  - Add URLs and domains
  - ARM Action: Add URL/Domain Indicators

**Indicator Actions:**
- Alert
- Block
- Allow

**Severity Levels:**
- Low
- Medium
- High

### 3. Action Manager (4 items)

**Purpose:** Monitor and manage all device actions

**Features:**
- ⚙️ **All Actions** (Custom Endpoint)
  - Real-time action status
  - Auto-refresh every 30-60 seconds
  - Status visualization (Success, InProgress, Failed)
  
- ❌ **Cancel Action** (ARM Action)
  - Click "❌ Cancel" on any action
  - Conditional visibility (only shows when action selected)

**Status Indicators:**
- ✅ Succeeded (green)
- ⏳ InProgress (blue)
- ❌ Failed (red)

### 4. Advanced Hunting Manager (6 items)

**Purpose:** Execute KQL queries against Defender XDR

**Features:**
- 🎯 **Console-like Query Interface:**
  - Multi-line KQL editor
  - Query name and parameters
  - ARM Action: Execute Hunt
  
- 📚 **Example Query Library:**
  - 💻 Devices
  - 🚨 Alerts
  - 🔐 Logons
  - ⚙️ Processes
  - 🌐 Network
  - 📁 Files
  - 🗄️ Registry
  - ☠️ Threats
  
- 📖 **KQL Reference:**
  - Available tables
  - Common operators
  - Best practices
  - Performance tips

**Example Workflow:**
1. Click an example query to load it
2. Modify as needed in the editor
3. Click "🔍 Execute Hunt Query"
4. Results returned in ARM Action response
5. Save query name for documentation

### 5. Incident Manager (2 items)

**Purpose:** View and manage security incidents

**Features:**
- 🚨 **Recent Incidents** (Custom Endpoint)
  - Auto-refresh incident list
  - Severity visualization
  - Status tracking

**Incident Properties:**
- ID and Name
- Severity (🔴 High, 🟠 Medium, 🔵 Low)
- Status
- Assignment
- Creation date

### 6. Custom Detections (2 items)

**Purpose:** Manage custom detection rules

**Features:**
- ⚙️ **Detection Rules** (Custom Endpoint)
  - List all custom detection rules
  - Enabled/disabled status
  - Severity levels

### 7. Live Response Console (13 items)

**Purpose:** Interactive command execution and file operations

**Features:**
- 🔄 **Active Sessions** (Custom Endpoint)
  - Real-time session monitoring
  - Session status tracking
  
- 📚 **Library Files** (Custom Endpoint)
  - List all library scripts and files
  - Click-to-select workflow
  
- ▶️ **Script Execution** (ARM Action)
  - Execute library scripts on devices
  - Support for script arguments
  
- 📤 **File Deployment** (ARM Action)
  - Deploy library files to devices
  - Automatic library integration
  
- 📥 **File Download** (ARM Action)
  - Download files from devices
  - Base64 encoding for transport

**File Operations Workarounds:**

**Upload to Library:**
```powershell
# Option 1: Azure Portal
# Navigate to: Storage Account → Containers → "library" → Upload

# Option 2: PowerShell
Add-AzStorageBlob -Container "library" -File "C:\Path\script.ps1" -Context $ctx

# Option 3: Azure Storage Explorer
# GUI-based upload (recommended for bulk operations)
```

**Deploy to Device:**
1. File appears in library listing (Custom Endpoint)
2. Click "▶️ Select" on the file
3. Ensure device(s) selected from Device Manager
4. Click "📤 Deploy Library File to Device"

**Download from Device:**
1. Enter full file path (e.g., `C:\Temp\suspicious.exe`)
2. Select device(s)
3. Click "📥 Download File from Device"
4. File retrieved as Base64 in response
5. Decode and save locally

## 🎨 Design Features

### Retro Terminal Theme

The workbook uses a Matrix-inspired green phosphor CRT terminal theme:

- **Colors:** Black background, bright green text (#00ff00)
- **Effects:** Text glow, CRT scanlines, phosphor persistence
- **Typography:** Monospace fonts (Courier New, Consolas)
- **Visual Cues:** Status indicators with icon+color combinations

### UX Enhancements

1. **Smart Filtering:**
   - Device selection auto-filters action results
   - Conflict detection shows only relevant actions
   
2. **Conditional Visibility:**
   - Sections appear only when needed
   - Tab-specific functionality
   
3. **Auto-refresh:**
   - Configurable intervals (30s/60s)
   - Real-time monitoring
   
4. **Click-to-select:**
   - Devices, scripts, actions
   - Parameter auto-population

## 🔧 Technical Details

### Custom Endpoints

**Structure:**
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\", ...}",
    "queryType": 10,
    "visualization": "table"
  }
}
```

**Key Properties:**
- `queryType: 10` - Identifies as Custom Endpoint
- `version: "CustomEndpoint/1.0"` - Required in query JSON
- `urlParams` - Parameters sent to function app
- `transformers` - JSONPath for response parsing

**Example:**
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ],
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.devices[*]",
      "columns": [
        {"path": "$.id", "columnid": "DeviceID"},
        {"path": "$.computerDnsName", "columnid": "ComputerName"}
      ]
    }
  }]
}
```

### ARM Actions

**Structure:**
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
        "params": [
          {"key": "api-version", "value": "2022-03-01"},
          {"key": "action", "value": "Isolate Device"},
          {"key": "tenantId", "value": "{TenantId}"},
          {"key": "deviceIds", "value": "{DeviceList}"}
        ],
        "httpMethod": "POST",
        "title": "Isolate Device",
        "description": "Isolating device...",
        "runLabel": "Execute"
      }
    }]
  }
}
```

**Key Properties:**
- `linkTarget: "ArmAction"` - Identifies as ARM Action
- `armActionContext.path` - ARM resource path with function invocation
- `armActionContext.params` - Query string parameters
- `armActionContext.httpMethod` - POST for all function calls

### Parameter Configuration

**Global Parameters:**
```json
{
  "name": "DeviceList",
  "type": 1,
  "isGlobal": true,
  "value": ""
}
```

**Auto-discovered Parameters:**
```json
{
  "name": "TenantId",
  "type": 2,
  "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId",
  "crossComponentResources": ["value::all"],
  "queryType": 1,
  "resourceType": "microsoft.resourcegraph/resources"
}
```

### Conditional Visibility

**Show when parameter has value:**
```json
{
  "conditionalVisibility": {
    "parameterName": "DeviceList",
    "comparison": "isNotEqualTo",
    "value": ""
  }
}
```

**Show for specific tab:**
```json
{
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "devices"
  }
}
```

## 📋 Function App Integration

### Supported Operations

**DefenderC2Dispatcher:**
- `Get Devices` - List all devices
- `Get Device Info` - Get specific device details
- `Get All Actions` - List all machine actions
- `Get Action Status` - Get specific action status
- `Cancel Action` - Cancel a running action
- `Isolate Device` - Isolate from network
- `Unisolate Device` - Remove isolation
- `Restrict App Execution` - Restrict to signed apps
- `Unrestrict App Execution` - Remove restriction
- `Run Antivirus Scan` - Execute AV scan
- `Collect Investigation Package` - Collect diagnostic package
- `Stop & Quarantine File` - Stop and quarantine by hash

**DefenderC2TIManager:**
- `List All Indicators` - List all threat indicators
- `Add File Indicators` - Add file hash indicators
- `Remove File Indicators` - Remove file indicators
- `Add IP Indicators` - Add IP address indicators
- `Remove IP Indicators` - Remove IP indicators
- `Add URL/Domain Indicators` - Add URL/domain indicators
- `Remove URL/Domain Indicators` - Remove URL/domain indicators

**DefenderC2HuntManager:**
- `ExecuteHunt` - Execute KQL hunting query

**DefenderC2IncidentManager:**
- `GetIncidents` - List all incidents
- `GetIncidentDetails` - Get specific incident details
- `UpdateIncident` - Update incident properties

**DefenderC2CDManager:**
- `List All Detections` - List custom detection rules
- `Create Detection` - Create new detection rule
- `Update Detection` - Update detection rule
- `Delete Detection` - Delete detection rule
- `Backup Detections` - Backup all detections

**DefenderC2Orchestrator:**
- `GetLiveResponseSessions` - List active LR sessions
- `InvokeLiveResponseScript` - Execute library script
- `GetLiveResponseOutput` - Get command output
- `GetLiveResponseFile` - Download file from device
- `PutLiveResponseFile` - Upload file to device
- `PutLiveResponseFileFromLibrary` - Deploy library file
- `ListLibraryFiles` - List library contents
- `GetLibraryFile` - Get library file details
- `UploadToLibrary` - Upload file to library
- `DeleteLibraryFile` - Delete library file

## 🛠️ Troubleshooting

### Common Issues

**1. Parameters not populating:**
- Ensure Function App and Workspace are selected first
- Check auto-discovery queries have proper permissions
- Verify Resource Graph API access

**2. Custom Endpoints not loading:**
- Check function app URL in browser console
- Verify function app is running (not in sleep mode)
- Check CORS settings if domain mismatch
- Ensure anonymous authentication is enabled

**3. ARM Actions failing:**
- Verify RBAC permissions (Contributor or higher)
- Check function app resource path
- Ensure api-version is current (2022-03-01)
- Review error message in Azure notification

**4. Auto-refresh not working:**
- Verify AutoRefresh parameter is set (30000 or 60000)
- Check timeContextFromParameter is configured
- Ensure Custom Endpoint has showRefreshButton: true

**5. File operations failing:**
- Verify devices are online and Live Response enabled
- Check library container exists in storage account
- Ensure adequate permissions (Security Administrator)
- Allow 30-60 seconds for session initialization

### Debug Tips

**Enable Detailed Logging:**
1. Open browser developer tools (F12)
2. Navigate to Console tab
3. Execute workbook operations
4. Review network requests and responses

**Test Function App Directly:**
```bash
# Test device listing
curl -X POST "https://your-function-app.azurewebsites.net/api/DefenderC2Dispatcher" \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"your-tenant-id"}'
```

**Validate JSON:**
```bash
# Validate workbook JSON structure
jq . workbook/DefenderC2-Workbook.json
```

## 🔐 Security Considerations

### RBAC Requirements

**Minimum Permissions:**
- **Reader** on Function App (for discovery)
- **Contributor** on Function App (for ARM Actions)
- **Reader** on Log Analytics Workspace (for queries)
- **Security Administrator** in Defender (for operations)

### Function App Security

**Authentication:**
- **Anonymous** (recommended for workbook integration)
- **Function Key** (optional, can be parameterized)
- **Azure AD** (requires additional configuration)

**Network Security:**
- Function app accessible from Azure Portal IP ranges
- CORS configured for Azure Portal domains
- Private endpoints for enhanced security

### Data Protection

**Sensitive Data:**
- File contents transmitted as Base64
- No credentials stored in workbook
- All operations audited via Azure Activity Log

**Compliance:**
- Azure RBAC enforcement
- Audit trail in Defender XDR
- Activity logging enabled

## 📚 Additional Resources

### Documentation
- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Defender for Endpoint API](https://docs.microsoft.com/defender-endpoint/api-reference)
- [KQL Language Reference](https://docs.microsoft.com/kusto/query/)
- [Live Response Documentation](https://docs.microsoft.com/defender-endpoint/live-response)

### Related Files
- `workbook/DefenderC2-Workbook.json` - Main enhanced workbook
- `workbook/DeviceManager-Hybrid.json` - Device management baseline
- `workbook/DeviceManager-CustomEndpoint.json` - Custom endpoint patterns
- `examples/customendpoint-example.json` - Custom endpoint examples

### Support
- GitHub Issues: [akefallonitis/defenderc2xsoar](https://github.com/akefallonitis/defenderc2xsoar/issues)
- Function App Documentation: See `functions/` directory
- Deployment Guide: See `DEPLOYMENT.md`

## 🎉 Conclusion

The DefenderC2 Enhanced Workbook provides a production-ready, feature-complete interface for managing Microsoft Defender for Endpoint. With 9 Custom Endpoints for real-time monitoring and 16 ARM Actions for manual operations across 7 functional tabs, it offers comprehensive command-and-control capabilities with a modern, user-friendly interface.

**Key Benefits:**
- ✅ Zero-code deployment (JSON import)
- ✅ Auto-discovery of configuration
- ✅ Real-time monitoring with auto-refresh
- ✅ Azure RBAC enforcement
- ✅ Multi-tenant support
- ✅ Production-ready workflows
- ✅ Comprehensive documentation
- ✅ Cutting-edge UX

Happy hunting! 🎯
