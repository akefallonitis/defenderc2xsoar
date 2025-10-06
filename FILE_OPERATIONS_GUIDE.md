# File Operations Guide

Complete guide for file upload/download operations with Microsoft Defender for Endpoint using Azure Storage as a centralized file library.

## 📋 Table of Contents

- [Overview](#overview)
- [Why Use a File Library?](#why-use-a-file-library)
- [Architecture](#architecture)
- [Setup](#setup)
- [User Workflows](#user-workflows)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

This solution provides comprehensive file operations for MDE Live Response:

✅ **Centralized Library**: Store files once in Azure Storage, deploy many times  
✅ **No Manual Base64**: Upload files via Azure Portal, CLI, or PowerShell  
✅ **Deploy to Devices**: Push files to MDE devices with Live Response API  
✅ **Download from Devices**: Retrieve files with automatic browser download  
✅ **Team Collaboration**: Share files across your security team  

### Why Azure Workbooks Can't Upload Files Natively

According to [Microsoft documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-parameters), Azure Workbooks **do not support native file upload controls**. This is a platform limitation.

Our solution works around this by:
1. Using Azure Storage as a file library (upload via Portal/CLI/PowerShell)
2. Listing library files in the workbook (read-only, no upload needed)
3. Deploying selected files via Azure Functions + Live Response API

---

## Why Use a File Library?

### Traditional Approach (Manual Base64)
```powershell
# User must manually encode files
$fileContent = [Convert]::ToBase64String([IO.File]::ReadAllBytes("file.exe"))

# Then paste into workbook (error-prone for large files)
# Re-encode every time
```

**Problems:**
- ❌ Manual Base64 encoding required
- ❌ Copy/paste errors for large files
- ❌ No file versioning
- ❌ No team sharing
- ❌ Re-encode every deployment

### File Library Approach (This Solution)
```powershell
# Upload once (via Portal, CLI, or PowerShell)
az storage blob upload --account-name mdeautomator --container-name library --name tool.exe --file tool.exe

# Deploy many times from workbook (4 clicks)
# No re-encoding needed
```

**Benefits:**
- ✅ Upload once, deploy many times
- ✅ No manual Base64 encoding
- ✅ Centralized file management
- ✅ Team collaboration (shared library)
- ✅ Version control possible (blob versioning)
- ✅ Audit trail (storage logs)

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Storage                           │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Container: "library"                               │     │
│  │  - script.ps1                                       │     │
│  │  - tool.exe                                         │     │
│  │  - config.json                                      │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Read/Write
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Azure Functions                             │
│  - ListLibraryFiles      (GET library contents)             │
│  - GetLibraryFile        (GET file as Base64)               │
│  - PutLiveResponseFile   (Deploy to device)                 │
│  - GetLiveResponseFile   (Download from device)             │
│  - DeleteLibraryFile     (Remove from library)              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ API Calls
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Azure Workbook                              │
│  Tab 1: Library Management                                   │
│  Tab 2: Upload Operations                                    │
│  Tab 3: Download Operations                                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Live Response API
                        ▼
┌─────────────────────────────────────────────────────────────┐
│            Microsoft Defender for Endpoint                   │
│                     Target Devices                           │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

#### Upload to Device
1. Admin uploads file to Azure Storage (Portal/CLI/PowerShell)
2. Workbook queries `ListLibraryFiles` → displays available files
3. User selects file and enters Device ID
4. Workbook calls `PutLiveResponseFileFromLibrary`
5. Function retrieves file from storage
6. Function uploads to MDE library
7. Function deploys to device via Live Response

#### Download from Device
1. User enters Device ID and file path
2. Workbook calls `GetLiveResponseFile`
3. Function starts Live Response session
4. Function executes `getfile` command
5. Function downloads file from MDE
6. Function returns file as Base64
7. Workbook decodes and provides download link

---

## Setup

See [LIBRARY_SETUP.md](LIBRARY_SETUP.md) for quick 5-minute setup guide.

### Prerequisites

- Azure Storage Account (automatically created with deployment)
- Azure Function App with MDE automator deployed
- Appropriate permissions:
  - Storage Blob Data Contributor (for library management)
  - Security Administrator (for MDE operations)

### Initial Configuration

The library container is automatically created when the Function App starts:

```powershell
# In functions/profile.ps1
if ($env:AzureWebJobsStorage) {
    $global:StorageContext = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    
    # Ensure library container exists
    $libraryContainer = Get-AzStorageContainer -Name "library" -Context $global:StorageContext -ErrorAction SilentlyContinue
    if (-not $libraryContainer) {
        New-AzStorageContainer -Name "library" -Context $global:StorageContext -Permission Off
    }
}
```

---

## User Workflows

### 1. Upload File to Library

#### Option A: Azure Portal (Easiest)
1. Open Azure Portal → Storage Account
2. Navigate to **Containers** → **library**
3. Click **Upload**
4. Select file(s) and upload

#### Option B: Azure CLI
```bash
# Single file
az storage blob upload \
  --account-name mdeautomator \
  --container-name library \
  --name script.ps1 \
  --file C:\scripts\script.ps1

# Multiple files
az storage blob upload-batch \
  --account-name mdeautomator \
  --destination library \
  --source C:\tools\
```

#### Option C: PowerShell Script
```powershell
# Single file
.\scripts\Upload-ToLibrary.ps1 `
  -FilePath "C:\tools\script.ps1" `
  -StorageAccountName "mdeautomator" `
  -ResourceGroup "rg-mde"

# Sync entire folder
.\scripts\Sync-LibraryFolder.ps1 `
  -FolderPath "C:\tools" `
  -StorageAccountName "mdeautomator" `
  -ResourceGroup "rg-mde"
```

#### Option D: Azure Storage Explorer
1. Download [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/)
2. Connect to your storage account
3. Navigate to **library** container
4. Drag and drop files

---

### 2. Deploy File to Device

#### Using Workbook (Recommended)
1. Open **FileOperations** workbook
2. Go to **📚 Library Management** tab
3. Files are listed automatically
4. Click on file to select it
5. Enter **Device ID**
6. Click **📤 Deploy to Device**
7. ✅ Done! File is deployed via Live Response

**Note**: This is a **4-click workflow** with no copy/paste required!

#### Using API Directly
```powershell
$body = @{
    fileName = "script.ps1"
    DeviceIds = "device-id-here"
    tenantId = "tenant-id"
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri "https://yourfunc.azurewebsites.net/api/PutLiveResponseFileFromLibrary?code=funckey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

---

### 3. Download File from Device

#### Using Workbook (Recommended)
1. Open **FileOperations** workbook
2. Go to **📥 Download Operations** tab
3. Enter **Device ID**
4. Enter **File Path** (e.g., `C:\Windows\Temp\suspicious.exe`)
5. Click **📥 Download File**
6. Wait for download to complete
7. Click **⬇️ Download** link in results
8. Browser downloads file automatically
9. ✅ Done!

**Note**: File is automatically Base64-decoded and ready for download!

#### Using API Directly
```powershell
$body = @{
    DeviceId = "device-id-here"
    FilePath = "C:\Windows\Temp\file.txt"
    tenantId = "tenant-id"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "https://yourfunc.azurewebsites.net/api/GetLiveResponseFile?code=funckey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

# Decode Base64 and save
[IO.File]::WriteAllBytes("downloaded.txt", [Convert]::FromBase64String($response.fileContent))
```

---

### 4. List Library Files

#### Using PowerShell Script
```powershell
.\scripts\Get-LibraryFiles.ps1 `
  -StorageAccountName "mdeautomator" `
  -ResourceGroup "rg-mde"
```

#### Using API
```powershell
Invoke-RestMethod `
  -Uri "https://yourfunc.azurewebsites.net/api/ListLibraryFiles?code=funckey" `
  -Method Get
```

---

### 5. Delete File from Library

#### Using PowerShell Script
```powershell
.\scripts\Remove-LibraryFile.ps1 `
  -FileName "old-script.ps1" `
  -StorageAccountName "mdeautomator" `
  -ResourceGroup "rg-mde"
```

#### Using API
```powershell
$body = @{
    fileName = "old-script.ps1"
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri "https://yourfunc.azurewebsites.net/api/DeleteLibraryFile?code=funckey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

---

## API Reference

### ListLibraryFiles

**Endpoint**: `GET/POST /api/ListLibraryFiles`  
**Auth**: Function-level key  

**Request**: No parameters required

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "fileName": "script.ps1",
      "size": 2048,
      "lastModified": "2025-01-06T14:30:00Z",
      "contentType": "application/octet-stream",
      "etag": "\"0x8DCAA1234567890\""
    }
  ],
  "count": 1,
  "timestamp": "2025-01-06T14:30:00Z",
  "error": null
}
```

---

### GetLibraryFile

**Endpoint**: `GET/POST /api/GetLibraryFile`  
**Auth**: Function-level key  

**Request**:
```json
{
  "fileName": "script.ps1"
}
```

**Response**:
```json
{
  "success": true,
  "fileName": "script.ps1",
  "fileContent": "base64-encoded-content-here",
  "size": 2048,
  "timestamp": "2025-01-06T14:30:00Z",
  "error": null
}
```

---

### PutLiveResponseFileFromLibrary

**Endpoint**: `GET/POST /api/PutLiveResponseFileFromLibrary`  
**Auth**: Function-level key  

**Request**:
```json
{
  "fileName": "script.ps1",
  "DeviceIds": "device-id-here",
  "tenantId": "tenant-id",
  "TargetFileName": "script.ps1"
}
```

**Response**:
```json
{
  "success": true,
  "status": "Success",
  "message": "File deployed successfully from library to device",
  "fileName": "script.ps1",
  "targetFileName": "script.ps1",
  "deviceId": "device-id",
  "sessionId": "session-id",
  "commandId": "command-id",
  "timestamp": "2025-01-06T14:30:00Z",
  "error": null
}
```

---

### GetLiveResponseFile

**Endpoint**: `GET/POST /api/GetLiveResponseFile`  
**Auth**: Function-level key  

**Request**:
```json
{
  "DeviceId": "device-id-here",
  "FilePath": "C:\\Windows\\Temp\\file.txt",
  "tenantId": "tenant-id"
}
```

**Response**:
```json
{
  "success": true,
  "status": "Success",
  "message": "File downloaded successfully from device",
  "fileName": "file.txt",
  "filePath": "C:\\Windows\\Temp\\file.txt",
  "fileContent": "base64-encoded-content-here",
  "size": 1024,
  "deviceId": "device-id",
  "sessionId": "session-id",
  "commandId": "command-id",
  "timestamp": "2025-01-06T14:30:00Z",
  "error": null
}
```

---

### DeleteLibraryFile

**Endpoint**: `GET/POST /api/DeleteLibraryFile`  
**Auth**: Function-level key  

**Request**:
```json
{
  "fileName": "old-script.ps1"
}
```

**Response**:
```json
{
  "success": true,
  "status": "Success",
  "message": "File deleted successfully from library",
  "fileName": "old-script.ps1",
  "timestamp": "2025-01-06T14:30:00Z",
  "error": null
}
```

---

## Troubleshooting

### Issue: Storage context not initialized

**Error**: `Storage context not initialized. Ensure AzureWebJobsStorage is configured.`

**Solution**: 
- Verify `AzureWebJobsStorage` app setting is configured
- Restart Function App to trigger profile.ps1 execution
- Check Application Insights logs for storage initialization messages

---

### Issue: File not found in library

**Error**: `File not found in library: script.ps1`

**Solution**:
- Verify file was uploaded successfully to "library" container
- Check file name matches exactly (case-sensitive)
- Use `ListLibraryFiles` API to confirm file exists

---

### Issue: Live Response session fails

**Error**: `Failed to start Live Response session`

**Solution**:
- Verify device is online and onboarded to MDE
- Check device has Live Response enabled in MDE settings
- Ensure correct Device ID is used
- Verify APPID/SECRETID have proper permissions

---

### Issue: File too large

**Error**: File upload times out or fails

**Solution**:
- MDE Live Response has file size limits (~50MB)
- For large files, consider splitting or compressing
- Increase function timeout in host.json if needed
- Use direct file transfer methods for very large files

---

### Issue: Permission denied

**Error**: `403 Forbidden` when accessing storage

**Solution**:
- Verify managed identity has "Storage Blob Data Contributor" role
- Check storage account firewall settings
- Ensure correct storage account connection string
- Verify function app has proper RBAC assignments

---

## Best Practices

### Security
- ✅ Keep library container private (Permission: Off)
- ✅ Use function-level authentication keys
- ✅ Rotate function keys periodically
- ✅ Enable blob versioning for audit trail
- ✅ Monitor access logs in Azure Monitor

### File Management
- ✅ Use descriptive file names
- ✅ Include version numbers in file names (e.g., tool-v1.2.exe)
- ✅ Document file purposes in a README blob
- ✅ Regularly clean up unused files
- ✅ Test files in non-production first

### Performance
- ✅ Keep files under 50MB for best performance
- ✅ Use compression for large files
- ✅ Monitor function execution times
- ✅ Use concurrent deployments sparingly

---

## Common File Paths

### Windows
- **Event Logs**: `C:\Windows\System32\winevt\Logs\Security.evtx`
- **Hosts File**: `C:\Windows\System32\drivers\etc\hosts`
- **Temp Directory**: `C:\Windows\Temp\`
- **User Profile**: `C:\Users\{username}\`
- **Program Files**: `C:\Program Files\`
- **Startup Folder**: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\`

### Common Investigation Targets
- Browser cache and history
- Recent downloads
- Scheduled tasks
- Registry exports
- Memory dumps
- Process artifacts

---

## Support

For issues or questions:
1. Check this guide first
2. Review Application Insights logs
3. Check Azure Function logs
4. Open GitHub issue with details

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0
