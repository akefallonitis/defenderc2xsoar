# Workbook Integration APIs

## Overview
APIs designed for Azure Workbook integration to enable dynamic action discovery, parameter validation, and bulk operations.

## 1. Action Discovery API

**Purpose**: Allow workbook to dynamically discover all available actions and their parameters

**Endpoint**: `GET /api/Gateway/actions`  
**Method**: GET  
**Authentication**: Function Key

### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tenantId | string | Yes | Target tenant ID |
| service | string | No | Filter by service (MDE, MDO, MCAS, MDI, EntraID, Intune, Azure) |
| category | string | No | Filter by category (device, email, alert, incident, user, etc.) |

### Response Format
```json
{
  "success": true,
  "data": {
    "totalActions": 213,
    "services": [
      {
        "name": "MDE",
        "displayName": "Microsoft Defender for Endpoint",
        "actionCount": 52,
        "actions": [
          {
            "name": "ISOLATEDEVICE",
            "displayName": "Isolate Device",
            "description": "Network isolate a device to prevent lateral movement",
            "category": "device",
            "requiredParameters": [
              {
                "name": "machineId",
                "type": "string",
                "description": "Device ID or device name",
                "example": "abc123..."
              },
              {
                "name": "isolationType",
                "type": "string",
                "enum": ["Full", "Selective"],
                "default": "Full",
                "description": "Full blocks all connections, Selective allows Outlook/Teams"
              },
              {
                "name": "comment",
                "type": "string",
                "description": "Reason for isolation",
                "example": "Suspected malware infection"
              }
            ],
            "optionalParameters": [],
            "responseFormat": "machineAction"
          }
        ]
      }
    ]
  }
}
```

### Implementation Plan

**Add to Gateway** (`functions/DefenderXDRGateway/run.ps1`):

```powershell
# After line 89 (after authentication), add:

# Action Discovery Endpoint
if ($Request.Method -eq "GET" -and $Request.Url -match "/actions$") {
    Write-Host "📋 Action discovery request"
    
    $tenantId = $Request.Query.tenantId
    $serviceFilter = $Request.Query.service
    $categoryFilter = $Request.Query.category
    
    if (-not $tenantId) {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = 400
            Body = @{
                success = $false
                error = "tenantId parameter required"
            } | ConvertTo-Json
        })
        return
    }
    
    # Load action metadata
    $actionsMetadata = Get-Content "$PSScriptRoot\..\modules\DefenderXDRIntegrationBridge\ActionMetadata.json" -Raw | ConvertFrom-Json
    
    # Filter by service/category if requested
    if ($serviceFilter) {
        $actionsMetadata = $actionsMetadata | Where-Object { $_.service -eq $serviceFilter }
    }
    if ($categoryFilter) {
        $actionsMetadata.services | ForEach-Object {
            $_.actions = $_.actions | Where-Object { $_.category -eq $categoryFilter }
        }
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 200
        Body = @{
            success = $true
            data = $actionsMetadata
        } | ConvertTo-Json -Depth 10
    })
    return
}
```

## 2. Parameter Validation API

**Purpose**: Validate action parameters before submission (reduce errors in workbook)

**Endpoint**: `POST /api/Gateway/validate`  
**Method**: POST  
**Authentication**: Function Key

### Request Body
```json
{
  "tenantId": "xxx",
  "service": "MDE",
  "action": "ISOLATEDEVICE",
  "parameters": {
    "machineId": "abc123",
    "isolationType": "Full",
    "comment": "Test"
  }
}
```

### Response Format
```json
{
  "success": true,
  "valid": true,
  "errors": [],
  "warnings": [
    "machineId looks like a test value - verify device exists"
  ]
}
```

### Implementation Plan

**Add ValidationHelper function** (`functions/modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1`):

```powershell
function Test-ActionParameters {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Service,
        
        [Parameter(Mandatory=$true)]
        [string]$Action,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters,
        
        [Parameter(Mandatory=$false)]
        [string]$TenantId
    )
    
    $errors = @()
    $warnings = @()
    
    # Load action metadata
    $metadata = Get-ActionMetadata -Service $Service -Action $Action
    
    if (-not $metadata) {
        return @{
            valid = $false
            errors = @("Unknown action: $Service/$Action")
            warnings = @()
        }
    }
    
    # Check required parameters
    foreach ($reqParam in $metadata.requiredParameters) {
        if (-not $Parameters.ContainsKey($reqParam.name)) {
            $errors += "Missing required parameter: $($reqParam.name)"
        } elseif ([string]::IsNullOrWhiteSpace($Parameters[$reqParam.name])) {
            $errors += "Required parameter '$($reqParam.name)' cannot be empty"
        }
    }
    
    # Validate parameter types and formats
    foreach ($param in $Parameters.Keys) {
        $paramMeta = $metadata.requiredParameters + $metadata.optionalParameters | 
            Where-Object { $_.name -eq $param } | Select-Object -First 1
        
        if ($paramMeta) {
            # Type validation
            if ($paramMeta.type -eq "email" -and $Parameters[$param] -notmatch "^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$") {
                $errors += "Parameter '$param' must be a valid email address"
            }
            
            # Enum validation
            if ($paramMeta.enum -and $Parameters[$param] -notin $paramMeta.enum) {
                $errors += "Parameter '$param' must be one of: $($paramMeta.enum -join ', ')"
            }
            
            # Format validation
            if ($param -match "machineId" -and $Parameters[$param] -match "^(abc|test|xxx)") {
                $warnings += "Parameter '$param' looks like a test value - verify device exists"
            }
        }
    }
    
    return @{
        valid = ($errors.Count -eq 0)
        errors = $errors
        warnings = $warnings
    }
}
```

## 3. Bulk Actions API

**Purpose**: Submit multiple actions in one request (e.g., isolate 10 devices)

**Endpoint**: `POST /api/Gateway/bulk`  
**Method**: POST  
**Authentication**: Function Key

### Request Body
```json
{
  "tenantId": "xxx",
  "service": "MDE",
  "action": "ISOLATEDEVICE",
  "targets": [
    {"machineId": "device1", "comment": "Incident 123"},
    {"machineId": "device2", "comment": "Incident 123"},
    {"machineId": "device3", "comment": "Incident 123"}
  ],
  "async": true
}
```

### Response Format (Async)
```json
{
  "success": true,
  "operationId": "bulk-20250113-123456-abc",
  "queuedCount": 3,
  "statusUrl": "/api/Gateway/bulk/status?operationId=bulk-20250113-123456-abc"
}
```

### Response Format (Sync)
```json
{
  "success": true,
  "results": [
    {
      "target": {"machineId": "device1"},
      "success": true,
      "actionId": "action-123"
    },
    {
      "target": {"machineId": "device2"},
      "success": false,
      "error": "Device not found"
    }
  ],
  "successCount": 1,
  "errorCount": 1
}
```

### Implementation Plan

**Add to Orchestrator** (`functions/DefenderXDROrchestrator/run.ps1`):

```powershell
# After service routing logic, add bulk handler:

if ($requestData.bulk -eq $true -and $requestData.targets) {
    Write-Host "🔄 Processing bulk operation: $($requestData.targets.Count) targets"
    
    if ($requestData.async -eq $true) {
        # Queue for async processing
        $operationId = "bulk-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(New-Guid | Select-Object -ExpandProperty Guid -First 8)"
        
        Add-BulkOperationToQueue -TenantId $tenantId `
            -OperationId $operationId `
            -Service $service `
            -Action $action `
            -Targets $requestData.targets
        
        $responseBody = @{
            success = $true
            operationId = $operationId
            queuedCount = $requestData.targets.Count
            statusUrl = "/api/Gateway/bulk/status?operationId=$operationId"
        }
    } else {
        # Execute synchronously
        $results = @()
        $successCount = 0
        $errorCount = 0
        
        foreach ($target in $requestData.targets) {
            try {
                # Merge common params with target-specific params
                $params = @{
                    tenantId = $tenantId
                    action = $action
                } + $target
                
                # Invoke worker
                $result = Invoke-Worker -Service $service -Parameters $params
                
                $results += @{
                    target = $target
                    success = $true
                    data = $result
                }
                $successCount++
            } catch {
                $results += @{
                    target = $target
                    success = $false
                    error = $_.Exception.Message
                }
                $errorCount++
            }
        }
        
        $responseBody = @{
            success = $true
            results = $results
            successCount = $successCount
            errorCount = $errorCount
        }
    }
}
```

## 4. Action Metadata File

**Create**: `functions/modules/DefenderXDRIntegrationBridge/ActionMetadata.json`

```json
{
  "totalActions": 213,
  "version": "3.0.0",
  "lastUpdated": "2025-01-13",
  "services": [
    {
      "name": "MDE",
      "displayName": "Microsoft Defender for Endpoint",
      "description": "Endpoint detection, response, and threat intel",
      "actionCount": 52,
      "categories": ["device", "investigation", "liveresponse", "indicator", "hunting", "incident", "alert"],
      "actions": [
        {
          "name": "ISOLATEDEVICE",
          "displayName": "Isolate Device",
          "description": "Network isolate a device to prevent lateral movement",
          "category": "device",
          "apiEndpoint": "machines/{machineId}/isolate",
          "requiredParameters": [
            {"name": "machineId", "type": "string", "description": "Device ID or name"},
            {"name": "isolationType", "type": "string", "enum": ["Full", "Selective"], "default": "Full"},
            {"name": "comment", "type": "string", "description": "Reason for isolation"}
          ]
        }
      ]
    }
  ]
}
```

## Implementation Steps

1. ✅ Create ActionMetadata.json with all 213 actions
2. ✅ Add GET /api/Gateway/actions endpoint to Gateway
3. ✅ Add POST /api/Gateway/validate endpoint to Gateway
4. ✅ Add Test-ActionParameters function to ValidationHelper
5. ✅ Add bulk operation handler to Orchestrator
6. ✅ Add POST /api/Gateway/bulk endpoint
7. ✅ Test all 3 new APIs with sample requests
8. ✅ Update workbook with dynamic action dropdown

## Testing

```powershell
# Test Action Discovery
$actionsResponse = Invoke-RestMethod `
    -Uri "https://your-app.azurewebsites.net/api/Gateway/actions?tenantId=xxx&service=MDE" `
    -Headers @{"x-functions-key"="your-key"}

# Test Parameter Validation
$validateResponse = Invoke-RestMethod `
    -Uri "https://your-app.azurewebsites.net/api/Gateway/validate" `
    -Method Post `
    -Headers @{"x-functions-key"="your-key"} `
    -Body (@{
        tenantId="xxx"
        service="MDE"
        action="ISOLATEDEVICE"
        parameters=@{machineId="test"; isolationType="Full"; comment="Test"}
    } | ConvertTo-Json)

# Test Bulk Actions
$bulkResponse = Invoke-RestMethod `
    -Uri "https://your-app.azurewebsites.net/api/Gateway/bulk" `
    -Method Post `
    -Headers @{"x-functions-key"="your-key"} `
    -Body (@{
        tenantId="xxx"
        service="MDE"
        action="ISOLATEDEVICE"
        targets=@(
            @{machineId="device1"; isolationType="Full"; comment="Bulk isolation"}
            @{machineId="device2"; isolationType="Full"; comment="Bulk isolation"}
        )
        async=$false
    } | ConvertTo-Json)
```

## Benefits for Workbook

1. **Dynamic Action Discovery**: Workbook dropdown auto-populates with available actions
2. **Parameter Hints**: Workbook shows required parameters and types for selected action
3. **Client-Side Validation**: Validate before sending (faster UX)
4. **Bulk Operations**: Execute same action on multiple targets efficiently
5. **Async Processing**: Large bulk operations don't timeout (use queue)
6. **Error Reduction**: Validation reduces invalid API calls
