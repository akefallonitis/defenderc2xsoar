# Phase 5-8 Completion Guide

## Summary
Phases 1-3 completed successfully. Phase 4 architecture defined. Phases 5-8 require ARM template creation and documentation updates.

## Phase 5: ARM Template Updates Required

### Current State
- Existing `deployment/azuredeploy.json` has basic Function App + Storage
- Missing: Queue/Table/Blob services, Managed Identity, RBAC

### Required Updates

**1. Storage Account Resource (Update existing)**
```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "apiVersion": "2023-01-01",
  "name": "[variables('storageAccountName')]",
  "location": "[parameters('location')]",
  "sku": {
    "name": "Standard_LRS"
  },
  "kind": "StorageV2",
  "properties": {
    "supportsHttpsTrafficOnly": true,
    "minimumTlsVersion": "TLS1_2",
    "allowBlobPublicAccess": false
  }
}
```

**2. Blob Container Resource (NEW)**
```json
{
  "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
  "apiVersion": "2023-01-01",
  "name": "[concat(variables('storageAccountName'), '/default/liveresponse')]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
  ],
  "properties": {
    "publicAccess": "None"
  }
}
```

**3. Table Storage Resource (NEW - for StatusTracker)**
```json
{
  "type": "Microsoft.Storage/storageAccounts/tableServices/tables",
  "apiVersion": "2023-01-01",
  "name": "[concat(variables('storageAccountName'), '/default/XDROperationStatus')]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
  ]
}
```

**4. Function App - Add Managed Identity**
```json
{
  "type": "Microsoft.Web/sites",
  "apiVersion": "2023-01-01",
  "name": "[variables('functionAppName')]",
  "location": "[parameters('location')]",
  "kind": "functionapp",
  "identity": {
    "type": "SystemAssigned"  // ADD THIS
  },
  "properties": {
    "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('hostingPlanName'))]",
    "siteConfig": {
      "appSettings": [
        {
          "name": "APPID",
          "value": "[parameters('spnId')]"
        },
        {
          "name": "SECRETID",
          "value": "[parameters('spnSecret')]"
        },
        {
          "name": "STORAGE_ACCOUNT_NAME",
          "value": "[variables('storageAccountName')]"
        },
        // ... other settings
      ]
    }
  }
}
```

**5. RBAC Role Assignments (NEW - 3 required)**

```json
{
  "type": "Microsoft.Authorization/roleAssignments",
  "apiVersion": "2022-04-01",
  "name": "[guid(resourceGroup().id, 'queue-contributor')]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]",
    "[resourceId('Microsoft.Web/sites', variables('functionAppName'))]"
  ],
  "properties": {
    "roleDefinitionId": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Authorization/roleDefinitions/', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')]",
    "principalId": "[reference(resourceId('Microsoft.Web/sites', variables('functionAppName')), '2023-01-01', 'Full').identity.principalId]",
    "principalType": "ServicePrincipal",
    "scope": "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
  }
}
```

Role Definition IDs:
- **Storage Queue Data Contributor**: `974c5e8b-45b9-4653-ba55-5f855dd0fb88`
- **Storage Table Data Contributor**: `0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3`
- **Storage Blob Data Contributor**: `ba92f5b4-2d11-453d-a403-e96b0029c9fe`

Repeat the role assignment block 3 times with different roleDefinitionIds and guids.

## Phase 6: Deployment Package Script

Create `deployment/create-deployment-package.ps1`:

```powershell
# Create deployment package for DefenderXDR v3.0

$packageDir = ".\package-temp"
$zipFile = ".\function-package.zip"

# Clean previous package
if (Test-Path $packageDir) { Remove-Item $packageDir -Recurse -Force }
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

# Create temp directory
New-Item -ItemType Directory -Path $packageDir

# Copy all functions (13 total)
$functions = @(
    "DefenderXDRGateway",
    "DefenderXDROrchestrator",
    "DefenderXDRMDEWorker",
    "DefenderXDRMDOWorker",
    "DefenderXDRMDCWorker",
    "DefenderXDRMDIWorker",
    "DefenderXDREntraIDWorker",
    "DefenderXDRIntuneWorker",
    "DefenderXDRAzureWorker",
    "DefenderXDRHuntManager",
    "DefenderXDRIncidentManager",
    "DefenderXDRThreatIntelManager",
    "DefenderXDRCustomDetectionManager"
)

foreach ($func in $functions) {
    Copy-Item -Path "..\functions\$func" -Destination "$packageDir\$func" -Recurse
}

# Copy modules
Copy-Item -Path "..\functions\modules" -Destination "$packageDir\modules" -Recurse

# Copy root files
Copy-Item -Path "..\functions\host.json" -Destination "$packageDir\"
Copy-Item -Path "..\functions\profile.ps1" -Destination "$packageDir\"
Copy-Item -Path "..\functions\requirements.psd1" -Destination "$packageDir\"

# Create zip
Compress-Archive -Path "$packageDir\*" -DestinationPath $zipFile -Force

# Clean up
Remove-Item $packageDir -Recurse -Force

Write-Host "Package created: $zipFile" -ForegroundColor Green
Write-Host "Size: $((Get-Item $zipFile).Length / 1MB) MB" -ForegroundColor Cyan
```

## Phase 7: README Updates

Add to `README.md`:

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│  DefenderXDR v3.0 - Worker-Based Architecture               │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  Azure Workbook  │
│   ARM Actions    │
└────────┬─────────┘
         │
         ▼
┌────────────────────────┐
│  DefenderXDRGateway    │  ◄─── Single Entry Point
│  - Health Check        │
│  - Status Lookup       │
│  - Bulk Detection      │
└───────────┬────────────┘
            │
            ▼
┌──────────────────────────┐
│ DefenderXDROrchestrator  │  ◄─── Central Router
│  Routes to Workers       │
└────────┬─────────────────┘
         │
    ┌────┴───────────────────────────────────┐
    │                                        │
    ▼                                        ▼
┌────────────────────┐            ┌───────────────────┐
│   Service Workers  │            │  Manager Workers  │
│                    │            │                   │
│ ├─ MDE Worker     │            │ ├─ Hunt Manager   │
│ ├─ MDO Worker     │            │ ├─ Incident Mgr   │
│ ├─ MDC Worker     │            │ ├─ ThreatIntel    │
│ ├─ MDI Worker     │            │ └─ CustomDetect   │
│ ├─ EntraID Worker │            │                   │
│ ├─ Intune Worker  │            └───────────────────┘
│ └─ Azure Worker   │
└────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  Shared Infrastructure (Managed Identity Auth)           │
│                                                          │
│  ┌─────────────────┐  ┌────────────────┐  ┌─────────┐  │
│  │ Queue Storage   │  │ Table Storage  │  │  Blob   │  │
│  │ Bulk Operations │  │ Status Tracker │  │ LiveResp│  │
│  └─────────────────┘  └────────────────┘  └─────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

**Post-Deployment:**
1. Test health endpoint: `https://<your-app>.azurewebsites.net/api/DefenderXDRGateway/health`
2. Verify Managed Identity RBAC assignments (3 roles on Storage Account)
3. Upload Live Response scripts to Blob Storage (`liveresponse` container)

### Live Response File Library

**Upload Scripts:**
```powershell
# Use BlobManager module
Import-Module ./functions/modules/DefenderXDRIntegrationBridge/BlobManager.psm1

Initialize-XDRBlobStorage -StorageAccountName "your-storage-account"

Add-XDRBlobFile -TenantId "your-tenant-id" `
    -FilePath "C:\scripts\remediation.ps1" `
    -Category "scripts"
```

**PutFile Operation:**
```json
POST /api/DefenderXDRGateway
{
  "service": "MDE",
  "action": "PutFile",
  "tenantId": "xxx",
  "parameters": {
    "machineId": "device-id",
    "fileName": "tool.exe"
  }
}
```
File is retrieved from Blob (`liveresponse/xxx/uploads/tool.exe`) and uploaded to device.

**GetFile Operation:**
```json
POST /api/DefenderXDRGateway
{
  "service": "MDE",
  "action": "GetFile",
  "tenantId": "xxx",
  "parameters": {
    "machineId": "device-id",
    "filePath": "C:\\Windows\\System32\\drivers\\etc\\hosts"
  }
}
```
Response includes SAS URL for download (24-hour validity).

## Phase 8: PERMISSIONS.md Updates

Add section:

### v3.0.0 Storage Permissions (Managed Identity)

**Azure Storage Account Permissions:**

The Function App's **System-Assigned Managed Identity** requires these RBAC roles on the Storage Account:

| Role | Purpose | Scope |
|------|---------|-------|
| **Storage Queue Data Contributor** | Bulk operation queueing | Storage Account |
| **Storage Table Data Contributor** | Operation status tracking | Storage Account |
| **Storage Blob Data Contributor** | Live Response file library | Storage Account |

**Setup Commands:**
```powershell
$functionAppName = "your-function-app"
$storageAccountName = "your-storage-account"
$resourceGroup = "your-resource-group"

# Get Function App Managed Identity Principal ID
$principalId = (Get-AzWebApp -ResourceGroupName $resourceGroup -Name $functionAppName).Identity.PrincipalId

# Get Storage Account Resource ID
$storageId = (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName).Id

# Assign roles
New-AzRoleAssignment -ObjectId $principalId `
    -RoleDefinitionName "Storage Queue Data Contributor" `
    -Scope $storageId

New-AzRoleAssignment -ObjectId $principalId `
    -RoleDefinitionName "Storage Table Data Contributor" `
    -Scope $storageId

New-AzRoleAssignment -ObjectId $principalId `
    -RoleDefinitionName "Storage Blob Data Contributor" `
    -Scope $storageId
```

**Verification:**
```powershell
Get-AzRoleAssignment -ObjectId $principalId -Scope $storageId
```

**Microsoft Graph & Defender API Permissions:**
Same as v2.4.0 (no changes).

---

## Completion Checklist

- [x] Phase 1: Workers renamed (DefenderXDR prefix) ✓
- [x] Phase 2: BlobManager.psm1 created (586 lines) ✓
- [x] Phase 3: DefenderXDRMDEWorker implemented (1,300+ lines, 63 actions) ✓
- [x] Phase 4: Orchestrator routing architecture defined ✓
- [ ] Phase 5: Update ARM template with Storage + Managed Identity + RBAC
- [ ] Phase 6: Create deployment package script
- [ ] Phase 7: Update README with Deploy button + Live Response docs
- [ ] Phase 8: Update PERMISSIONS.md with Storage RBAC

## Files Created/Modified

### Created:
- `functions/modules/DefenderXDRIntegrationBridge/BlobManager.psm1` (586 lines)
- `functions/DefenderXDRMDEWorker/run.ps1` (1,300+ lines)
- `functions/DefenderXDRMDEWorker/function.json`

### Renamed (Phase 1):
- `AzureWorker` → `DefenderXDRAzureWorker`
- `EntraIDWorker` → `DefenderXDREntraIDWorker`
- `IntuneWorker` → `DefenderXDRIntuneWorker`
- `MDOWorker` → `DefenderXDRMDOWorker`
- `MDCWorker` → `DefenderXDRMDCWorker`
- `MDIWorker` → `DefenderXDRMDIWorker`

### To Update:
- `deployment/azuredeploy.json` (add Storage services, Managed Identity, RBAC)
- `README.md` (add architecture diagram, Deploy button, Live Response docs)
- `PERMISSIONS.md` (add Storage RBAC section)
- `deployment/create-deployment-package.ps1` (create new)

## Testing Commands

**Health Check:**
```powershell
Invoke-RestMethod -Uri "https://<app>.azurewebsites.net/api/DefenderXDRGateway/health"
```

**MDE Action (via Gateway):**
```powershell
$body = @{
    service = "MDE"
    action = "GetDevices"
    tenantId = "your-tenant-id"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://<app>.azurewebsites.net/api/DefenderXDRGateway" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

**Live Response - GetFile:**
```powershell
$body = @{
    service = "MDE"
    action = "GetFile"
    tenantId = "your-tenant-id"
    parameters = @{
        machineId = "device-id"
        filePath = "C:\Windows\System32\config\SAM"
    }
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://<app>.azurewebsites.net/api/DefenderXDRGateway" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

# Download file from Blob SAS URL
Invoke-WebRequest -Uri $response.data.blobDownloadUrl -OutFile "SAM_downloaded.bin"
```

## Next Steps

1. **Complete ARM Template**: Add Storage Account resources, Managed Identity, and 3 RBAC role assignments to `deployment/azuredeploy.json`

2. **Create Deployment Package Script**: Implement `deployment/create-deployment-package.ps1` to bundle all 13 functions + modules

3. **Update Documentation**: 
   - Add architecture diagram to README
   - Add Deploy to Azure button
   - Document Live Response operations
   - Update PERMISSIONS.md with Storage RBAC requirements

4. **Test Deployment**: Deploy ARM template to test subscription, verify:
   - All 13 functions deployed
   - Storage Account has Queue + Table + Blob
   - Managed Identity assigned
   - 3 RBAC roles on Storage Account
   - Health endpoint returns 200 OK
   - MDE Worker can execute GetDevices action
   - GetFile operation stores file in Blob and returns SAS URL

## Version 3.0.0 Summary

**Architecture:**
- Worker-based (13 functions total)
- Gateway → Orchestrator → Workers → Managers
- Shared infrastructure (Queue + Table + Blob)
- Managed Identity (keyless authentication)

**Key Features:**
- Live Response with Blob Storage (GetFile, PutFile, RunScript)
- Bulk operations via Queue Storage
- Status tracking via Table Storage
- One-click deployment via ARM template
- Full RBAC automation (3 Storage roles)
- Multi-tenant support (tenantId in all requests)
- ARM Actions compatible (authLevel: function)

**Code Metrics:**
- Total Functions: 13
- MDE Worker: 1,300+ lines, 63 actions
- BlobManager: 586 lines, 8 functions
- Orchestrator: 206 lines (pure routing)
- Gateway: 520 lines

**Deployment:**
- ARM template with complete infrastructure
- Deployment package script
- Deploy to Azure button
- Post-deployment verification steps
