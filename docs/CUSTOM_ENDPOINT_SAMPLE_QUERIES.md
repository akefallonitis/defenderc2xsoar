# DefenderC2 Workbook - Custom Endpoint Sample Queries

## 📋 Overview

This document provides complete, copy-paste ready JSON code samples for implementing Custom Endpoint queries and ARM Actions across all 7 functional tabs in the DefenderC2 workbook.

### Tabs Covered
1. [Device Manager (Defender C2)](#1-device-manager-defender-c2)
2. [Threat Intel Manager](#2-threat-intel-manager)
3. [Action Manager](#3-action-manager)
4. [Hunt Manager](#4-hunt-manager)
5. [Incident Manager](#5-incident-manager)
6. [Detection Manager (Custom Detection Manager)](#6-detection-manager-custom-detection-manager)
7. [Console](#7-console)

---

## 🔧 Prerequisites

Before using these samples, ensure you have:
- **FunctionAppName** parameter configured
- **TenantId** parameter configured (auto-discovered from workspace)
- **Subscription** and **Workspace** parameters selected
- Function App deployed with all endpoints

---

## 1. Device Manager (Defender C2)

### 1.1 Get Devices (Custom Endpoint with Auto-Refresh)

**Purpose**: Display all devices with real-time status updates  
**Auto-Refresh**: 30 seconds  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.devices[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.isolationState\",\"columnid\":\"isolationState\"},{\"path\":\"$.healthStatus\",\"columnid\":\"healthStatus\"},{\"path\":\"$.riskScore\",\"columnid\":\"riskScore\"},{\"path\":\"$.exposureLevel\",\"columnid\":\"exposureLevel\"},{\"path\":\"$.lastSeen\",\"columnid\":\"lastSeen\"},{\"path\":\"$.osPlatform\",\"columnid\":\"osPlatform\"}]}}]}",
    "size": 0,
    "title": "💻 Device List (Custom HTTP Auto-Refresh)",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "formatters": [
        {
          "columnMatch": "isolationState",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "Isolated",
                "representation": "critical",
                "text": "🔒 Isolated"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "success",
                "text": "🔓 Not Isolated"
              }
            ]
          }
        },
        {
          "columnMatch": "healthStatus",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "Active",
                "representation": "success",
                "text": "✅ Active"
              },
              {
                "operator": "==",
                "thresholdValue": "Inactive",
                "representation": "warning",
                "text": "⚠️ Inactive"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "riskScore",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "High",
                "representation": "critical",
                "text": "🔴 High"
              },
              {
                "operator": "==",
                "thresholdValue": "Medium",
                "representation": "warning",
                "text": "🟡 Medium"
              },
              {
                "operator": "==",
                "thresholdValue": "Low",
                "representation": "success",
                "text": "🟢 Low"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        }
      ],
      "labelSettings": [
        {
          "columnId": "id",
          "label": "Device ID"
        },
        {
          "columnId": "computerDnsName",
          "label": "Computer Name"
        },
        {
          "columnId": "isolationState",
          "label": "Isolation Status"
        },
        {
          "columnId": "healthStatus",
          "label": "Health"
        },
        {
          "columnId": "riskScore",
          "label": "Risk Score"
        },
        {
          "columnId": "exposureLevel",
          "label": "Exposure"
        },
        {
          "columnId": "lastSeen",
          "label": "Last Seen"
        },
        {
          "columnId": "osPlatform",
          "label": "OS Platform"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "deviceActions"
  },
  "name": "query-get-devices",
  "styleSettings": {
    "showBorder": true
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30
  }
}
```

### 1.2 Isolate Devices (ARM Action)

**Purpose**: Isolate selected devices from network  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "isolate-device-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🚨 Isolate Devices",
        "style": "primary",
        "linkIsContextBlade": false,
        "preText": "",
        "postText": "",
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{IsolateDeviceIds}\"}",
          "httpMethod": "POST",
          "title": "Isolate Devices",
          "description": "This will isolate the selected devices from the network.",
          "actionName": "Isolate Devices",
          "runLabel": "Isolate"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "deviceActions"
  },
  "name": "links-isolate-device"
}
```

### 1.3 Release from Isolation (ARM Action)

**Purpose**: Release devices from isolation  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "unisolate-device-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🔓 Release from Isolation",
        "style": "secondary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Release Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{UnisolateDeviceIds}\"}",
          "httpMethod": "POST",
          "title": "Release from Isolation",
          "description": "This will release the selected devices from isolation.",
          "actionName": "Release from Isolation",
          "runLabel": "Release"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "deviceActions"
  },
  "name": "links-unisolate-device"
}
```

### 1.4 Run Antivirus Scan (ARM Action)

**Purpose**: Trigger antivirus scan on devices  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "run-av-scan-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🛡️ Run Antivirus Scan",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Run Antivirus Scan\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{ScanDeviceIds}\",\"scanType\":\"{ScanType}\"}",
          "httpMethod": "POST",
          "title": "Run Antivirus Scan",
          "description": "This will run an antivirus scan on the selected devices.",
          "actionName": "Run Scan",
          "runLabel": "Run Scan"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "deviceActions"
  },
  "name": "links-run-av-scan"
}
```

### 1.5 Stop and Quarantine File (ARM Action)

**Purpose**: Stop file execution and quarantine  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "stop-quarantine-file-action",
        "linkTarget": "ArmAction",
        "linkLabel": "⛔ Stop and Quarantine File",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Stop and Quarantine File\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{QuarantineDeviceIds}\",\"sha1\":\"{FileSHA1}\"}",
          "httpMethod": "POST",
          "title": "Stop and Quarantine File",
          "description": "This will stop the file and quarantine it on the selected devices.",
          "actionName": "Stop and Quarantine",
          "runLabel": "Quarantine"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "deviceActions"
  },
  "name": "links-stop-quarantine"
}
```

---

## 2. Threat Intel Manager

### 2.1 List Active Threat Indicators (Custom Endpoint)

**Purpose**: Display all active threat indicators  
**Auto-Refresh**: None (updated on demand)  
**Endpoint**: `DefenderC2TIManager`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"List Indicators\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.indicators[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.indicatorValue\",\"columnid\":\"indicatorValue\"},{\"path\":\"$.indicatorType\",\"columnid\":\"indicatorType\"},{\"path\":\"$.action\",\"columnid\":\"action\"},{\"path\":\"$.severity\",\"columnid\":\"severity\"},{\"path\":\"$.title\",\"columnid\":\"title\"},{\"path\":\"$.description\",\"columnid\":\"description\"},{\"path\":\"$.creationTimeDateTimeUtc\",\"columnid\":\"createdTime\"}]}}]}",
    "size": 0,
    "title": "📍 Active Threat Indicators",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "formatters": [
        {
          "columnMatch": "indicatorType",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "FileSha1",
                "representation": "info",
                "text": "📄 File (SHA1)"
              },
              {
                "operator": "==",
                "thresholdValue": "FileSha256",
                "representation": "info",
                "text": "📄 File (SHA256)"
              },
              {
                "operator": "==",
                "thresholdValue": "IpAddress",
                "representation": "info",
                "text": "🌐 IP Address"
              },
              {
                "operator": "==",
                "thresholdValue": "Url",
                "representation": "info",
                "text": "🔗 URL"
              },
              {
                "operator": "==",
                "thresholdValue": "DomainName",
                "representation": "info",
                "text": "🌍 Domain"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "action",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "Alert",
                "representation": "warning",
                "text": "⚠️ Alert"
              },
              {
                "operator": "==",
                "thresholdValue": "AlertAndBlock",
                "representation": "critical",
                "text": "🚫 Alert & Block"
              },
              {
                "operator": "==",
                "thresholdValue": "Allowed",
                "representation": "success",
                "text": "✅ Allowed"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "severity",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "High",
                "representation": "critical",
                "text": "🔴 High"
              },
              {
                "operator": "==",
                "thresholdValue": "Medium",
                "representation": "warning",
                "text": "🟡 Medium"
              },
              {
                "operator": "==",
                "thresholdValue": "Low",
                "representation": "info",
                "text": "🟢 Low"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        }
      ],
      "labelSettings": [
        {
          "columnId": "id",
          "label": "Indicator ID"
        },
        {
          "columnId": "indicatorValue",
          "label": "Indicator Value"
        },
        {
          "columnId": "indicatorType",
          "label": "Type"
        },
        {
          "columnId": "action",
          "label": "Action"
        },
        {
          "columnId": "severity",
          "label": "Severity"
        },
        {
          "columnId": "title",
          "label": "Title"
        },
        {
          "columnId": "description",
          "label": "Description"
        },
        {
          "columnId": "createdTime",
          "label": "Created"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "threatIntel"
  },
  "name": "query-list-indicators",
  "styleSettings": {
    "showBorder": true
  }
}
```

### 2.2 Submit File Indicator (ARM Action)

**Purpose**: Submit file hash as threat indicator  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2TIManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "submit-file-indicator-action",
        "linkTarget": "ArmAction",
        "linkLabel": "📄 Submit File Indicator",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Submit Indicator\",\"tenantId\":\"{TenantId}\",\"indicatorType\":\"FileSha1\",\"indicatorValue\":\"{FileIndicatorValue}\",\"action\":\"{FileIndicatorAction}\",\"severity\":\"{FileIndicatorSeverity}\",\"title\":\"{FileIndicatorTitle}\",\"description\":\"{FileIndicatorDescription}\"}",
          "httpMethod": "POST",
          "title": "Submit File Indicator",
          "description": "Submit a file hash as a threat indicator.",
          "actionName": "Submit File Indicator",
          "runLabel": "Submit"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "threatIntel"
  },
  "name": "links-submit-file-indicator"
}
```

### 2.3 Submit IP Indicator (ARM Action)

**Purpose**: Submit IP address as threat indicator  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2TIManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "submit-ip-indicator-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🌐 Submit IP Indicator",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Submit Indicator\",\"tenantId\":\"{TenantId}\",\"indicatorType\":\"IpAddress\",\"indicatorValue\":\"{IPIndicatorValue}\",\"action\":\"{IPIndicatorAction}\",\"severity\":\"{IPIndicatorSeverity}\",\"title\":\"{IPIndicatorTitle}\",\"description\":\"{IPIndicatorDescription}\"}",
          "httpMethod": "POST",
          "title": "Submit IP Indicator",
          "description": "Submit an IP address as a threat indicator.",
          "actionName": "Submit IP Indicator",
          "runLabel": "Submit"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "threatIntel"
  },
  "name": "links-submit-ip-indicator"
}
```

### 2.4 Submit URL Indicator (ARM Action)

**Purpose**: Submit URL as threat indicator  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2TIManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "submit-url-indicator-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🔗 Submit URL Indicator",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Submit Indicator\",\"tenantId\":\"{TenantId}\",\"indicatorType\":\"Url\",\"indicatorValue\":\"{URLIndicatorValue}\",\"action\":\"{URLIndicatorAction}\",\"severity\":\"{URLIndicatorSeverity}\",\"title\":\"{URLIndicatorTitle}\",\"description\":\"{URLIndicatorDescription}\"}",
          "httpMethod": "POST",
          "title": "Submit URL Indicator",
          "description": "Submit a URL as a threat indicator.",
          "actionName": "Submit URL Indicator",
          "runLabel": "Submit"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "threatIntel"
  },
  "name": "links-submit-url-indicator"
}
```

---

## 3. Action Manager

### 3.1 Machine Actions (Custom Endpoint with Auto-Refresh)

**Purpose**: Display all machine actions with real-time status updates  
**Auto-Refresh**: 30 seconds  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"Get Machine Actions\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.machineactions[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.type\",\"columnid\":\"type\"},{\"path\":\"$.status\",\"columnid\":\"status\"},{\"path\":\"$.machineId\",\"columnid\":\"machineId\"},{\"path\":\"$.computerDnsName\",\"columnid\":\"computerDnsName\"},{\"path\":\"$.requestor\",\"columnid\":\"requestor\"},{\"path\":\"$.creationDateTimeUtc\",\"columnid\":\"createdTime\"},{\"path\":\"$.lastUpdateDateTimeUtc\",\"columnid\":\"lastUpdate\"}]}}]}",
    "size": 0,
    "title": "📊 Machine Actions (Auto-refresh every 30s)",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "formatters": [
        {
          "columnMatch": "type",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "RunAntiVirusScan",
                "representation": "info",
                "text": "🛡️ AV Scan"
              },
              {
                "operator": "==",
                "thresholdValue": "Isolate",
                "representation": "warning",
                "text": "🔒 Isolate"
              },
              {
                "operator": "==",
                "thresholdValue": "Unisolate",
                "representation": "success",
                "text": "🔓 Release"
              },
              {
                "operator": "==",
                "thresholdValue": "StopAndQuarantineFile",
                "representation": "critical",
                "text": "⛔ Quarantine"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "status",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "Pending",
                "representation": "info",
                "text": "⏳ Pending"
              },
              {
                "operator": "==",
                "thresholdValue": "InProgress",
                "representation": "warning",
                "text": "🔄 In Progress"
              },
              {
                "operator": "==",
                "thresholdValue": "Succeeded",
                "representation": "success",
                "text": "✅ Succeeded"
              },
              {
                "operator": "==",
                "thresholdValue": "Failed",
                "representation": "critical",
                "text": "❌ Failed"
              },
              {
                "operator": "==",
                "thresholdValue": "Cancelled",
                "representation": "disabled",
                "text": "🚫 Cancelled"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        }
      ],
      "labelSettings": [
        {
          "columnId": "id",
          "label": "Action ID"
        },
        {
          "columnId": "type",
          "label": "Action Type"
        },
        {
          "columnId": "status",
          "label": "Status"
        },
        {
          "columnId": "machineId",
          "label": "Machine ID"
        },
        {
          "columnId": "computerDnsName",
          "label": "Computer Name"
        },
        {
          "columnId": "requestor",
          "label": "Requestor"
        },
        {
          "columnId": "createdTime",
          "label": "Created"
        },
        {
          "columnId": "lastUpdate",
          "label": "Last Updated"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "actionManager"
  },
  "name": "query-machine-actions",
  "styleSettings": {
    "showBorder": true
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30
  }
}
```

### 3.2 Cancel Action (ARM Action)

**Purpose**: Cancel a pending or in-progress action  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2Dispatcher`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "cancel-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🚫 Cancel Action",
        "style": "secondary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Cancel Action\",\"tenantId\":\"{TenantId}\",\"actionId\":\"{CancelActionId}\"}",
          "httpMethod": "POST",
          "title": "Cancel Action",
          "description": "Cancel a pending or in-progress machine action.",
          "actionName": "Cancel Action",
          "runLabel": "Cancel"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "actionManager"
  },
  "name": "links-cancel-action"
}
```

---

## 4. Hunt Manager

### 4.1 Run Advanced Hunting Query (ARM Action)

**Purpose**: Execute advanced hunting KQL query  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2HuntManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "run-hunt-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🔍 Run Hunt Query",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Run Hunt\",\"tenantId\":\"{TenantId}\",\"huntQuery\":\"{HuntQuery}\"}",
          "httpMethod": "POST",
          "title": "Run Hunt Query",
          "description": "Execute an advanced hunting query.",
          "actionName": "Run Hunt",
          "runLabel": "Run Query"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "huntManager"
  },
  "name": "links-run-hunt"
}
```

### 4.2 Hunt Results (Custom Endpoint with Auto-Refresh)

**Purpose**: Display hunting query results with status updates  
**Auto-Refresh**: 30 seconds (until completion)  
**Endpoint**: `DefenderC2HuntManager`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"Get Hunt Results\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.results[*]\",\"columns\":[{\"path\":\"$.Timestamp\",\"columnid\":\"Timestamp\"},{\"path\":\"$.DeviceName\",\"columnid\":\"DeviceName\"},{\"path\":\"$.AccountName\",\"columnid\":\"AccountName\"},{\"path\":\"$.FileName\",\"columnid\":\"FileName\"},{\"path\":\"$.FolderPath\",\"columnid\":\"FolderPath\"},{\"path\":\"$.SHA1\",\"columnid\":\"SHA1\"}]}}]}",
    "size": 0,
    "title": "🔍 Hunt Results (Auto-refresh until completion)",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "labelSettings": [
        {
          "columnId": "Timestamp",
          "label": "Timestamp"
        },
        {
          "columnId": "DeviceName",
          "label": "Device Name"
        },
        {
          "columnId": "AccountName",
          "label": "Account"
        },
        {
          "columnId": "FileName",
          "label": "File Name"
        },
        {
          "columnId": "FolderPath",
          "label": "Path"
        },
        {
          "columnId": "SHA1",
          "label": "SHA1 Hash"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "huntManager"
  },
  "name": "query-hunt-results",
  "styleSettings": {
    "showBorder": true
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 30,
    "refreshCondition": "{Status} == 'Completed'"
  }
}
```

---

## 5. Incident Manager

### 5.1 List Security Incidents (Custom Endpoint)

**Purpose**: Display all security incidents  
**Auto-Refresh**: 60 seconds  
**Endpoint**: `DefenderC2IncidentManager`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"List Incidents\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.incidents[*]\",\"columns\":[{\"path\":\"$.incidentId\",\"columnid\":\"incidentId\"},{\"path\":\"$.incidentName\",\"columnid\":\"incidentName\"},{\"path\":\"$.severity\",\"columnid\":\"severity\"},{\"path\":\"$.status\",\"columnid\":\"status\"},{\"path\":\"$.classification\",\"columnid\":\"classification\"},{\"path\":\"$.assignedTo\",\"columnid\":\"assignedTo\"},{\"path\":\"$.createdTime\",\"columnid\":\"createdTime\"},{\"path\":\"$.lastUpdateTime\",\"columnid\":\"lastUpdateTime\"}]}}]}",
    "size": 0,
    "title": "🚨 Security Incidents",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "formatters": [
        {
          "columnMatch": "severity",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "High",
                "representation": "critical",
                "text": "🔴 High"
              },
              {
                "operator": "==",
                "thresholdValue": "Medium",
                "representation": "warning",
                "text": "🟡 Medium"
              },
              {
                "operator": "==",
                "thresholdValue": "Low",
                "representation": "info",
                "text": "🟢 Low"
              },
              {
                "operator": "==",
                "thresholdValue": "Informational",
                "representation": "info",
                "text": "ℹ️ Info"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "status",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "Active",
                "representation": "warning",
                "text": "🔄 Active"
              },
              {
                "operator": "==",
                "thresholdValue": "Resolved",
                "representation": "success",
                "text": "✅ Resolved"
              },
              {
                "operator": "==",
                "thresholdValue": "InProgress",
                "representation": "info",
                "text": "⏳ In Progress"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        }
      ],
      "labelSettings": [
        {
          "columnId": "incidentId",
          "label": "Incident ID"
        },
        {
          "columnId": "incidentName",
          "label": "Name"
        },
        {
          "columnId": "severity",
          "label": "Severity"
        },
        {
          "columnId": "status",
          "label": "Status"
        },
        {
          "columnId": "classification",
          "label": "Classification"
        },
        {
          "columnId": "assignedTo",
          "label": "Assigned To"
        },
        {
          "columnId": "createdTime",
          "label": "Created"
        },
        {
          "columnId": "lastUpdateTime",
          "label": "Last Updated"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "incidentManager"
  },
  "name": "query-security-incidents",
  "styleSettings": {
    "showBorder": true
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 60
  }
}
```

### 5.2 Update Incident (ARM Action)

**Purpose**: Update incident status and properties  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2IncidentManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "update-incident-action",
        "linkTarget": "ArmAction",
        "linkLabel": "✏️ Update Incident",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Update Incident\",\"tenantId\":\"{TenantId}\",\"incidentId\":\"{UpdateIncidentId}\",\"status\":\"{IncidentStatus}\",\"classification\":\"{IncidentClassification}\",\"determination\":\"{IncidentDetermination}\"}",
          "httpMethod": "POST",
          "title": "Update Incident",
          "description": "Update incident status, classification, and determination.",
          "actionName": "Update Incident",
          "runLabel": "Update"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "incidentManager"
  },
  "name": "links-update-incident"
}
```

### 5.3 Add Comment to Incident (ARM Action)

**Purpose**: Add comment to incident  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2IncidentManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "add-comment-action",
        "linkTarget": "ArmAction",
        "linkLabel": "💬 Add Comment",
        "style": "secondary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2IncidentManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Add Comment\",\"tenantId\":\"{TenantId}\",\"incidentId\":\"{CommentIncidentId}\",\"comment\":\"{IncidentComment}\"}",
          "httpMethod": "POST",
          "title": "Add Comment",
          "description": "Add a comment to the incident.",
          "actionName": "Add Comment",
          "runLabel": "Add"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "incidentManager"
  },
  "name": "links-add-comment"
}
```

---

## 6. Detection Manager (Custom Detection Manager)

### 6.1 List Custom Detection Rules (Custom Endpoint)

**Purpose**: Display all custom detection rules  
**Auto-Refresh**: 120 seconds  
**Endpoint**: `DefenderC2CDManager`

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"ARMEndpoint/1.0\",\"data\":null,\"method\":\"POST\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"httpBodySchema\":\"{\\\"action\\\":\\\"List Detections\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\",\"transformers\":[{\"type\":\"jsonpath\",\"settings\":{\"tablePath\":\"$.detections[*]\",\"columns\":[{\"path\":\"$.id\",\"columnid\":\"id\"},{\"path\":\"$.displayName\",\"columnid\":\"displayName\"},{\"path\":\"$.severity\",\"columnid\":\"severity\"},{\"path\":\"$.enabled\",\"columnid\":\"enabled\"},{\"path\":\"$.createdBy\",\"columnid\":\"createdBy\"},{\"path\":\"$.creationTime\",\"columnid\":\"creationTime\"},{\"path\":\"$.lastUpdateTime\",\"columnid\":\"lastUpdateTime\"}]}}]}",
    "size": 0,
    "title": "🔍 Custom Detection Rules",
    "queryType": 12,
    "visualization": "table",
    "gridSettings": {
      "formatters": [
        {
          "columnMatch": "severity",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "High",
                "representation": "critical",
                "text": "🔴 High"
              },
              {
                "operator": "==",
                "thresholdValue": "Medium",
                "representation": "warning",
                "text": "🟡 Medium"
              },
              {
                "operator": "==",
                "thresholdValue": "Low",
                "representation": "info",
                "text": "🟢 Low"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        },
        {
          "columnMatch": "enabled",
          "formatter": 18,
          "formatOptions": {
            "thresholdsOptions": "icons",
            "thresholdsGrid": [
              {
                "operator": "==",
                "thresholdValue": "true",
                "representation": "success",
                "text": "✅ Enabled"
              },
              {
                "operator": "==",
                "thresholdValue": "false",
                "representation": "disabled",
                "text": "❌ Disabled"
              },
              {
                "operator": "Default",
                "thresholdValue": null,
                "representation": "info",
                "text": "{0}"
              }
            ]
          }
        }
      ],
      "labelSettings": [
        {
          "columnId": "id",
          "label": "Rule ID"
        },
        {
          "columnId": "displayName",
          "label": "Name"
        },
        {
          "columnId": "severity",
          "label": "Severity"
        },
        {
          "columnId": "enabled",
          "label": "Status"
        },
        {
          "columnId": "createdBy",
          "label": "Created By"
        },
        {
          "columnId": "creationTime",
          "label": "Created"
        },
        {
          "columnId": "lastUpdateTime",
          "label": "Last Updated"
        }
      ]
    }
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "detectionManager"
  },
  "name": "query-custom-detections",
  "styleSettings": {
    "showBorder": true
  },
  "isAutoRefreshEnabled": true,
  "autoRefreshSettings": {
    "intervalInSeconds": 120
  }
}
```

### 6.2 Create Custom Detection (ARM Action)

**Purpose**: Create new custom detection rule  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2CDManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "create-detection-action",
        "linkTarget": "ArmAction",
        "linkLabel": "➕ Create Detection",
        "style": "primary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Create Detection\",\"tenantId\":\"{TenantId}\",\"displayName\":\"{DetectionName}\",\"description\":\"{DetectionDescription}\",\"query\":\"{DetectionQuery}\",\"severity\":\"{DetectionSeverity}\",\"enabled\":true}",
          "httpMethod": "POST",
          "title": "Create Custom Detection",
          "description": "Create a new custom detection rule.",
          "actionName": "Create Detection",
          "runLabel": "Create"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "detectionManager"
  },
  "name": "links-create-detection"
}
```

### 6.3 Update Custom Detection (ARM Action)

**Purpose**: Update existing detection rule  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2CDManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "update-detection-action",
        "linkTarget": "ArmAction",
        "linkLabel": "✏️ Update Detection",
        "style": "secondary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Update Detection\",\"tenantId\":\"{TenantId}\",\"ruleId\":\"{UpdateDetectionRuleId}\",\"enabled\":\"{UpdateDetectionEnabled}\"}",
          "httpMethod": "POST",
          "title": "Update Detection",
          "description": "Update an existing custom detection rule.",
          "actionName": "Update Detection",
          "runLabel": "Update"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "detectionManager"
  },
  "name": "links-update-detection"
}
```

### 6.4 Delete Custom Detection (ARM Action)

**Purpose**: Delete detection rule  
**Action Type**: ARM Action  
**Endpoint**: `DefenderC2CDManager`

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "style": "pills",
    "links": [
      {
        "id": "delete-detection-action",
        "linkTarget": "ArmAction",
        "linkLabel": "🗑️ Delete Detection",
        "style": "secondary",
        "linkIsContextBlade": false,
        "armActionContext": {
          "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2CDManager",
          "headers": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ],
          "params": [],
          "body": "{\"action\":\"Delete Detection\",\"tenantId\":\"{TenantId}\",\"ruleId\":\"{DeleteDetectionRuleId}\"}",
          "httpMethod": "POST",
          "title": "Delete Detection",
          "description": "Delete a custom detection rule.",
          "actionName": "Delete Detection",
          "runLabel": "Delete"
        }
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "selectedTab",
    "comparison": "isEqualTo",
    "value": "detectionManager"
  },
  "name": "links-delete-detection"
}
```

---

## 7. Console

### 7.1 Console Overview

The Console tab provides quick access to common operations through a command-line style interface. Unlike other tabs, it uses a combination of text inputs and ARM Actions for streamlined operations.

**Note**: The Console tab primarily uses the existing ARM Actions from other tabs, presented in a different UI format. The JSON structure is identical to the actions documented above, but the presentation differs.

### 7.2 Console Commands

The Console tab typically includes:

1. **Device Operations**
   - Isolate Device (reuses ARM Action from Device Manager)
   - Release Device (reuses ARM Action from Device Manager)
   - Run AV Scan (reuses ARM Action from Device Manager)

2. **Threat Intel Operations**
   - Submit Indicator (reuses ARM Actions from Threat Intel Manager)

3. **Incident Operations**
   - Update Incident (reuses ARM Action from Incident Manager)
   - Add Comment (reuses ARM Action from Incident Manager)

4. **Detection Operations**
   - Create Detection (reuses ARM Action from Detection Manager)
   - Update Detection (reuses ARM Action from Detection Manager)

5. **Advanced Operations**
   - Run Hunt Query (reuses ARM Action from Hunt Manager)
   - Cancel Action (reuses ARM Action from Action Manager)

**Implementation Note**: The Console tab aggregates actions from all other tabs into a single, unified interface. No new JSON structures are needed—simply reference the ARM Actions defined in tabs 1-6 above.

---

## 🔧 Parameter Definitions

All queries and actions reference these parameters. Ensure they are defined in your workbook:

### Required Parameters

```json
{
  "parameters": [
    {
      "id": "function-app-name",
      "version": "KqlParameterItem/1.0",
      "name": "FunctionAppName",
      "label": "Function App Name",
      "type": 1,
      "isRequired": true,
      "value": "__FUNCTION_APP_NAME_PLACEHOLDER__",
      "description": "Name of the Azure Function App (e.g., defc2)"
    },
    {
      "id": "tenant-id",
      "version": "KqlParameterItem/1.0",
      "name": "TenantId",
      "label": "Target Tenant ID",
      "type": 1,
      "isRequired": false,
      "query": "Resources | where type =~ 'microsoft.operationalinsights/workspaces' | where id == '{Workspace}' | extend TenantId = tostring(properties.customerId) | project value = TenantId, label = TenantId",
      "crossComponentResources": ["{Subscription}"],
      "isHiddenWhenLocked": true,
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources",
      "description": "Auto-discovered from Log Analytics Workspace"
    },
    {
      "id": "subscription",
      "version": "KqlParameterItem/1.0",
      "name": "Subscription",
      "type": 6,
      "isRequired": true,
      "query": "where type =~ 'microsoft.operationalinsights/workspaces' | summarize by subscriptionId | project value = subscriptionId, label = subscriptionId, selected = false",
      "crossComponentResources": ["value::all"],
      "typeSettings": {
        "additionalResourceOptions": ["value::all"],
        "showDefault": false
      },
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    },
    {
      "id": "workspace",
      "version": "KqlParameterItem/1.0",
      "name": "Workspace",
      "type": 5,
      "isRequired": true,
      "query": "where type =~ 'microsoft.operationalinsights/workspaces' | project id, name, location",
      "crossComponentResources": ["{Subscription}"],
      "typeSettings": {
        "additionalResourceOptions": []
      },
      "queryType": 1,
      "resourceType": "microsoft.resourcegraph/resources"
    }
  ]
}
```

### Action-Specific Parameters

Each tab may define additional parameters for specific actions (e.g., `IsolateDeviceIds`, `FileIndicatorValue`, `HuntQuery`). These are typically text input parameters that users fill in before executing ARM Actions.

**Example: Device IDs Parameter**
```json
{
  "id": "isolate-device-ids",
  "version": "KqlParameterItem/1.0",
  "name": "IsolateDeviceIds",
  "label": "Device IDs (comma-separated)",
  "type": 1,
  "isRequired": false,
  "description": "Enter device IDs to isolate, separated by commas"
}
```

---

## 📚 Additional Resources

- [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](./WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) - Complete implementation guide
- [WORKBOOK_PARAMETERS_GUIDE.md](../deployment/WORKBOOK_PARAMETERS_GUIDE.md) - Parameter configuration
- [WORKBOOK_ARM_ACTION_FIX.md](../WORKBOOK_ARM_ACTION_FIX.md) - ARM Action headers fix

---

## 🤝 Contributing

If you have improvements or corrections to these samples:

1. Test your changes in a real Azure Workbook
2. Validate with actual Function App endpoints
3. Document any new patterns or best practices
4. Submit updates to the repository

---

**Last Updated**: 2025-10-11  
**Version**: 2.0  
**Maintainer**: DefenderC2 Team
