# DefenderC2 Enhanced Workbook Guide

## 🎯 Overview

The **DefenderC2 Enhanced Workbook** is a comprehensive, production-ready Azure Workbook that provides full-featured command and control capabilities for Microsoft Defender for Endpoint. This enhanced version incorporates proven patterns from working examples and implements all success criteria.

## ✨ Key Features

### 1. **All Manual Actions Use ARM Actions** ✅
- Device isolation/unisolation
- Antivirus scan execution
- App execution restriction/unrestriction
- Investigation package collection
- Threat indicator management
- Incident updates
- Custom detection rule management
- Live response command execution
- Action cancellation

### 2. **All Listing Operations Use CustomEndpoint with Auto-Refresh** ✅
- Device inventory (30s refresh)
- Pending/running actions (30s refresh)
- All machine actions history (30s refresh)
- Threat indicators (30s refresh)
- Security incidents (30s refresh)
- Custom detection rules (30s refresh)
- Live response sessions (30s refresh)

### 3. **Top-Level Selection and Autopopulation** ✅
- Click devices to select → Auto-populates `DeviceList` parameter
- Selected devices automatically filter pending actions
- Action IDs clickable → Auto-populates cancel parameter
- Function App selection → Auto-discovers all connection parameters

### 4. **Conditional Visibility** ✅
- Pending actions section only shows when devices are selected
- Each tab has specific parameters and UI elements
- Smart filtering based on selected parameters

### 5. **Console-Like UI** ✅
- **Advanced Hunting**: KQL query console with sample queries
- **Live Response**: Interactive command interface with session management
- Text input fields for commands and queries
- Real-time result display

### 6. **Optimized UI/UX** ✅
- Retro terminal theme (Matrix green phosphor CRT style)
- Color-coded status indicators:
  - 🟢 Green: Success, Active, Healthy
  - 🟡 Yellow: Warning, Pending
  - 🔴 Red: Error, Failed, High Risk
  - 🔵 Blue: In Progress, Info
- Click-to-select functionality across tables
- Auto-refresh on monitoring sections
- Manual trigger on execution actions

## 📋 Workbook Structure

### Global Parameters (Auto-Discovery)

1. **FunctionApp** - Select your DefenderC2 Function App
   - Type: Resource picker
   - Filters: Function Apps only
   - Auto-discovers: Subscription, ResourceGroup, FunctionAppName

2. **Workspace** - Select Log Analytics Workspace
   - Type: Resource picker
   - Required for Sentinel integration

3. **TenantId** - Defender XDR Tenant
   - Type: Dropdown
   - Auto-populated from available tenants
   - Selects which Defender instance to manage

4. **DeviceList** - Selected Devices
   - Type: Text
   - Populated by clicking devices in tables
   - Comma-separated device IDs

5. **ActionIdToCancel** - Action to Cancel
   - Type: Text
   - Populated by clicking cancel buttons
   - Used for action cancellation

6. **TimeRange** - Time Range Filter
   - Type: Time picker
   - Default: Last 7 days
   - Configurable

### Tabs

#### 1. 🎯 Device Manager

**Purpose**: Comprehensive device operations and monitoring

**Features**:
- Device inventory with click-to-select
- Pending actions check with smart filtering
- Device action execution (Isolate, Scan, Restrict, etc.)
- Color-coded health and risk indicators

**Workflow**:
1. View all devices in auto-refreshing table
2. Click "✅ Select" on devices to add to `DeviceList`
3. Review pending actions (auto-filtered by selected devices)
4. Choose action type from dropdown
5. Execute ARM action
6. Track progress in pending actions table

**CustomEndpoint Queries**:
- `device-list`: Lists all devices with auto-refresh
- `pending-actions`: Shows running actions, filtered by selected devices

**ARM Actions**:
- Run Antivirus Scan
- Isolate Device (DESTRUCTIVE)
- Unisolate Device
- Collect Investigation Package
- Restrict App Execution (DESTRUCTIVE)
- Unrestrict App Execution

---

#### 2. 🛡️ Threat Intel Manager

**Purpose**: Manage threat indicators across all types

**Features**:
- View all indicators with auto-refresh
- Add file indicators (SHA1/SHA256/MD5)
- Add IP indicators (IPv4/IPv6)
- Add URL/Domain indicators
- Add certificate indicators
- Update/Remove indicators

**Workflow**:
1. View current indicators in auto-refreshing table
2. Fill in indicator details (hash, IP, URL, etc.)
3. Select action type (Alert, Block, Warn)
4. Add title/description
5. Execute ARM action to add indicator

**CustomEndpoint Queries**:
- `indicators-list`: All threat indicators with auto-refresh

**ARM Actions**:
- Add File Indicator
- Add IP Indicator
- Add URL Indicator
- Add Certificate Indicator
- Update Indicator
- Remove Indicator

---

#### 3. 📋 Action Manager

**Purpose**: Track and manage all device actions

**Features**:
- Complete action history
- Real-time status updates
- Click-to-cancel functionality
- Filter by device, action type, status

**Workflow**:
1. View all actions in auto-refreshing table
2. Click "❌ Cancel" on action ID to populate cancel parameter
3. Execute ARM action to cancel
4. Monitor status changes in real-time

**CustomEndpoint Queries**:
- `all-actions`: All machine actions with auto-refresh

**ARM Actions**:
- Cancel Action (by ActionID)

---

#### 4. 🔍 Advanced Hunting

**Purpose**: Execute KQL queries against Defender XDR

**Features**:
- Sample query library
- Custom KQL query input
- Console-like interface
- Result export capability

**Sample Queries**:
- Device inventory
- High risk devices
- Recent network activity
- Recent process events
- Recent file events

**Workflow**:
1. Select a sample query OR enter custom KQL
2. Click "🚀 Execute Query"
3. View results in table below
4. Export or analyze results

**ARM Actions**:
- Execute KQL Query (via DefenderC2HuntManager)

---

#### 5. 🚨 Incident Manager

**Purpose**: Security incident response operations

**Features**:
- Incident listing with auto-refresh
- Status updates (Active, InProgress, Resolved, Redirected)
- Assignment management
- Comment/note addition
- Priority management

**Workflow**:
1. View incidents in auto-refreshing table
2. Select incident ID
3. Choose new status
4. Add investigation notes
5. Execute ARM action to update

**CustomEndpoint Queries**:
- `incidents-list`: All incidents with auto-refresh

**ARM Actions**:
- Update Incident (status, comments, assignment)

---

#### 6. ⚙️ Custom Detection Manager

**Purpose**: Manage custom detection rules

**Features**:
- Detection rule listing with auto-refresh
- Create new rules with KQL
- Update existing rules
- Enable/Disable rules
- Rule backup/export

**Workflow**:
1. View current rules in auto-refreshing table
2. Enter rule name and KQL query
3. Set severity level
4. Execute ARM action to create
5. Monitor rule performance

**CustomEndpoint Queries**:
- `detection-rules-list`: All custom detection rules with auto-refresh

**ARM Actions**:
- Create Custom Detection Rule
- Update Detection Rule
- Delete Detection Rule

---

#### 7. 🖥️ Live Response Console

**Purpose**: Interactive command execution on remote devices

**Features**:
- Session management
- Native command execution (dir, netstat, tasklist, etc.)
- Script execution from library
- File upload/download
- Real-time command results

**Supported Commands**:
```
cd              - Change directory
dir / ls        - List directory contents
reg query       - Query registry
netstat         - Network connections
tasklist        - Running processes
getfile         - Download file from device
putfile         - Upload file to device
run             - Execute script from library
remediate       - Execute remediation script
```

**Workflow**:
1. View active sessions in auto-refreshing table
2. Enter device ID (or use selected from Device Manager)
3. Choose command type (RunScript, RunCommand, GetFile, PutFile)
4. Enter command/script name/file path
5. Add optional arguments
6. Execute ARM action
7. View results in Defender portal or poll via API

**CustomEndpoint Queries**:
- `live-sessions`: Active Live Response sessions with auto-refresh
- `library-scripts`: Available scripts in library

**ARM Actions**:
- Execute Live Response Command (via DefenderC2Orchestrator)

---

## 🔧 Configuration

### Prerequisites

1. **Azure Subscription** with:
   - Function App deployed (DefenderC2)
   - Reader role for Resource Graph queries
   - Invoke permissions on Function App

2. **Microsoft Defender for Endpoint** with:
   - App Registration (multi-tenant or single-tenant)
   - Appropriate API permissions
   - Function App configured with app credentials

3. **Function App Setup**:
   - Environment variables: `APPID`, `SECRETID`
   - Anonymous authentication enabled
   - Functions deployed: DefenderC2Dispatcher, DefenderC2Orchestrator, DefenderC2HuntManager, DefenderC2IncidentManager, DefenderC2CDManager, DefenderC2TIManager

### Deployment Steps

1. **Navigate to Azure Portal** → Workbooks
2. Click **"New"** or open existing workbook
3. Click **"Advanced Editor"** (</> icon in toolbar)
4. **Paste** the DefenderC2-Workbook.json content
5. Click **"Apply"**
6. **Configure** fallbackResourceIds (optional):
   ```json
   "fallbackResourceIds": [
     "/subscriptions/YOUR-SUBSCRIPTION-ID/resourcegroups/YOUR-RESOURCE-GROUP"
   ]
   ```
7. **Save** the workbook with a descriptive name
8. **Pin** to dashboard for easy access

### First-Time Setup

1. **Select Function App**: Choose your DefenderC2 Function App from dropdown
   - Wait 2-3 seconds for auto-discovery to populate parameters
   
2. **Select Workspace**: Choose your Log Analytics Workspace
   
3. **Select Tenant**: Choose the Defender XDR tenant to manage
   
4. **Test Connectivity**: Navigate to Device Manager tab
   - Device list should populate automatically
   - If you see errors, check Function App logs

## 🎨 Customization

### Retro Terminal Theme

The workbook includes a Matrix/Green Phosphor CRT style theme. To customize:

1. Open Advanced Editor
2. Find the `<style>` section in the header
3. Modify colors:
   - Primary: `#00ff00` (green)
   - Background: `#000000` (black)
   - Hover: `#001100` (dark green)

### Auto-Refresh Intervals

Default: 30 seconds for monitoring queries

To change:
1. Find query items with `"isAutoRefreshEnabled": true`
2. Modify `"intervalInSeconds"` value
3. Recommended range: 15-60 seconds

### Adding Custom Queries

1. Use the CustomEndpoint pattern:
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Your Action\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.results[*]\",\"columns\":[...]}}]}",
    "queryType": 10,
    "visualization": "table"
  }
}
```

2. For ARM Actions:
```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Your Action Label",
      "armActionContext": {
        "path": "https://{FunctionAppName}.azurewebsites.net/api/YourFunction",
        "headers": [{"name": "Content-Type", "value": "application/json"}],
        "body": "{\"action\":\"...\",\"tenantId\":\"{TenantId}\"}",
        "httpMethod": "POST"
      }
    }]
  }
}
```

## 🐛 Troubleshooting

### Device List Shows "<query failed>"

**Cause**: Function App parameters not populated yet  
**Solution**: 
1. Ensure Function App is selected
2. Wait 2-3 seconds for auto-discovery
3. Check Function App is running and accessible
4. Verify Function App environment variables (APPID, SECRETID)

### 400 Bad Request Error

**Cause**: Attempting to run same action on device with pending action  
**Solution**: 
1. Check "Pending Actions" section
2. Wait for completion OR
3. Click "❌ Cancel" to cancel existing action
4. Retry operation

### Action IDs Not Auto-populating

**Cause**: JSONPath transformer issue or function response format mismatch  
**Solution**: 
1. Check function logs for response format
2. Verify JSONPath: `$.actionIds[*]` or `$.actions[*].id`
3. Update transformer in query definition

### ARM Action Not Executing

**Cause**: Permission issues or incorrect ARM path  
**Solution**: 
1. Verify you have `Microsoft.Web/sites/functions/invoke/action` permission
2. Check ARM path format: `https://{FunctionAppName}.azurewebsites.net/api/FunctionName`
3. Ensure Subscription and ResourceGroup parameters are populated
4. Check Azure Activity Log for error details

### Auto-Refresh Not Working

**Cause**: Missing auto-refresh configuration  
**Solution**: 
1. Verify query has `"isAutoRefreshEnabled": true`
2. Check `"autoRefreshSettings"` is present
3. Ensure `"intervalInSeconds"` is set (15-60 recommended)
4. Note: ARM Actions do NOT auto-refresh (by design)

## 📊 Monitoring and Logging

### Azure Activity Log

All ARM Actions are logged in Azure Activity Log:
1. Navigate to Azure Portal → Activity Log
2. Filter by:
   - Resource: Your Function App
   - Operation: "Invoke Action"
   - Time range: Last X hours
3. View execution details, status, errors

### Function App Logs

Monitor function execution:
1. Navigate to Function App → Functions → Your Function
2. Click "Monitor" tab
3. View invocation logs
4. Check Application Insights for detailed traces

### Workbook Telemetry

Track workbook usage:
1. Navigate to Workbook → Settings
2. Enable "Workbook Analytics"
3. View usage in Application Insights

## 🚀 Best Practices

### 1. Security

- ✅ Use managed identities where possible
- ✅ Rotate app registration secrets regularly
- ✅ Apply least privilege RBAC roles
- ✅ Monitor suspicious activity in Activity Log
- ✅ Implement conditional access policies

### 2. Performance

- ✅ Use auto-refresh only on monitoring queries (not actions)
- ✅ Set reasonable refresh intervals (30s recommended)
- ✅ Filter large result sets at the API level
- ✅ Use pagination for large datasets
- ✅ Cache static data where appropriate

### 3. Operations

- ✅ Test in non-production environment first
- ✅ Document custom modifications
- ✅ Backup workbook JSON before major changes
- ✅ Version control your workbook definitions
- ✅ Monitor function app performance and costs

### 4. User Experience

- ✅ Train users on the interface before production use
- ✅ Create quick reference guides for common tasks
- ✅ Set up alerts for failed operations
- ✅ Provide feedback mechanism for improvements
- ✅ Regularly update based on user feedback

## 📚 API Reference

### Function App Endpoints

#### DefenderC2Dispatcher
**Purpose**: Device operations and listing

**Actions**:
- `Get Devices`: List all devices
- `Get All Actions`: List all machine actions
- `Isolate Device`: Isolate device from network
- `Unisolate Device`: Remove isolation
- `Run Antivirus Scan`: Execute AV scan
- `Restrict App Execution`: Enable app restrictions
- `Unrestrict App Execution`: Disable app restrictions
- `Collect Investigation Package`: Gather forensic data
- `Cancel Action`: Cancel running action

**Example Request**:
```json
POST https://your-function-app.azurewebsites.net/api/DefenderC2Dispatcher
Content-Type: application/json

{
  "action": "Get Devices",
  "tenantId": "your-tenant-id"
}
```

#### DefenderC2TIManager
**Purpose**: Threat intelligence operations

**Actions**:
- `List Indicators`: Get all indicators
- `Add File Indicator`: Add file hash indicator
- `Add IP Indicator`: Add IP address indicator
- `Add URL Indicator`: Add URL/domain indicator
- `Update Indicator`: Modify existing indicator
- `Remove Indicator`: Delete indicator

#### DefenderC2HuntManager
**Purpose**: Advanced hunting queries

**Actions**:
- `Run Advanced Hunting Query`: Execute KQL query

#### DefenderC2IncidentManager
**Purpose**: Incident management

**Actions**:
- `Get Incidents`: List all incidents
- `Update Incident`: Modify incident properties

#### DefenderC2CDManager
**Purpose**: Custom detection management

**Actions**:
- `List Custom Detection Rules`: Get all rules
- `Create Custom Detection`: Add new rule
- `Update Custom Detection`: Modify rule
- `Delete Custom Detection`: Remove rule

#### DefenderC2Orchestrator
**Purpose**: Live response operations

**Actions**:
- `GetLiveResponseSessions`: List active sessions
- `InvokeLiveResponseScript`: Execute script from library
- `RunCommand`: Execute native command
- `GetFile`: Download file from device
- `PutFile`: Upload file to device
- `GetLibraryScripts`: List available scripts

## 🔗 Related Resources

- [Original MDEAutomator](https://github.com/msdirtbag/MDEAutomator) - PowerShell module this is based on
- [Microsoft Defender API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure Workbooks Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [KQL Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)

## 📝 Version History

### v2.0.0 - Enhanced (2024-11-05)
- ✅ Complete rewrite with 7 comprehensive tabs
- ✅ All listing operations use CustomEndpoint with auto-refresh
- ✅ All manual actions use ARM actions
- ✅ Click-to-select device functionality
- ✅ Smart filtering based on selected devices
- ✅ Color-coded status indicators
- ✅ Console-like UI for Advanced Hunting and Live Response
- ✅ Conditional visibility for improved UX
- ✅ Auto-population of parameters
- ✅ Comprehensive documentation

### v1.0.0 - Original
- Basic functionality with mixed query types
- Limited auto-refresh
- Manual parameter entry
- Basic UI

## 🤝 Contributing

To contribute improvements:

1. Test changes in non-production environment
2. Document new features
3. Follow existing patterns (CustomEndpoint for queries, ARM for actions)
4. Validate JSON before committing
5. Update this guide with new features

## 📄 License

This workbook is part of the DefenderC2 XSOAR project. See repository LICENSE for details.

## 💬 Support

For issues, questions, or feature requests:
- Create an issue in the GitHub repository
- Include workbook version, error messages, and steps to reproduce
- Check Azure Activity Log and Function App logs for errors
- Consult troubleshooting section above

---

**Last Updated**: 2024-11-05  
**Workbook Version**: 2.0.0 Enhanced  
**Maintainer**: DefenderC2 Team
