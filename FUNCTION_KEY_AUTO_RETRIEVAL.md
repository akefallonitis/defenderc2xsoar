# 🔑 Function Key Auto-Retrieval - ARM Action Implementation

## Overview

The DefenderC2 workbook now **automatically retrieves** the function key from the selected Function App using Azure Resource Manager (ARM) Actions. Users no longer need to manually copy the key from deployment outputs or Azure Portal.

---

## How It Works

### 1. **ARM Action Query**

The `FunctionKey` parameter is configured with an ARM Action that:
- Uses `POST` method to call Azure Resource Manager API
- Endpoint: `{FunctionApp}/host/default/listKeys` (where {FunctionApp} is the full resource ID)
- API Version: `2022-03-01`

### 2. **API Response**

Azure returns the function keys:
```json
{
  "masterKey": "<REDACTED>",
  "functionKeys": {
    "default": "<FUNCTION_KEY_VALUE>"
  },
  "systemKeys": {}
}
```

### 3. **JSONPath Extraction**

The workbook uses a JSONPath transformer to extract the default function key:
- Path: `$.functionKeys.default`
- Column ID: `key`

### 4. **Auto-Population**

The extracted key automatically populates the `FunctionKey` parameter, which is then used in all CustomEndpoint queries.

---

## User Experience

### Before (Manual Process):
1. Deploy ARM template
2. Go to Deployment Outputs in Azure Portal
3. Copy `functionKey` value
4. Open workbook
5. Paste key into FunctionKey parameter
6. Click Update

### After (Automatic Process):
1. Deploy ARM template
2. Open workbook
3. Select Function App from dropdown
4. **✅ Function key auto-populated!**
5. All queries work immediately

---

## Technical Details

### ARM Action Configuration

```json
{
  "version": "ARMEndpoint/1.0",
  "data": null,
  "headers": [],
  "method": "POST",
  "path": "{FunctionApp}/host/default/listKeys",
  "urlParams": [
    {
      "key": "api-version",
      "value": "2022-03-01"
    }
  ],
  "transformers": [
    {
      "type": "jsonpath",
      "settings": {
        "columns": [
          {
            "path": "$.functionKeys.default",
            "columnid": "key"
          }
        ]
      }
    }
  ]
}
```

### Key Fix Applied

**Problem:** Original workbook used manual path construction:
```json
"path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/listKeys"
```

**Solution:** Use full resource ID directly:
```json
"path": "{FunctionApp}/host/default/listKeys"
```

This allows Azure Workbooks to properly recognize the path as an Azure Resource and execute the ARM Action.

---

## Security Considerations

### Authentication
- ARM Action uses **Azure RBAC** (user's identity)
- User must have `Microsoft.Web/sites/host/listKeys/action` permission
- Typically granted via `Website Contributor` or `Function App Contributor` roles

### Key Visibility
- Function key visible in workbook parameter field (password type recommended for production)
- Key transmitted securely over HTTPS in all CustomEndpoint queries
- No key storage in workbook JSON (retrieved at runtime)

---

## Troubleshooting

### "Path must be for an Azure Resource" Error
- **Cause:** FunctionApp parameter not selected or invalid
- **Solution:** Select a valid Function App from the dropdown

### "Unauthorized" or "Forbidden" Error
- **Cause:** User lacks permissions to list function keys
- **Solution:** Grant `Microsoft.Web/sites/host/listKeys/action` permission

### Function Key Parameter Empty
- **Cause:** ARM Action failed or returned unexpected format
- **Solution:** 
  1. Check Function App is running
  2. Verify API version is supported
  3. Check Azure RBAC permissions

---

## Files Modified

### `workbook/DefenderC2-Workbook.json`
- **Parameter ID:** `funckey`
- **Label:** 🔑 Function Key (Auto-retrieved)
- **Type:** Text (type 1) with ARM Action query
- **Query Type:** 12 (ARMEndpoint)
- **Dependencies:** `{FunctionApp}` parameter

### `deployment/azuredeploy.json`
- Updated `workbookContent` variable with base64-encoded workbook (140,620 bytes)
- Contains ARM Action configuration for automatic key retrieval

---

## Benefits

✅ **Zero Manual Steps** - No copy/paste from deployment outputs  
✅ **Real-time Updates** - Key refreshes when Function App changes  
✅ **Error Reduction** - No risk of wrong key or typos  
✅ **Better UX** - Immediate functionality after deployment  
✅ **RBAC Integration** - Uses existing Azure permissions  

---

## Related Documentation

- **AUTHENTICATION_FIX_SUMMARY.md** - CustomEndpoint authentication implementation
- **deployment/FIX_WORKBOOK_AUTH.md** - Detailed authentication architecture
- **DEPLOYMENT_GUIDE_PERFECT.md** - Complete deployment instructions

---

**Status:** ✅ Production Ready  
**Last Updated:** November 6, 2025  
**Feature:** Auto-retrieval of function keys via ARM Actions
