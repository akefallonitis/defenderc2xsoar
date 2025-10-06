# Architecture Documentation

## Overview

defenderc2xsoar is a workbook-based automation platform for Microsoft Defender for Endpoint (MDE). It replaces the traditional web application approach with Azure Workbooks for the UI layer while maintaining all core functionality.

## Design Principles

1. **No Secrets in Code**: Use managed identity and federated credentials instead of storing secrets
2. **Multi-Tenant by Design**: Single deployment serves multiple tenants via parameter passing
3. **Workbook-First**: Leverage Azure Workbooks for UI instead of maintaining a separate web app
4. **Cost-Effective**: Minimize running costs while maintaining functionality
5. **Standards-Based**: Use ARM templates, standard Azure services, and PowerShell

## Component Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         USER LAYER                             │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │             Azure Sentinel Workbook                       │ │
│  │  - Parameter input (tenant, subscriptions, etc.)         │ │
│  │  - Tabbed interface (6 functional areas)                 │ │
│  │  - KQL queries for data visualization                    │ │
│  │  - Action buttons to trigger functions                   │ │
│  │  - Result parsing and display                            │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │ HTTPS
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                    COMPUTE/LOGIC LAYER                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │          Azure Function App (Consumption Plan)            │ │
│  │                                                            │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │  System-Assigned Managed Identity                  │  │ │
│  │  │  - No secrets required                             │  │ │
│  │  │  - Linked to App Registration via Federated Cred   │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  │                                                            │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │  Functions (PowerShell Core 7.2):                  │  │ │
│  │  │  - DefenderC2Dispatcher        (device actions)           │  │ │
│  │  │  - DefenderC2TIManager         (threat intel)             │  │ │
│  │  │  - DefenderC2HuntManager       (hunting)                  │  │ │
│  │  │  - DefenderC2IncidentManager   (incidents)                │  │ │
│  │  │  - DefenderC2CDManager         (custom detections)        │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │ OAuth 2.0
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATION LAYER                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │      Multi-Tenant App Registration (Entra ID)            │ │
│  │                                                            │ │
│  │  - Federated Identity Credential (linked to MI)          │ │
│  │  - Application Permissions (MDE + Graph APIs)            │ │
│  │  - Admin Consent per tenant                              │ │
│  │  - No client secrets required                            │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │ API Calls
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                      API/DATA LAYER                            │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │   Microsoft Defender for Endpoint APIs                   │ │
│  │   - Machine actions (isolate, scan, collect)             │ │
│  │   - Threat indicators (IOCs)                             │ │
│  │   - Live Response                                        │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │   Microsoft Graph APIs                                   │ │
│  │   - Advanced hunting                                     │ │
│  │   - Custom detections                                    │ │
│  │   - Incident management                                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Authentication Flow

### Token Acquisition Flow

```
1. User clicks action in Workbook
   │
   └─> Workbook passes: tenantId, spnId, action params
       │
       └─> Function App receives request
           │
           └─> Function uses Managed Identity to request token
               │
               └─> Azure AD validates Federated Credential
                   │  (Managed Identity <-> App Registration)
                   │
                   └─> Token Exchange (OAuth 2.0 FIC)
                       │
                       └─> Access Token issued for target tenant
                           │
                           └─> Function calls MDE/Graph API with token
                               │
                               └─> API validates token and processes request
                                   │
                                   └─> Response returned to Function
                                       │
                                       └─> Function returns JSON to Workbook
                                           │
                                           └─> Workbook displays results
```

### Why Federated Identity Credentials?

Federated Identity Credentials (FIC) eliminate the need for client secrets:

1. **No Secret Storage**: No secrets in Key Vault or environment variables
2. **Automatic Rotation**: Managed identity credentials rotate automatically
3. **Multi-Tenant**: Single app registration works across all tenants
4. **Least Privilege**: Managed identity only has permissions to exchange tokens
5. **Audit Trail**: All token requests are logged in Azure AD

## Data Flow

### Example: Isolate Device Action

```
1. User Input (Workbook)
   - Tab: MDEAutomator
   - Action: Isolate Device
   - Device Filter: riskScore eq 'High'
   - Target Tenant: tenant-id-123

2. Workbook Action
   - Constructs URL: https://func-app.com/api/DefenderC2Dispatcher
   - Parameters: action=Isolate&tenantId=tenant-id-123&deviceFilter=...
   - User clicks "Execute Action"

3. Function App (DefenderC2Dispatcher)
   - Receives HTTP request
   - Validates parameters
   - Calls Connect-MDE with tenantId
   - Gets OAuth token via Managed Identity + FIC
   - Calls Get-Machines with filter
   - For each device: Calls Invoke-MachineIsolation
   - Returns action IDs and status

4. Workbook Display
   - Parses JSON response
   - Shows action status in grid
   - Updates device list
   - Displays success/error messages
```

## Workbook Structure

The workbook is organized into functional tabs:

### Tab 1: MDEAutomator (Device Actions)
- **Purpose**: Execute response actions on devices
- **Key Components**:
  - Action type selector
  - Device filter input (OData syntax)
  - Device ID input (for specific targeting)
  - Execute button
  - Action status display
  - Device list query
- **Backend**: DefenderC2Dispatcher function

### Tab 2: Threat Intelligence Manager
- **Purpose**: Manage threat indicators (IOCs)
- **Key Components**:
  - Action selector (Add/Remove)
  - Indicator type selector (File/IP/URL/Cert)
  - Indicator list input
  - Title, severity, action settings
  - Execute button
  - Recent indicators query
- **Backend**: DefenderC2TIManager function

### Tab 3: Action Manager
- **Purpose**: View and manage machine actions
- **Key Components**:
  - Refresh button
  - Cancel all actions button (safety switch)
  - Recent actions grid
  - Action statistics chart
  - Action timeline
- **Backend**: DefenderC2Dispatcher function (GetActions/CancelAllActions)

### Tab 4: Hunt Manager
- **Purpose**: Execute advanced hunting queries
- **Key Components**:
  - KQL query editor (multi-line)
  - Hunt name input
  - Save to storage toggle
  - Execute button
  - Sample queries
  - Results preview
- **Backend**: DefenderC2HuntManager function

### Tab 5: Incident Manager
- **Purpose**: Manage security incidents
- **Key Components**:
  - Severity and status filters
  - Refresh button
  - Incidents grid
  - Incident statistics charts
- **Backend**: DefenderC2IncidentManager function

### Tab 6: Custom Detection Manager
- **Purpose**: Manage custom detection rules
- **Key Components**:
  - Action selector (List/Create/Update/Delete/Backup)
  - Detection rule name input
  - KQL query editor
  - Severity selector
  - Execute button
  - Sample detection rules
  - Detection statistics
- **Backend**: DefenderC2CDManager function

## Function App Structure

Each function follows a consistent pattern:

```powershell
using namespace System.Net

param($Request, $TriggerMetadata)

# 1. Parameter extraction
$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId
# ... other parameters

# 2. Parameter validation
if (-not $tenantId -or -not $spnId) {
    return BadRequest
}

try {
    # 3. Authentication
    # Import MDEAutomator module
    # $token = Connect-MDE -SpnId $spnId -ManagedIdentityId $env:MSI_CLIENT_ID -TenantId $tenantId

    # 4. Execute action
    switch ($action) {
        "Action1" { 
            # Call MDE/Graph API
            $result = ...
        }
        "Action2" { ... }
    }

    # 5. Return response
    return OK with JSON result

} catch {
    # 6. Error handling
    return InternalServerError with error details
}
```

## Multi-Tenancy

### How It Works

1. **Single Deployment**: One function app, one app registration
2. **Tenant Parameter**: Each request includes target tenant ID
3. **Token Scoping**: OAuth token is requested for specific tenant
4. **API Isolation**: Each API call is scoped to the target tenant
5. **Data Separation**: No data mixing between tenants

### Tenant Onboarding

To add a new tenant:

1. Grant admin consent in the new tenant:
   ```
   https://login.microsoftonline.com/{NEW_TENANT_ID}/adminconsent?client_id={APP_ID}
   ```

2. Update workbook parameter when working with that tenant:
   ```
   Target Tenant ID: new-tenant-id-here
   ```

No code changes required!

## Security Architecture

### Authentication Security

1. **Managed Identity**: Function app identity managed by Azure
2. **Federated Credentials**: No secrets to rotate or leak
3. **Token Scoping**: Tokens are tenant-specific and time-limited
4. **API Permissions**: Least privilege principle applied
5. **Audit Logging**: All auth requests logged in Azure AD

### Network Security

1. **HTTPS Only**: All traffic encrypted in transit
2. **Function Keys**: Optional function-level keys for additional security
3. **CORS**: Configured to allow only Azure Portal
4. **Private Endpoints**: Optional for enhanced network isolation

### Data Security

1. **No Persistent Storage**: Function app is stateless
2. **Temporary Data**: Results returned immediately, not stored
3. **Optional Storage**: If enabled, secured with managed identity
4. **Encryption**: Data encrypted at rest and in transit

### Access Control

1. **Workbook RBAC**: Azure RBAC controls who can view/edit workbooks
2. **Function Auth**: Optional Azure AD authentication on function app
3. **API Permissions**: Require admin consent per tenant
4. **Audit Trail**: Application Insights logs all requests

## Scalability

### Horizontal Scaling

- **Function App**: Automatically scales based on load (Consumption plan)
- **Workbook**: Rendered client-side, no server load
- **Multi-Instance**: Multiple function instances run in parallel

### Performance Considerations

1. **Cold Starts**: First request after idle period takes 3-10 seconds
   - Mitigation: Keep function warm with scheduled ping
2. **API Rate Limits**: MDE/Graph APIs have rate limits
   - Mitigation: Implement retry logic and exponential backoff
3. **Bulk Operations**: Large device sets can take time
   - Mitigation: Batch requests and provide progress feedback

### Limits

- **Function Timeout**: Default 5 minutes (configurable up to 10 minutes)
- **Request Size**: 100 MB max
- **Response Size**: 100 MB max
- **Concurrent Executions**: 200 per Consumption plan instance

## Cost Model

### Monthly Costs (Estimated)

| Component | Usage | Cost |
|-----------|-------|------|
| Function App (Consumption) | 100K executions, 1GB-s avg | $5-10 |
| Storage Account | 1 GB storage, minimal transactions | $0.50 |
| Application Insights | 1 GB ingestion, 90 days retention | $2-5 |
| Workbooks | Free (no server-side compute) | $0 |
| **Total** | | **$10-20/month** |

Compare to original MDEAutomator: ~$220/month

### Cost Optimization Tips

1. Use Consumption plan (not Premium)
2. Minimize storage usage (don't save unnecessary results)
3. Reduce Application Insights sampling if high volume
4. Share function app across multiple tenants
5. Consider scheduled actions during off-hours

## Monitoring and Observability

### Metrics

1. **Function App Metrics**:
   - Execution count
   - Execution duration
   - Error rate
   - HTTP status codes

2. **Application Insights**:
   - Request telemetry
   - Dependency calls (to MDE/Graph APIs)
   - Exceptions and traces
   - Custom events

3. **Azure Monitor**:
   - Resource health
   - Service availability
   - Alert rules

### Logging

Each function logs:
- Request parameters (sanitized)
- Authentication status
- API calls made
- Response status
- Errors with stack traces

### Alerts

Recommended alerts:
1. Function error rate > 10%
2. Function duration > 60 seconds (avg)
3. Authentication failures
4. API rate limit errors

## Disaster Recovery

### Backup Strategy

1. **Workbook Definition**: Export JSON regularly
2. **Function Code**: Stored in Git repository
3. **ARM Template**: Stored in Git repository
4. **App Registration**: Document configuration
5. **Custom Detections**: Use backup feature to save to storage

### Recovery Steps

If function app is lost:

1. Redeploy ARM template
2. Redeploy function code from Git
3. Reconfigure federated credential
4. Test with workbook

Time to recovery: ~15 minutes

## Future Enhancements

### Potential Improvements

1. **Durable Functions**: For long-running operations
2. **Event Grid**: For event-driven automation
3. **Logic Apps**: For workflow orchestration
4. **Power BI**: For advanced analytics
5. **Notification System**: Email/Teams alerts on actions
6. **Approval Workflow**: For sensitive actions
7. **Batch Scheduling**: Schedule bulk operations

### Integration Opportunities

- Sentinel automation rules
- Microsoft Teams webhooks
- ServiceNow integration
- Ticketing system integration
- SIEM forwarding

## Comparison with Original MDEAutomator

| Aspect | MDEAutomator | defenderc2xsoar |
|--------|-------------|-----------------|
| UI | Flask web app | Azure Workbook |
| Hosting | App Service | Consumption Functions |
| Authentication | Key Vault secrets | Managed Identity + FIC |
| Network | VNet, Private Endpoints | Public (optional private) |
| Storage | Required | Optional |
| OpenAI | Included | Optional |
| Cost | ~$220/month | ~$10-20/month |
| Deployment | Complex Bicep | Simple ARM template |
| Maintenance | Web app updates | Minimal |

Both solutions provide the same core MDE automation capabilities.

## Technical Decisions

### Why Workbooks vs Web App?

**Advantages**:
- No server-side UI code to maintain
- Built-in security (Azure RBAC)
- Native integration with Log Analytics
- No hosting costs for UI
- Rich visualization capabilities
- Easy to share and version

**Trade-offs**:
- Less customizable UI
- Limited to Azure Portal access
- KQL query limitations

### Why Consumption Plan?

**Advantages**:
- Pay only for executions
- Automatic scaling
- No idle costs
- Simple management

**Trade-offs**:
- Cold start latency
- 10-minute timeout
- No always-on capability

### Why Federated Credentials?

**Advantages**:
- No secret management
- Automatic rotation
- Simplified multi-tenancy
- Enhanced security

**Trade-offs**:
- Requires managed identity
- More complex initial setup
- Newer technology (less familiar)

---

This architecture provides a secure, scalable, and cost-effective approach to MDE automation while maintaining feature parity with the original MDEAutomator solution.
