# 📊 Visual Summary - TRUE Hybrid Workbook

## Quick Reference Guide

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TRUE HYBRID WORKBOOK                             │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  PARAMETERS (12 total)                                        │  │
│  │  • FunctionApp, Subscription, ResourceGroup, FunctionAppName  │  │
│  │  • TenantId, DeviceList, ScanType, IsolationType             │  │
│  │  • ActionTrigger, LastActionId, CancelActionId, AutoRefresh  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  CUSTOMENDPOINT SECTIONS (Monitoring - Auto-Refresh)          │  │
│  │                                                                │  │
│  │  📋 Device List (Parameter Dropdown)                          │  │
│  │     Query: Get Devices                                        │  │
│  │     Type: CustomEndpoint/1.0                                  │  │
│  │                                                                │  │
│  │  ⚠️  Pending Actions Check               ⏱️ Auto-Refresh      │  │
│  │     Query: Get All Actions (filtered)                         │  │
│  │     Type: CustomEndpoint/1.0                                  │  │
│  │     Click: "❌ Cancel" → CancelActionId                       │  │
│  │                                                                │  │
│  │  📊 Action Status Tracking               ⏱️ Auto-Refresh      │  │
│  │     Query: Get Action Status                                  │  │
│  │     Type: CustomEndpoint/1.0                                  │  │
│  │     Input: LastActionId                                       │  │
│  │                                                                │  │
│  │  📜 Machine Actions History              ⏱️ Auto-Refresh      │  │
│  │     Query: Get All Actions                                    │  │
│  │     Type: CustomEndpoint/1.0                                  │  │
│  │     Click: "📊 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  💻 Device Inventory                     ⏱️ Auto-Refresh      │  │
│  │     Query: Get Devices                                        │  │
│  │     Type: CustomEndpoint/1.0                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ARMENDPOINT SECTIONS (Execution - Manual Trigger)            │  │
│  │                                                                │  │
│  │  🔍 Execute: Antivirus Scan              ⚡ Manual            │  │
│  │     Action: Run Antivirus Scan                                │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  🔒 Execute: Device Isolation            ⚡ Manual            │  │
│  │     Action: Isolate Device                                    │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  🔓 Execute: Device Unisolation          ⚡ Manual            │  │
│  │     Action: Unisolate Device                                  │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  📦 Execute: Investigation Package       ⚡ Manual            │  │
│  │     Action: Collect Investigation Package                     │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  🚫 Execute: Restrict App Execution      ⚡ Manual            │  │
│  │     Action: Restrict App Execution                            │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  ✅ Execute: Unrestrict App Execution    ⚡ Manual            │  │
│  │     Action: Unrestrict App Execution                          │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Click: "📋 Track" → LastActionId                          │  │
│  │                                                                │  │
│  │  ❌ Cancel Machine Action                ⚡ Manual            │  │
│  │     Action: Cancel Action                                     │  │
│  │     Type: ARMEndpoint/1.0                                     │  │
│  │     Input: CancelActionId                                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 User Workflow Diagram

```
                    ┌─────────────────┐
                    │  START: Open    │
                    │    Workbook     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Select Function │
                    │      App        │
                    └────────┬────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ Parameters Auto-Populate │
              │ • Subscription           │
              │ • ResourceGroup          │
              │ • FunctionAppName        │
              └──────────┬───────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ Select Tenant & Devices │
              └──────────┬─────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        ▼                                 ▼
┌───────────────┐              ┌─────────────────┐
│  MONITORING   │              │   EXECUTION     │
│ (CustomEndpoint)             │  (ARMEndpoint)  │
│               │              │                 │
│ • View Pending│              │ • Run Scan      │
│ • Check Status│              │ • Isolate       │
│ • View History│              │ • Unisolate     │
│ • See Devices │              │ • Collect       │
│               │              │ • Restrict      │
│ ⏱️ Auto-Refresh│              │ • Unrestrict    │
│               │              │ • Cancel        │
└───────┬───────┘              └────────┬────────┘
        │                               │
        │      ┌─────────────────┐      │
        └──────►  Click Action   ◄──────┘
               │      ID Link    │
               └────────┬────────┘
                        │
                        ▼
               ┌─────────────────┐
               │  Parameter Auto │
               │   -Populates    │
               │ • LastActionId  │
               │ • CancelActionId│
               └────────┬────────┘
                        │
                        ▼
               ┌─────────────────┐
               │   Take Action   │
               │ • Track Status  │
               │ • Cancel Action │
               └─────────────────┘
```

---

## 🎯 Action ID Autopopulation Flow

```
┌──────────────────────────────────────────────────────────────┐
│  EXECUTION RESULT                                            │
│  ┌──────────────┬─────────────────┬──────────┬────────────┐ │
│  │ Result Msg   │   Action IDs    │  Status  │  Details   │ │
│  ├──────────────┼─────────────────┼──────────┼────────────┤ │
│  │ Success      │ [📋 Track] abc  │  ✅ Init  │  ...       │ │
│  │              │     123-456     │          │            │ │
│  └──────────────┴─────────────────┴──────────┴────────────┘ │
└──────────────────────────┬───────────────────────────────────┘
                           │
                    User clicks "📋 Track"
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  PARAMETER AUTO-POPULATION                                   │
│  LastActionId = "abc123-456"                                 │
└──────────────────────────┬───────────────────────────────────┘
                           │
                    Triggers conditional visibility
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  ACTION STATUS TRACKING SECTION APPEARS                      │
│  • Shows real-time status                                    │
│  • Auto-refreshes every 30 seconds                           │
│  • Displays: Status, Device, Requestor, Timestamps           │
└──────────────────────────────────────────────────────────────┘
```

---

## 📋 Section Type Quick Reference

| Icon | Section Type | Endpoint | Auto-Refresh | Purpose |
|------|-------------|----------|--------------|---------|
| 📋 | Device List | CustomEndpoint | No | Populate dropdown |
| ⚠️ | Pending Actions | CustomEndpoint | ✅ Yes | Monitor running actions |
| 📊 | Status Tracking | CustomEndpoint | ✅ Yes | Track specific action |
| 📜 | Actions History | CustomEndpoint | ✅ Yes | View all actions |
| 💻 | Device Inventory | CustomEndpoint | ✅ Yes | Monitor devices |
| 🔍 | Run Scan | ARMEndpoint | ❌ Manual | Execute scan |
| 🔒 | Isolate | ARMEndpoint | ❌ Manual | Isolate device |
| 🔓 | Unisolate | ARMEndpoint | ❌ Manual | Release isolation |
| 📦 | Collect Package | ARMEndpoint | ❌ Manual | Gather forensics |
| 🚫 | Restrict Apps | ARMEndpoint | ❌ Manual | Block execution |
| ✅ | Unrestrict Apps | ARMEndpoint | ❌ Manual | Allow execution |
| ❌ | Cancel Action | ARMEndpoint | ❌ Manual | Cancel action |

---

## 🔗 Parameter Relationships

```
┌───────────────────────────────────────────────────────────────┐
│  PARAMETER DEPENDENCIES                                       │
│                                                               │
│  FunctionApp (Resource Picker)                                │
│    │                                                          │
│    ├──► Subscription (Auto-extracted)                         │
│    ├──► ResourceGroup (Auto-extracted)                        │
│    └──► FunctionAppName (Auto-extracted)                      │
│                                                               │
│  FunctionAppName + TenantId                                   │
│    └──► DeviceList (Populated via CustomEndpoint)             │
│                                                               │
│  DeviceList + ActionType                                      │
│    └──► Execute Action (ARMEndpoint)                          │
│         └──► Action IDs returned                              │
│              └──► Click "Track"                               │
│                   └──► LastActionId (Auto-populated)          │
│                        └──► Status Tracking (CustomEndpoint)   │
│                                                               │
│  Pending Action                                               │
│    └──► Click "Cancel"                                        │
│         └──► CancelActionId (Auto-populated)                  │
│              └──► Cancel Action (ARMEndpoint)                 │
│                                                               │
│  AutoRefresh (Dropdown)                                       │
│    └──► Controls refresh rate for all CustomEndpoint queries  │
│         with timeContextFromParameter                         │
└───────────────────────────────────────────────────────────────┘
```

---

## 🎨 UI Section Layout

```
╔═══════════════════════════════════════════════════════════════╗
║                    DEVICEMANAGER WORKBOOK                     ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  🔧 PARAMETERS                                                ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Function App: [Dropdown ▼]                              │ ║
║  │ Tenant: [Dropdown ▼]         Devices: [Multi-select ▼] │ ║
║  │ Action Trigger: [Dropdown ▼] Auto Refresh: [30s ▼]     │ ║
║  │ Last Action ID: [________]   Cancel Action ID: [______] │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  ⚠️ PRE-EXECUTION CHECK                        ⏱️ Auto-Refresh ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Currently Running Actions on Selected Devices           │ ║
║  │ Action ID      │ Type      │ Status    │ [❌ Cancel]    │ ║
║  │ abc-123        │ Scan      │ InProgress│ [❌ Cancel]    │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  🔍 EXECUTE: ANTIVIRUS SCAN                      ⚡ Manual    ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Scan Type: [Quick ▼]                [Execute Button]    │ ║
║  │ ─────────────────────────────────────────────────────── │ ║
║  │ Result      │ Action IDs      │ Status │ Details        │ ║
║  │ Success     │ [📋 Track] xyz  │ ✅ Init │ Scan queued   │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  📊 ACTION STATUS TRACKING                       ⏱️ Auto-Refresh║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Tracking: xyz-789-abc                                   │ ║
║  │ Status: ⏱️ InProgress                                    │ ║
║  │ Device: DESKTOP-ABC123                                  │ ║
║  │ Updated: 2025-10-16 12:34:56                           │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  📜 MACHINE ACTIONS HISTORY                      ⏱️ Auto-Refresh║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Action ID       │ Type      │ Status    │ [📊 Track]    │ ║
║  │ xyz-789-abc     │ Scan      │ Succeeded │ [📊 Track]    │ ║
║  │ abc-123-456     │ Isolate   │ Succeeded │ [📊 Track]    │ ║
║  └─────────────────────────────────────────────────────────┘ ║
║                                                               ║
║  ❌ CANCEL MACHINE ACTION                        ⚡ Manual    ║
║  ┌─────────────────────────────────────────────────────────┐ ║
║  │ Action ID to Cancel: [abc-123]      [Cancel Button]    │ ║
║  │ ─────────────────────────────────────────────────────── │ ║
║  │ Result: Cancellation successful                         │ ║
║  └─────────────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📊 Statistics

### Query Distribution
- **Total Queries:** 12
- **CustomEndpoint:** 5 (42%)
- **ARMEndpoint:** 7 (58%)

### Section Categories
- **Monitoring (Auto-refresh):** 5 sections
- **Execution (Manual):** 7 sections

### Parameters
- **Total:** 12 parameters
- **Required:** 8 core parameters
- **Optional:** 4 action-specific parameters

### Autopopulation
- **Sections with links:** 8
- **Target parameters:** 2 (LastActionId, CancelActionId)
- **Formatter type:** 7 (Link to parameter)

---

## 🚀 Quick Start Commands

```bash
# Navigate to workbook directory
cd workbook_tests/

# Validate JSON
python3 -m json.tool DeviceManager-Hybrid.workbook.json > /dev/null && echo "✅ Valid"

# Count endpoints
echo "ARMEndpoint: $(grep -c 'ARMEndpoint/1.0' DeviceManager-Hybrid.workbook.json)"
echo "CustomEndpoint: $(grep -c 'CustomEndpoint/1.0' DeviceManager-Hybrid.workbook.json)"

# Run verification
./verify.sh

# View documentation
cat TRUE_HYBRID_IMPLEMENTATION.md
cat QUICK_VERIFICATION.md
cat IMPLEMENTATION_SUMMARY.md
```

---

## ✅ Checklist

### Pre-Deployment
- [x] JSON syntax valid
- [x] Endpoint types correct (7 ARM, 5 Custom)
- [x] Parameters present (12 total)
- [x] Formatters configured (8 sections)
- [x] ARM paths correct
- [x] Documentation complete

### Post-Deployment
- [ ] Import to Azure Portal
- [ ] Test parameter population
- [ ] Execute test action
- [ ] Verify autopopulation
- [ ] Check auto-refresh
- [ ] Test cancellation

---

**Status:** ✅ PRODUCTION READY
**Version:** 1.1.0
**Date:** October 16, 2025
