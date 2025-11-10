# Migration Guide: DefenderC2Automator → DefenderXDRC2XSOAR

This guide helps existing users of DefenderC2Automator migrate to the new DefenderXDRC2XSOAR (v2.0.0) solution with full XDR capabilities.

## Overview of Changes

DefenderXDRC2XSOAR v2.0.0 represents a major expansion of the original DefenderC2Automator solution:

### What's Changed
- **Module Name**: DefenderC2Automator → DefenderXDRC2XSOAR
- **Version**: 1.0.0 → 2.0.0
- **Scope**: MDE-only → Full Microsoft Defender XDR Stack
- **Functions**: 6 → 7 Azure Functions
- **Actions**: 15 → 40+ security actions

### What's the Same
- **Existing Function Names**: All DefenderC2* functions remain unchanged
- **API Compatibility**: Existing API calls continue to work
- **Workbook**: Current workbook continues to function (new tabs can be added)
- **Deployment Method**: Same ARM template deployment process

## Breaking Changes

### ⚠️ Module Import Statement
If you have custom scripts that import the module directly, update:

**Old:**
```powershell
Import-Module DefenderC2Automator
```

**New:**
```powershell
Import-Module DefenderXDRC2XSOAR
```

### ⚠️ Module Path References
If you reference the module path directly:

**Old:**
```powershell
$modulePath = "C:\path\to\DefenderC2Automator"
```

**New:**
```powershell
$modulePath = "C:\path\to\DefenderXDRC2XSOAR"
```

### ⚠️ Manifest File Name
If you import via manifest file:

**Old:**
```powershell
Import-Module .\DefenderC2Automator.psd1
```

**New:**
```powershell
Import-Module .\DefenderXDRC2XSOAR.psd1
```

## Non-Breaking Changes

### ✅ Function Names Unchanged
All existing functions continue to work:
```powershell
# These all still work exactly as before
Invoke-DeviceIsolation
Invoke-DeviceUnisolation
Get-AllDevices
Add-FileIndicator
Invoke-AdvancedHunting
# ... etc
```

### ✅ Azure Functions Unchanged
Existing Azure Functions remain:
- `DefenderC2Dispatcher`
- `DefenderC2TIManager`
- `DefenderC2HuntManager`
- `DefenderC2IncidentManager`
- `DefenderC2CDManager`
- `DefenderC2Orchestrator`

### ✅ Workbook Compatibility
Your existing workbook queries continue to work without modification.

## Migration Steps

### Option 1: Fresh Deployment (Recommended)

1. **Deploy New Version**
   ```bash
   # Click the "Deploy to Azure" button in README.md
   # Or use Azure CLI:
   az deployment group create \
     --resource-group YourRG \
     --template-file deployment/azuredeploy.json
   ```

2. **Update App Registration Permissions**
   - Add new Graph API permissions (see [PERMISSIONS.md](PERMISSIONS.md))
   - Grant admin consent for new permissions
   - Keep existing MDE permissions

3. **Test New Capabilities**
   - Verify existing MDE actions work
   - Test new XDR actions (optional)

4. **Update Documentation**
   - Update internal documentation with new module name
   - Document new XDR capabilities for your team

### Option 2: In-Place Update

1. **Backup Current Deployment**
   ```powershell
   # Export current function app settings
   az functionapp config appsettings list \
     --name YourFunctionApp \
     --resource-group YourRG \
     --output json > backup-settings.json
   ```

2. **Stop Function App**
   ```powershell
   az functionapp stop \
     --name YourFunctionApp \
     --resource-group YourRG
   ```

3. **Deploy New Package**
   ```powershell
   # Download new function-package.zip from GitHub
   # Deploy to function app
   az functionapp deployment source config-zip \
     --name YourFunctionApp \
     --resource-group YourRG \
     --src deployment/function-package.zip
   ```

4. **Start Function App**
   ```powershell
   az functionapp start \
     --name YourFunctionApp \
     --resource-group YourRG
   ```

5. **Update App Registration Permissions**
   - Add new Graph API permissions
   - Grant admin consent

## New Permissions Required

If you want to use the new XDR capabilities, add these permissions to your App Registration:

### Microsoft Graph API (Application Permissions)
```
SecurityAnalyzedMessage.ReadWrite.All
ThreatSubmission.ReadWrite.All
User.ReadWrite.All
Directory.ReadWrite.All
IdentityRiskyUser.ReadWrite.All
Policy.ReadWrite.ConditionalAccess
DeviceManagementManagedDevices.ReadWrite.All
MailboxSettings.ReadWrite
```

### Azure RBAC Roles (for Azure infrastructure actions)
```
Network Contributor
Virtual Machine Contributor
Storage Account Contributor
Security Admin
```

**📖 See [PERMISSIONS.md](PERMISSIONS.md) for complete details**

## Testing the Migration

### 1. Test Existing MDE Actions
```powershell
# Test device isolation (existing function)
$token = Connect-MDE -TenantId "your-tenant-id" -AppId "your-app-id" -ClientSecret "your-secret"
$devices = Get-AllDevices -Token $token
Write-Host "Retrieved $($devices.Count) devices"
```

### 2. Test New XDR Actions (Optional)
```powershell
# Test email remediation (new function)
$graphToken = Get-GraphToken -TenantId "your-tenant-id" -AppId "your-app-id" -ClientSecret "your-secret"
$result = Invoke-EmailRemediation -Token $graphToken -Action "softDelete" -NetworkMessageId "msg-id" -RecipientEmailAddress "user@domain.com"
Write-Host "Email remediation: $($result.status)"
```

### 3. Test Azure Functions
```bash
# Test existing dispatcher
curl -X POST "https://your-app.azurewebsites.net/api/DefenderC2Dispatcher" \
  -H "Content-Type: application/json" \
  -d '{"action":"Get Devices","tenantId":"your-tenant-id"}'

# Test new XDR manager
curl -X POST "https://your-app.azurewebsites.net/api/DefenderXDRManager" \
  -H "Content-Type: application/json" \
  -d '{"action":"Disable User","service":"EntraID","tenantId":"your-tenant-id","userId":"user@domain.com"}'
```

## Rollback Plan

If you encounter issues, you can rollback:

### 1. Restore Previous Package
```powershell
# Deploy previous version's function-package.zip
az functionapp deployment source config-zip \
  --name YourFunctionApp \
  --resource-group YourRG \
  --src backup/function-package-v1.zip
```

### 2. Restore App Settings
```powershell
# Restore from backup
az functionapp config appsettings set \
  --name YourFunctionApp \
  --resource-group YourRG \
  --settings @backup-settings.json
```

### 3. Restart Function App
```powershell
az functionapp restart \
  --name YourFunctionApp \
  --resource-group YourRG
```

## New Features Available After Migration

### 1. Email Remediation (MDO)
```powershell
# Soft delete phishing emails
Invoke-EmailRemediation -Token $graphToken -Action "softDelete" -NetworkMessageId $msgId -RecipientEmailAddress $email

# Block malicious URLs
Submit-URLThreat -Token $graphToken -Category "phishing" -Url $maliciousUrl
```

### 2. Identity Protection (Entra ID)
```powershell
# Disable compromised user
Set-UserAccountStatus -Token $graphToken -UserId "user@domain.com" -Enabled $false

# Reset password and revoke sessions
Reset-UserPassword -Token $graphToken -UserId "user@domain.com" -NewPassword $newPass
Revoke-UserSessions -Token $graphToken -UserId "user@domain.com"
```

### 3. Conditional Access
```powershell
# Block malicious IPs
New-NamedLocation -Token $graphToken -DisplayName "Blocked IPs" -IpRanges @("192.0.2.0/24") -IsTrusted $false

# Create risk-based policies
New-SignInRiskPolicy -Token $graphToken -DisplayName "Block High Risk Sign-ins" -RiskLevels @("high")
```

### 4. Intune Device Management
```powershell
# Remote lock device
Invoke-IntuneDeviceRemoteLock -Token $graphToken -DeviceId "device-id"

# Wipe compromised device
Invoke-IntuneDeviceWipe -Token $graphToken -DeviceId "device-id"
```

### 5. Azure Infrastructure Security
```powershell
# Block malicious IP at NSG level
$azureToken = Get-AzureAccessToken -TenantId $tenantId -AppId $appId -ClientSecret $secret
Add-NSGDenyRule -Token $azureToken -SubscriptionId $subId -ResourceGroupName "RG" -NSGName "NSG" -RuleName "Block-Attack" -SourceAddressPrefix "192.0.2.50" -DestinationPortRange "*" -Priority 100

# Stop compromised VM
Stop-AzureVM -Token $azureToken -SubscriptionId $subId -ResourceGroupName "RG" -VMName "VM"
```

## FAQ

### Q: Do I need to update my existing workbook?
**A:** No, your existing workbook continues to work. You can add new tabs for XDR features later.

### Q: Will this break my existing automations?
**A:** No, all existing function names and APIs remain unchanged.

### Q: Do I need all the new permissions?
**A:** No, you only need permissions for the services you want to use. MDE actions work with existing permissions.

### Q: Can I use both versions side-by-side?
**A:** Not recommended. Choose one deployment per environment.

### Q: How do I know if migration was successful?
**A:** Test existing MDE actions. If they work, migration succeeded. New XDR actions are optional.

### Q: What if I only want MDE functionality?
**A:** That's fine! Just don't add the new Graph API permissions. The module is fully backward compatible.

### Q: How long does migration take?
**A:** Fresh deployment: ~15 minutes. In-place update: ~5 minutes.

## Support

### Getting Help
- 📖 Review [PERMISSIONS.md](PERMISSIONS.md) for permission issues
- 📖 Review [DEPLOYMENT.md](DEPLOYMENT.md) for deployment issues
- 🐛 Open GitHub issue for bugs
- 💬 Use GitHub discussions for questions

### Common Issues

#### Issue: "Module DefenderXDRC2XSOAR not found"
**Solution:** Clear PowerShell module cache and restart function app

#### Issue: "Insufficient privileges"
**Solution:** Grant admin consent for new Graph API permissions

#### Issue: "Function not found: DefenderXDRManager"
**Solution:** Verify function-package.zip was deployed correctly

## Summary Checklist

Before going live with the migration:

- [ ] Backup current deployment
- [ ] Test migration in dev/test environment first
- [ ] Update App Registration permissions
- [ ] Grant admin consent for new permissions
- [ ] Deploy new function package
- [ ] Test existing MDE actions
- [ ] Test new XDR actions (optional)
- [ ] Update internal documentation
- [ ] Train team on new capabilities
- [ ] Monitor logs for errors

---

**Version:** 2.0.0  
**Last Updated:** 2025-01-10  
**Migration Complexity:** Low (backward compatible)  
**Estimated Time:** 15-30 minutes
