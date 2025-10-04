# MDE Automator - Standalone PowerShell Framework

A local, standalone version of the MDE Automator that runs directly on your workstation without requiring Azure infrastructure. Features a menu-driven UI similar to MDEAutomator for easy interaction.

## 🎯 Overview

This standalone framework provides a PowerShell-based interface for managing Microsoft Defender for Endpoint operations locally. No Azure Functions, Azure Workbooks, or other cloud services required - just PowerShell and your MDE credentials.

## ✨ Features

- **🖥️ Interactive Menu UI** - Terminal-based menu system similar to MDEAutomator
- **🔐 Secure Credential Storage** - Encrypted storage of credentials using Windows DPAPI
- **📦 Zero Cloud Dependencies** - Runs entirely on your local machine
- **🚀 Quick Actions** - Fast access to common MDE operations
- **📊 Device Management** - Isolate, scan, restrict, and manage devices
- **🛡️ Threat Intelligence** - Manage indicators (files, IPs, URLs, domains)
- **🔍 Advanced Hunting** - Execute custom KQL queries
- **📋 Incident Management** - View and manage security incidents
- **🎨 Custom Detections** - Manage custom detection rules
- **🎮 Live Response Shell** - Interactive shell with file upload/download and command execution
- **💾 Export Capabilities** - Export results to CSV for analysis

## 🔧 Prerequisites

- **PowerShell 7.0 or later** - [Download here](https://github.com/PowerShell/PowerShell/releases)
- **Internet Connectivity** - To reach Microsoft Defender API endpoints
- **MDE App Registration** - With required API permissions (see below)

## 📋 Required API Permissions

You need an Azure AD App Registration with the following permissions:

### WindowsDefenderATP API
- `AdvancedQuery.Read.All`
- `Alert.Read.All`
- `File.Read.All`
- `Ip.Read.All`
- `Library.Manage`
- `Machine.CollectForensics`
- `Machine.Isolate`
- `Machine.StopAndQuarantine`
- `Machine.LiveResponse`
- `Machine.Offboard`
- `Machine.ReadWrite.All`
- `Machine.RestrictExecution`
- `Machine.Scan`
- `Ti.ReadWrite.All`
- `User.Read.All`

### Microsoft Graph API
- `CustomDetection.ReadWrite.All`
- `ThreatHunting.Read.All`
- `ThreatIndicators.ReadWrite.OwnedBy`
- `SecurityIncident.ReadWrite.All`

**Important:** Grant admin consent for these permissions in your tenant.

## 🚀 Quick Start

### 1. Create App Registration

1. Go to **Azure Portal** > **Azure Active Directory** > **App Registrations**
2. Click **New registration**
   - Name: `MDE-Automator-Local`
   - Supported account types: **Single tenant**
3. Create a **Client Secret**:
   - Go to **Certificates & secrets**
   - Click **New client secret**
   - Copy the secret value immediately
4. Configure **API Permissions** (see list above)
5. Grant **Admin consent** for all permissions
6. Copy your **Tenant ID** and **Application (Client) ID**

### 2. Download and Extract

```powershell
# Clone or download the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git
cd defenderc2xsoar/standalone
```

### 3. Launch the Framework

```powershell
# Run the main script
.\Start-MDEAutomatorLocal.ps1
```

### 4. First-Time Setup

On first launch, you'll be prompted to enter:
- **Tenant ID** - Your Azure AD tenant ID
- **Application (Client) ID** - From your app registration
- **Client Secret** - The secret value you copied

These credentials will be encrypted and saved locally for future sessions.

## 📖 Usage Guide

### Main Menu

After launching, you'll see the main menu:

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator - Standalone PowerShell Framework                ║
║        Local Edition                                                  ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Connected to tenant: your-tenant-id

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
```

### Common Operations

#### Isolate a Device

1. Select **2** (Device Actions)
2. Select **1** (Isolate Device)
3. Enter device ID(s) - comma-separated for multiple devices
4. Enter isolation reason
5. Choose isolation type (Full/Selective)

#### Add Threat Indicator

1. Select **3** (Threat Intelligence Manager)
2. Select the indicator type (File/IP/URL)
3. Enter the indicator value
4. Provide title, severity, and action

#### Execute Hunting Query

1. Select **4** (Advanced Hunting)
2. Select **1** (Execute Custom KQL Query)
3. Enter your KQL query
4. View results and optionally export to CSV

#### View Device Information

1. Select **2** (Device Actions)
2. Select **8** (Get Device Information)
3. Enter device ID
4. View detailed device information

### 🎮 Live Response Interactive Shell

The Live Response feature provides an interactive shell for executing commands on remote devices with real-time output and command history.

#### Starting an Interactive Session

1. Select **8** (Live Response Operations)
2. Select **1** (Interactive Shell)
3. Enter the Device ID to connect to
4. Wait for the session to become active
5. You'll enter the interactive shell with black/green UI theme

#### Available Commands in Interactive Shell

```
LR> help                         # Show all available commands
LR> dir <path>                   # List directory contents
LR> getfile <remote_path>        # Download file from device
LR> putfile <local_path>         # Upload file to device
LR> runscript <script_name>      # Execute script from library
LR> run <command>                # Execute arbitrary command
LR> history                      # Show command history
LR> clear                        # Clear screen
LR> exit                         # Close session and return
```

#### Features

- **🖥️ Split-Screen Display** - Command history panel + live output
- **⚡ Async Execution** - Commands run asynchronously with automatic polling
- **🎨 Black/Green Theme** - Classic terminal aesthetic for Live Response
- **📊 Command History** - Track all executed commands with status
- **✅ Status Indicators** - Visual feedback (✓ Completed, ✗ Failed, ⏳ InProgress)
- **🔁 Auto-Polling** - Respects API rate limits (3-5 second intervals)
- **📤 File Operations** - Upload/download files seamlessly

#### Example: Investigating a Device

```
LR> dir C:\Users\user\Downloads
⏳ Listing directory: C:\Users\user\Downloads
✓ Directory listing:
[Files listed here]

LR> getfile C:\Users\user\Downloads\suspicious.exe
Enter local destination path: C:\investigation\suspicious.exe
⏳ Downloading file: C:\Users\user\Downloads\suspicious.exe
✓ File downloaded to: C:\investigation\suspicious.exe

LR> run Get-FileHash -Path C:\Users\user\Downloads\suspicious.exe
⏳ Executing: Get-FileHash -Path C:\Users\user\Downloads\suspicious.exe
✓ Command output:
[Hash information displayed]

LR> history
[Shows all commands executed in this session]

LR> exit
Closing session...
✓ Session closed
```

#### Quick File Operations (Without Interactive Shell)

If you only need to perform a single operation:

**Download a File:**
1. Select **8** (Live Response Operations)
2. Select **3** (Get File from Device)
3. Enter Device ID, remote path, and local destination

**Upload a File:**
1. Select **8** (Live Response Operations)
2. Select **4** (Put File to Device)
3. Enter Device ID, local file path, and remote destination

**Run a Script:**
1. Select **8** (Live Response Operations)
2. Select **2** (Run Live Response Script)
3. Enter Device ID and script name from library

**View Library Scripts:**
1. Select **8** (Live Response Operations)
2. Select **5** (List Available Scripts in Library)

#### Technical Details

- **Session Management** - Automatic session creation and cleanup
- **API Rate Limiting** - 3-5 second polling intervals to respect limits
- **Multi-Tenancy** - Switch between tenants using configuration
- **Command Parsing** - Smart parsing of command arguments
- **Error Handling** - Clear error messages and recovery
- **Transcript Support** - Full output capture from executed commands

## 🔒 Security Features

### Credential Storage

Credentials are encrypted using Windows Data Protection API (DPAPI):
- Stored in `%USERPROFILE%\.mdeautomator\config.json`
- Encrypted per-user and per-machine
- Cannot be decrypted by other users or on other machines

### Token Management

- Access tokens are stored in memory only
- Automatic token validation and refresh
- Tokens expire after configured duration

### Best Practices

1. **Use dedicated service account** - Create a specific user for MDE operations
2. **Limit permissions** - Only grant required API permissions
3. **Rotate secrets regularly** - Change client secrets periodically
4. **Monitor activity** - Review MDE action logs regularly
5. **Secure your workstation** - Use full disk encryption and screen lock

## 📂 File Structure

```
standalone/
├── Start-MDEAutomatorLocal.ps1    # Main launcher script
├── modules/
│   ├── MDEAuth.psm1               # Authentication functions
│   ├── MDEConfig.psm1             # Configuration management
│   ├── MDEDevice.psm1             # Device operations
│   ├── MDEThreatIntel.psm1        # Threat intelligence
│   ├── MDEHunting.psm1            # Advanced hunting
│   ├── MDEIncident.psm1           # Incident management
│   ├── MDEDetection.psm1          # Custom detections
│   └── MDELiveResponse.psm1       # Live Response operations
├── config/                        # Configuration files (created at runtime)
├── examples/                      # Example scripts and queries
└── README.md                      # This file
```

## 🔧 Configuration

### Configuration File Location

`%USERPROFILE%\.mdeautomator\config.json`

### Manual Configuration

You can manually edit the configuration (though credentials will need re-encryption):

```powershell
# Remove existing configuration
Remove-MDEConfiguration

# Re-authenticate
.\Start-MDEAutomatorLocal.ps1
# Select option 1 to reconfigure
```

## 🐛 Troubleshooting

### "Authentication failed" Error

**Cause:** Invalid credentials or expired secret

**Solution:**
1. Verify your Tenant ID, App ID, and Client Secret
2. Check that the client secret hasn't expired
3. Ensure admin consent is granted for all API permissions

### "Failed to isolate device" Error

**Cause:** Missing API permissions or invalid device ID

**Solution:**
1. Verify the `Machine.Isolate` permission is granted
2. Check that the device ID is correct
3. Ensure the device is online and responding

### "Module not found" Error

**Cause:** PowerShell cannot find the required modules

**Solution:**
1. Ensure you're running the script from the `standalone` directory
2. Check that all module files exist in the `modules` folder
3. Use the full path: `C:\path\to\standalone\Start-MDEAutomatorLocal.ps1`

### Token Expiration

**Cause:** Access token has expired

**Solution:**
- Tokens are automatically refreshed when they expire
- If issues persist, select option 1 to re-authenticate

## 🆚 Comparison with Azure-based Version

| Feature | Azure Version | Standalone Version |
|---------|--------------|-------------------|
| **UI** | Azure Workbook | PowerShell Menu |
| **Infrastructure** | Azure Function App | Local PowerShell |
| **Authentication** | Managed Identity | App Registration |
| **Cost** | ~$50/month | Free (no Azure costs) |
| **Multi-tenant** | Yes | Single tenant |
| **Deployment** | Complex | Simple (just copy files) |
| **Portability** | Requires Azure | Runs anywhere |

## 💡 Tips & Tricks

1. **Bulk Operations**: For device actions, enter multiple device IDs separated by commas
2. **Export Results**: Most list operations offer CSV export functionality
3. **Save Queries**: Create a library of commonly-used hunting queries
4. **Action Tracking**: Use the Action Manager to monitor ongoing operations
5. **Quick Access**: Create a desktop shortcut to the launcher script

## 🔄 Updates

To update the standalone framework:

```powershell
# Pull latest changes
cd defenderc2xsoar
git pull origin main

# Your configuration is stored separately and won't be affected
```

## 📝 Examples

See the `examples/` directory for:
- Sample KQL hunting queries
- Bulk device operation scripts
- Indicator import scripts
- Custom detection templates

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📄 License

This project inherits the license from the original MDEAutomator project.

## 🙏 Acknowledgements

- Original [MDEAutomator](https://github.com/msdirtbag/MDEAutomator) by msdirtbag
- Azure-based defenderc2xsoar implementation
- Microsoft Defender for Endpoint team

## 📞 Support

For issues or questions:
1. Check this README and troubleshooting section
2. Review the [main project documentation](../README.md)
3. Search existing [GitHub issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
4. Open a new issue with details

## ⚠️ Disclaimer

This software is provided "as is", without warranty of any kind. Always test in a non-production environment first. Use at your own risk.
