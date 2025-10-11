# Azure Workbook Parameter Autodiscovery Strategy

## Overview

Based on testing and Azure Resource Graph capabilities, here's the optimal parameter configuration:

## Parameters That CAN Be Autodiscovered

### ✅ From Azure Resource Graph (Read-Only)

1. **Subscription** - Query: `Resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | summarize by subscriptionId`

2. **Function App** (Dropdown) - Query: `Resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | where name contains 'defender' | project id, name, resourceGroup`

3. **Function App Name** - Extract from selected Function App resource ID

4. **Resource Group** - Extract from selected Function App resource ID

5. **Workspace** - Query: `Resources | where type =~ 'microsoft.operationalinsights/workspaces' | project id, name`

6. **Workspace Tenant ID** (Initial) - Query: `Resources | where id == '{Workspace}' | extend tenantId = tostring(properties.customerId) | project value = tenantId`

## Parameters That CANNOT Be Autodiscovered

### ❌ Requires ARM Operations (Write Permissions)

1. **Function Key** - Requires `listKeys()` operation
   - **Azure Resource Graph**: ❌ Read-only, cannot call listKeys()
   - **ARM Template**: ✅ Can use `listKeys(resourceId(...), '2022-03-01').default`
   - **ARM Action**: ✅ Can call `/listKeys` endpoint
   - **Manual**: ✅ User enters from Azure Portal

2. **Azure AD Tenant ID** - May differ from Workspace customerId
   - **Workspace customerId**: Often the same, but not always
   - **App Registration Tenant**: Where APPID/SECRETID are created
   - **Solution**: Autodiscover from workspace, allow manual override

## Recommended Configuration

### User Experience

**Step 1**: User selects **Subscription**
**Step 2**: User selects **Function App** from dropdown (autodiscovered)
**Step 3**: All other parameters autodiscover:
- Function App Name
- Resource Group  
- Workspace (user selects)
- Tenant ID (autodiscovered, editable)

**Step 4**: User provides **Function Key** (one of these options):

#### Option A: Enter Manually
- User copies key from Azure Portal → Function App → Functions → Function Keys
- Pastes into workbook parameter

#### Option B: Disable App Service Authentication
- Function App → Authentication → Disable
- No key needed (anonymous access)

#### Option C: Retrieve via ARM Template
- At deployment time: `listKeys(resourceId('Microsoft.Web/sites/functions', parameters('functionAppName'), 'DefenderC2Dispatcher'), '2022-03-01').default`
- Store in workbook parameter default value

## Implementation in Workbook JSON

```json
{
  "parameters": [
    {
      "name": "Subscription",
      "type": 6,
      "query": "Resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | summarize by subscriptionId",
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "FunctionApp",
      "type": 5,
      "query": "Resources | where type =~ 'microsoft.web/sites' and kind contains 'functionapp' | where name contains 'defender' | project id, name, resourceGroup",
      "crossComponentResources": ["{Subscription}"],
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "FunctionAppName",
      "type": 1,
      "query": "Resources | where id == '{FunctionApp}' | project value = name",
      "crossComponentResources": ["{Subscription}"],
      "isHiddenWhenLocked": true,
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "ResourceGroup",
      "type": 1,
      "query": "Resources | where id == '{FunctionApp}' | project value = resourceGroup",
      "crossComponentResources": ["{Subscription}"],
      "isHiddenWhenLocked": true,
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "Workspace",
      "type": 5,
      "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | project id, name",
      "crossComponentResources": ["{Subscription}"],
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "TenantId",
      "label": "Azure AD Tenant ID",
      "type": 1,
      "query": "Resources | where id == '{Workspace}' | extend tenantId = tostring(properties.customerId) | project value = tenantId",
      "crossComponentResources": ["{Subscription}"],
      "description": "Auto-discovered from workspace. Override if your App Registration is in a different tenant.",
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "name": "FunctionKey",
      "label": "Function Key",
      "type": 1,
      "isRequired": false,
      "defaultValue": "",
      "description": "Get from Azure Portal → Function App → Functions → DefenderC2Dispatcher → Function Keys. Leave empty if anonymous auth is enabled."
    }
  ]
}
```

## URL Construction

### For CustomEndpoint Queries
```
https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}
```

### For ARM Actions
```
{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01
```

Note: ARM Actions don't need Function Key - they use Azure RBAC permissions instead.

## Alternative: Function Key via ARM Action

If you want to retrieve the function key dynamically in the workbook, you can create an ARM Action that calls `listKeys()`:

```json
{
  "type": 11,
  "content": {
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Get Function Key",
      "armActionContext": {
        "path": "{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/listKeys?api-version=2022-03-01",
        "httpMethod": "POST",
        "title": "Retrieve Function Key"
      }
    }]
  }
}
```

However, this requires:
- User has `Microsoft.Web/sites/functions/listKeys/action` permission
- User clicks the button to retrieve the key
- Key is displayed in response (need to copy manually)

## Recommendation

**Best approach**: 
1. ✅ Autodiscover: Subscription, FunctionApp, FunctionAppName, ResourceGroup, Workspace, TenantId
2. ✅ User provides: Function Key (from Portal or disable auth)
3. ✅ Keep it simple and secure

This gives the best balance of automation and security.
