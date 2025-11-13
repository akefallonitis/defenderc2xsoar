# Workbook Analysis & Pattern Discovery

**Date**: November 12, 2025  
**Purpose**: Extract patterns from existing workbooks for v4.0 advanced workbook implementation

---

## 📚 Workbook Inventory

### Current Production Workbooks
1. **DefenderXDR-Complete.json** (3554 lines)
   - Retro terminal theme with CRT effects
   - 7 tabs: Defender C2, Threat Intel, Action Manager, Hunt Manager, Incident Manager, Custom Detection, Interactive Console
   - CustomEndpoint pattern with auto-discovery
   - ARM Actions NOT implemented (uses CustomEndpoint for everything)
   
2. **DefenderC2-Hybrid.json**
   - Similar to Complete, likely hybrid ARM/CustomEndpoint approach

### Reference Workbooks (Archive)
1. **Sentinel360 XDR Investigation-Remediation Console Enhanced.json** ⭐ REFERENCE DESIGN
   - Incident/Alert/Entity dashboard structure
   - Multi-tenant Lighthouse support
   - Entity-driven actions (Account, Host, IP, URL, FileHash)
   - Conditional visibility per entity type
   - PowerShell remediation scripts embedded
   
2. **Advanced Workbook Concepts.json** ⭐ ADVANCED PATTERNS
   - Azure Resource Graph queries
   - Azure Resource Manager (ARM) API calls with JSONPath
   - Azure Data Explorer integration
   - Merge queries (joins between data sources)
   - Custom Endpoint examples
   - Graph visualizations (interactive node-relation graphs)
   - Linking Azure resources, blades, workbooks, external URLs
   - ARM template deployment FROM workbook
   - Playbook execution automation
   
3. **DefenderC2 Advanced Console.json**
4. **DefenderC2-CustomEndpoint.json**
5. **DeviceManager-Hybrid.json**
6. **DeviceManager-CustomEndpoint.json**
7. **Sentinel360-MDR-Console.json** (and v1)
8. **Sentinel360-XDR-Auditing.json**
9. **Investigation Insights.json** (and Original)

### Test Workbooks
- **DeviceManager-Hybrid.workbook.json**
- **DeviceManager-Hybrid-CustomEndpointOnly.workbook.json**
- **DeviceManager-CustomEndpoint-Only.workbook.json**

---

## 🎯 Key Patterns Discovered

### Pattern 1: CustomEndpoint (Auto-Refresh Listings)

**Purpose**: Query function app for live data with auto-refresh

**Syntax**:
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderXDRDispatcher",
  "body": null,
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ],
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.devices[*]",
      "columns": [
        {"path": "$.id", "columnid": "value"},
        {"path": "$.computerDnsName", "columnid": "label"}
      ]
    }
  }]
}
```

**Use Cases**:
- Device listings
- User listings
- Incident listings
- Alert listings
- File library listings
- Action history
- Operation status queries

**Auto-Refresh**: Set `timeContextFromParameter` to enable 30s/60s refresh intervals

---

### Pattern 2: ARM Actions (Manual Execution with Confirmation)

**Purpose**: Execute destructive actions with user confirmation

**Syntax** (from Advanced Workbook Concepts):
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Deploy Dynamic Template",
      "style": "primary",
      "linkIsContextBlade": true,
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{RG}/providers/Microsoft.Insights/dataCollectionRules/{DCRName}?api-version=2021-09-01-preview",
        "body": "{...JSON_BODY...}",
        "httpMethod": "PUT",
        "description": "# Actions can potentially modify resources.\n## Please use caution and include a confirmation message in this description when authoring this command."
      }
    }]
  }
}
```

**For Our Function App**:
```json
{
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/Gateway",
    "body": "{\"service\":\"MDE\",\"action\":\"ISOLATEDEVICE\",\"tenantId\":\"{TenantId}\",\"machineId\":\"{SelectedDevice}\",\"comment\":\"Incident response\"}",
    "httpMethod": "POST",
    "title": "Isolate Device",
    "description": "Network isolate the selected device",
    "runLabel": "Isolate"
  }
}
```

**Use Cases**:
- Device isolation/release
- User disable/enable
- File quarantine/allow
- Email delete/move
- Investigation package collection
- Antivirus scan execution
- Live Response command execution
- Advanced Hunting query execution

---

### Pattern 3: Multi-Tenant Lighthouse Support

**Auto-Populated Parameters**:
```json
{
  "id": "subscription-param",
  "version": "KqlParameterItem/1.0",
  "name": "Subscriptions",
  "type": 6,
  "isRequired": true,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "typeSettings": {
    "additionalResourceOptions": ["value::all"],
    "showDefault": false
  },
  "defaultValue": "value::all",
  "queryType": 1
},
{
  "id": "workspace-param",
  "version": "KqlParameterItem/1.0",
  "name": "Workspaces",
  "type": 5,
  "isRequired": true,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "query": "where type =~ 'microsoft.operationalinsights/workspaces'\r\n| order by name asc\r\n| take 50",
  "crossComponentResources": ["{Subscriptions}"],
  "typeSettings": {
    "additionalResourceOptions": ["value::10"],
    "showDefault": false
  },
  "defaultValue": "value::10",
  "queryType": 1,
  "resourceType": "microsoft.resourcegraph/resources"
},
{
  "id": "tenantid-autodiscover",
  "version": "KqlParameterItem/1.0",
  "name": "TenantId",
  "type": 1,
  "query": "ResourceContainers\n| where type == 'microsoft.resources/subscriptions'\n| project tenantId\n| distinct tenantId",
  "crossComponentResources": ["value::all"],
  "queryType": 1,
  "resourceType": "microsoft.resourcegraph/resources"
}
```

**Key**: Use Azure Resource Graph to discover tenants, subscriptions, workspaces dynamically

---

### Pattern 4: Conditional Visibility

**Show Entity-Specific Actions**:
```json
{
  "type": 12,
  "content": {
    "version": "NotebookGroup/1.0",
    "groupType": "editable",
    "items": [
      {
        "type": 1,
        "content": {
          "json": "### 🔧 Account Remediation Actions\n\n..."
        }
      },
      {
        "type": 11,
        "content": {
          "version": "LinkItem/1.0",
          "links": [{
            "linkTarget": "ArmAction",
            "linkLabel": "Disable Account",
            ...
          }]
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "entityTab",
    "comparison": "isEqualTo",
    "value": "Account"
  }
}
```

**Use Cases**:
- Show device actions only when device entity selected
- Show user actions only when user entity selected
- Show file actions only when file entity selected
- Show email actions only when email entity selected
- Show IP actions only when IP entity selected

---

### Pattern 5: Incident/Alert Dashboard Structure

**From Sentinel360 Reference**:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "tabs",
    "links": [
      {"id": "dashboard-tab", "cellValue": "selectedTab", "linkTarget": "parameter", "linkLabel": "📊 Dashboard", "subTarget": "Dashboard"},
      {"id": "incident-workflow-tab", "cellValue": "selectedTab", "linkTarget": "parameter", "linkLabel": "🚨 Incident Workflow", "subTarget": "IncidentWorkflow"},
      {"id": "entity-insights-tab", "cellValue": "selectedTab", "linkTarget": "parameter", "linkLabel": "🔍 Entity Insights", "subTarget": "EntityInsights"},
      {"id": "incident-management-tab", "cellValue": "selectedTab", "linkTarget": "parameter", "linkLabel": "📝 Incident Management", "subTarget": "IncidentManagement"}
    ]
  }
},
{
  "type": 12,
  "content": {
    "version": "NotebookGroup/1.0",
    "groupType": "editable",
    "items": [
      {
        "type": 3,
        "content": {
          "version": "KqlItem/1.0",
          "query": "SecurityIncident\r\n| where TimeGenerated {TimeRange}\r\n| summarize TotalIncidents = count()\r\n...",
          "visualization": "tiles"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "Dashboard"
  }
}
```

**Key Components**:
1. **Tab navigation** (LinkItem with style="tabs")
2. **Dashboard metrics** (tiles visualization)
3. **Incident listing** (grid with export to Excel)
4. **Entity selector** (tabs within tabs: IP/Account/Host/URL/FileHash)
5. **Entity details** (conditional groups per entity type)
6. **Remediation actions** (embedded PowerShell or ARM Actions)

---

### Pattern 6: Console UI (Text Input + Execution)

**From DefenderXDR-Complete**:
```json
{
  "type": 1,
  "content": {
    "json": "### Live Response Console\n\n**Device**: {SelectedDevice}\n\n**Commands**: `dir`, `getfile`, `putfile`, `run`, `processes`, `registry`"
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

**For Interactive Console**:
1. **Command input** parameter (text, multiline)
2. **Execute button** (ARM Action to send command)
3. **Output display** (CustomEndpoint to query results)
4. **Session management** (start/stop/status)

---

### Pattern 7: File Operations Workarounds

**Upload Flow**:
```
1. User uploads file to Storage Account Blob Container (manual or via portal link)
2. Workbook has link to Storage Account blade
3. User gets SAS URL from blob
4. ARM Action calls function app: TransferFileToLibrary
   - Body: {"service":"MDE","action":"TransferFileToLibrary","blobUrl":"{BlobSasUrl}","fileName":"{FileName}"}
5. Function app downloads from blob, uploads to MDE library
```

**Download Flow**:
```
1. Workbook lists library files (CustomEndpoint)
2. User selects file
3. ARM Action calls function app: GenerateSASUrl
   - Body: {"service":"MDE","action":"GetLibraryFile","fileName":"{SelectedFile}"}
4. Function app returns SAS URL
5. Workbook displays link to download URL
```

**Library Listing**:
```json
{
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionApp}.azurewebsites.net/api/Gateway\",\"body\":\"{\\\"service\\\":\\\"MDE\\\",\\\"action\\\":\\\"GETLIBRARYFILES\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\"}",
  "queryType": 10,
  "refreshInterval": 120
}
```

---

### Pattern 8: Advanced Hunting

**KQL Input + Execution**:
```json
{
  "type": 9,
  "content": {
    "version": "KqlParameterItem/1.0",
    "parameters": [{
      "id": "hunting-query",
      "version": "KqlParameterItem/1.0",
      "name": "HuntingQuery",
      "label": "KQL Query",
      "type": 1,
      "typeSettings": {
        "multiLineText": true,
        "editorLanguage": "kql",
        "multiLineHeight": 10
      },
      "value": "DeviceProcessEvents\n| where FileName =~ \"powershell.exe\"\n| take 100"
    }]
  }
},
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Run Query",
      "style": "primary",
      "armActionContext": {
        "path": "https://{FunctionApp}.azurewebsites.net/api/Gateway",
        "body": "{\"service\":\"MDE\",\"action\":\"RUNADVANCEDHUNTING\",\"tenantId\":\"{TenantId}\",\"query\":\"{HuntingQuery}\"}",
        "httpMethod": "POST",
        "title": "Execute Advanced Hunting Query",
        "runLabel": "Execute"
      }
    }]
  }
},
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionApp}.azurewebsites.net/api/Gateway\",\"body\":\"{\\\"service\\\":\\\"MDE\\\",\\\"action\\\":\\\"GETLASTQUERYRESULTS\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\"}",
    "queryType": 10,
    "transformers": [{
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.results[*]"
      }
    }]
  }
}
```

**Simulating Defender Console**:
- Multi-line KQL input (editorLanguage: "kql")
- Table selector dropdown (DeviceProcessEvents, DeviceFileEvents, DeviceNetworkEvents, etc.)
- Run Query ARM Action
- Results display with JSONPath transformer
- Export to CSV button
- Save Query button (store in parameter or blob)

---

### Pattern 9: Grouping and Nesting

**Logical Organization**:
```json
{
  "type": 12,
  "content": {
    "version": "NotebookGroup/1.0",
    "groupType": "editable",
    "title": "Investigation",
    "expandable": true,
    "items": [
      {
        "type": 12,
        "content": {
          "version": "NotebookGroup/1.0",
          "groupType": "editable",
          "title": "Incidents",
          "expandable": true,
          "items": [...]
        }
      },
      {
        "type": 12,
        "content": {
          "version": "NotebookGroup/1.0",
          "groupType": "editable",
          "title": "Alerts",
          "expandable": true,
          "items": [...]
        }
      },
      {
        "type": 12,
        "content": {
          "version": "NotebookGroup/1.0",
          "groupType": "editable",
          "title": "Entities",
          "expandable": true,
          "items": [...]
        }
      }
    ]
  }
}
```

**Recommended Structure**:
```
📊 DefenderXDR - Unified Console
├── 🔍 Investigation
│   ├── 🚨 Incidents
│   ├── ⚠️ Alerts
│   └── 🎯 Entities
│       ├── 💻 Devices
│       ├── 👤 Users
│       ├── 📂 Files
│       ├── 📧 Emails
│       ├── 🌐 IPs
│       └── 🔗 URLs
├── ⚡ Remediation
│   ├── 💻 Device Actions
│   ├── 👤 User Actions
│   ├── 📂 File Actions
│   ├── 📧 Email Actions
│   ├── 🌐 Network Actions
│   └── 📦 Batch Operations
├── 🔬 Advanced
│   ├── 🖥️ Live Response Console
│   ├── 🔍 Advanced Hunting
│   ├── 📚 File Library
│   └── 🤖 Custom Detections
└── ⚙️ Administration
    ├── 📋 Operation History
    ├── 🎯 Threat Indicators
    └── ⚙️ Settings
```

---

### Pattern 10: JSONPath Transformers

**Parse API Responses**:
```json
{
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.data[*]",
      "columns": [
        {"path": "$.id", "columnid": "DeviceId"},
        {"path": "$.computerDnsName", "columnid": "DeviceName"},
        {"path": "$.healthStatus", "columnid": "Status"},
        {"path": "$.riskScore", "columnid": "RiskScore"},
        {"path": "$.lastSeen", "columnid": "LastSeen"}
      ]
    }
  }]
}
```

**Common Paths**:
- `$.data[*]` - Array of data items
- `$.value[*]` - ARM API responses
- `$.result` - Single result object
- `$.devices[*]` - Device list
- `$.users[*]` - User list
- `$.incidents[*]` - Incident list
- `$.properties` - ARM resource properties

---

### Pattern 11: Graph Visualizations

**Interactive Node-Relation Graphs**:
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "let links = data\n| summarize by  Source = Account, Target = Computer, Kind = 'Account -> Machine';\nlet nodes = data \n| summarize by  Id = Account, Name = Account, Kind = 'Account'\n| union (data\n    | summarize by Id = Computer, Name = Computer, Kind = 'Machine');\nnodes\n| union links",
    "visualization": "graph",
    "graphSettings": {
      "type": 0,
      "centerContent": {"columnMatch": "Name"},
      "bottomContent": {"columnMatch": "Kind"},
      "nodeIdField": "Id",
      "sourceIdField": "Source",
      "targetIdField": "Target",
      "graphOrientation": 3,
      "showOrientationToggles": true
    }
  }
}
```

**Use Cases**:
- Device-to-User relationships
- Process execution trees
- Network communication graphs
- Alert correlation graphs

---

### Pattern 12: Merge Queries (Join Data Sources)

**Combine Multiple Queries**:
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"Merge/1.0\",\"merges\":[{\"id\":\"join1\",\"mergeType\":\"innerunique\",\"leftTable\":\"Q1\",\"rightTable\":\"Q2\",\"leftColumn\":\"UserPrincipalName\",\"rightColumn\":\"UserId\"}]}",
    "queryType": 7
  }
}
```

**Join Types**:
- inner unique
- full inner/outer
- left inner/outer
- left semi/anti
- right inner/outer
- right semi/anti
- union

---

### Pattern 13: Linking Azure Resources

**Open Resources from Workbook**:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "cellValue": "{WorkspaceResourceId}",
      "linkTarget": "Resource",
      "linkLabel": "Open Workspace",
      "style": "primary",
      "linkIsContextBlade": true,
      "subTarget": "workbook"
    }]
  }
}
```

**Link Azure Blades**:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "OpenBlade",
      "linkLabel": "Open Storage Account",
      "style": "primary",
      "linkIsContextBlade": true,
      "bladeOpenContext": {
        "bladeName": "StorageAccountBlade",
        "extensionName": "Microsoft_Azure_Storage",
        "bladeJsonParameters": "{\"resourceId\":\"{StorageAccountId}\"}"
      }
    }]
  }
}
```

---

### Pattern 14: Playbook Execution from Workbook

**Run Logic Apps on Incidents**:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Run Playbook",
      "style": "primary",
      "linkIsContextBlade": true,
      "armActionContext": {
        "path": "{Workspace}/providers/Microsoft.SecurityInsights/incidents/{IncidentName}/runPlaybook?api-version=2019-01-01-preview",
        "body": "{\"LogicAppsResourceId\":\"{Playbook}\",\"TenantId\":\"{TenantId}\"}",
        "httpMethod": "POST",
        "description": "Execute playbook on selected incident"
      }
    }]
  }
}
```

---

## 🎯 Implementation Recommendations

### For v4.0 Workbook

**1. Use CustomEndpoint for ALL Listings**:
- Device lists → CustomEndpoint with 60s refresh
- User lists → CustomEndpoint with 60s refresh
- Incident lists → CustomEndpoint with 30s refresh
- Alert lists → CustomEndpoint with 30s refresh
- Action history → CustomEndpoint with 10s refresh
- Library files → CustomEndpoint with 120s refresh
- Operation status → CustomEndpoint with 10s refresh

**2. Use ARM Actions for ALL Manual Operations**:
- Device isolation/release
- User disable/enable
- File quarantine/allow
- Email delete/move
- Antivirus scan
- Investigation package collection
- Live Response commands
- Advanced Hunting query execution
- Batch operation submission

**3. Implement Incident/Alert/Entity Dashboard**:
- Main tab: Incident listing (CustomEndpoint)
- Sub-tabs: Alerts, Entities
- Entity sub-tabs: Devices, Users, Files, Emails, IPs, URLs
- Conditional visibility for entity-specific actions
- Entity selection → populate action parameters

**4. Implement Console UI**:
- Live Response: Device selector + command input + execute ARM Action + output display
- Advanced Hunting: KQL input + table selector + execute ARM Action + results display
- File Library: List files + upload link + download ARM Action + delete ARM Action

**5. Implement Multi-Tenant**:
- Subscription picker (Azure Resource Graph)
- Workspace picker (filtered by subscription)
- TenantId auto-discovery or manual selector
- Cross-tenant context switching

**6. Implement Batch Operations**:
- Multi-select on entity lists
- Bulk action section
- ARM Action for batch submission
- Operation tracking with status query

**7. Use Grouping/Nesting**:
- Investigation group (Incidents/Alerts/Entities)
- Remediation group (Actions by entity type)
- Advanced group (Console/Hunting/Library)
- Administration group (History/Indicators/Settings)

**8. Add Conditional Visibility**:
- Device actions → show only when device selected
- User actions → show only when user selected
- File actions → show only when file selected
- Email actions → show only when email selected

**9. Configure Auto-Refresh**:
- Incidents/Alerts: 30s
- Devices/Users: 60s
- Operation Status: 10s
- Library Files: 120s
- Disable for manual actions and hunting queries

**10. Add Confirmation Dialogs**:
- All destructive actions (isolate, delete, disable, quarantine)
- Title, description, runLabel
- Skip for safe actions (list, get)

---

## 📊 Success Metrics

✅ **Incident-Centric**: Main dashboard starts with incidents  
✅ **Entity-Driven**: Selecting entity filters available actions  
✅ **Multi-Tenant**: Lighthouse support with auto-populated parameters  
✅ **Auto-Refresh**: All listings auto-update at appropriate intervals  
✅ **ARM Actions**: All manual operations use ARM Actions with confirmation  
✅ **CustomEndpoint**: All listings use CustomEndpoint with JSONPath  
✅ **Console UI**: Live Response and Advanced Hunting have console-like UX  
✅ **File Operations**: Upload/download/library management working  
✅ **Batch Operations**: Multi-select + bulk action + tracking working  
✅ **Conditional Visibility**: Entity-specific actions show/hide correctly  
✅ **Grouping/Nesting**: Logical organization with expandable sections  
✅ **Best-in-Class**: Combines best features from all reference workbooks  

---

**This analysis provides the foundation for building the v4.0 advanced workbook. All patterns are validated from existing working examples.**
