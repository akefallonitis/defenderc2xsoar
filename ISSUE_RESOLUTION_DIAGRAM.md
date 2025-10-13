# Issue Resolution Diagram

## ⚠️ OUTDATED DOCUMENTATION ⚠️

**This document describes an intermediate fix that was superseded by Issue #57.**

**For current implementation, see:** `ISSUE_57_COMPLETE_FIX.md`

**Key Changes:**
- All ARMEndpoint queries converted to CustomEndpoint
- ARM Actions fixes described here are still accurate

---

## Original Issue (From Screenshot)

```
┌─────────────────────────────────────────────────────────────────┐
│  DefenderC2 Workbook - Incident Manager Tab                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Parameters:                                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Available Devices: < query failed >  ❌                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Security Incidents Table:                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ⚠️  Please provide the api-version URL parameter         │  │
│  │     (e.g., api-version=2019-06-01)                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Root Causes Identified:

1. **Device Parameter Error:** 
   - Was correctly configured with CustomEndpoint
   - The `<query failed>` was due to Function App issues, not configuration

2. **Query Implementation (Superseded):**
   - Initial fix: Added api-version to ARMEndpoint queries
   - Final fix (Issue #57): Converted all to CustomEndpoint queries
   - Reason: ARMEndpoint is for Azure Resource Manager APIs, not custom Function Apps

3. **ARM Actions:**
   - Using full URLs instead of relative paths
   - api-version in wrong location (URL instead of params)
   - Fixed to use Azure best practices

---

## Solution Evolution

### Fix 1: Query Implementation (Final Solution - Issue #57)

**Intermediate Approach (Obsolete):**
```json
{
  "version": "ARMEndpoint/1.0",
  "method": "POST",
  "path": "https://{FunctionAppName}.azurewebsites.net/api/...",
  "urlParams": [{"name": "api-version", "value": "2022-03-01"}],
  "body": "...",
  "transformers": [...]
}
```
❌ ARMEndpoint is for Azure Resource Manager, not custom Function Apps

**Current Implementation:**
```json
{
  "queryType": 10,
  "query": "{
    \"version\": \"CustomEndpoint/1.0\",
    \"method\": \"POST\",
    \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",
    \"body\": \"{\\\"action\\\": \\\"Get Devices\\\", \\\"tenantId\\\": \\\"{TenantId}\\\"}\",
    \"transformers\": [...]
  }"
}
```
✅ Correct pattern for custom Function App endpoints

### Fix 2: ARM Actions (Still Accurate)

**Before:**
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "https://management.azure.com/subscriptions/{Subscription}/.../invocations?api-version=2022-03-01",
    "httpMethod": "POST",
    "body": "...",
    "params": [{"key": "api-version", "value": "2022-03-01"}]
  }
}
```
❌ Full URL with duplicate api-version

**After:**
```json
{
  "linkTarget": "ArmAction",
  "armActionContext": {
    "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
    "httpMethod": "POST",
    "body": "...",
    "params": [{"key": "api-version", "value": "2022-03-01"}]
  }
}
```
✅ Relative path with api-version only in params

### Fix 3: Device Parameters (Already Correct)

```json
{
  "name": "DeviceList",
  "type": 2,
  "queryType": 10,
  "multiSelect": true,
  "query": "{
    \"version\": \"CustomEndpoint/1.0\",
    \"method\": \"POST\",
    \"url\": \"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",
    \"body\": \"{\\\"action\\\": \\\"Get Devices\\\", \\\"tenantId\\\": \\\"{TenantId}\\\"}\",
    \"transformers\": [{
      \"type\": \"jsonpath\",
      \"settings\": {
        \"tablePath\": \"$.devices[*]\",
        \"columns\": [
          {\"path\": \"$.id\", \"columnid\": \"value\"},
          {\"path\": \"$.computerDnsName\", \"columnid\": \"label\"}
        ]
      }
    }]
  }"
}
```
✅ Already correctly configured

---

## Expected Result After Fix

```
┌─────────────────────────────────────────────────────────────────┐
│  DefenderC2 Workbook - Incident Manager Tab                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Parameters:                                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Available Devices: [Select devices...] ✅                │  │
│  │                    ▼ DESKTOP-ABC123                       │  │
│  │                      LAPTOP-XYZ789                        │  │
│  │                      SERVER-DEF456                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Security Incidents Table:                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Incident ID  │ Title             │ Severity │ Status     │  │
│  ├──────────────┼───────────────────┼──────────┼───────────┤  │
│  │ 123          │ Malware Detection │ High     │ Active ✅ │  │
│  │ 124          │ Phishing Attempt  │ Medium   │ Resolved  │  │
│  │ 125          │ Data Exfiltration │ Critical │ Active ✅ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Actions:                                                      │
│  [ ✏️ Update Incident ]  [ 💬 Add Comment ] ✅               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Current State by Component

### DefenderC2-Workbook.json

| Component | Current State | Notes |
|-----------|---------------|-------|
| Device Parameters (5) | ✅ CustomEndpoint | Correctly configured |
| CustomEndpoint Queries (21) | ✅ With parameter substitution | All queries converted from ARMEndpoint |
| ARM Actions (15) | ✅ Relative paths + api-version | Following Azure best practices |
| Global Parameters (6) | ✅ Marked as global | For nested group access |

### FileOperations.workbook

| Component | Current State | Notes |
|-----------|---------------|-------|
| CustomEndpoint Queries (1) | ✅ With parameter substitution | Converted from ARMEndpoint |
| ARM Actions (4) | ✅ Relative paths + api-version | Following Azure best practices |
| Global Parameters (3) | ✅ Marked as global | For nested group access |

---

## Affected Tabs and Components

### ✅ Device Manager / Defender C2
- Device List Query (ARMEndpoint)
- Device Parameters (Already working)
- Isolation Actions (ARM Actions)

### ✅ Threat Intel Manager
- Threat Indicators Query (ARMEndpoint)
- Add Indicator Actions (ARM Actions)

### ✅ Action Manager
- Machine Actions Query with Auto-Refresh (ARMEndpoint)
- Action Details Query (ARMEndpoint)
- Cancel Action (ARM Action)

### ✅ Hunt Manager
- Hunt Results Query with Auto-Refresh (ARMEndpoint)
- Hunt Execution Query (ARMEndpoint)

### ✅ Incident Manager
- Security Incidents Query (ARMEndpoint) ← **Main error from screenshot**
- Update Incident Action (ARM Action)
- Add Comment Action (ARM Action)

### ✅ Custom Detection Manager
- Detection Rules Query (ARMEndpoint)
- Detection Backup Query (ARMEndpoint)
- CRUD Actions (ARM Actions)

### ✅ Interactive Console
- Command Execution Queries (ARMEndpoint)
- Status and Results Queries (ARMEndpoint)
- History Query (ARMEndpoint)

### ✅ File Operations Workbook
- File List Query (ARMEndpoint)
- File Operations Actions (ARM Actions)

---

## Current Testing Status

```
Automated Verification:
  ✅ JSON validation passed
  ✅ All 21 CustomEndpoint queries verified
  ✅ All 19 ARM Actions verified (15 + 4)
  ✅ All device parameters verified
  ✅ All global parameters verified
  ✅ Verification script passes

Deployment Verification Required:
  ⏳ Device parameter dropdown population
  ⏳ All CustomEndpoint queries execute correctly
  ⏳ ARM Actions execute successfully
  ⏳ No "api-version" or "query failed" errors

Expected Results:
  ✅ Zero ARMEndpoint queries (all converted to CustomEndpoint)
  ✅ All queries use proper parameter substitution
  ✅ Device dropdowns populate correctly
  ✅ Tables display data without errors
  ✅ Actions execute with relative paths
```

---

## Verification Command

```bash
# Run this to verify all fixes are present
python3 scripts/verify_workbook_config.py

# Expected output:
# 🎉 SUCCESS: All workbooks are correctly configured!
```

---

**Issue Status:** ✅ RESOLVED (via Issue #57)  
**Implementation:** CustomEndpoint queries + ARM Action best practices  
**Current State:** 22 CustomEndpoint queries, 19 ARM Actions, 9 global parameters  
**Documentation:** See `ISSUE_57_COMPLETE_FIX.md` for authoritative details
