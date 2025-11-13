# DefenderXDR v4.0 - Complete Architectural Overhaul Plan

**Date**: January 2025  
**Scope**: Production-Grade XDR Platform with Advanced Workbook  
**Complexity**: HIGH - Multi-phase implementation

---

## 🎯 Requirements Summary

### Core Architecture
1. **Simplified, Modular, Scalable** - Easy debugging and extension
2. **IntegrationBridge consolidation** - All shared logic in one place
3. **Batch Operations** - Multiple entities, queuing, error handling, cancellation
4. **Enhanced Error Handling** - Comprehensive logging, retry logic, graceful degradation

### Workbook Requirements
1. **Incident/Alert/Entity Dashboard** - Main view with filtered actions
2. **Multi-tenant Lighthouse** - Auto-populated parameters
3. **ARM Actions** (manual) + **Custom Endpoint** (auto-refresh listing)
4. **Advanced UI** - Grouping, nesting, conditional visibility, dropdowns
5. **File Operations** - Upload/download for Live Response library
6. **Console UI** - Interactive shell for Live Response and KQL hunting
7. **Best-in-class** - Learn from old workbooks, combine best features

---

## 📋 Phase 1: Architecture Redesign (Week 1)

### 1.1 Simplify Function Structure

**Current Issue**: Gateway → Orchestrator → Workers = 3 hops  
**New Design**: Gateway → Workers (direct routing)

**Benefits**:
- Faster response times
- Easier debugging
- Less code duplication
- Simpler error handling

**Implementation**:
```
functions/
├── DefenderXDRGateway/          [ENHANCED]
│   ├── run.ps1                  - Add direct worker routing
│   └── function.json
├── DefenderXDRMDEWorker/        [KEEP - Enhanced with batch]
├── DefenderXDRMDOWorker/        [KEEP - Enhanced with batch]
├── ... (all 9 workers)
└── modules/
    └── DefenderXDRIntegrationBridge/
        ├── AuthManager.psm1
        ├── BatchProcessor.psm1      [NEW]
        ├── QueueManager.psm1        [ENHANCED]
        ├── ErrorHandler.psm1        [NEW]
        ├── RetryLogic.psm1          [NEW]
        └── ... (all other modules)
```

**Decision**: Keep Or chestrator for backward compatibility, but enhance Gateway for direct routing

###

 1.2 IntegrationBridge Consolidation

**Purpose**: All workers import from single module location

**Current State**: ✅ Already done! All 21 modules in DefenderXDRIntegrationBridge/

**Enhancement Needed**:
- Add batch operation support to all modules
- Add error handling helpers
- Add retry logic
- Add cancellation token support

### 1.3 New Core Modules

**BatchProcessor.psm1** - Handle multi-entity operations:
```powershell
function Start-BatchOperation {
    param(
        [array]$Targets,          # Device IDs, User IDs, etc.
        [string]$Action,
        [hashtable]$CommonParams,
        [int]$MaxConcurrency = 10,
        [int]$RetryAttempts = 3
    )
    
    # Queue management
    # Parallel execution with throttling
    # Error tracking per target
    # Cancellation support
    # Progress reporting
}
```

**ErrorHandler.psm1** - Centralized error handling:
```powershell
function New-ErrorResponse {
    param(
        [string]$ErrorMessage,
        [string]$ErrorCode,
        [hashtable]$Context,
        [bool]$Retryable
    )
}

function Get-RetryStrategy {
    # Exponential backoff
    # Circuit breaker pattern
}
```

**CancellationManager.psm1** - Operation cancellation:
```powershell
function Register-CancellableOperation {
    # Store operation in Table Storage
    # Return cancellation token
}

function Request-OperationCancellation {
    # Mark operation for cancellation
    # Workers check this token
}
```

---

## 📋 Phase 2: Batch Operations & Queuing (Week 2)

### 2.1 Enhanced QueueManager

**Upgrade existing QueueManager.psm1**:

```powershell
# Add batch operation queuing
function Add-BatchOperationToQueue {
    param(
        [string]$TenantId,
        [string]$Service,
        [string]$Action,
        [array]$Targets,              # Multiple entities
        [hashtable]$CommonParams,
        [string]$OperationId,
        [string]$SubmittedBy
    )
    
    # Create operation record
    # Split into individual tasks
    # Queue each task with operation ID
    # Return operation tracking info
}

function Get-BatchOperationStatus {
    param([string]$OperationId)
    
    # Aggregate status from all tasks
    # Calculate progress percentage
    # Return success/failure counts
}

function Cancel-BatchOperation {
    param([string]$OperationId)
    
    # Set cancellation flag
    # Stop processing new tasks
    # Allow running tasks to complete
}
```

### 2.2 Worker Batch Support

**Enhance ALL 9 workers with**:

```powershell
# In each Worker/run.ps1

# Check if batch operation
if ($requestData.batch -eq $true -and $requestData.targets) {
    
    # Option 1: Sync (small batches < 10)
    if ($requestData.async -ne $true -and $requestData.targets.Count -le 10) {
        $results = @()
        foreach ($target in $requestData.targets) {
            try {
                $result = Invoke-SingleAction -Target $target -Action $action
                $results += @{
                    target = $target
                    success = $true
                    data = $result
                }
            } catch {
                $results += @{
                    target = $target
                    success = $false
                    error = $_.Exception.Message
                }
            }
        }
        return $results
    }
    
    # Option 2: Async (large batches or always async)
    else {
        $operationId = Add-BatchOperationToQueue `
            -TenantId $tenantId `
            -Service $service `
            -Action $action `
            -Targets $requestData.targets `
            -CommonParams $commonParams
        
        return @{
            operationId = $operationId
            queuedCount = $requestData.targets.Count
            statusUrl = "/api/Gateway/batch/status?operationId=$operationId"
        }
    }
}
```

### 2.3 Status Tracking

**Enhance StatusTracker.psm1**:

```powershell
function Update-BatchOperationStatus {
    param(
        [string]$OperationId,
        [string]$TaskId,
        [string]$Status,        # Queued, Running, Completed, Failed, Cancelled
        [hashtable]$Result
    )
    
    # Update Table Storage
    # Aggregate operation-level status
    # Trigger notifications if needed
}

function Get-OperationHistory {
    param(
        [string]$TenantId,
        [string]$Service,
        [int]$Days = 7
    )
    
    # Query Table Storage
    # Return operation history with stats
}
```

---

## 📋 Phase 3: Enhanced Gateway with Direct Routing (Week 3)

### 3.1 Gateway Enhancement

**Add to DefenderXDRGateway/run.ps1**:

```powershell
# NEW: Action Discovery Endpoint
if ($Request.Method -eq "GET" -and $Request.Url -match "/actions$") {
    # Return all 213 actions with metadata
    $metadata = Get-ActionMetadata -Service $service
    return $metadata
}

# NEW: Parameter Validation Endpoint
if ($Request.Method -eq "POST" -and $Request.Url -match "/validate$") {
    # Validate action parameters before execution
    $validation = Test-ActionParameters -Service $service -Action $action -Parameters $params
    return $validation
}

# NEW: Batch Operations Endpoint
if ($Request.Method -eq "POST" -and $Request.Url -match "/batch$") {
    # Handle batch operations
    if ($async) {
        # Queue for async processing
        $operationId = Add-BatchOperationToQueue...
        return @{operationId = $operationId; statusUrl = "..."}
    } else {
        # Process synchronously
        $results = Invoke-BatchOperation...
        return $results
    }
}

# NEW: Batch Status Endpoint
if ($Request.Method -eq "GET" -and $Request.Url -match "/batch/status$") {
    $operationId = $Request.Query.operationId
    $status = Get-BatchOperationStatus -OperationId $operationId
    return $status
}

# NEW: Cancel Batch Endpoint
if ($Request.Method -eq "POST" -and $Request.Url -match "/batch/cancel$") {
    $operationId = $Request.Body.operationId
    $result = Cancel-BatchOperation -OperationId $operationId
    return $result
}

# EXISTING: Forward to Orchestrator (keep for compatibility)
# OR NEW: Direct worker invocation
$worker = Get-WorkerForService -Service $service
$result = Invoke-RestMethod -Uri $worker -Method Post -Body $requestData
return $result
```

---

## 📋 Phase 4: Advanced Workbook (Week 4-5)

### 4.1 Workbook Structure

**Based on best-in-class examples**:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "# DefenderXDR - Unified Investigation & Remediation Console"
      }
    },
    {
      "type": 9,
      "content": {
        "version": "ParametersItem/1.0",
        "parameters": [
          {
            "id": "tenant-param",
            "version": "KqlParameterItem/1.0",
            "name": "TenantId",
            "type": 2,
            "query": "resources | where type =~ 'microsoft.operationalinsights/workspaces' | project id, name",
            "typeSettings": {
              "additionalResourceOptions": ["value::1"],
              "showDefault": false
            }
          },
          {
            "id": "function-app-param",
            "name": "FunctionApp",
            "type": 5,
            "query": "resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | project id, name",
            "typeSettings": {
              "resourceTypeFilter": {
                "microsoft.web/sites": true
              }
            }
          }
        ]
      }
    },
    {
      "type": 12,
      "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "title": "🚨 Incidents & Alerts",
        "items": [
          // Incident list (Custom Endpoint - auto-refresh)
          // Alert list (Custom Endpoint - auto-refresh)
          // Entity selector (dropdown from above lists)
          // Filtered actions based on selected entity
        ]
      }
    }
  ]
}
```

### 4.2 Key Features

**1. Multi-Tenant Auto-Population**:
- Workspace selector → TenantId auto-discovered
- Lighthouse environments supported
- Subscription/ResourceGroup from workspace

**2. Incident/Alert/Entity Dashboard**:
```
┌─────────────────────────────────────────────────────────────┐
│ 🚨 Incidents (Auto-refresh 30s)                             │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ [Select Incident] ▼                                    │   │
│ │ INC001 - Ransomware Detection                          │   │
│ │ INC002 - Phishing Campaign                             │   │
│ └───────────────────────────────────────────────────────┘   │
│                                                              │
│ 📍 Entities in Selected Incident                            │
│ ┌──────┬──────────┬────────┬──────────┐                    │
│ │Device│User      │IP      │File      │                    │
│ ├──────┼──────────┼────────┼──────────┤                    │
│ │☑ PC01│☑ user@...│☐ 1.2...│☐ mal.exe │                    │
│ └──────┴──────────┴────────┴──────────┘                    │
│                                                              │
│ ⚡ Available Actions (Filtered by Entity Type)              │
│ [Isolate Device] [Disable User] [Block IP] [Quarantine]    │
└─────────────────────────────────────────────────────────────┘
```

**3. Live Response Console**:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "tabs",
    "links": [
      {
        "id": "console-tab",
        "cellValue": "selectedTab",
        "linkTarget": "parameter",
        "linkLabel": "🖥️ Live Response",
        "subTarget": "console"
      }
    ]
  }
},
{
  "type": 1,
  "content": {
    "json": "### Live Response Console\n\n**Device**: {SelectedDevice}\n\n**Commands**: `dir`, `getfile`, `putfile`, `run`, `processes`, `registry`"
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "console"
  }
},
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionApp}.azurewebsites.net/api/Gateway\",\"body\":\"{\\\"service\\\":\\\"MDE\\\",\\\"action\\\":\\\"StartSession\\\",\\\"tenantId\\\":\\\"{TenantId}\\\",\\\"machineId\\\":\\\"{SelectedDevice}\\\"}\"}",
    "queryType": 10
  }
}
```

**4. Advanced Hunting Console**:
```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Advanced Hunting                                          │
│                                                              │
│ KQL Query:                                                   │
│ ┌──────────────────────────────────────────────────────┐    │
│ │ DeviceProcessEvents                                   │    │
│ │ | where FileName =~ "powershell.exe"                  │    │
│ │ | where ProcessCommandLine contains "Invoke-"         │    │
│ │ | summarize count() by DeviceName                     │    │
│ └──────────────────────────────────────────────────────┘    │
│                                                              │
│ [Run Query] [Save Query] [Export Results]                   │
│                                                              │
│ Results: (Auto-refresh disabled for hunt queries)           │
│ ┌──────────────┬───────┐                                    │
│ │ DeviceName   │ Count │                                    │
│ ├──────────────┼───────┤                                    │
│ │ DESKTOP-001  │ 23    │                                    │
│ └──────────────┴───────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

**5. File Operations (Library)**:
```json
// Workaround for file upload: Use storage account
{
  "type": 1,
  "content": {
    "json": "### File Upload Workflow\n\n1. Upload file to storage account blob container\n2. Get SAS URL\n3. Function app downloads from blob\n4. Function app uploads to MDE Live Response library"
  }
},
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkLabel": "📤 Upload to Blob",
      "linkTarget": "OpenBlade",
      "linkIsContextBlade": true,
      "bladeOpenContext": {
        "bladeName": "StorageAccountBlade"
      }
    }]
  }
},
// Then ARM action to transfer from blob to MDE library
{
  "type": 11,
  "content": {
    "armActionContext": {
      "path": "https://{FunctionApp}.azurewebsites.net/api/Gateway",
      "body": "{\"service\":\"MDE\",\"action\":\"TransferFileToLibrary\",\"blobUrl\":\"{BlobSasUrl}\",\"fileName\":\"{FileName}\"}",
      "httpMethod": "POST"
    }
  }
}
```

### 4.3 Conditional Visibility Rules

```json
{
  "conditionalVisibility": {
    "parameterName": "SelectedEntityType",
    "comparison": "isEqualTo",
    "value": "Device"
  }
}

// Show device actions only when device selected
// Show user actions only when user selected
// Show file actions only when file selected
```

### 4.4 ARM Actions vs Custom Endpoint

**Pattern 1: Custom Endpoint (Listing - Auto-Refresh)**
```json
{
  "queryType": 10,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionApp}.azurewebsites.net/api/Gateway\",\"body\":\"{\\\"service\\\":\\\"MDE\\\",\\\"action\\\":\\\"GETDEVICES\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.data[*]\"}}]}",
  "timeContextFromParameter": "TimeRange"
}
```

**Pattern 2: ARM Action (Manual Execution)**
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "🔒 Isolate Device",
      "armActionContext": {
        "path": "https://{FunctionApp}.azurewebsites.net/api/Gateway",
        "headers": [{"name": "Content-Type", "value": "application/json"}],
        "body": "{\"service\":\"MDE\",\"action\":\"ISOLATEDEVICE\",\"tenantId\":\"{TenantId}\",\"machineId\":\"{SelectedDevice}\",\"comment\":\"Incident response\"}",
        "httpMethod": "POST",
        "title": "Isolate Device",
        "description": "Network isolate the selected device",
        "runLabel": "Isolate"
      }
    }]
  }
}
```

---

## 📋 Phase 5: Standalone Script Revival (Week 6)

### 5.1 Update Standalone Script

**File**: `standalone/Start-DefenderXDRLocal.ps1`

**Purpose**: Allow running XDR actions locally without Azure deployment

**Enhancements**:
- Use ALL new IntegrationBridge modules
- Support batch operations
- Interactive console mode
- Export results to CSV/JSON
- Integration with new Gateway APIs

```powershell
<#
.SYNOPSIS
    DefenderXDR Standalone Script - Run XDR operations locally
    
.EXAMPLE
    .\Start-DefenderXDRLocal.ps1 -Service MDE -Action ISOLATEDEVICE -MachineId "abc123" -TenantId "xxx"
    
.EXAMPLE
    .\Start-DefenderXDRLocal.ps1 -Interactive
#>

param(
    [string]$Service,
    [string]$Action,
    [string]$TenantId,
    [hashtable]$Parameters,
    [switch]$Interactive,
    [switch]$Batch,
    [array]$Targets
)

# Import all IntegrationBridge modules
$modulePath = "$PSScriptRoot\modules\DefenderXDRIntegrationBridge"
Get-ChildItem "$modulePath\*.psm1" | ForEach-Object {
    Import-Module $_.FullName -Force
}

# Interactive mode
if ($Interactive) {
    while ($true) {
        $service = Read-Host "Service (MDE/MDO/MCAS/MDI/EntraID/Intune/Azure)"
        $action = Read-Host "Action"
        $tenantId = Read-Host "Tenant ID"
        
        # Execute action
        $result = Invoke-XDRAction -Service $service -Action $action -TenantId $tenantId
        
        Write-Host "`n$($result | ConvertTo-Json -Depth 10)`n" -ForegroundColor Cyan
        
        $continue = Read-Host "Continue? (Y/N)"
        if ($continue -ne "Y") { break }
    }
}

# Batch mode
if ($Batch) {
    $results = Start-BatchOperation -Service $Service -Action $Action -Targets $Targets -TenantId $TenantId
    $results | Export-Csv "batch-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation
}

# Single action
else {
    $result = Invoke-XDRAction -Service $Service -Action $Action -TenantId $TenantId -Parameters $Parameters
    return $result
}
```

---

## 📋 Phase 6: Documentation & Deployment (Week 7)

### 6.1 Update All Documentation

1. **README.md** - New architecture diagram, batch operations
2. **ARCHITECTURE.md** - Gateway → Workers direct routing, IntegrationBridge modules
3. **DEPLOYMENT_GUIDE.md** - Updated with new features
4. **WORKBOOK_GUIDE.md** - Complete workbook documentation
5. **BATCH_OPERATIONS_GUIDE.md** - How to use batch features
6. **API_REFERENCE.md** - All 213 actions + batch endpoints

### 6.2 Update ARM Templates

**deployment/azuredeploy.json**:
- Add storage account for batch operations (if not already present)
- Update function app settings
- Add new environment variables for batch processing

### 6.3 Update Deployment Package

**deployment/create-deployment-package.ps1**:
- Include all new modules
- Include updated workers
- Include enhanced gateway
- Test package creation

### 6.4 One-Click Deployment

**Update Deploy to Azure button**:
- Ensure all new features are included
- Test end-to-end deployment
- Verify storage account creation
- Verify batch operations work

---

## 📋 Implementation Timeline

| Week | Phase | Deliverables |
|------|-------|--------------|
| 1 | Architecture Redesign | New modules, enhanced IntegrationBridge |
| 2 | Batch Operations | QueueManager upgrade, worker batch support |
| 3 | Enhanced Gateway | Direct routing, new endpoints, action discovery |
| 4-5 | Advanced Workbook | Incident dashboard, console, file ops, best-in-class UI |
| 6 | Standalone Script | Updated local execution script |
| 7 | Documentation & Deployment | All docs updated, ARM templates, deployment package |

---

## 🎯 Success Criteria

1. ✅ **Batch operations working** - Can isolate 100 devices in one API call
2. ✅ **Error handling robust** - Failed actions don't crash the operation
3. ✅ **Cancellation works** - Can stop long-running batch operations
4. ✅ **Workbook incident-centric** - Start from incident, filter actions by entity
5. ✅ **Multi-tenant support** - Auto-populated parameters work across tenants
6. ✅ **File operations** - Can upload/download files for Live Response
7. ✅ **Console UI working** - Interactive shell for Live Response and KQL
8. ✅ **All 213 actions accessible** - No functionality lost
9. ✅ **Deployment successful** - One-click deploy works end-to-end
10. ✅ **Documentation complete** - Every feature documented with examples

---

**This is a 7-week project. Should we proceed with Phase 1?**
