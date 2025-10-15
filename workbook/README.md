# DefenderC2 Workbook - Zero-Configuration Deployment

## Overview

The **DefenderC2 Command & Control Console** provides enterprise-grade automation for Microsoft Defender for Endpoint with **zero manual configuration required**.

## 🚀 What's New: Enhanced Auto-Discovery & Auto-Populated Parameters

### Key Improvements

✅ **Device Parameter Auto-Population** - Device lists automatically populated from Defender environment  
✅ **Multi-Select Device Dropdowns** - Select multiple devices for bulk actions  
✅ **Auto-Refresh Queries** - Action manager and hunt status auto-refresh every 30 seconds  
✅ **Anonymous Function Authentication** - No function keys required  
✅ **Automatic Resource Discovery** - Function Apps auto-discovered via Azure Resource Graph  
✅ **Environment Variable Integration** - Service Principal ID read from function app settings  
✅ **Cross-Subscription Discovery** - Find resources anywhere in your subscription  
✅ **Zero Configuration UX** - Just select subscription and workspace, everything else auto-populates

## 📁 Files

### DefenderC2-Workbook.json
The main operational workbook featuring:
- **Zero-config deployment** - Only requires subscription and workspace selection
- **7 functional tabs** for complete MDE automation
- **Auto-discovery** for all infrastructure components
- **Anonymous functions** - No authentication keys needed
- **Enterprise-ready** branding and user experience

### FileOperations.workbook
Specialized workbook for file operations:
- Azure Storage library management
- File deployment to devices
- Live Response file operations

### DeviceManager-Testing.workbook.json ⭐ NEW
Comprehensive device functionality testing workbook:
- **Complete device action testing** - All 6 device action types
- **Auto-populated device lists** - Devices load automatically
- **Real-time monitoring** - Auto-refresh status tracking (30s default)
- **Conflict detection** - Checks for running actions before execution
- **Action management** - Track and cancel actions
- **Conditional visibility** - Smart UI shows only relevant sections
- **Comprehensive documentation** - See [DEVICE_TESTING_GUIDE.md](../DEVICE_TESTING_GUIDE.md)

**Device Actions Tested:**
- 🔍 Antivirus Scan (Quick/Full)
- 🔒 Device Isolation (Full/Selective)
- 🔓 Device Unisolation
- 📦 Investigation Package Collection
- 🚫 App Execution Restriction
- ✅ App Execution Unrestriction

**Use Case:** Ideal for testing device functionality, validating API integration, and verifying action execution before production use.

## 🎯 Quick Start

### 1. Automatic Deployment

**🎉 The workbook is automatically deployed when you use the "Deploy to Azure" button!**

The ARM template (`deployment/azuredeploy.json`) includes the workbook embedded as base64-encoded content. When you deploy the solution, you get:
- ✅ Azure Function App
- ✅ DefenderC2 Command & Control Workbook (automatically deployed)
- ✅ Storage Account and App Service Plan
- ✅ All configuration and settings

### 2. Access Your Workbook

After deployment completes:

1. Open Azure Portal → **Monitor** → **Workbooks**
2. Look for **"DefenderC2 Command & Control Console"**
3. Click to open it
4. Pin it to your dashboard for quick access

### 3. Configure (Zero Configuration Required!)

1. **Select Subscription** - Choose your Azure subscription
2. **Select Workspace** - Choose your Log Analytics workspace
3. **Done!** - All other settings auto-discover:
   - ✅ Tenant ID (from workspace)
   - ✅ Function App URL (auto-discovered via ARG query)
   - ✅ Service Principal ID (read from function app env vars)
   - ✅ Authentication (anonymous - no keys needed)

### Alternative: Manual Deployment (Advanced Users Only)

If you need to manually deploy or update the workbook:

1. Open Azure Portal → **Monitor** → **Workbooks**
2. Click **New** → **Advanced Editor** (`</>` icon)
3. Copy contents of `DefenderC2-Workbook.json`
4. Paste into editor and click **Apply**
5. Save with title: **DefenderC2 Command & Control Console**

## 🔧 How Auto-Discovery Works

### Function App Discovery
The workbook uses Azure Resource Graph (ARG) to find your Function App:

```kql
Resources 
| where type =~ 'microsoft.web/sites' 
| where kind =~ 'functionapp' 
| where name contains 'defenderc2' or tags['Project'] =~ 'defenderc2'
| extend FunctionUrl = strcat('https://', name, '.azurewebsites.net')
| project FunctionUrl 
| limit 1
```

**Search Criteria:**
- Function App with 'defenderc2' in the name, OR
- Function App with `Project=defenderc2` tag

### Service Principal Discovery
The Service Principal ID (Client ID) is stored in the Function App's environment variables:
- Environment variable: `APPID`
- Set during function app deployment
- Read by functions at runtime (no workbook configuration needed)

## 🎛️ Auto-Populated Device Parameters

### Device Selection Made Easy
Device parameters are now automatically populated from your Defender environment:

**Benefits:**
- **No manual ID entry** - Select devices from dropdown
- **Device names shown** - See computer names, not just IDs
- **Multi-select support** - Choose multiple devices for bulk actions
- **Always up-to-date** - Device list refreshes automatically

**How It Works:**
1. Workbook queries DefenderC2Dispatcher endpoint for device list
2. JSONPath parses response to extract device IDs and names
3. Devices appear in dropdown with computer name and ID
4. Select one or more devices for your action
5. Device IDs automatically passed to Function App

**Affected Actions:**
- ✅ Isolate Device
- ✅ Unisolate Device
- ✅ Restrict App Execution
- ✅ Run Antivirus Scan

**Technical Details:**
- Uses Custom Endpoint (queryType: 10)
- POST to `/api/DefenderC2Dispatcher` with action "Get Devices"
- JSONPath: `$.devices[*]` with columns for ID and computerDnsName
- Multi-select enabled for all device parameters

For full technical documentation, see: [DEVICE_PARAMETER_AUTOPOPULATION.md](../deployment/DEVICE_PARAMETER_AUTOPOPULATION.md)

## 🔄 Auto-Refresh Queries

Critical monitoring queries now auto-refresh:

**Action Manager:**
- Auto-refreshes every 30 seconds
- Shows real-time status of device actions
- Includes status indicators (✅ Succeeded, ⏳ In Progress, ❌ Failed)

**Hunt Status:**
- Auto-refreshes every 30 seconds  
- Shows status of advanced hunting queries
- Updates automatically as queries complete

### Anonymous Authentication
All functions are configured with `"authLevel": "anonymous"`:
- No function keys required
- Secure for internal Azure calls
- Simplified user experience
- Zero friction deployment

## 📊 Workbook Features

### Core Tabs
1. **Defender C2 (Device Actions)** - Isolate, scan, restrict devices
2. **Threat Intel Manager** - Manage indicators (files, IPs, URLs)
3. **Action Manager** - View and manage MDE actions
4. **Hunt Manager** - Execute advanced hunting queries
5. **Incident Manager** - Manage security incidents
6. **Custom Detection Manager** - Manage detection rules
7. **Interactive Console** - Command-line interface for advanced operations

### Enhanced User Experience
- **Visual Status Indicators** - See what was auto-discovered
- **Minimal Input Required** - Only 2 selections needed
- **Professional Branding** - DefenderC2 naming throughout
- **Error Handling** - Clear messages if resources not found

## 🔒 Security Considerations

### Anonymous Functions
While functions are anonymous, they:
- Are only accessible within Azure (CORS configured)
- Still require valid tenant authentication
- Use client credentials flow for MDE API access
- Don't expose sensitive data

### Network Isolation (Optional)
For enhanced security:
- Configure VNet integration for function app
- Use Private Endpoints for storage
- Enable Azure Firewall rules

### Credential Management
- Service Principal credentials stored as function app settings (encrypted)
- No credentials in workbook JSON
- Client secret can be rotated without workbook changes

## 🐛 Troubleshooting

### Function App Not Found
If auto-discovery fails:
1. Ensure function app name contains 'defenderc2', OR
2. Add tag `Project=defenderc2` to function app
3. Verify function app is in selected subscription
4. Check you have Reader permissions on subscription

### Functions Return Errors
If API calls fail:
1. Verify `APPID` and `SECRETID` environment variables are set in function app
2. Check app registration has required MDE API permissions
3. Verify admin consent granted for API permissions
4. Review function logs in Application Insights

### Tenant ID Issues
If tenant ID is wrong:
1. Ensure workspace is in correct subscription
2. Try reloading the workbook
3. Check workspace resource in Azure Portal

## 📚 Additional Documentation

- **[Main README](../README.md)** - Project overview
- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Full deployment guide
- **[QUICKSTART.md](../QUICKSTART.md)** - Quick start guide
- **[Archive Documentation](../archive/)** - Detailed technical docs

## 🆘 Support

For issues or questions:
1. Check [Troubleshooting Guide](../archive/deployment-guides/DEPLOYMENT_TROUBLESHOOTING.md)
2. Review [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
3. Open a new issue with details

## 📝 Version History

### v2.1 - Auto-Populated Device Parameters (Current)
- **Device parameter auto-population** from Defender environment
- **Multi-select dropdowns** for all device actions
- **Auto-refresh** for action manager (30s interval)
- **Auto-refresh** for hunt status queries (30s interval)
- **JSONPath parsing** for device list responses
- Enhanced user experience with dropdown selections

### v2.0 - Enhanced Auto-Discovery
- Anonymous function authentication
- Automatic Function App discovery
- Service Principal from environment variables
- Rebranded to DefenderC2
- Zero-configuration deployment

### v1.0 - Initial Release
- Manual configuration required
- Function key authentication
- Manual resource entry
- MDEAutomator branding
