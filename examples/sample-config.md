# Sample Configuration

## Example Workbook Parameters

When you first open the workbook, configure these parameters:

```
Subscription: /subscriptions/12345678-1234-1234-1234-123456789abc
Workspace: /subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/rg-sentinel/providers/Microsoft.OperationalInsights/workspaces/workspace-sentinel
Target Tenant ID: 87654321-4321-4321-4321-cba987654321
Function App Base URL: https://mde-automator-prod.azurewebsites.net
Time Range: Last 30 days
```

**Note:** The Application ID and Client Secret are stored securely in the Function App's environment variables (configured during deployment). They are no longer entered in the workbook.

## Example Device Actions

### Isolate Specific Devices

```
Action Type: Isolate Device
Device IDs: device-id-1,device-id-2,device-id-3
```

### Isolate All High-Risk Devices

```
Action Type: Isolate Device
Device Filter: riskScore eq 'High'
```

### Collect Investigation Package from Critical Servers

```
Action Type: Collect Investigation Package
Device Filter: contains(machineTags, 'Critical') and contains(osPlatform, 'Windows')
```

### Run Antivirus Scan on All Endpoints

```
Action Type: Run Antivirus Scan
Device Filter: onboardingStatus eq 'Onboarded'
```

## Example Threat Intelligence Operations

### Block Known Malware Hashes

```
Action: Add File Indicators
Indicators: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855,5d41402abc4b2a76b9719d911017c592
Title: Cobalt Strike Beacons - Campaign X
Severity: High
Recommended Action: Block
```

### Alert on Suspicious IPs

```
Action: Add IP Indicators
Indicators: 192.0.2.1,198.51.100.42,203.0.113.99
Title: Known C2 Infrastructure
Severity: Medium
Recommended Action: Alert
```

### Block Malicious Domains

```
Action: Add URL/Domain Indicators
Indicators: evil.example.com,malicious.test,phishing.bad
Title: Phishing Campaign Q1 2024
Severity: High
Recommended Action: Block
```

## Example Hunting Queries

### Suspicious PowerShell Activity

```kql
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FileName =~ "powershell.exe" or FileName =~ "pwsh.exe"
| where ProcessCommandLine has_any (
    "-enc", "-encoded", "-e ", 
    "downloadstring", "downloadfile",
    "invoke-expression", "iex",
    "invoke-webrequest", "iwr",
    "-w hidden", "-windowstyle hidden",
    "bypass"
)
| where InitiatingProcessFileName !in~ ("explorer.exe", "services.exe", "svchost.exe")
| project Timestamp, DeviceName, AccountName, FileName, ProcessCommandLine, InitiatingProcessFileName, InitiatingProcessCommandLine
| order by Timestamp desc
```

### Lateral Movement via WMI

```kql
DeviceProcessEvents
| where Timestamp > ago(1d)
| where FileName =~ "wmic.exe"
| where ProcessCommandLine has_any ("process call create", "create", "/node:")
| where AccountName !endswith "$"
| project Timestamp, DeviceName, AccountName, ProcessCommandLine, RemoteDeviceName=extract(@"/node:\"?([^\"]+)\"?", 1, ProcessCommandLine)
| where isnotempty(RemoteDeviceName)
```

### File Creation in Suspicious Locations

```kql
DeviceFileEvents
| where Timestamp > ago(1d)
| where FolderPath startswith @"C:\Users\" 
| where FolderPath has_any (@"\AppData\Local\Temp\", @"\AppData\Roaming\", @"\Downloads\")
| where FileName endswith ".exe" or FileName endswith ".dll" or FileName endswith ".ps1"
| where ActionType == "FileCreated"
| project Timestamp, DeviceName, FileName, FolderPath, SHA256, InitiatingProcessFileName, InitiatingProcessCommandLine
| order by Timestamp desc
```

### Rare Network Connections

```kql
DeviceNetworkEvents
| where Timestamp > ago(1d)
| where ActionType == "ConnectionSuccess"
| where RemotePort in (443, 80, 8080, 8443)
| where RemoteUrl !has "microsoft" and RemoteUrl !has "windows" and RemoteUrl !has "azure"
| summarize ConnectionCount=count(), FirstSeen=min(Timestamp), LastSeen=max(Timestamp), DeviceCount=dcount(DeviceName) 
    by RemoteUrl, RemoteIP, RemotePort
| where DeviceCount <= 3 or ConnectionCount <= 5
| order by FirstSeen desc
```

### Persistence Mechanisms

```kql
DeviceRegistryEvents
| where Timestamp > ago(1h)
| where RegistryKey has_any (
    @"Software\Microsoft\Windows\CurrentVersion\Run",
    @"Software\Microsoft\Windows\CurrentVersion\RunOnce",
    @"Software\Microsoft\Windows\CurrentVersion\RunServices",
    @"Software\Microsoft\Windows\CurrentVersion\RunServicesOnce"
)
| where ActionType == "RegistryValueSet"
| where RegistryValueData !has "Microsoft" and RegistryValueData !has "Windows"
| project Timestamp, DeviceName, RegistryKey, RegistryValueName, RegistryValueData, InitiatingProcessFileName, InitiatingProcessCommandLine
```

## Example Custom Detection Rules

### Malicious PowerShell Detection

```json
{
  "name": "Suspicious PowerShell with Encoded Commands",
  "description": "Detects PowerShell executions with encoded commands and download capabilities",
  "severity": "High",
  "enabled": true,
  "query": "DeviceProcessEvents\n| where Timestamp > ago(1h)\n| where FileName =~ 'powershell.exe'\n| where ProcessCommandLine has_any ('-enc', 'downloadstring', 'iex')\n| where InitiatingProcessFileName !in~ ('explorer.exe', 'services.exe')",
  "recommendedActions": [
    "Isolate the affected device",
    "Collect investigation package",
    "Review process tree and network connections"
  ]
}
```

### Credential Dumping Detection

```json
{
  "name": "Credential Dumping Attempt",
  "description": "Detects attempts to access LSASS or credential stores",
  "severity": "Critical",
  "enabled": true,
  "query": "DeviceProcessEvents\n| where Timestamp > ago(1h)\n| where FileName in~ ('procdump.exe', 'mimikatz.exe', 'pwdump.exe')\n   or (ProcessCommandLine has 'lsass' and ProcessCommandLine has_any ('dump', 'minidump'))\n   or ProcessCommandLine has_any ('sekurlsa', 'logonpasswords')",
  "recommendedActions": [
    "Immediately isolate the device",
    "Force password reset for all users on the device",
    "Collect full investigation package",
    "Escalate to incident response team"
  ]
}
```

## Example Multi-Tenant Configuration

If you manage multiple tenants:

### Tenant A (Production)

```
Target Tenant ID: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
Function App Base URL: https://mde-automator-prod.azurewebsites.net
```

### Tenant B (Development)

```
Target Tenant ID: bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
Function App Base URL: https://mde-automator-prod.azurewebsites.net (same function app!)
```

**Note**: You use the same function app and app registration for all tenants. Just change the Target Tenant ID parameter when switching between tenants. The app credentials (APPID and SECRETID) are stored securely in the function app's environment variables.

## Example Incident Management

### Update Incident Status

```
Action: Update Incident
Incident ID: 123456
Status: Resolved
Classification: True Positive
Determination: Malware
Resolving Comment: Malware identified and quarantined. All affected devices cleaned.
```

### Add Investigation Notes

```
Action: Add Comment
Incident ID: 123456
Comment: Initial triage complete. Identified 5 affected devices. Malware appears to be Emotet variant. Recommending full investigation package collection.
```

## Function App Environment Variables

Your function app should have these configured (done automatically by ARM template):

```
APPID=your-app-id-here
SECRETID=your-client-secret-here
FUNCTIONS_WORKER_RUNTIME=powershell
FUNCTIONS_EXTENSION_VERSION=~4
AzureWebJobsStorage=[connection string - auto-configured]
```

**Security Note**: The `APPID` and `SECRETID` are stored securely in the function app settings and are never exposed to the workbook or end users. Each function request receives the `tenantId` parameter and uses these stored credentials to authenticate to that specific tenant.

## Tips and Best Practices

1. **Save Multiple Workbooks**: Create separate workbooks for different use cases or teams
2. **Use Filters Wisely**: Device filters accept OData syntax - use them to target specific devices
3. **Test First**: Always test actions on a small set of devices before bulk operations
4. **Document Actions**: Use meaningful titles and descriptions for threat indicators and detections
5. **Regular Hunts**: Schedule regular hunting queries to proactively find threats
6. **Review Logs**: Check Application Insights regularly for function errors
7. **Backup Detections**: Use the backup feature before making changes to custom detections

## Security Best Practices

1. **Restrict Workbook Access**: Use Azure RBAC to limit who can view/edit the workbook
2. **Enable Function Authentication**: Add Azure AD authentication to the function app
3. **Monitor Usage**: Set up alerts on unusual activity or high error rates
4. **Rotate Credentials**: Periodically rotate the client secret in the app registration and update the SECRETID environment variable
5. **Use Tags**: Tag devices and organize them for easier management
6. **Secure Environment Variables**: Limit access to the function app configuration where APPID and SECRETID are stored
6. **Test in Non-Production**: Always test new actions in a dev/test environment first
