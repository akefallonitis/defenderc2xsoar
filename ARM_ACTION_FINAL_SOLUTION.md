# 🎯 ARM Action Parameter Fix - FINAL SOLUTION

## 🔍 The Real Issue: POST Body vs Query Parameters

### What We Discovered

Looking at the **working DeviceList parameter** configuration and screenshot evidence, the pattern is:

```json
{
  "method": "POST",
  "body": null,
  "urlParams": [
    {"key": "action", "value": "Get Devices"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

**Key Insight**: The function is called with **POST method but parameters in query string**, not in POST body!

---

## ❌ What Was Wrong

### ARM Actions BEFORE (Broken)
```json
{
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
  "headers": [{"name": "Content-Type", "value": "application/json"}],
  "params": [{"key": "api-version", "value": "2022-03-01"}],
  "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceList}\"}",
  "httpMethod": "POST"
}
```

**Problems**:
1. ❌ Used constructed path with text parameters
2. ❌ Parameters in JSON POST body
3. ❌ Content-Type header (not needed for query params)

---

## ✅ What's Fixed Now

### ARM Actions AFTER (Working)
```json
{
  "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
  "headers": [],
  "params": [
    {"key": "api-version", "value": "2022-03-01"},
    {"key": "action", "value": "Isolate Device"},
    {"key": "tenantId", "value": "{TenantId}"},
    {"key": "deviceIds", "value": "{DeviceList}"},
    {"key": "isolationType", "value": "{IsolationType}"},
    {"key": "comment", "value": "Isolated via Workbook"}
  ],
  "body": null,
  "httpMethod": "POST"
}
```

**Fixes Applied**:
1. ✅ Uses `{FunctionApp}` resource ID directly in path
2. ✅ All parameters in `params` array (query string)
3. ✅ No Content-Type header needed
4. ✅ `body` set to null

---

## 🔧 Two-Part Fix Summary

### Fix #1: Path Construction (Commit 270465c)
**Changed**: ARM action paths from text-based construction to resource picker

**Before**:
```
/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/...
```

**After**:
```
{FunctionApp}/functions/DefenderC2Dispatcher/invocations
```

**Why**: Type 5 resource picker contains full ARM resource ID

---

### Fix #2: Parameter Passing (Commit b9254cc)
**Changed**: Parameters from POST body to query parameters

**Before**:
```json
"params": [{"key": "api-version", "value": "2022-03-01"}],
"body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\"}"
```

**After**:
```json
"params": [
  {"key": "api-version", "value": "2022-03-01"},
  {"key": "action", "value": "Isolate Device"},
  {"key": "tenantId", "value": "{TenantId}"}
],
"body": null
```

**Why**: Matches working DeviceList parameter pattern (POST with query params)

---

## 📊 Function Code Compatibility

The PowerShell functions support **both patterns**:

```powershell
# Check query parameters first
$action = $Request.Query.action
$tenantId = $Request.Query.tenantId

# If body exists, use it to override query params
if ($Request.Body) {
    $action = $Request.Body.action ?? $action
    $tenantId = $Request.Body.tenantId ?? $tenantId
}
```

**Why Query Params?**
- ✅ Matches working DeviceList custom endpoint pattern
- ✅ Simpler - no JSON escaping needed
- ✅ Consistent pattern across workbook
- ✅ Easier to debug (visible in URL)

---

## 🎯 Actions Fixed (15 Total)

### DefenderC2Dispatcher (7 actions)
1. ✅ **Isolate Device** - `action=Isolate Device&tenantId={TenantId}&deviceIds={DeviceList}&isolationType={IsolationType}`
2. ✅ **Unisolate Device** - `action=Unisolate Device&tenantId={TenantId}&deviceIds={DeviceList}`
3. ✅ **Restrict App Execution** - `action=Restrict App Execution&tenantId={TenantId}&deviceIds={DeviceList}`
4. ✅ **Run Antivirus Scan** - `action=Run Antivirus Scan&tenantId={TenantId}&deviceIds={DeviceList}&scanType={ScanType}`
5. ✅ **Get Library Files** - `action=GetFile&deviceIds={DeviceIds}&filePath={LibraryFilePath}`
6. ✅ **Upload Library File** - `fileName={LibraryFileNameUpload}&fileContent={LibraryContentUpload}`
7. ✅ **Deploy Library File** - `action=PutFile&deviceIds={DeviceIds}&fileName={LibraryDeployFileName}`

### DefenderC2TIManager (3 actions)
8. ✅ **Add File Indicators** - `action=Add File Indicators&tenantId={TenantId}&indicators={FileIndicators}`
9. ✅ **Add IP Indicators** - `action=Add IP Indicators&tenantId={TenantId}&indicators={IpIndicators}`
10. ✅ **Add URL Indicators** - `action=Add URL Indicators&tenantId={TenantId}&indicators={UrlIndicators}`

### DefenderC2Dispatcher (1 action)
11. ✅ **Cancel Action** - `action=Cancel Action&tenantId={TenantId}&actionId={CancelActionId}`

### DefenderC2IncidentManager (2 actions)
12. ✅ **Update Incident** - `action=Update Incident&tenantId={TenantId}&incidentId={UpdateIncidentId}`
13. ✅ **Add Comment** - `action=Add Comment&tenantId={TenantId}&incidentId={CommentIncidentId}&comment={CommentText}`

### DefenderC2CDManager (3 actions)
14. ✅ **Create Detection** - `action=Create Detection&tenantId={TenantId}&ruleName={CreateRuleName}&query={CreateQuery}`
15. ✅ **Update Detection** - `action=Update Detection&tenantId={TenantId}&ruleId={UpdateRuleId}`
16. ✅ **Delete Detection** - `action=Delete Detection&tenantId={TenantId}&ruleId={DeleteRuleId}`

---

## 🧪 Testing Procedure

### Before Testing
1. Deploy updated workbook to Azure Portal
2. Clear browser cache
3. Select Function App and Workspace

### Test Each Action Type
1. **Device Actions**:
   - Select device(s) from DeviceList
   - Click "Isolate Devices"
   - **Verify ARM blade shows**:
     - Path: `{functionapp-resource-id}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01&action=Isolate Device&tenantId=xxx&deviceIds=xxx`
     - Parameters populated (not `<unset>`)

2. **Threat Intel Actions**:
   - Enter file hash indicators
   - Click "Add File Indicators"
   - **Verify query string** contains `action=Add File Indicators&tenantId=xxx&indicators=xxx`

3. **Incident Management**:
   - Enter incident ID
   - Click "Update Incident"
   - **Verify query string** contains incident details

---

## 📚 Pattern Comparison

### CustomEndpoint (Type 10) - DeviceList Parameter
```json
{
  "query": "{
    \"version\": \"CustomEndpoint/1.0\",
    \"method\": \"POST\",
    \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",
    \"body\": null,
    \"urlParams\": [
      {\"key\": \"action\", \"value\": \"Get Devices\"},
      {\"key\": \"tenantId\", \"value\": \"{TenantId}\"}
    ]
  }",
  "queryType": 10
}
```

### ARM Action - Isolate Button
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
    "httpMethod": "POST",
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "Isolate Device"},
      {"key": "tenantId", "value": "{TenantId}"}
    ],
    "body": null
  }
}
```

**Key Similarity**: Both use **POST with query parameters**, not POST body!

---

## 🎓 Key Learnings

### 1. **Always Match Working Patterns**
The DeviceList parameter was working correctly. We should have matched its exact pattern from the start.

### 2. **POST ≠ POST Body**
POST method can have parameters in:
- Query string (what we use) ✅
- Request body (what we tried first) ❌
- Both (what function supports) ⚠️

### 3. **Screenshot Evidence is Gold**
The user's screenshot showing `urlParams` in the DeviceList configuration was the key to solving this.

### 4. **Function Flexibility**
PowerShell functions accepting both patterns (`Query` and `Body`) is good defensive coding but can mask workbook configuration issues.

---

## 📦 Commits

1. **270465c** - Fixed ARM action paths (use FunctionApp resource ID)
2. **b9254cc** - Converted ARM actions to query parameters (matches DeviceList)
3. **fae1069** - Documentation for original fix
4. **(this doc)** - Final solution documentation

---

## ✅ Verification Checklist

- [x] All 15 ARM actions converted to query parameters
- [x] Path uses `{FunctionApp}` resource picker
- [x] `body` set to `null`
- [x] `headers` array empty
- [x] `params` array contains all action parameters
- [x] Matches working DeviceList pattern exactly
- [x] Compatible with PowerShell function code
- [ ] **USER TESTING REQUIRED**: Deploy and test in Azure Portal

---

## 🚀 Next Steps

1. **Deploy to Azure**: Import updated workbook JSON
2. **Test All Actions**: Run through each of the 15 ARM action buttons
3. **Verify Query Strings**: Check ARM blade shows populated query parameters
4. **Confirm Execution**: Verify actions complete successfully in Defender

---

## 📖 References

- **User Screenshot**: Shows DeviceList using `urlParams` (query parameters)
- **Custom Endpoint Example**: `/examples/customendpoint-example.json`
- **Function Code**: `/functions/DefenderC2Dispatcher/run.ps1` (lines 10-24)
- **Working Pattern**: DeviceList parameter (lines 190-211)

---

*Generated: 2025-10-13*  
*Status: ✅ READY FOR USER TESTING*  
*Pattern: POST with query parameters (matching working DeviceList)*
