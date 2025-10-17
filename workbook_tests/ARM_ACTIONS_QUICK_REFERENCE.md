# ARM Actions Quick Reference

## DeviceManager-Hybrid.workbook.json ARM Actions

This workbook now includes 7 ARM action buttons for executing Defender XDR actions through Azure Resource Manager.

## Available ARM Actions

### 1. 🔍 Run Antivirus Scan
**Location:** `scan-group`  
**Action Value:** `Run Antivirus Scan`  
**Required Parameters:**
- TenantId
- DeviceList
- ScanType (Quick or Full)

**What it does:** Initiates an antivirus scan on selected devices

### 2. 🔒 Isolate Devices
**Location:** `isolate-group`  
**Action Value:** `Isolate Device`  
**Required Parameters:**
- TenantId
- DeviceList
- IsolationType (Full or Selective)

**What it does:** Isolates selected devices from the network

### 3. 🔓 Unisolate Devices
**Location:** `unisolate-group`  
**Action Value:** `Unisolate Device`  
**Required Parameters:**
- TenantId
- DeviceList

**What it does:** Removes network isolation from selected devices

### 4. 📦 Collect Investigation Package
**Location:** `collect-group`  
**Action Value:** `Collect Investigation Package`  
**Required Parameters:**
- TenantId
- DeviceList

**What it does:** Collects forensic investigation package from selected devices

### 5. 🚫 Restrict App Execution
**Location:** `restrict-group`  
**Action Value:** `Restrict App Execution`  
**Required Parameters:**
- TenantId
- DeviceList

**What it does:** Restricts application execution on selected devices (only Microsoft-signed apps allowed)

### 6. ✅ Unrestrict App Execution
**Location:** `unrestrict-group`  
**Action Value:** `Unrestrict App Execution`  
**Required Parameters:**
- TenantId
- DeviceList

**What it does:** Removes application execution restrictions from selected devices

### 7. ❌ Cancel Action
**Location:** `cancel-action-group`  
**Action Value:** `Cancel Action`  
**Required Parameters:**
- TenantId
- DeviceList
- CancelActionId

**What it does:** Cancels a running Defender XDR action

## ARM Action Structure

Each ARM action uses the following structure:

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "list",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Action Label",
      "armActionContext": {
        "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations",
        "httpMethod": "POST",
        "params": [
          {"key": "api-version", "value": "2022-03-01"},
          {"key": "action", "value": "Action Name"},
          {"key": "tenantId", "value": "{TenantId}"},
          {"key": "deviceIds", "value": "{DeviceList}"}
        ]
      }
    }]
  }
}
```

## Common Parameters

All ARM actions use these common parameters:

| Parameter | Description | Source |
|-----------|-------------|--------|
| Subscription | Azure Subscription ID | Auto-populated from FunctionApp |
| ResourceGroup | Azure Resource Group | Auto-populated from FunctionApp |
| FunctionAppName | Function App name | Auto-populated from FunctionApp |
| TenantId | Defender XDR Tenant ID | User selects from dropdown |
| DeviceList | Comma-separated device IDs | Auto-populated from device selection |

## Action-Specific Parameters

| Action | Parameter | Values | Description |
|--------|-----------|--------|-------------|
| Scan | ScanType | Quick, Full | Type of antivirus scan |
| Isolate | IsolationType | Full, Selective | Level of device isolation |
| Cancel | CancelActionId | Action ID | ID of action to cancel |

## How ARM Actions Work

1. **User clicks ARM action button** in workbook
2. **Azure validates permissions** (requires `Microsoft.Web/sites/functions/invoke/action`)
3. **Azure invokes Function App** via ARM endpoint
4. **Function App processes request** and calls Defender XDR API
5. **Results displayed** in workbook result section
6. **Action logged** in Azure Activity Log for audit trail

## Benefits of ARM Actions

✅ **Azure RBAC Integration** - Respects Azure permissions  
✅ **Audit Trails** - All executions logged in Azure Activity Log  
✅ **Enterprise Governance** - Proper Azure resource management  
✅ **Security** - No direct API keys in workbook  
✅ **Consistency** - Standard Azure deployment patterns

## Required Permissions

To use ARM actions, users need:
- **Reader** role on subscription (for Resource Graph queries)
- **Microsoft.Web/sites/functions/invoke/action** permission on Function App
- **Defender XDR API permissions** (configured in Function App's managed identity)

## Troubleshooting

### ARM Action Button Not Visible
- Check that all required parameters are populated
- Verify FunctionApp, TenantId, and DeviceList have values

### ARM Action Fails with 403
- Verify user has `Microsoft.Web/sites/functions/invoke/action` permission
- Check Function App RBAC settings

### ARM Action Fails with 400
- Check that device is not already in the requested state
- Verify all required parameters are provided
- Check "Pending Actions" section for conflicts

## Comparison with CustomEndpoint

| Feature | ARM Actions | CustomEndpoint |
|---------|-------------|----------------|
| Execution Method | ARM invocation | Direct HTTPS |
| RBAC Integration | ✅ Full | ⚠️ Function App only |
| Audit Logging | ✅ Azure Activity Log | ⚠️ Function logs |
| Permissions | Azure RBAC | Function App access |
| Complexity | Higher | Lower |
| Best For | Enterprise governance | Simple deployments |

## When to Use

### Use ARM Actions (Hybrid Workbook) When:
- ✅ You need enterprise-grade governance
- ✅ You require Azure Activity Log audit trails
- ✅ You have strict RBAC requirements
- ✅ You need compliance with Azure policies

### Use CustomEndpoint (CustomEndpoint-Only) When:
- ✅ You want maximum simplicity
- ✅ You don't need ARM audit trails
- ✅ You prefer easier troubleshooting
- ✅ You want consistent behavior everywhere

## Examples

### Execute Scan on Multiple Devices
1. Select Function App → Auto-populates connection parameters
2. Select Tenant → Choose from dropdown
3. Select Devices → Check devices in list
4. Choose Scan Type → Quick or Full
5. Click "🔍 Run Antivirus Scan"
6. View results in scan-result section

### Isolate Compromised Device
1. Ensure prerequisites are met (Function App, Tenant, Devices selected)
2. Select Isolation Type → Full or Selective
3. Click "🔒 Isolate Devices"
4. Confirm action in popup
5. Track progress in "Action Status Tracking" section

### Cancel Running Action
1. Find action ID in "Currently Running Actions" or "Machine Actions History"
2. Copy Action ID
3. Paste into CancelActionId parameter (or click cancel link if auto-populated)
4. Click "❌ Cancel Action"
5. Verify cancellation in status tracking

## Related Documentation

- [Parent README](README.md) - Main workbook documentation
- [workingexamples/README.md](workingexamples/README.md) - Template documentation
- [workingexamples/VERIFICATION_REPORT.md](workingexamples/VERIFICATION_REPORT.md) - Implementation verification

---

**Last Updated:** 2025-10-16  
**Workbook Version:** DeviceManager-Hybrid v1.1 with ARM Actions
