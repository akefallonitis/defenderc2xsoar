# Live Response Quick Reference Card

## Quick Start

```bash
# Launch MDE Automator
.\Start-MDEAutomatorLocal.ps1

# Main Menu → 8 (Live Response Operations)
# → 1 (Interactive Shell)
# → Enter Device ID
```

## Commands

| Command | Usage | Example |
|---------|-------|---------|
| `help` | Show all commands | `help` |
| `dir` | List directory | `dir C:\Users\user\Downloads` |
| `getfile` | Download file | `getfile C:\file.txt` |
| `putfile` | Upload file | `putfile C:\local.exe` |
| `runscript` | Run library script | `runscript CollectLogs.ps1` |
| `run` | Execute command | `run ipconfig /all` |
| `history` | Show command history | `history` |
| `clear` | Clear screen | `clear` |
| `exit` | Close session | `exit` |

## Status Indicators

| Icon | Status | Meaning |
|------|--------|---------|
| ✓ | Completed | Command succeeded |
| ✗ | Failed | Command failed |
| ⏳ | InProgress | Command executing |
| ⏸ | Pending | Command queued |

## Common Tasks

### Investigate Suspicious Process
```
LR> run Get-Process | Where-Object {$_.ProcessName -eq 'suspicious'}
LR> run tasklist /V /FI "PID eq 4532"
LR> run taskkill /PID 4532 /F
```

### Collect Evidence
```
LR> dir C:\Users\user\Downloads
LR> getfile C:\Users\user\Downloads\malware.exe
LR> run Get-FileHash -Path C:\Users\user\Downloads\malware.exe
```

### Deploy Tool
```
LR> putfile C:\tools\analyzer.exe
LR> run C:\Temp\analyzer.exe -scan
LR> run Remove-Item C:\Temp\analyzer.exe -Force
```

### Network Investigation
```
LR> run netstat -ano | findstr ESTABLISHED
LR> run Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'}
LR> run nslookup 52.96.128.23
```

## Tips

- **Wait for completion** - Let commands finish before next action
- **Check status** - Look for ✓ before proceeding
- **Use history** - Review what you've done
- **Copy output** - Select and copy terminal text
- **Clean up** - Remove uploaded files after use
- **Close properly** - Use `exit` to end session

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Session won't connect | Verify device is online, check device ID |
| Command timeout | Simplify command, check device load |
| File transfer fails | Verify paths, check permissions and space |
| Permission denied | Check API permissions in Azure Portal |
| Session disconnects | Check network, verify token not expired |

## API Limits

- Polling interval: 3-5 seconds
- Command timeout: 5 minutes default
- Session timeout: 30 minutes inactive
- Concurrent sessions: 1 per framework instance

## Multi-Tenancy

Switch tenants:
1. Exit current session: `exit`
2. Main Menu → 1 (Authentication)
3. Enter new tenant credentials
4. Resume operations

## File Locations

- Config: `%USERPROFILE%\.mdeautomator\config.json`
- Module: `standalone/modules/MDELiveResponse.psm1`
- Docs: `standalone/LIVE_RESPONSE_GUIDE.md`

## Required Permissions

- `Machine.LiveResponse` - Required for all operations
- Admin consent - Must be granted in Azure Portal

## Support

- Documentation: `LIVE_RESPONSE_GUIDE.md`
- Issues: https://github.com/akefallonitis/defenderc2xsoar/issues
- Microsoft Docs: https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/live-response

---

**Version:** 1.0  
**Last Updated:** January 2024
