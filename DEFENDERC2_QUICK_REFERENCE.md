# DefenderC2 Enhanced Workbook - Quick Reference

## 🚀 Quick Start (3 Steps)

1. **Select Function App** → Auto-discovers connection details
2. **Select Workspace** → Enables logging and Sentinel integration  
3. **Select Tenant** → Choose which Defender XDR to manage

✅ You're ready! Navigate to any tab to begin operations.

---

## 📋 Tab Quick Reference

### 🎯 Device Manager
**Use When**: Managing device states and executing device-level actions

| Action | Steps | Result |
|--------|-------|--------|
| **View All Devices** | 1. Open tab | Auto-refreshing device inventory |
| **Select Device** | 1. Click "✅ Select" button | Device ID added to `DeviceList` parameter |
| **Isolate Device** | 1. Select device(s)<br>2. Choose "Isolate Device"<br>3. Click "Execute" | Device disconnected from network |
| **Run AV Scan** | 1. Select device(s)<br>2. Choose "Run Antivirus Scan"<br>3. Click "Execute" | Full antivirus scan initiated |
| **Check Conflicts** | 1. Select device(s)<br>2. Review "Pending Actions" table | Shows if action already running |

**Key Parameters**:
- `DeviceList`: Comma-separated device IDs (click to select)
- `ActionToExecute`: Device action type

---

### 🛡️ Threat Intel Manager
**Use When**: Managing threat indicators (IOCs)

| Action | Steps | Result |
|--------|-------|--------|
| **View Indicators** | 1. Open tab | Auto-refreshing indicator list |
| **Add File Hash** | 1. Enter hash (SHA1/SHA256/MD5)<br>2. Choose action (Alert/Block/Warn)<br>3. Add title<br>4. Click "Add" | File indicator created |
| **Add IP Address** | 1. Enter IP (IPv4/IPv6)<br>2. Choose action<br>3. Add title<br>4. Click "Add" | IP indicator created |
| **Block URL** | 1. Enter URL/domain<br>2. Choose "Block"<br>3. Add title<br>4. Click "Add" | URL blocked across organization |

**Indicator Actions**:
- **Alert**: Generate alert only
- **Block**: Block and alert
- **Warn**: Warn user and allow override

---

### 📋 Action Manager
**Use When**: Tracking device actions and troubleshooting

| Action | Steps | Result |
|--------|-------|--------|
| **View All Actions** | 1. Open tab | Auto-refreshing action history |
| **Cancel Action** | 1. Click "❌ Cancel" on action<br>2. Click "Cancel Action" button | Action terminated |
| **Track Progress** | 1. Watch Status column | Real-time status updates (30s) |
| **Filter by Device** | 1. Use table filters | Show actions for specific device |

**Action Statuses**:
- 🟡 **Pending**: Queued, not started
- 🔵 **InProgress**: Currently executing
- 🟢 **Succeeded**: Completed successfully
- 🔴 **Failed**: Error occurred

---

### 🔍 Advanced Hunting
**Use When**: Running KQL queries for threat hunting or investigation

| Action | Steps | Result |
|--------|-------|--------|
| **Run Sample Query** | 1. Select from dropdown<br>2. Click "Execute Query" | Results displayed below |
| **Custom KQL Query** | 1. Enter KQL in text box<br>2. Click "Execute Query" | Custom query results |
| **Device Inventory** | 1. Select "Device Inventory"<br>2. Execute | All devices with details |
| **Network Activity** | 1. Select "Recent Network Activity"<br>2. Execute | Last 24h network events |

**Sample Queries**:
```kql
// High Risk Devices
DeviceInfo 
| where RiskScore >= 'High'

// Recent Process Events  
DeviceProcessEvents
| where Timestamp > ago(24h)
| take 100

// Network Connections
DeviceNetworkEvents
| where Timestamp > ago(24h)
| project Timestamp, DeviceName, RemoteIP, RemotePort, RemoteUrl
```

---

### 🚨 Incident Manager
**Use When**: Managing security incidents

| Action | Steps | Result |
|--------|-------|--------|
| **View Incidents** | 1. Open tab | Auto-refreshing incident list |
| **Update Status** | 1. Enter Incident ID<br>2. Choose new status<br>3. Add comment<br>4. Click "Update" | Incident status changed |
| **Add Investigation Notes** | 1. Enter Incident ID<br>2. Add comment<br>3. Click "Update" | Comment added to incident |

**Incident Statuses**:
- 🔴 **Active**: Under investigation
- 🟡 **InProgress**: Being remediated
- 🟢 **Resolved**: Investigation complete
- ⚪ **Redirected**: Moved to other team

---

### ⚙️ Custom Detections
**Use When**: Creating or managing custom detection rules

| Action | Steps | Result |
|--------|-------|--------|
| **View Rules** | 1. Open tab | Auto-refreshing rule list |
| **Create Rule** | 1. Enter rule name<br>2. Enter KQL query<br>3. Choose severity<br>4. Click "Create" | New detection rule active |
| **Monitor Rules** | 1. Check "Enabled" column | See which rules are active |

**Severity Levels**:
- ℹ️ **Informational**: FYI only
- 🟢 **Low**: Minor issue
- 🟡 **Medium**: Investigate
- 🟠 **High**: Urgent response needed

**Example Detection KQL**:
```kql
// Detect PowerShell download cradle
DeviceProcessEvents
| where Timestamp > ago(1h)
| where FileName == "powershell.exe"
| where ProcessCommandLine has_any ("IEX", "Invoke-Expression", "downloadstring")
```

---

### 🖥️ Live Response Console
**Use When**: Executing commands on remote devices

| Action | Steps | Result |
|--------|-------|--------|
| **View Sessions** | 1. Open tab | Active Live Response sessions |
| **Run Command** | 1. Enter Device ID<br>2. Choose "RunCommand"<br>3. Enter command (e.g., `dir c:\`)<br>4. Click "Execute" | Command executed on device |
| **Run Script** | 1. Enter Device ID<br>2. Choose "RunScript"<br>3. Enter script name<br>4. Add arguments (optional)<br>5. Click "Execute" | Library script executed |
| **Get File** | 1. Enter Device ID<br>2. Choose "GetFile"<br>3. Enter file path<br>4. Click "Execute" | File downloaded to Defender portal |
| **Put File** | 1. Enter Device ID<br>2. Choose "PutFile"<br>3. Enter file name<br>4. Click "Execute" | File uploaded from library |

**Command Types**:
- **RunScript**: Execute script from library
- **RunCommand**: Native Windows/Linux command
- **GetFile**: Download file from device
- **PutFile**: Upload file to device

**Common Commands**:
```cmd
# Windows
dir c:\
netstat -ano
tasklist
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
ipconfig /all

# Linux
ls -la /home
ps aux
netstat -tulpn
cat /etc/passwd
```

---

## 🎨 UI Elements

### Color Codes

| Color | Meaning | Example |
|-------|---------|---------|
| 🟢 Green | Success, Active, Low Risk | Device healthy, action succeeded |
| 🟡 Yellow | Warning, Pending | Action queued, medium priority |
| 🔴 Red | Error, Failed, High Risk | Device unhealthy, action failed |
| 🔵 Blue | In Progress, Info | Action running, informational |
| ⚪ Gray | Inactive, Unknown | Device offline, status unknown |

### Interactive Elements

| Icon/Text | Action | Result |
|-----------|--------|--------|
| **✅ Select** | Click on device row | Device ID added to `DeviceList` |
| **❌ Cancel** | Click on action row | Action ID added to `ActionIdToCancel` |
| **🚀 Execute** | Click button | ARM action triggered with Azure confirmation |
| **📊 Details** | Click link | Opens detailed view |

---

## 🔧 Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| **Device list empty** | Wait 3 seconds after selecting Function App for auto-discovery |
| **"Query failed" error** | Check Function App is running and APPID/SECRETID are set |
| **400 Bad Request** | Check Pending Actions - may have duplicate action running |
| **ARM Action not working** | Verify you have `invoke/action` permission on Function App |
| **Auto-refresh stopped** | Refresh browser page to restart |
| **Parameters not populating** | Re-select Function App to trigger auto-discovery |

---

## ⚡ Power User Tips

### 1. Bulk Device Operations
```
1. Select multiple devices (click ✅ Select on each)
2. DeviceList will be comma-separated: "device1,device2,device3"
3. Execute action → applies to all selected devices
```

### 2. Quick Action Cancellation
```
1. Device Manager tab → Pending Actions table
2. Click ❌ Cancel next to unwanted action
3. Scroll down → Click "Cancel Action" button
4. No need to copy/paste Action ID!
```

### 3. Advanced Hunting Workflows
```
1. Run broad query (e.g., all process events)
2. Export results to CSV
3. Analyze in Excel/Power BI
4. Create custom detection rule from findings
```

### 4. Incident Response Workflow
```
1. Device Manager → Select affected device
2. Action Manager → Cancel any conflicting actions
3. Device Manager → Isolate device
4. Live Response → Collect forensics (getfile)
5. Incident Manager → Update incident status
```

### 5. Threat Intel Workflow
```
1. Hunting → Identify malicious hash/IP/URL
2. Threat Intel → Add indicator with Block action
3. Device Manager → Run AV scan on affected devices
4. Action Manager → Track scan progress
```

---

## 📊 Key Metrics to Monitor

### Device Health
- Unhealthy devices: Filter by Health = "Inactive"
- High risk devices: Filter by Risk = "High"
- Isolated devices: Filter by IsolationState = "Isolated"

### Action Performance
- Failed actions: Filter by Status = "Failed"
- Long-running actions: Sort by Created date
- Action success rate: Count(Succeeded) / Count(Total)

### Incident Response
- Open incidents: Status = "Active"
- Average resolution time: Track Created → Updated
- High severity incidents: Severity = "High"

---

## 🔐 Security Best Practices

### Before Isolating Devices
- ✅ Check if device is critical server
- ✅ Notify device owner/user
- ✅ Document reason in Incident Manager
- ✅ Check for pending actions that might conflict

### When Adding Threat Indicators
- ✅ Verify indicator is truly malicious (VirusTotal, etc.)
- ✅ Use "Alert" first, then escalate to "Block" if confirmed
- ✅ Add descriptive title with threat name/type
- ✅ Document source of indicator

### For Live Response Sessions
- ✅ Only run on devices under active investigation
- ✅ Document all commands executed
- ✅ Sessions auto-expire after 10 minutes inactivity
- ✅ Downloaded files stored in Defender portal, not local

---

## 📱 Mobile Access

The workbook is responsive and works on mobile devices:
- Access via Azure Mobile App → Workbooks
- Use tablet for better experience
- Portrait mode: stacked layout
- Landscape mode: desktop-like layout

---

## 🔄 Auto-Refresh Behavior

| Section | Refresh | Reason |
|---------|---------|--------|
| Device List | ✅ 30s | Monitor device health changes |
| Pending Actions | ✅ 30s | Track action progress |
| Action History | ✅ 30s | See newly completed actions |
| Threat Indicators | ✅ 30s | Monitor indicator additions |
| Incidents | ✅ 30s | Track incident updates |
| Detection Rules | ✅ 30s | Monitor rule changes |
| Live Sessions | ✅ 30s | Track active sessions |
| **ARM Actions** | ❌ Manual | Prevents accidental re-execution |

---

## 💡 Pro Tips

1. **Pin workbook to dashboard** for quick access
2. **Use browser bookmarks** with pre-selected parameters
3. **Create separate workbooks** for prod/dev environments
4. **Set up alerts** on failed actions (via Azure Monitor)
5. **Export action history** weekly for compliance audit
6. **Document custom queries** in Advanced Hunting comments
7. **Test destructive actions** in dev environment first
8. **Use dark theme** in Azure Portal for better terminal aesthetic

---

## 📞 Getting Help

### In Order of Priority
1. **Check this Quick Reference** - Common issues covered here
2. **Review Full Guide** - DEFENDERC2_WORKBOOK_ENHANCED_GUIDE.md
3. **Check Function Logs** - Function App → Monitor tab
4. **Azure Activity Log** - Portal → Activity Log → Filter by Function App
5. **GitHub Issues** - Create issue with error details
6. **Azure Support** - For platform-level issues

---

**Quick Reference Version**: 2.0.0  
**Last Updated**: 2024-11-05  
**Full Guide**: DEFENDERC2_WORKBOOK_ENHANCED_GUIDE.md
