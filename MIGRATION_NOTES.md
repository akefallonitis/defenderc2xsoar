# Migration Notes: MDE to DefenderC2 Consolidation

## Overview
This document describes the consolidation and renaming changes made to align with DefenderC2 naming conventions and improve the architecture by consolidating live response operations.

## Changes Made

### 1. Function Renaming (MDE → DefenderC2)

All MDE-prefixed functions have been renamed to DefenderC2-prefixed:

| Old Name | New Name |
|----------|----------|
| MDEDispatcher | DefenderC2Dispatcher |
| MDEOrchestrator | DefenderC2Orchestrator |
| MDECDManager | DefenderC2CDManager |
| MDEHuntManager | DefenderC2HuntManager |
| MDEIncidentManager | DefenderC2IncidentManager |
| MDETIManager | DefenderC2TIManager |
| MDEAutomator (module) | DefenderC2Automator (module) |

### 2. Live Response and Library Function Consolidation

**Functions Removed:**
- `GetLiveResponseFile` (standalone function)
- `PutLiveResponseFileFromLibrary` (standalone function)
- `ListLibraryFiles` (standalone function)
- `GetLibraryFile` (standalone function)
- `DeleteLibraryFile` (standalone function)

**Reason:** These functions were redundant as DefenderC2Orchestrator provides a better consolidated architecture.

**Functions Added to DefenderC2Orchestrator:**
- `PutLiveResponseFileFromLibrary` - Deploy files from Azure Storage library to devices
- `ListLibraryFiles` - List all files in Azure Storage library
- `GetLibraryFile` - Retrieve file from Azure Storage library (Base64 encoded)
- `DeleteLibraryFile` - Delete file from Azure Storage library

**Result:**
- Total function count reduced from 11 to 6
- All live response operations consolidated in DefenderC2Orchestrator
- All library operations consolidated in DefenderC2Orchestrator
- Cleaner, more maintainable architecture

### 3. DefenderC2Orchestrator Capabilities

DefenderC2Orchestrator now handles ALL live response and library operations:

**Live Response Operations:**
1. **GetLiveResponseSessions** - List active Live Response sessions
2. **InvokeLiveResponseScript** - Execute scripts from Live Response library
3. **GetLiveResponseOutput** - Get command execution results
4. **GetLiveResponseFile** - Download files from devices
5. **PutLiveResponseFile** - Upload files to devices (Base64 content)
6. **PutLiveResponseFileFromLibrary** - Deploy files from Azure Storage library to devices

**Library Operations:**
7. **ListLibraryFiles** - List all files in Azure Storage library
8. **GetLibraryFile** - Retrieve file from Azure Storage library (Base64 encoded)
9. **DeleteLibraryFile** - Delete file from Azure Storage library

### 4. Updated Components

**Code:**
- ✅ Function directories renamed
- ✅ Function code log messages updated
- ✅ Module manifest updated (DefenderC2Automator.psd1)
- ✅ profile.ps1 updated to import DefenderC2Automator
- ✅ DefenderC2Orchestrator enhanced with library deployment

**Documentation:**
- ✅ README.md
- ✅ COMPLETE_DEPLOYMENT.md
- ✅ FUNCTIONS_REFERENCE.md
- ✅ FILE_OPERATIONS_GUIDE.md
- ✅ ARCHITECTURE.md
- ✅ All other markdown documentation files

**Deployment:**
- ✅ function-package.zip regenerated (35KB)
- ✅ GitHub Actions workflow updated
- ✅ Deployment documentation updated with correct function count

**Workbook:**
- ✅ MDEAutomatorWorkbook.json updated with new function names

## Migration Guide for Existing Deployments

### For API Consumers

If you were calling the standalone functions, update your API calls:

**Old:**
```json
POST /api/GetLiveResponseFile
{
  "DeviceId": "device-id",
  "FilePath": "C:\\file.txt",
  "tenantId": "tenant-id"
}
```

**New:**
```json
POST /api/DefenderC2Orchestrator
{
  "Function": "GetLiveResponseFile",
  "DeviceIds": "device-id",
  "filePath": "C:\\file.txt",
  "tenantId": "tenant-id"
}
```

**Old:**
```json
POST /api/PutLiveResponseFileFromLibrary
{
  "fileName": "script.ps1",
  "DeviceIds": "device-id",
  "tenantId": "tenant-id"
}
```

**New:**
```json
POST /api/DefenderC2Orchestrator
{
  "Function": "PutLiveResponseFileFromLibrary",
  "fileName": "script.ps1",
  "DeviceIds": "device-id",
  "tenantId": "tenant-id"
}
```

**Old:**
```json
GET /api/ListLibraryFiles?code={key}
```

**New:**
```json
POST /api/DefenderC2Orchestrator
{
  "Function": "ListLibraryFiles",
  "tenantId": "tenant-id"
}
```

**Old:**
```json
POST /api/GetLibraryFile
{
  "fileName": "script.ps1"
}
```

**New:**
```json
POST /api/DefenderC2Orchestrator
{
  "Function": "GetLibraryFile",
  "fileName": "script.ps1",
  "tenantId": "tenant-id"
}
```

**Old:**
```json
POST /api/DeleteLibraryFile
{
  "fileName": "script.ps1"
}
```

**New:**
```json
POST /api/DefenderC2Orchestrator
{
  "Function": "DeleteLibraryFile",
  "fileName": "script.ps1",
  "tenantId": "tenant-id"
}
```

### For Azure Function Apps

When deploying the updated code:

1. The deployment package now contains DefenderC2* functions instead of MDE* functions
2. Old MDE* function endpoints will no longer exist
3. Update any hardcoded references to function names in your code or configuration
4. The workbook has been updated to use the new function names

## Benefits

1. **Consistent Naming**: All functions now use DefenderC2 prefix aligned with project name
2. **Consolidated Architecture**: All live response and library operations in one function (DefenderC2Orchestrator)
3. **Reduced Complexity**: Fewer functions to maintain (6 instead of 11)
4. **Better Organization**: All file operations (both live response and library) in one place
5. **Web Deployment Ready**: Package ready for GitHub-based web deployment

## Verification

After deployment, verify:

```bash
# Check function count (should be 6)
az functionapp function list \
  --resource-group your-rg \
  --name your-function-app \
  --query "length([*])"

# Check DefenderC2Orchestrator exists
az functionapp function show \
  --resource-group your-rg \
  --name your-function-app \
  --function-name DefenderC2Orchestrator
```

## Helper Scripts

The helper scripts in the `scripts/` directory reference the old API endpoints for backward compatibility. To use the new consolidated endpoint:

**Old Script Usage:**
```powershell
.\Get-LibraryFiles.ps1 -UseAPI -FunctionUrl "https://func.azurewebsites.net/api/ListLibraryFiles" -FunctionKey "key"
```

**New API Usage:**
```powershell
$body = @{
    Function = "ListLibraryFiles"
    tenantId = "tenant-id"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
    -Uri "https://func.azurewebsites.net/api/DefenderC2Orchestrator?code=key" `
    -Body $body `
    -ContentType "application/json"
```

## Reference

- Problem Statement: Consolidate live response operations and library file operations into DefenderC2Orchestrator
- Aligned with: mdeautomator GitHub project structure
- Deployment Method: Web deployment package via GitHub
- Total Functions: 6 Azure Functions + 1 PowerShell module (DefenderC2Automator)
