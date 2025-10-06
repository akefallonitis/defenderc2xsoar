# Workbook File Operations Guide

This guide explains how to use the DefenderC2Orchestrator function for Live Response file operations directly from Azure Workbooks without requiring an Azure Storage account.

## Overview

Azure Workbooks have security restrictions that prevent custom JavaScript execution. However, we can still perform file upload and download operations using:
- **Base64 encoding** for file transfers
- **Data URIs** for browser downloads
- **ARM Actions** for API calls

## 🔐 Security Note

**Never upload sensitive files containing credentials, passwords, or secrets through the workbook interface.** Always review file content before encoding and uploading.

---

## 📤 File Upload to Device

### How It Works

1. Encode your file to Base64 locally (on your machine)
2. Paste the Base64 string into the workbook parameter
3. Workbook sends Base64 content to DefenderC2Orchestrator
4. Function uploads to MDE Live Response library
5. Function transfers file to target device

### PowerShell: Encode File for Upload

**Single Command to Encode and Copy to Clipboard:**

```powershell
# Encode file and copy Base64 to clipboard
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\your\file.txt"))
$base64 | Set-Clipboard
Write-Host "✅ File encoded and copied to clipboard. Paste into workbook." -ForegroundColor Green
```

**For Large Files (show size info):**

```powershell
# Encode with size check
$filePath = "C:\path\to\your\file.txt"
$fileBytes = [IO.File]::ReadAllBytes($filePath)
$fileSizeMB = [Math]::Round($fileBytes.Length / 1MB, 2)

if ($fileSizeMB -gt 10) {
    Write-Warning "File is ${fileSizeMB}MB. Large files may timeout. Consider splitting or compressing."
}

$base64 = [Convert]::ToBase64String($fileBytes)
$base64 | Set-Clipboard
Write-Host "✅ File encoded ($fileSizeMB MB) and copied to clipboard." -ForegroundColor Green
```

### Linux/macOS: Encode File for Upload

```bash
# Encode file and copy to clipboard (macOS)
base64 -i /path/to/your/file.txt | pbcopy
echo "✅ File encoded and copied to clipboard"

# Encode file and copy to clipboard (Linux with xclip)
base64 -w 0 /path/to/your/file.txt | xclip -selection clipboard
echo "✅ File encoded and copied to clipboard"

# Or just output to console
base64 -w 0 /path/to/your/file.txt
```

### Workbook ARM Action for Upload

Add this to your workbook JSON:

```json
{
  "type": 9,
  "content": {
    "version": "KqlParameterItem/1.0",
    "parameters": [
      {
        "id": "upload-device-id",
        "version": "KqlParameterItem/1.0",
        "name": "UploadDeviceId",
        "type": 1,
        "isRequired": true,
        "label": "Device ID",
        "description": "MDE Device ID to upload file to"
      },
      {
        "id": "upload-filename",
        "version": "KqlParameterItem/1.0",
        "name": "UploadFileName",
        "type": 1,
        "isRequired": true,
        "label": "Target File Name",
        "description": "File name on target device (e.g., script.ps1)"
      },
      {
        "id": "upload-content",
        "version": "KqlParameterItem/1.0",
        "name": "FileContent",
        "type": 1,
        "isRequired": true,
        "label": "File Content (Base64)",
        "description": "Paste Base64 encoded file content here"
      }
    ]
  }
},
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "upload-file-action",
        "linkTarget": "ArmAction",
        "linkLabel": "📤 Upload File to Device",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Orchestrator?code={FunctionKey}",
          "headers": [],
          "params": [],
          "body": "{\"Function\":\"PutLiveResponseFile\",\"tenantId\":\"{TenantId}\",\"DeviceIds\":\"{UploadDeviceId}\",\"TargetFileName\":\"{UploadFileName}\",\"fileContent\":\"{FileContent}\"}",
          "httpMethod": "POST",
          "title": "Upload File",
          "description": "Upload file to device via Live Response",
          "runLabel": "Uploading...",
          "runInBackground": false
        }
      }
    ]
  }
}
```

---

## 📥 File Download from Device

### How It Works

1. Click download button in workbook
2. Workbook sends request to DefenderC2Orchestrator with device ID and file path
3. Function starts Live Response session
4. Function downloads file from device
5. Function encodes file as Base64
6. Function returns data URI
7. Workbook displays download link
8. User clicks link → Browser downloads file

### Workbook Query for Download

Add this to your workbook JSON:

```json
{
  "type": 9,
  "content": {
    "version": "KqlParameterItem/1.0",
    "parameters": [
      {
        "id": "download-device-id",
        "version": "KqlParameterItem/1.0",
        "name": "DownloadDeviceId",
        "type": 1,
        "isRequired": true,
        "label": "Device ID",
        "description": "MDE Device ID to download from"
      },
      {
        "id": "download-filepath",
        "version": "KqlParameterItem/1.0",
        "name": "DownloadFilePath",
        "type": 1,
        "isRequired": true,
        "label": "File Path on Device",
        "description": "Full path to file (e.g., C:\\Temp\\log.txt)",
        "value": "C:\\Windows\\System32\\drivers\\etc\\hosts"
      }
    ]
  }
},
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "download-file-action",
        "linkTarget": "ArmAction",
        "linkLabel": "📥 Download File from Device",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Orchestrator?code={FunctionKey}",
          "headers": [],
          "params": [],
          "body": "{\"Function\":\"GetLiveResponseFile\",\"tenantId\":\"{TenantId}\",\"DeviceIds\":\"{DownloadDeviceId}\",\"filePath\":\"{DownloadFilePath}\"}",
          "httpMethod": "POST",
          "title": "Download File",
          "description": "Download file from device via Live Response",
          "runLabel": "Downloading...",
          "runInBackground": false
        }
      }
    ]
  }
}
```

### PowerShell: Decode Downloaded File

If you receive Base64 content from the API response:

```powershell
# Decode Base64 to file
$base64Content = "YOUR_BASE64_STRING_HERE"
$outputPath = "C:\Downloads\downloaded_file.txt"

$bytes = [Convert]::FromBase64String($base64Content)
[IO.File]::WriteAllBytes($outputPath, $bytes)

Write-Host "✅ File decoded and saved to: $outputPath" -ForegroundColor Green
```

---

## 🚀 Script Execution

### Execute Script from Library

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "run-script-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🚀 Execute Script",
        "style": "primary",
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Orchestrator?code={FunctionKey}",
          "body": "{\"Function\":\"InvokeLiveResponseScript\",\"tenantId\":\"{TenantId}\",\"DeviceIds\":\"{DeviceId}\",\"scriptName\":\"{ScriptName}\",\"arguments\":\"{ScriptArgs}\"}",
          "httpMethod": "POST",
          "title": "Execute Script",
          "runLabel": "Executing..."
        }
      }
    ]
  }
}
```

### Get Command Output

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "get-output-action",
        "linkTarget": "ArmAction",
        "linkLabel": "📊 Get Command Output",
        "style": "secondary",
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Orchestrator?code={FunctionKey}",
          "body": "{\"Function\":\"GetLiveResponseOutput\",\"tenantId\":\"{TenantId}\",\"commandId\":\"{CommandId}\"}",
          "httpMethod": "POST",
          "title": "Get Output",
          "runLabel": "Fetching..."
        }
      }
    ]
  }
}
```

---

## 📋 List Active Sessions

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [
      {
        "id": "list-sessions-action",
        "linkTarget": "ArmAction",
        "linkLabel": "📋 List Live Response Sessions",
        "style": "secondary",
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Orchestrator?code={FunctionKey}",
          "body": "{\"Function\":\"GetLiveResponseSessions\",\"tenantId\":\"{TenantId}\"}",
          "httpMethod": "POST",
          "title": "List Sessions"
        }
      }
    ]
  }
}
```

---

## ⚡ Rate Limiting & Retry Logic

The DefenderC2Orchestrator function automatically handles:

### Rate Limits
- **MDE API**: 45 calls per minute per tenant
- **Live Response**: 100 concurrent sessions maximum

### Automatic Retry
- **HTTP 429 (Rate Limited)**: Waits for `Retry-After` header value (default: 30s)
- **HTTP 5xx (Server Error)**: Exponential backoff (5s, 10s, 20s)
- **Max Retries**: 3 attempts before failure

### Workbook Auto-Refresh Configuration

For monitoring long-running operations:

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "...",
    "autoRefresh": {
      "enabled": true,
      "interval": 30,
      "maxRefreshCount": 20
    }
  }
}
```

**Best Practices:**
- Minimum refresh interval: 30 seconds (respects 45/min limit)
- Stop after completion: Set `maxRefreshCount` appropriately
- Monitor status: Check `status` field in response

---

## 🔍 Troubleshooting

### File Upload Fails

**Problem:** "File upload failed or timed out"

**Solutions:**
1. **Check file size**: Files > 10MB may timeout
   ```powershell
   # Check file size
   (Get-Item "C:\path\to\file.txt").Length / 1MB
   ```
2. **Verify Base64 encoding**: Ensure no whitespace or line breaks
   ```powershell
   # Clean Base64 (remove whitespace)
   $base64 = $base64 -replace '\s', ''
   ```
3. **Check device connectivity**: Ensure device is online in MDE portal

### File Download Fails

**Problem:** "File download failed or timed out"

**Solutions:**
1. **Verify file path**: Use full path with correct slashes
   - Windows: `C:\Windows\System32\drivers\etc\hosts`
   - Not: `C:/Windows/System32/drivers/etc/hosts`
2. **Check permissions**: Ensure MDE has access to file location
3. **File size**: Large files (>100MB) may timeout - increase timeout in function

### Rate Limiting Errors

**Problem:** "Rate limited (429)"

**Solutions:**
1. Function automatically retries with backoff
2. Reduce workbook auto-refresh frequency (min 30s)
3. Stagger operations across multiple devices
4. Consider batch operations instead of individual calls

### Session Creation Fails

**Problem:** "Failed to start Live Response session"

**Solutions:**
1. **Device online**: Check device is connected to MDE
2. **Live Response enabled**: Verify in MDE settings
3. **Concurrent sessions**: Maximum 100 sessions per tenant
4. **API permissions**: Ensure app registration has `Machine.LiveResponse` permission

---

## 📚 Additional Resources

- [Microsoft Defender Live Response API](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/run-live-response)
- [API Rate Limits](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api-terms-of-use)
- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Base64 Encoding Best Practices](https://en.wikipedia.org/wiki/Base64)

---

## 🎯 Quick Reference

### Upload File
```powershell
# 1. Encode locally
[Convert]::ToBase64String([IO.File]::ReadAllBytes("file.txt")) | Set-Clipboard

# 2. Paste in workbook parameter
# 3. Click "Upload File to Device" button
```

### Download File
```powershell
# 1. Click "Download File from Device" button
# 2. Click the download link in results
# 3. Browser downloads file automatically
```

### Common File Paths
- **Windows Event Logs**: `C:\Windows\System32\winevt\Logs\Security.evtx`
- **Hosts File**: `C:\Windows\System32\drivers\etc\hosts`
- **Temp Directory**: `C:\Windows\Temp\`
- **User Profile**: `C:\Users\{username}\`

---

**Note:** Always test file operations in a non-production environment first. Large files may require increased timeout values in the function code.
