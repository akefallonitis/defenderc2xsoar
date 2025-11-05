# DefenderC2 Workbook Testing & Troubleshooting Guide

## Quick Test Checklist

### Step 1: Deploy Workbook
1. Azure Portal → Workbooks → New
2. Advanced Editor → Paste `DefenderC2-Workbook.json`
3. Apply → Save

### Step 2: Verify Parameter Population
✅ **Expected Behavior**:
- Select Function App from dropdown → Should auto-populate:
  - Subscription
  - ResourceGroup  
  - FunctionAppName
- Select TenantId from dropdown

❌ **If Parameters Don't Populate**:
- Check Function App is running
- Verify Function App has proper tags/metadata
- Try selecting different Function App

### Step 3: Verify Device Listing (CustomEndpoint Test)
✅ **Expected Behavior**:
- Navigate to "Automator" tab
- Device list should populate within 5-10 seconds
- Table shows: DeviceID, ComputerName, OS, Health, Risk
- Auto-refreshes every 30 seconds

❌ **If Device List Doesn't Populate**:

**Diagnostic Steps**:

1. **Check if query is running**:
   - Look for "Loading..." indicator
   - If stuck on "Loading...", query might be timing out

2. **Check parameter values**:
   - Verify TenantId is selected
   - Verify FunctionAppName is populated
   - Check DevTools (F12) → Network tab for API calls

3. **Verify API endpoint format**:
   Expected call: `POST https://{your-function-app}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get+Devices&tenantId={your-tenant-id}`

4. **Check Function App logs**:
   ```bash
   az functionapp logs tail --name defenderc2 --resource-group {rg}
   ```

5. **Test API directly**:
   ```bash
   curl -X POST "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get+Devices&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" \
     -H "Content-Type: application/json"
   ```

**Common Issues**:

| Issue | Cause | Solution |
|-------|-------|----------|
| "No data" | Function app not responding | Check function app status, restart if needed |
| "Loading..." forever | Query timeout | Increase timeout in query settings |
| Empty table | No devices in tenant | Verify devices exist in Microsoft Defender |
| Error message | Authentication failure | Check APPID/SECRETID environment variables |
| 401 Unauthorized | Missing credentials | Verify Function App authentication config |

### Step 4: Verify Click-to-Select
✅ **Expected Behavior**:
- Device table has "✅ Select" button in DeviceID column
- Click "✅ Select" → DeviceList parameter populates
- Parameter value shows at top: `{selected-device-id}`

❌ **If Click-to-Select Doesn't Work**:
- Check if DeviceList parameter exists in top menu
- Verify parameter is marked as global (`isGlobal: true`)
- Check formatter configuration in query

### Step 5: Verify Conditional Visibility
✅ **Expected Behavior**:
- **Before device selection**: "Isolate Result" section is HIDDEN
- **After device selection**: "Isolate Result" section APPEARS
- Same pattern for other result sections in different tabs

❌ **If Conditional Visibility Doesn't Work**:

**Check These Items**:

1. **Parameter value**: Verify DeviceList actually has a value
2. **Condition syntax**: Should be `isNotEqualTo` with value `""`
3. **Parameter name match**: Must match exactly (case-sensitive)

**Example Working Condition**:
```json
{
  "conditionalVisibilities": [{
    "parameterName": "DeviceList",
    "comparison": "isNotEqualTo",
    "value": ""
  }]
}
```

### Step 6: Verify ARM Actions
✅ **Expected Behavior**:
- Select device
- Choose action from dropdown
- Click "🚨 Isolate Devices" or other action button
- Azure confirmation dialog appears
- Action executes

❌ **If ARM Actions Don't Work**:

**Diagnostic Steps**:

1. **Check parameter accessibility**:
   - Verify ActionToExecute parameter is populated
   - Check DeviceList has device ID
   - Verify TenantId is set

2. **Check ARM action configuration**:
   ```json
   {
     "linkTarget": "ArmAction",
     "armActionContext": {
       "path": "...",
       "body": "..."
     }
   }
   ```

3. **Check RBAC permissions**:
   - Need `Microsoft.Web/sites/functions/invoke/action` permission
   - Verify in Azure Activity Log

4. **Test function directly**:
   ```bash
   az functionapp function invoke \
     --name defenderc2 \
     --function-name DefenderC2Dispatcher \
     --resource-group {rg} \
     --body '{...}'
   ```

## Comprehensive Testing Matrix

### Tab-by-Tab Functionality Test

#### 1. Automator Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Device List | Load tab | Devices populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Click-to-select | Click device | DeviceList populates | [ ] |
| Color coding | Check status | 🟢/🔴 indicators | [ ] |
| Isolate action | Execute | Confirmation dialog | [ ] |
| Result display | After action | Shows when DeviceList set | [ ] |

#### 2. Threat Intel Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Indicator List | Load tab | Indicators populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Add indicator | Fill form + execute | Indicator added | [ ] |
| Click-to-select | Click indicator | IndicatorId populates | [ ] |

#### 3. Actions Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Action List | Load tab | Actions populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Status colors | Check display | 🟢/🟡/🔵/🔴 | [ ] |
| Click-to-cancel | Click action | ActionId populates | [ ] |
| Cancel action | Execute cancel | Action cancelled | [ ] |
| Status query | Fill ActionId | Status shows | [ ] |
| Conditional visibility | Without ActionId | Status hidden | [ ] |
| Conditional visibility | With ActionId | Status visible | [ ] |

#### 4. Hunting Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Sample queries | Select query | HuntQuery populates | [ ] |
| Execute query | Run hunt | Results appear | [ ] |
| Results visibility | Before query | Hidden | [ ] |
| Results visibility | After query | Visible | [ ] |
| Status auto-refresh | Wait 30s | Status updates | [ ] |

#### 5. Incidents Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Incident List | Load tab | Incidents populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Click-to-view | Click incident | IncidentId populates | [ ] |
| Update incident | Execute | Incident updated | [ ] |

#### 6. Detections Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Rules List | Load tab | Rules populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Create rule | Fill form + execute | Rule created | [ ] |
| Update rule | Execute | Rule updated | [ ] |

#### 7. Console Tab
| Feature | Test | Expected Result | Status |
|---------|------|-----------------|--------|
| Library List | Load tab | Scripts populate | [ ] |
| Auto-refresh | Wait 30s | List refreshes | [ ] |
| Execute command | Fill + execute | Command runs | [ ] |
| Poll status | Check status | Status shows | [ ] |
| Results | Check results | Results show | [ ] |
| Conditional visibility | Without ActionId | Results hidden | [ ] |
| Conditional visibility | With ActionId | Results visible | [ ] |

## Common Error Messages & Solutions

### Error: "No data available"
**Causes**:
1. Function app returned empty array
2. JSONPath not matching response structure
3. API error returned

**Solutions**:
```bash
# Check function app response structure
curl -X POST "https://{function-app}/api/DefenderC2Dispatcher?action=Get+Devices&tenantId={tenant}" \
  -H "Content-Type: application/json" | jq .

# Verify JSONPath matches response
# Expected: $.devices[*] for device queries
# Expected: $.actions[*] for action queries
```

### Error: "Failed to execute query"
**Causes**:
1. Network timeout
2. Function app error
3. Invalid parameters

**Solutions**:
1. Check Function App logs
2. Verify parameter values
3. Test API endpoint directly
4. Check CORS settings

### Error: "Parameter not found"
**Causes**:
1. Parameter not marked as global
2. Parameter name mismatch
3. Parameter not initialized

**Solutions**:
```bash
# Verify all parameters are global
grep -A5 '"name": "DeviceList"' workbook/DefenderC2-Workbook.json | grep isGlobal

# Should show: "isGlobal": true
```

### Error: "ARM action failed"
**Causes**:
1. Insufficient permissions
2. Invalid function path
3. Missing parameters

**Solutions**:
1. Check RBAC: Need `Microsoft.Web/sites/functions/invoke/action`
2. Verify in Activity Log: Subscription → Activity Log → Filter by Function App
3. Check parameter values before clicking action

## Performance Optimization

### Auto-Refresh Settings
Current configuration: 30s interval for 8 queries

**If performance is slow**:
1. Increase interval to 60s:
   ```json
   "autoRefreshSettings": {
     "intervalInSeconds": 60,
     "refreshCondition": "always"
   }
   ```

2. Or disable auto-refresh on non-critical queries

### Large Result Sets
If device list > 100 items:
1. Add paging to query
2. Use table filters
3. Increase query timeout

## Advanced Debugging

### Enable Browser DevTools
1. Press F12 in browser
2. Network tab → Filter: XHR
3. Look for POST requests to function app
4. Check request payload and response

### Check Workbook JSON
```bash
# Validate JSON structure
python3 scripts/validate_workbook.py

# Check specific query
cat workbook/DefenderC2-Workbook.json | jq '.items[] | select(.name == "group - automator") | .content.items[] | select(.name == "query - get-devices")'
```

### Test Function App Directly
```bash
# PowerShell
$headers = @{
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod `
    -Uri "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get+Devices&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" `
    -Method POST `
    -Headers $headers

$response | ConvertTo-Json -Depth 10
```

```bash
# Bash
curl -v -X POST \
  "https://defenderc2.azurewebsites.net/api/DefenderC2Dispatcher?action=Get+Devices&tenantId=a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" \
  -H "Content-Type: application/json"
```

## Success Criteria Checklist

Based on original requirements:

- [ ] **1. All manual actions are ARM actions** (15 ARM actions)
- [ ] **2. All listing queries are CustomEndpoint with auto-refresh** (8/16 with auto-refresh)
- [ ] **3. Top-level listings with selection and autopopulation** (5 click-to-select formatters)
- [ ] **4. Conditional visibility per tab** (8 conditional visibility items)
- [ ] **5. Console-like UI for interactive operations** (Console tab with command execution)
- [ ] **6. Optimized UI experience** (Color coding, auto-refresh, autopopulation)
- [ ] **7. Full functionality operational** (All 7 tabs, 87 sub-items)
- [ ] **8. Parameters export correctly** (50 parameters, all global)

## Support

If issues persist after following this guide:

1. Check Function App logs
2. Verify APPID/SECRETID environment variables
3. Test API endpoints directly
4. Check Azure Activity Log for errors
5. Verify RBAC permissions

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-05  
**Workbook Lines**: ~3,850  
**Status**: Production Ready
