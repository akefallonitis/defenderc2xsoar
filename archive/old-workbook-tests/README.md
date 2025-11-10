# DeviceManager Workbook Versions

## Overview
This folder contains three versions of the DefenderC2 Device Manager workbook, each optimized for different use cases.

## Version 1: CustomEndpoint-Only
**File:** `DeviceManager-CustomEndpoint-Only.workbook.json`

### Features
- ✅ **All CustomEndpoint queries** for maximum compatibility
- ✅ **Auto-refresh capability** for real-time updates
- ✅ **Auto-population** of devices and tenants
- ✅ **Pending action detection** with warnings
- ✅ **Action ID auto-population** for tracking
- ✅ **Cancel functionality** with proper error handling
- ✅ **Full machine actions history**

### Best For
- **Production environments** requiring maximum stability
- **Consistent behavior** across all Azure regions
- **Simplified troubleshooting** (single query type)
- **Auto-refresh requirements** for monitoring dashboards

### How It Works
1. Select Function App → Auto-populates connection parameters
2. Select Tenant → Auto-populates from Azure Resource Graph
3. Select Devices → Auto-populates from Defender XDR API
4. Pending Actions Check → Warns if same action is already running
5. Execute Action → Returns Action IDs for tracking
6. Auto-refresh → Updates every 30 seconds (configurable)

### Key Advantages
- **No ARM routing issues** - Direct HTTPS calls
- **Better error messages** - Clear API responses
- **Easier debugging** - Standard HTTP requests
- **Consistent behavior** - Works the same everywhere

## Version 2: TRUE Hybrid (CustomEndpoint + ARMEndpoint) ⭐ NEW
**File:** `DeviceManager-Hybrid.workbook.json`

### Features
- ✅ **CustomEndpoint for monitoring** (device list, pending actions, status tracking, history, inventory)
- ✅ **ARMEndpoint for execution** (Run Scan, Isolate, Unisolate, Collect, Restrict, Unrestrict, Cancel)
- ✅ **Auto-refresh on monitoring sections** for real-time updates
- ✅ **Manual trigger on execution sections** for controlled actions
- ✅ **Action ID autopopulation** - Click to track or cancel
- ✅ **Full Azure RBAC integration** via ARM invoke endpoints
- ✅ **Clear section naming** - Monitoring vs Execution clearly labeled

### Best For
- **Production environments** requiring both monitoring AND control
- **Azure-native workflows** with ARM integration
- **RBAC-controlled environments** with strict permissions
- **Audit trail requirements** - ARM logs all executions
- **Enterprise compliance** - Proper ARM resource governance

### How It Works
1. Select Function App → Auto-populates connection parameters (CustomEndpoint)
2. Select Tenant → Auto-populates from Azure Resource Graph
3. Select Devices → Auto-populates from Defender XDR API (CustomEndpoint)
4. Pending Actions Check → CustomEndpoint query with auto-refresh
5. Execute Action → ARMEndpoint invocation with proper ARM path
6. Track Status → CustomEndpoint query with auto-refresh
7. Click Action ID Links → Auto-populate tracking/cancel parameters

### Key Advantages
- **Best of both worlds** - Auto-refresh monitoring + ARM execution control
- **Azure RBAC integration** - Full Azure permissions on actions
- **Audit trails** - All executions logged in Azure Activity Log
- **Auto-refresh monitoring** - Real-time updates without manual actions
- **Action ID autopopulation** - One-click tracking and cancellation
- **Clear separation** - Monitoring (CustomEndpoint) vs Execution (ARMEndpoint)

### ARMEndpoint Sections (Manual Trigger)
- 🔍 Run Antivirus Scan
- 🔒 Isolate Device
- 🔓 Unisolate Device
- 📦 Collect Investigation Package
- 🚫 Restrict App Execution
- ✅ Unrestrict App Execution
- ❌ Cancel Action

### CustomEndpoint Sections (Auto-Refresh)
- 💻 Device List (parameter)
- ⚠️ Pending Actions Check
- 📊 Action Status Tracking
- 📜 Machine Actions History
- 💻 Device Inventory

## Version 3: Hybrid-CustomEndpointOnly (Alternative)
**File:** `DeviceManager-Hybrid-CustomEndpointOnly.workbook.json`

### Features
- ✅ **All CustomEndpoint queries** throughout
- ✅ **Enhanced UI layout** similar to Hybrid
- ✅ **Full auto-refresh support**
- ✅ **No ARM dependencies**

### Best For
- **Simplified deployments** without ARM complexity
- **Environments with ARM routing issues**
- **Alternative UI preference** to CustomEndpoint-Only

## Which Version Should You Use?

### Choose CustomEndpoint-Only if:
- ✅ You want **maximum simplicity** and stability
- ✅ You don't need ARM audit trails
- ✅ You want **consistent behavior** everywhere
- ✅ You prefer **easier troubleshooting**
- ✅ You want full auto-refresh on all sections

### Choose TRUE Hybrid if:
- ✅ You need **enterprise-grade governance** with ARM
- ✅ You require **Azure Activity Log audit trails**
- ✅ You have **strict RBAC requirements**
- ✅ You want **monitoring auto-refresh** + **controlled execution**
- ✅ You need compliance with Azure policies

### Choose Hybrid-CustomEndpointOnly if:
- ✅ You like the Hybrid UI layout
- ✅ You don't need ARM complexity
- ✅ You want an alternative to CustomEndpoint-Only

## Comparison Table

| Feature | CustomEndpoint-Only | TRUE Hybrid | Hybrid-CustomEndpointOnly |
|---------|-------------------|-------------|---------------------------|
| **Device Discovery** | ✅ CustomEndpoint | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Action Execution** | ✅ CustomEndpoint | ⭐ ARMEndpoint | ✅ CustomEndpoint |
| **Status Tracking** | ✅ CustomEndpoint | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Machine History** | ✅ CustomEndpoint | ✅ CustomEndpoint | ✅ CustomEndpoint |
| **Cancel Actions** | ✅ CustomEndpoint | ⭐ ARMEndpoint | ✅ CustomEndpoint |
| **Auto-refresh** | ✅ Full support | ✅ Monitoring only | ✅ Full support |
| **Action ID Autopopulation** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Error Handling** | ✅ Inline errors | ✅ ARM + inline | ✅ Inline errors |
| **RBAC Integration** | ⚠️ Function App only | ✅✅ Full Azure RBAC | ⚠️ Function App only |
| **Audit Logging** | ⚠️ Function logs only | ✅✅ Azure Activity Log | ⚠️ Function logs only |
| **Stability** | ✅✅ High | ✅ Good | ✅✅ High |
| **Troubleshooting** | ✅✅ Easy | ⚠️ ARM complexities | ✅✅ Easy |
| **Best Use Case** | Simple monitoring | Enterprise governance | Alternative UI |

## Installation

### For All Versions
1. Navigate to Azure Portal → Workbooks
2. Click "New" or open existing workbook
3. Click "Advanced Editor" (</> icon)
4. Paste the JSON content
5. Click "Apply"
6. Configure fallbackResourceIds if needed
7. Save the workbook

### Required Permissions

**For CustomEndpoint-Only and Hybrid-CustomEndpointOnly:**
- **Reader** role on subscription (for Resource Graph queries)
- **Function App permissions** for the DefenderC2 Function App
- **Defender XDR permissions** (configured in Function App)

**Additional for TRUE Hybrid (ARMEndpoint):**
- **Microsoft.Web/sites/functions/invoke/action** permission on Function App
- **Contributor** or custom role with invoke permissions
- Properly configured **Subscription** and **ResourceGroup** parameters

## Configuration

### Update Fallback Resource IDs
Both workbooks contain:
```json
"fallbackResourceIds": [
  "/subscriptions/YOUR-SUBSCRIPTION-ID/resourcegroups/YOUR-RESOURCE-GROUP"
]
```

Update this to match your Azure environment.

### Update Timestamps
Search for `2025-10-16 00:00:00 UTC` and update to current timestamp if desired.

### Update User Attribution
Search for `akefallonitis` and replace with your username if desired.

## Troubleshooting

### Common Issues

#### 1. Device List Shows "<query failed>"
**Cause:** Function App parameters not populated yet  
**Solution:** Select Function App first, wait 2-3 seconds for auto-population

#### 2. 400 Bad Request Error
**Cause:** Attempting to run same action on device with pending action  
**Solution:** Check "Pending Actions" section, wait for completion or cancel existing action

#### 3. Action IDs Not Auto-populating
**Cause:** JSONPath transformer issue  
**Solution:** Check that $.actionIds[*] path is correct in function response

#### 4. ARM Action Not Executing (TRUE Hybrid Only)
**Cause:** ARM routing issues or insufficient permissions  
**Solution:** 
- Verify RBAC permissions on Function App
- Check Microsoft.Web/sites/functions/invoke/action permission
- Ensure Subscription and ResourceGroup parameters are correctly set
- Verify FunctionAppName matches the actual function app name

### Debug Mode
To enable detailed logging:
1. Open browser developer tools (F12)
2. Go to Network tab
3. Execute action
4. Inspect request/response in network log

## API Endpoints Reference

### Function Actions
- `Get Devices` - Returns all devices
- `Get All Actions` - Returns machine actions history (supports filter parameter)
- `Get Action Status` - Returns specific action status (requires actionId)
- `Cancel Action` - Cancels specific action (requires actionId)
- `Run Antivirus Scan` - Executes antivirus scan (requires deviceIds)
- `Isolate Device` - Isolates device (requires deviceIds, isolationType)
- `Unisolate Device` - Removes isolation (requires deviceIds)
- `Collect Investigation Package` - Collects forensic package (requires deviceIds)
- `Restrict App Execution` - Restricts apps (requires deviceIds)
- `Unrestrict App Execution` - Removes restrictions (requires deviceIds)

### Parameters
- `action` - Action type (required)
- `tenantId` - Defender XDR tenant ID (required)
- `deviceIds` - Comma-separated device IDs (required for device actions)
- `actionId` - Specific action ID (required for status/cancel)
- `filter` - OData filter for Get All Actions (optional)
- `comment` - Comment for action (optional)
- `scanType` - "Quick" or "Full" (for scans)
- `isolationType` - "Full" or "Selective" (for isolation)

## Action Tracking and Cancellation

### Track Action Status
1. **Execute an action** - Action IDs are returned automatically
2. **Click "📋 Track" link** next to the Action ID (or copy/paste manually)
3. **LastActionId parameter auto-populates** at the top of the workbook
4. **View real-time status** - "Track Action Status" section appears
5. **Auto-refresh enabled** - Status updates every 30 seconds (configurable)

**What You'll See:**
- Action ID and Type
- Current Status (Pending, InProgress, Succeeded, Failed, Cancelled)
- Device ID and Name
- Requestor
- Created and Last Updated timestamps

### Cancel Running Actions
1. **Find the action** in "Currently Running Actions" or "Machine Actions History"
2. **Click "❌ Cancel" link** next to the Action ID (or copy/paste manually)
3. **CancelActionId parameter auto-populates**
4. **Cancel section appears** with confirmation
5. **Execute cancellation** - Result shown immediately (ARMEndpoint in TRUE Hybrid, CustomEndpoint in others)
6. **Verify** - Check status tracking to confirm cancellation

**When to Cancel:**
- Action stuck in "Pending" or "InProgress"
- Wrong device selected
- Action no longer needed
- Need to retry with different parameters

## Best Practices

### 1. Always Check Pending Actions First
Before executing actions, review the "Pending Actions" section to avoid 400 errors.

### 2. Use Auto-refresh Wisely
- **10 seconds** - Active incident response
- **30 seconds** - Normal monitoring (default)
- **1-5 minutes** - Background monitoring
- **Off** - Manual control only

### 3. Track Important Actions
After executing critical actions (isolation, restriction), immediately copy Action IDs to track status and enable cancellation if needed.

### 4. Filter Machine History
Use the filter functionality to narrow down results by:
- Device name
- Action type
- Status
- Time range

### 5. Export for Reporting
Both versions support "Export to Excel" for machine actions and device inventory.

## Version History

### v1.1 - 2025-10-16 (Current)
- ⭐ **TRUE Hybrid implementation** with CustomEndpoint + ARMEndpoint
- ✅ Action ID autopopulation with clickable links
- ✅ Clear separation of monitoring (CustomEndpoint) vs execution (ARMEndpoint)
- ✅ Full ARM invoke endpoint integration
- 📄 Comprehensive documentation in TRUE_HYBRID_IMPLEMENTATION.md

### v1.0 - 2025-10-16
- Initial release
- CustomEndpoint-Only version with full functionality
- Hybrid version (now Hybrid-CustomEndpointOnly) with enhanced UI
- Complete documentation and troubleshooting guide

## Support

### Issues
Report issues on GitHub: https://github.com/akefallonitis/defenderc2xsoar/issues

### Conversation History
Full development conversation and requirements: `/workspaces/defenderc2xsoar/conversationfix`

### Sample Workbooks
Additional examples: `/workspaces/defenderc2xsoar/conversationworkbookstests`

## Contributing
Improvements and bug fixes welcome! Please:
1. Test thoroughly in your environment
2. Document any changes
3. Submit pull request with clear description

---

**Maintained by:** akefallonitis  
**Last Updated:** 2025-10-16  
**Repository:** https://github.com/akefallonitis/defenderc2xsoar
