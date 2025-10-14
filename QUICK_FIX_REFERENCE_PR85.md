# Quick Fix Reference: Post-PR #85 Issues

## Problem
After PR #85 merged:
- ❌ "Available Devices" shows `<query failed>`
- ❌ "Get Incidents" shows "Please provide the api-version URL parameter"
- ❌ ARM Actions not working properly

## Solution
Added missing `api-version` parameter to CustomEndpoint queries and standardized ARM Actions.

---

## Fix #1: CustomEndpoint Queries

### What Changed
All CustomEndpoint queries now include `api-version` in their `urlParams` array.

### Pattern

**Before:**
```json
"urlParams": [
  {"key": "action", "value": "Get Devices"},
  {"key": "tenantId", "value": "{TenantId}"}
]
```

**After:**
```json
"urlParams": [
  {"key": "action", "value": "Get Devices"},
  {"key": "tenantId", "value": "{TenantId}"},
  {"key": "api-version", "value": "2022-03-01"}
]
```

### Affected Queries
- DeviceList parameter (Get Devices)
- Device List grid display
- Threat Intel indicators
- Action Manager status
- Hunt Manager queries
- Incident Manager queries
- Custom Detection queries
- Interactive Console commands
- File Operations library

**Total: 18 CustomEndpoint queries fixed**

---

## Fix #2: ARM Actions

### What Changed
All ARM Actions now have:
1. `Content-Type: application/json` header
2. Parameters in body JSON (not params array)
3. Only `api-version` in params array

### Pattern

**Before:**
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/.../invocations",
    "headers": [],
    "params": [
      {"key": "api-version", "value": "2022-03-01"},
      {"key": "action", "value": "Isolate Device"},
      {"key": "tenantId", "value": "{TenantId}"},
      {"key": "deviceIds", "value": "{DeviceList}"}
    ],
    "body": null,
    "httpMethod": "POST"
  }
}
```

**After:**
```json
{
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/.../invocations",
    "headers": [
      {"name": "Content-Type", "value": "application/json"}
    ],
    "params": [
      {"key": "api-version", "value": "2022-03-01"}
    ],
    "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceList}\"}",
    "httpMethod": "POST"
  }
}
```

### Affected Actions
**DefenderC2-Workbook.json (15 actions):**
1. Isolate Device
2. Unisolate Device
3. Restrict App Execution
4. Scan Device
5. Add File Indicators
6. Add IP Indicators
7. Add URL Indicators
8. Cancel Action
9. Update Incident
10. Add Comment
11. Create Detection
12. Update Detection
13. Delete Detection
14. Upload File
15. Deploy File

**FileOperations.workbook (already correct):**
- Deploy, Download, Delete actions already had correct pattern

---

## Why This Works

### CustomEndpoint Queries
The DefenderC2 Function App expects `api-version` as a URL parameter. Without it:
- Azure returns "Please provide the api-version URL parameter" error
- Queries fail and show `<query failed>`

### ARM Actions
The correct Azure Workbook ARM Action pattern requires:
- Content-Type header for JSON POST requests
- Query parameters (like api-version) in params array
- Action parameters in body JSON

---

## Verification

Run this Python script to verify:

```python
import json

with open('workbook/DefenderC2-Workbook.json', 'r') as f:
    data = json.load(f)

# Check CustomEndpoint queries
def check_custom_endpoints(obj):
    if isinstance(obj, dict):
        if 'query' in obj and 'CustomEndpoint' in str(obj.get('query')):
            query = json.loads(obj['query'])
            url_params = query.get('urlParams', [])
            has_api_ver = any(p.get('key') == 'api-version' for p in url_params)
            print(f"Query: {has_api_ver}")
        for v in obj.values():
            check_custom_endpoints(v)
    elif isinstance(obj, list):
        for item in obj:
            check_custom_endpoints(item)

check_custom_endpoints(data)
```

---

## Testing Checklist

After deployment:
- [ ] Available Devices dropdown shows devices (not `<query failed>`)
- [ ] Device List grid displays device information
- [ ] Threat Intel indicators load
- [ ] Action Manager shows actions
- [ ] Hunt Manager executes queries
- [ ] Incident Manager shows incidents
- [ ] Isolate Device action works
- [ ] Other ARM Actions execute successfully

---

## Quick Diff Summary

```
workbook/DefenderC2-Workbook.json:
  - 17 CustomEndpoint queries: added api-version to urlParams
  - 15 ARM Actions: added Content-Type, moved params to body

workbook/FileOperations.workbook:
  - 1 CustomEndpoint query: added api-version to urlParams
```

---

## Related Files

- `FIX_SUMMARY_PR85_FOLLOWUP.md` - Detailed explanation
- `PR_SUMMARY.md` - Original PR #85 summary
- `ARM_ACTION_FINAL_SOLUTION.md` - ARM Action documentation
