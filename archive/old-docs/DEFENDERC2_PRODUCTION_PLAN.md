# DefenderC2 Production Workbooks - Build Plan

## 🎯 Objective

Create **TWO fully functional production workbooks** based on DefenderC2-Workbook.json with complete MDEAutomator functionality:

1. **DefenderC2-Hybrid.json** - ARM Actions + CustomEndpoint (like DeviceManager-Hybrid.json)
2. **DefenderC2-CustomEndpoint.json** - Pure CustomEndpoint (like DeviceManager-CustomEndpoint.json)

## 📊 Feature Requirements

### Complete MDEAutomator Feature Parity

Based on analysis, we need to implement ALL these features across 7 tabs:

#### Tab 1: Device Actions (DefenderC2Dispatcher)
- ✅ Isolate Device
- ✅ Unisolate Device  
- ✅ Restrict App Execution
- ✅ Unrestrict App Execution
- ✅ Run Antivirus Scan
- ✅ Collect Investigation Package
- ✅ Stop & Quarantine File
- ⏳ Get Device Info
- ⏳ List All Devices
- ⏳ Get Machine Actions
- ⏳ Cancel Action

#### Tab 2: Threat Intelligence (TIManager)
- ✅ Add File Indicator (SHA1/SHA256/MD5)
- ✅ Add IP Indicator
- ✅ Add URL Indicator
- ✅ Add Domain Indicator
- ✅ Add Certificate Indicator
- ⏳ Remove Indicator
- ⏳ List All Indicators
- ⏳ Bulk Import from CSV

#### Tab 3: Action Manager (DefenderC2Dispatcher)
- ✅ List All Machine Actions (auto-refresh)
- ✅ Get Action Details
- ✅ Cancel Action
- ⏳ Filter by Status/Device/Type
- ⏳ Export to CSV

#### Tab 4: Hunt Manager (HuntManager)
- ✅ Execute Advanced Hunt Query
- ✅ View Hunt Results (auto-refresh)
- ✅ Hunt Status
- ⏳ Query Library
- ⏳ Scheduled Hunts
- ⏳ Export Results

#### Tab 5: Incident Manager (IncidentManager)
- ✅ List Security Incidents
- ✅ Update Incident Status
- ✅ Add Incident Comment
- ⏳ Incident Details
- ⏳ Filter by Severity/Status
- ⏳ Assign to User

#### Tab 6: Custom Detection Manager (CDManager)
- ✅ List Detection Rules
- ✅ Create Detection Rule
- ✅ Update Detection Rule
- ✅ Delete Detection Rule
- ⏳ Backup Rules
- ⏳ Restore from Backup

#### Tab 7: Interactive Console (Multiple APIs)
- ✅ Execute Commands
- ✅ View Results
- ✅ Command History
- ⏳ File Upload/Download
- ⏳ Live Response Shell
- ⏳ Library Management

## 🏗️ Technical Architecture

### Hybrid Version Architecture
```
User Input → ARM Action Button → Azure Function App → MDE API
              ↓
         CustomEndpoint Query → Display Results (auto-refresh)
```

**Key Components**:
- **ARM Actions (Type 11)**: For user-triggered operations
  - Path: `/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/{FunctionName}/invocations`
  - Params: `api-version=2022-03-01` (FIRST param)
  - Body: null
  - Query params: action, tenantId, deviceIds, etc.
  
- **CustomEndpoint Queries (Type 3)**: For data retrieval
  - URL: `https://{FunctionAppName}.azurewebsites.net/api/{FunctionName}`
  - Method: POST
  - urlParams: action, tenantId, etc.
  - Auto-refresh: timeContextFromParameter

### CustomEndpoint-Only Architecture
```
User Input → Parameter Selection → CustomEndpoint Query → Function App → MDE API
                                          ↓
                                   Display Results (auto-refresh)
```

**Key Components**:
- **Confirmation Parameters**: ConfirmAction="EXECUTE"
- **CustomEndpoint Queries (Type 3)**: For everything
  - Same URL structure
  - Safer (requires confirmation)
  - Faster execution
  - Better for automation

## 🎨 UI/UX Enhancements

### From Medium Article (Advanced Workbook Design)
1. **Dynamic CSS Theming**
   - Retro CRT green phosphor theme
   - Dark mode optimized
   - Custom fonts (monospace)
   - Glowing text effects

2. **Color Schemes**
   - Success: Green (#00ff00)
   - Warning: Yellow (#ffff00)
   - Error: Red (#ff0000)
   - Info: Cyan (#00ffff)
   - Critical: Magenta (#ff00ff)

3. **Smart Layout**
   - Tab navigation at top
   - Logical grouping by function
   - Progressive disclosure
   - Minimal scrolling

4. **Status Indicators**
   - ✅ Success
   - ⚠️ Warning
   - ❌ Error
   - 🔄 In Progress
   - ⏸️ Pending

### Enhanced Features
- **Smart Filtering**: defaultFilters by DeviceID, TenantId
- **Auto-Population**: FunctionApp picker → auto-discover all params
- **Error Handling**: Clear messages for missing params
- **Loading States**: "Querying..." indicators
- **Result Formatting**: Tables with proper columns
- **Action Feedback**: Success/failure messages

## 📦 Function App Integration

### All 5 Dispatchers
1. **DefenderC2Dispatcher** - Device actions
2. **TIManager** - Threat intelligence
3. **HuntManager** - Advanced hunting
4. **IncidentManager** - Incidents
5. **CDManager** - Custom detections

### API Contract
```json
{
  "action": "Isolate Device",
  "tenantId": "{TenantId}",
  "deviceIds": "device1,device2",
  "isolationType": "Full",
  "comment": "Security investigation"
}
```

**Response**:
```json
{
  "actionId": "12345678-abcd-...",
  "status": "Pending",
  "message": "Device isolation initiated",
  "deviceId": "device1",
  "tenantId": "tenant-id"
}
```

## 🔧 Implementation Strategy

### Phase 1: Base Structure ✅
- Use DeviceManager-Hybrid.json as template
- Expand from 1 tab to 7 tabs
- Copy parameter structure
- Set up tab navigation

### Phase 2: Device Actions Tab (Current)
- Convert existing ARM Actions to proper format
- Add missing actions (Get Device Info, etc.)
- Implement smart filtering
- Add auto-refresh to all queries

### Phase 3: Threat Intel Tab
- File indicator management
- IP/URL/Domain indicators
- Certificate indicators
- Bulk operations

### Phase 4: Action Manager Tab
- List all actions (auto-refresh)
- Action details
- Cancel action
- Status filtering

### Phase 5: Hunt Manager Tab
- Query execution
- Results display (auto-refresh)
- Query library
- Export capabilities

### Phase 6: Incident Manager Tab
- List incidents
- Update status
- Add comments
- Severity filtering

### Phase 7: Detection Manager Tab
- List rules
- Create/Update/Delete
- Backup/Restore
- Rule validation

### Phase 8: Console Tab
- Command execution
- Results display
- History
- File operations

### Phase 9: CustomEndpoint Version
- Convert all ARM Actions to CustomEndpoint queries
- Add confirmation parameters
- Optimize for automation
- Test all flows

## 📋 Quality Checklist

### Functionality
- [ ] All 7 tabs working
- [ ] All ARM Actions correct (api-version in params)
- [ ] All CustomEndpoint queries use urlParams
- [ ] Auto-refresh on all data queries
- [ ] Smart filtering where appropriate
- [ ] Error handling for missing params

### Performance
- [ ] Fast loading (<5s per tab)
- [ ] Auto-refresh intervals configurable
- [ ] Queries optimized
- [ ] No unnecessary API calls

### UX/UI
- [ ] Consistent theming
- [ ] Clear visual hierarchy
- [ ] Helpful tooltips
- [ ] Status indicators
- [ ] Loading states
- [ ] Success/error messages

### Documentation
- [ ] Deployment guide
- [ ] Usage guide per tab
- [ ] Troubleshooting section
- [ ] API reference
- [ ] Screenshots

## 📁 Deliverables

### Files to Create
1. **workbook/DefenderC2-Hybrid.json** - Hybrid version (ARM + CustomEndpoint)
2. **workbook/DefenderC2-CustomEndpoint.json** - CustomEndpoint-only version
3. **docs/DEFENDERC2_HYBRID_GUIDE.md** - Hybrid workbook documentation
4. **docs/DEFENDERC2_CUSTOMENDPOINT_GUIDE.md** - CustomEndpoint workbook documentation
5. **docs/DEFENDERC2_COMPARISON.md** - Side-by-side comparison
6. **workbook/README.md** - Updated with new workbooks

### Files to Update
- Main README.md - Add new workbooks section
- QUICKSTART.md - Add deployment steps
- Function App docs - Link to workbooks

## 🚀 Deployment

### Azure Import Steps
1. Open Azure Workbooks
2. New → Advanced Editor
3. Paste JSON
4. Apply
5. Configure AutoRefresh parameter
6. Test all tabs
7. Save

### Prerequisites
- Azure subscription
- Function Apps deployed (all 5)
- Proper RBAC permissions
- MDE API access configured

## 📊 Success Metrics

- ✅ All 50+ actions implemented
- ✅ Both workbooks deploy without errors
- ✅ All tabs load data correctly
- ✅ Auto-refresh working
- ✅ UI/UX matches design specs
- ✅ Documentation complete
- ✅ Ready for production use

---

**Status**: Planning Complete  
**Next Step**: Build DefenderC2-Hybrid.json with all 7 tabs
