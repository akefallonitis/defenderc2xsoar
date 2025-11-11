# DefenderXDRC2XSOAR PowerShell Module# MDEAutomator PowerShell Module



**Enterprise Microsoft Security Orchestration**This module provides comprehensive automation capabilities for Microsoft Defender for Endpoint (MDE) operations within Azure Functions.



---## Overview



## OverviewThe MDEAutomator module is a collection of PowerShell modules that enable:

- Multi-tenant authentication to MDE

The DefenderXDRC2XSOAR module is a collection of PowerShell modules that enable:- Device management operations

- Threat intelligence management

- Authentication across Microsoft security services- Advanced hunting queries

- Device management and response actions- Security incident management

- Threat intelligence operations- Custom detection rule management

- Advanced hunting queries- Live Response operations

- Incident management

- Custom detection rules## Module Structure

- Live response capabilities

- Email security operations (MDO)```

- Cloud security (MDC)MDEAutomator/

- Identity protection (MDI)├── MDEAutomator.psd1       # Module manifest

- Entra ID management├── MDEAuth.psm1            # Authentication module

- Intune device management├── MDEDevice.psm1          # Device operations

- Azure infrastructure security├── MDEThreatIntel.psm1     # Threat intelligence operations

├── MDEHunting.psm1         # Advanced hunting

---├── MDEIncident.psm1        # Incident management

├── MDEDetection.psm1       # Custom detection management

## Module Structure├── MDELiveResponse.psm1    # Live Response operations

└── MDEConfig.psm1          # Configuration management

``````

DefenderXDRC2XSOAR/

├── DefenderXDRC2XSOAR.psd1    # Module manifest## Installation

├── AuthManager.psm1            # Centralized authentication with token caching

├── MDEAuth.psm1                # MDE authentication helpersThe module is automatically loaded by the Azure Functions runtime via `profile.ps1`.

├── MDEConfig.psm1              # Configuration management

├── MDEDevice.psm1              # Device actions## Authentication

├── MDEThreatIntel.psm1         # Threat indicators

├── MDEHunting.psm1             # Advanced hunting### Connect-MDE

├── MDEIncident.psm1            # Incident management

├── MDEDetection.psm1           # Custom detectionsAuthenticates to the Microsoft Defender for Endpoint API using client credentials flow.

├── MDELiveResponse.psm1        # Live response

├── MDOEmailRemediation.psm1    # Email security (Defender for Office 365)```powershell

├── DefenderForCloud.psm1       # Cloud security operations$token = Connect-MDE -TenantId "tenant-id" -AppId "app-id" -ClientSecret "secret"

├── DefenderForIdentity.psm1    # Identity threat detection```

├── EntraIDIdentity.psm1        # Entra ID management

├── IntuneDeviceManagement.psm1 # Intune operations**Parameters:**

├── AzureInfrastructure.psm1    # Azure security- `TenantId` - Azure AD Tenant ID

├── ConditionalAccess.psm1      # Conditional Access policies- `AppId` - Application (Client) ID from App Registration

├── ValidationHelper.psm1       # Input validation- `ClientSecret` - Client Secret (string or SecureString)

└── LoggingHelper.psm1          # Structured logging

```**Returns:** Token hashtable containing AccessToken, TokenType, ExpiresAt, and TenantId



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
