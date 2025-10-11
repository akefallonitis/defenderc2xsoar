# Complete Autodiscovery Solution for DefenderC2 Workbook

## Overview

After testing with curl and examining Azure Resource Graph capabilities, we've determined the optimal autodiscovery strategy for the DefenderC2 workbook.

## What Can Be Autodiscovered from Azure Resource Graph

Azure Resource Graph provides these core fields for **all** Azure resources:

| Field | Description | How We Use It |
|-------|-------------|---------------|
| `id` | Full Azure resource ID | Extract subscription, resource group, resource name |
| `name` | Resource name | Function App name |
| `type` | Resource type | Filter for Function Apps (`microsoft.web/sites`) |
| **`tenantId`** | **ID of tenant the resource belongs to** | **Azure AD Tenant ID for authentication!** |
| `subscriptionId` | Subscription ID | For ARM Actions |
| `resourceGroup` | Resource group name | For ARM Actions |
| `location` | Azure region | For reference |
| `tags` | Resource tags | Can tag Function App with `purpose: defenderc2` |
| `properties` | Resource-specific properties | Function App config, runtime, etc. |

**Source**: https://learn.microsoft.com/en-us/azure/service-health/azure-resource-graph-overview

## Complete Autodiscovery Strategy

### Step 1: User Selects Function App
- Query Resource Graph for Function Apps with `kind contains 'functionapp'`
- Filter by name containing 'defender' or tag `purpose: defenderc2`
- User selects their DefenderC2 Function App from dropdown

### Step 2: Everything Autodiscovers from That Selection
From the selected Function App resource, extract:

```kusto
Resources
| where id == '{FunctionApp}'
| project 
    functionAppName = name,
    resourceGroup = resourceGroup,
    subscriptionId = subscriptionId,
    tenantId = tenantId,  // ← This is the Azure AD Tenant ID!
    location = location
```

### Step 3: User Selects Log Analytics Workspace
- Query Resource Graph for workspaces
- User selects workspace (for Sentinel data)
- This is separate from Function App tenant

### Step 4: Function Key from Deployment Parameters
Function keys **cannot** be retrieved from Resource Graph (secrets are not exposed).

**Two options**:

#### Option A: Deployment Parameter (Recommended)
In ARM template deployment:
```json
{
  "type": "Microsoft.Insights/workbooks",
  "properties": {
    "parameters": {
      "FunctionKey": {
        "value": "[listKeys(resourceId('Microsoft.Web/sites/functions', parameters('functionAppName'), 'DefenderC2Dispatcher'), '2022-03-01').default]"
      }
    }
  }
}
```

#### Option B: Manual Entry (Fallback)
- User gets key from Azure Portal → Function App → Functions → Function Keys
- Enters in workbook parameter
- Can be hidden after first entry

## Final Parameter Configuration

### User-Selected Parameters (2 only!)
1. **Function App** - Dropdown of DefenderC2 Function Apps
2. **Workspace** - Dropdown of Log Analytics workspaces

### Auto-Discovered Parameters (5 parameters!)
3. **FunctionAppName** - From Function App resource `.name`
4. **ResourceGroup** - From Function App resource `.resourceGroup`
5. **SubscriptionId** - From Function App resource `.subscriptionId`
6. **TenantId** - From Function App resource `.tenantId` ← **KEY DISCOVERY!**
7. **FunctionKey** - From ARM deployment parameter or manual entry

### Computed Parameters
8. **FunctionAppUrl** - Computed as `https://{FunctionAppName}.azurewebsites.net`
9. **FunctionAppUrlWithKey** - Computed as `{FunctionAppUrl}?code={FunctionKey}`

## Implementation Plan

### Workbook Parameter Section
```json
{
  "parameters": [
    {
      "name": "FunctionApp",
      "type": 5,  // Resource picker
      "label": "DefenderC2 Function App",
      "query": "Resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | where name contains 'defender' or tags.purpose =~ 'defenderc2' | project id, name, resourceGroup, subscriptionId, tenantId",
      "isRequired": true
    },
    {
      "name": "Workspace",
      "type": 5,  // Resource picker
      "label": "Log Analytics Workspace",
      "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces'",
      "isRequired": true
    },
    {
      "name": "FunctionAppName",
      "type": 1,  // Text (auto-filled)
      "query": "Resources | where id == '{FunctionApp}' | project value = name",
      "isHiddenWhenLocked": true
    },
    {
      "name": "ResourceGroup",
      "type": 1,  // Text (auto-filled)
      "query": "Resources | where id == '{FunctionApp}' | project value = resourceGroup",
      "isHiddenWhenLocked": true
    },
    {
      "name": "SubscriptionId",
      "type": 1,  // Text (auto-filled)
      "query": "Resources | where id == '{FunctionApp}' | project value = subscriptionId",
      "isHiddenWhenLocked": true
    },
    {
      "name": "TenantId",
      "type": 1,  // Text (auto-filled)
      "query": "Resources | where id == '{FunctionApp}' | project value = tenantId",
      "isHiddenWhenLocked": false,  // Allow manual override if needed
      "description": "Auto-discovered from Function App. This is the Azure AD tenant where your App Registration lives."
    },
    {
      "name": "FunctionKey",
      "type": 1,  // Text (from deployment or manual)
      "isRequired": false,
      "description": "Function key for authentication. Auto-populated during deployment or enter manually."
    }
  ]
}
```

## CustomEndpoint Query Format

With autodiscovery, queries become simpler:

```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}",
  "headers": [{"name": "Content-Type", "value": "application/json"}],
  "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [...]
}
```

## ARM Action Format

ARM Actions already use the correct format:

```json
{
  "path": "/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
  "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",...}",
  "httpMethod": "POST"
}
```

## Benefits

✅ **User only selects 2 things**: Function App and Workspace  
✅ **Everything else autodiscovers**: Name, resource group, subscription, **tenant ID**  
✅ **TenantId is correct**: Comes from Function App resource, not workspace  
✅ **No hardcoded values**: All parameters are dynamic  
✅ **Deployment-ready**: Function key can be injected during ARM deployment  
✅ **Manual fallback**: User can still enter function key manually if needed  

## Testing Results

### Confirmed Working Configuration
```bash
# With correct tenant ID from Function App resource
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"}' \
  "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=FUNCTION_KEY"

# Returns 200 OK with device list
```

### Issue Identified
- Workspace `customerId`: `fb5d034d-10f1-4497-b0fa-b654ad10813c` (wrong for auth)
- Function App `tenantId`: `a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9` (correct for auth)

Using Resource Graph to get `tenantId` from the Function App resource solves this!

## Deployment Integration

### ARM Template Deployment
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "functionAppName": {
      "type": "string"
    },
    "workbookName": {
      "type": "string",
      "defaultValue": "DefenderC2-Workbook"
    }
  },
  "variables": {
    "functionAppId": "[resourceId('Microsoft.Web/sites', parameters('functionAppName'))]",
    "functionKey": "[listKeys(concat(variables('functionAppId'), '/functions/DefenderC2Dispatcher'), '2022-03-01').default]"
  },
  "resources": [
    {
      "type": "Microsoft.Insights/workbooks",
      "apiVersion": "2022-04-01",
      "name": "[parameters('workbookName')]",
      "location": "[resourceGroup().location]",
      "kind": "shared",
      "properties": {
        "displayName": "DefenderC2 Command & Control",
        "serializedData": "[replace(replace(string(variables('workbookJson')), '__FUNCTION_KEY__', variables('functionKey')), '__FUNCTION_APP_ID__', variables('functionAppId'))]",
        "category": "sentinel"
      }
    }
  ]
}
```

## Summary

**Issue #57 Complete Resolution Strategy**:

1. ✅ User selects Function App from dropdown (filtered list)
2. ✅ All parameters autodiscover from Resource Graph (including **tenantId**!)
3. ✅ Function key injected during deployment OR entered manually
4. ✅ CustomEndpoint queries work with correct authentication
5. ✅ ARM Actions work with correct resource paths
6. ✅ Zero manual configuration needed if deployed via ARM template
7. ✅ Manual deployment works with just 2 selections + optional key entry

**Result**: True "zero-configuration deployment" as promised in the workbook header! 🎉

---

**Status**: Implementation Ready  
**Next Step**: Update workbook JSON with autodiscovery parameters  
**Date**: October 11, 2025
