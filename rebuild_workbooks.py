#!/usr/bin/env python3
"""
Generate DeviceManager workbooks based on WORKING examples structure
"""

import json

def create_customendpoint_workbook():
    """Create pure CustomEndpoint workbook based on working structure"""
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - CustomEndpoint Version\n\n## Fully Automated Multi-Tenant Defender XDR Management\n\n### Features:\n- ✅ **Auto-populated device selection** from Defender tenant\n- ✅ **Auto-refreshing machine actions** to track execution status\n- ✅ **Pending action detection** with warnings\n- ✅ **Action ID auto-population** for easy tracking\n- ✅ **Error handling** to prevent 400 errors from duplicate actions"
        },
        "name": "header"
    })
    
    # Parameters
    workbook["items"].append({
        "type": 9,
        "content": {
            "version": "KqlParameterItem/1.0",
            "parameters": [
                {
                    "id": "function-app",
                    "version": "KqlParameterItem/1.0",
                    "name": "FunctionApp",
                    "label": "DefenderC2 Function App",
                    "type": 5,
                    "isRequired": True,
                    "isGlobal": True,
                    "query": "Resources | where type == 'microsoft.web/sites' and kind == 'functionapp' | project id, name, resourceGroup, subscriptionId",
                    "crossComponentResources": ["value::all"],
                    "typeSettings": {
                        "additionalResourceOptions": ["value::1"],
                        "showDefault": False,
                        "resourceTypeFilter": {"microsoft.web/sites": True}
                    },
                    "queryType": 1,
                    "resourceType": "microsoft.resourcegraph/resources"
                },
                {
                    "id": "function-name",
                    "version": "KqlParameterItem/1.0",
                    "name": "FunctionAppName",
                    "type": 1,
                    "isRequired": True,
                    "isGlobal": True,
                    "query": "Resources | where id == '{FunctionApp}' | project value = name",
                    "crossComponentResources": ["value::all"],
                    "isHiddenWhenLocked": True,
                    "queryType": 1,
                    "resourceType": "microsoft.resourcegraph/resources"
                },
                {
                    "id": "tenant-id",
                    "version": "KqlParameterItem/1.0",
                    "name": "TenantId",
                    "label": "Defender XDR Tenant",
                    "type": 2,
                    "isRequired": True,
                    "isGlobal": True,
                    "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('Tenant: ', tenantId) | order by label asc",
                    "crossComponentResources": ["value::all"],
                    "typeSettings": {
                        "additionalResourceOptions": [],
                        "selectFirstItem": True,
                        "showDefault": False
                    },
                    "queryType": 1,
                    "resourceType": "microsoft.resourcegraph/resources"
                },
                {
                    "id": "device-list",
                    "version": "KqlParameterItem/1.0",
                    "name": "DeviceList",
                    "label": "Select Devices",
                    "type": 2,
                    "isRequired": True,
                    "isGlobal": True,
                    "multiSelect": True,
                    "quote": "'",
                    "delimiter": ",",
                    "query": json.dumps({
                        "version": "CustomEndpoint/1.0",
                        "data": None,
                        "headers": [],
                        "method": "POST",
                        "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                        "body": None,
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
                    "queryType": 10
                },
                {
                    "id": "action-selector",
                    "version": "KqlParameterItem/1.0",
                    "name": "ActionToExecute",
                    "label": "Select Action to Execute",
                    "type": 2,
                    "typeSettings": {
                        "additionalResourceOptions": [],
                        "showDefault": False
                    },
                    "jsonData": json.dumps([
                        {"value": "none", "label": "-- Select an Action --"},
                        {"value": "scan", "label": "🔍 Run Antivirus Scan"},
                        {"value": "isolate", "label": "🔒 Isolate Device"},
                        {"value": "unisolate", "label": "🔓 Unisolate Device"},
                        {"value": "collect", "label": "📦 Collect Investigation Package"},
                        {"value": "restrict", "label": "🚫 Restrict App Execution"},
                        {"value": "unrestrict", "label": "✅ Unrestrict App Execution"}
                    ]),
                    "value": "none"
                },
                {
                    "id": "cancel-action-id",
                    "version": "KqlParameterItem/1.0",
                    "name": "CancelActionId",
                    "label": "Action ID to Cancel",
                    "type": 1,
                    "value": "<unset>"
                },
                {
                    "id": "auto-refresh",
                    "version": "KqlParameterItem/1.0",
                    "name": "AutoRefresh",
                    "label": "Auto Refresh Interval",
                    "type": 2,
                    "isGlobal": True,
                    "typeSettings": {
                        "additionalResourceOptions": [],
                        "showDefault": False
                    },
                    "jsonData": json.dumps([
                        {"value": "0", "label": "Off"},
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
    
    # Pending Actions Check
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "## ⚠️ Pending Actions Warning\n\n**Auto-Refresh:** Every 30 seconds\n\n⚠️ **Warning:** Attempting to run the same action on a device that already has the same action in progress will result in a 400 error."
        },
        "name": "pending-header"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0",
                "data": None,
                "headers": [],
                "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                "body": None,
                "urlParams": [
                    {"key": "action", "value": "Get All Actions"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "filter", "value": "status eq 'InProgress' or status eq 'Pending'"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "tablePath": "$.actions[*]",
                        "columns": [
                            {"path": "$.machineId", "columnid": "Device ID"},
                            {"path": "$.computerDnsName", "columnid": "Device Name"},
                            {"path": "$.type", "columnid": "Running Action"},
                            {"path": "$.id", "columnid": "Action ID"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.creationDateTimeUtc", "columnid": "Started"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Currently Running Actions",
            "noDataMessage": "✅ No conflicting actions detected. It's safe to proceed.",
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [{
                    "columnMatch": "Status",
                    "formatter": 18,
                    "formatOptions": {
                        "thresholdsOptions": "icons",
                        "thresholdsGrid": [
                            {"operator": "==", "thresholdValue": "InProgress", "representation": "pending", "text": "⏳ {0}"},
                            {"operator": "==", "thresholdValue": "Pending", "representation": "pending", "text": "⏳ {0}"},
                            {"operator": "Default", "thresholdValue": None, "text": "{0}"}
                        ]
                    }
                }]
            }
        },
        "conditionalVisibility": {
            "parameterName": "ActionToExecute",
            "comparison": "isNotEqualTo",
            "value": "none"
        },
        "name": "pending-check"
    })
    
    # Action Execution Sections
    actions = [
        {"value": "scan", "label": "Antivirus Scan", "action": "Run Antivirus Scan", "icon": "🔍", 
         "extra_params": [{"key": "scanType", "value": "Quick"}]},
        {"value": "isolate", "label": "Device Isolation", "action": "Isolate Device", "icon": "🔒",
         "extra_params": [{"key": "isolationType", "value": "Full"}]},
        {"value": "unisolate", "label": "Device Unisolation", "action": "Unisolate Device", "icon": "🔓",
         "extra_params": []},
        {"value": "collect", "label": "Investigation Package Collection", "action": "Collect Investigation Package", "icon": "📦",
         "extra_params": []},
        {"value": "restrict", "label": "App Execution Restriction", "action": "Restrict App Execution", "icon": "🚫",
         "extra_params": []},
        {"value": "unrestrict", "label": "App Execution Unrestriction", "action": "Unrestrict App Execution", "icon": "✅",
         "extra_params": []}
    ]
    
    for action_def in actions:
        # Header
        workbook["items"].append({
            "type": 1,
            "content": {
                "json": f"### {action_def['icon']} Executing: {action_def['label']}\n\n**Target Devices:** {{DeviceList}}\n**User:** akefallonitis"
            },
            "conditionalVisibility": {
                "parameterName": "ActionToExecute",
                "comparison": "isEqualTo",
                "value": action_def['value']
            },
            "name": f"{action_def['value']}-info"
        })
        
        # Execution Query
        url_params = [
            {"key": "action", "value": action_def['action']},
            {"key": "tenantId", "value": "{TenantId}"},
            {"key": "deviceIds", "value": "{DeviceList}"},
            {"key": "comment", "value": f"{action_def['action']} via DefenderC2 Workbook by akefallonitis"}
        ]
        url_params.extend(action_def['extra_params'])
        
        workbook["items"].append({
            "type": 3,
            "content": {
                "version": "KqlItem/1.0",
                "query": json.dumps({
                    "version": "CustomEndpoint/1.0",
                    "data": None,
                    "headers": [],
                    "method": "POST",
                    "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                    "body": None,
                    "urlParams": url_params,
                    "transformers": [{
                        "type": "jsonpath",
                        "settings": {
                            "columns": [
                                {"path": "$.message", "columnid": "Result"},
                                {"path": "$.actionIds[0]", "columnid": "Action ID"},
                                {"path": "$.status", "columnid": "Status"}
                            ]
                        }
                    }]
                }),
                "size": 0,
                "title": f"✅ {action_def['label']} Result",
                "showRefreshButton": True,
                "queryType": 10,
                "visualization": "table",
                "gridSettings": {
                    "formatters": [{
                        "columnMatch": "Action ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "📋 Copy to Cancel",
                            "parameterName": "CancelActionId",
                            "parameterValue": "{0}"
                        }
                    }]
                }
            },
            "conditionalVisibility": {
                "parameterName": "ActionToExecute",
                "comparison": "isEqualTo",
                "value": action_def['value']
            },
            "name": f"{action_def['value']}-result"
        })
    
    # Status Tracking Section
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\n\n## 📊 Action Status Tracking\n\n**Auto-Refresh:** Every 30 seconds\n\nTrack all machine actions across your Defender XDR environment."
        },
        "name": "status-header"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0",
                "data": None,
                "headers": [],
                "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                "body": None,
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
                            {"path": "$.lastUpdateDateTimeUtc", "columnid": "Last Update"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ All Machine Actions",
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "Action ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "❌ Cancel",
                            "parameterName": "CancelActionId",
                            "parameterValue": "{0}"
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
                "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
        },
        "name": "all-actions"
    })
    
    # Cancel Action Section
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\n\n## ❌ Cancel Action\n\n**Action ID to Cancel:** {CancelActionId}\n\nClick an Action ID in the tables above to populate the field, then the query below will execute."
        },
        "name": "cancel-header"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0",
                "data": None,
                "headers": [],
                "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher",
                "body": None,
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
                            {"path": "$.status", "columnid": "Status"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "✅ Cancellation Result",
            "showRefreshButton": True,
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [{
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
                }]
            }
        },
        "conditionalVisibility": {
            "parameterName": "CancelActionId",
            "comparison": "isNotEqualTo",
            "value": "<unset>"
        },
        "name": "cancel-result"
    })
    
    return workbook

# Generate and save
workbook = create_customendpoint_workbook()
with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-CustomEndpoint.json', 'w') as f:
    json.dump(workbook, f, indent=2)

print("✅ Created DeviceManager-CustomEndpoint.json based on working structure")
print("   - Added 'body: null' to all CustomEndpoint queries")
print("   - Using $.actionIds[0] for single action ID extraction")
print("   - Conditional visibility on individual items, not groups")
print("   - Auto-refresh every 30 seconds for status tracking")
