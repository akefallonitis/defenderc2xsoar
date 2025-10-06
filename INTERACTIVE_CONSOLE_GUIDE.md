# Interactive Console Feature Guide

## Overview

The Interactive Console is a new feature added to the MDE Automator Workbook that provides a shell-like interface for executing MDE commands asynchronously with automatic result polling and JSON parsing.

## What's New

### 🖥️ Interactive Console Tab

A dedicated tab in the main workbook (`MDEAutomatorWorkbook.json`) that provides:

1. **Async Command Execution** - Commands run in the background via Azure Function App
2. **Auto-Polling** - Automatic status checking with configurable refresh intervals
3. **JSON Parsing** - Response data automatically parsed and displayed in table format
4. **Multi-Action Support** - Execute device actions, queries, and API calls
5. **Result History** - Track command execution history and results
6. **Visual Status Indicators** - Real-time status updates with emojis (✅ Succeeded, ⏳ InProgress, ⏸️ Pending, ❌ Failed)

## Features

### Configuration Options

- **Auto Refresh Interval**: Choose from:
  - 🟢 10 seconds (fast polling)
  - 🟢 30 seconds (recommended)
  - 🟡 1 minute (moderate)
  - 🔵 5 minutes (slow)
  - 🔴 Manual Only (no auto-refresh)

- **Command Types**:
  - 🎯 Device Actions (Isolate, Scan, etc.)
  - 🔍 Advanced Hunting Query
  - 📍 Threat Intelligence
  - 🚨 Incident Management
  - 🛡️ Custom Detection

- **Actions/Commands**:
  - Isolate/Unisolate Device
  - Run Antivirus Scan
  - Collect Investigation Package
  - Restrict/Unrestrict App Execution
  - Stop & Quarantine File
  - Run Live Response Script
  - Get/Put File (Live Response)

### Workflow

The Interactive Console uses a three-step workflow:

#### Step 1: Execute Command
- Select command type and action
- Enter target device IDs (comma-separated)
- Add optional JSON parameters
- Click "Run Query" to submit

#### Step 2: Poll for Results
- Automatic polling starts immediately
- Status updates at configured interval
- Visual indicators show progress
- No manual intervention needed

#### Step 3: View Results
- Parsed JSON displayed in table format
- Export to Excel available
- Structured data for easy analysis

### Additional Features

- **Command History**: Track last 20 executions with timestamps and status
- **Conditional Visibility**: Results only show when data is available
- **Error Handling**: Clear error messages and status indicators
- **Audit Trail**: Complete execution history for compliance

## How It Works

### Architecture

```
User Interface (Workbook)
    ↓
    ↓ [Execute Command]
    ↓
Azure Function App (DefenderC2Dispatcher)
    ↓
    ↓ [Managed Identity Auth]
    ↓
Microsoft Defender for Endpoint API
    ↓
    ↓ [Async Execution]
    ↓
Function App Polls Status
    ↓
    ↓ [Auto-refresh]
    ↓
Results Displayed in Workbook
```

### Key Components

1. **Parameters Section**: Configurable settings for command execution
2. **Execute Query**: ARM Endpoint call to Function App
3. **Poll Status**: Auto-refreshing status check
4. **Results Display**: Parsed JSON in table format
5. **History View**: Audit trail of executions

## Usage Examples

### Example 1: Isolate a Device

1. Navigate to **🖥️ Interactive Console** tab
2. Set **Auto Refresh Interval**: `30 seconds`
3. Select **Command Type**: `Device Actions`
4. Select **Action/Command**: `Isolate Device`
5. Enter **Target Device IDs**: `device-id-1,device-id-2`
6. Click **Run Query**
7. Watch automatic status updates
8. View results when complete

### Example 2: Run Advanced Hunting

1. Select **Command Type**: `Advanced Hunting Query`
2. Enter **Command Params**:
   ```json
   {
     "query": "DeviceProcessEvents | where Timestamp > ago(1h) | take 100",
     "name": "Recent Process Events"
   }
   ```
3. Click **Run Query**
4. Results auto-populate when ready

### Example 3: Manage Threat Intelligence

1. Select **Command Type**: `Threat Intelligence`
2. Select **Action/Command**: Based on TI operation
3. Add **Command Params** with indicator details
4. Execute and monitor progress

## Benefits

### For Security Analysts

- ✅ **Faster Response**: No waiting for manual status checks
- ✅ **Better Visibility**: Real-time status and visual indicators
- ✅ **Easier Tracking**: Complete execution history
- ✅ **Structured Results**: JSON parsed into readable tables

### For SOC Teams

- ✅ **Audit Trail**: Complete command history
- ✅ **Multi-tenant**: Works across different tenants
- ✅ **Batch Operations**: Process multiple devices at once
- ✅ **Export Capability**: Results exportable to Excel

### For Administrators

- ✅ **No Manual Polling**: Reduces workload
- ✅ **Configurable**: Adjust refresh rates as needed
- ✅ **Integrated**: Part of existing workbook
- ✅ **Secure**: Uses managed identity authentication

## Technical Details

### Function App Integration

The Interactive Console makes ARM Endpoint calls to the Function App:

```
POST {FunctionAppUrl}/api/DefenderC2Dispatcher
Parameters:
  - tenantId: {TenantId}
  - spnId: {SpnId}
  - action: {CommandType}
  - actionName: {ActionName}
  - deviceIds: {DeviceIds}
  - params: {CommandParams}
```

### Auto-Refresh Mechanism

The workbook uses built-in auto-refresh capabilities with configurable intervals. Status queries execute automatically without user intervention.

### Result Parsing

Results are transformed using JSON path transformers to extract relevant fields and display in table format with appropriate formatting.

## Configuration Requirements

To use the Interactive Console, ensure:

1. **Function App Deployed**: Azure Function App with DefenderC2Dispatcher endpoint
2. **Parameters Configured**: 
   - TenantId (target tenant)
   - FunctionAppUrl (Function App base URL)
   - SpnId (Service Principal ID)
3. **Permissions Granted**: Function App has required MDE API permissions
4. **Managed Identity**: System-assigned identity configured and linked

## Troubleshooting

### No Results Showing

- Check that Action ID parameter is populated
- Verify Function App is running
- Check Function App logs in Application Insights
- Ensure correct tenant ID and SPN ID

### Status Not Updating

- Verify auto-refresh interval is not set to "Manual Only"
- Check browser console for errors
- Ensure Function App is accessible
- Verify CORS settings allow Azure Portal

### Command Execution Fails

- Validate device IDs are correct
- Check Function App has proper permissions
- Verify managed identity is configured
- Review Function App logs for errors

## Best Practices

1. **Use 30-second refresh** for active monitoring
2. **Use 5-minute refresh** for long-running operations
3. **Review history regularly** for audit purposes
4. **Export results** for further analysis
5. **Test with single device** before bulk operations
6. **Monitor Function App logs** during troubleshooting

## Comparison with Original Examples

The Interactive Console integrates concepts from `DefenderC2 Advanced Console.json` but is adapted for the MDE Automator architecture:

| Feature | DefenderC2 Console | Interactive Console |
|---------|-------------------|---------------------|
| Async Execution | ✅ via Logic Apps | ✅ via Function App |
| Auto-Polling | ✅ | ✅ |
| JSON Parsing | ✅ | ✅ |
| Multi-Action | ❌ (MDE only) | ✅ (All operations) |
| History Tracking | ❌ | ✅ |
| Export Results | ❌ | ✅ |
| Managed Identity | ❌ | ✅ |
| Multi-tenant | ❌ | ✅ |

## Future Enhancements

Potential improvements for future versions:

- [ ] Real-time notifications when commands complete
- [ ] Bulk import of device IDs from CSV
- [ ] Command templates/favorites
- [ ] Progress bar for long-running operations
- [ ] Advanced filtering of history
- [ ] Custom time ranges for history
- [ ] Integration with Teams/Slack for notifications
- [ ] Command scheduling capabilities

## Related Documentation

- [Main README](README.md) - Project overview and setup
- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide
- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [WORKBOOK_EXAMPLES.md](WORKBOOK_EXAMPLES.md) - Other workbook examples
- [deployment/README.md](deployment/README.md) - ARM template documentation

## Support

For issues or questions about the Interactive Console:

1. Check this guide first
2. Review [TROUBLESHOOTING](DEPLOYMENT.md#troubleshooting) section
3. Check Function App logs in Application Insights
4. Review existing GitHub issues
5. Open a new issue with details

---

**Note**: The Interactive Console requires an Azure Function App deployment to be functional. Ensure you've completed all deployment steps before using this feature.
