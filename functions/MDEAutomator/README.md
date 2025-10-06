# MDEAutomator PowerShell Module

This module provides comprehensive automation capabilities for Microsoft Defender for Endpoint (MDE) operations within Azure Functions.

## Overview

The MDEAutomator module is a collection of PowerShell modules that enable:
- Multi-tenant authentication to MDE
- Device management operations
- Threat intelligence management
- Advanced hunting queries
- Security incident management
- Custom detection rule management
- Live Response operations

## Module Structure

```
MDEAutomator/
├── MDEAutomator.psd1       # Module manifest
├── MDEAuth.psm1            # Authentication module
├── MDEDevice.psm1          # Device operations
├── MDEThreatIntel.psm1     # Threat intelligence operations
├── MDEHunting.psm1         # Advanced hunting
├── MDEIncident.psm1        # Incident management
├── MDEDetection.psm1       # Custom detection management
├── MDELiveResponse.psm1    # Live Response operations
└── MDEConfig.psm1          # Configuration management
```

## Installation

The module is automatically loaded by the Azure Functions runtime via `profile.ps1`.

## Authentication

### Connect-MDE

Authenticates to the Microsoft Defender for Endpoint API using client credentials flow.

```powershell
$token = Connect-MDE -TenantId "tenant-id" -AppId "app-id" -ClientSecret "secret"
```

**Parameters:**
- `TenantId` - Azure AD Tenant ID
- `AppId` - Application (Client) ID from App Registration
- `ClientSecret` - Client Secret (string or SecureString)

**Returns:** Token hashtable containing AccessToken, TokenType, ExpiresAt, and TenantId

## Device Operations (MDEDevice.psm1)

### Invoke-DeviceIsolation
Isolates device(s) from the network.

```powershell
Invoke-DeviceIsolation -Token $token -DeviceIds @("device-id") -Comment "Suspected compromise" -IsolationType "Full"
```

### Invoke-DeviceUnisolation
Releases device(s) from isolation.

```powershell
Invoke-DeviceUnisolation -Token $token -DeviceIds @("device-id") -Comment "Threat remediated"
```

### Invoke-RestrictAppExecution
Restricts application execution on device(s).

```powershell
Invoke-RestrictAppExecution -Token $token -DeviceIds @("device-id") -Comment "Suspicious activity"
```

### Invoke-UnrestrictAppExecution
Removes application execution restriction.

```powershell
Invoke-UnrestrictAppExecution -Token $token -DeviceIds @("device-id") -Comment "Investigation completed"
```

### Invoke-AntivirusScan
Initiates antivirus scan on device(s).

```powershell
Invoke-AntivirusScan -Token $token -DeviceIds @("device-id") -ScanType "Full" -Comment "Routine scan"
```

### Invoke-CollectInvestigationPackage
Collects investigation package from device(s).

```powershell
Invoke-CollectInvestigationPackage -Token $token -DeviceIds @("device-id") -Comment "Security investigation"
```

### Invoke-StopAndQuarantineFile
Stops and quarantines a file across all devices.

```powershell
Invoke-StopAndQuarantineFile -Token $token -Sha1 "file-hash" -Comment "Malware detected"
```

### Get-DeviceInfo
Gets information about a specific device.

```powershell
Get-DeviceInfo -Token $token -DeviceId "device-id"
```

### Get-AllDevices
Gets all devices in the tenant.

```powershell
Get-AllDevices -Token $token -Filter "riskScore eq 'High'"
```

## Threat Intelligence (MDEThreatIntel.psm1)

### Add-FileIndicator
Adds file indicator to MDE.

```powershell
Add-FileIndicator -Token $token -Sha256 "hash" -Title "Malware" -Severity "High" -Action "Block"
```

### Remove-FileIndicator
Removes file indicator from MDE.

```powershell
Remove-FileIndicator -Token $token -IndicatorId "indicator-id"
```

### Add-IPIndicator
Adds IP address indicator.

```powershell
Add-IPIndicator -Token $token -IPAddress "1.2.3.4" -Title "C2 Server" -Severity "High" -Action "Block"
```

### Add-URLIndicator
Adds URL or domain indicator.

```powershell
Add-URLIndicator -Token $token -URL "malicious.com" -Title "Phishing Site" -Severity "High" -Action "Block"
```

### Get-AllIndicators
Gets all threat indicators.

```powershell
Get-AllIndicators -Token $token -Filter "severity eq 'High'"
```

## Advanced Hunting (MDEHunting.psm1)

### Invoke-AdvancedHunting
Executes an advanced hunting query.

```powershell
$query = @"
DeviceProcessEvents
| where Timestamp > ago(7d)
| where ProcessCommandLine has "powershell"
| take 100
"@

$results = Invoke-AdvancedHunting -Token $token -Query $query
```

## Incident Management (MDEIncident.psm1)

### Get-SecurityIncidents
Gets security incidents.

```powershell
Get-SecurityIncidents -Token $token -Filter "severity eq 'High'"
```

## Custom Detections (MDEDetection.psm1)

### Get-CustomDetections
Gets all custom detection rules.

```powershell
Get-CustomDetections -Token $token
```

## Live Response (MDELiveResponse.psm1)

### Start-MDELiveResponseSession
Initiates a Live Response session.

```powershell
Start-MDELiveResponseSession -Token $token -DeviceId "device-id" -Comment "Investigation"
```

### Get-MDELiveResponseSession
Gets Live Response session status.

```powershell
Get-MDELiveResponseSession -Token $token -SessionId "session-id"
```

## Azure Functions Integration

The module is used by Azure Functions through the following pattern:

```powershell
# In function run.ps1
using namespace System.Net

param($Request, $TriggerMetadata)

# Get credentials from environment
$appId = $env:APPID
$secretId = $env:SECRETID
$tenantId = $Request.Body.tenantId

# Authenticate
$token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

# Perform operations
$devices = Get-AllDevices -Token $token

# Return results
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $devices | ConvertTo-Json
})
```

## API Permissions Required

The App Registration must have the following API permissions:

### Microsoft Threat Protection / Microsoft Defender
- `Machine.Isolate` - Isolate/unisolate devices
- `Machine.RestrictExecution` - Restrict app execution
- `Machine.Scan` - Run antivirus scans
- `Machine.CollectForensics` - Collect investigation packages
- `Machine.StopAndQuarantine` - Stop and quarantine files
- `Machine.Read.All` - Read device information
- `Machine.ReadWrite.All` - Full device management
- `Ti.ReadWrite.All` - Manage threat indicators
- `AdvancedQuery.Read.All` - Execute advanced hunting queries
- `SecurityIncident.Read.All` - Read security incidents
- `SecurityIncident.ReadWrite.All` - Manage security incidents
- `CustomDetections.ReadWrite.All` - Manage custom detections

All permissions should be granted as **Application permissions** (not Delegated).

## Error Handling

All functions use try-catch blocks and throw exceptions on errors. The Azure Functions will catch these and return appropriate HTTP error responses.

```powershell
try {
    $result = Invoke-DeviceIsolation -Token $token -DeviceIds @("id") -Comment "Test"
} catch {
    Write-Error $_.Exception.Message
    throw
}
```

## Multi-Tenant Support

The module supports multi-tenant scenarios by accepting the `TenantId` parameter in `Connect-MDE`. Each request can target a different tenant by specifying the appropriate tenant ID.

## Logging

Use `Write-Verbose` for detailed logging and `Write-Error` for errors. Azure Functions will capture these in Application Insights.

```powershell
Write-Verbose "Processing device isolation for device: $deviceId"
Write-Error "Failed to isolate device: $($_.Exception.Message)"
```

## Rate Limiting

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
