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

## MDEDispatcher - Device Operations

**Endpoint:** `/api/MDEDispatcher`

### Isolate Device
Isolates one or more devices from the network.

**Request:**
```http
POST /api/MDEDispatcher
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

## MDETIManager - Threat Intelligence

**Endpoint:** `/api/MDETIManager`

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

## MDEHuntManager - Advanced Hunting

**Endpoint:** `/api/MDEHuntManager`

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

## MDEIncidentManager - Incident Management

**Endpoint:** `/api/MDEIncidentManager`

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

## MDECDManager - Custom Detections

**Endpoint:** `/api/MDECDManager`

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

Implement retry logic with exponential backoff for production use.

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

$response = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEDispatcher" -Body $body -ContentType "application/json"
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
    f"{base_url}/MDEHuntManager",
    json=payload
)

print(json.dumps(response.json(), indent=2))
```

### cURL Example
```bash
curl -X POST https://your-function-app.azurewebsites.net/api/MDETIManager \
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
          "path": "{FunctionAppUrl}/api/MDEDispatcher",
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
