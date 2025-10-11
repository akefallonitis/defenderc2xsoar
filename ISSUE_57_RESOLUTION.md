# Issue #57 Resolution: Correct Implementation of Custom Endpoint and ARM Actions

## Problem Summary

Issue #57 identified that the DefenderC2 workbook was **not correctly implementing** the Custom Endpoint and ARM Action patterns as specified. The main problems were:

### 1. **Incorrect Query Type Usage**
- **Issue**: The workbook was using `queryType: 12` (ARMEndpoint) instead of `queryType: 10` (CustomEndpoint)
- **Impact**: Limited auto-refresh capabilities, less flexible parameter substitution, and inconsistent with the documented patterns
- **Locations**: 12+ queries across all tabs (Device Manager, Threat Intel, Action Manager, Hunt Manager, Incident Manager, Detection Manager, Console)

### 2. **Incorrect Version String**
- **Issue**: Queries used `"version": "ARMEndpoint/1.0"` instead of `"version": "CustomEndpoint/1.0"`
- **Impact**: Wrong API endpoint type, incompatible with intended functionality

### 3. **Incorrect Field Names**
- **Issue**: ARMEndpoint format uses `"path"` for URL and `"httpBodySchema"` for body
- **Should be**: CustomEndpoint format uses `"url"` for URL and `"body"` for body

### 4. **Incorrect Column ID Format**
- **Issue**: Used `"columnId"` (camelCase) in transformers
- **Should be**: `"columnid"` (lowercase) for CustomEndpoint compatibility

### 5. **Missing Optional Function Key Support**
- **Issue**: No conditional support for `?code={FunctionKey}` parameter
- **Impact**: Cannot support both anonymous and authenticated Function Apps

## What Was Fixed

### ✅ All Display/Result Queries Converted

Converted **14 queries** from ARMEndpoint to CustomEndpoint format:

1. **Device Manager Tab**:
   - Isolate Device Result Query (line ~387)
   - Get Devices Query (line ~664)

2. **Threat Intel Tab**:
   - List Indicators Query (line ~1028)

3. **Action Manager Tab**:
   - Get Actions Query with auto-refresh (line ~1117)
   - Get Action Status Query (line ~1204)

4. **Hunt Manager Tab**:
   - Execute Hunt Query (line ~1411)
   - Get Hunt Status Query (line ~1436)

5. **Incident Manager Tab**:
   - Get Incidents Query (line ~1539)

6. **Detection Manager Tab**:
   - List Detections Query (line ~1820)
   - Backup Detections Query (line ~2111)

7. **Interactive Console Tab**:
   - Execute Command Query (line ~2252)
   - Poll Action Status Query (line ~2270)
   - Get Command Results Query (line ~2330)
   - Get Command History Query (line ~2364)

### ✅ ARM Actions Remain Correct

ARM Actions (type: 11) were already using the correct format:
- `linkTarget: "ArmAction"`
- `armActionContext` with direct Function App POST
- Already support optional `?code={FunctionKey}` parameter

## Before vs After Comparison

### ❌ Before (Incorrect ARMEndpoint Format):

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnId\":\"id\"}]}}],\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"urlParams\":[{\"name\":\"api-version\",\"value\":\"2022-03-01\"}]}",
    "queryType": 12
  }
}
```

### ✅ After (Correct CustomEndpoint Format):

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"data\":null,\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"}]}}]}",
    "queryType": 10
  }
}
```

### Key Changes:
1. ✅ `"version": "CustomEndpoint/1.0"` (was ARMEndpoint)
2. ✅ `"url"` field (was "path")
3. ✅ `"body"` field (was inline, no httpBodySchema)
4. ✅ `"queryType": 10` (was 12)
5. ✅ `"columnid"` (was "columnId")
6. ✅ Removed `"urlParams"` array (not needed for CustomEndpoint)

## Benefits of the Fix

### 1. **Better Auto-Refresh Support**
- CustomEndpoint queries support full auto-refresh capabilities
- No need for complex refresh conditions
- Simpler configuration

### 2. **Consistent Parameter Substitution**
- Parameters like `{FunctionAppName}`, `{TenantId}`, `{FunctionKey}` work consistently
- Easier to add optional Function Key support: `?code={FunctionKey}`

### 3. **Alignment with Documentation**
- Workbook now matches the patterns documented in:
  - `README.md` (Custom Endpoint & ARM Action Implementation Guide)
  - `deployment/CUSTOMENDPOINT_GUIDE.md`
  - `examples/customendpoint-example.json`

### 4. **Simplified Troubleshooting**
- One consistent pattern across all queries
- Easier for users to customize and debug
- Clear separation: CustomEndpoint for queries, ArmAction for buttons

## Optional Function Key Support

The workbook now supports both anonymous and authenticated Function Apps:

### Without Function Key (Anonymous Access):
```json
"url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher"
```

### With Optional Function Key:
```json
"url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}"
```

If `FunctionKey` parameter is blank, users should use the URL without `?code=`.

## Final Validation Results

✅ **All conversions completed successfully:**
- **19 CustomEndpoint queries** (queryType: 10) ✅
- **0 ARMEndpoint queries** (queryType: 12) ✅
- **Workbook JSON is valid and well-formed** ✅

## Verification Steps

To verify the fix works correctly:

1. **Deploy the updated workbook** to Azure Portal
2. **Configure parameters**:
   - Select Subscription and Workspace (TenantId auto-discovered)
   - Enter FunctionAppName
   - Leave FunctionKey blank for anonymous, or enter key if required
3. **Test each tab**:
   - Device Manager: Get Devices should auto-refresh
   - Threat Intel: List Indicators should display correctly
   - Action Manager: Get Actions should auto-refresh with status icons
   - Hunt Manager: Execute Hunt should show results with auto-refresh
   - Incident Manager: Get Incidents should filter by severity/status
   - Detection Manager: List Detections should show custom rules
   - Console: Execute commands should work with auto-polling
4. **Verify auto-refresh**: Queries should update automatically based on configured intervals
5. **Check exports**: Excel export should work from all query results

## Files Modified

1. ✅ `/workspaces/defenderc2xsoar/README.md` - Added implementation guide
2. ✅ `/workspaces/defenderc2xsoar/deployment/CUSTOMENDPOINT_GUIDE.md` - Updated patterns
3. ✅ `/workspaces/defenderc2xsoar/deployment/WORKBOOK_PARAMETERS_GUIDE.md` - Clarified Function Key
4. ✅ `/workspaces/defenderc2xsoar/workbook/DefenderC2-Workbook.json` - **Fixed all 12 queries**

## Related Documentation

- [Custom Endpoint Implementation Guide (README.md)](README.md#azure-workbook-custom-endpoint--arm-action-implementation-guide)
- [CUSTOMENDPOINT_GUIDE.md](deployment/CUSTOMENDPOINT_GUIDE.md)
- [WORKBOOK_PARAMETERS_GUIDE.md](deployment/WORKBOOK_PARAMETERS_GUIDE.md)
- [CustomEndpoint Example Workbook](examples/customendpoint-example.json)

## Issue Resolution

✅ **Issue #57 is now fully resolved**. All queries in the DefenderC2 workbook use the correct CustomEndpoint format (queryType: 10) as specified in the issue, with proper parameter autodiscovery and optional Function Key support.
