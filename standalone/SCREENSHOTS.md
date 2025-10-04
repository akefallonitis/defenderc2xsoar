# UI Screenshots - MDE Automator Standalone

This document shows the user interface of the standalone MDE Automator framework.

## Main Menu

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator - Standalone PowerShell Framework                ║
║        Local Edition                                                  ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Connected to tenant: contoso.onmicrosoft.com

═══════════════════════════════════════════════════════════════════════
 Main Menu
═══════════════════════════════════════════════════════════════════════

 1.  Authentication & Configuration
 2.  Device Actions (Isolate, Scan, etc.)
 3.  Threat Intelligence Manager
 4.  Advanced Hunting
 5.  Incident Manager
 6.  Custom Detection Manager
 7.  Action Manager (View/Cancel Actions)
 8.  Live Response Operations
 9.  View Current Configuration
 0.  Exit

═══════════════════════════════════════════════════════════════════════

Enter your choice: _
```

## Device Actions Menu

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator - Standalone PowerShell Framework                ║
║        Local Edition                                                  ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Connected to tenant: contoso.onmicrosoft.com

═══════════════════════════════════════════════════════════════════════
 Device Actions Menu
═══════════════════════════════════════════════════════════════════════

 1.  Isolate Device(s)
 2.  Release Device(s) from Isolation
 3.  Restrict App Execution
 4.  Remove App Execution Restriction
 5.  Run Antivirus Scan
 6.  Collect Investigation Package
 7.  Stop and Quarantine File
 8.  Get Device Information
 9.  List All Devices
 0.  Back to Main Menu

═══════════════════════════════════════════════════════════════════════

Enter your choice: _
```

## Threat Intelligence Menu

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator - Standalone PowerShell Framework                ║
║        Local Edition                                                  ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Connected to tenant: contoso.onmicrosoft.com

═══════════════════════════════════════════════════════════════════════
 Threat Intelligence Menu
═══════════════════════════════════════════════════════════════════════

 1.  Add File Indicator (SHA256)
 2.  Remove File Indicator
 3.  Add IP Indicator
 4.  Remove IP Indicator
 5.  Add URL/Domain Indicator
 6.  Remove URL/Domain Indicator
 7.  Add Certificate Indicator (SHA1)
 8.  Remove Certificate Indicator
 9.  List All Indicators
 0.  Back to Main Menu

═══════════════════════════════════════════════════════════════════════

Enter your choice: _
```

## Example Operation: Device Isolation

```
Enter Device ID(s) (comma-separated): abc123def456

Enter isolation reason/comment: Suspected ransomware activity detected

Isolation type (Full/Selective) [Full]: Full

Initiating device isolation...
✓ Device isolation initiated successfully!
Action ID(s): 12345678-abcd-1234-abcd-123456789abc

Press any key to continue...
```

## Example Operation: List Devices

```
Retrieving all devices...

Total Devices: 15

id                                    computerDnsName  osPlatform  riskScore  healthStatus  lastSeen
------------------------------------  ---------------  ----------  ---------  ------------  -------------------
abc123def456ghi789                    DESKTOP-001      Windows10   High       Active        2024-01-15 14:30:22
def456ghi789jkl012                    LAPTOP-002       Windows11   Medium     Active        2024-01-15 14:28:15
ghi789jkl012mno345                    SERVER-001       WindowsSvr  Low        Active        2024-01-15 14:25:10
...

Export to CSV? (Y/N): Y
✓ Exported to: C:\Scripts\standalone\devices_export_20240115_143045.csv

Press any key to continue...
```

## Example: Authentication Setup

```
Authentication & Configuration
═══════════════════════════════════════════════════════════════════════

No configuration found. Let's set up your credentials.

Enter your Tenant ID: contoso.onmicrosoft.com
Enter your Application (Client) ID: 12345678-abcd-1234-abcd-123456789abc
Enter your Client Secret: ******************************************

Save configuration for future sessions? (Y/N): Y
✓ Configuration saved

Authenticating...
✓ Successfully authenticated!

Press any key to continue...
```

## Example: Advanced Hunting Query

```
═══════════════════════════════════════════════════════════════════════
 Advanced Hunting Menu
═══════════════════════════════════════════════════════════════════════

 1.  Execute Custom KQL Query
 2.  Run Saved Query from Library
 3.  Save Query to Library
 4.  List Query Library
 5.  Export Results to CSV
 0.  Back to Main Menu

═══════════════════════════════════════════════════════════════════════

Enter your choice: 1

Enter your KQL query (multi-line, end with empty line):

DeviceInfo
| where Timestamp > ago(1d)
| where RiskScore == "High"
| project DeviceName, OSPlatform, RiskScore, LastSeen = Timestamp

[empty line to execute]

Executing query...
✓ Query completed successfully!

Results (5 records):

DeviceName       OSPlatform   RiskScore  LastSeen
--------------   ----------   ---------  -------------------
DESKTOP-001      Windows10    High       2024-01-15 14:30:22
DESKTOP-005      Windows10    High       2024-01-15 14:25:18
LAPTOP-003       Windows11    High       2024-01-15 14:20:45
...

Export to CSV? (Y/N): N

Press any key to continue...
```

## Configuration View

```
Current Configuration:
  Tenant ID: contoso.onmicrosoft.com
  App ID: 12345678-abcd-1234-abcd-123456789abc
  Token Status: ✓ Valid

Press any key to continue...
```

## Error Handling Example

```
Enter Device ID(s) (comma-separated): invalid-device-id

Enter isolation reason/comment: Test isolation

Isolation type (Full/Selective) [Full]: Full

Initiating device isolation...
✗ Failed: Device not found: The specified device does not exist in this tenant

Press any key to continue...
```

## Installation Prerequisite Check

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator Local - Prerequisites Installer                 ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

[1/3] Checking PowerShell version...
  Current version: 7.4.1
  ✓ PowerShell 7.0+ detected

[2/3] Checking internet connectivity...
  ✓ Internet connectivity verified

[3/3] Checking module files...
  ✓ modules\MDEAuth.psm1
  ✓ modules\MDEConfig.psm1
  ✓ modules\MDEDevice.psm1
  ✓ modules\MDEThreatIntel.psm1
  ✓ modules\MDEHunting.psm1
  ✓ modules\MDEIncident.psm1
  ✓ modules\MDEDetection.psm1

═══════════════════════════════════════════════════════════════════════

✓ All prerequisites are met!

Next steps:
  1. Create an Azure AD App Registration
     - See QUICKSTART.md for detailed instructions
  2. Grant required API permissions
     - See README.md for the complete permission list
  3. Run the MDE Automator
     - Execute: .\Start-MDEAutomatorLocal.ps1

═══════════════════════════════════════════════════════════════════════

Would you like to launch MDE Automator now? (Y/N): _
```

## Color Legend

The UI uses colors to convey status information:

- 🟢 **Green** - Success messages, completed operations
- 🔴 **Red** - Error messages, failed operations
- 🟡 **Yellow** - Warnings, prompts, informational messages
- ⚪ **White** - Standard text, menu options
- 🔵 **Cyan** - Headers, borders, emphasis
- ⚫ **Gray** - Secondary information, details

## Navigation

- **Number Keys** - Select menu options
- **Enter** - Confirm selections
- **Text Input** - Enter values as prompted
- **0** - Return to previous menu or exit
- **Any Key** - Continue after messages

## Tips for Best Experience

1. **Terminal Size**: Minimum 120x30 characters recommended
2. **Colors**: Enable ANSI color support in your terminal
3. **PowerShell 7**: Use PowerShell 7.0+ for best compatibility
4. **Font**: Monospace font recommended for aligned tables
5. **Screen Reader**: Basic screen reader support via clear text labels

---

**Note**: Actual colors and formatting may vary depending on your terminal emulator and color scheme settings.
