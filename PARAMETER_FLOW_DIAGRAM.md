# 📊 Parameter Waiting & Auto-Refresh Flow Diagram

## 🔄 Complete Parameter Dependency Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                                │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  Select Function App  │
                        │   (Type 5 - Manual)   │
                        └───────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      AUTO-DISCOVERY PHASE                                │
│                   (criteriaData: [{FunctionApp}])                        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │ Subscription│ │ Resource    │ │ Function    │
            │             │ │ Group       │ │ App Name    │
            │ (Type 1)    │ │ (Type 1)    │ │ (Type 1)    │
            └─────────────┘ └─────────────┘ └─────────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │   TenantId Query      │
                        │   (Type 2 Dropdown)   │
                        │ selectFirstItem: true │
                        └───────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │ TenantId = "actual-id"│
                        │  (Auto-Selected)      │
                        └───────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────┐
│                    ⚠️  CONDITIONAL VISIBILITY CHECK                      │
│                                                                           │
│   conditionalVisibility: {                                               │
│     parameterName: "TenantId",                                           │
│     comparison: "isNotEqualTo",                                          │
│     value: ""                                                            │
│   }                                                                      │
│                                                                           │
│   ✅ TenantId has value → SHOW sections below                           │
│   ❌ TenantId is empty  → HIDE sections below                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      DEVICE QUERY PHASE                                  │
│        (criteriaData: [{FunctionApp}, {FunctionAppName}, {TenantId}])   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
        ┌───────────────────────┐       ┌───────────────────────┐
        │  DeviceList Parameter │       │  Device Grid Display  │
        │  (Type 10 CustomEP)   │       │  (Type 3, QueryType10)│
        │                       │       │                       │
        │  POST to Function:    │       │  Same query           │
        │  ?action=Get Devices  │       │  Shows table          │
        │  &tenantId={TenantId} │       │                       │
        └───────────────────────┘       └───────────────────────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  Devices Populated    │
                        │  User selects devices │
                        └───────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ARM ACTIONS AVAILABLE                               │
│     (criteriaData: [FunctionApp, TenantId, DeviceList,                  │
│                     Subscription, ResourceGroup, FunctionAppName])       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │   Isolate   │ │  Unisolate  │ │ Antivirus   │
            │   Devices   │ │   Devices   │ │    Scan     │
            │  (Type 11)  │ │  (Type 11)  │ │  (Type 11)  │
            └─────────────┘ └─────────────┘ └─────────────┘
```

---

## 🔄 Auto-Refresh Trigger Flow

### Scenario 1: User Changes TenantId

```
User selects different TenantId in dropdown
            │
            ▼
Azure Workbooks detects parameter change
            │
            ▼
Scans all components for criteriaData containing {TenantId}
            │
            ├──> DeviceList Parameter (has {TenantId} in criteriaData)
            │            │
            │            ▼
            │    Re-execute CustomEndpoint query with new TenantId
            │            │
            │            ▼
            │    DeviceList refreshes with new tenant's devices
            │
            ├──> Device Grid Display (has {TenantId} in criteriaData)
            │            │
            │            ▼
            │    Re-execute CustomEndpoint query with new TenantId
            │            │
            │            ▼
            │    Device Grid refreshes with new device table
            │
            └──> ARM Actions (have {TenantId} in criteriaData)
                         │
                         ▼
                 Parameter substitution updates
                         │
                         ▼
                 ARM action URLs ready with new TenantId
```

### Scenario 2: User Changes FunctionApp

```
User selects different Function App
            │
            ▼
Azure Workbooks detects parameter change
            │
            ▼
Scans all components for criteriaData containing {FunctionApp}
            │
            ├──> Subscription Parameter (has {FunctionApp} in criteriaData)
            │            │
            │            ▼
            │    Re-execute auto-discovery query
            │            │
            │            ▼
            │    Subscription updates
            │
            ├──> ResourceGroup Parameter (has {FunctionApp} in criteriaData)
            │            │
            │            ▼
            │    Re-execute auto-discovery query
            │            │
            │            ▼
            │    ResourceGroup updates
            │
            ├──> FunctionAppName Parameter (has {FunctionApp} in criteriaData)
            │            │
            │            ▼
            │    Re-execute auto-discovery query
            │            │
            │            ▼
            │    FunctionAppName updates
            │
            ├──> TenantId Parameter (indirectly via Azure context)
            │            │
            │            ▼
            │    Re-query available tenants
            │            │
            │            ▼
            │    Auto-select first tenant (selectFirstItem: true)
            │            │
            │            ▼
            │    Triggers DeviceList refresh (see Scenario 1)
            │
            └──> DeviceList Parameter (has {FunctionApp} in criteriaData)
                         │
                         ▼
                 Re-execute CustomEndpoint query
                         │
                         ▼
                 DeviceList refreshes
```

---

## ⏱️ Timing Sequence (What Waits for What)

### Phase 1: Initial Load

```
Time    Event                               Visible to User
─────────────────────────────────────────────────────────────────
T+0     Workbook opens                      FunctionApp picker
T+0                                          Parameters section (collapsed)
T+0                                          [Device sections HIDDEN]

T+1     User selects FunctionApp            FunctionApp shows selected value
T+1                                          Parameters section expands

T+2     Auto-discovery queries execute      Loading spinners on:
                                            - Subscription
                                            - ResourceGroup
                                            - FunctionAppName
                                            - TenantId

T+3     Auto-discovery completes            Values populate:
                                            - Subscription: "12345..."
                                            - ResourceGroup: "rg-sentinel"
                                            - FunctionAppName: "func-defender"
                                            - TenantId: Auto-selects first

T+4     Conditional visibility triggers     [Device sections APPEAR]
                                            "Device Actions" header visible
                                            "Connected Devices" header visible

T+5     DeviceList query executes           Loading spinner on Device List
                                            Loading spinner on Device Grid

T+6     DeviceList query completes          Device List dropdown populates
                                            Device Grid table displays

T+7     User selects devices                ARM action buttons become active

T+8     User clicks "Isolate Devices"       ARM action blade opens
                                            Parameters pre-filled
```

### Phase 2: Parameter Change (Auto-Refresh)

```
Time    Event                               Visible to User
─────────────────────────────────────────────────────────────────
T+0     User changes TenantId dropdown      Dropdown shows new selection

T+0     criteriaData triggers refresh       Device List: loading spinner
                                            Device Grid: loading spinner

T+1     CustomEndpoint queries execute      Function receives new tenantId

T+2     Queries complete                    Device List: new devices
                                            Device Grid: new device table

T+2     Previous device selection cleared   ARM actions disabled (no selection)
```

---

## 🛡️ Conditional Visibility Protection

### Without Conditional Visibility (BEFORE)

```
┌─────────────────────────────────────────────────────────────────┐
│  T+0: Workbook loads                                            │
│  ├─ All sections visible immediately                            │
│  ├─ DeviceList query tries to execute                           │
│  │  └─ TenantId = "" (empty)                                    │
│  │     └─ Function URL: ?tenantId=                              │
│  │        └─ Function returns error or empty result             │
│  │           └─ DeviceList shows infinite loading spinner ❌    │
│  │                                                               │
│  └─ User sees broken UI with loading spinners forever           │
└─────────────────────────────────────────────────────────────────┘
```

### With Conditional Visibility (AFTER)

```
┌─────────────────────────────────────────────────────────────────┐
│  T+0: Workbook loads                                            │
│  ├─ Only FunctionApp picker visible                             │
│  └─ Device sections HIDDEN (conditionalVisibility check fails)  │
│                                                                  │
│  T+1: User selects FunctionApp                                  │
│  ├─ Auto-discovery runs                                         │
│  └─ TenantId auto-selects first tenant                          │
│                                                                  │
│  T+2: TenantId has value                                        │
│  ├─ conditionalVisibility check PASSES ✅                       │
│  ├─ Device sections APPEAR                                      │
│  └─ DeviceList query executes with valid TenantId              │
│     └─ Function URL: ?tenantId=actual-tenant-id                │
│        └─ Function returns device data                          │
│           └─ DeviceList populates successfully ✅               │
│                                                                  │
│  └─ User sees clean, professional UI                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔗 CriteriaData Dependency Graph

### DeviceList Parameter Dependencies

```
DeviceList
    │
    ├─ criteriaData: [{FunctionApp}]
    │       │
    │       └─ Watches: FunctionApp
    │          └─ If changes → Re-execute query
    │
    ├─ criteriaData: [{FunctionAppName}]
    │       │
    │       └─ Watches: FunctionAppName
    │          └─ If changes → Re-execute query
    │          └─ Used in URL: https://{FunctionAppName}.azurewebsites.net/...
    │
    └─ criteriaData: [{TenantId}]
            │
            └─ Watches: TenantId
               └─ If changes → Re-execute query
               └─ Used in params: ?tenantId={TenantId}
```

### ARM Action Dependencies

```
Isolate Device Action
    │
    ├─ criteriaData: [{FunctionApp}]
    │       └─ Watches for changes (context)
    │
    ├─ criteriaData: [{Subscription}]
    │       └─ Used in path: /subscriptions/{Subscription}/...
    │
    ├─ criteriaData: [{ResourceGroup}]
    │       └─ Used in path: .../resourceGroups/{ResourceGroup}/...
    │
    ├─ criteriaData: [{FunctionAppName}]
    │       └─ Used in path: .../sites/{FunctionAppName}/...
    │
    ├─ criteriaData: [{TenantId}]
    │       └─ Used in params: ?tenantId={TenantId}
    │
    └─ criteriaData: [{DeviceList}]
            └─ Used in params: ?deviceIds={DeviceList}
```

---

## 📋 Key Takeaways

### ✅ What Makes This Work

1. **Complete criteriaData** - Every query lists ALL its dependencies
2. **Conditional visibility** - Sections only appear when params ready
3. **selectFirstItem: true** - TenantId auto-selects (no user action needed)
4. **Global parameters** - All params accessible across entire workbook
5. **Explicit value: null** - Clear initial state for state tracking

### ❌ What Would Break It

1. Missing parameters in criteriaData → No auto-refresh
2. No conditional visibility → Queries run too early
3. Missing selectFirstItem → TenantId never populates
4. Parameters not global → Not accessible in ARM actions
5. Wrong queryType → CustomEndpoint queries fail

---

## 🎯 Testing Checklist

Use this diagram to verify each step:

- [ ] **Phase 1 Complete**: FunctionApp → Auto-discovery → TenantId
- [ ] **Phase 2 Complete**: Sections appear (were hidden)
- [ ] **Phase 3 Complete**: DeviceList populates
- [ ] **Phase 4 Complete**: Device Grid displays
- [ ] **Auto-Refresh Test**: Change TenantId → List refreshes
- [ ] **ARM Action Test**: Select devices → Actions work

---

**Visual understanding** helps troubleshoot! Reference this diagram when debugging parameter flow issues. 🎨
