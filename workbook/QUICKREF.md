# DeviceManager Workbooks - Quick Reference

## 🚀 Quick Start

### 1. Choose Your Version

| Version | Best For | File |
|---------|----------|------|
| **CustomEndpoint** | Testing, Debugging, Simple Architecture | `DeviceManager-CustomEndpoint.json` |
| **Hybrid** | Production, RBAC, Native Azure Integration | `DeviceManager-Hybrid.json` |

### 2. Import Workbook

```
Azure Portal → Monitor → Workbooks → New → Advanced Editor → Paste JSON → Apply → Save
```

### 3. Configure

1. Select **Function App** → Auto-populates: Subscription, ResourceGroup, FunctionAppName
2. Select **Tenant ID** → Your Defender XDR tenant
3. Select **Devices** → Auto-populated from Defender XDR

### 4. Execute Actions

**CustomEndpoint:** Select action from dropdown → Configure parameters → Execute  
**Hybrid:** Configure parameters → Click action button → Confirm → Execute

---

## 📊 Sections Overview

| Section | Purpose | Auto-Refresh |
|---------|---------|--------------|
| ⚠️ Pending Actions Warning | Shows pending actions on selected devices | ✅ |
| 🎯 Execute Action | Execute machine actions | ❌ |
| 📊 Running Actions | Monitor pending/in-progress actions | ✅ |
| 📋 Actions History | View all past actions (last 100) | ✅ |
| 🔍 Track Action | Monitor specific action by ID | ✅ |
| ❌ Cancel Action | Cancel a pending action | ❌ |
| 💻 Device Inventory | View all devices with risk scores | ✅ |

---

## 🎯 Supported Actions

| Icon | Action | Parameters | API Call |
|------|--------|------------|----------|
| 🔍 | Run Antivirus Scan | Scan Type (Quick/Full) | `Run Antivirus Scan` |
| 🔒 | Isolate Device | Isolation Type (Full/Selective) | `Isolate Device` |
| 🔓 | Unisolate Device | None | `Unisolate Device` |
| 📦 | Collect Investigation Package | None | `Collect Investigation Package` |
| 🚫 | Restrict App Execution | None | `Restrict App Execution` |
| ✅ | Unrestrict App Execution | None | `Unrestrict App Execution` |

---

## ⚡ Common Workflows

### Execute Scan on Multiple Devices
1. Select devices from **💻 Select Devices**
2. Choose **Scan Type** (Quick/Full)
3. Check **⚠️ Pending Actions Warning** for conflicts
4. **CustomEndpoint:** Select "Run Antivirus Scan" → Execute
5. **Hybrid:** Click "🔍 Run Antivirus Scan" → Confirm
6. View Action IDs in result table

### Track Action Status
1. Find action in **📊 Running Actions** or **📋 Actions History**
2. Click the **Action ID** (it auto-populates **🔍 Track Action ID**)
3. View status in **🔍 Track Action Status** section
4. Auto-refresh updates status automatically

### Cancel Pending Action
1. Find pending action in **📊 Running Actions**
2. Click the **Action ID** (it auto-populates **❌ Cancel Action ID**)
3. Cancellation executes immediately
4. View result in **❌ Cancel Action** section

### Handle 400 Error
1. Review **⚠️ Pending Actions Warning** before executing
2. Identify conflicting action and device
3. **Option A:** Wait for pending action to complete (monitor via auto-refresh)
4. **Option B:** Cancel pending action
5. Then execute new action

---

## 🔄 Auto-Refresh Configuration

| Interval | Value | Best For |
|----------|-------|----------|
| Off | 0 | Manual control, minimal API calls |
| 30 seconds | 30000 | **Default** - Good balance |
| 1 minute | 60000 | Lower API load |
| 5 minutes | 300000 | Production with many devices |

---

## 🎨 Visual Indicators

### Risk Scores
- 🔴 **High** → Red background
- 🟡 **Medium** → Orange background
- 🟢 **Low** → Green background

### Action Status
- ✅ **Succeeded** → Green with checkmark
- ❌ **Failed** → Red with X
- ⏳ **Pending** → Yellow with clock
- 🔄 **InProgress** → Blue with spinner
- 🚫 **Cancelled** → Gray with block

### Health Status
- **Active** → Green checkmark
- **Inactive** → Gray disabled
- **Other** → Yellow warning

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Devices not loading | Check Function App is running, verify tenant ID |
| 400 Bad Request | Check Pending Actions Warning, cancel duplicates |
| Auto-refresh not working | Verify AutoRefreshInterval ≠ "Off", check network |
| Action IDs not showing | Wait for auto-refresh, check action executed successfully |
| ARM Action fails | Check RBAC permissions, verify Function App auth |

---

## 📝 Parameter Reference

| Parameter | Type | Auto-Populated | Global | Dependencies |
|-----------|------|----------------|--------|--------------|
| FunctionApp | Dropdown | ❌ | ✅ | None |
| Subscription | Hidden | ✅ | ✅ | FunctionApp |
| ResourceGroup | Hidden | ✅ | ✅ | FunctionApp |
| FunctionAppName | Hidden | ✅ | ✅ | FunctionApp |
| TenantId | Dropdown | ✅ | ✅ | None |
| DeviceList | Multi-Select | ✅ | ✅ | FunctionApp, TenantId |
| ActionToExecute | Dropdown | ❌ | ✅ | None |
| ScanType | Dropdown | ❌ | ✅ | None |
| IsolationType | Dropdown | ❌ | ✅ | None |
| ActionIdToTrack | Text | ✅ (click) | ✅ | None |
| ActionIdToCancel | Text | ✅ (click) | ✅ | None |
| AutoRefreshInterval | Dropdown | ❌ | ✅ | None |

---

## 🔐 Security Best Practices

1. ✅ Use **Hybrid version** in production for better RBAC
2. ✅ Configure **Function App authentication** properly
3. ✅ Review **audit trail** (all actions logged with user/timestamp)
4. ✅ Use **least privilege** RBAC roles
5. ✅ Enable **Application Insights** for monitoring
6. ✅ Review **pending actions** before executing critical actions

---

## 📚 Additional Resources

- **Full Documentation:** `DEVICEMANAGER_README.md`
- **Implementation Details:** `PR93_IMPLEMENTATION_SUMMARY.md`
- **Conversation Logs:** `/conversationfix` and `/conversationworkbookstests`
- **Related PR:** #93

---

## 💡 Pro Tips

1. **Click Action IDs** in tables to auto-populate tracking/cancellation fields
2. **Use filters** in tables to find specific devices or actions
3. **Sort by Created** to see most recent actions first
4. **Set auto-refresh to 30s** for active monitoring
5. **Check pending actions** before executing to avoid 400 errors
6. **Use device inventory** to identify high-risk devices
7. **Export tables** using browser tools for reporting

---

**Version:** 1.0  
**Last Updated:** 2025-10-16  
**Author:** akefallonitis
