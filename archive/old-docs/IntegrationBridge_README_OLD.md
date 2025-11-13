# DefenderXDR Integration Bridge

**Shared Utility Modules for Microsoft Security Orchestration**

Version: 2.4.0 | Refactored Architecture | Azure Functions



---

## Architecture Overview

This module provides **shared utility infrastructure** for the DefenderXDR C2 XSOAR platform. Business logic is embedded directly in worker functions, making this a lightweight utility bridge.

### Design Philosophy (v2.4.0 Refactoring)

**Before:** 21 modules (3 utilities + 2 duplicates + 16 service-specific)
- Service modules imported but unused (workers had inline logic)
- Duplicate authentication code (MDEAuth vs AuthManager)
- Slower cold starts (unnecessary imports)

**After:** 7 modules (6 utilities + 1 service)
- **71% reduction** in module count
- Workers remain self-contained
- Orchestrator only imports utilities
- Faster cold starts & cleaner architecture

---

## Module Structure

```
DefenderXDRIntegrationBridge/
├── DefenderXDRC2XSOAR.psd1        # Module manifest
│
├── === SHARED UTILITIES (6) ===
├── AuthManager.psm1               # Multi-service OAuth with token caching
├── ValidationHelper.psm1          # Input validation, sanitization, rate limiting
├── LoggingHelper.psm1             # Structured logging, metrics, Application Insights
├── BlobManager.psm1               # Live Response file upload/download
├── QueueManager.psm1              # Batch operation queuing
├── StatusTracker.psm1             # Long-running operation status tracking
│
└── === SERVICE MODULES (1) ===
    └── DefenderForIdentity.psm1   # MDI-specific Graph API calls
```

### Archived Modules (v2.4.0)

The following modules have been archived to `archive/old-modules/` as their functionality is now embedded in worker functions:

**Service Modules (11):**
- `MDEDevice.psm1` → Logic in MDEWorker
- `MDEIncident.psm1` → Logic in MDEWorker
- `MDEHunting.psm1` → Logic in MDEWorker
- `MDEThreatIntel.psm1` → Logic in MDEWorker
- `MDEDetection.psm1` → Logic in MDEWorker
- `MDELiveResponse.psm1` → Logic in MDEWorker
- `MDOEmailRemediation.psm1` → Logic in MDOWorker
- `EntraIDIdentity.psm1` → Logic in EntraIDWorker
- `ConditionalAccess.psm1` → Logic in EntraIDWorker
- `IntuneDeviceManagement.psm1` → Logic in IntuneWorker
- `AzureInfrastructure.psm1` → Logic in AzureWorker

**Duplicates (2):**
- `MDEAuth.psm1` → Replaced by AuthManager.psm1
- `MDEConfig.psm1` → Not used in Azure Functions

**Why?** Workers are self-contained with action handlers inline. Service modules added unnecessary imports without providing value.

---

## Utility Modules



---## Device Operations (MDEDevice.psm1)



## Usage in Azure Functions### Invoke-DeviceIsolation

Isolates device(s) from the network.

This module is automatically loaded by all worker functions:

```powershell

```powershellInvoke-DeviceIsolation -Token $token -DeviceIds @("device-id") -Comment "Suspected compromise" -IsolationType "Full"

# Auto-imported in profile.ps1```

Import-Module DefenderXDRC2XSOAR

### Invoke-DeviceUnisolation

# Use in worker functionsReleases device(s) from isolation.

$token = Get-MicrosoftGraphToken -TenantId $tenantId

$devices = Get-MDEDevices -Token $token```powershell

```Invoke-DeviceUnisolation -Token $token -DeviceIds @("device-id") -Comment "Threat remediated"

```

---

### Invoke-RestrictAppExecution

## Key FeaturesRestricts application execution on device(s).



### Centralized Authentication (AuthManager.psm1)```powershell

- Multi-tenant supportInvoke-RestrictAppExecution -Token $token -DeviceIds @("device-id") -Comment "Suspicious activity"

- Token caching (5-min expiry buffer)```

- Microsoft Graph, Defender ATP, Azure Management APIs

- Secure credential handling### Invoke-UnrestrictAppExecution

Removes application execution restriction.

### Device Management (MDEDevice.psm1)

- Isolate/unisolate devices```powershell

- Run antivirus scansInvoke-UnrestrictAppExecution -Token $token -DeviceIds @("device-id") -Comment "Investigation completed"

- Collect investigation packages```

- Restrict app execution

- Manage machine tags### Invoke-AntivirusScan

Initiates antivirus scan on device(s).

### Threat Intelligence (MDEThreatIntel.psm1)

- Submit file/URL/IP/certificate indicators```powershell

- List and remove indicatorsInvoke-AntivirusScan -Token $token -DeviceIds @("device-id") -ScanType "Full" -Comment "Routine scan"

- Advanced filtering```



### Advanced Hunting (MDEHunting.psm1)### Invoke-CollectInvestigationPackage

- Execute KQL queriesCollects investigation package from device(s).

- Query result caching

- Schema exploration```powershell

Invoke-CollectInvestigationPackage -Token $token -DeviceIds @("device-id") -Comment "Security investigation"

### Incident Management (MDEIncident.psm1)```

- List incidents with filtering

- Update incident properties### Invoke-StopAndQuarantineFile

- Add commentsStops and quarantines a file across all devices.

- Incident enrichment

```powershell

### Email Security (MDOEmailRemediation.psm1)Invoke-StopAndQuarantineFile -Token $token -Sha1 "file-hash" -Comment "Malware detected"

- Remediate phishing emails```

- Submit threats for analysis

- Remove forwarding rules### Get-DeviceInfo

- Quarantine managementGets information about a specific device.



### Cloud Security (DefenderForCloud.psm1)```powershell

- Security alertsGet-DeviceInfo -Token $token -DeviceId "device-id"

- Recommendations```

- Secure score

- Defender plans management### Get-AllDevices

Gets all devices in the tenant.

### Identity Protection (DefenderForIdentity.psm1)

- Identity alerts```powershell

- Lateral movement pathsGet-AllDevices -Token $token -Filter "riskScore eq 'High'"

- Exposed credentials```

- Suspicious activities

## Threat Intelligence (MDEThreatIntel.psm1)

---

### Add-FileIndicator

## ConfigurationAdds file indicator to MDE.



### Azure Function App Settings```powershell

Add-FileIndicator -Token $token -Sha256 "hash" -Title "Malware" -Severity "High" -Action "Block"

``````

SPN_ID          = <multi-tenant-app-id>

SPN_SECRET      = <app-secret>### Remove-FileIndicator

```Removes file indicator from MDE.



### Standalone Configuration```powershell

Remove-FileIndicator -Token $token -IndicatorId "indicator-id"

```powershell```

# Save configuration locally

Save-MDEConfiguration -Config @{### Add-IPIndicator

    TenantId = "your-tenant-id"Adds IP address indicator.

    AppId = "your-app-id"

    ClientSecret = (ConvertTo-SecureString "your-secret" -AsPlainText -Force)```powershell

}Add-IPIndicator -Token $token -IPAddress "1.2.3.4" -Title "C2 Server" -Severity "High" -Action "Block"

```

# Load configuration

$config = Get-MDEConfiguration### Add-URLIndicator

```Adds URL or domain indicator.



---```powershell

Add-URLIndicator -Token $token -URL "malicious.com" -Title "Phishing Site" -Severity "High" -Action "Block"

## API Permissions Required```



See [PERMISSIONS.md](../../PERMISSIONS.md) for complete list:### Get-AllIndicators

Gets all threat indicators.

- Microsoft Graph (Security, User, Device)

- Windows Defender ATP (Machine, Alert, Incident)```powershell

- Office 365 ExchangeGet-AllIndicators -Token $token -Filter "severity eq 'High'"

- Azure Service Management```



---## Advanced Hunting (MDEHunting.psm1)



## Examples### Invoke-AdvancedHunting

Executes an advanced hunting query.

### Get Device and Isolate

```powershell

```powershell$query = @"

# Get tokenDeviceProcessEvents

$token = Get-DefenderToken -TenantId $tenantId -AppId $appId -AppSecret $appSecret| where Timestamp > ago(7d)

| where ProcessCommandLine has "powershell"

# Find device| take 100

$device = Get-MDEDevices -Token $token -Filter "computerDnsName eq 'DESKTOP-ABC123'""@



# Isolate device$results = Invoke-AdvancedHunting -Token $token -Query $query

Invoke-MDEIsolateDevice -Token $token -MachineId $device.id -Comment "Suspicious activity detected"```

```

## Incident Management (MDEIncident.psm1)

### Run Advanced Hunting Query

### Get-SecurityIncidents

```powershellGets security incidents.

$query = @"

DeviceProcessEvents```powershell

| where Timestamp > ago(1h)Get-SecurityIncidents -Token $token -Filter "severity eq 'High'"

| where ProcessCommandLine contains "powershell"```

| project Timestamp, DeviceName, ProcessCommandLine

"@## Custom Detections (MDEDetection.psm1)



$results = Invoke-MDEAdvancedHunting -Token $token -Query $query### Get-CustomDetections

```Gets all custom detection rules.



### Remediate Email```powershell

Get-CustomDetections -Token $token

```powershell```

Invoke-MDORemediateEmail `

    -Token $token `## Live Response (MDELiveResponse.psm1)

    -MessageId "AAMkAGI2..." `

    -RemediationType "SoftDelete"### Start-MDELiveResponseSession

```Initiates a Live Response session.



---```powershell

Start-MDELiveResponseSession -Token $token -DeviceId "device-id" -Comment "Investigation"

## Worker Functions```



Each worker function uses these modules:### Get-MDELiveResponseSession

Gets Live Response session status.

- **MDOWorker** → MDOEmailRemediation.psm1

- **MDCWorker** → DefenderForCloud.psm1```powershell

- **MDIWorker** → DefenderForIdentity.psm1Get-MDELiveResponseSession -Token $token -SessionId "session-id"

- **EntraIDWorker** → EntraIDIdentity.psm1```

- **IntuneWorker** → IntuneDeviceManagement.psm1

- **AzureWorker** → AzureInfrastructure.psm1## Azure Functions Integration



All workers use:The module is used by Azure Functions through the following pattern:

- AuthManager.psm1 (authentication)

- ValidationHelper.psm1 (validation)```powershell

- LoggingHelper.psm1 (logging)# In function run.ps1

using namespace System.Net

---

param($Request, $TriggerMetadata)

## Logging

# Get credentials from environment

All modules use structured logging via LoggingHelper:$appId = $env:APPID

$secretId = $env:SECRETID

```powershell$tenantId = $Request.Body.tenantId

Write-LogInfo "Device isolated successfully" -Context @{

    deviceId = $deviceId# Authenticate

    action = "Isolate"$token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

}

# Perform operations

Write-LogError "Failed to isolate device" -Error $_.Exception -Context @{$devices = Get-AllDevices -Token $token

    deviceId = $deviceId

}# Return results

```Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{

    StatusCode = [HttpStatusCode]::OK

---    Body = $devices | ConvertTo-Json

})

## Error Handling```



Consistent error handling across all modules:## API Permissions Required



```powershellThe App Registration must have the following API permissions:

try {

    # API call### Microsoft Threat Protection / Microsoft Defender

} catch {- `Machine.Isolate` - Isolate/unisolate devices

    Write-LogError "Operation failed" -Error $_.Exception- `Machine.RestrictExecution` - Restrict app execution

    throw- `Machine.Scan` - Run antivirus scans

}- `Machine.CollectForensics` - Collect investigation packages

```- `Machine.StopAndQuarantine` - Stop and quarantine files

- `Machine.Read.All` - Read device information

---- `Machine.ReadWrite.All` - Full device management

- `Ti.ReadWrite.All` - Manage threat indicators

## Testing- `AdvancedQuery.Read.All` - Execute advanced hunting queries

- `SecurityIncident.Read.All` - Read security incidents

```powershell- `SecurityIncident.ReadWrite.All` - Manage security incidents

# Test authentication- `CustomDetections.ReadWrite.All` - Manage custom detections

Test-DefenderAuth -TenantId $tenantId -AppId $appId -AppSecret $appSecret

All permissions should be granted as **Application permissions** (not Delegated).

# Test device query

Get-MDEDevices -Token $token -Top 5## Error Handling

```

All functions use try-catch blocks and throw exceptions on errors. The Azure Functions will catch these and return appropriate HTTP error responses.

---

```powershell

## Contributingtry {

    $result = Invoke-DeviceIsolation -Token $token -DeviceIds @("id") -Comment "Test"

When adding new capabilities:} catch {

    Write-Error $_.Exception.Message

1. Follow PowerShell best practices    throw

2. Use AuthManager for token acquisition}

3. Add ValidationHelper checks```

4. Include LoggingHelper logging

5. Add error handling## Multi-Tenant Support

6. Update this README

The module supports multi-tenant scenarios by accepting the `TenantId` parameter in `Connect-MDE`. Each request can target a different tenant by specifying the appropriate tenant ID.

---

## Logging

## Version History

Use `Write-Verbose` for detailed logging and `Write-Error` for errors. Azure Functions will capture these in Application Insights.

- **v2.3.0** - Specialized worker architecture with 50 actions

- **v2.2.0** - Consolidated XDR orchestrator```powershell

- **v2.1.0** - Multi-tenant support with centralized authWrite-Verbose "Processing device isolation for device: $deviceId"

- **v1.0.0** - Initial releaseWrite-Error "Failed to isolate device: $($_.Exception.Message)"

```

---

## Rate Limiting

**Part of DefenderXDR v2.3.0 Platform** 🚀

The MDE API has rate limits. Implement retry logic with exponential backoff for production scenarios.

## Testing

Test authentication and basic operations:

```powershell
# Load module
Import-Module ./MDEAutomator.psd1

# Test authentication
$token = Connect-MDE -TenantId "your-tenant" -AppId "your-app" -ClientSecret "your-secret"

# Test device retrieval
$devices = Get-AllDevices -Token $token
Write-Host "Found $($devices.Count) devices"
```

## Troubleshooting

### Authentication Fails
- Verify App ID and Secret are correct
- Verify API permissions are granted and admin consented
- Check tenant ID is correct

### API Calls Fail
- Verify token is valid: `Test-MDEToken -Token $token`
- Check API permissions
- Review error messages for specific issues

### Module Not Loading
- Check `profile.ps1` loads the module
- Verify all .psm1 files are present
- Check for syntax errors in module files

## References

- [Microsoft Defender for Endpoint API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Advanced Hunting API Reference](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/run-advanced-query-api)
- [Machine Actions API](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/machineaction)
