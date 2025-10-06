# File Operations Testing Guide

This guide provides testing instructions for the new file library management features.

## 🧪 Testing Prerequisites

Before testing, ensure you have:

1. **Deployed Function App** with the new functions
2. **Azure Storage Account** with "library" container
3. **MDE Test Device** that is online and has Live Response enabled
4. **Appropriate Permissions**:
   - Storage Blob Data Contributor (for manual testing)
   - Security Administrator or similar (for MDE operations)
5. **Function App Configuration**:
   - `APPID` environment variable set
   - `SECRETID` environment variable set
   - `AzureWebJobsStorage` connection string configured

---

## 📋 Test Plan

### Phase 1: Configuration Testing

#### Test 1.1: Verify Az.Storage Module
```powershell
# In Function App Console (Kudu)
Get-Module -ListAvailable -Name Az.Storage
```

**Expected Result**: Az.Storage module version 5.x listed

#### Test 1.2: Verify Storage Context Initialization
```powershell
# Check Function App logs in Application Insights
traces
| where message contains "Initializing storage context for file library"
| order by timestamp desc
| take 10
```

**Expected Result**: Log messages showing successful initialization

#### Test 1.3: Verify Library Container Exists
```bash
# Azure CLI
az storage container show \
  --name library \
  --account-name <storage-account-name> \
  --query "{name:name, publicAccess:properties.publicAccess}"
```

**Expected Result**: Container exists with `publicAccess: null` (private)

---

### Phase 2: Function Testing

#### Test 2.1: ListLibraryFiles Function

**Setup**: Upload a test file to library container first
```bash
echo "Test content" > test-file.txt
az storage blob upload \
  --account-name <storage-account-name> \
  --container-name library \
  --name test-file.txt \
  --file test-file.txt
```

**Test**: Call the function
```powershell
$functionUrl = "https://<your-func-app>.azurewebsites.net/api/ListLibraryFiles"
$functionKey = "<your-function-key>"

$response = Invoke-RestMethod -Uri "$functionUrl`?code=$functionKey" -Method Get

$response | ConvertTo-Json -Depth 5
```

**Expected Result**:
```json
{
  "success": true,
  "data": [
    {
      "fileName": "test-file.txt",
      "size": 13,
      "lastModified": "2025-01-06T...",
      "contentType": "text/plain"
    }
  ],
  "count": 1,
  "timestamp": "2025-01-06T...",
  "error": null
}
```

**Validation Checklist**:
- [ ] Returns 200 OK status
- [ ] `success` is `true`
- [ ] `data` array contains uploaded file
- [ ] File metadata is accurate (name, size, timestamp)
- [ ] No error in response

---

#### Test 2.2: GetLibraryFile Function

**Test**: Retrieve the test file
```powershell
$functionUrl = "https://<your-func-app>.azurewebsites.net/api/GetLibraryFile"
$functionKey = "<your-function-key>"

$body = @{
    fileName = "test-file.txt"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$functionUrl`?code=$functionKey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

# Decode Base64 to verify content
$decodedContent = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($response.fileContent))
Write-Host "Decoded content: $decodedContent"
```

**Expected Result**:
- Returns 200 OK status
- `success` is `true`
- `fileContent` is Base64 encoded
- Decoded content matches original: "Test content"

**Validation Checklist**:
- [ ] Returns 200 OK status
- [ ] `fileContent` is valid Base64
- [ ] Decoded content matches original file
- [ ] File size is correct
- [ ] No error in response

---

#### Test 2.3: PutLiveResponseFileFromLibrary Function

**Prerequisites**:
- Online MDE device with Live Response enabled
- Device ID from MDE portal
- Tenant ID

**Test**: Deploy test file to device
```powershell
$functionUrl = "https://<your-func-app>.azurewebsites.net/api/PutLiveResponseFileFromLibrary"
$functionKey = "<your-function-key>"

$body = @{
    fileName = "test-file.txt"
    DeviceIds = "<your-device-id>"
    tenantId = "<your-tenant-id>"
    TargetFileName = "test-deployed.txt"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$functionUrl`?code=$functionKey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

$response | ConvertTo-Json -Depth 5
```

**Expected Result**:
```json
{
  "success": true,
  "status": "Success",
  "message": "File deployed successfully from library to device",
  "fileName": "test-file.txt",
  "targetFileName": "test-deployed.txt",
  "deviceId": "<device-id>",
  "sessionId": "<session-id>",
  "commandId": "<command-id>",
  "timestamp": "2025-01-06T...",
  "error": null
}
```

**Validation Checklist**:
- [ ] Returns 200 OK status
- [ ] `success` is `true`
- [ ] `sessionId` is returned
- [ ] `commandId` is returned
- [ ] No error in response
- [ ] File appears on device in expected location

**Verify on Device** (if accessible):
1. Connect to device via Live Response
2. Check if file exists: `dir C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Downloads\`
3. Verify file content matches original

---

#### Test 2.4: GetLiveResponseFile Function

**Prerequisites**:
- File exists on target device (use file from Test 2.3 or any existing file)
- Device is online

**Test**: Download file from device
```powershell
$functionUrl = "https://<your-func-app>.azurewebsites.net/api/GetLiveResponseFile"
$functionKey = "<your-function-key>"

$body = @{
    DeviceId = "<your-device-id>"
    FilePath = "C:\Windows\System32\drivers\etc\hosts"
    tenantId = "<your-tenant-id>"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$functionUrl`?code=$functionKey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

# Save decoded file
[IO.File]::WriteAllBytes("downloaded-hosts.txt", [Convert]::FromBase64String($response.fileContent))

Write-Host "File downloaded: $($response.fileName)"
Write-Host "Size: $($response.size) bytes"
```

**Expected Result**:
- Returns 200 OK status
- `success` is `true`
- `fileContent` contains Base64 encoded file
- File can be decoded and saved locally
- Content matches original file on device

**Validation Checklist**:
- [ ] Returns 200 OK status
- [ ] `fileContent` is valid Base64
- [ ] File size matches
- [ ] Decoded file is readable
- [ ] Content is accurate
- [ ] No error in response

---

#### Test 2.5: DeleteLibraryFile Function

**Test**: Delete test file from library
```powershell
$functionUrl = "https://<your-func-app>.azurewebsites.net/api/DeleteLibraryFile"
$functionKey = "<your-function-key>"

$body = @{
    fileName = "test-file.txt"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$functionUrl`?code=$functionKey" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

$response | ConvertTo-Json -Depth 5
```

**Expected Result**:
```json
{
  "success": true,
  "status": "Success",
  "message": "File deleted successfully from library",
  "fileName": "test-file.txt",
  "timestamp": "2025-01-06T...",
  "error": null
}
```

**Validation Checklist**:
- [ ] Returns 200 OK status
- [ ] `success` is `true`
- [ ] File no longer appears in ListLibraryFiles
- [ ] No error in response

**Verify Deletion**:
```powershell
# List files again - test-file.txt should be gone
Invoke-RestMethod -Uri "https://<your-func-app>.azurewebsites.net/api/ListLibraryFiles?code=<key>" -Method Get
```

---

### Phase 3: Helper Scripts Testing

#### Test 3.1: Upload-ToLibrary.ps1

**Test**: Upload a file using the helper script
```powershell
cd scripts

.\Upload-ToLibrary.ps1 `
  -FilePath "C:\temp\test-upload.txt" `
  -StorageAccountName "<storage-account-name>" `
  -ResourceGroup "<resource-group>"
```

**Expected Output**:
```
📦 Upload to Library - Starting...
🔐 Connecting to storage account: ...
📤 Uploading file: test-upload.txt (...)
✅ File uploaded successfully: test-upload.txt
   Container: library
   Blob Name: test-upload.txt
   Size: ... KB
```

**Validation Checklist**:
- [ ] Script completes without errors
- [ ] File appears in storage container
- [ ] Progress messages are displayed
- [ ] File size is accurate

---

#### Test 3.2: Sync-LibraryFolder.ps1

**Setup**: Create a test folder with multiple files
```powershell
mkdir C:\temp\test-sync
echo "File 1" > C:\temp\test-sync\file1.txt
echo "File 2" > C:\temp\test-sync\file2.txt
echo "File 3" > C:\temp\test-sync\file3.txt
```

**Test**: Sync the folder
```powershell
.\Sync-LibraryFolder.ps1 `
  -FolderPath "C:\temp\test-sync" `
  -StorageAccountName "<storage-account-name>" `
  -ResourceGroup "<resource-group>"
```

**Expected Output**:
```
📦 Sync Library Folder - Starting...
📂 Scanning local folder: C:\temp\test-sync
   Found 3 file(s) to sync
📋 Getting existing library files...
   Found X existing file(s) in library
📤 Uploading new file: file1.txt
   ✅ Uploaded: file1.txt (... KB)
📤 Uploading new file: file2.txt
   ✅ Uploaded: file2.txt (... KB)
📤 Uploading new file: file3.txt
   ✅ Uploaded: file3.txt (... KB)
✅ Sync complete!
   📤 Uploaded: 3
   ⏭️  Skipped: 0
```

**Validation Checklist**:
- [ ] All files uploaded successfully
- [ ] Statistics are accurate
- [ ] Files appear in storage container

---

#### Test 3.3: Get-LibraryFiles.ps1

**Test**: List files in library
```powershell
.\Get-LibraryFiles.ps1 `
  -StorageAccountName "<storage-account-name>" `
  -ResourceGroup "<resource-group>" `
  -Format Table
```

**Expected Output**: Table showing all files with columns:
- FileName
- SizeKB
- LastModified
- ContentType

**Validation Checklist**:
- [ ] All uploaded files are listed
- [ ] File metadata is accurate
- [ ] Table formatting is correct

---

#### Test 3.4: Remove-LibraryFile.ps1

**Test**: Delete a file
```powershell
.\Remove-LibraryFile.ps1 `
  -FileName "file1.txt" `
  -StorageAccountName "<storage-account-name>" `
  -ResourceGroup "<resource-group>" `
  -Force
```

**Expected Output**:
```
🗑️  Remove Library File - Starting...
🔐 Connecting to storage account: ...
🔍 Checking if file exists: file1.txt
   File: file1.txt
   Size: ... KB
   Last Modified: ...
🗑️  Deleting file: file1.txt
✅ File deleted successfully: file1.txt
```

**Validation Checklist**:
- [ ] File is deleted successfully
- [ ] File no longer appears in library
- [ ] Confirmation works (without -Force)

---

### Phase 4: Workbook Testing

#### Test 4.1: Deploy FileOperations Workbook

**Steps**:
1. Open Azure Portal
2. Navigate to **Azure Monitor** → **Workbooks**
3. Click **+ New**
4. Click **Advanced Editor** (</> icon)
5. Paste contents of `workbook/FileOperations.workbook`
6. Click **Apply**
7. Configure parameters:
   - Function App URL
   - Function Key
   - Tenant ID

**Validation Checklist**:
- [ ] Workbook loads without errors
- [ ] All three tabs are visible
- [ ] Parameters are configurable

---

#### Test 4.2: Library Management Tab

**Steps**:
1. Navigate to **📚 Library Management** tab
2. Click **🔄 Refresh Library Files**
3. View files in grid
4. Enter file name and device ID in parameters
5. Click **📤 Deploy to Device**

**Validation Checklist**:
- [ ] Files are listed in grid
- [ ] File metadata is displayed correctly
- [ ] Deploy button executes without errors
- [ ] Deployment status is shown

---

#### Test 4.3: Download Operations Tab

**Steps**:
1. Navigate to **📥 Download Operations** tab
2. Enter Device ID
3. Enter File Path (e.g., `C:\Windows\System32\drivers\etc\hosts`)
4. Click **📥 Download File from Device**
5. Wait for operation to complete
6. View results

**Validation Checklist**:
- [ ] Download operation executes
- [ ] File content is returned
- [ ] Instructions for decoding are clear

---

### Phase 5: End-to-End Testing

#### Test 5.1: Complete Upload-Deploy-Download Workflow

**Scenario**: Upload a script, deploy it to a device, execute it, and download the results.

**Steps**:

1. **Upload Script to Library**:
```powershell
# Create a test script
$scriptContent = @"
Get-Date > C:\Temp\test-output.txt
Write-Host "Script executed successfully"
"@

$scriptContent | Out-File -FilePath "C:\temp\test-script.ps1"

# Upload to library
.\scripts\Upload-ToLibrary.ps1 `
  -FilePath "C:\temp\test-script.ps1" `
  -StorageAccountName "<storage>" `
  -ResourceGroup "<rg>"
```

2. **Deploy Script to Device** (via workbook or API)
3. **Execute Script** (via Live Response or MDE portal)
4. **Download Output File** (via workbook or API)
5. **Verify Results**

**Validation Checklist**:
- [ ] Script uploads successfully
- [ ] Script deploys to device
- [ ] Script executes on device
- [ ] Output file downloads correctly
- [ ] Content matches expected output

---

## 🚨 Error Testing

Test error handling by intentionally causing failures:

### Test E.1: Non-Existent File
```powershell
# Try to get a file that doesn't exist
$body = @{ fileName = "does-not-exist.txt" } | ConvertTo-Json
Invoke-RestMethod -Uri "$url/GetLibraryFile?code=$key" -Method Post -Body $body -ContentType "application/json"
```

**Expected**: 404 Not Found with error message

### Test E.2: Invalid Device ID
```powershell
# Try to deploy to invalid device
$body = @{
    fileName = "test-file.txt"
    DeviceIds = "invalid-device-id"
    tenantId = "<tenant-id>"
} | ConvertTo-Json
Invoke-RestMethod -Uri "$url/PutLiveResponseFileFromLibrary?code=$key" -Method Post -Body $body -ContentType "application/json"
```

**Expected**: Error with meaningful message about invalid device

### Test E.3: Missing Parameters
```powershell
# Try to deploy without required parameters
$body = @{ fileName = "test-file.txt" } | ConvertTo-Json
Invoke-RestMethod -Uri "$url/PutLiveResponseFileFromLibrary?code=$key" -Method Post -Body $body -ContentType "application/json"
```

**Expected**: 400 Bad Request with missing parameter details

---

## 📊 Performance Testing

### Test P.1: Large File Upload (10MB+)
```powershell
# Create a 10MB test file
$bytes = New-Object byte[] 10485760
(New-Object Random).NextBytes($bytes)
[IO.File]::WriteAllBytes("C:\temp\large-file.bin", $bytes)

# Upload
.\scripts\Upload-ToLibrary.ps1 -FilePath "C:\temp\large-file.bin" ...
```

**Monitor**: Upload time, memory usage

### Test P.2: Concurrent Operations
```powershell
# Deploy to multiple devices simultaneously
1..5 | ForEach-Object -Parallel {
    # Deploy to device $_
}
```

**Monitor**: Function execution times, throttling

---

## 📝 Testing Checklist Summary

### Configuration
- [ ] Az.Storage module installed
- [ ] Storage context initialized
- [ ] Library container created

### Functions
- [ ] ListLibraryFiles works
- [ ] GetLibraryFile retrieves correct content
- [ ] PutLiveResponseFileFromLibrary deploys successfully
- [ ] GetLiveResponseFile downloads correctly
- [ ] DeleteLibraryFile removes files

### Helper Scripts
- [ ] Upload-ToLibrary.ps1 uploads files
- [ ] Sync-LibraryFolder.ps1 syncs folders
- [ ] Get-LibraryFiles.ps1 lists files
- [ ] Remove-LibraryFile.ps1 deletes files

### Workbook
- [ ] Workbook deploys successfully
- [ ] Library Management tab functional
- [ ] Upload Operations tab functional
- [ ] Download Operations tab functional

### Error Handling
- [ ] Non-existent files return 404
- [ ] Invalid parameters return 400
- [ ] Meaningful error messages provided

### End-to-End
- [ ] Complete upload→deploy→download workflow works
- [ ] Files can be retrieved and are accurate
- [ ] Team collaboration works (multiple users)

---

## 🐛 Reporting Issues

If you encounter issues during testing:

1. **Capture Details**:
   - Function/script name
   - Error message
   - Function App logs (Application Insights)
   - Request/response bodies

2. **Check Logs**:
```kql
traces
| where message contains "LibraryFile" or message contains "LiveResponse"
| order by timestamp desc
| take 50
```

3. **Open GitHub Issue** with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Logs and screenshots
   - Environment details

---

**Testing Document Version**: 1.0.0  
**Last Updated**: 2025-01-06
