# DefenderC2 Workbook - MDEAutomator Port Documentation

## Overview

This document details the DefenderC2 Azure Workbook implementation as a port of [@msdirtbag/MDEAutomator](https://github.com/msdirtbag/MDEAutomator), featuring a retro green/black terminal theme and comprehensive Microsoft Defender for Endpoint automation capabilities.

---

## ✅ Requirements Checklist

All requirements from the original issue have been implemented:

### 1. ✅ Map MDEAutomator Functionality
**Status**: Complete  
**Implementation**: All 7 tabs mapped to DefenderC2 functions:

| MDEAutomator Feature | DefenderC2 Tab | Function Endpoint |
|---------------------|----------------|-------------------|
| Device Actions | 🎯 Defender C2 | `/api/DefenderC2Dispatcher` |
| Threat Intelligence | 🛡️ Threat Intel Manager | `/api/DefenderC2TIManager` |
| Action Management | 📋 Action Manager | `/api/DefenderC2Dispatcher` |
| Advanced Hunting | 🔍 Hunt Manager | `/api/DefenderC2HuntManager` |
| Incident Management | 🚨 Incident Manager | `/api/DefenderC2IncidentManager` |
| Custom Detections | ⚙️ Custom Detection Manager | `/api/DefenderC2CDManager` |
| Live Response | 🖥️ Interactive Console | `/api/DefenderC2Orchestrator` |

### 2. ✅ Retro Green/Black Theme
**Status**: Complete  
**Implementation**: Custom CSS with:
- **Colors**: Green (#00ff00) on Black (#000000)
- **Font**: Courier New, Consolas monospace
- **Effects**: 
  - CRT scanline simulation
  - Text glow effects
  - Blinking cursor animation
  - Matrix-style aesthetic
- **Location**: Header section (first item) with `<style>` tags

**CSS Classes Applied**:
```css
.workbook-content - Main container (black bg, green text)
.console-output - Interactive console area with enhanced styling
.status-success - Green glow for success messages
.status-warning - Yellow glow for warnings
.status-error - Red glow for errors
```

### 3. ✅ Autopopulate Parameters via Azure Resource Graph
**Status**: Complete  
**Parameters Auto-discovered**:

| Parameter | Method | Query Type |
|-----------|--------|------------|
| `Subscription` | Azure Resource Graph | `queryType: 1` |
| `Workspace` | Azure Resource Graph | `queryType: 1` |
| `ResourceGroup` | Azure Resource Graph | `queryType: 1` |
| `TenantId` | Azure Resource Graph | `queryType: 1` |
| `FunctionAppName` | Azure Resource Graph | `queryType: 1` |
| `DeviceList` | Custom Endpoint | `queryType: 10` |

**User Only Selects**:
1. Function App (dropdown)
2. Workspace (dropdown)

Everything else autodiscovers based on selected resources.

### 4. ✅ Custom Endpoints with Auto-Refresh
**Status**: Complete  
**Count**: 16 Custom Endpoint queries

**Configuration**:
```json
{
  "queryType": 10,
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ],
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "tablePath": "$.devices[*]",
        "columns": [...]
      }
    }
  ]
}
```

**Features**:
- ✅ Auto-refresh enabled (configurable intervals: 15s, 30s, 60s)
- ✅ JSONPath transformers for response parsing
- ✅ Dynamic URL parameters from workbook parameters
- ✅ Proper error handling and display

### 5. ✅ ARM Actions for Manual Input Operations
**Status**: Complete  
**Count**: 15 ARM Action buttons

**Implementation**: All manual actions use Azure Management API with correct URL parameters:

**Example - Isolate Device**:
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
    "headers": [
      {"name": "Content-Type", "value": "application/json"}
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
    "httpMethod": "POST",
    "description": "Isolate selected devices from network"
  }
}
```

**ARM Actions Available**:
- Device isolation/unisolation
- Application restriction
- Antivirus scans
- Indicator management (File, IP, URL, Domain, Certificate)
- Incident updates and comments
- Detection rule CRUD operations
- Library file upload/deployment

### 6. ✅ Interactive Shell for Live Response Commands
**Status**: Complete  
**Implementation**: 🖥️ Interactive Console tab

**Features**:
- ✅ **Shell-like UI** with retro terminal styling
- ✅ **Async command execution** via Function App
- ✅ **Auto-polling** for command status (configurable intervals)
- ✅ **Result display** with JSON parsing
- ✅ **Command history** tracking
- ✅ **Multi-action support** (all function endpoints accessible)

**Console Components**:
1. **Command Configuration**: Select command type and parameters
2. **Execute Command**: Trigger async execution
3. **Poll Status**: Auto-refresh command status
4. **View Results**: Parse and display JSON output
5. **History**: Track execution history

**Supported Command Types**:
- 🎯 DefenderC2Dispatcher (Device actions)
- 🔍 DefenderC2HuntManager (Advanced Hunting)
- 🛡️ DefenderC2TIManager (Threat Intelligence)
- 🚨 DefenderC2IncidentManager (Incident Management)
- ⚙️ DefenderC2CDManager (Custom Detections)
- 🎻 DefenderC2Orchestrator (Live Response & Library)

### 7. ✅ Library Operations (get, list, download)
**Status**: Complete  
**Implementation**: Integrated into Interactive Console tab

**Operations**:

| Operation | Implementation | Query Type |
|-----------|----------------|------------|
| **📚 List Library Files** | Custom Endpoint query with auto-refresh | `queryType: 10` |
| **📤 Upload to Library** | ARM Action with file content | ARM Action |
| **📥 Get Library File** | Custom Endpoint with file content display | `queryType: 10` |
| **🚀 Deploy from Library** | ARM Action to deploy to device(s) | ARM Action |

**Endpoints**:
```
List:   /api/DefenderC2Orchestrator?action=ListLibraryFiles&tenantId={TenantId}
Upload: /api/DefenderC2Orchestrator (POST with fileName, content, tenantId)
Get:    /api/DefenderC2Orchestrator?action=GetLibraryFile&fileName={name}&tenantId={TenantId}
Deploy: /api/DefenderC2Dispatcher (POST with action=PutFile, libraryFile=true)
```

---

## 🎨 Theme Customization

The workbook uses a custom retro terminal theme inspired by classic CRT monitors and Matrix-style interfaces.

### Theme Colors

| Element | Color | Hex Code | Effect |
|---------|-------|----------|--------|
| Background | Black | `#000000` | Main canvas |
| Text | Green | `#00ff00` | Primary color |
| Dark Green | Dark Green | `#001100` | Hover states |
| Very Dark Green | Very Dark Green | `#001a00` | Table headers |
| Yellow | Yellow | `#ffff00` | Warnings |
| Red | Red | `#ff0000` | Errors |

### Visual Effects

1. **Text Glow**: All green text has subtle glow effect
   ```css
   text-shadow: 0 0 10px #00ff00, 0 0 20px #00ff00;
   ```

2. **CRT Scanlines**: Simulated vintage monitor effect
   ```css
   background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%);
   background-size: 100% 2px;
   ```

3. **Blinking Cursor**: Terminal-style cursor animation
   ```css
   @keyframes blink {
     0%, 49% { opacity: 1; }
     50%, 100% { opacity: 0; }
   }
   ```

4. **Button Hover**: Inverted colors with glow on hover
   ```css
   button:hover {
     background-color: #00ff00 !important;
     color: #000000 !important;
     box-shadow: 0 0 10px #00ff00, 0 0 20px #00ff00;
   }
   ```

---

## 📊 Workbook Structure

### File Location
`/workbook/DefenderC2-Workbook.json` (2900+ lines)

### Item Breakdown

| Item # | Type | Name | Purpose |
|--------|------|------|---------|
| 0 | Text | `text - header` | Header with theme CSS and introduction |
| 1 | Parameters | `parameters - configuration` | Global parameters with autodiscovery |
| 2 | Links | `links - tabs` | Tab navigation (7 tabs) |
| 3 | Group | `group - automator` | Device Actions tab |
| 4 | Group | `group - threatintel` | Threat Intelligence tab |
| 5 | Group | `group - actions` | Action Manager tab |
| 6 | Group | `group - hunting` | Hunt Manager tab |
| 7 | Group | `group - incidents` | Incident Manager tab |
| 8 | Group | `group - detections` | Custom Detection Manager tab |
| 9 | Group | `group - console` | Interactive Console tab |

### Console Tab Structure (15 items)

1. **Console Header** - Enhanced with shell-like UI
2. **Configuration Parameters** - Command type, refresh interval, action name
3. **Step 1: Execute Command** - Trigger async execution
4. **Step 2: Poll Status** - Auto-refresh command status
5. **Step 3: View Results** - Display parsed JSON output
6. **Command History** - Track execution history
7. **Library List** - Display available library files
8. **Library Upload** - Upload files to library
9. **Library Get** - Retrieve file content
10. **Library Deploy** - Deploy library file to device(s)

---

## 🔗 Integration with Azure Functions

### Function Endpoints

All endpoints follow the pattern:
```
https://{FunctionAppName}.azurewebsites.net/api/{FunctionName}
```

**Available Functions**:
1. `DefenderC2Dispatcher` - Device actions
2. `DefenderC2TIManager` - Threat intelligence
3. `DefenderC2HuntManager` - Advanced hunting
4. `DefenderC2IncidentManager` - Incident management
5. `DefenderC2CDManager` - Custom detections
6. `DefenderC2Orchestrator` - Live Response & Library operations

### Authentication

- **Method**: Anonymous (no function keys required)
- **Tenant Auth**: Multi-tenant App Registration with Client Credentials flow
- **Parameters**: `tenantId` passed with every request
- **Identity**: Managed Identity for Function App to access Azure resources

### Request Format

**Custom Endpoint Query**:
```json
{
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

**ARM Action**:
```json
{
  "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
  "httpMethod": "POST"
}
```

---

## 🚀 Deployment

### Prerequisites

1. **Azure Subscription** with permissions to create:
   - Function App
   - Storage Account
   - Workbook

2. **Multi-tenant App Registration** with:
   - Client ID (APPID)
   - Client Secret (SECRETID)
   - API Permissions: `SecurityEvents.ReadWrite.All`, `Machine.ReadWrite.All`, etc.

### Deploy via ARM Template

```bash
az deployment group create \
  --resource-group defenderc2-rg \
  --template-file deployment/azuredeploy.json \
  --parameters \
    functionAppName=defenderc2-func \
    spnId=<YOUR_APP_ID> \
    spnSecret=<YOUR_SECRET>
```

### Manual Deployment

1. **Deploy Function App**:
   - Runtime: PowerShell 7.4
   - OS: Linux
   - Plan: Consumption

2. **Configure App Settings**:
   ```
   APPID=<your-app-id>
   SECRETID=<your-secret>
   ```

3. **Deploy Functions**:
   ```bash
   cd functions
   func azure functionapp publish <function-app-name>
   ```

4. **Import Workbook**:
   - Open Azure Portal
   - Navigate to Azure Monitor → Workbooks
   - Click "New" → "Advanced Editor"
   - Paste contents of `workbook/DefenderC2-Workbook.json`
   - Save workbook

---

## 📚 Usage Guide

### Getting Started

1. **Open Workbook** in Azure Portal
2. **Select Function App** from dropdown (auto-populated list)
3. **Select Workspace** from dropdown (auto-populated list)
4. **All other parameters autodiscover**:
   - Subscription ID
   - Resource Group
   - Function App Name
   - Tenant ID
5. **Navigate tabs** to access different capabilities

### Tab-by-Tab Guide

#### 🎯 Defender C2 (Device Actions)
**Purpose**: Execute response actions on devices

**Available Actions**:
- 🚨 Isolate Devices
- 🔓 Unisolate Devices
- 🛡️ Restrict App Execution
- 🔍 Run Antivirus Scan
- 📦 Collect Investigation Package

**Workflow**:
1. Select device(s) from auto-populated list
2. Choose action type
3. Click action button
4. View results in Action Manager tab

#### 🛡️ Threat Intel Manager
**Purpose**: Manage threat indicators

**Available Operations**:
- 📄 Add File Indicators (SHA1, SHA256, MD5)
- 🌐 Add IP Indicators
- 🔗 Add URL/Domain Indicators
- 🔐 Add Certificate Indicators

**Workflow**:
1. Select indicator type
2. Enter indicator value(s) (comma-separated)
3. Set severity and recommended action
4. Click "Add Indicators"
5. View confirmation

#### 📋 Action Manager
**Purpose**: Track device action status

**Features**:
- Auto-refresh list of all actions
- Filter by status, device, action type
- View action details and results
- Cancel pending actions

#### 🔍 Hunt Manager
**Purpose**: Execute advanced hunting queries

**Features**:
- Custom KQL query input
- Pre-defined hunting templates
- Results table with export
- Auto-refresh capability

#### 🚨 Incident Manager
**Purpose**: Manage security incidents

**Available Operations**:
- Update incident status
- Assign to user
- Add comments
- Change severity
- Bulk operations

#### ⚙️ Custom Detection Manager
**Purpose**: Manage custom detection rules

**Available Operations**:
- Create new detection rules
- Update existing rules
- Delete rules
- Backup/export rules

#### 🖥️ Interactive Console
**Purpose**: Execute Live Response commands and manage library

**Features**:
- **Command Execution**: Async execution with auto-polling
- **Library Management**: Upload, list, download files
- **File Deployment**: Deploy library files to devices
- **Command History**: Track execution history

**Workflow**:
1. Select command type
2. Configure parameters
3. Execute command
4. Poll for status
5. View results

---

## 🔧 Troubleshooting

### Common Issues

#### Parameter Not Autopopulating
**Symptom**: Dropdown shows "No items found"  
**Solution**:
1. Verify Function App is deployed and running
2. Check Resource Graph permissions
3. Refresh workbook
4. Verify parameter dependencies

#### Custom Endpoint Returns 401/403
**Symptom**: "Unauthorized" or "Forbidden" errors  
**Solution**:
1. Verify Function App authentication settings (should be anonymous)
2. Check App Registration permissions
3. Verify `tenantId` parameter is correct
4. Check Function App logs for detailed error

#### ARM Action Fails
**Symptom**: Action button shows error  
**Solution**:
1. Verify parameter values are populated
2. Check Function App endpoint URL
3. Verify request body format
4. Check Function App logs

#### Theme Not Applied
**Symptom**: Workbook shows default Azure theme  
**Solution**:
1. Verify `<style>` tags are present in header
2. Check browser console for CSS errors
3. Clear browser cache
4. Verify workbook JSON is valid

### Debug Mode

Enable debug mode by viewing Function App logs:
```bash
az webapp log tail --name <function-app-name> --resource-group <rg>
```

---

## 📈 Performance Optimization

### Auto-Refresh Intervals

Recommended intervals by tab:

| Tab | Interval | Reason |
|-----|----------|--------|
| Device Actions | 30s | Moderate update frequency |
| Threat Intel | 60s | Low update frequency |
| Action Manager | 15s | High update frequency |
| Hunt Manager | Manual | User-driven queries |
| Incident Manager | 30s | Moderate update frequency |
| Detection Manager | 60s | Low update frequency |
| Interactive Console | 10-30s | Varies by command type |

### Query Optimization

- Use JSONPath transformers to reduce data transfer
- Limit result sets with filters
- Use pagination for large datasets
- Cache static data (device lists, indicators)

---

## 🔒 Security Considerations

### Authentication
- Function App uses **anonymous** authentication for workbook access
- Backend authentication via **Multi-tenant App Registration**
- **No function keys** exposed in workbook
- **TenantId** passed with every request for multi-tenancy

### Data Protection
- All communication over HTTPS
- No sensitive data stored in workbook parameters
- Results displayed in workbook only
- Azure RBAC controls workbook access

### Permissions Required

**App Registration**:
- `SecurityEvents.ReadWrite.All`
- `Machine.ReadWrite.All`
- `ThreatIndicators.ReadWrite.OwnedBy`
- `AdvancedHunting.Read.All`

**User**:
- Workbook Reader (minimum)
- Function App Contributor (for deployment)

---

## 📝 Maintenance

### Regular Tasks

**Weekly**:
- Review action history
- Check function app health
- Verify authentication status

**Monthly**:
- Update function app runtime
- Review and optimize queries
- Update detection rules

**Quarterly**:
- Backup workbook JSON
- Review and update theme
- Update documentation

### Monitoring

Monitor the following metrics:
- Function App execution count
- Error rates
- Response times
- Authentication failures

---

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Reporting issues
- Submitting changes
- Code style
- Testing requirements

---

## 📚 Additional Resources

- [Original MDEAutomator](https://github.com/msdirtbag/MDEAutomator)
- [Azure Workbooks Documentation](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Defender for Endpoint API](https://learn.microsoft.com/microsoft-365/security/defender-endpoint/api/apis-intro)
- [Advanced Workbook Concepts](../archive/old-workbooks/Advanced%20Workbook%20Concepts.json)

---

## 📄 License

See [LICENSE](../LICENSE) file for details.

---

**Last Updated**: 2025-10-13  
**Version**: 1.0  
**Status**: ✅ Production Ready
