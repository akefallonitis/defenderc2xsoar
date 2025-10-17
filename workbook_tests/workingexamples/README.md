# Working Examples - Base Workbook Templates

This directory contains the original base workbook templates that were used to design the DefenderC2 workbooks.

## Files

### base-no-arm.workbook.json
**Original workbook without ARM actions** - This template contains the structure and layout for a workbook that uses only CustomEndpoint queries. It includes:
- Parameter definitions
- Device list displays
- Action result displays
- Machine actions history
- Device inventory

**Note:** This workbook has **NO ARM action buttons**. It was designed to show the structure without execution capabilities.

### base-with-arm.workbook.json
**Simple workbook with 3 ARM actions** - This template demonstrates basic ARM action integration with:
- ✅ Isolate Device ARM action
- ✅ Unisolate Device ARM action  
- ✅ Run Antivirus Scan ARM action

This template shows the minimal ARM action structure needed for execution.

### INSTRUCTIONS.txt
Original requirements for the two workbook implementations:
1. **CustomEndpoint-Only version**: Only CustomEndpoints with autorefresh, autopopulation, and machine action list/get/cancel/run
2. **Hybrid version**: CustomEndpoints for autorefreshed sections (action list, get) + ARM actions for manual input machine actions (run, cancel)

## Current Implementation Status

The requirements from these templates have been implemented in the parent directory:

- ✅ `DeviceManager-CustomEndpoint-Only.workbook.json` - Implements requirement #1
- ⚠️ `DeviceManager-Hybrid.workbook.json` - **MISSING ARM ACTIONS** (needs to implement requirement #2)
- ✅ `DeviceManager-Hybrid-CustomEndpointOnly.workbook.json` - Alternative hybrid with CustomEndpoints only

## Known Issues

### DeviceManager-Hybrid.workbook.json
According to the README in the parent directory, this workbook should have ARM actions for:
- 🔍 Run Antivirus Scan
- 🔒 Isolate Device
- 🔓 Unisolate Device
- 📦 Collect Investigation Package
- 🚫 Restrict App Execution
- ✅ Unrestrict App Execution
- ❌ Cancel Action

**Current Status:** This workbook has 0 ARM actions (verified with `grep -c "armAction"`).

The workbook needs ARM action buttons added to the execution groups while keeping CustomEndpoint queries for monitoring.

## Usage

These templates are for reference and development purposes. For production use, refer to the implemented workbooks in the parent directory.

## Related Documentation

- Parent directory README: `../README.md`
- Main workbook documentation: `../../workbook/README.md`
- Deployment guide: `../../DEPLOYMENT.md`
