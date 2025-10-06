# File Library Setup Guide

Quick 5-minute setup guide for Azure Storage file library with MDE Live Response.

## 🚀 Quick Start

This guide assumes you already have the MDE Automator function app deployed. If not, see [QUICKSTART.md](QUICKSTART.md) first.

---

## Step 1: Verify Storage Account (30 seconds)

The storage account is automatically created during deployment. Verify it exists:

### Azure Portal
1. Open Azure Portal
2. Navigate to **Resource Groups** → your resource group
3. Look for storage account (name pattern: `stmdeautomator*`)
4. Click on the storage account

### Azure CLI
```bash
# List storage accounts in resource group
az storage account list --resource-group rg-mde --query "[].name" -o table
```

✅ **Expected Result**: You should see a storage account

---

## Step 2: Verify Library Container (30 seconds)

The "library" container is automatically created when the Function App starts.

### Azure Portal
1. In Storage Account → **Containers**
2. Look for **library** container
3. If it doesn't exist, restart the Function App to trigger creation

### Azure CLI
```bash
# List containers
az storage container list --account-name mdeautomator --query "[].name" -o table
```

✅ **Expected Result**: You should see the "library" container

---

## Step 3: Upload Your First File (2 minutes)

Choose your preferred method:

### Option A: Azure Portal (Easiest)
1. Storage Account → **Containers** → **library**
2. Click **Upload**
3. Select a test file (e.g., `test-script.ps1`)
4. Click **Upload**

✅ **Done!** File is now in the library

### Option B: Azure CLI
```bash
# Upload a file
az storage blob upload \
  --account-name mdeautomator \
  --container-name library \
  --name test-script.ps1 \
  --file C:\scripts\test-script.ps1
```

### Option C: PowerShell Script
```powershell
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar

# Upload a file
.\scripts\Upload-ToLibrary.ps1 `
  -FilePath "C:\scripts\test-script.ps1" `
  -StorageAccountName "mdeautomator" `
  -ResourceGroup "rg-mde"
```

---

## Step 4: Test Library API (1 minute)

Test that the function can access the library:

### Get Function URL
1. Azure Portal → Function App → **Functions** → **ListLibraryFiles**
2. Click **Get Function Url**
3. Copy the URL (includes function key)

### Test with PowerShell
```powershell
# Replace with your function URL
$url = "https://yourfunc.azurewebsites.net/api/ListLibraryFiles?code=funckey"

# Call API
$response = Invoke-RestMethod -Uri $url -Method Get

# View results
$response | ConvertTo-Json -Depth 5
```

✅ **Expected Result**: JSON response with your uploaded file listed

---

## Step 5: Test File Deployment (1 minute)

Test deploying a file to a device (optional, requires an active MDE device):

### Prerequisites
- Device ID of an online MDE device
- Tenant ID
- Device has Live Response enabled

### Test Deployment
```powershell
$url = "https://yourfunc.azurewebsites.net/api/PutLiveResponseFileFromLibrary?code=funckey"

$body = @{
    fileName = "test-script.ps1"
    DeviceIds = "your-device-id"
    tenantId = "your-tenant-id"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"

$response | ConvertTo-Json -Depth 5
```

✅ **Expected Result**: File deployed to device successfully

---

## 🎉 You're Done!

Your file library is now set up and ready to use!

### Next Steps

1. **Upload more files**: Add your common tools, scripts, and configs
2. **Import workbook**: Deploy FileOperations workbook for GUI access
3. **Share with team**: Grant team members appropriate storage permissions
4. **Read the guide**: See [FILE_OPERATIONS_GUIDE.md](FILE_OPERATIONS_GUIDE.md) for detailed workflows

---

## Common Setup Issues

### Issue: Library container doesn't exist

**Solution**: Restart the Function App to trigger profile.ps1 execution:
```bash
az functionapp restart --name yourfuncapp --resource-group rg-mde
```

### Issue: Can't upload files to storage

**Solution**: Check your permissions:
```bash
# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee your-user@domain.com \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-mde/providers/Microsoft.Storage/storageAccounts/mdeautomator
```

### Issue: Function can't access storage

**Solution**: Verify `AzureWebJobsStorage` app setting:
```bash
# Check app settings
az functionapp config appsettings list \
  --name yourfuncapp \
  --resource-group rg-mde \
  --query "[?name=='AzureWebJobsStorage']"
```

---

## Verification Checklist

- [ ] Storage account exists
- [ ] "library" container exists
- [ ] Test file uploaded successfully
- [ ] ListLibraryFiles API returns files
- [ ] (Optional) File deployed to test device
- [ ] Team members have appropriate permissions

---

## Security Configuration

### Container Access Level
The library container should have **Private** access (no public access):

```bash
# Verify private access
az storage container show \
  --name library \
  --account-name mdeautomator \
  --query "properties.publicAccess"
```

✅ **Expected Result**: `null` or empty (private)

### RBAC Permissions

**For Admins** (upload/delete files):
- Storage Blob Data Contributor

**For Users** (read-only via API):
- No direct storage access needed (uses function auth)

**For Function App** (automated):
- Uses managed identity or connection string

---

## Sample Files to Upload

Here are some useful files to add to your library:

### PowerShell Scripts
- `Collect-Logs.ps1` - Gather event logs
- `Get-NetworkConfig.ps1` - Network settings
- `Check-Persistence.ps1` - Startup items

### Tools
- `PsExec.exe` - Sysinternals tools
- `Autoruns.exe` - Startup analyzer
- `tcpdump.exe` - Packet capture

### Configuration Files
- `hosts.template` - Clean hosts file
- `firewall-rules.json` - Standard rules
- `defender-settings.json` - Baseline config

---

## Advanced Configuration

### Enable Blob Versioning (Recommended)
```bash
# Enable versioning for audit trail
az storage account blob-service-properties update \
  --account-name mdeautomator \
  --resource-group rg-mde \
  --enable-versioning true
```

### Enable Soft Delete
```bash
# Enable soft delete (7-day retention)
az storage account blob-service-properties update \
  --account-name mdeautomator \
  --resource-group rg-mde \
  --enable-delete-retention true \
  --delete-retention-days 7
```

### Enable Access Logs
```bash
# Enable storage analytics logging
az storage logging update \
  --account-name mdeautomator \
  --services b \
  --log rwd \
  --retention 90
```

---

## Automation Examples

### Bulk Upload
```powershell
# Upload all PowerShell scripts from a folder
Get-ChildItem "C:\SecurityScripts\*.ps1" | ForEach-Object {
    az storage blob upload `
      --account-name mdeautomator `
      --container-name library `
      --name $_.Name `
      --file $_.FullName
}
```

### Scheduled Sync
```powershell
# Windows Task Scheduler - sync daily at 2 AM
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-File C:\scripts\Sync-LibraryFolder.ps1 -FolderPath C:\SecurityTools -StorageAccountName mdeautomator -ResourceGroup rg-mde"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

Register-ScheduledTask -TaskName "SyncMDELibrary" -Action $action -Trigger $trigger
```

---

## Cost Estimation

Azure Storage costs are minimal:

- **Storage**: ~$0.02 per GB/month (Standard LRS)
- **Transactions**: ~$0.004 per 10,000 operations
- **Example**: 100 files (500 MB) with 1,000 deployments/month = **~$0.05/month**

Function execution costs also minimal (Consumption plan):
- First 1M executions free
- Then ~$0.20 per million executions

**Total estimated cost**: **< $1/month** for typical usage

---

## Support

If you encounter issues:
1. Check Application Insights logs
2. Review [FILE_OPERATIONS_GUIDE.md](FILE_OPERATIONS_GUIDE.md) troubleshooting section
3. Open GitHub issue with details

---

**Setup Time**: ~5 minutes  
**Difficulty**: Easy  
**Last Updated**: 2025-01-06
