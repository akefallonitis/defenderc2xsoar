# DefenderC2 Workbook - Zero-Configuration Deployment

## Overview

The **DefenderC2 Command & Control Console** provides enterprise-grade automation for Microsoft Defender for Endpoint with **zero manual configuration required**.

## 🚀 What's New: Enhanced Auto-Discovery

### Key Improvements

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

## 🎯 Quick Start

### 1. Prerequisites
- Azure subscription with Sentinel/Log Analytics workspace
- DefenderC2 Function App deployed (with 'defenderc2' in name or Project tag)
- Multi-tenant app registration with MDE API permissions

### 2. Deploy Workbook

1. Open Azure Portal → **Monitor** → **Workbooks**
2. Click **New** → **Advanced Editor** (`</>` icon)
3. Copy contents of `DefenderC2-Workbook.json`
4. Paste into editor and click **Apply**
5. Save with title: **DefenderC2 Command & Control Console**

### 3. Configure (Zero Configuration Required!)

1. **Select Subscription** - Choose your Azure subscription
2. **Select Workspace** - Choose your Log Analytics workspace
3. **Done!** - All other settings auto-discover:
   - ✅ Tenant ID (from workspace)
   - ✅ Function App URL (auto-discovered via ARG query)
   - ✅ Service Principal ID (read from function app env vars)
   - ✅ Authentication (anonymous - no keys needed)

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

### v2.0 - Enhanced Auto-Discovery (Current)
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
