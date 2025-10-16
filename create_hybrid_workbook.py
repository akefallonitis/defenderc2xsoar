#!/usr/bin/env python3
"""
Generate DeviceManager-Hybrid.json with ARM Actions (Type 11 LinkItem)
"""

import json

# Base workbook structure
workbook = {
    "version": "Notebook/1.0",
    "items": [],
    "styleSettings": {},
    "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}

# Header
workbook["items"].append({
    "type": 1,
    "content": {
        "json": """# 🖥️ DefenderC2 Device Manager - Hybrid Version

## ARM Actions + CustomEndpoint Auto-Refresh

**Features:**
- ✅ **ARM Actions** for reliable action execution with confirmation dialogs
- ✅ **CustomEndpoint** for auto-refreshing status tracking
- ✅ **Auto-populated device selection** from Defender XDR
- ✅ **Pending action warnings** to prevent 400 errors
- ✅ **Action tracking & cancellation** via CustomEndpoint queries"""
    },
    "name": "header-text"
})

# Parameters
workbook["items"].append({
    "type": 9,
    "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
            {
                "id": "sub-param",
                "version": "KqlParameterItem/1.0",
                "name": "Subscription",
                "label": "🔑 Subscription",
                "type": 6,
                "isRequired": True,
                "isGlobal": True,
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "includeAll": False,
                    "showDefault": False
                }
            },
            {
                "id": "rg-param",
                "version": "KqlParameterItem/1.0",
                "name": "ResourceGroup",
                "label": "📦 Resource Group",
                "type": 2,
                "isRequired": True,
                "isGlobal": True,
                "query": "ResourceContainers | where type == 'microsoft.resources/resourcegroups' | where subscriptionId == '{Subscription}' | project value = id, label = name | order by label asc",
                "crossComponentResources": ["{Subscription}"],
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "queryType": 1,
                "resourceType": "microsoft.resourcegraph/resources"
            },
            {
                "id": "function-app-selector",
                "version": "KqlParameterItem/1.0",
                "name": "FunctionApp",
                "label": "🔧 DefenderC2 Function App",
                "type": 5,
                "isRequired": True,
                "isGlobal": True,
                "query": "Resources | where type == 'microsoft.web/sites' and kind == 'functionapp' | where resourceGroup == extract(@'/resourceGroups/([^/]+)', 1, '{ResourceGroup}') | project id, name, resourceGroup, subscriptionId | order by name asc",
                "crossComponentResources": ["{Subscription}"],
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "queryType": 1,
                "resourceType": "microsoft.resourcegraph/resources"
            },
            {
                "id": "function-name-hidden",
                "version": "KqlParameterItem/1.0",
                "name": "FunctionAppName",
                "type": 1,
                "isRequired": True,
                "isGlobal": True,
                "query": "Resources | where id == '{FunctionApp}' | project value = name",
                "crossComponentResources": ["{Subscription}"],
                "isHiddenWhenLocked": True,
                "queryType": 1,
                "resourceType": "microsoft.resourcegraph/resources",
                "criteriaData": [
                    {
                        "criterionType": "param",
                        "value": "{FunctionApp}"
                    }
                ]
            },
            {
                "id": "tenant-id-selector",
                "version": "KqlParameterItem/1.0",
                "name": "TenantId",
                "label": "🏢 Defender XDR Tenant",
                "type": 2,
                "isRequired": True,
                "isGlobal": True,
                "multiSelect": False,
                "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('🏢 Tenant: ', tenantId) | order by label asc",
                "crossComponentResources": ["value::all"],
                "queryType": 1,
                "resourceType": "microsoft.resourcegraph/resources",
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "selectFirstItem": True,
                    "showDefault": False
                },
                "timeContext": {"durationMs": 86400000}
            },
            {
                "id": "device-list-dropdown",
                "version": "KqlParameterItem/1.0",
                "name": "DeviceList",
                "label": "💻 Select Devices",
                "type": 2,
                "isRequired": False,
                "isGlobal": True,
                "multiSelect": True,
                "quote": "",
                "delimiter": ",",
                "query": json.dumps({
                    "version": "CustomEndpoint/1.0",
                    "data": None,
                    "headers": [],
                    "method": "POST",
                    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                    "urlParams": [
                        {"key": "action", "value": "Get Devices"},
                        {"key": "tenantId", "value": "{TenantId}"}
                    ],
                    "transformers": [{
                        "type": "jsonpath",
                        "settings": {
                            "tablePath": "$.devices[*]",
                            "columns": [
                                {"path": "$.id", "columnid": "value"},
                                {"path": "$.computerDnsName", "columnid": "label"}
                            ]
                        }
                    }]
                }),
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "timeContext": {"durationMs": 86400000},
                "queryType": 10,
                "description": "✅ Auto-populated from Defender XDR",
                "criteriaData": [
                    {"criterionType": "param", "value": "{FunctionAppName}"},
                    {"criterionType": "param", "value": "{TenantId}"}
                ]
            },
            {
                "id": "scan-type-param",
                "version": "KqlParameterItem/1.0",
                "name": "ScanType",
                "label": "Scan Type",
                "type": 2,
                "isGlobal": True,
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "jsonData": json.dumps([
                    {"value": "Quick", "label": "Quick Scan"},
                    {"value": "Full", "label": "Full Scan"}
                ]),
                "value": "Quick"
            },
            {
                "id": "isolation-type-param",
                "version": "KqlParameterItem/1.0",
                "name": "IsolationType",
                "label": "Isolation Type",
                "type": 2,
                "isGlobal": True,
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "jsonData": json.dumps([
                    {"value": "Full", "label": "Full Isolation"},
                    {"value": "Selective", "label": "Selective Isolation"}
                ]),
                "value": "Full"
            },
            {
                "id": "cancel-action-id",
                "version": "KqlParameterItem/1.0",
                "name": "CancelActionId",
                "label": "❌ Action ID to Cancel",
                "type": 1,
                "isGlobal": True,
                "value": "",
                "description": "Copy an Action ID from the table below to cancel it"
            },
            {
                "id": "auto-refresh",
                "version": "KqlParameterItem/1.0",
                "name": "AutoRefresh",
                "label": "🔄 Auto Refresh",
                "type": 2,
                "isGlobal": True,
                "typeSettings": {
                    "additionalResourceOptions": [],
                    "showDefault": False
                },
                "jsonData": json.dumps([
                    {"value": "0", "label": "Off"},
                    {"value": "10000", "label": "Every 10 seconds"},
                    {"value": "30000", "label": "Every 30 seconds"},
                    {"value": "60000", "label": "Every 1 minute"},
                    {"value": "300000", "label": "Every 5 minutes"}
                ]),
                "value": "30000"
            }
        ],
        "style": "pills",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
    },
    "name": "parameters"
})

# Pending Actions Check Group
workbook["items"].append({
    "type": 12,
    "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "title": "⚠️ Pending Actions Check",
        "expandable": True,
        "expanded": True,
        "items": [
            {
                "type": 1,
                "content": {
                    "json": "### 🔍 Checking for Running Actions\n\n⚠️ **Important:** Attempting the same action on a device with a pending action will result in **400 Bad Request**.\n\n**Auto-Refresh:** Every {AutoRefresh:label}"
                },
                "name": "pending-check-info"
            },
            {
                "type": 3,
                "content": {
                    "version": "KqlItem/1.0",
                    "query": json.dumps({
                        "version": "CustomEndpoint/1.0",
                        "data": None,
                        "headers": [],
                        "method": "POST",
                        "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                        "urlParams": [
                            {"key": "action", "value": "Get All Actions"},
                            {"key": "tenantId", "value": "{TenantId}"}
                        ],
                        "transformers": [{
                            "type": "jsonpath",
                            "settings": {
                                "tablePath": "$.actions[?(@.status=='Pending' || @.status=='InProgress')]",
                                "columns": [
                                    {"path": "$.machineId", "columnid": "Device ID"},
                                    {"path": "$.computerDnsName", "columnid": "Device Name"},
                                    {"path": "$.type", "columnid": "Action Type"},
                                    {"path": "$.id", "columnid": "Action ID"},
                                    {"path": "$.status", "columnid": "Status"},
                                    {"path": "$.creationDateTimeUtc", "columnid": "Started"}
                                ]
                            }
                        }]
                    }),
                    "size": 0,
                    "title": "⚙️ Currently Running Actions",
                    "noDataMessage": "✅ No pending actions found. Safe to execute new actions.",
                    "noDataMessageStyle": 3,
                    "timeContext": {"durationMs": 0},
                    "timeContextFromParameter": "AutoRefresh",
                    "showRefreshButton": True,
                    "queryType": 10,
                    "visualization": "table",
                    "gridSettings": {
                        "formatters": [
                            {"columnMatch": "Action Type", "formatter": 1},
                            {
                                "columnMatch": "Action ID",
                                "formatter": 7,
                                "formatOptions": {
                                    "linkTarget": "parameter",
                                    "linkLabel": "❌ Cancel",
                                    "parameterName": "CancelActionId",
                                    "parameterValue": "{0}",
                                    "linkIsContextBlade": False
                                }
                            },
                            {
                                "columnMatch": "Status",
                                "formatter": 18,
                                "formatOptions": {
                                    "thresholdsOptions": "icons",
                                    "thresholdsGrid": [
                                        {"operator": "==", "thresholdValue": "Pending", "representation": "pending", "text": "⏳ {0}"},
                                        {"operator": "==", "thresholdValue": "InProgress", "representation": "2", "text": "⚙️ {0}"},
                                        {"operator": "Default", "representation": "unknown", "text": "{0}"}
                                    ]
                                }
                            }
                        ],
                        "filter": True,
                        "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
                    },
                    "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
                },
                "conditionalVisibility": {
                    "parameterName": "DeviceList",
                    "comparison": "isNotEqualTo",
                    "value": ""
                },
                "name": "pending-actions-check"
            }
        ]
    },
    "conditionalVisibility": {
        "parameterName": "DeviceList",
        "comparison": "isNotEqualTo",
        "value": ""
    },
    "name": "pending-actions-group"
})

# ARM Action Groups
actions = [
    {
        "title": "🔬 Run Antivirus Scan",
        "name": "scan",
        "action": "Run Antivirus Scan",
        "emoji": "🔬",
        "description": "Execute {ScanType} antivirus scan via ARM Actions",
        "params": [
            {"key": "action", "value": "Run Antivirus Scan"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "scanType", "value": "{ScanType}"},
            {"key": "comment", "value": "ARM Action scan from DefenderC2 Workbook"}
        ]
    },
    {
        "title": "🔒 Isolate Device",
        "name": "isolate",
        "action": "Isolate Device",
        "emoji": "🔒",
        "description": "Isolate devices ({IsolationType}) via ARM Actions",
        "params": [
            {"key": "action", "value": "Isolate Device"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "isolationType", "value": "{IsolationType}"},
            {"key": "comment", "value": "ARM Action isolation from DefenderC2 Workbook"}
        ]
    },
    {
        "title": "🔓 Unisolate Device",
        "name": "unisolate",
        "action": "Unisolate Device",
        "emoji": "🔓",
        "description": "Reconnect devices to network via ARM Actions",
        "params": [
            {"key": "action", "value": "Unisolate Device"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "comment", "value": "ARM Action unisolation from DefenderC2 Workbook"}
        ]
    },
    {
        "title": "📦 Collect Investigation Package",
        "name": "collect",
        "action": "Collect Investigation Package",
        "emoji": "📦",
        "description": "Collect forensic package via ARM Actions",
        "params": [
            {"key": "action", "value": "Collect Investigation Package"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "comment", "value": "ARM Action collection from DefenderC2 Workbook"}
        ]
    },
    {
        "title": "🚫 Restrict App Execution",
        "name": "restrict",
        "action": "Restrict App Execution",
        "emoji": "🚫",
        "description": "Block unauthorized apps via ARM Actions",
        "params": [
            {"key": "action", "value": "Restrict App Execution"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "comment", "value": "ARM Action restriction from DefenderC2 Workbook"}
        ]
    },
    {
        "title": "✅ Unrestrict App Execution",
        "name": "unrestrict",
        "action": "Unrestrict App Execution",
        "emoji": "✅",
        "description": "Allow normal app execution via ARM Actions",
        "params": [
            {"key": "action", "value": "Unrestrict App Execution"},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "comment", "value": "ARM Action unrestriction from DefenderC2 Workbook"}
        ]
    }
]

for action_def in actions:
    workbook["items"].append({
        "type": 12,
        "content": {
            "version": "NotebookGroup/1.0",
            "groupType": "editable",
            "title": action_def["title"],
            "expandable": True,
            "expanded": False,
            "items": [
                {
                    "type": 1,
                    "content": {
                        "json": f"### {action_def['emoji']} {action_def['action']}\n\n{action_def['description']}\n\n**Selected Devices:** {{DeviceList:label}}"
                    },
                    "name": f"{action_def['name']}-header"
                },
                {
                    "type": 11,
                    "content": {
                        "version": "LinkItem/1.0",
                        "style": "list",
                        "links": [
                            {
                                "id": f"{action_def['name']}-link",
                                "linkTarget": "ArmAction",
                                "linkLabel": f"{action_def['emoji']} Execute {action_def['action']}",
                                "style": "primary",
                                "linkIsContextBlade": False,
                                "armActionContext": {
                                    "path": "{FunctionApp}/functions/DefenderC2Dispatcher/invoke",
                                    "headers": [],
                                    "params": action_def["params"],
                                    "isLongOperation": True,
                                    "httpMethod": "POST",
                                    "title": action_def["action"],
                                    "description": f"Execute {action_def['action']} on {{DeviceList:label}}",
                                    "actionName": action_def["action"]
                                }
                            }
                        ]
                    },
                    "conditionalVisibility": {
                        "parameterName": "DeviceList",
                        "comparison": "isNotEqualTo",
                        "value": ""
                    },
                    "name": f"{action_def['name']}-arm-action"
                }
            ]
        },
        "conditionalVisibility": {
            "parameterName": "DeviceList",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": f"{action_def['name']}-group"
    })

# Status Tracking Group
workbook["items"].append({
    "type": 12,
    "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "title": "📊 Action Status Tracking (Auto-Refresh)",
        "expandable": True,
        "expanded": True,
        "items": [
            {
                "type": 1,
                "content": {
                    "json": "### 📊 All Machine Actions\n\n**Auto-Refresh:** Every {AutoRefresh:label}\n\nTrack all actions across your Defender XDR environment."
                },
                "name": "status-header"
            },
            {
                "type": 3,
                "content": {
                    "version": "KqlItem/1.0",
                    "query": json.dumps({
                        "version": "CustomEndpoint/1.0",
                        "data": None,
                        "headers": [],
                        "method": "POST",
                        "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                        "urlParams": [
                            {"key": "action", "value": "Get All Actions"},
                            {"key": "tenantId", "value": "{TenantId}"}
                        ],
                        "transformers": [{
                            "type": "jsonpath",
                            "settings": {
                                "tablePath": "$.actions[*]",
                                "columns": [
                                    {"path": "$.machineId", "columnid": "Device ID"},
                                    {"path": "$.computerDnsName", "columnid": "Device Name"},
                                    {"path": "$.type", "columnid": "Action Type"},
                                    {"path": "$.id", "columnid": "Action ID"},
                                    {"path": "$.status", "columnid": "Status"},
                                    {"path": "$.creationDateTimeUtc", "columnid": "Started"},
                                    {"path": "$.lastUpdateDateTimeUtc", "columnid": "Last Update"},
                                    {"path": "$.requestor", "columnid": "Requestor"}
                                ]
                            }
                        }]
                    }),
                    "size": 0,
                    "title": "⚙️ All Actions",
                    "timeContext": {"durationMs": 0},
                    "timeContextFromParameter": "AutoRefresh",
                    "showRefreshButton": True,
                    "queryType": 10,
                    "visualization": "table",
                    "gridSettings": {
                        "formatters": [
                            {"columnMatch": "Action Type", "formatter": 1},
                            {
                                "columnMatch": "Action ID",
                                "formatter": 7,
                                "formatOptions": {
                                    "linkTarget": "parameter",
                                    "linkLabel": "❌ Cancel",
                                    "parameterName": "CancelActionId",
                                    "parameterValue": "{0}",
                                    "linkIsContextBlade": False
                                }
                            },
                            {
                                "columnMatch": "Status",
                                "formatter": 18,
                                "formatOptions": {
                                    "thresholdsOptions": "icons",
                                    "thresholdsGrid": [
                                        {"operator": "==", "thresholdValue": "Pending", "representation": "pending", "text": "⏳ {0}"},
                                        {"operator": "==", "thresholdValue": "InProgress", "representation": "2", "text": "⚙️ {0}"},
                                        {"operator": "==", "thresholdValue": "Succeeded", "representation": "success", "text": "✅ {0}"},
                                        {"operator": "==", "thresholdValue": "Failed", "representation": "failed", "text": "❌ {0}"},
                                        {"operator": "Default", "representation": "unknown", "text": "{0}"}
                                    ]
                                }
                            }
                        ],
                        "filter": True,
                        "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
                    },
                    "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
                },
                "name": "all-actions-query"
            }
        ]
    },
    "name": "status-tracking-group"
})

# Cancel Action Group
workbook["items"].append({
    "type": 12,
    "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "title": "❌ Cancel Action",
        "expandable": True,
        "expanded": False,
        "items": [
            {
                "type": 1,
                "content": {
                    "json": "### ❌ Cancel Machine Action\n\n**Action ID:** {CancelActionId}\n\nClick an Action ID above to auto-populate, then execute cancellation."
                },
                "name": "cancel-header"
            },
            {
                "type": 3,
                "content": {
                    "version": "KqlItem/1.0",
                    "query": json.dumps({
                        "version": "CustomEndpoint/1.0",
                        "data": None,
                        "headers": [],
                        "method": "POST",
                        "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                        "urlParams": [
                            {"key": "action", "value": "Cancel Action"},
                            {"key": "tenantId", "value": "{TenantId}"},
                            {"key": "actionId", "value": "{CancelActionId}"},
                            {"key": "comment", "value": "Cancelled via DefenderC2 Workbook"}
                        ],
                        "transformers": [{
                            "type": "jsonpath",
                            "settings": {
                                "columns": [
                                    {"path": "$.message", "columnid": "Result"},
                                    {"path": "$.status", "columnid": "Status"},
                                    {"path": "$.details", "columnid": "Details"}
                                ]
                            }
                        }]
                    }),
                    "size": 0,
                    "title": "✅ Cancellation Result",
                    "timeContext": {"durationMs": 86400000},
                    "showRefreshButton": True,
                    "queryType": 10,
                    "visualization": "table",
                    "gridSettings": {
                        "formatters": [
                            {
                                "columnMatch": "Status",
                                "formatter": 18,
                                "formatOptions": {
                                    "thresholdsOptions": "colors",
                                    "thresholdsGrid": [
                                        {"operator": "contains", "thresholdValue": "success", "representation": "green", "text": "✅ {0}"},
                                        {"operator": "contains", "thresholdValue": "error", "representation": "redBright", "text": "❌ {0}"},
                                        {"operator": "Default", "representation": "blue", "text": "{0}"}
                                    ]
                                }
                            }
                        ]
                    }
                },
                "conditionalVisibility": {
                    "parameterName": "CancelActionId",
                    "comparison": "isNotEqualTo",
                    "value": ""
                },
                "name": "cancel-query"
            }
        ]
    },
    "name": "cancel-group"
})

# Write to file
with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-Hybrid.json', 'w') as f:
    json.dump(workbook, f, indent=2)

print("✅ Created DeviceManager-Hybrid.json with ARM Actions (Type 11 LinkItem)")
print("✅ 6 ARM Action groups: Scan, Isolate, Unisolate, Collect, Restrict, Unrestrict")
print("✅ CustomEndpoint for auto-refresh status tracking and cancellation")
