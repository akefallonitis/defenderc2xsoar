# Examples - MDE Automator Standalone

This directory contains example scripts and queries to help you get started with the standalone MDE Automator framework.

## Files

### `sample-hunting-queries.kql`

A collection of 15 pre-built advanced hunting queries for common security scenarios:

1. **Suspicious PowerShell Activity** - Detect encoded commands and suspicious PowerShell usage
2. **Failed Logon Attempts** - Identify brute force attempts
3. **Files Written to Startup Folders** - Persistence mechanism detection
4. **Suspicious Network Connections** - Unusual high port connections
5. **Credential Dumping Tools** - LSASS access detection
6. **Scheduled Task Creation** - Persistence via scheduled tasks
7. **Devices with High Risk Score** - Current high-risk endpoints
8. **Unsigned Driver Loading** - Potentially malicious drivers
9. **Suspicious Registry Modifications** - Persistence via registry
10. **Lateral Movement** - Remote execution detection
11. **Web Shell Activity** - IIS process spawning detection
12. **Ransomware Indicators** - Mass file encryption detection
13. **Living-off-the-Land Binaries** - LOLBin abuse
14. **USB Device Activity** - External device tracking
15. **Privilege Escalation Attempts** - UAC bypass and elevation attempts

**Usage:**
1. Launch the standalone framework: `.\Start-MDEAutomatorLocal.ps1`
2. Go to **Advanced Hunting** menu (Option 4)
3. Select **Execute Custom KQL Query** (Option 1)
4. Copy and paste a query from the file
5. View and optionally export results

### `bulk-isolate-devices.ps1`

Example script demonstrating programmatic use of the framework modules to perform bulk operations.

**Features:**
- Automatically isolates devices based on risk score
- Can use saved configuration or accept credentials as parameters
- WhatIf mode for testing
- Confirmation prompt before isolation
- CSV export of results
- Detailed progress and error reporting

**Usage:**

```powershell
# Using saved configuration
.\bulk-isolate-devices.ps1 -RiskScore High

# WhatIf mode (no actual changes)
.\bulk-isolate-devices.ps1 -RiskScore High -WhatIf

# With explicit credentials
$secret = Read-Host "Client Secret" -AsSecureString
.\bulk-isolate-devices.ps1 -TenantId "xxx" -AppId "xxx" -ClientSecret $secret -RiskScore High
```

**Parameters:**
- `-TenantId` - Azure AD Tenant ID (optional if config saved)
- `-AppId` - Application Client ID (optional if config saved)
- `-ClientSecret` - Client Secret as SecureString (optional if config saved)
- `-RiskScore` - Filter devices by risk score: High, Medium, or Low (default: High)
- `-WhatIf` - Show what would happen without making changes

## Creating Your Own Scripts

You can create custom automation scripts using the framework modules. Here's a template:

```powershell
# Import required modules
$ScriptRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$ScriptRoot\modules\MDEAuth.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEDevice.psm1" -Force
Import-Module "$ScriptRoot\modules\MDEConfig.psm1" -Force

# Load configuration
$config = Get-MDEConfiguration

# Authenticate
$token = Connect-MDE -TenantId $config.TenantId -AppId $config.AppId -ClientSecret $config.ClientSecret

# Perform operations
$devices = Get-AllDevices -Token $token

# Process results
foreach ($device in $devices) {
    # Your logic here
}
```

## Common Patterns

### Pattern 1: Query and Act on Results

```powershell
# Get devices with specific criteria
$filter = "riskScore eq 'High' and healthStatus eq 'Active'"
$devices = Get-AllDevices -Token $token -Filter $filter

# Act on each device
foreach ($device in $devices) {
    # Take action
    Invoke-DeviceIsolation -Token $token -DeviceIds @($device.id) -Comment "Auto-isolation"
}
```

### Pattern 2: Bulk Threat Intelligence Import

```powershell
# Read indicators from CSV
$indicators = Import-Csv "indicators.csv"

# Add each indicator
foreach ($indicator in $indicators) {
    Add-FileIndicator -Token $token `
        -Sha256 $indicator.Hash `
        -Title $indicator.Title `
        -Severity $indicator.Severity `
        -Action "Block"
}
```

### Pattern 3: Scheduled Hunting

```powershell
# Execute hunting query
$query = @"
DeviceProcessEvents
| where Timestamp > ago(1h)
| where FileName =~ "powershell.exe"
| where ProcessCommandLine has "downloadstring"
"@

$results = Invoke-AdvancedHunting -Token $token -Query $query

# Process and alert on results
if ($results.Count -gt 0) {
    # Send notification, create ticket, etc.
}
```

### Pattern 4: Device Inventory Report

```powershell
# Get all devices
$devices = Get-AllDevices -Token $token

# Create report
$report = $devices | Select-Object `
    computerDnsName,
    osPlatform,
    osVersion,
    riskScore,
    healthStatus,
    lastSeen

# Export
$report | Export-Csv "device-inventory-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
```

## Best Practices

1. **Always use try-catch** for error handling
2. **Implement WhatIf mode** for potentially destructive operations
3. **Require confirmation** before bulk actions
4. **Export results** to CSV for audit trail
5. **Use verbose logging** during development
6. **Test with small batches** before full automation
7. **Schedule with Task Scheduler** for regular operations
8. **Monitor execution logs** for errors

## Advanced Usage

### Task Scheduler Integration

Create a scheduled task to run automation scripts:

```powershell
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\Scripts\bulk-isolate-devices.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

Register-ScheduledTask -TaskName "MDE Auto Isolation" `
    -Action $action -Trigger $trigger -RunLevel Highest
```

### Webhook Integration

Receive alerts and trigger actions:

```powershell
# Simple HTTP listener (use proper web framework in production)
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    
    # Parse webhook payload
    $reader = [System.IO.StreamReader]::new($request.InputStream)
    $body = $reader.ReadToEnd() | ConvertFrom-Json
    
    # Take action based on webhook
    if ($body.alertType -eq "HighRiskDevice") {
        Invoke-DeviceIsolation -Token $token -DeviceIds @($body.deviceId) -Comment "Auto-isolation from alert"
    }
    
    # Send response
    $response = $context.Response
    $response.StatusCode = 200
    $response.Close()
}
```

## Resources

- [Main Documentation](../README.md)
- [Quick Start Guide](../QUICKSTART.md)
- [Architecture Overview](../ARCHITECTURE.md)
- [MDE API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api-overview)
- [KQL Query Language](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)

## Contributing Examples

Have a useful script or query? Consider contributing:

1. Ensure your script follows the patterns above
2. Include comments explaining what it does
3. Test thoroughly in a non-production environment
4. Submit a pull request with your example

## Support

For questions about these examples:
1. Review the main documentation
2. Check [existing issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
3. Open a new issue with details

---

**⚠️ Warning**: These examples are for demonstration purposes. Always test in a non-production environment before using in production. Modify scripts to match your specific requirements and security policies.
