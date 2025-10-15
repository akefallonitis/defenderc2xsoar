# DefenderC2 XSOAR - Functionality Reference

> **Quick answer to "where is the functionality?"** - This guide maps all features to their implementation locations in the codebase.
>
> **⚡ Want an even faster lookup?** See [Quick Reference Card](docs/QUICK_REFERENCE.md) for ultra-fast table lookup.

## 📋 Table of Contents

- [Overview](#overview)
- [Azure Functions (Backend API)](#azure-functions-backend-api)
- [Workbook Components (User Interface)](#workbook-components-user-interface)
- [Helper Modules & Scripts](#helper-modules--scripts)
- [Deployment Components](#deployment-components)
- [Documentation](#documentation)
- [Quick Reference](#quick-reference)

---

## Overview

DefenderC2 XSOAR is structured with:
- **Backend**: Azure Functions (PowerShell) in `/functions/`
- **Frontend**: Azure Workbook JSON in `/workbook/`
- **Deployment**: ARM templates in `/deployment/`
- **Standalone**: PowerShell CLI version in `/standalone/`

---

## Azure Functions (Backend API)

All Azure Functions are located in `/functions/` directory. Each function is a separate endpoint that handles specific MDE operations.

### 1. DefenderC2Dispatcher
**Location**: `/functions/DefenderC2Dispatcher/run.ps1`  
**Endpoint**: `/api/DefenderC2Dispatcher`  
**Purpose**: Main device management and control operations

**Functionality:**
- ✅ **Device Actions**
  - Isolate Device
  - Unisolate Device
  - Restrict App Execution
  - Unrestrict App Execution
  - Collect Investigation Package
  - Run Antivirus Scan
  - Stop & Quarantine File
  
- ✅ **Device Information**
  - Get Devices (with filtering)
  - Get Device Info
  
- ✅ **Action Management**
  - Get Action Status
  - Get All Actions
  - Cancel Action

**Key Code Sections:**
- Lines 1-53: Parameter handling and validation
- Lines 54-168: Action routing (switch statement)
- Lines 70-127: Device action implementations

**Related Workbook Tab**: "MDEAutomator (Device Actions)" in DefenderC2-Workbook.json

---

### 2. DefenderC2TIManager
**Location**: `/functions/DefenderC2TIManager/run.ps1`  
**Endpoint**: `/api/DefenderC2TIManager`  
**Purpose**: Threat intelligence indicator management

**Functionality:**
- ✅ **File Indicators** (SHA1/SHA256/MD5)
  - Add File Indicators
  - Remove File Indicators
  
- ✅ **Network Indicators**
  - Add IP Indicators
  - Add URL/Domain Indicators
  - Remove Network Indicators
  
- ✅ **Certificate Indicators**
  - Add Certificate Indicators
  
- ✅ **Indicator Management**
  - List All Indicators
  - Bulk Import from CSV

**Related Workbook Tab**: "Threat Intelligence Manager" in DefenderC2-Workbook.json

---

### 3. DefenderC2HuntManager
**Location**: `/functions/DefenderC2HuntManager/run.ps1`  
**Endpoint**: `/api/DefenderC2HuntManager`  
**Purpose**: Advanced hunting query execution

**Functionality:**
- ✅ **Hunt Execution**
  - Execute KQL queries
  - Save hunt results
  - Named hunt operations
  
- ✅ **Query Management**
  - Custom KQL queries
  - Result filtering
  - Data export

**Related Workbook Tab**: "Hunt Manager" in DefenderC2-Workbook.json

---

### 4. DefenderC2IncidentManager
**Location**: `/functions/DefenderC2IncidentManager/run.ps1`  
**Endpoint**: `/api/DefenderC2IncidentManager`  
**Purpose**: Security incident management

**Functionality:**
- ✅ **Incident Operations**
  - Get Incidents (with filtering)
  - Get Incident Details
  - Update Incident status
  - Update Incident classification
  
- ✅ **Incident Properties**
  - Severity filtering
  - Status updates
  - Classification updates
  - Determination updates

**Related Workbook Tab**: "Incident Manager" in DefenderC2-Workbook.json

---

### 5. DefenderC2CDManager
**Location**: `/functions/DefenderC2CDManager/run.ps1`  
**Endpoint**: `/api/DefenderC2CDManager`  
**Purpose**: Custom detection rule management

**Functionality:**
- ✅ **Detection Operations**
  - List All Detections
  - Create Detection
  - Update Detection
  - Delete Detection
  - Backup Detections
  
- ✅ **Detection Properties**
  - Detection name
  - KQL query
  - Severity levels
  - Enable/disable status

**Related Workbook Tab**: "Custom Detection Manager" in DefenderC2-Workbook.json

---

### 6. DefenderC2Orchestrator
**Location**: `/functions/DefenderC2Orchestrator/run.ps1`  
**Endpoint**: `/api/DefenderC2Orchestrator`  
**Purpose**: Live Response and file library operations

**Functionality:**
- ✅ **Live Response Operations**
  - GetLiveResponseSessions - List active sessions
  - InvokeLiveResponseScript - Execute scripts
  - GetLiveResponseOutput - Get command results
  - GetLiveResponseFile - Download files (returns Base64)
  - PutLiveResponseFile - Upload files (accepts Base64)
  - PutLiveResponseFileFromLibrary - Deploy from library
  
- ✅ **Library Management**
  - ListLibraryFiles - List files in Azure Storage
  - GetLibraryFile - Retrieve file (Base64 encoded)
  - UploadToLibrary - Upload file to library
  - DeleteLibraryFile - Remove file from library
  
- ✅ **Advanced Features**
  - Automatic retry logic
  - Rate limit handling
  - Session management
  - Command monitoring

**Key Code Sections:**
- Lines 63-104: Rate limit retry logic
- Lines 121-417: Live Response operations
- Lines 419-576: Library management operations

**Related Workbook Tabs**: 
- "🖥️ Interactive Console" in DefenderC2-Workbook.json
- "📦 File Operations" in FileOperations.workbook

---

## Workbook Components (User Interface)

### Main Workbook
**Location**: `/workbook/DefenderC2-Workbook.json`

**Structure:**
```
DefenderC2-Workbook.json
├── Parameters (Global)
│   ├── FunctionAppName (auto-discovered)
│   ├── TenantId (auto-discovered from workspace)
│   └── FunctionKey (optional)
│
├── Tab 1: MDEAutomator (Device Actions)
│   ├── Get Devices (Custom Endpoint → DefenderC2Dispatcher)
│   ├── Isolate Device (ARM Action → DefenderC2Dispatcher)
│   ├── Unisolate Device (ARM Action → DefenderC2Dispatcher)
│   ├── Restrict App Execution (ARM Action → DefenderC2Dispatcher)
│   ├── Run Antivirus Scan (ARM Action → DefenderC2Dispatcher)
│   └── Collect Investigation Package (ARM Action → DefenderC2Dispatcher)
│
├── Tab 2: Threat Intelligence Manager
│   ├── List Indicators (Custom Endpoint → DefenderC2TIManager)
│   ├── Add File Indicators (ARM Action → DefenderC2TIManager)
│   ├── Add IP Indicators (ARM Action → DefenderC2TIManager)
│   └── Remove Indicators (ARM Action → DefenderC2TIManager)
│
├── Tab 3: Action Manager
│   ├── Get All Actions (Custom Endpoint → DefenderC2Dispatcher)
│   ├── Get Action Status (Custom Endpoint → DefenderC2Dispatcher)
│   └── Cancel Action (ARM Action → DefenderC2Dispatcher)
│
├── Tab 4: Hunt Manager
│   ├── Execute Hunt (Custom Endpoint → DefenderC2HuntManager)
│   └── Save Hunt Results (ARM Action → DefenderC2HuntManager)
│
├── Tab 5: Incident Manager
│   ├── Get Incidents (Custom Endpoint → DefenderC2IncidentManager)
│   ├── Get Incident Details (Custom Endpoint → DefenderC2IncidentManager)
│   └── Update Incident (ARM Action → DefenderC2IncidentManager)
│
├── Tab 6: Custom Detection Manager
│   ├── List Detections (Custom Endpoint → DefenderC2CDManager)
│   ├── Create Detection (ARM Action → DefenderC2CDManager)
│   ├── Update Detection (ARM Action → DefenderC2CDManager)
│   └── Delete Detection (ARM Action → DefenderC2CDManager)
│
├── Tab 7: 🖥️ Interactive Console
│   ├── Command Execution (Custom Endpoint → DefenderC2Orchestrator)
│   ├── Auto-refresh status polling
│   ├── Result parsing and display
│   └── Execution history tracking
│
└── Tab 8: 📦 File Operations (if using FileOperations.workbook)
    ├── List Library Files (Custom Endpoint → DefenderC2Orchestrator)
    ├── Upload to Library (ARM Action → DefenderC2Orchestrator)
    ├── Deploy to Device (ARM Action → DefenderC2Orchestrator)
    └── Delete from Library (ARM Action → DefenderC2Orchestrator)
```

**Workbook Patterns:**
- **Custom Endpoint** (queryType: 10): Auto-refresh queries that call functions and display results
- **ARM Action** (type: 11): Manual buttons that trigger function calls
- **Parameters**: Use `{ParameterName}` in URLs and bodies for dynamic values

---

### File Operations Workbook
**Location**: `/workbook/FileOperations.workbook`

Specialized workbook for file library management and Live Response file operations.

---

## Helper Modules & Scripts

### PowerShell Helper Modules
**Location**: `/functions/profile.ps1`

Contains shared PowerShell functions used by all Azure Functions:
- `Connect-MDE` - Authenticate with MDE API
- `Get-MDEAuthHeaders` - Get auth headers
- `Start-MDELiveResponseSession` - Start Live Response
- `Invoke-MDELiveResponseCommand` - Execute commands
- `Wait-MDELiveResponseCommand` - Wait for completion
- Plus many more MDE API wrapper functions

**Key Functions:**
```powershell
# Authentication
Connect-MDE -TenantId $tid -AppId $appId -ClientSecret $secret

# Device Operations
Get-AllDevices -Token $token -Filter "riskScore eq 'High'"
Invoke-DeviceIsolation -Token $token -DeviceIds @("id1","id2")

# Threat Intelligence
Add-FileIndicators -Token $token -Hashes @("sha256:...")

# Advanced Hunting
Invoke-AdvancedHunt -Token $token -Query "DeviceInfo | take 10"

# Live Response
Start-MDELiveResponseSession -Token $token -DeviceId $deviceId
```

---

### Validation & Fix Scripts
**Location**: `/scripts/`

Utility scripts for workbook validation and fixes:
- `verify_workbook_config.py` - Validate workbook JSON structure
- `verify_arm_customendpoint_fix.py` - Check ARM actions and Custom Endpoints
- `fix_workbook_surgical.py` - Fix common workbook issues
- `convert_arm_actions.py` - Convert between ARM action formats

---

## Deployment Components

### ARM Templates
**Location**: `/deployment/azuredeploy.json`

**What gets deployed:**
```json
{
  "resources": [
    "Azure Function App (PowerShell 7.4)",
    "App Service Plan (Consumption)",
    "Storage Account (for function app and library)",
    "Application Insights (monitoring)",
    "Azure Workbook (DefenderC2 Console)"
  ]
}
```

**Key Parameters:**
- `functionAppName` - Name for the Function App
- `appId` - Multi-tenant App Registration client ID
- `secretId` - Client secret for authentication
- `location` - Azure region for deployment

**Deploy Button**: See README.md for one-click deployment

---

### Deployment Documentation
**Location**: `/deployment/`

- `CUSTOMENDPOINT_GUIDE.md` - Guide for CustomEndpoint and ARM Actions
- `WORKBOOK_PARAMETERS_GUIDE.md` - Parameter configuration reference
- `DYNAMIC_FUNCTION_APP_NAME.md` - Function app naming patterns
- `FUNCTION_APP_NAME_README.md` - Function app configuration

---

## Documentation

### Main Documentation (Root)
- `README.md` - Project overview and quick start
- `DEPLOYMENT.md` - Full deployment guide
- `QUICKSTART.md` - Quick start guide
- `CONTRIBUTING.md` - Contributing guidelines
- **`FUNCTIONALITY_REFERENCE.md`** - This file (feature-to-code mapping)

### Archive Documentation
**Location**: `/archive/`

- **`/archive/technical-docs/`** - Technical documentation
  - `FUNCTIONS_REFERENCE.md` - Complete API reference (most detailed)
  - `ARCHITECTURE.md` - Architecture diagrams and details
  - `FEATURES.md` - Feature documentation
  
- **`/archive/feature-guides/`** - Feature-specific guides
  - `FILE_OPERATIONS_GUIDE.md` - File library and Live Response guide
  - `WORKBOOK_EXAMPLES.md` - Workbook pattern examples
  
- **`/archive/deployment-guides/`** - Advanced deployment scenarios
  - `DEPLOYMENT_TROUBLESHOOTING.md` - Common issues and solutions
  - `QUICKSTART_FUNCTIONS.md` - Function-specific quick start

---

## Quick Reference

### "I want to... Where is the code?"

#### Device Operations
- **Isolate a device** → `/functions/DefenderC2Dispatcher/run.ps1` (lines 72-78)
- **Run antivirus scan** → `/functions/DefenderC2Dispatcher/run.ps1` (lines 111-118)
- **Collect investigation package** → `/functions/DefenderC2Dispatcher/run.ps1` (lines 103-110)
- **Get device list** → `/functions/DefenderC2Dispatcher/run.ps1` (lines 127-131)

#### Threat Intelligence
- **Add file indicators** → `/functions/DefenderC2TIManager/run.ps1`
- **Add IP indicators** → `/functions/DefenderC2TIManager/run.ps1`
- **List all indicators** → `/functions/DefenderC2TIManager/run.ps1`

#### Live Response & Files
- **Upload file to device** → `/functions/DefenderC2Orchestrator/run.ps1` (lines 255-320)
- **Download file from device** → `/functions/DefenderC2Orchestrator/run.ps1` (lines 200-253)
- **Run script on device** → `/functions/DefenderC2Orchestrator/run.ps1` (lines 142-175)
- **Manage library files** → `/functions/DefenderC2Orchestrator/run.ps1` (lines 419-576)

#### Advanced Hunting
- **Execute KQL query** → `/functions/DefenderC2HuntManager/run.ps1`

#### Incidents
- **Get incidents** → `/functions/DefenderC2IncidentManager/run.ps1`
- **Update incident** → `/functions/DefenderC2IncidentManager/run.ps1`

#### Custom Detections
- **Create detection rule** → `/functions/DefenderC2CDManager/run.ps1`
- **List detections** → `/functions/DefenderC2CDManager/run.ps1`

---

### "I want to customize the workbook... Where do I start?"

1. **Understand the pattern**: Read `/deployment/CUSTOMENDPOINT_GUIDE.md`
2. **Look at examples**: Check `/examples/customendpoint-example.json`
3. **Edit workbook**: Modify `/workbook/DefenderC2-Workbook.json`
4. **Test locally**: Use scripts in `/scripts/` to validate
5. **Deploy**: Re-import to Azure Portal

**Key workbook concepts:**
- **Custom Endpoint** (queryType: 10): For queries that auto-refresh
- **ARM Action** (type: 11): For manual button actions
- **Parameters**: Use `{ParamName}` for dynamic values in URLs/bodies

---

### "I want to add a new feature... What do I modify?"

1. **Backend Function**: Add new action to appropriate function in `/functions/`
2. **Workbook UI**: Add corresponding Custom Endpoint or ARM Action in `/workbook/`
3. **Documentation**: Update this file and `/archive/technical-docs/FUNCTIONS_REFERENCE.md`
4. **Testing**: Validate with scripts in `/scripts/`

**Example: Add new device action**
```powershell
# 1. Add to /functions/DefenderC2Dispatcher/run.ps1
"My New Action" {
    # Your implementation
}

# 2. Add ARM Action button to workbook
{
  "type": 11,
  "content": {
    "links": [{
      "linkLabel": "My New Action",
      "armActionContext": {
        "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
        "body": "{\"action\":\"My New Action\",\"tenantId\":\"{TenantId}\"}",
        "httpMethod": "POST"
      }
    }]
  }
}
```

---

## API Testing

### Using PowerShell
```powershell
$baseUrl = "https://your-function-app.azurewebsites.net/api"
$body = @{
    action = "Get Devices"
    tenantId = "your-tenant-id"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "$baseUrl/DefenderC2Dispatcher" -Body $body -ContentType "application/json"
```

### Using cURL
```bash
curl -X POST https://your-function-app.azurewebsites.net/api/DefenderC2Dispatcher \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"your-tenant-id"}'
```

---

## Common Tasks

### Task 1: Find function for a workbook button
1. Open `/workbook/DefenderC2-Workbook.json`
2. Search for the button label
3. Look at `armActionContext.path` or Custom Endpoint `url`
4. Function name is in the URL: `/api/{FunctionName}`
5. Open `/functions/{FunctionName}/run.ps1`

### Task 2: Understand what a function does
1. Open `/functions/{FunctionName}/run.ps1`
2. Look at the switch statement (usually around line 60-200)
3. Each case is an action/operation
4. See `/archive/technical-docs/FUNCTIONS_REFERENCE.md` for detailed API docs

### Task 3: Troubleshoot failed operation
1. Check Function App logs in Azure Portal
2. Look for error messages in function response
3. Verify API permissions in App Registration
4. Check rate limits (see FUNCTIONS_REFERENCE.md)
5. See `/archive/deployment-guides/DEPLOYMENT_TROUBLESHOOTING.md`

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Workbook (UI)                      │
│  /workbook/DefenderC2-Workbook.json                         │
│  - Parameters (FunctionAppName, TenantId)                   │
│  - 8 Tabs (Device, TI, Hunt, Incident, Detection, etc.)    │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS (Custom Endpoint / ARM Action)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Azure Function App (Backend)                    │
│  /functions/                                                 │
│  ├── DefenderC2Dispatcher      (Device operations)          │
│  ├── DefenderC2TIManager       (Threat intel)               │
│  ├── DefenderC2HuntManager     (Hunting)                    │
│  ├── DefenderC2IncidentManager (Incidents)                  │
│  ├── DefenderC2CDManager       (Custom detections)          │
│  └── DefenderC2Orchestrator    (Live Response & files)      │
│                                                              │
│  Shared: /functions/profile.ps1 (MDE API helpers)           │
└────────────────────┬────────────────────────────────────────┘
                     │ OAuth 2.0 + API Calls
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          Microsoft Defender for Endpoint (MDE)              │
│  - Device Management API                                     │
│  - Threat Intelligence API                                   │
│  - Advanced Hunting API                                      │
│  - Live Response API                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure Summary

```
defenderc2xsoar/
├── functions/                      # Backend API (Azure Functions)
│   ├── DefenderC2Dispatcher/       # Device operations
│   ├── DefenderC2TIManager/        # Threat intelligence
│   ├── DefenderC2HuntManager/      # Advanced hunting
│   ├── DefenderC2IncidentManager/  # Incident management
│   ├── DefenderC2CDManager/        # Custom detections
│   ├── DefenderC2Orchestrator/     # Live Response & files
│   └── profile.ps1                 # Shared helper functions
│
├── workbook/                       # Frontend UI (Azure Workbooks)
│   ├── DefenderC2-Workbook.json    # Main operational workbook
│   └── FileOperations.workbook     # File operations workbook
│
├── deployment/                     # Deployment files
│   ├── azuredeploy.json            # ARM template
│   └── *.md                        # Deployment guides
│
├── scripts/                        # Validation & utility scripts
│   └── *.py                        # Workbook validation tools
│
├── standalone/                     # Standalone PowerShell version
│   └── README.md                   # Standalone documentation
│
├── archive/                        # Archive documentation
│   ├── technical-docs/             # Technical references
│   ├── feature-guides/             # Feature documentation
│   └── deployment-guides/          # Advanced deployment
│
├── README.md                       # Project overview
├── DEPLOYMENT.md                   # Deployment guide
├── QUICKSTART.md                   # Quick start guide
└── FUNCTIONALITY_REFERENCE.md      # This file (you are here!)
```

---

## Additional Resources

- **Complete API Reference**: `/archive/technical-docs/FUNCTIONS_REFERENCE.md`
- **Architecture Details**: `/archive/technical-docs/ARCHITECTURE.md`
- **File Operations Guide**: `/archive/feature-guides/FILE_OPERATIONS_GUIDE.md`
- **Deployment Guide**: `/DEPLOYMENT.md`
- **Troubleshooting**: `/archive/deployment-guides/DEPLOYMENT_TROUBLESHOOTING.md`

---

## Support

**Found what you're looking for?** Great! 🎉

**Still need help?** 
1. Check detailed API docs: `/archive/technical-docs/FUNCTIONS_REFERENCE.md`
2. Review examples: `/examples/`
3. Open GitHub issue with specific question

---

**Last Updated**: 2025-10-15  
**Version**: 1.0
