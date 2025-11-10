# DefenderXDR v2.3.0 - Worker Pattern Architecture

## 🎯 Overview

v2.3.0 adopts a **specialized worker pattern** where each Microsoft security product has its own dedicated Azure Function. This architecture:

✅ **Direct HTTP responses** - Each worker returns JSON directly (workbook compatible)  
✅ **Product specialization** - One function per product = clearer responsibility  
✅ **Parallel scaling** - Each worker scales independently based on load  
✅ **Easier debugging** - Issues isolated to specific product workers  
✅ **Workbook integration** - Direct endpoint calls from Azure Workbook queries  

## 🏗️ Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    Client (XSOAR / Workbook)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┴──────────────┐
         │                            │
    ┌────▼────┐              ┌────────▼────────┐
    │ Direct  │              │ MainOrchestrator│
    │ Worker  │              │   (Router)      │
    │  Call   │              └────────┬────────┘
    └────┬────┘                       │
         │              ┌─────────────┼──────────────┐
         │              │             │              │
    ┌────▼──────┐  ┌───▼───┐    ┌───▼───┐     ┌───▼───┐
    │ MDEWorker │  │  MDO  │    │  MDC  │ ... │ Azure │
    │  (MDE)    │  │Worker │    │Worker │     │Worker │
    └───────────┘  └───────┘    └───────┘     └───────┘
         │              │             │              │
         └──────────────┴─────────────┴──────────────┘
                        │
              ┌─────────▼─────────┐
              │   AuthManager     │
              │ (Token Caching)   │
              └───────────────────┘
```

## 📦 Function Structure

### Worker Functions (7 total)

Each worker is a dedicated Azure Function with:
- **Single responsibility**: One Microsoft product
- **Direct HTTP response**: Returns JSON immediately
- **Independent scaling**: Scales based on product usage
- **Shared infrastructure**: Uses AuthManager, ValidationHelper, LoggingHelper

#### 1. MDEWorker (Microsoft Defender for Endpoint)
**Endpoint**: `/api/MDEWorker`

**Actions**: Device isolation, antivirus scans, threat intelligence, hunting, incidents, live response

**Example**:
```json
POST /api/MDEWorker
{
  "action": "IsolateDevice",
  "tenantId": "xxx",
  "deviceIds": "machine1,machine2",
  "comment": "Compromised devices"
}
```

**Response**:
```json
{
  "success": true,
  "action": "IsolateDevice",
  "tenantId": "xxx",
  "deviceCount": 2,
  "actionIds": ["id1", "id2"],
  "timestamp": "2025-11-10T12:34:56Z"
}
```

#### 2. MDOWorker (Microsoft Defender for Office 365)
**Endpoint**: `/api/MDOWorker`

**Actions**: Email remediation, threat submission (email/URL/file), mail forwarding rule removal

**Example**:
```json
POST /api/MDOWorker
{
  "action": "RemediateEmail",
  "tenantId": "xxx",
  "messageId": "email-id",
  "remediationType": "SoftDelete"
}
```

#### 3. MDCWorker (Microsoft Defender for Cloud)
**Endpoint**: `/api/MDCWorker`

**Actions**: Security alerts, recommendations, secure score, compliance, Defender plans, JIT access

**Example**:
```json
POST /api/MDCWorker
{
  "action": "GetSecurityAlerts",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "filter": "properties/severity eq 'High'"
}
```

#### 4. MDIWorker (Microsoft Defender for Identity)
**Endpoint**: `/api/MDIWorker`

**Actions**: Identity alerts, lateral movement paths, exposed credentials, suspicious activities

**Example**:
```json
POST /api/MDIWorker
{
  "action": "GetLateralMovementPaths",
  "tenantId": "xxx"
}
```

#### 5. EntraIDWorker (Identity & Access Management)
**Endpoint**: `/api/EntraIDWorker`

**Actions**: User management, password resets, session revocation, risk management, conditional access

**Example**:
```json
POST /api/EntraIDWorker
{
  "action": "RevokeSessions",
  "tenantId": "xxx",
  "userId": "user@domain.com"
}
```

#### 6. IntuneWorker (Device Management)
**Endpoint**: `/api/IntuneWorker`

**Actions**: Remote lock, wipe, retire, sync, Defender scan, managed device queries

**Example**:
```json
POST /api/IntuneWorker
{
  "action": "RemoteLock",
  "tenantId": "xxx",
  "deviceId": "intune-device-id"
}
```

#### 7. AzureWorker (Infrastructure Security)
**Endpoint**: `/api/AzureWorker`

**Actions**: NSG rules, VM operations, storage security, public IP removal

**Example**:
```json
POST /api/AzureWorker
{
  "action": "StopVM",
  "tenantId": "xxx",
  "subscriptionId": "sub-id",
  "resourceGroup": "rg-name",
  "vmName": "vm-name"
}
```

### Orchestrator Function

#### MainOrchestrator
**Endpoint**: `/api/MainOrchestrator`

**Purpose**: Intelligent router that forwards requests to appropriate worker

**Example**:
```json
POST /api/MainOrchestrator
{
  "service": "MDE",
  "action": "IsolateDevice",
  "tenantId": "xxx",
  "deviceIds": "machine1"
}
```

Routes to → `MDEWorker`

### Legacy Compatibility

#### DefenderC2Dispatcher
**Endpoint**: `/api/DefenderC2Dispatcher`

**Purpose**: Backward compatibility with existing workbooks and XSOAR playbooks

**Status**: Maintained for legacy support, new integrations should use workers directly

## 🔄 Request Flow Options

### Option 1: Direct Worker Call (Recommended for Workbooks)
```
Workbook → MDEWorker → MDE API → Response
```

**Benefits**:
- Fastest (no routing overhead)
- Simplest debugging
- Clearest Azure Monitor logs

**Use When**:
- Calling from Azure Workbook
- You know exactly which product
- Maximum performance needed

### Option 2: Orchestrator Routing (Recommended for XSOAR)
```
XSOAR → MainOrchestrator → MDEWorker → MDE API → Response
```

**Benefits**:
- Single endpoint to manage
- Service parameter routing
- Abstraction for clients

**Use When**:
- Calling from XSOAR playbooks
- Dynamic service selection
- Unified API surface preferred

### Option 3: Legacy Dispatcher (Backward Compatibility)
```
Old Workbook → DefenderC2Dispatcher → MDE API → Response
```

**Benefits**:
- Zero breaking changes
- Existing workbooks work unchanged

**Use When**:
- Migrating gradually
- Legacy workbooks in use

## 🎨 Response Format

All workers return consistent JSON:

```json
{
  "success": true | false,
  "action": "ActionName",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "timestamp": "2025-11-10T12:34:56.789Z",
  "result": { /* action-specific data */ },
  "error": "error message" // only if success = false
}
```

## 📊 Workbook Integration

### Direct Worker Queries

```kql
// Call MDEWorker directly from workbook
let FunctionUrl = "https://your-app.azurewebsites.net/api/MDEWorker";
let FunctionKey = "your-function-key";
let TenantId = "your-tenant-id";

evaluate bag_pack("action", "GetAllDevices", "tenantId", TenantId)
| evaluate azure_function(FunctionUrl, FunctionKey)
| project devices = tostring(devices)
| mv-expand device = parse_json(devices)
| project 
    DeviceName = device.computerDnsName,
    RiskScore = device.riskScore,
    HealthStatus = device.healthStatus,
    LastSeen = device.lastSeen
```

### Orchestrator Queries

```kql
// Call via MainOrchestrator
evaluate bag_pack(
    "service", "MDE",
    "action", "GetAllDevices", 
    "tenantId", TenantId
)
| evaluate azure_function(OrchestratorUrl, FunctionKey)
```

## 🚀 Deployment

### Azure Function App Structure
```
defenderxdr-functions/
├── MDEWorker/
│   ├── function.json
│   └── run.ps1
├── MDOWorker/
│   ├── function.json
│   └── run.ps1
├── MDCWorker/
├── MDIWorker/
├── EntraIDWorker/
├── IntuneWorker/
├── AzureWorker/
├── MainOrchestrator/
├── DefenderC2Dispatcher/  (legacy)
└── DefenderXDRC2XSOAR/    (shared module)
    ├── AuthManager.psm1
    ├── ValidationHelper.psm1
    ├── LoggingHelper.psm1
    └── [19 service modules]
```

### ARM Template Updates

```json
{
  "resources": [
    {
      "type": "Microsoft.Web/sites/functions",
      "name": "MDEWorker",
      "properties": {
        "config": {
          "bindings": [
            {
              "type": "httpTrigger",
              "authLevel": "function"
            }
          ]
        }
      }
    },
    // Repeat for all 7 workers + MainOrchestrator
  ]
}
```

## 📈 Scaling Characteristics

| Worker | Expected Load | Scaling Strategy |
|--------|--------------|------------------|
| MDEWorker | High (alerts, devices) | Aggressive auto-scale |
| MDOWorker | Medium (email incidents) | Moderate auto-scale |
| MDCWorker | Low (compliance checks) | Conservative auto-scale |
| MDIWorker | Low (identity threats) | Conservative auto-scale |
| EntraIDWorker | Medium (user mgmt) | Moderate auto-scale |
| IntuneWorker | Low (device mgmt) | Conservative auto-scale |
| AzureWorker | Low (infra changes) | Conservative auto-scale |

Each worker can scale independently based on its specific load patterns.

## 🛡️ Security Benefits

1. **Isolation**: Compromise of one worker doesn't affect others
2. **Least Privilege**: Each worker can have product-specific permissions
3. **Audit Trail**: Clear logs per product (MDEWorker.log, MDOWorker.log, etc.)
4. **Rate Limiting**: Per-worker rate limits prevent cascading failures

## 🔍 Monitoring

### Application Insights Queries

**Worker Performance**:
```kql
requests
| where name in ("MDEWorker", "MDOWorker", "MDCWorker", "MDIWorker", "EntraIDWorker", "IntuneWorker", "AzureWorker")
| summarize 
    Count=count(), 
    AvgDuration=avg(duration), 
    P95Duration=percentile(duration, 95) 
  by name, bin(timestamp, 5m)
| render timechart
```

**Worker Success Rate**:
```kql
requests
| where name endswith "Worker"
| summarize 
    Total=count(), 
    Success=countif(success == true),
    Failures=countif(success == false)
  by name
| extend SuccessRate = Success * 100.0 / Total
| project name, SuccessRate, Total, Failures
```

**Worker Errors by Product**:
```kql
exceptions
| extend workerName = cloud_RoleName
| where workerName endswith "Worker"
| summarize ErrorCount=count() by workerName, problemId
| top 20 by ErrorCount desc
```

## 🎯 Migration Path

### Phase 1: Deploy Workers (Week 1)
- Deploy all 7 worker functions
- Test each worker independently
- Verify AuthManager integration

### Phase 2: Update Workbooks (Week 2)
- Update workbook queries to call workers directly
- Test all workbook tabs
- Compare results with legacy functions

### Phase 3: Deploy MainOrchestrator (Week 3)
- Deploy orchestrator function
- Update XSOAR playbooks to use orchestrator
- Monitor routing performance

### Phase 4: Deprecate Legacy (Week 4+)
- Mark DefenderC2Dispatcher as deprecated
- Remove old 6 MDE functions (merged into MDEWorker)
- Clean up unused code

## 💡 Benefits Summary

| Aspect | v2.2.0 (Unified) | v2.3.0 (Workers) |
|--------|-----------------|------------------|
| Functions | 2 main (XDROrchestrator, MDEManager) | 7 workers + 1 orchestrator |
| Workbook Integration | ❌ Indirect | ✅ Direct |
| Independent Scaling | ❌ All together | ✅ Per product |
| Debugging | Harder (combined logs) | ✅ Easier (isolated logs) |
| Responsibility | Blurred | ✅ Clear per product |
| Backward Compatible | ✅ Yes | ✅ Yes |
| Multi-tenant | ✅ Yes | ✅ Yes |

## 🎉 Conclusion

The **Worker Pattern** provides the best balance of:
- ✅ **Simplicity**: One function = one product
- ✅ **Performance**: Independent scaling
- ✅ **Maintainability**: Clear boundaries
- ✅ **Integration**: Direct workbook calls
- ✅ **Flexibility**: Use workers directly OR via orchestrator

This architecture scales better, debugs easier, and integrates seamlessly with Azure Workbooks while maintaining full backward compatibility.
