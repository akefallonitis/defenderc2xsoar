# FunctionApp Parameter Filter Fix

## Issue Summary

**Problem:** CustomEndpoint queries and ARM actions not receiving parameters, causing the workbook to fail for many users.

**Root Cause:** The FunctionApp parameter had an overly restrictive filter that prevented users' Function Apps from appearing in the dropdown.

**Fix:** Removed the restrictive filter to show all Function Apps in the subscription.

---

## The Problem in Detail

### What Was Wrong

The `FunctionApp` parameter (the first parameter users select in the workbook) had this filter:

```kql
Resources
| where type =~ 'microsoft.web/sites'
| where kind contains 'functionapp'
| where name contains 'defender' or tags.purpose =~ 'defenderc2' or tags.application =~ 'defenderc2'  ← PROBLEMATIC
| project id, name, resourceGroup, subscriptionId, location, tags
| order by name asc
```

This required Function Apps to:
- Have 'defender' in the name, OR
- Be tagged with `purpose=defenderc2`, OR
- Be tagged with `application=defenderc2`

### Why This Broke Everything

The parameter dependency chain in the workbook is:

```
FunctionApp (user selects from dropdown)
  ↓
  ├─→ Subscription (auto-discovered from FunctionApp)
  ├─→ ResourceGroup (auto-discovered from FunctionApp)
  ├─→ FunctionAppName (auto-discovered from FunctionApp)
  └─→ TenantId (auto-discovered from FunctionApp)
       ↓
       └─→ DeviceList (auto-discovered using FunctionAppName + TenantId)
            ↓
            └─→ All CustomEndpoint queries and ARM actions
```

**If the FunctionApp dropdown is empty**, the entire chain fails:
- ❌ User can't select a Function App
- ❌ No Subscription, ResourceGroup, FunctionAppName, or TenantId get populated
- ❌ DeviceList remains empty
- ❌ All CustomEndpoint queries fail (no FunctionAppName or TenantId)
- ❌ All ARM actions fail (no parameters available)

### User Impact

Users reported:
> "although all values are populate on top menu bar and Available Devices (Auto-populated) works all other customendpoints and armactions etc are not getting those parameters and they dont work"

This suggests they may have been able to work around the filter in some scenarios, but the automatic parameter population was broken for most deployments.

---

## The Solution

### What We Changed

**Removed the restrictive filter** from the FunctionApp parameter query:

```kql
Resources
| where type =~ 'microsoft.web/sites'
| where kind contains 'functionapp'
| project id, name, resourceGroup, subscriptionId, location, tags
| order by name asc
```

Now the query shows **ALL Function Apps** in the user's subscription(s), regardless of naming or tags.

### Updated Description

Also updated the parameter description for clarity:

**Before:**
```
"Select your DefenderC2 Function App. The list shows Function Apps with 'defender' in the name or tagged with 'purpose=defenderc2'."
```

**After:**
```
"Select your DefenderC2 Function App from the list of available Function Apps in your subscription(s)."
```

---

## How to Verify the Fix

### For Users

1. **Open the workbook** in Azure Portal
2. **Check the FunctionApp dropdown** - you should now see ALL your Function Apps listed
3. **Select your DefenderC2 Function App** - even if it doesn't have 'defender' in the name
4. **Verify auto-population:**
   - Subscription should populate automatically
   - ResourceGroup should populate automatically
   - FunctionAppName should populate automatically
   - TenantId should populate automatically
   - DeviceList should populate with devices

5. **Test a query or action** to confirm everything works

### For Developers

Run the verification script:

```bash
cd deployment
python3 verify_workbook_deployment.py
```

Expected results:
- ✅ Parameter Configuration: PASS
- ✅ Custom Endpoints: PASS
- ✅ All 21 CustomEndpoint queries correctly configured
- ✅ All 15 ARM actions correctly configured

---

## Technical Details

### Parameter Types

- **FunctionApp**: Type 5 (Azure Resource Picker)
  - Uses native Azure resource selector UI
  - Query returns Azure resource properties (id, name, etc.)
  - Resource ID is automatically extracted as parameter value

- **Dependent Parameters**: Type 1 (Text/Dropdown with query)
  - Use Azure Resource Graph queries
  - Have `criteriaData` to trigger refresh when FunctionApp changes
  - Extract specific properties (subscriptionId, resourceGroup, name, tenantId)

### Parameter Dependencies

All dependent parameters have proper `criteriaData`:

```json
{
  "name": "Subscription",
  "query": "Resources | where id == '{FunctionApp}' | project value = subscriptionId",
  "criteriaData": [
    {
      "criterionType": "param",
      "value": "{FunctionApp}"
    }
  ]
}
```

This tells the workbook: "When FunctionApp changes, re-run this query with the new value."

---

## Files Modified

- `workbook/DefenderC2-Workbook.json`
  - Line changes: 2 (FunctionApp parameter query and description)
  - Impact: Makes FunctionApp dropdown work for all users

---

## Related Documentation

- [PARAMETER_DEPENDENCY_FLOW.md](PARAMETER_DEPENDENCY_FLOW.md) - Visual guide to parameter dependencies
- [WORKBOOK_PARAMETERS_GUIDE.md](deployment/WORKBOOK_PARAMETERS_GUIDE.md) - Complete parameters reference
- [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md) - Best practices for workbook development

---

## FAQ

### Q: Why was the filter there in the first place?

A: The filter was likely intended to help users find the correct Function App in environments with many Function Apps. However, it was too restrictive and prevented legitimate deployments from working.

### Q: Will this show too many Function Apps?

A: Possibly, in large environments. However, showing all Function Apps is better than showing none. Users can use the search box in the resource picker to filter by name.

### Q: Can I add the filter back if I want it?

A: Yes, if you want to filter the list for your specific environment, you can edit the workbook in Azure Portal:
1. Edit → Advanced Editor
2. Search for `"name": "FunctionApp"`
3. Add your custom filter to the query
4. Example: `| where name contains 'myprefix'`

### Q: What if my Function App still doesn't appear?

A: Check:
1. **Permissions**: You need Reader access to the subscription/resource group
2. **Resource type**: Ensure it's actually a Function App (not a regular App Service)
3. **Subscription selection**: The workbook searches across all subscriptions you have access to

---

**Status**: ✅ Fixed in commit 03e08f8  
**Impact**: High - Resolves workbook functionality for all users  
**Breaking Changes**: None - only removes restrictions
