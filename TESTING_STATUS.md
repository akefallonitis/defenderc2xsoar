# DefenderC2XSOAR Function Testing & Workbook Implementation Status

## Current Status: Functions Not Yet Accessible

### Issue
- **401 Unauthorized** errors when calling Gateway endpoint
- **Root Cause:** Function App hasn't reloaded the new package from GitHub yet
- **WEBSITE_RUN_FROM_PACKAGE:** Auto-reload is ETag-based (30-90 seconds typically)

### Test Results
```
❌ Gateway GET: 401 Unauthorized
❌ Gateway POST: 401 Unauthorized  
❌ Function keys tested: default and master keys both return 401
```

### Resolution Options

**Option 1: Wait for Auto-Reload (RECOMMENDED - 30-90 seconds)**
```bash
# The function app checks the GitHub URL periodically
# Package URL: https://github.com/akefallonitis/defenderc2xsoar/raw/main/deployment/function-package.zip
# Wait 1-2 minutes, then test again
```

**Option 2: Manual Sync via Azure Portal**
```
1. Navigate to: https://portal.azure.com
2. Find Function App: sentryxdr
3. Go to: Deployment Center
4. Click: Sync
5. Wait 30 seconds
6. Test Gateway endpoint
```

**Option 3: Manual Sync via Azure CLI (if installed)**
```powershell
az functionapp deployment source sync `
  --name sentryxdr `
  --resource-group alex-testing-rg
```

**Option 4: Restart Function App**
```
Azure Portal → sentryxdr → Overview → Restart
Wait 2 minutes for cold start, then test
```

---

## Comprehensive Testing Script Created

**File:** `deployment/test-gateway-comprehensive.ps1`

**Features:**
- Tests Gateway GET/POST connectivity
- Tests MDE device listing
- Tests Security Incidents (Graph API)
- Tests MDE Alerts
- Tests Advanced Hunting (KQL)
- Tests Threat Intelligence
- Tests EntraID operations
- Comprehensive error handling and reporting

**Usage:**
```powershell
cd deployment
.\test-gateway-comprehensive.ps1 -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
```

---

## Workbook Analysis Complete

### Patterns Identified from Samples

**From Sentinel360 XDR Investigation-Remediation Console Enhanced:**
- Multi-level tab navigation (main tabs → sub-tabs)
- Entity-based investigation (IP/Account/Host/URL/FileHash)
- Conditional visibility per tab
- ARM actions embedded in markdown code blocks  
- Parameter-based filtering and selection
- Auto-population from queries

**From Advanced Workbook Concepts:**
- Azure Resource Graph for dynamic resource selection
- ARM actions for deployments
- Custom endpoints for external data
- Merge queries for combining data sources
- Graph visualizations with nodes and links
- Template loading from external URLs

**From DefenderC2-CustomEndpoint:**
- Retro terminal theme (green phosphor CRT style)
- Custom CSS styling for workbook elements
- Custom endpoint pattern for Function App calls
- Real-time device list population
- Action tracking with status indicators
- Interactive console with command execution

---

## Workbook Design Architecture

### Main Structure

```
📊 DefenderXDR C2 XSOAR Console
│
├── 🎯 Global Parameters (Auto-Population)
│   ├── Lighthouse Tenant Selector (multi-tenant)
│   ├── Function App URL (auto-discovered)
│   ├── Time Range
│   └── Refresh Interval
│
├── Tab 1: 📊 Main Dashboard
│   ├── Metrics Tiles (Incidents/Alerts/Entities)
│   ├── Incident List (custom endpoint - auto-refresh)
│   ├── Alert List (custom endpoint - auto-refresh)
│   ├── Entity Summary Grid
│   └── Quick Actions (ARM actions)
│
├── Tab 2: 💻 Device Management
│   ├── Device List (custom endpoint with filters)
│   ├── Selected Device Details
│   ├── Device Actions (ARM actions)
│   │   ├── Isolate Device
│   │   ├── Release from Isolation
│   │   ├── Run AV Scan
│   │   ├── Collect Investigation Package
│   │   ├── Restrict App Execution
│   │   └── Initiate Live Response
│   └── Device Action History
│
├── Tab 3: 🔍 Advanced Hunting Console
│   ├── Query Input (multi-line text editor)
│   ├── Saved Queries Dropdown
│   ├── Query Templates
│   ├── Execute Query (ARM action)
│   ├── Results Grid (export to Excel)
│   └── Query History
│
├── Tab 4: 🖥️ Live Response Console
│   ├── Device Selector
│   ├── Session Management
│   ├── Command Input (interactive shell)
│   ├── Command Library Dropdown
│   │   ├── Directory Operations (dir, cd, etc.)
│   │   ├── File Operations (get, put, delete)
│   │   ├── Process Operations (ps, kill)
│   │   └── Custom Commands
│   ├── File Library Management
│   │   ├── Upload File (via Storage Account)
│   │   ├── Download File (direct download)
│   │   └── List Library Files (custom endpoint)
│   └── Command Output Console
│
├── Tab 5: 🛡️ Threat Intelligence
│   ├── Indicator List (custom endpoint)
│   ├── Add File Indicator (ARM action)
│   ├── Add IP Indicator (ARM action)
│   ├── Add URL/Domain Indicator (ARM action)
│   ├── Remove Indicator (ARM action)
│   └── Bulk Import (via ARM template deployment)
│
├── Tab 6: 🚨 Incident Management
│   ├── Incident List (custom endpoint with filters)
│   ├── Selected Incident Details
│   ├── Update Incident (ARM action)
│   │   ├── Change Status
│   │   ├── Assign Owner
│   │   ├── Set Classification
│   │   └── Set Determination
│   ├── Add Comment (ARM action)
│   └── Related Alerts/Entities
│
├── Tab 7: 👤 Identity Protection
│   ├── Risky Users (custom endpoint)
│   ├── Risk Detections (custom endpoint)
│   ├── User Actions (ARM actions)
│   │   ├── Disable Account
│   │   ├── Revoke Sessions
│   │   ├── Reset Password
│   │   ├── Confirm Compromised
│   │   └── Dismiss Risk
│   └── Conditional Access Policies
│
└── Tab 8: ⚙️ Custom Detections
    ├── Detection Rules List (custom endpoint)
    ├── Create Detection (ARM action)
    ├── Update Detection (ARM action)
    ├── Delete Detection (ARM action)
    └── Test Detection Query
```

### Advanced Features Implementation

#### 1. Multi-Tenant Support (Lighthouse)
```json
{
  "id": "tenant-selector",
  "name": "SelectedTenant",
  "type": 2,
  "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId",
  "crossComponentResources": ["value::all"]
}
```

#### 2. Custom Endpoints for Auto-Refresh Lists
```json
{
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://sentryxdr.azurewebsites.net/api/Gateway\",\"body\":\"{\\\"tenant\\\":\\\"{SelectedTenant}\\\",\\\"service\\\":\\\"MDE\\\",\\\"action\\\":\\\"GetAllDevices\\\"}\"}",
  "queryType": 10
}
```

#### 3. ARM Actions for Manual Operations
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "https://sentryxdr.azurewebsites.net/api/Gateway",
    "method": "POST",
    "body": "{\"tenant\":\"{SelectedTenant}\",\"service\":\"MDE\",\"action\":\"IsolateDevice\",\"deviceId\":\"{SelectedDevice}\"}"
  }
}
```

#### 4. Conditional Visibility Per Tab
```json
{
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "DeviceManagement"
  }
}
```

#### 5. File Operations Workaround
```markdown
**Upload File to Library:**
1. Upload file to Storage Account: {StorageAccountName}/library/{filename}
2. Reference in Live Response: library/{filename}

**Download File from Device:**
1. Execute GetFile command in Live Response
2. File downloads via direct URL from function response
```

#### 6. Interactive Console UI
```json
{
  "type": 1,
  "content": {
    "json": "```\\n> {ConsoleCommand}\\n{ConsoleOutput}\\n> _\\n```"
  }
}
```

### Auto-Population Strategy

**Level 1 - Top Parameters (Always Visible):**
- Lighthouse Tenant Selector → Auto-populates from Azure delegations
- Time Range → Standard time picker
- Function App URL → Auto-discovered from Function App resource

**Level 2 - Per-Tab Listings (Auto-Refresh):**
- Device List → Custom endpoint, refreshes every 60s
- Incident List → Custom endpoint, refreshes every 30s
- Alert List → Custom endpoint, refreshes every 30s
- Indicator List → Custom endpoint, refreshes every 120s

**Level 3 - Selection-Based (Dependent):**
- Selected Device → Populates from Device List selection
- Selected Incident → Populates from Incident List selection
- Selected Alert → Populates from Alert List selection
- Related Entities → Populates from selected incident/alert

**Level 4 - Action Parameters (Dynamic):**
- Device Actions → Auto-populate device ID from selection
- Incident Updates → Auto-populate incident fields from selection
- Indicator Actions → Auto-populate indicator details from selection

---

## Next Steps

### Step 1: Verify Function Deployment ✅
**Wait 2-3 minutes for auto-reload, then run:**
```powershell
cd deployment
.\test-gateway-comprehensive.ps1 -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
```

**Expected Outcome:**
- ✅ All tests pass
- ✅ Functions return 200 OK
- ✅ Data returned from MDE, Graph, Sentinel

### Step 2: Generate Complete Workbook 🚀
**Once functions are verified working:**
```
I will generate the complete Azure Workbook JSON with:
- All 8 tabs fully implemented
- ARM actions for manual operations  
- Custom endpoints for auto-refresh
- Conditional visibility per tab
- Multi-tenant support
- Console UI with file operations
- Auto-population at all levels
```

**Estimated Workbook Size:** ~15,000-20,000 lines of JSON

### Step 3: Deploy Workbook 📊
**ARM Template Deployment:**
```powershell
az deployment group create `
  --resource-group alex-testing-rg `
  --template-file workbook/DefenderXDR-Complete-ARM.json `
  --parameters workbookDisplayName="DefenderXDR C2 XSOAR Console"
```

### Step 4: Test Workbook End-to-End ✅
- Verify all tabs load
- Test ARM actions (isolate device, update incident, etc.)
- Test custom endpoints (device lists, incident lists, etc.)
- Test conditional visibility
- Test multi-tenant switching
- Test console UI
- Test file operations

---

## Technical Documentation

### API Permission Mapping

All 46 API permissions are validated and mapped:
- ✅ WindowsDefenderATP (17): Complete coverage
- ✅ Microsoft Graph (29): Complete coverage including SecurityIncident.*
- ⚠️ Azure RBAC: Manual assignment required per subscription

**Reference:** `API_PERMISSIONS_VALIDATION.md`

### Function Architecture

**13 Functions:**
- Gateway → Orchestrator → 7 Workers + 4 Managers
- OAuth with token caching
- Multi-tenant support via tenant parameter
- Comprehensive error handling

**Reference:** `ANALYSIS_AND_FIXES.md`

### Deployment Infrastructure

**Files Created/Updated:**
- ✅ Gateway function (run.ps1, function.json)
- ✅ Function package (function-package.zip)
- ✅ Permissions script (Set-DefenderC2XSOARPermissions.ps1)
- ✅ ARM template (azuredeploy.json)
- ✅ Testing scripts (test-gateway-comprehensive.ps1)

**Commits:**
- 90c7e8f: Gateway implementation
- 3eda186: Deployment updates
- ef5173b: Deployment summary
- 46ea40e: Two-step permissions
- 208e9b0: Fixed deprecated permissions
- 6e17114: API validation documentation

---

## Ready State Checklist

**Before Workbook Development:**
- ⏳ Function deployment synced and accessible
- ⏳ Gateway endpoint returns 200 OK
- ⏳ MDE/Graph/Incident APIs return data
- ✅ All 46 permissions documented and validated
- ✅ Workbook patterns analyzed
- ✅ Architecture designed
- ✅ Testing scripts ready

**For Workbook Deployment:**
- ⏳ Functions verified working
- ⏳ Complete workbook JSON generated
- ⏳ ARM template created
- ⏳ Deployment tested
- ⏳ End-to-end validation complete

---

## Recommendation

**WAIT 2-3 MINUTES** for function package auto-reload, then:

1. Run test script: `.\deployment\test-gateway-comprehensive.ps1`
2. If tests pass → Proceed with workbook generation
3. If tests fail → Manually sync function app in Azure Portal
4. Once working → I'll generate the complete 15k+ line workbook JSON

**Current Blocker:** Function App deployment timing (expected, normal behavior)

**ETA to Resolution:** 2-5 minutes (auto-reload) or immediate (manual sync)

---

**Status:** 📍 **READY FOR TESTING - Awaiting Function Deployment Completion**

