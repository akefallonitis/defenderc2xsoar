# Live Response Interactive Shell - UI Screenshots

This document shows the user interface of the Live Response Interactive Shell feature.

## Main Menu with Live Response Option

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
 8.  Live Response Operations                    ← NEW FEATURE
 9.  View Current Configuration
 0.  Exit

═══════════════════════════════════════════════════════════════════════

Enter your choice: 8
```

## Live Response Menu

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        MDE Automator - Standalone PowerShell Framework                ║
║        Local Edition                                                  ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Connected to tenant: contoso.onmicrosoft.com

═══════════════════════════════════════════════════════════════════════
 Live Response Menu
═══════════════════════════════════════════════════════════════════════

 1.  Interactive Shell (Connect to Device)      ← INTERACTIVE SHELL
 2.  Run Live Response Script
 3.  Get File from Device
 4.  Put File to Device
 5.  List Available Scripts in Library
 6.  View Active Sessions
 0.  Back to Main Menu

═══════════════════════════════════════════════════════════════════════

Enter your choice: 1
```

## Session Connection Process

```
Enter Device ID to connect: abc123-def456-789ghi-012jkl-345mno

⏳ Initiating Live Response session...
⏳ Waiting for session to become active...
  Status: Pending
  Status: Pending
  Status: Active
✓ Session established!

Press any key to enter interactive shell...
```

## Interactive Shell - Black & Green Theme

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════╗
║  COMMAND HISTORY (Last 10)                                            ║
╚═══════════════════════════════════════════════════════════════════════╝

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> _
```

**Note:** The actual terminal displays:
- Black background
- Green text for prompts and headers
- White text for output
- Color-coded status indicators (✓=Green, ✗=Red, ⏳=Yellow, ⏸=Gray)

## Example: Directory Listing

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════╗
║  COMMAND HISTORY (Last 10)                                            ║
╚═══════════════════════════════════════════════════════════════════════╝
[14:23:45] ✓ dir C:\Users\user\Downloads

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> dir C:\Users\user\Downloads

⏳ Listing directory: C:\Users\user\Downloads
✓ Directory listing:
    Directory: C:\Users\user\Downloads

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---           1/15/2024  2:30 PM         524288 document.pdf
-a---           1/15/2024  3:15 PM        1048576 suspicious.exe
-a---           1/14/2024 10:45 AM          65536 readme.txt

Press any key to continue...
```

## Example: File Download

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════╗
║  COMMAND HISTORY (Last 10)                                            ║
╚═══════════════════════════════════════════════════════════════════════╝
[14:23:45] ✓ dir C:\Users\user\Downloads
[14:24:12] ✓ getfile C:\Users\user\Downloads\suspicious.exe

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> getfile C:\Users\user\Downloads\suspicious.exe
Enter local destination path: C:\evidence\case123\suspicious.exe

⏳ Waiting for file download to complete...
✓ File downloaded to: C:\evidence\case123\suspicious.exe

Press any key to continue...
```

## Example: Command Execution

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════╗
║  COMMAND HISTORY (Last 10)                                            ║
╚═══════════════════════════════════════════════════════════════════════╝
[14:23:45] ✓ dir C:\Users\user\Downloads
[14:24:12] ✓ getfile C:\Users\user\Downloads\suspicious.exe
[14:25:03] ✓ run ipconfig /all

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> run ipconfig /all

⏳ Executing: ipconfig /all
✓ Command output:

Windows IP Configuration

   Host Name . . . . . . . . . . . . : DESKTOP-ABC123
   Primary Dns Suffix  . . . . . . . : contoso.com
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No

Ethernet adapter Ethernet:

   Connection-specific DNS Suffix  . : contoso.com
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.1.1

Press any key to continue...
```

## Example: Help Display

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> help

Available Commands:
  help              - Show this help message
  dir <path>        - List directory contents
  getfile <path>    - Download file from device
  putfile <path>    - Upload file to device
  runscript <name>  - Execute script from library
  run <command>     - Execute arbitrary command
  history           - Show command history
  clear             - Clear screen
  exit              - Close session and return

Press any key to continue...
```

## Example: Command History View

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> history

Command History:

[2024-01-15 14:23:45] ✓ dir C:\Users\user\Downloads
[2024-01-15 14:24:12] ✓ getfile C:\Users\user\Downloads\suspicious.exe
[2024-01-15 14:25:03] ✓ run ipconfig /all
[2024-01-15 14:26:18] ✓ run Get-Process | Where-Object {$_.CPU -gt 100}
[2024-01-15 14:27:45] ✓ dir C:\Windows\Temp
[2024-01-15 14:28:32] ✗ getfile C:\nonexistent.txt
[2024-01-15 14:29:10] ✓ run netstat -ano

Press any key to continue...
```

## Split-Screen View with Active Commands

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════╗
║  COMMAND HISTORY (Last 10)                                            ║
╚═══════════════════════════════════════════════════════════════════════╝
[14:23:45] ✓ dir C:\Users\user\Downloads
[14:24:12] ✓ getfile C:\Users\user\Downloads\suspicious.exe
[14:25:03] ✓ run ipconfig /all
[14:26:18] ✓ run Get-Process | Where-Object {$_.CPU -gt 100}
[14:27:45] ✓ dir C:\Windows\Temp
[14:28:32] ✗ getfile C:\nonexistent.txt
[14:29:10] ✓ run netstat -ano
[14:30:05] ⏳ run Get-EventLog -LogName Security -Newest 100

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> _
```

## Session Exit

```
╔═══════════════════════════════════════════════════════════════════════╗
║              LIVE RESPONSE - INTERACTIVE SHELL                        ║
╚═══════════════════════════════════════════════════════════════════════╝

Device ID    : abc123-def456-789ghi-012jkl-345mno
Session ID   : sess-12345-67890-abcde-fghij
Status       : Active

═══════════════════════════════════════════════════════════════════════

Commands: help, dir <path>, getfile, putfile, runscript, exit

LR> exit

Closing session...
✓ Session closed

Press any key to continue...
```

## Color Scheme Legend

The Live Response shell uses a distinctive black and green color scheme:

| Element | Color | Description |
|---------|-------|-------------|
| Background | Black | Terminal background |
| Headers/Borders | Green | Box drawing and headers |
| Prompts | Green | `LR>` prompt and labels |
| Command Text | White | User input and output |
| Success (✓) | Green | Completed operations |
| Error (✗) | Red | Failed operations |
| In Progress (⏳) | Yellow | Running operations |
| Pending (⏸) | Gray | Queued operations |
| Device/Session Info | Yellow | Important identifiers |
| Timestamps | Gray | Historical information |

## Features Demonstrated

### 1. Split-Screen Layout
- Top: Session status banner
- Middle: Command history panel (last 10 commands)
- Bottom: Interactive prompt area

### 2. Visual Status Indicators
- ✓ Green checkmark for successful operations
- ✗ Red X for failed operations
- ⏳ Yellow hourglass for in-progress operations
- ⏸ Gray pause for pending operations

### 3. Real-Time Updates
- Session status updates automatically
- Command history updates as commands complete
- Status indicators change based on async polling results

### 4. User-Friendly Prompts
- Clear command syntax examples
- Interactive file path prompts
- Helpful error messages
- Context-aware help system

### 5. Professional Appearance
- Clean box-drawing characters
- Consistent spacing and alignment
- Color-coded information hierarchy
- Classic terminal aesthetic

## Navigation Tips

- **Tab completion**: Not currently supported (manual typing required)
- **Arrow keys**: Not currently supported for history (use `history` command)
- **Ctrl+C**: May interrupt current operation (use `exit` to close gracefully)
- **Clear screen**: Use `clear` command to refresh display

## Accessibility

- High contrast green-on-black theme
- Clear visual indicators for all states
- Text-based interface works with screen readers
- No reliance on graphics or icons beyond standard Unicode
