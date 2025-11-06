# 🚀 Deploy DefenderC2 Complete Workbook - Quick Guide

## 📋 Prerequisites

- [x] Azure subscription with active Defender XDR
- [x] DefenderC2 Function App deployed (all 6 functions)
- [x] Azure AD App Registration with Defender API permissions
- [x] Contributor/Website Contributor role on Function App resource group

## 🎯 Quick Deploy (5 Minutes)

### Step 1: Get Workbook JSON

```powershell
# Copy workbook to clipboard
Get-Content "c:\Users\AlexandrosKefallonit\Desktop\FF\defenderc2xsoar\workbook\DefenderC2-Complete.json" | Set-Clipboard
```

**OR** open the file in VS Code and copy all content.

### Step 2: Create Workbook in Azure Portal

1. **Navigate**: Azure Portal → Monitor → Workbooks
2. **Create**: Click "+ New"
3. **Edit**: Click "</> Advanced Editor" (top toolbar)
4. **Gallery Template**: Select "Empty" or keep default
5. **Paste**: Replace entire JSON with copied content
6. **Apply**: Click "Apply" button

### Step 3: Configure Parameters

Fill in the required parameters (top of workbook):

```
Subscription:     [Select your Azure subscription]
ResourceGroup:    [Resource group with Function App]
FunctionAppName:  defenderc2  (or your function app name)
TenantId:         a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9  (your Azure AD tenant)
```

**Main Tab**: Select "dashboard" to start

### Step 4: Save Workbook

1. **Save**: Click "Save" (💾) icon
2. **Title**: "DefenderC2 Complete Workbook"
3. **Subscription**: [Select subscription]
4. **Resource Group**: [Select resource group]
5. **Location**: [Select region]
6. **Click**: "Apply"

### Step 5: Test Functionality

1. **Dashboard Tab**: Should show device/incident stats
2. **Device Management**: 
   - Verify device list loads
   - Select a device
   - Choose "Run Antivirus Scan" from dropdown
   - Verify execution
3. **Other Tabs**: Test each module

## 🔍 Verification Checklist

After deployment, verify:

- [ ] Dashboard shows statistics
- [ ] Device list populates in Device Management
- [ ] Action dropdowns appear in each module
- [ ] Selecting action shows action group
- [ ] CustomEndpoint queries auto-refresh
- [ ] ARMEndpoint actions execute successfully

## ⚙️ Parameter Reference

### Required Parameters
| Parameter | Example | Description |
|-----------|---------|-------------|
| `Subscription` | Production | Azure subscription |
| `ResourceGroup` | defenderc2-rg | Function App resource group |
| `FunctionAppName` | defenderc2 | Function App name (without .azurewebsites.net) |
| `TenantId` | a92a42cd-... | Azure AD tenant ID |

### Global Parameters (Auto-created)
| Parameter | Type | Purpose |
|-----------|------|---------|
| `MainTab` | Dropdown | Tab navigation |
| `AutoRefresh` | Dropdown | Auto-refresh interval |
| `DeviceActionTrigger` | Dropdown | Device management actions |
| `LRActionTrigger` | Dropdown | Live Response actions |
| `LibraryActionTrigger` | Dropdown | File Library actions |
| `HuntingActionTrigger` | Dropdown | Advanced Hunting actions |
| `TIActionTrigger` | Dropdown | Threat Intelligence actions |
| `DetectionActionTrigger` | Dropdown | Custom Detection actions |

## 🧪 Test Each Module

### 1. Dashboard ✅
- Should load automatically
- Shows device count, incident count, risk distribution

### 2. Device Management ✅
**Test Scan:**
1. Select "devices" tab
2. Wait for device list to load
3. Click a device row (auto-populates `DeviceList`)
4. Select "🔍 Run Antivirus Scan" from dropdown
5. Verify action group appears
6. Check results table

**Test Other Actions:**
- Isolate/Unisolate (⚠️ destructive - use test device)
- Collect Investigation Package
- Restrict/Unrestrict App (⚠️ destructive - use test device)
- Quarantine File (requires SHA256 hash)

### 3. Live Response ✅
**Test Script Execution:**
1. Select "liveresponse" tab
2. Wait for device list
3. Select device
4. Enter script name (must exist in library)
5. Select "🔍 Run Library Script" from dropdown
6. Verify execution

**Test File Retrieval:**
1. Enter file path (e.g., `C:\Windows\System32\notepad.exe`)
2. Select "📥 Get File from Device" from dropdown
3. Check results (Base64 content)

### 4. File Library ✅
**Test Download:**
1. Select "library" tab
2. Wait for file list
3. Click a file row
4. Select "📥 Download File" from dropdown
5. Verify Base64 content returned

**Test Delete (⚠️ destructive):**
1. Select test file
2. Select "🗑️ Delete File" from dropdown
3. Verify deletion

### 5. Advanced Hunting ✅
**Test Query:**
1. Select "hunting" tab
2. Choose sample query or enter custom KQL
3. Enter query name
4. Select "🔍 Execute Hunt Query" from dropdown
5. Verify results

**Sample Query:**
```kql
DeviceInfo
| where Timestamp > ago(7d)
| summarize count() by OSPlatform
```

### 6. Threat Intelligence ✅
**Test File Indicator:**
1. Select "threatintel" tab
2. Enter SHA256 hash
3. Enter title, severity, action
4. Select "➕ Add File Indicator" from dropdown
5. Verify creation

**Test IP/URL:**
- Use same process with IP addresses or URLs

### 7. Incident Management ✅
- Should auto-load incidents
- No manual actions (CustomEndpoint only)

### 8. Custom Detections ✅
**Test Detection Creation:**
1. Select "detections" tab
2. Enter detection name
3. Enter KQL query
4. Select severity
5. Select "➕ Create Detection Rule" from dropdown
6. Verify creation

## 🐛 Troubleshooting

### Issue: "No data available"
**Solutions:**
- Check Function App is running
- Verify App Settings: `APPID`, `SECRETID`, `TENANTID`
- Check RBAC permissions on Function App
- Verify tenant ID is correct

### Issue: "Authorization failed"
**Solutions:**
- Add user to "Contributor" role on Function App resource group
- Or add "Website Contributor" role
- Re-login to Azure Portal

### Issue: Action doesn't execute
**Solutions:**
- Verify all required parameters filled
- Check action dropdown is selected
- Ensure conditional visibility criteria met
- Check Function App logs for errors

### Issue: Results show error message
**Solutions:**
- Check Function App logs (Application Insights)
- Verify API permissions on App Registration
- Check Defender XDR API quota limits
- Ensure tenant ID matches Defender instance

## 📊 Expected Behavior

### CustomEndpoint Queries (Auto-refresh)
- Execute automatically when visible
- Refresh based on `AutoRefresh` parameter
- Display results in tables
- Support sorting, filtering, selection

### ARMEndpoint Actions (Manual)
- Execute when dropdown selected + parameters filled
- Show results immediately
- Display in table format
- Support copy, export

## 🔐 Security Notes

1. **RBAC**: Users need Contributor/Website Contributor role
2. **API Keys**: Never exposed in workbook (stored in Function App)
3. **Audit**: All actions logged in Activity Log
4. **Destructive Actions**: Clearly marked (isolate, restrict, delete)
5. **Parameter Validation**: Basic validation only (be careful!)

## 📈 Performance Tips

1. **Auto-Refresh**: Set to 1m or 5m for better performance
2. **Large Results**: Use filters to limit result sets
3. **Concurrent Users**: Function App scales automatically
4. **Heavy Queries**: Use Advanced Hunting with time filters
5. **API Limits**: Defender XDR has rate limits (50 req/min)

## 🆘 Support Resources

- **Function App Logs**: Azure Portal → Function App → Log Stream
- **Application Insights**: Monitor → Application Insights → Logs
- **Activity Log**: Monitor → Activity log (filter by Function App)
- **Defender API Docs**: https://learn.microsoft.com/en-us/defender-xdr/api-overview
- **Workbook Docs**: https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview

## ✅ Success Indicators

After deployment, you should see:

- ✅ Dashboard loads with stats
- ✅ Device list populates (48 devices expected for test tenant)
- ✅ Action dropdowns functional
- ✅ Actions execute and return results
- ✅ Auto-refresh working
- ✅ Parameter auto-population working
- ✅ All 8 tabs accessible
- ✅ No JavaScript errors in browser console

## 🎓 Training Resources

### For Analysts
- **Dashboard**: Overview of security posture
- **Device Management**: Incident response actions
- **Live Response**: Remote investigation
- **Advanced Hunting**: Threat hunting queries
- **Threat Intelligence**: IOC management

### For SOC Leads
- **Incident Management**: Incident triage
- **Custom Detections**: Detection rule management
- **File Library**: Script/tool management

### For Automation
- **API Integration**: Use Function App directly for automation
- **Playbooks**: Integrate with Logic Apps/Power Automate
- **SOAR**: Connect to Sentinel or third-party SOAR

---

**Ready to Deploy!** 🚀

Follow the 5-step quick deploy and you'll have a fully functional DefenderC2 workbook in minutes.
