# Live Response Interactive Shell - User Guide

## Overview

The Live Response Interactive Shell provides a powerful, terminal-based interface for real-time interaction with devices in your Microsoft Defender for Endpoint environment. This feature brings shell-like capabilities directly to the standalone MDE Automator, allowing you to:

- Execute commands interactively on remote devices
- Upload and download files
- Run scripts from your Live Response library
- View command history and execution status
- Monitor operations with visual status indicators

## Key Features

### 🎨 Black & Green Terminal Theme
Classic terminal aesthetic with black background and green text for the Live Response shell, providing clear visual distinction from other menu operations.

### 📊 Split-Screen Display
- **Command History Panel** - Shows last 10 commands with timestamps and status
- **Live Output Area** - Displays command results and system messages
- **Session Status Bar** - Real-time session status and device information

### ⚡ Async Command Execution
- Commands execute asynchronously on the remote device
- Automatic polling with configurable intervals (3-5 seconds)
- Respects Microsoft API rate limits
- Visual progress indicators during execution

### 📝 Command History Tracking
- Persistent history for the current session
- Status tracking for each command (✓ Completed, ✗ Failed, ⏳ InProgress, ⏸ Pending)
- Timestamp for each command execution
- Easy review of past operations

### 🔄 Multi-Tenancy Support
Built-in support for multiple tenants through the configuration system. Switch tenants by updating your configuration.

## Getting Started

### Prerequisites

1. **Authentication** - Authenticate first using Main Menu > Option 1
2. **API Permissions** - Ensure `Machine.LiveResponse` permission is granted
3. **Device Access** - Target device must be online and responsive
4. **PowerShell 7+** - Required for optimal experience

### Starting an Interactive Session

1. From the Main Menu, select **8** (Live Response Operations)
2. Select **1** (Interactive Shell)
3. Enter the Device ID you want to connect to
4. Wait for session initialization (typically 5-15 seconds)
5. Once active, you'll enter the interactive shell

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789...
Session ID   : sess-12345-67890...
Status       : Active

═══════════════════════════════════════════════════════════════════════

LR>
```

## Available Commands

### help
Display all available commands and their usage.

```
LR> help
```

### dir <path>
List directory contents on the remote device.

```
LR> dir C:\Users\user\Desktop
LR> dir "C:\Program Files"
```

**Notes:**
- Path defaults to `C:\` if not specified
- Use quotes for paths with spaces
- Results show files and directories with attributes

### getfile <remote_path>
Download a file from the remote device to your local machine.

```
LR> getfile C:\Users\user\Downloads\suspicious.exe
Enter local destination path: C:\investigation\suspicious.exe
```

**Notes:**
- You'll be prompted for local destination path
- If destination not specified, file saves to temp directory
- Large files may take several minutes to download
- Progress indicator shows download status

### putfile <local_path>
Upload a file from your local machine to the remote device.

```
LR> putfile C:\tools\analyzer.exe
Enter remote destination path: C:\Temp\analyzer.exe
```

**Notes:**
- File must exist locally before upload
- You'll be prompted for remote destination
- Default destination is `C:\Temp\<filename>`
- File is uploaded to Live Response library first, then to device

### runscript <script_name> [arguments]
Execute a script from your Live Response library.

```
LR> runscript CollectLogs.ps1
LR> runscript AnalyzeProcess.ps1 -ProcessName chrome
```

**Notes:**
- Script must exist in your Live Response library
- View available scripts with Main Menu > 8 > 5
- Optional arguments passed to the script
- Full output displayed after completion

### run <command>
Execute an arbitrary command on the remote device.

```
LR> run ipconfig /all
LR> run Get-Process | Where-Object {$_.CPU -gt 100}
LR> run netstat -ano
```

**Notes:**
- Supports both CMD and PowerShell commands
- Output captured and displayed
- Long-running commands supported with async polling
- Timeout after 5 minutes (configurable)

### history
Display complete command history for the current session.

```
LR> history
```

Shows:
- Timestamp for each command
- Command executed
- Status indicator (✓ Completed, ✗ Failed, etc.)

### clear
Clear the screen and refresh the display.

```
LR> clear
```

### exit
Close the Live Response session and return to menu.

```
LR> exit
```

**Notes:**
- Session is properly closed on the server
- Command history is preserved until program exit
- You can start a new session at any time

## Usage Examples

### Example 1: Investigate Suspicious Process

```
LR> run Get-Process | Where-Object {$_.ProcessName -eq 'suspicious'}
⏳ Executing: Get-Process | Where-Object {$_.ProcessName -eq 'suspicious'}
✓ Command output:
ProcessName      : suspicious
Id               : 4532
CPU              : 125.43
...

LR> run tasklist /FI "PID eq 4532" /V
⏳ Executing: tasklist /FI "PID eq 4532" /V
✓ Command output:
[Process details displayed]

LR> run taskkill /PID 4532 /F
⏳ Executing: taskkill /PID 4532 /F
✓ Command output:
SUCCESS: The process with PID 4532 has been terminated.
```

### Example 2: Collect Evidence

```
LR> dir C:\Users\compromised_user\Downloads
⏳ Listing directory: C:\Users\compromised_user\Downloads
✓ Directory listing:
malware.exe
suspicious.doc
...

LR> getfile C:\Users\compromised_user\Downloads\malware.exe
Enter local destination path: C:\evidence\case123\malware.exe
⏳ Downloading file: C:\Users\compromised_user\Downloads\malware.exe
✓ File downloaded to: C:\evidence\case123\malware.exe

LR> getfile C:\Users\compromised_user\Downloads\suspicious.doc
Enter local destination path: C:\evidence\case123\suspicious.doc
⏳ Downloading file: C:\Users\compromised_user\Downloads\suspicious.doc
✓ File downloaded to: C:\evidence\case123\suspicious.doc

LR> history
[2024-01-15 14:23:45] ✓ dir C:\Users\compromised_user\Downloads
[2024-01-15 14:24:12] ✓ getfile C:\Users\compromised_user\Downloads\malware.exe
[2024-01-15 14:25:03] ✓ getfile C:\Users\compromised_user\Downloads\suspicious.doc
```

### Example 3: Deploy Remediation Tool

```
LR> putfile C:\tools\remediation_script.ps1
Enter remote destination path: C:\Temp\remediation_script.ps1
⏳ Uploading file: C:\tools\remediation_script.ps1
✓ File uploaded to: C:\Temp\remediation_script.ps1

LR> run PowerShell.exe -ExecutionPolicy Bypass -File C:\Temp\remediation_script.ps1
⏳ Executing: PowerShell.exe -ExecutionPolicy Bypass -File C:\Temp\remediation_script.ps1
✓ Command output:
[Remediation script output]

LR> run Remove-Item C:\Temp\remediation_script.ps1 -Force
⏳ Executing: Remove-Item C:\Temp\remediation_script.ps1 -Force
✓ Command output:
[Cleanup confirmed]
```

### Example 4: Network Investigation

```
LR> run netstat -ano | findstr ESTABLISHED
⏳ Executing: netstat -ano | findstr ESTABLISHED
✓ Command output:
TCP    192.168.1.100:54321    52.96.128.23:443    ESTABLISHED    4532
TCP    192.168.1.100:54322    40.76.4.15:443      ESTABLISHED    2156
...

LR> run nslookup 52.96.128.23
⏳ Executing: nslookup 52.96.128.23
✓ Command output:
[DNS resolution results]

LR> run Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'} | Format-Table
⏳ Executing: Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'} | Format-Table
✓ Command output:
[Formatted connection table]
```

## Command Status Indicators

Commands display status using visual indicators:

| Indicator | Status | Meaning |
|-----------|--------|---------|
| ✓ | Completed | Command executed successfully |
| ✗ | Failed | Command failed with error |
| ⏳ | InProgress | Command currently executing |
| ⏸ | Pending | Command queued for execution |

## API Rate Limiting & Polling

The Live Response shell respects Microsoft's API rate limits:

- **Polling Interval**: 3-5 seconds between status checks
- **Timeout**: 300 seconds (5 minutes) default
- **Automatic Retry**: Built-in exponential backoff for transient errors
- **Session Limits**: Follow Microsoft's guidance on concurrent sessions

This ensures reliable operation without hitting rate limits while maintaining responsive user experience.

## Multi-Tenancy Support

Switch between tenants easily:

1. Exit the current session with `exit` command
2. Return to Main Menu
3. Select **9** (View Current Configuration)
4. Note current tenant
5. Select **1** (Authentication & Configuration)
6. Choose **N** to enter new credentials
7. Enter credentials for different tenant
8. Resume operations with new tenant context

## Best Practices

### Security
- ✅ **Use service accounts** - Dedicated accounts for Live Response operations
- ✅ **Log all actions** - Command history provides audit trail
- ✅ **Verify device ID** - Ensure you're connecting to correct device
- ✅ **Secure downloaded files** - Treat as potentially malicious
- ✅ **Clean up uploaded files** - Remove tools after use

### Performance
- ✅ **Wait for completion** - Allow commands to finish before next action
- ✅ **Use specific paths** - Avoid wildcards for better performance
- ✅ **Monitor session status** - Check session remains active
- ✅ **Close unused sessions** - Use `exit` to clean up properly

### Troubleshooting
- ✅ **Check device status** - Ensure device is online
- ✅ **Verify permissions** - Confirm `Machine.LiveResponse` granted
- ✅ **Review command syntax** - Use `help` for guidance
- ✅ **Check network** - Ensure connectivity to Microsoft APIs

## Troubleshooting

### Session Won't Connect

**Symptoms:** Session stuck in "Pending" status

**Solutions:**
1. Verify device is online and responsive
2. Check device ID is correct
3. Ensure device has defender running
4. Wait up to 60 seconds for initial connection
5. Try different device to rule out device-specific issues

### Commands Timeout

**Symptoms:** Commands don't complete within 5 minutes

**Solutions:**
1. Check command complexity - simplify if possible
2. Verify device isn't under heavy load
3. Split complex commands into smaller operations
4. Use scripts for long-running operations

### File Transfer Fails

**Symptoms:** Upload or download fails with error

**Solutions:**
1. Verify file exists and path is correct
2. Check file size - large files take longer
3. Ensure sufficient disk space on both systems
4. Verify permissions on source/destination paths
5. Try smaller files first to test connectivity

### "Permission Denied" Errors

**Symptoms:** Commands fail with access denied

**Solutions:**
1. Verify `Machine.LiveResponse` permission granted
2. Check admin consent was provided
3. Review API permissions in Azure Portal
4. Re-authenticate if token expired
5. Ensure app registration is active

### Session Disconnects

**Symptoms:** Session closes unexpectedly

**Solutions:**
1. Check network connectivity
2. Verify token hasn't expired
3. Look for API rate limit errors
4. Review device health status
5. Start new session and retry operation

## Technical Reference

### Session Lifecycle

1. **Initialization** - `Start-MDELiveResponseSession` called
2. **Activation** - Wait for session status to become "Active"
3. **Command Loop** - Interactive command execution
4. **Polling** - Async status checks every 3-5 seconds
5. **Cleanup** - `Stop-MDELiveResponseSession` on exit

### API Endpoints Used

- `POST /api/machines/{id}/liveresponse` - Create session
- `GET /api/liveresponse/sessions/{id}` - Check session status
- `POST /api/liveresponse/sessions/{id}/commands` - Execute command
- `GET /api/liveresponse/commands/{id}` - Get command result
- `DELETE /api/liveresponse/sessions/{id}` - Close session

### Module Functions

The `MDELiveResponse.psm1` module provides:

- `Start-MDELiveResponseSession` - Create new session
- `Get-MDELiveResponseSession` - Get session status
- `Invoke-MDELiveResponseCommand` - Execute command
- `Get-MDELiveResponseCommandResult` - Get result
- `Wait-MDELiveResponseCommand` - Async polling
- `Get-MDELiveResponseFile` - Download file
- `Send-MDELiveResponseFile` - Upload file
- `Stop-MDELiveResponseSession` - Close session
- `Get-MDELiveResponseLibraryScripts` - List scripts
- `Invoke-MDELiveResponseScript` - Run script

## FAQ

**Q: Can I run multiple sessions simultaneously?**
A: The current implementation supports one active session at a time. Start a new session after closing the previous one.

**Q: How long can a session stay active?**
A: Microsoft's default timeout is 30 minutes of inactivity. Keep the session active by executing commands.

**Q: What commands are supported?**
A: Most PowerShell and CMD commands work. Avoid GUI applications or interactive prompts.

**Q: Can I upload/download large files?**
A: Yes, but be mindful of network bandwidth and timeout settings. Files over 100MB may require extended timeouts.

**Q: Is command history saved between sessions?**
A: History is maintained during program execution but clears on exit. Use `history` command to review before exiting.

**Q: How do I stop a running command?**
A: Currently commands must complete. Future versions may support command cancellation.

**Q: Can I use this with non-Windows devices?**
A: Live Response is currently supported for Windows devices only in Microsoft Defender for Endpoint.

## Additional Resources

- [Microsoft Defender Live Response Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/live-response)
- [MDE API Reference](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api/apis-intro)
- [Live Response Command Reference](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/live-response-command-examples)

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Microsoft documentation
3. Check GitHub issues: https://github.com/akefallonitis/defenderc2xsoar/issues
4. Open new issue with details and logs
