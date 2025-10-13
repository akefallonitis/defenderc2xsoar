# Quick Fix: Parameter Substitution Not Working

## The Problem
✅ Device dropdowns work  
❌ Everything else shows undefined or empty parameters

## The Solution (1 Line Per Parameter)

### DefenderC2-Workbook.json
Add `"isGlobal": true` to these parameters:
```json
{ "name": "FunctionApp", "isGlobal": true, ... }
{ "name": "Workspace", "isGlobal": true, ... }
{ "name": "Subscription", "isGlobal": true, ... }
{ "name": "ResourceGroup", "isGlobal": true, ... }
{ "name": "FunctionAppName", "isGlobal": true, ... }
{ "name": "TenantId", "isGlobal": true, ... }
```

### FileOperations.workbook
Add `"isGlobal": true` to these parameters:
```json
{ "name": "Workspace", "isGlobal": true, ... }
{ "name": "FunctionAppName", "isGlobal": true, ... }
{ "name": "TenantId", "isGlobal": true, ... }
```

## Why This Works
Azure Workbooks have **parameter scoping**:
- **Local** (default): Only works in same group
- **Global** (`isGlobal: true`): Works everywhere in workbook

Your workbook has nested groups → needs global parameters!

## Test It
```bash
python3 scripts/verify_workbook_config.py
# Should show: ✅ Global Parameters: 6/6 marked as global
```

## Full Documentation
See [GLOBAL_PARAMETERS_FIX.md](GLOBAL_PARAMETERS_FIX.md)
