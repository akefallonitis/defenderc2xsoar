# DefenderC2 Workbook - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Deploy Infrastructure (One-Click)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**What gets deployed**:
- ✅ Azure Function App (PowerShell 7.4)
- ✅ 6 DefenderC2 Functions
- ✅ Storage Account
- ✅ App Service Plan
- ✅ DefenderC2 Workbook

**Required inputs during deployment**:
- Resource Group name
- Function App name
- App Registration Client ID (`APPID`)
- App Registration Client Secret (`SECRETID`)

### Step 2: Open Workbook
1. Navigate to Azure Portal → Azure Monitor → Workbooks
2. Find "DefenderC2 Command & Control Console"
3. Click to open

### Step 3: Configure (2 clicks!)
1. **Select Function App**: Choose your deployed Function App from dropdown
2. **Select Workspace**: Choose your Log Analytics Workspace

**That's it!** All other parameters (Subscription, Resource Group, Tenant ID, Function App Name) autodiscover.

---

## 🎨 What You Get

### Retro Terminal Theme 🖥️
- **Colors**: Matrix-style green (#00ff00) on black (#000000)
- **Font**: Monospace (Courier New, Consolas)
- **Effects**: CRT scanlines, text glow, blinking cursor
- **Style**: Vintage terminal aesthetic

### 7 Functional Tabs

| Icon | Tab Name | Purpose | Key Features |
|------|----------|---------|--------------|
| 🎯 | **Defender C2** | Device Actions | Isolate, scan, restrict devices |
| 🛡️ | **Threat Intel Manager** | Indicators | Manage file/IP/URL/certificate indicators |
| 📋 | **Action Manager** | Track Actions | View and manage device action status |
| 🔍 | **Hunt Manager** | Advanced Hunting | Execute KQL queries across environment |
| 🚨 | **Incident Manager** | Incident Response | Update, assign, comment on incidents |
| ⚙️ | **Custom Detection Manager** | Detection Rules | CRUD operations on custom rules |
| 🖥️ | **Interactive Console** | Live Response | Shell-like command execution + library |

---

## 💡 Common Tasks

### Isolate a Device
1. Navigate to **🎯 Defender C2** tab
2. Scroll to "Isolate Device" section
3. Select device(s) from dropdown (auto-populated)
4. Select isolation type (Full or Selective)
5. Click **🚨 Isolate Devices** button
6. Confirm action in dialog
7. View result in Action Manager tab

### Add Threat Indicators
1. Navigate to **🛡️ Threat Intel Manager** tab
2. Scroll to indicator type (File/IP/URL/Certificate)
3. Enter indicator value(s) - comma-separated for multiple
4. Set title, severity, and recommended action
5. Click **Add Indicators** button
6. View confirmation

### Execute Advanced Hunting Query
1. Navigate to **🔍 Hunt Manager** tab
2. Enter KQL query in text box
3. Set time range
4. Click **Execute Query** button
5. View results in table below
6. Export to Excel if needed

### Manage Incident
1. Navigate to **🚨 Incident Manager** tab
2. Select incident from auto-populated list
3. Update status, severity, or assignment
4. Add comments if needed
5. Click **Update Incident** button
6. View confirmation

### Execute Live Response Command
1. Navigate to **🖥️ Interactive Console** tab
2. Select command type from dropdown
3. Enter device ID(s) and command parameters
4. Click **Execute Command**
5. Monitor status with auto-refresh
6. View results when complete

### Upload to Library
1. Navigate to **🖥️ Interactive Console** tab
2. Select **📤 Upload to Library** from command type
3. Enter file name
4. Enter file content (text or Base64 encoded)
5. Click **Upload** button
6. File is now available in library

### Deploy from Library
1. Navigate to **🖥️ Interactive Console** tab
2. Select **🚀 Deploy from Library** from command type
3. Select file from library list
4. Select target device(s)
5. Click **Deploy** button
6. File is deployed to device(s)

---

## 📊 Parameter Autodiscovery

### Global Parameters (Auto-populated)

| Parameter | How It's Discovered | When It Updates |
|-----------|---------------------|-----------------|
| **Subscription** | From Function App resource | When Function App changes |
| **Resource Group** | From Function App resource | When Function App changes |
| **Function App Name** | From Function App resource | When Function App changes |
| **Tenant ID** | From Function App resource | When Function App changes |
| **Device List** | Custom Endpoint query to Defender API | Auto-refresh every 30s |

### What You Select

1. **Function App**: Choose from dropdown (filtered to Function Apps in your subscriptions)
2. **Workspace**: Choose from dropdown (filtered to Log Analytics Workspaces)

Everything else is automatic!

---

## 🎯 Quick Troubleshooting

### Device List Empty
**Problem**: Device dropdown shows "No items found"

**Solutions**:
- ✅ Wait 30 seconds for auto-refresh
- ✅ Verify Function App is running
- ✅ Check App Registration has correct permissions
- ✅ Verify `tenantId` is correct for your Defender environment

### Action Button Fails
**Problem**: ARM Action returns error

**Solutions**:
- ✅ Verify device ID is valid and selected
- ✅ Check Function App logs for detailed error
- ✅ Verify App Registration permissions
- ✅ Ensure Function App authentication is set to "Anonymous"

### Theme Not Applied
**Problem**: Workbook shows default Azure blue theme

**Solutions**:
- ✅ Clear browser cache and refresh
- ✅ Verify workbook JSON includes `<style>` tags in header
- ✅ Check browser console for CSS errors

### Custom Endpoint Returns 401
**Problem**: "Unauthorized" error on queries

**Solutions**:
- ✅ Function App must have "Anonymous" authentication
- ✅ Verify App Registration credentials in Function App settings
- ✅ Check `APPID` and `SECRETID` environment variables
- ✅ Verify App Registration has correct API permissions

---

## 🔧 Advanced Configuration

### Auto-Refresh Intervals

Customize refresh intervals for each tab by editing query settings:

**Fast** (10-15s): Action Manager, Console  
**Medium** (30s): Device Actions, Incident Manager  
**Slow** (60s): Threat Intel, Detection Manager  
**Manual**: Hunt Manager

### Custom Commands in Console

Add your own commands by:
1. Creating new parameter for command type
2. Adding new Custom Endpoint query
3. Configuring JSONPath transformer
4. Adding to command type dropdown

### Theme Customization

Modify the CSS in the header section (first item) to change:
- Colors (search/replace `#00ff00` for green, `#000000` for black)
- Font (change `'Courier New', 'Consolas', monospace`)
- Effects (modify `text-shadow`, `box-shadow` properties)
- Animations (adjust `@keyframes` rules)

---

## 📚 Key Endpoints

All endpoints follow this pattern:
```
https://{FunctionAppName}.azurewebsites.net/api/{FunctionName}
```

| Function | Purpose | Common Actions |
|----------|---------|----------------|
| `DefenderC2Dispatcher` | Device actions | Get Devices, Isolate, Scan |
| `DefenderC2TIManager` | Threat intel | Add/List Indicators |
| `DefenderC2HuntManager` | Hunting | Execute Query |
| `DefenderC2IncidentManager` | Incidents | Update, Comment |
| `DefenderC2CDManager` | Detections | Create/Update/Delete Rules |
| `DefenderC2Orchestrator` | Live Response | Library operations |

---

## ✅ Pre-flight Checklist

Before using the workbook, verify:

- [ ] Function App is deployed and running
- [ ] App Registration has correct permissions:
  - [ ] `SecurityEvents.ReadWrite.All`
  - [ ] `Machine.ReadWrite.All`
  - [ ] `ThreatIndicators.ReadWrite.OwnedBy`
  - [ ] `AdvancedHunting.Read.All`
- [ ] Environment variables set in Function App:
  - [ ] `APPID` (Client ID)
  - [ ] `SECRETID` (Client Secret)
- [ ] Function App authentication is "Anonymous"
- [ ] Workbook is imported and visible
- [ ] User has "Workbook Reader" or higher role

---

## 🆘 Getting Help

1. **Check Documentation**:
   - [Full Documentation](docs/WORKBOOK_MDEAUTOMATOR_PORT.md)
   - [Custom Endpoint Guide](docs/WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md)
   - [Contributing Guide](CONTRIBUTING.md)

2. **View Function Logs**:
   ```bash
   az webapp log tail \
     --name <function-app-name> \
     --resource-group <resource-group>
   ```

3. **Common Issues**:
   - [Deployment Troubleshooting](DEPLOYMENT.md#troubleshooting)
   - [Authentication Issues](FUNCTION_APP_AUTH_CONFIG.md)
   - [Parameter Binding Problems](TROUBLESHOOTING_PARAMETER_BINDING.md)

4. **Open an Issue**:
   - [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)

---

## 🎓 Learning Resources

- **MDEAutomator Original**: https://github.com/msdirtbag/MDEAutomator
- **Azure Workbooks**: https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview
- **Defender API**: https://learn.microsoft.com/microsoft-365/security/defender-endpoint/api/apis-intro
- **Advanced Workbook Concepts**: See `archive/old-workbooks/Advanced Workbook Concepts.json`

---

## 🚀 What's Next?

After getting started, explore:

1. **Customize Theme**: Modify colors, fonts, effects
2. **Add Custom Commands**: Create new automation workflows
3. **Create Dashboards**: Build custom views for your team
4. **Automate Response**: Chain actions together
5. **Export Data**: Use Excel export for reporting

---

**Ready to get started? Deploy now!** ⬇️

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

---

**Last Updated**: 2025-10-13  
**Version**: 1.0  
**Status**: ✅ Production Ready
