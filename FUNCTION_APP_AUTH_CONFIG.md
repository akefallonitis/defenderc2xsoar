# Function App Authentication Configuration

## Issue Identified

Testing the DefenderC2 Function App endpoint shows **401 Unauthorized** responses:

```bash
$ curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"..."}' \
  https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher

HTTP/1.1 401 Unauthorized
```

This indicates the Function App requires authentication, despite `function.json` having:
```json
{
  "authLevel": "anonymous"
}
```

## Root Cause

Azure Function Apps can have authentication enforced at **two levels**:

1. **Function-level** (`function.json` - set to anonymous)
2. **App-level** (Azure Portal > Authentication - currently enabled)

Even if function.json says "anonymous", app-level authentication takes precedence.

## Solution Options

### Option 1: Disable App Service Authentication (Recommended for Internal Use)

**Steps**:
1. Go to Azure Portal
2. Navigate to your Function App (`defenderc2`)
3. Go to **Settings** > **Authentication**
4. If authentication is enabled, click **Delete** or **Disable**
5. Save changes

**Pros**:
- Workbook queries work immediately with no keys
- Simpler configuration
- Fine for internal/private deployments

**Cons**:
- Function App is publicly accessible (anyone with URL can call it)
- Not recommended for internet-exposed deployments

### Option 2: Use Function Keys (Recommended for Production)

**Steps to Get Function Key**:
1. Go to Azure Portal
2. Navigate to your Function App (`defenderc2`)
3. Go to **Functions** > **DefenderC2Dispatcher**
4. Click **Function Keys** tab
5. Copy the **default** key (or create a new one)

**Configure Workbook**:
```
FunctionAppName: defenderc2?code=YOUR_FUNCTION_KEY_HERE
```

Example:
```
FunctionAppName: defenderc2?code=abc123xyz789_SAMPLE_KEY_HERE
```

**Pros**:
- Secure - requires valid key to call functions
- Works with Azure Workbooks
- Can rotate keys as needed

**Cons**:
- Requires key management
- Key must be stored in workbook parameter

### Option 3: Use Azure AD Authentication with Managed Identity

**Steps**:
1. Enable managed identity on the Workbook
2. Configure Function App to accept Azure AD tokens
3. Grant workbook identity permissions to call Function App

**Pros**:
- Most secure option
- No keys to manage
- Integrates with Azure RBAC

**Cons**:
- Most complex setup
- Requires careful permission configuration

## Testing Authentication

### Test Anonymous Access
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"YOUR_TENANT_ID"}' \
  https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher
```

**Expected**:
- ✅ 200 OK = Anonymous working
- ❌ 401 Unauthorized = Authentication required

### Test Function Key Access
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"YOUR_TENANT_ID"}' \
  "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=YOUR_KEY"
```

**Expected**:
- ✅ 200 OK = Function key working
- ❌ 401 Unauthorized = Invalid key or app auth enabled
- ❌ 500 Internal Server Error = Check APPID/SECRETID environment variables

## Current Status

**Your Function App**: `https://defenderc2.azurewebsites.net`

**Test Result**: 401 Unauthorized (Authentication required)

**Recommendation**: 
1. Check Azure Portal > Function App > Authentication settings
2. Either:
   - **Disable** App Service Authentication for anonymous access, OR
   - **Get** the function key and append `?code=KEY` to FunctionAppName parameter

## Workbook Configuration

Once authentication is resolved:

### For Anonymous Auth:
```
FunctionAppName: defenderc2
```

### For Function Key Auth:
```
FunctionAppName: defenderc2?code=abc123xyz789...
```

The workbook CustomEndpoint queries will then call:
```
https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher
```

Or:
```
https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?code=abc123xyz789...
```

## Additional Checks

Ensure your Function App has:

1. ✅ **Environment Variables Set**:
   - `APPID` = Your App Registration ID
   - `SECRETID` = Your App Registration Secret

2. ✅ **CORS Enabled**:
   - Add `https://portal.azure.com` to allowed origins
   - Or use `*` for testing (not recommended for production)

3. ✅ **Function App Running**:
   - Check Azure Portal > Overview
   - Status should show "Running"

4. ✅ **Functions Deployed**:
   - Check Functions list
   - Should see DefenderC2Dispatcher, DefenderC2TIManager, etc.

## Troubleshooting

### 401 Unauthorized
- Check Authentication settings in Azure Portal
- Verify function key if using key-based auth
- Ensure CORS is configured

### 500 Internal Server Error
- Check Function App logs in Azure Portal
- Verify APPID and SECRETID environment variables
- Check that DefenderC2Automator module is deployed

### No Response / Timeout
- Verify Function App is running
- Check network connectivity
- Verify URL is correct

### "Function app not configured" Error
- Set APPID environment variable
- Set SECRETID environment variable
- Restart Function App

---

**Next Steps**:
1. Check your Function App authentication settings in Azure Portal
2. Either disable auth or get the function key
3. Update FunctionAppName parameter in workbook
4. Test that queries populate correctly

**Status**: Authentication configuration needed ⚠️
