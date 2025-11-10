# 🔒 Workbook Authentication Fix - Function Keys for CustomEndpoint

## 🚨 Issue Identified

Your workbook has **two types of function app calls**:

### ✅ ARM Actions (Already Correct)
- **Path**: `/subscriptions/{Sub}/resourceGroups/{RG}/providers/Microsoft.Web/sites/{FunctionApp}/host/default/admin/functions/DefenderC2HuntManager`
- **Authentication**: Azure RBAC (user's Azure identity)
- **No Function Key Needed**: ARM API handles authentication
- **Used For**: Device actions (Isolate, Scan, Restrict, etc.)

### ❌ CustomEndpoint Queries (NEED FIX)
- **URL**: `https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager`
- **Current Auth**: **NONE** ❌
- **Required Auth**: Function key (because `authLevel: "function"` in function.json)
- **Used For**: 
  - Threat Intelligence listing
  - Incident listing
  - Detection rules listing

## 🔧 Solution Options

### Option 1: Add Function Key to CustomEndpoint URLs (Quick Fix)

**Pros:**
- Simple fix
- Works with current workbook structure
- Users get function key from deployment outputs

**Cons:**
- Function key visible in workbook parameters
- Less secure than RBAC
- Key rotation requires workbook update

**Implementation:**
Add FunctionKey parameter and append `?code={FunctionKey}` to all CustomEndpoint URLs.

### Option 2: Convert CustomEndpoint to ARM Actions (Recommended)

**Pros:**
- Uses Azure RBAC (more secure)
- No function keys needed
- Consistent authentication model
- Works with managed identities

**Cons:**
- More complex ARM paths
- Requires workbook restructuring

**Implementation:**
Convert all CustomEndpoint queries to ARM Actions with proper paths.

### Option 3: Change Functions to Anonymous (NOT RECOMMENDED)

**Pros:**
- No authentication required
- Works immediately

**Cons:**
- **SECURITY RISK** - Anyone with URL can call functions
- Not suitable for production
- Exposes your function app to public internet

## 🎯 Recommended Implementation

**Use Option 1 for immediate functionality**, then migrate to Option 2 for production.

### Step 1: Add FunctionKey Parameter to Workbook

Add after the `FunctionAppName` parameter:

```json
{
  "id": "fk",
  "version": "KqlParameterItem/1.0",
  "name": "FunctionKey",
  "label": "🔑 Function Key",
  "type": 1,
  "isRequired": true,
  "isGlobal": true,
  "description": "Enter your Function App default host key",
  "typeSettings": {
    "parameterType": "password"
  }
}
```

### Step 2: Update All CustomEndpoint URLs

**Before:**
```json
"url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager"
```

**After:**
```json
"url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager?code={FunctionKey}"
```

### Step 3: Get Function Key After Deployment

After deploying with ARM template:

```powershell
# Get function key from deployment outputs
az deployment group show \
  -g <resource-group> \
  -n <deployment-name> \
  --query properties.outputs.functionKey.value \
  -o tsv
```

Or from Azure Portal:
1. Go to Function App → Functions → App Keys
2. Copy the `default` host key
3. Paste into workbook FunctionKey parameter

## 🔄 Migration Path to ARM Actions (Future)

Convert CustomEndpoint to ARM Action:

**CustomEndpoint (Current):**
```json
{
  "version": "CustomEndpoint/1.0",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager?code={FunctionKey}",
  "method": "POST",
  "urlParams": [
    {"key": "action", "value": "List All Indicators"},
    {"key": "tenantId", "value": "{TenantId}"}
  ]
}
```

**ARM Action (Future):**
```json
{
  "version": "ARMEndpoint/1.0",
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/DefenderC2TIManager",
  "method": "POST",
  "params": [
    {"key": "api-version", "value": "2023-12-01"}
  ],
  "body": "{\"action\": \"List All Indicators\", \"tenantId\": \"{TenantId}\"}"
}
```

## 📋 Files to Update

1. **workbook/DefenderC2-Workbook.json**
   - Add FunctionKey parameter
   - Update all CustomEndpoint URLs (6 locations):
     - Threat Intelligence list
     - Threat Intelligence add actions
     - Incident Management list
     - Incident Management actions
     - Detection Rules list
     - Detection Rules actions

2. **deployment/azuredeploy.json**
   - ✅ Already has functionKey output (added in commit cc0e702)

3. **README.md**
   - Add instructions for obtaining function key
   - Document workbook setup with function key

## ⚡ Quick Fix Script

I'll create a PowerShell script to automatically update the workbook with function key support.

## 🎯 Summary

**Your ARM Actions are correct** - they use Azure RBAC and don't need function keys.

**Your CustomEndpoint queries need fixing** - they require function keys because all your functions have `authLevel: "function"`.

**Two approaches:**
1. **Quick Fix**: Add function key parameter to workbook
2. **Long-term**: Convert CustomEndpoint to ARM Actions for consistent RBAC

**Current State:**
- ARM Actions: ✅ Working (RBAC-authenticated)
- CustomEndpoint: ❌ Broken (missing function key)
