# Naming Convention Audit - DefenderXDRC2XSOAR v2.3.0

## Project Naming Standards

### Primary Names (Correct)
- **DefenderXDR** - Product branding for all user-facing elements
- **DefenderXDRC2XSOAR** - Full product name for technical integrations
- **defenderxdrc2xsoar** - Repository name, lowercase for Git/URLs

### Deprecated Names (Must Remove)
- ❌ **MDEAutomator** - Original project reference, should be removed
- ❌ **MDE Automator Local** - Old module descriptions
- ❌ **DefenderC2Automator** - Previous version name

### Legacy Names (Keep for Backward Compatibility)
- ⚠️ **DefenderC2Dispatcher** - Legacy function for workbook compatibility
- ⚠️ **DefenderC2Orchestrator** - Legacy function for workbook compatibility
- ⚠️ **DefenderC2*Manager** - Legacy functions (Incident, TI, Hunt, CD)

---

## Audit Results

### 1. ❌ MDEAutomator References Found (30+ instances)

#### Module Files (functions/DefenderXDRC2XSOAR/)
```
MDEAuth.psm1:3              "Authentication module for MDE Automator Local"
MDEConfig.psm1:3            "Configuration management module for MDE Automator Local"
MDEConfig.psm1:17           $configDir = Join-Path $env:USERPROFILE ".mdeautomator"
MDEDevice.psm1:3            "Device actions module for MDE Automator Local"
MDEThreatIntel.psm1:3       "Threat Intelligence module for MDE Automator Local"
MDEHunting.psm1:3           "Advanced Hunting module for MDE Automator Local"
MDEIncident.psm1:3          "Incident management module for MDE Automator Local"
MDEDetection.psm1:3         "Custom detection module for MDE Automator Local"
MDELiveResponse.psm1:3      "Live Response module for MDE Automator Local"
```

#### Documentation Files
```
README.md:718               | Feature | Azure Workbook | Standalone PowerShell | Original MDEAutomator |
README.md:797               1. **MDEAutomator (Device Actions)** - Isolate, scan, restrict devices
README.md:891               - **Original Project**: [MDEAutomator](https://github.com/msdirtbag/MDEAutomator)
README.md:908               - **[MDEAutomator](https://github.com/msdirtbag/MDEAutomator)** - Original Python/Flask
functions/DefenderXDRC2XSOAR/README.md:1    # MDEAutomator PowerShell Module
functions/DefenderXDRC2XSOAR/README.md:7    The MDEAutomator module is...
DEPLOYMENT.md:141           - **Name**: `MDE-Automator-MultiTenant`
DEPLOYMENT.md:152           - **Description**: `MDE-Automator-Secret`
DEPLOYMENT.md:215           - **Function App Name**: Enter a globally unique name (e.g., `mde-automator-func-prod`)
```

### 2. ⚠️ DefenderC2* Legacy References (Acceptable for Compatibility)

#### Legacy Function Names (KEEP - Workbook Dependency)
```
functions/DefenderC2CDManager/          ✅ Keep - workbook uses /api/DefenderC2CDManager
functions/DefenderC2Dispatcher/         ✅ Keep - workbook uses /api/DefenderC2Dispatcher
functions/DefenderC2HuntManager/        ✅ Keep - workbook uses /api/DefenderC2HuntManager
functions/DefenderC2IncidentManager/    ✅ Keep - workbook uses /api/DefenderC2IncidentManager
functions/DefenderC2Orchestrator/       ✅ Keep - workbook uses /api/DefenderC2Orchestrator
functions/DefenderC2TIManager/          ✅ Keep - workbook uses /api/DefenderC2TIManager
```

#### Workbook References (Correct)
```
workbook/DefenderC2-Hybrid.json         ✅ Correct - uses DefenderC2 branding
workbook/DefenderC2-CustomEndpoint.json ✅ Correct - uses DefenderC2 branding
```

### 3. ✅ Correct Naming (No Changes Needed)

#### New Worker Functions
```
functions/MDOWorker/                    ✅ Correct - Microsoft Defender for Office 365
functions/MDCWorker/                    ✅ Correct - Microsoft Defender for Cloud
functions/MDIWorker/                    ✅ Correct - Microsoft Defender for Identity
functions/EntraIDWorker/                ✅ Correct - Entra ID
functions/IntuneWorker/                 ✅ Correct - Intune
functions/AzureWorker/                  ✅ Correct - Azure
```

#### Consolidated Functions
```
functions/DefenderXDRManager/           ✅ Correct - uses DefenderXDR
functions/DefenderMDEManager/           ✅ Correct - uses DefenderMDE
functions/XDROrchestrator/              ✅ Correct - uses XDR
```

#### Module Folder
```
functions/DefenderXDRC2XSOAR/           ✅ Correct - folder name matches project
```

---

## Required Changes

### Priority 1: Remove MDEAutomator References

#### A. Module Description Headers
**Files to Update:**
- `functions/DefenderXDRC2XSOAR/MDEAuth.psm1`
- `functions/DefenderXDRC2XSOAR/MDEConfig.psm1`
- `functions/DefenderXDRC2XSOAR/MDEDevice.psm1`
- `functions/DefenderXDRC2XSOAR/MDEThreatIntel.psm1`
- `functions/DefenderXDRC2XSOAR/MDEHunting.psm1`
- `functions/DefenderXDRC2XSOAR/MDEIncident.psm1`
- `functions/DefenderXDRC2XSOAR/MDEDetection.psm1`
- `functions/DefenderXDRC2XSOAR/MDELiveResponse.psm1`

**Change:**
```powershell
# OLD:
<#
.SYNOPSIS
    Authentication module for MDE Automator Local

# NEW:
<#
.SYNOPSIS
    Authentication module for DefenderXDRC2XSOAR (MDE operations)
```

#### B. Config Directory Path
**File:** `functions/DefenderXDRC2XSOAR/MDEConfig.psm1:17`

**Change:**
```powershell
# OLD:
$configDir = Join-Path $env:USERPROFILE ".mdeautomator"

# NEW:
$configDir = Join-Path $env:USERPROFILE ".defenderxdr"
```

#### C. Module README
**File:** `functions/DefenderXDRC2XSOAR/README.md`

**Change:**
```markdown
# OLD:
# MDEAutomator PowerShell Module
The MDEAutomator module is a collection...

# NEW:
# DefenderXDRC2XSOAR PowerShell Modules
The DefenderXDRC2XSOAR module collection provides...
```

### Priority 2: Update Documentation

#### A. Main README.md
**Remove:**
- Lines referencing "Original MDEAutomator"
- Comparison table with MDEAutomator column
- External links to msdirtbag/MDEAutomator (keep only in Credits section)

**Update:**
```markdown
# OLD:
1. **MDEAutomator (Device Actions)** - Isolate, scan, restrict devices

# NEW:
1. **Device Actions** - Isolate, scan, restrict devices via DefenderMDEManager
```

#### B. DEPLOYMENT.md
**Update example names:**
```
# OLD:
MDE-Automator-MultiTenant
mde-automator-func-prod

# NEW:
DefenderXDR-MultiTenant
defenderxdr-func-prod
```

### Priority 3: Maintain Backward Compatibility

#### ✅ DO NOT CHANGE (Workbook Dependency)

**Legacy Functions - Must Keep Exact Names:**
```
/api/DefenderC2CDManager
/api/DefenderC2Dispatcher
/api/DefenderC2HuntManager
/api/DefenderC2IncidentManager
/api/DefenderC2Orchestrator
/api/DefenderC2TIManager
```

**Reason:** Existing workbooks use these endpoint paths in CustomEndpoint queries. Changing names would break deployed workbooks.

**Strategy:** Keep legacy functions as wrappers/aliases to new workers for backward compatibility.

---

## Workbook Compatibility Requirements

### CustomEndpoint Query Format (MUST SUPPORT)

Workbooks use this JSON format:
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
  "body": "{\"action\":\"Get Devices\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.devices[*]",
      "columns": [...]
    }
  }]
}
```

### Required Response Format

**Legacy Functions MUST Return:**
```json
{
  "devices": [...],        // For device queries
  "indicators": [...],     // For TI queries
  "incidents": [...],      // For incident queries
  "results": [...]         // For hunting queries
}
```

**New Workers Return:**
```json
{
  "success": true,
  "action": "GetDevices",
  "tenantId": "xxx",
  "result": {...},
  "timestamp": "2025-11-10T..."
}
```

### Compatibility Solution

**Legacy functions wrap new workers:**
```powershell
# DefenderC2Dispatcher wraps DefenderMDEManager
# Transform response format for workbook compatibility
if ($result.success) {
    @{ devices = $result.result } | ConvertTo-Json -Depth 10
} else {
    @{ error = $result.error } | ConvertTo-Json
}
```

---

## Implementation Checklist

### Phase 1: Clean Module Headers ✅
- [ ] Update 8 .psm1 module descriptions
- [ ] Change config directory path from .mdeautomator to .defenderxdr
- [ ] Update module README.md

### Phase 2: Clean Documentation ✅
- [ ] Remove MDEAutomator references from main README.md
- [ ] Update DEPLOYMENT.md example names
- [ ] Update MIGRATION_GUIDE.md (already has DefenderC2Automator → DefenderXDRC2XSOAR)

### Phase 3: Verify Compatibility ✅
- [ ] Test legacy functions still return correct format
- [ ] Verify workbook CustomEndpoint queries work
- [ ] Confirm ARM Actions work with response format

### Phase 4: Package and Deploy ✅
- [ ] Run create-package.ps1
- [ ] Verify package size and contents
- [ ] Commit and push changes
- [ ] Wait for auto-deployment

---

## Testing Plan

### 1. Legacy Function Test
```powershell
$response = Invoke-RestMethod `
  -Uri "https://your-app.azurewebsites.net/api/DefenderC2Dispatcher" `
  -Method Post `
  -Body (@{action="Get Devices"; tenantId="xxx"}|ConvertTo-Json)

# Should return: { devices: [...] }
```

### 2. New Worker Test
```powershell
$response = Invoke-RestMethod `
  -Uri "https://your-app.azurewebsites.net/api/EntraIDWorker" `
  -Method Post `
  -Body (@{action="GetUser"; tenantId="xxx"; userId="user@domain.com"}|ConvertTo-Json)

# Should return: { success: true, action: "GetUser", result: {...} }
```

### 3. Workbook CustomEndpoint Test
- Deploy workbook
- Execute "Get Devices" query
- Verify table renders with device data
- Check for JSON parsing errors

---

## Summary

**Total Changes Required:** 35+ references
**Breaking Changes:** 0 (maintain backward compatibility)
**Risk Level:** Low (only cosmetic/documentation changes)

**Naming Convention Moving Forward:**
- ✅ **Public Branding:** DefenderXDR
- ✅ **Technical Name:** DefenderXDRC2XSOAR
- ✅ **Repository:** defenderxdrc2xsoar
- ⚠️ **Legacy Compatibility:** DefenderC2* (keep for workbooks)
- ❌ **Deprecated:** MDEAutomator, MDE Automator Local
