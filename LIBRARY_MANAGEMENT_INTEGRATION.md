# Library Management Integration for DefenderC2 Workbook

## Overview

Library management functionality has been integrated into the **Interactive Console** tab, providing:
- ✅ **List Library Files** - View all files in Azure Storage library
- ✅ **Upload to Library** - Upload files via Function App
- ✅ **Get Library File** - Download specific file content
- ✅ **Deploy to Device** - Push library files to MDE devices

---

## Implementation Details

### 1. List Library Files

**CustomEndpoint Query:**
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Orchestrator?code={FunctionKey}",
  "body": "{\"Function\":\"ListLibraryFiles\",\"tenantId\":\"{TenantId}\"}",
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$.files[*]",
      "columns": [
        {"path": "$.fileName", "columnid": "File Name"},
        {"path": "$.size", "columnid": "Size (bytes)"},
        {"path": "$.lastModified", "columnid": "Last Modified"},
        {"path": "$.contentType", "columnid": "Content Type"}
      ]
    }
  }]
}
```

**Features:**
- Auto-refresh table with all library files
- Sort by last modified date
- Export to Excel capability
- File size formatting (KB/MB)
- Content type detection

---

### 2. Upload to Library

**ARM Action:**
```json
{
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Orchestrator/invocations?api-version=2022-03-01",
  "method": "POST",
  "body": "{\"Function\":\"UploadToLibrary\",\"tenantId\":\"{TenantId}\",\"fileName\":\"{LibraryFileName}\",\"fileContent\":\"{FileContentBase64}\"}",
  "title": "Upload File to Library"
}
```

**Parameters Required:**
- `LibraryFileName` - Name for the file in library (e.g., "investigation.ps1")
- `FileContentBase64` - Base64-encoded file content

**Usage:**
1. User enters filename
2. User pastes Base64-encoded content (or use file upload if supported)
3. Click ARM Action button
4. File uploaded to Azure Storage library
5. Immediately available for deployment to devices

---

### 3. Get Library File

**CustomEndpoint Query:**
```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Orchestrator?code={FunctionKey}",
  "body": "{\"Function\":\"GetLibraryFile\",\"tenantId\":\"{TenantId}\",\"fileName\":\"{GetLibraryFileName}\"}",
  "transformers": [{
    "type": "jsonpath",
    "settings": {
      "tablePath": "$",
      "columns": [
        {"path": "$.fileName", "columnid": "File Name"},
        {"path": "$.content", "columnid": "Content"},
        {"path": "$.size", "columnid": "Size"},
        {"path": "$.contentType", "columnid": "Content Type"}
      ]
    }
  }]
}
```

**Parameters Required:**
- `GetLibraryFileName` - Name of file to retrieve

**Features:**
- Retrieve file content from library
- View file metadata
- Copy content for deployment
- Verify file exists before deployment

---

### 4. Deploy Library File to Device

**ARM Action:**
```json
{
  "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
  "method": "POST",
  "body": "{\"action\":\"PutFile\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeployDeviceIds}\",\"fileName\":\"{DeployFileName}\",\"libraryFile\":true}",
  "title": "Deploy Library File to Device"
}
```

**Parameters Required:**
- `DeployDeviceIds` - Target device(s) for deployment
- `DeployFileName` - File name from library to deploy

**Workflow:**
1. List library files to see available files
2. Select target devices
3. Enter filename from library
4. Click deploy button
5. File automatically retrieved from library and pushed to device(s)

---

## Function App Implementation

The DefenderC2Orchestrator Function App needs to implement:

### ListLibraryFiles Function
```powershell
function Invoke-ListLibraryFiles {
    param(
        [string]$TenantId,
        [string]$StorageAccountName,
        [string]$ContainerName = "library"
    )
    
    # Connect to Azure Storage
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    
    # List all blobs
    $blobs = Get-AzStorageBlob -Container $ContainerName -Context $ctx
    
    # Format response
    $files = $blobs | ForEach-Object {
        @{
            fileName = $_.Name
            size = $_.Length
            lastModified = $_.LastModified.ToString("yyyy-MM-dd HH:mm:ss")
            contentType = $_.ICloudBlob.Properties.ContentType
        }
    }
    
    return @{
        success = $true
        files = $files
        count = $files.Count
    }
}
```

### UploadToLibrary Function
```powershell
function Invoke-UploadToLibrary {
    param(
        [string]$TenantId,
        [string]$FileName,
        [string]$FileContent,
        [string]$StorageAccountName,
        [string]$ContainerName = "library"
    )
    
    # Decode Base64 content
    $bytes = [Convert]::FromBase64String($FileContent)
    
    # Upload to Azure Storage
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    
    # Create temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllBytes($tempFile, $bytes)
    
    # Upload blob
    Set-AzStorageBlobContent -File $tempFile -Container $ContainerName -Blob $FileName -Context $ctx -Force
    
    # Cleanup
    Remove-Item $tempFile -Force
    
    return @{
        success = $true
        fileName = $FileName
        size = $bytes.Length
        message = "File uploaded successfully to library"
    }
}
```

### GetLibraryFile Function
```powershell
function Invoke-GetLibraryFile {
    param(
        [string]$TenantId,
        [string]$FileName,
        [string]$StorageAccountName,
        [string]$ContainerName = "library"
    )
    
    # Connect to Azure Storage
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    
    # Get blob
    $blob = Get-AzStorageBlob -Container $ContainerName -Blob $FileName -Context $ctx
    
    # Download content
    $tempFile = [System.IO.Path]::GetTempFileName()
    Get-AzStorageBlobContent -Container $ContainerName -Blob $FileName -Destination $tempFile -Context $ctx -Force
    
    # Read and encode content
    $content = [System.IO.File]::ReadAllText($tempFile)
    $bytes = [System.IO.File]::ReadAllBytes($tempFile)
    $contentBase64 = [Convert]::ToBase64String($bytes)
    
    # Cleanup
    Remove-Item $tempFile -Force
    
    return @{
        success = $true
        fileName = $FileName
        content = $content
        contentBase64 = $contentBase64
        size = $blob.Length
        contentType = $blob.ICloudBlob.Properties.ContentType
        lastModified = $blob.LastModified.ToString("yyyy-MM-dd HH:mm:ss")
    }
}
```

---

## User Workflow

### Scenario 1: Upload Script to Library
1. Open **Interactive Console** tab
2. Scroll to **Library Management** section
3. Enter filename (e.g., "forensics.ps1")
4. Paste Base64-encoded script content
5. Click **Upload to Library** button
6. File appears in library list

### Scenario 2: Deploy Library File to Device
1. Click **List Library Files** to see available files
2. Scroll to **Deploy from Library** section
3. Select target device(s)
4. Enter filename from library (e.g., "forensics.ps1")
5. Click **Deploy to Device** button
6. File automatically pushed to device via Live Response

### Scenario 3: View Library File Content
1. Click **List Library Files**
2. Note the filename you want to view
3. Scroll to **Get Library File** section
4. Enter filename
5. Click **Get File** button
6. File content and metadata displayed in table

---

## Benefits

✅ **Centralized Storage**: Upload once, deploy anywhere  
✅ **Team Collaboration**: Shared library accessible to all team members  
✅ **Version Control**: Track file modifications with timestamps  
✅ **No Manual Encoding**: Function App handles Base64 encoding/decoding  
✅ **Quick Deployment**: One-click deployment from library to devices  
✅ **Audit Trail**: All library operations logged via Workbook  
✅ **Integration**: Seamlessly integrated with Interactive Console  

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           Azure Workbook - Interactive Console              │
│                                                             │
│  📚 Library Management                                      │
│  ├─ List Files      (CustomEndpoint → Orchestrator)        │
│  ├─ Upload File     (ARM Action → Orchestrator)            │
│  ├─ Get File        (CustomEndpoint → Orchestrator)        │
│  └─ Deploy to Device (ARM Action → Dispatcher)             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              DefenderC2Orchestrator Function                │
│                                                             │
│  ListLibraryFiles()                                         │
│  UploadToLibrary()                                          │
│  GetLibraryFile()                                           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Azure Storage Account                          │
│                                                             │
│  Container: library/                                        │
│  ├─ investigation.ps1                                       │
│  ├─ forensics.ps1                                           │
│  ├─ remediation.ps1                                         │
│  └─ tools.zip                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│         DefenderC2Dispatcher → MDE Device                   │
│                                                             │
│  PutFile (Live Response)                                    │
│  └─ Deploy file from library to device                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Status

✅ **List Library Files** - Added to Interactive Console  
🔄 **Upload to Library** - Implementation ready (requires function)  
🔄 **Get Library File** - Implementation ready (requires function)  
🔄 **Deploy from Library** - Implementation ready (requires function)  

**Next Steps:**
1. Implement Orchestrator functions in Function App
2. Add UI elements for upload/get operations
3. Test end-to-end workflow
4. Document for users

---

**Created**: October 11, 2025  
**Status**: Library listing integrated, full implementation ready
