# Function App Authentication Configuration

## Issue Resolved

The workbook queries were missing the `?code={FunctionKey}` parameter in the URL, which is required for Function App authentication.

## What Was Fixed

✅ **Added `?code={FunctionKey}` to all CustomEndpoint query URLs:**
- DefenderC2Dispatcher
- DefenderC2TIManager  
- DefenderC2HuntManager
- DefenderC2IncidentManager
- DefenderC2CDManager

## Function App Authentication Setup

### Option 1: Anonymous Access (Recommended for Testing)

If you want to test without a Function Key:

1. Go to your Function App in Azure Portal
2. Navigate to each function (DefenderC2Dispatcher, etc.)
3. Go to **Function** → **Integration** → **HTTP trigger**
4. Set **Authorization level** to **Anonymous**
5. **Leave the FunctionKey parameter blank in the workbook**

When FunctionKey is blank, the URL becomes:
```
https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=
```

Azure Functions will ignore the empty `code=` parameter when set to Anonymous.

### Option 2: Function Key Authentication (Production)

For production deployments:

1. Go to your Function App in Azure Portal
2. Navigate to **App keys** or **Function keys**
3. Copy the function key (or host key)
4. In the workbook, enter the key in the **Function Key (Optional)** parameter field

The URL becomes:
```
https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=your-actual-key-here
```

### Option 3: System/Managed Identity (Advanced)

For even better security, use Managed Identity (requires additional Function App configuration):

1. Enable System-assigned Managed Identity on the Function App
2. Grant appropriate permissions to the Managed Identity
3. Remove the need for Function Keys entirely
4. This is outside the scope of the current workbook but is the most secure option

## Current Workbook Configuration

The workbook now includes:

- ✅ **FunctionKey parameter** (optional, defined in parameters section)
- ✅ **All queries include `?code={FunctionKey}`** in the URL
- ✅ **Works with both anonymous and key-based authentication**

## Troubleshooting

### "Query Failed" Error

If you see "Available Devices: <query failed>":

1. **Check Function App authentication level**:
   - If set to **Function** or **Admin**: Provide a Function Key in the workbook
   - If set to **Anonymous**: Leave Function Key blank

2. **Verify Function App is running**:
   - Go to Azure Portal → Function App → Overview
   - Check the status is "Running"

3. **Check Function App name**:
   - Verify the FunctionAppName parameter matches your actual Function App name
   - It should be just the name (e.g., "defenderc2"), not the full URL

4. **Test the Function App directly**:
   ```bash
   curl -X POST https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=YOUR_KEY \
     -H "Content-Type: application/json" \
     -d '{"action":"Get Devices","tenantId":"your-tenant-id"}'
   ```

5. **Check CORS settings**:
   - Function App → CORS
   - Ensure Azure Portal (portal.azure.com) is allowed

6. **Check Application Insights logs**:
   - Function App → Application Insights → Logs
   - Look for errors or failed requests

## Next Steps

1. Commit and push the updated workbook with Function Key support
2. Redeploy the workbook to Azure Portal
3. Configure Function App authentication level
4. Provide Function Key in workbook if needed
5. Test the queries

## Related Files

- `/workspaces/defenderc2xsoar/workbook/DefenderC2-Workbook.json` - Updated with `?code={FunctionKey}`
- `/workspaces/defenderc2xsoar/deployment/CUSTOMENDPOINT_GUIDE.md` - Documentation
- `/workspaces/defenderc2xsoar/deployment/WORKBOOK_PARAMETERS_GUIDE.md` - Parameter guide
