# ✅ Workbook Authentication - FIXED

## 🎯 Your Question Answered

**"Are all custom endpoints and ARM actions from workbooks using keys correctly?"**

### Answer: **NO - Fixed in commit 9a54129**

## 🔍 What We Found

### ✅ ARM Actions - Already Correct
**Path Example:**
```
/subscriptions/{Sub}/resourceGroups/{RG}/providers/Microsoft.Web/sites/{FunctionApp}/host/default/admin/functions/DefenderC2HuntManager
```

**Authentication:** Azure RBAC (user's Azure identity)  
**Function Key:** ❌ **Not needed** - ARM API uses Azure authentication  
**Used For:** All device actions (Isolate, Scan, Restrict, Create Detection, etc.)  
**Status:** ✅ **Working correctly**

### ❌ CustomEndpoint Queries - WERE BROKEN (Now Fixed)
**URL Example (Before):**
```
https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager
```

**Authentication:** ❌ **NONE** (Would fail with 401 Unauthorized)  
**Function Key:** ✅ **Required** (authLevel: "function" in function.json)  
**Problem:** Missing `?code={FunctionKey}` parameter  
**Used For:** 
- Threat Intelligence listing
- Incident listing  
- Detection rules listing
- Live Response monitoring
- Orchestrator status

**URL Example (After Fix):**
```
https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager?code={FunctionKey}
```

## 🔧 What We Fixed

### Changes Made (Commit 9a54129):

1. **Added FunctionKey Parameter to Workbook**
   - Required, global parameter
   - Users enter their function app default host key
   - Type: password (hidden when entered)

2. **Updated 18 CustomEndpoint URLs**
   - All now include `?code={FunctionKey}`
   - Affected functions:
     - DefenderC2Dispatcher (8 calls)
     - DefenderC2TIManager (3 calls)
     - DefenderC2IncidentManager (2 calls)
     - DefenderC2CDManager (2 calls)
     - DefenderC2Orchestrator (3 calls)

3. **Updated ARM Template**
   - Embedded latest fixed workbook (base64)
   - Already has functionKey output (from commit cc0e702)

4. **Documentation Created**
   - FIX_WORKBOOK_AUTH.md - Complete explanation
   - fix-workbook-authentication.py - Utility script

## 📊 Authentication Summary

| Component | Type | Auth Method | Function Key? | Status |
|-----------|------|-------------|---------------|--------|
| **Device Actions** | ARM Action | Azure RBAC | ❌ Not needed | ✅ Correct |
| **Create Detection** | ARM Action | Azure RBAC | ❌ Not needed | ✅ Correct |
| **Execute Hunt** | ARM Action | Azure RBAC | ❌ Not needed | ✅ Correct |
| **List Indicators** | CustomEndpoint | Function Key | ✅ Required | ✅ Fixed |
| **List Incidents** | CustomEndpoint | Function Key | ✅ Required | ✅ Fixed |
| **List Detections** | CustomEndpoint | Function Key | ✅ Required | ✅ Fixed |
| **Live Response Status** | CustomEndpoint | Function Key | ✅ Required | ✅ Fixed |

## 🚀 How to Use After Deployment

### Step 1: Deploy ARM Template
```bash
# Click "Deploy to Azure" button in README
# Or deploy via Azure CLI
az deployment group create \
  -g <resource-group> \
  -n defenderc2-deployment \
  --template-file deployment/azuredeploy.json \
  --parameters @deployment/azuredeploy.parameters.json
```

### Step 2: Get Function Key
```bash
# From deployment outputs (RECOMMENDED)
az deployment group show \
  -g <resource-group> \
  -n defenderc2-deployment \
  --query properties.outputs.functionKey.value \
  -o tsv

# Or from Azure Portal
# Go to: Function App → Functions → App Keys → default (Host key)
```

### Step 3: Open Workbook
1. Go to Azure Portal → Workbooks
2. Find "DefenderC2 Command & Control Console"
3. Click "Edit" then "Done Editing"

### Step 4: Enter Function Key
1. You'll see a "🔑 Function Key" parameter at the top
2. Paste the function key you copied
3. Click "Apply"

### Step 5: Verify It Works
- ✅ ARM Actions (device actions) work immediately - no key needed
- ✅ CustomEndpoint queries (lists) now work with function key
- ✅ All tabs functional

## 🔐 Security Notes

### Why Two Authentication Methods?

**ARM Actions:**
- Use Azure RBAC (Role-Based Access Control)
- User must have permissions on the Function App resource
- More secure - uses Azure identity
- Best for: Write operations (Isolate, Scan, Create)

**CustomEndpoint with Function Key:**
- Use function app host key
- Key provides access to all functions
- Less secure than RBAC but simpler for workbooks
- Best for: Read operations (List, Monitor, Status)

### Future Enhancement Option

Convert all CustomEndpoint queries to ARM Actions for uniform RBAC security:
- More secure (no shared keys)
- Better audit trail
- Consistent authentication model
- Requires workbook restructuring

## 📝 Summary

**Before:**
- ❌ ARM Actions: ✅ Worked (RBAC)
- ❌ CustomEndpoint: ❌ **BROKEN** (no auth)

**After (Commit 9a54129):**
- ✅ ARM Actions: ✅ Work (RBAC)
- ✅ CustomEndpoint: ✅ **WORK** (function key)

**Your original question:** "Are all custom endpoints and ARM actions using keys correctly?"

**Answer:** 
- ARM Actions don't need keys (they use Azure RBAC) ✅
- CustomEndpoint calls NEED keys and were MISSING them ❌
- **NOW FIXED** - all 18 CustomEndpoint URLs include `?code={FunctionKey}` ✅

## 🎉 Result

**All workbook functionality now works correctly with proper authentication!**
