# Before/After Comparison: ARM Actions & CustomEndpoints Fix

## 🔧 ARM Actions - Parameter Handling

### ❌ BEFORE: Parameters in Query String

```json
{
  "linkLabel": "🔒 Isolate Devices",
  "armActionContext": {
    "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
    "headers": [],
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "Isolate Device"},
      {"key": "tenantId", "value": "{TenantId}"},
      {"key": "deviceIds", "value": "{DeviceList}"},
      {"key": "isolationType", "value": "Full"},
      {"key": "comment", "value": "Isolated via Workbook"}
    ],
    "body": null,
    "httpMethod": "POST"
  }
}
```

**HTTP Request Generated**:
```
POST /subscriptions/xxx/resourceGroups/yyy/providers/Microsoft.Web/sites/zzz/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01&action=Isolate+Device&tenantId=aaa&deviceIds=bbb&isolationType=Full&comment=Isolated+via+Workbook
Content-Length: 0
```

**Problem**: Azure Function receives parameters as query string instead of JSON body. This can cause:
- Function expecting JSON body gets empty body
- Parameters in query string instead of expected format
- Special characters not properly encoded
- Parameter values showing as `<unset>` in ARM blade

### ✅ AFTER: Parameters in POST Body

```json
{
  "linkLabel": "🔒 Isolate Devices",
  "armActionContext": {
    "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invocations",
    "headers": [
      {"name": "Content-Type", "value": "application/json"}
    ],
    "params": [
      {"key": "api-version", "value": "2022-03-01"}
    ],
    "body": "{\"action\": \"Isolate Device\", \"tenantId\": \"{TenantId}\", \"deviceIds\": \"{DeviceList}\", \"isolationType\": \"Full\", \"comment\": \"Isolated via Workbook\"}",
    "httpMethod": "POST"
  }
}
```

**HTTP Request Generated**:
```
POST /subscriptions/xxx/resourceGroups/yyy/providers/Microsoft.Web/sites/zzz/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01
Content-Type: application/json
Content-Length: 145

{
  "action": "Isolate Device",
  "tenantId": "aaa-bbb-ccc",
  "deviceIds": "device1,device2",
  "isolationType": "Full",
  "comment": "Isolated via Workbook"
}
```

**Benefits**:
- ✅ Function receives proper JSON body
- ✅ Parameters correctly formatted
- ✅ Special characters handled properly
- ✅ ARM blade shows correct parameter values
- ✅ Follows Azure Function invocation API standards

---

## 🔄 CustomEndpoints - CriteriaData Dependencies

### ❌ BEFORE: Redundant Dependencies

```json
{
  "name": "DeviceList",
  "type": 2,
  "queryType": 10,
  "query": "{\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}]}",
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionApp}"},
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ]
}
```

**Dependency Chain**:
```
FunctionApp (selected by user)
    ↓
    ├─→ FunctionAppName (derived, has criteriaData: {FunctionApp})
    ↓
DeviceList CustomEndpoint
    ├─ Depends on: {FunctionApp} ❌ (redundant)
    ├─ Depends on: {FunctionAppName} ✅ (actually used)
    └─ Depends on: {TenantId} ✅ (actually used)
```

**Problem**: Including both `{FunctionApp}` and `{FunctionAppName}` creates a redundant dependency chain:
1. When FunctionApp changes → FunctionAppName updates → DeviceList should refresh
2. But DeviceList ALSO directly depends on FunctionApp
3. This creates two parallel refresh triggers
4. Can cause refresh loops or timing issues
5. "Stacks in loop" - query keeps re-running unnecessarily

### ✅ AFTER: Direct Dependencies Only

```json
{
  "name": "DeviceList",
  "type": 2,
  "queryType": 10,
  "query": "{\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"urlParams\":[{\"key\":\"action\",\"value\":\"Get Devices\"},{\"key\":\"tenantId\",\"value\":\"{TenantId}\"}]}",
  "criteriaData": [
    {"criterionType": "param", "value": "{FunctionAppName}"},
    {"criterionType": "param", "value": "{TenantId}"}
  ]
}
```

**Dependency Chain**:
```
FunctionApp (selected by user)
    ↓
    ├─→ FunctionAppName (derived, has criteriaData: {FunctionApp})
    ↓
DeviceList CustomEndpoint
    ├─ Depends on: {FunctionAppName} ✅ (used in URL)
    └─ Depends on: {TenantId} ✅ (used in urlParams)
```

**Benefits**:
- ✅ Single, clear refresh path
- ✅ No redundant dependencies
- ✅ No refresh loops
- ✅ Proper parameter waiting
- ✅ Query runs only when necessary

---

## 📊 Impact Summary

### ARM Actions

| Aspect | Before | After |
|--------|--------|-------|
| Parameters | Query string | POST body (JSON) |
| Headers | Empty | Content-Type: application/json |
| params array | 6 items | 1 item (api-version) |
| Function receives | Empty body | JSON body |
| Parameter values | May show `<unset>` | Show correctly |

### CustomEndpoints

| Aspect | Before | After |
|--------|--------|-------|
| CriteriaData count | 3 dependencies | 2 dependencies |
| FunctionApp dependency | ❌ Included (redundant) | ✅ Removed |
| Refresh behavior | May loop | Runs once per change |
| Parameter waiting | Unclear | Clear chain |

---

## 🧪 Testing Checklist

After deploying the fixed workbook:

### ARM Actions
- [ ] Select Function App → parameters auto-populate
- [ ] Select Tenant ID → dropdown loads
- [ ] Select Devices → DeviceList shows options
- [ ] Click "Isolate Devices" button
  - [ ] ARM blade opens (not error)
  - [ ] Parameters show values (not `<unset>`)
  - [ ] Can see correct tenantId
  - [ ] Can see correct deviceIds
- [ ] Click "Run/Execute" in ARM blade
  - [ ] Function executes successfully
  - [ ] Check function logs to confirm JSON body received

### CustomEndpoints
- [ ] Select Function App
  - [ ] FunctionAppName auto-populates (few seconds)
- [ ] Select Tenant ID
  - [ ] DeviceList dropdown populates (few seconds)
  - [ ] List shows devices from selected tenant
  - [ ] ❌ Does NOT keep refreshing in loop
- [ ] Device grid displays
  - [ ] Shows devices (not loading spinner)
  - [ ] Displays all columns correctly
  - [ ] ❌ Does NOT keep refreshing in loop

### Parameter Flow
- [ ] Change Function App selection
  - [ ] FunctionAppName updates immediately
  - [ ] DeviceList refreshes once
  - [ ] Device grid refreshes once
  - [ ] ❌ No continuous loop
- [ ] Change Tenant ID
  - [ ] DeviceList refreshes once
  - [ ] Device grid refreshes once
  - [ ] ❌ No continuous loop

---

## 📝 Lines Changed

### workbook/DefenderC2-Workbook-MINIMAL-FIXED.json

**Total changes**: ~70 lines modified

**ARM Actions (3 actions × ~20 lines each = ~60 lines)**:
- Removed: 5-6 params from params array per action
- Added: 1 header (Content-Type) per action
- Added: 1 body with JSON string per action

**CustomEndpoints (2 endpoints × ~5 lines each = ~10 lines)**:
- Removed: 1 criteriaData entry per endpoint ({FunctionApp})
- Kept: 2 criteriaData entries per endpoint ({FunctionAppName}, {TenantId})

---

## 🔗 References

- [Azure Functions HTTP trigger](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger)
- [Azure Function App invocation API](https://learn.microsoft.com/en-us/rest/api/appservice/web-apps/invoke-function-async)
- [Azure Workbooks ARM actions](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-link-actions)
- [Azure Workbooks criteria parameters](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-criteria)

---

**Fix Date**: October 14, 2025  
**Commit**: 7be47be  
**Files Changed**: 3 (workbook JSON, documentation, verification script)
