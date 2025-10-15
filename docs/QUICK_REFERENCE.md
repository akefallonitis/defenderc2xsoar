# DefenderC2 XSOAR - Quick Reference Card

> **⚡ Ultra-fast reference for "where is the functionality?"**

## 🎯 Quick Lookup Table

| **What I want to do** | **Where to find it** | **File location** |
|----------------------|---------------------|-------------------|
| Isolate a device | DefenderC2Dispatcher | `/functions/DefenderC2Dispatcher/run.ps1` |
| Run antivirus scan | DefenderC2Dispatcher | `/functions/DefenderC2Dispatcher/run.ps1` |
| Block a file hash | DefenderC2TIManager | `/functions/DefenderC2TIManager/run.ps1` |
| Block an IP address | DefenderC2TIManager | `/functions/DefenderC2TIManager/run.ps1` |
| Execute KQL query | DefenderC2HuntManager | `/functions/DefenderC2HuntManager/run.ps1` |
| Manage incidents | DefenderC2IncidentManager | `/functions/DefenderC2IncidentManager/run.ps1` |
| Create detection rule | DefenderC2CDManager | `/functions/DefenderC2CDManager/run.ps1` |
| Upload file to device | DefenderC2Orchestrator | `/functions/DefenderC2Orchestrator/run.ps1` (line 255) |
| Download file from device | DefenderC2Orchestrator | `/functions/DefenderC2Orchestrator/run.ps1` (line 200) |
| Run script on device | DefenderC2Orchestrator | `/functions/DefenderC2Orchestrator/run.ps1` (line 142) |
| Manage file library | DefenderC2Orchestrator | `/functions/DefenderC2Orchestrator/run.ps1` (line 419) |

---

## 🔍 The 6 Azure Functions

```
┌────────────────────────────────────────────────────────────┐
│                    Azure Functions                          │
│                   /functions/ directory                     │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  1️⃣  DefenderC2Dispatcher      → Device Actions           │
│      • Isolate/Unisolate                                    │
│      • Scan/Restrict/Collect                                │
│      • Action management                                    │
│                                                             │
│  2️⃣  DefenderC2TIManager        → Threat Intelligence      │
│      • File indicators (hashes)                             │
│      • Network indicators (IPs, URLs, domains)              │
│      • Certificate indicators                               │
│                                                             │
│  3️⃣  DefenderC2HuntManager      → Advanced Hunting         │
│      • Execute KQL queries                                  │
│      • Save/manage hunt results                             │
│                                                             │
│  4️⃣  DefenderC2IncidentManager  → Incident Management      │
│      • List/filter incidents                                │
│      • Update status/classification                         │
│                                                             │
│  5️⃣  DefenderC2CDManager        → Custom Detections        │
│      • Create/update/delete rules                           │
│      • Backup detections                                    │
│                                                             │
│  6️⃣  DefenderC2Orchestrator     → Live Response & Files    │
│      • Upload/download files                                │
│      • Run scripts on devices                               │
│      • Library management                                   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 📂 Directory Structure (30 Second Guide)

```
defenderc2xsoar/
│
├── functions/                  ← 🔧 ALL BACKEND CODE HERE
│   ├── DefenderC2Dispatcher/   ← Device actions
│   ├── DefenderC2TIManager/    ← Threat intel
│   ├── DefenderC2HuntManager/  ← Hunting
│   ├── DefenderC2IncidentManager/ ← Incidents
│   ├── DefenderC2CDManager/    ← Detections
│   ├── DefenderC2Orchestrator/ ← Live Response
│   └── profile.ps1             ← Shared helpers
│
├── workbook/                   ← 🎨 ALL UI CODE HERE
│   └── DefenderC2-Workbook.json
│
├── deployment/                 ← 🚀 ARM TEMPLATES
│   └── azuredeploy.json
│
├── FUNCTIONALITY_REFERENCE.md  ← 📖 DETAILED MAPPING
└── README.md                   ← 📋 START HERE
```

---

## ⚡ Common Operations

### Find a function's code
```bash
# Pattern: /functions/{FunctionName}/run.ps1
cat /functions/DefenderC2Dispatcher/run.ps1
```

### Test a function locally
```powershell
$body = @{ action = "Get Devices"; tenantId = "your-tid" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://your-app.azurewebsites.net/api/DefenderC2Dispatcher" -Method Post -Body $body -ContentType "application/json"
```

### Find workbook code
```bash
# The workbook JSON: /workbook/DefenderC2-Workbook.json
# Search for button labels to find ARM actions
```

---

## 🔗 Full Documentation

For complete details, see:
- **[FUNCTIONALITY_REFERENCE.md](../FUNCTIONALITY_REFERENCE.md)** - Complete feature mapping
- **[archive/technical-docs/FUNCTIONS_REFERENCE.md](../archive/technical-docs/FUNCTIONS_REFERENCE.md)** - Full API docs
- **[README.md](../README.md)** - Project overview
- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Deployment guide

---

## 🎯 Decision Tree: "Where do I go?"

```
┌─────────────────────────────────────┐
│  What do you need to do?            │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
   Need code?      Need docs?
       │                │
       ▼                ▼
   /functions/    FUNCTIONALITY_REFERENCE.md
       │                │
   Pick one:            └─→ Full API docs:
   ├─ Dispatcher              archive/technical-docs/
   ├─ TIManager               FUNCTIONS_REFERENCE.md
   ├─ HuntManager
   ├─ IncidentManager
   ├─ CDManager
   └─ Orchestrator
```

---

**Need help?** → Start with [FUNCTIONALITY_REFERENCE.md](../FUNCTIONALITY_REFERENCE.md)
