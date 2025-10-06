# Azure Functions API Reference

Complete reference for all Azure Functions in the defenderc2xsoar project.

## Base URL
```
https://<your-function-app>.azurewebsites.net/api
```

## Authentication
All functions require:
- **Environment Variables**: `APPID` and `SECRETID` configured in Function App settings
- **Request Parameters**: `tenantId` in query string or request body

## Common Response Format
```json
{
  "action": "action-name",
  "status": "Success|Initiated|Failed",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "details": "Operation description",
  "data": {}
}
```

---

## DefenderC2Dispatcher - Device Operations

**Endpoint:** `/api/DefenderC2Dispatcher`

### Isolate Device
Isolates one or more devices from the network.

**Request:**
```http
POST /api/DefenderC2Dispatcher
Content-Type: application/json

{
  "action": "Isolate Device",
  "tenantId": "tenant-id",
  "deviceIds": "device-id-1,device-id-2"
}
```

**Response:**
```json
{
  "action": "Isolate Device",
  "status": "Initiated",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "details": "Device isolation initiated for 2 device(s)",
  "actionIds": ["action-id-1", "action-id-2"]
}
```

### Unisolate Device
Releases devices from isolation.

**Request:**
```json
{
  "action": "Unisolate Device",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Restrict App Execution
Restricts application execution on devices.

**Request:**
```json
{
  "action": "Restrict App Execution",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Unrestrict App Execution
Removes application execution restrictions.

**Request:**
```json
{
  "action": "Unrestrict App Execution",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Collect Investigation Package
Collects forensic investigation package from devices.

**Request:**
```json
{
  "action": "Collect Investigation Package",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Run Antivirus Scan
Initiates antivirus scan on devices.

**Request:**
```json
{
  "action": "Run Antivirus Scan",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Stop & Quarantine File
Stops and quarantines a file across all devices.

**Request:**
```json
{
  "action": "Stop & Quarantine File",
  "tenantId": "tenant-id",
  "fileHash": "sha1-hash"
}
```

### Get Devices
Retrieves list of devices with optional filtering.

**Request:**
```json
{
  "action": "Get Devices",
  "tenantId": "tenant-id",
  "deviceFilter": "riskScore eq 'High'"
}
```

### Get Device Info
Retrieves detailed information about a specific device.

**Request:**
```json
{
  "action": "Get Device Info",
  "tenantId": "tenant-id",
  "deviceIds": "device-id"
}
```

### Get Action Status
Checks the status of a machine action.

**Request:**
```json
{
  "action": "Get Action Status",
  "tenantId": "tenant-id",
  "actionId": "action-id"
}
```

**Response:**
```json
{
  "action": "Get Action Status",
  "status": "Success",
  "details": "Retrieved action status",
  "actionStatus": {
    "id": "action-id",
    "status": "Succeeded|Failed|InProgress|Pending",
    "machineId": "device-id",
    "type": "Isolate",
    "creationDateTimeUtc": "2024-01-01T00:00:00Z"
  }
}
```

### Get All Actions
Lists all machine actions with optional filtering.

**Request:**
```json
{
  "action": "Get All Actions",
  "tenantId": "tenant-id",
  "filter": "status eq 'Pending'"
}
```

### Cancel Action
Cancels a pending machine action.

**Request:**
```json
{
  "action": "Cancel Action",
  "tenantId": "tenant-id",
  "actionId": "action-id"
}
```

---

## DefenderC2TIManager - Threat Intelligence

**Endpoint:** `/api/DefenderC2TIManager`

### Add File Indicators
Adds file hash indicators (SHA256).

**Request:**
```json
{
  "action": "Add File Indicators",
  "tenantId": "tenant-id",
  "indicators": "hash1,hash2,hash3",
  "title": "Malware Campaign X",
  "severity": "High",
  "recommendedAction": "Block"
}
```

**Parameters:**
- `severity`: Informational, Low, Medium, High
- `recommendedAction`: Alert, Block, Allowed

### Remove File Indicators
Removes file indicators by ID.

**Request:**
```json
{
  "action": "Remove File Indicators",
  "tenantId": "tenant-id",
  "indicators": "indicator-id-1,indicator-id-2"
}
```

### Add IP Indicators
Adds IP address indicators.

**Request:**
```json
{
  "action": "Add IP Indicators",
  "tenantId": "tenant-id",
  "indicators": "1.2.3.4,5.6.7.8",
  "title": "C2 Servers",
  "severity": "High",
  "recommendedAction": "Block"
}
```

### Add URL/Domain Indicators
Adds URL or domain indicators.

**Request:**
```json
{
  "action": "Add URL/Domain Indicators",
  "tenantId": "tenant-id",
  "indicators": "malicious.com,evil.net",
  "title": "Phishing Sites",
  "severity": "High",
  "recommendedAction": "Block"
}
```

### List All Indicators
Retrieves all threat indicators.

**Request:**
```json
{
  "action": "List All Indicators",
  "tenantId": "tenant-id"
}
```

---

## DefenderC2HuntManager - Advanced Hunting

**Endpoint:** `/api/DefenderC2HuntManager`

### Execute Hunt
Executes a KQL advanced hunting query.

**Request:**
```json
{
  "tenantId": "tenant-id",
  "huntQuery": "DeviceProcessEvents | where Timestamp > ago(7d) | where ProcessCommandLine has 'powershell' | take 100",
  "huntName": "Suspicious PowerShell Activity",
  "saveResults": "false"
}
```

**Response:**
```json
{
  "action": "ExecuteHunt",
  "status": "Success",
  "tenantId": "tenant-id",
  "huntName": "Suspicious PowerShell Activity",
  "timestamp": "2024-01-01T00:00:00Z",
  "details": "Hunt 'Suspicious PowerShell Activity' executed successfully",
  "resultCount": 42,
  "query": "DeviceProcessEvents | ...",
  "results": [
    {
      "Timestamp": "2024-01-01T00:00:00Z",
      "DeviceName": "DESKTOP-ABC123",
      "ProcessCommandLine": "powershell.exe -enc ..."
    }
  ]
}
```

---

## DefenderC2IncidentManager - Incident Management

**Endpoint:** `/api/DefenderC2IncidentManager`

### Get Incidents
Lists security incidents with optional filtering.

**Request:**
```json
{
  "action": "GetIncidents",
  "tenantId": "tenant-id",
  "severity": "High",
  "status": "Active"
}
```

**Parameters:**
- `severity`: Informational, Low, Medium, High
- `status`: Active, Resolved, InProgress

### Get Incident Details
Retrieves details of a specific incident.

**Request:**
```json
{
  "action": "GetIncidentDetails",
  "tenantId": "tenant-id",
  "incidentId": "incident-id"
}
```

### Update Incident
Updates incident properties.

**Request:**
```json
{
  "action": "UpdateIncident",
  "tenantId": "tenant-id",
  "incidentId": "incident-id",
  "status": "Resolved"
}
```

**Parameters:**
- `status`: Active, Resolved, InProgress
- `classification`: Unknown, FalsePositive, TruePositive
- `determination`: NotAvailable, Apt, Malware, SecurityPersonnel, SecurityTesting, UnwantedSoftware, Other

---

## DefenderC2CDManager - Custom Detections

**Endpoint:** `/api/DefenderC2CDManager`

### List All Detections
Retrieves all custom detection rules.

**Request:**
```json
{
  "action": "List All Detections",
  "tenantId": "tenant-id"
}
```

### Create Detection
Creates a new custom detection rule.

**Request:**
```json
{
  "action": "Create Detection",
  "tenantId": "tenant-id",
  "detectionName": "Suspicious PowerShell Activity",
  "detectionQuery": "DeviceProcessEvents | where ProcessCommandLine has_any ('enc', 'IEX', 'downloadstring')",
  "severity": "High"
}
```

### Update Detection
Updates an existing detection rule.

**Request:**
```json
{
  "action": "Update Detection",
  "tenantId": "tenant-id",
  "ruleId": "rule-id",
  "detectionName": "Updated Name",
  "enabled": true
}
```

### Delete Detection
Deletes a custom detection rule.

**Request:**
```json
{
  "action": "Delete Detection",
  "tenantId": "tenant-id",
  "ruleId": "rule-id"
}
```

### Backup Detections
Exports all detection rules to JSON.

**Request:**
```json
{
  "action": "Backup Detections",
  "tenantId": "tenant-id"
}
```

---

## DefenderC2Orchestrator - Live Response Operations

**Endpoint:** `/api/DefenderC2Orchestrator`

The DefenderC2Orchestrator function provides Live Response capabilities for Microsoft Defender for Endpoint, enabling file operations and script execution directly from Azure Workbooks without requiring an Azure Storage account.

### Features
- **Live Response session management** - Start, monitor, and manage sessions
- **File upload** - Upload files to devices (accepts Base64 encoded content)
- **File download** - Download files from devices (returns Base64 encoded content)
- **Script execution** - Run scripts from Live Response library
- **Command monitoring** - Get command execution results
- **Automatic retry logic** - Handles rate limiting and transient failures

### Get Live Response Sessions

Lists all active Live Response sessions.

**Request:**
```json
{
  "Function": "GetLiveResponseSessions",
  "tenantId": "tenant-id"
}
```

**Response:**
```json
{
  "function": "GetLiveResponseSessions",
  "status": "Success",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "message": "Retrieved Live Response sessions",
  "sessions": [
    {
      "id": "session-id-1",
      "machineId": "device-id-1",
      "status": "Active",
      "createdBy": "user@domain.com"
    }
  ],
  "count": 1
}
```

### Invoke Live Response Script

Executes a script from the Live Response library on a device.

**Request:**
```json
{
  "Function": "InvokeLiveResponseScript",
  "tenantId": "tenant-id",
  "DeviceIds": "device-id",
  "scriptName": "CollectLogs.ps1",
  "arguments": "arg1 arg2"
}
```

**Response:**
```json
{
  "function": "InvokeLiveResponseScript",
  "status": "Initiated",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "message": "Script execution initiated",
  "sessionId": "session-id",
  "commandId": "command-id",
  "deviceId": "device-id"
}
```

### Get Live Response Output

Retrieves the output of a previously executed command.

**Request:**
```json
{
  "Function": "GetLiveResponseOutput",
  "tenantId": "tenant-id",
  "commandId": "command-id"
}
```

**Response:**
```json
{
  "function": "GetLiveResponseOutput",
  "status": "Success",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "message": "Command result retrieved",
  "commandId": "command-id",
  "commandStatus": "Completed",
  "output": "Command output here..."
}
```

### Get Live Response File (Download)

Downloads a file from a device and returns Base64-encoded content.

**Request:**
```json
{
  "Function": "GetLiveResponseFile",
  "tenantId": "tenant-id",
  "DeviceIds": "device-id",
  "filePath": "C:\\Windows\\System32\\drivers\\etc\\hosts"
}
```

**Response:**
```json
{
  "function": "GetLiveResponseFile",
  "status": "Success",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "message": "File downloaded successfully",
  "fileName": "hosts",
  "fileContent": "IyBDb3B5cmlnaHQgKGMpIDE5OTMtMjAwOSBNaWNyb3NvZnQ...",
  "downloadUrl": "data:application/octet-stream;base64,IyBDb3B5cmlnaHQg...",
  "sessionId": "session-id",
  "deviceId": "device-id"
}
```

**Notes:**
- `downloadUrl` can be used directly in a browser as a download link
- File content is Base64 encoded for safe transmission
- Large files may require increased timeout values

### Put Live Response File (Upload)

Uploads a Base64-encoded file to a device.

**Request:**
```json
{
  "Function": "PutLiveResponseFile",
  "tenantId": "tenant-id",
  "DeviceIds": "device-id",
  "TargetFileName": "script.ps1",
  "fileContent": "IyBQb3dlclNoZWxsIFNjcmlwdA0KV3JpdGUtSG9zdCAi..."
}
```

**Response:**
```json
{
  "function": "PutLiveResponseFile",
  "status": "Success",
  "tenantId": "tenant-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "message": "File uploaded successfully",
  "fileName": "script.ps1",
  "sessionId": "session-id",
  "commandId": "command-id",
  "deviceId": "device-id"
}
```

**Notes:**
- `fileContent` must be Base64 encoded
- Whitespace in Base64 string is automatically cleaned
- File is first uploaded to Live Response library, then transferred to device

### Rate Limiting & Retry Logic

DefenderC2Orchestrator automatically handles:

**Rate Limits:**
- **MDE API**: 45 calls per minute per tenant
- **Live Response**: 100 concurrent sessions maximum

**Automatic Retry:**
- **HTTP 429 (Rate Limited)**: Waits for `Retry-After` header (default: 30s)
- **HTTP 5xx (Server Error)**: Exponential backoff (5s, 10s, 20s)
- **Max Retries**: 3 attempts before failure

**Example Rate Limit Response:**
```
⚠️ Rate limited (429). Waiting 30 seconds before retry...
```

### Usage from PowerShell

```powershell
$baseUrl = "https://your-function-app.azurewebsites.net/api"
$functionKey = "your-function-key"

# Upload file to device
$fileBytes = [IO.File]::ReadAllBytes("C:\local\script.ps1")
$base64Content = [Convert]::ToBase64String($fileBytes)

$body = @{
    Function = "PutLiveResponseFile"
    tenantId = "tenant-id"
    DeviceIds = "device-id"
    TargetFileName = "script.ps1"
    fileContent = $base64Content
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post `
    -Uri "$baseUrl/DefenderC2Orchestrator?code=$functionKey" `
    -Body $body `
    -ContentType "application/json"

Write-Output $response
```

### Usage from Workbook

See [WORKBOOK_FILE_OPERATIONS.md](WORKBOOK_FILE_OPERATIONS.md) for complete workbook integration examples including:
- File upload/download ARM actions
- Base64 encoding examples
- Auto-refresh configuration
- Troubleshooting guide

---

## Error Handling

All functions return consistent error responses:

**Error Response:**
```json
{
  "error": "Error message",
  "details": "Detailed exception information"
}
```

**HTTP Status Codes:**
- `200 OK` - Success
- `400 Bad Request` - Missing required parameters
- `500 Internal Server Error` - Function execution error

---

## Rate Limiting

Be aware of Microsoft Defender API rate limits:
- **Machine Actions**: 100 calls per minute
- **Advanced Hunting**: 15 calls per minute, 10 queries per hour
- **Indicators**: 100 calls per minute
- **Live Response (DefenderC2Orchestrator)**: 45 calls per minute per tenant, 100 concurrent sessions

**DefenderC2Orchestrator Automatic Retry:**
The DefenderC2Orchestrator function automatically implements retry logic with exponential backoff:
- HTTP 429 (Rate Limited): Automatically waits for `Retry-After` header value
- HTTP 5xx (Server Errors): Exponential backoff (5s, 10s, 20s)
- Maximum 3 retry attempts before failure

**Workbook Auto-Refresh Best Practices:**
- Minimum refresh interval: 30 seconds (respects 45/min limit)
- Set `maxRefreshCount` to stop after completion
- Monitor `status` field in responses to determine when to stop refreshing

For other functions, implement retry logic with exponential backoff for production use.

---

## Examples

### PowerShell Example
```powershell
$baseUrl = "https://your-function-app.azurewebsites.net/api"
$tenantId = "your-tenant-id"

# Isolate a device
$body = @{
    action = "Isolate Device"
    tenantId = $tenantId
    deviceIds = "device-id"
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post -Uri "$baseUrl/DefenderC2Dispatcher" -Body $body -ContentType "application/json"
Write-Output $response
```

### Python Example
```python
import requests
import json

base_url = "https://your-function-app.azurewebsites.net/api"
tenant_id = "your-tenant-id"

# Execute hunting query
payload = {
    "tenantId": tenant_id,
    "huntQuery": "DeviceInfo | take 10",
    "huntName": "Test Hunt"
}

response = requests.post(
    f"{base_url}/DefenderC2HuntManager",
    json=payload
)

print(json.dumps(response.json(), indent=2))
```

### cURL Example
```bash
curl -X POST https://your-function-app.azurewebsites.net/api/DefenderC2TIManager \
  -H "Content-Type: application/json" \
  -d '{
    "action": "Add File Indicators",
    "tenantId": "your-tenant-id",
    "indicators": "sha256hash1,sha256hash2",
    "title": "Malware",
    "severity": "High",
    "recommendedAction": "Block"
  }'
```

---

## Workbook Integration

Azure Workbooks can call these functions using ARMActions or HTTP calls:

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "list",
    "links": [
      {
        "linkTarget": "ArmAction",
        "linkLabel": "Isolate Device",
        "armActionContext": {
          "path": "{FunctionAppUrl}/api/DefenderC2Dispatcher",
          "headers": [],
          "params": [
            {
              "key": "action",
              "value": "Isolate Device"
            },
            {
              "key": "tenantId",
              "value": "{TenantId}"
            },
            {
              "key": "deviceIds",
              "value": "{DeviceId}"
            }
          ],
          "httpMethod": "POST"
        }
      }
    ]
  }
}
```

---

## Monitoring

View function execution logs in:
- Azure Portal > Function App > Monitor > Logs
- Application Insights for detailed telemetry
- Log Analytics for query-based analysis

---

## Support

For issues or questions:
1. Check function logs in Application Insights
2. Verify API permissions are granted
3. Ensure APPID and SECRETID are configured
4. Validate tenant ID is correct
5. Check MDE API rate limits

---

## Additional Resources

- [Microsoft Defender for Endpoint API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [Azure Workbooks Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
