# ⏱️ Parameter Waiting & Auto-Refresh Fix

## 🎯 Problem Statement

The workbook was executing CustomEndpoint queries **before all dependent parameters were populated**, causing:
- Device List stuck in infinite loading spinner
- ARM actions showing `<unset>` parameters
- Queries executing with incomplete parameter values

User requirement: *"workbook should wait for parameters needed to populate before running - we should have also auto refresh for customendpoints - correct autopopulation for both custom endpoints and arm actions"*

---

## ✅ Solution Applied (Commit `3cee240`)

### 1. **Conditional Visibility on All Query Components**

Added `conditionalVisibility` to ensure sections only appear **after** required parameters are ready:

```json
{
  "conditionalVisibility": {
    "parameterName": "TenantId",
    "comparison": "isNotEqualTo",
    "value": ""
  }
}
```

**Applied to:**
- ✅ Device Actions header text
- ✅ Device Actions ARM buttons section
- ✅ Connected Devices header text  
- ✅ Device Grid display (Type 3, QueryType 10)

**Effect:**
- Workbook **waits** for TenantId to be populated before showing/executing these sections
- Prevents CustomEndpoint queries from running with empty parameters
- User sees clean UI progression: FunctionApp → Auto-discovery → TenantId → Devices

---

### 2. **Added `value: null` to DeviceList Parameter**

Matched the exact pattern from the working main workbook:

```json
{
  "name": "DeviceList",
  "type": 2,
  "queryType": 10,
  "value": null  // ✅ Now present
}
```

**Effect:**
- Ensures parameter starts with null value (not undefined)
- Helps Azure Workbooks properly track parameter state changes
- Matches proven working configuration from main workbook

---

## 🔄 How Auto-Refresh Works

### Parameter Dependency Chain

```
1. User selects FunctionApp (Type 5 - Resource picker)
   ↓
2. Auto-discovery params execute (criteriaData: [{FunctionApp}])
   - Subscription
   - ResourceGroup  
   - FunctionAppName
   ↓
3. TenantId query executes and auto-selects first tenant
   - selectFirstItem: true
   ↓
4. DeviceList CustomEndpoint executes (criteriaData: [{FunctionApp}, {FunctionAppName}, {TenantId}])
   ↓
5. Device Grid displays (criteriaData: [{FunctionApp}, {FunctionAppName}, {TenantId}])
   ↓
6. ARM actions become available (criteriaData: [all 6 params])
```

### Auto-Refresh Trigger: `criteriaData`

**Every query component includes `criteriaData`** listing all parameters it depends on:

```json
{
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionApp}"},
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ]
}
```

**When ANY parameter in criteriaData changes:**
- ✅ Query automatically re-executes
- ✅ Results refresh in real-time
- ✅ No manual refresh needed

**Example:**
- User changes TenantId dropdown → Device List query automatically re-runs with new tenantId
- User selects different FunctionApp → ALL queries re-execute with new function context

---

## 📋 Complete Parameter Configuration

### DeviceList Parameter (Type 10 - CustomEndpoint)

```json
{
  "id": "device-list",
  "version": "KqlParameterItem/1.0",
  "name": "DeviceList",
  "label": "Select Devices",
  "type": 2,
  "isRequired": false,
  "isGlobal": true,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":null,\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"value\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"label\"}]}}],\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}]}",
  "typeSettings": {
    "additionalResourceOptions": [],
    "showDefault": false
  },
  "timeContext": {
    "durationMs": 86400000
  },
  "queryType": 10,
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionApp}"},
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ],
  "value": null  // ✅ NEW
}
```

**Key Properties:**
- `criteriaData`: Lists ALL dependencies (FunctionApp, FunctionAppName, TenantId)
- `timeContext`: Cache duration 24 hours
- `value: null`: Initial state
- `queryType: 10`: CustomEndpoint query type

---

### Device Grid Display (Type 3, QueryType 10)

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{...CustomEndpoint query...}",
    "size": 0,
    "title": "Device List",
    "showExportToExcel": true,
    "queryType": 10,
    "visualization": "table",
    "criteriaData": [
      {"criterionType": "param", "value": "{FunctionApp}"},
      {"criterionType": "param", "value": "{FunctionAppName}"},
      {"criterionType": "param", "value": "{TenantId}"}
    ]
  },
  "conditionalVisibility": {  // ✅ NEW
    "parameterName": "TenantId",
    "comparison": "isNotEqualTo",
    "value": ""
  }
}
```

**Key Properties:**
- `criteriaData`: Same dependencies as DeviceList parameter
- `conditionalVisibility`: Only shows when TenantId has value
- `queryType: 10`: Must be 10 for CustomEndpoint displays

---

### ARM Actions (Type 11)

```json
{
  "linkTarget": "ArmAction",
  "linkIsContextBlade": true,
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "Isolate Device"},
      {"key": "tenantId", "value": "{TenantId}"},
      {"key": "deviceIds", "value": "{DeviceList}"}
    ],
    "body": null,
    "httpMethod": "POST",
    "title": "Isolate Devices",
    "description": "Initiating...",
    "actionName": "Isolate",
    "runLabel": "Isolate Devices"
  },
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionApp}"},
    {"criterionType": "param", "value": "{TenantId}"},
    {"criterionType": "param", "value": "{DeviceList}"},
    {"criterionType": "param", "value": "{Subscription}"},
    {"criterionType": "param", "value": "{ResourceGroup}"},
    {"criterionType": "param", "value": "{FunctionAppName}"}
  ]
}
```

**Key Properties:**
- `criteriaData`: ALL 6 parameters (even if not all used in path/params)
- `params`: Query string parameters (NOT body)
- `body: null`: Do NOT use POST body for ARM actions

**The parent section has conditional visibility:**
```json
{
  "type": 1,
  "content": {
    "json": "## Device Actions..."
  },
  "conditionalVisibility": {  // ✅ NEW
    "parameterName": "TenantId",
    "comparison": "isNotEqualTo",
    "value": ""
  }
}
```

---

## 🔍 Verification Steps

### 1. **Deploy Latest Version**
```bash
# Download from GitHub
curl -o DefenderC2-Workbook-MINIMAL-FIXED.json \
  https://raw.githubusercontent.com/akefallonitis/defenderc2xsoar/main/workbook/DefenderC2-Workbook-MINIMAL-FIXED.json

# Upload to Azure Portal > Sentinel > Workbooks > + New
# Paste JSON content
# Save as "DefenderC2 Minimal - FIXED v2"
```

### 2. **Test Parameter Waiting**

**Expected behavior:**

✅ **Step 1: Function Selection**
- See: FunctionApp resource picker
- See: Parameters section (collapsed)
- Don't see: Device Actions, Connected Devices sections

✅ **Step 2: Auto-Discovery** (happens automatically)
- Subscription populates
- ResourceGroup populates
- FunctionAppName populates
- TenantId dropdown populates AND auto-selects first tenant

✅ **Step 3: Device List Loads** (triggered by TenantId selection)
- "Device Actions" section appears
- "Connected Devices" section appears
- Device List parameter shows loading spinner briefly
- Device Grid shows loading spinner briefly
- **Device List populates with devices from selected tenant**
- **Device Grid displays table with device data**

✅ **Step 4: ARM Actions Available**
- Select one or more devices from Device List dropdown
- ARM action buttons (Isolate, Unisolate, Scan) become clickable
- Click button → Opens ARM action blade with pre-filled parameters

### 3. **Test Auto-Refresh**

✅ **Change TenantId:**
- Change TenantId dropdown to different tenant
- Device List parameter **automatically clears and reloads**
- Device Grid **automatically refreshes with new tenant's devices**
- Previously selected devices are cleared

✅ **Change FunctionApp:**
- Select different Function App from resource picker
- All auto-discovery parameters **automatically re-populate**
- TenantId **automatically refreshes** (may select different first tenant)
- Device List **automatically refreshes** with new function context

---

## 🎯 Technical Details

### Why Conditional Visibility Matters

**Without conditional visibility:**
```
FunctionApp selected → TenantId query starts → Device List query tries to run
                                            ↓
                        TenantId = "" (empty) → Function called with empty tenantId
                                            ↓
                                    Function returns error or empty result
                                            ↓
                                    Device List shows infinite loading
```

**With conditional visibility:**
```
FunctionApp selected → TenantId query starts → Device sections HIDDEN
                                            ↓
                        TenantId populates to "actual-tenant-id"
                                            ↓
                        Device sections APPEAR → Device List query runs with valid tenantId
                                            ↓
                                    Function returns device data
                                            ↓
                                    Device List populates successfully
```

### Why `value: null` Matters

Azure Workbooks tracks parameter state changes. Starting with explicit `null`:
- ✅ Helps diff engine detect when parameter transitions from null → populated
- ✅ Triggers criteriaData refresh more reliably
- ✅ Matches exact pattern from proven working main workbook
- ✅ Prevents undefined vs null ambiguity in JavaScript runtime

### CriteriaData Auto-Refresh Mechanism

Azure Workbooks maintains a **dependency graph**:

```
criteriaData: [{FunctionApp}, {FunctionAppName}, {TenantId}]
              ↓                ↓                  ↓
         Watch for       Watch for          Watch for
         changes         changes            changes
              ↓                ↓                  ↓
         If ANY parameter changes → Re-execute query
```

**This is why:**
- ✅ Changing TenantId refreshes Device List (TenantId in criteriaData)
- ✅ Changing FunctionApp refreshes Device List (FunctionApp in criteriaData)
- ✅ Changing FunctionApp refreshes TenantId (FunctionApp in criteriaData)

---

## 📚 Related Documentation

- `FINAL_WORKING_VERSION.md` - Complete pattern documentation
- `AUTO_POPULATION_FIX.md` - TenantId auto-selection details
- `DEPLOY_NOW.md` - Deployment guide
- `MINIMAL_WORKBOOK_FINAL.md` - Initial minimal workbook docs

---

## 🐛 Troubleshooting

### Device List Still Shows Loading Spinner

**Check:**
1. TenantId has a value (not empty string)
2. FunctionAppName populated correctly
3. Function is responding (test with curl):
   ```bash
   curl "https://YOUR-FUNCTION.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=YOUR-TENANT-ID"
   ```
4. Browser console for errors (F12 → Console)

**If function returns data but grid doesn't show:**
- Verify JSONPath transformer: `$.devices[*]`
- Verify column paths: `$.id`, `$.computerDnsName`, etc.
- Check function response structure matches transformer expectations

### ARM Actions Show `<unset>` Parameters

**Check:**
1. All 6 parameters in criteriaData:
   - FunctionApp
   - TenantId
   - DeviceList
   - Subscription
   - ResourceGroup
   - FunctionAppName
2. Auto-discovery parameters populated correctly
3. FunctionApp resource picker has valid selection

### Parameters Not Auto-Refreshing

**Check:**
1. `criteriaData` includes ALL dependencies
2. Parameters marked `isGlobal: true`
3. `timeContext` present on all auto-discovery params

---

## ✅ Success Criteria

After deploying this version, you should have:

- ✅ **No infinite loading spinners** on Device List
- ✅ **Clean UI progression** (sections appear only when ready)
- ✅ **Auto-refresh works** (change TenantId → Device List refreshes)
- ✅ **ARM actions populate correctly** (no `<unset>` values)
- ✅ **Professional user experience** (no errors, smooth loading)

---

## 📝 Commit Details

**Commit:** `3cee240`  
**Branch:** `main`  
**Date:** 2025-01-XX

**Files Changed:**
- `workbook/DefenderC2-Workbook-MINIMAL-FIXED.json` (+17, -1)

**Changes:**
1. Added `conditionalVisibility` to 4 components (Device Actions text, ARM buttons, Connected Devices text, Device Grid)
2. Added `value: null` to DeviceList parameter
3. Preserved all existing criteriaData and working patterns

---

**Ready to deploy?** Download the latest version from GitHub and import into Azure Portal! 🚀
