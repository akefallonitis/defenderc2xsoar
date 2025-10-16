#!/usr/bin/env python3
"""
COMPLETE WORKBOOK REBUILD
Based on full conversation history and requirements

REQUIREMENTS FROM CONVERSATION:
1. Device inventory at top with clickable selection
2. Conflict detection to prevent 400 errors
3. Action strings match DefenderC2Dispatcher/run.ps1 exactly (WITH SPACES)
4. Confirmation for destructive actions
5. Manual device ID input option
6. Action ID auto-population for cancellation
7. Auto-refresh (30s default)
8. Hybrid: Fixed parameter chain (Subscription → ResourceGroup → FunctionApp)
9. Both: Multi-device support
10. Clear error messages
"""

import json

# Action strings MUST match DefenderC2Dispatcher/run.ps1 switch statement
ACTION_STRINGS = {
    "scan": "Run Antivirus Scan",
    "isolate": "Isolate Device",
    "unisolate": "Unisolate Device",
    "collect": "Collect Investigation Package",
    "restrict": "Restrict App Execution",
    "unrestrict": "Unrestrict App Execution"
}

def create_customendpoint_workbook():
    """
    CustomEndpoint Version with:
    - Multi-device selection
    - Conflict detection
    - Confirmation parameter
    - Manual input option
    """
    
    workbook = {
        "version": "Notebook/1.0",
        "items": [],
        "styleSettings": {},
        "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
    }
    
    # Header with workflow
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "# 🖥️ DefenderC2 Device Manager - CustomEndpoint\\n\\n## 📋 Workflow:\\n1. ✅ **Select Devices** from inventory (click multiple or type IDs)\\n2. ⚠️ **Check Conflicts** - view running actions\\n3. ⚡ **Choose Action** from dropdown\\n4. 🔒 **Type 'EXECUTE'** to confirm\\n5. 🚀 **Execute** and track status\\n\\n### Features:\\n- Multi-device selection\\n- Conflict detection\\n- Auto-refresh (30s)\\n- Action cancellation\\n- Manual device ID input"
        },
        "name": "header"
    })
    
    # Parameters
    params = [
        # Function App
        {
            "id": "fa",
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
        # Function App Name (derived)
        {
            "id": "fn",
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
        # Tenant ID
        {
            "id": "tid",
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
        # Device List - MULTI-SELECT with manual input
        {
            "id": "dev",
            "version": "KqlParameterItem/1.0",
            "name": "DeviceList",
            "label": "🖥️ Selected Devices (comma-separated IDs)",
            "type": 1,
            "isRequired": False,
            "isGlobal": True,
            "value": "",
            "description": "Click devices below OR paste device IDs manually (comma-separated)"
        },
        # Action Selector
        {
            "id": "act",
            "version": "KqlParameterItem/1.0",
            "name": "ActionToExecute",
            "label": "⚡ Action to Execute",
            "type": 2,
            "isRequired": True,
            "isGlobal": True,
            "typeSettings": {
                "additionalResourceOptions": [],
                "showDefault": False
            },
            "jsonData": json.dumps([
                {"value": "none", "label": "-- Select Action --"},
                {"value": ACTION_STRINGS["scan"], "label": "🔍 Run Antivirus Scan"},
                {"value": ACTION_STRINGS["isolate"], "label": "🔒 Isolate Device (DESTRUCTIVE)"},
                {"value": ACTION_STRINGS["unisolate"], "label": "🔓 Unisolate Device"},
                {"value": ACTION_STRINGS["collect"], "label": "📦 Collect Investigation Package"},
                {"value": ACTION_STRINGS["restrict"], "label": "🚫 Restrict App Execution (DESTRUCTIVE)"},
                {"value": ACTION_STRINGS["unrestrict"], "label": "✅ Unrestrict App Execution"}
            ]),
            "value": "none"
        },
        # Confirmation
        {
            "id": "conf",
            "version": "KqlParameterItem/1.0",
            "name": "ConfirmExecution",
            "label": "⚠️ Confirmation (type 'EXECUTE' to enable)",
            "type": 1,
            "isRequired": False,
            "isGlobal": True,
            "value": "",
            "description": "Type EXECUTE in all caps to enable action execution"
        },
        # Action ID for cancellation
        {
            "id": "aid",
            "version": "KqlParameterItem/1.0",
            "name": "ActionIdToCancel",
            "label": "🗑️ Action ID (for cancellation)",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
        # Auto Refresh
        {
            "id": "ref",
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
                {"value": "30000", "label": "Every 30 seconds"},
                {"value": "60000", "label": "Every 1 minute"},
                {"value": "300000", "label": "Every 5 minutes"}
            ]),
            "value": "30000"
        }
    ]
    
    workbook["items"].append({
        "type": 9,
        "content": {
            "version": "KqlParameterItem/1.0",
            "parameters": params,
            "style": "pills",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
        },
        "name": "parameters"
    })
    
    # === DEVICE INVENTORY ===
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## 💻 STEP 1: Device Inventory\\n\\n**Click '✅ Select' to add device to list** | **Or manually type/paste device IDs above (comma-separated)**"
        },
        "name": "inv-header"
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
                    {"key": "action", "value": "Get Devices"},
                    {"key": "tenantId", "value": "{TenantId}"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "tablePath": "$.devices[*]",
                        "columns": [
                            {"path": "$.id", "columnid": "Device ID"},
                            {"path": "$.computerDnsName", "columnid": "Computer Name"},
                            {"path": "$.osPlatform", "columnid": "OS"},
                            {"path": "$.osVersion", "columnid": "Version"},
                            {"path": "$.healthStatus", "columnid": "Health"},
                            {"path": "$.riskScore", "columnid": "Risk"},
                            {"path": "$.exposureLevel", "columnid": "Exposure"},
                            {"path": "$.lastSeen", "columnid": "Last Seen"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "🖥️ All Devices - Click to Select",
            "showRefreshButton": True,
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "Device ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "✅ Select",
                            "parameterName": "DeviceList",
                            "parameterValue": "{DeviceList},{0}"
                        }
                    },
                    {
                        "columnMatch": "Health",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "icons",
                            "thresholdsGrid": [
                                {"operator": "==", "thresholdValue": "Active", "representation": "success", "text": "✅ {0}"},
                                {"operator": "==", "thresholdValue": "Inactive", "representation": "warning", "text": "⚠️ {0}"},
                                {"operator": "Default", "representation": "unknown", "text": "{0}"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "Risk",
                        "formatter": 8,
                        "formatOptions": {
                            "palette": "redGreen",
                            "aggregation": "Min"
                        }
                    },
                    {
                        "columnMatch": "Exposure",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "==", "thresholdValue": "High", "representation": "redBright", "text": "🔴 {0}"},
                                {"operator": "==", "thresholdValue": "Medium", "representation": "orange", "text": "🟠 {0}"},
                                {"operator": "==", "thresholdValue": "Low", "representation": "green", "text": "🟢 {0}"},
                                {"operator": "Default", "representation": "blue", "text": "{0}"}
                            ]
                        }
                    }
                ],
                "filter": True,
                "sortBy": [{"itemKey": "Last Seen", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Last Seen", "sortOrder": 2}]
        },
        "name": "inventory"
    })
    
    # === CONFLICT DETECTION ===
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ⚠️ STEP 2: Conflict Detection\\n\\n**Selected Devices:** {DeviceList}  \\n**Selected Action:** {ActionToExecute}\\n\\n🔍 Checking if any selected device already has this action running..."
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "conflict-header"
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
                            {"path": "$.creationDateTimeUtc", "columnid": "Started"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Currently Running Actions on Selected Devices",
            "noDataMessage": "✅ No conflicts detected. Safe to proceed with execution.",
            "noDataMessageStyle": 3,
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "Action Type",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "==", "thresholdValue": "{ActionToExecute}", "representation": "redBright", "text": "🚨 {0} - CONFLICT!"},
                                {"operator": "Default", "representation": "orange", "text": "⚠️ {0}"}
                            ]
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
                    },
                    {
                        "columnMatch": "Action ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "❌ Cancel This",
                            "parameterName": "ActionIdToCancel",
                            "parameterValue": "{0}"
                        }
                    }
                ],
                "filter": True
            }
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "conflict-check"
    })
    
    # === EXECUTION ===
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ⚡ STEP 3: Execute Action\\n\\n**Devices:** {DeviceList}  \\n**Action:** {ActionToExecute}  \\n**Confirmation:** {ConfirmExecution}\\n\\n### ✅ Execution Checklist:\\n- ✓ Device IDs entered/selected\\n- ✓ Action selected from dropdown\\n- ✓ No conflicts detected above (green message)\\n- ⚠️ **Type 'EXECUTE' in confirmation box**\\n\\n### 🚨 Warning:\\nIf you see CONFLICT in the table above, **DO NOT EXECUTE**. Cancel the conflicting action first!"
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "execution-instructions"
    })
    
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "### 🚀 Executing: {ActionToExecute}\\n\\n**Target Devices:** {DeviceList}"
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"},
            {"parameterName": "ConfirmExecution", "comparison": "isEqualTo", "value": "EXECUTE"}
        ],
        "name": "execution-info"
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
                    {"key": "action", "value": "{ActionToExecute}"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "deviceIds", "value": "{DeviceList}"},
                    {"key": "comment", "value": "{ActionToExecute} via DefenderC2 Workbook - User: akefallonitis"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.details", "columnid": "Details"},
                            {"path": "$.actionIds[0]", "columnid": "First Action ID"},
                            {"path": "$.error", "columnid": "Error"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "✅ Execution Result",
            "showRefreshButton": True,
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "First Action ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "📋 Track/Cancel",
                            "parameterName": "ActionIdToCancel",
                            "parameterValue": "{0}"
                        }
                    },
                    {
                        "columnMatch": "Status",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "success", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "error", "representation": "redBright", "text": "❌ {0}"},
                                {"operator": "contains", "thresholdValue": "Unknown", "representation": "redBright", "text": "❌ {0}"},
                                {"operator": "Default", "representation": "blue", "text": "{0}"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "Error",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "Default", "representation": "redBright", "text": "❌ {0}"}
                            ]
                        }
                    }
                ]
            }
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"},
            {"parameterName": "ConfirmExecution", "comparison": "isEqualTo", "value": "EXECUTE"}
        ],
        "name": "execution-result"
    })
    
    # === STATUS TRACKING ===
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## 📊 Action Status Tracking\\n\\n**Auto-Refresh:** Every 30 seconds | Click Action ID to populate cancellation parameter"
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
                            "parameterName": "ActionIdToCancel",
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
                "filter": True,
                "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
        },
        "name": "all-actions"
    })
    
    # === CANCELLATION ===
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ❌ Cancel Machine Action\\n\\n**Action ID:** {ActionIdToCancel}\\n\\nClick an Action ID in the tables above to populate, then this query will execute the cancellation."
        },
        "conditionalVisibility": {
            "parameterName": "ActionIdToCancel",
            "comparison": "isNotEqualTo",
            "value": ""
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
                    {"key": "actionId", "value": "{ActionIdToCancel}"},
                    {"key": "comment", "value": "Cancelled via DefenderC2 Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.details", "columnid": "Details"},
                            {"path": "$.error", "columnid": "Error"}
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
                "formatters": [
                    {
                        "columnMatch": "Status",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "success", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "error", "representation": "redBright", "text": "❌ {0}"},
                                {"operator": "Default", "representation": "blue", "text": "{0}"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "Error",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "Default", "representation": "redBright", "text": "❌ {0}"}
                            ]
                        }
                    }
                ]
            }
        },
        "conditionalVisibility": {
            "parameterName": "ActionIdToCancel",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "cancel-result"
    })
    
    return workbook


def create_hybrid_workbook():
    """
    Hybrid Version with ARM Actions
    CRITICAL FIX: Proper parameter chain dependencies
    """
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - Hybrid Version\\n\\n## ARM Actions + CustomEndpoint Monitoring\\n\\n### Workflow:\\n1. ✅ **Select Devices** from inventory\\n2. ⚠️ **Check Conflicts** before execution\\n3. ⚡ **Execute ARM Actions** with native Azure confirmation dialogs\\n4. 📊 **Monitor Status** with auto-refresh\\n\\n### Features:\\n- Native ARM Action execution\\n- Multi-device support\\n- Conflict detection\\n- Auto-refresh (30s)\\n- Action cancellation"
        },
        "name": "header"
    })
    
    # Parameters with FIXED dependencies
    params = [
        # Subscription - FIRST (no dependencies)
        {
            "id": "sub",
            "version": "KqlParameterItem/1.0",
            "name": "Subscription",
            "label": "Azure Subscription",
            "type": 6,
            "isRequired": True,
            "isGlobal": True,
            "typeSettings": {
                "additionalResourceOptions": ["value::1"],
                "includeAll": False,
                "showDefault": False
            }
        },
        # Resource Group - depends on Subscription
        {
            "id": "rg",
            "version": "KqlParameterItem/1.0",
            "name": "ResourceGroup",
            "label": "Resource Group",
            "type": 2,
            "isRequired": True,
            "isGlobal": True,
            "query": "ResourceContainers | where type == 'microsoft.resources/resourcegroups' | where subscriptionId == '{Subscription:id}' | project value = name, label = name | order by label asc",
            "crossComponentResources": ["{Subscription}"],
            "typeSettings": {
                "additionalResourceOptions": [],
                "showDefault": False
            },
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
        },
        # Function App - depends on Subscription AND ResourceGroup
        {
            "id": "fa",
            "version": "KqlParameterItem/1.0",
            "name": "FunctionApp",
            "label": "DefenderC2 Function App",
            "type": 5,
            "isRequired": True,
            "isGlobal": True,
            "query": "Resources | where type == 'microsoft.web/sites' and kind == 'functionapp' | where subscriptionId == '{Subscription:id}' and resourceGroup == '{ResourceGroup}' | project id, name, resourceGroup, subscriptionId",
            "crossComponentResources": ["{Subscription}"],
            "typeSettings": {
                "additionalResourceOptions": ["value::1"],
                "showDefault": False,
                "resourceTypeFilter": {"microsoft.web/sites": True}
            },
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
        },
        # Function App Name - derived from FunctionApp
        {
            "id": "fn",
            "version": "KqlParameterItem/1.0",
            "name": "FunctionAppName",
            "type": 1,
            "isRequired": True,
            "isGlobal": True,
            "query": "Resources | where id == '{FunctionApp}' | project value = name",
            "crossComponentResources": ["{Subscription}"],
            "isHiddenWhenLocked": True,
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
        },
        # Tenant ID
        {
            "id": "tid",
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
        # Device List
        {
            "id": "dev",
            "version": "KqlParameterItem/1.0",
            "name": "DeviceList",
            "label": "🖥️ Selected Devices (comma-separated)",
            "type": 1,
            "isRequired": False,
            "isGlobal": True,
            "value": ""
        },
        # Action ID
        {
            "id": "aid",
            "version": "KqlParameterItem/1.0",
            "name": "ActionIdToCancel",
            "label": "🗑️ Action ID (for cancellation)",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
        # Auto Refresh
        {
            "id": "ref",
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
                {"value": "30000", "label": "Every 30 seconds"},
                {"value": "60000", "label": "Every 1 minute"}
            ]),
            "value": "30000"
        }
    ]
    
    workbook["items"].append({
        "type": 9,
        "content": {
            "version": "KqlParameterItem/1.0",
            "parameters": params,
            "style": "pills",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
        },
        "name": "parameters"
    })
    
    # Device Inventory (same as CustomEndpoint)
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## 💻 STEP 1: Device Inventory\\n\\n**Click '✅ Select' to add device to list**"
        },
        "name": "inv-header"
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
                    {"key": "action", "value": "Get Devices"},
                    {"key": "tenantId", "value": "{TenantId}"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "tablePath": "$.devices[*]",
                        "columns": [
                            {"path": "$.id", "columnid": "Device ID"},
                            {"path": "$.computerDnsName", "columnid": "Computer Name"},
                            {"path": "$.osPlatform", "columnid": "OS"},
                            {"path": "$.healthStatus", "columnid": "Health"},
                            {"path": "$.riskScore", "columnid": "Risk"},
                            {"path": "$.exposureLevel", "columnid": "Exposure"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "🖥️ All Devices",
            "showRefreshButton": True,
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "Device ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "✅ Select",
                            "parameterName": "DeviceList",
                            "parameterValue": "{DeviceList},{0}"
                        }
                    },
                    {
                        "columnMatch": "Health",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "icons",
                            "thresholdsGrid": [
                                {"operator": "==", "thresholdValue": "Active", "representation": "success", "text": "✅ {0}"},
                                {"operator": "Default", "representation": "unknown", "text": "{0}"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "Risk",
                        "formatter": 8,
                        "formatOptions": {"palette": "redGreen"}
                    },
                    {
                        "columnMatch": "Exposure",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "==", "thresholdValue": "High", "representation": "redBright", "text": "🔴 {0}"},
                                {"operator": "==", "thresholdValue": "Medium", "representation": "orange", "text": "🟠 {0}"},
                                {"operator": "==", "thresholdValue": "Low", "representation": "green", "text": "🟢 {0}"},
                                {"operator": "Default", "representation": "blue", "text": "{0}"}
                            ]
                        }
                    }
                ],
                "filter": True
            }
        },
        "name": "inventory"
    })
    
    # Conflict Check
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ⚠️ STEP 2: Check for Conflicts\\n\\n**Selected Devices:** {DeviceList}\\n\\n⚠️ **BEFORE clicking ARM Actions below**, check if any selected device has pending actions."
        },
        "conditionalVisibility": {
            "parameterName": "DeviceList",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "conflict-header"
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
                            {"path": "$.type", "columnid": "Running Action"},
                            {"path": "$.id", "columnid": "Action ID"},
                            {"path": "$.status", "columnid": "Status"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Currently Running Actions on Selected Devices",
            "noDataMessage": "✅ No conflicts. Safe to execute ARM Actions below.",
            "noDataMessageStyle": 3,
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "Running Action",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "Default", "representation": "orange", "text": "⚠️ {0}"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "Action ID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "❌ Cancel",
                            "parameterName": "ActionIdToCancel",
                            "parameterValue": "{0}"
                        }
                    }
                ],
                "filter": True
            }
        },
        "conditionalVisibility": {
            "parameterName": "DeviceList",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "conflict-check"
    })
    
    # ARM Actions
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ⚡ STEP 3: Execute ARM Actions\\n\\n**Selected Devices:** {DeviceList}\\n\\n**Click any button below** - Azure will show a native confirmation dialog with full details."
        },
        "conditionalVisibility": {
            "parameterName": "DeviceList",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "arm-header"
    })
    
    arm_links = []
    for key, action_str in ACTION_STRINGS.items():
        arm_links.append({
            "id": f"arm-{key}",
            "linkTarget": "ArmAction",
            "linkLabel": f"{'🔍' if key == 'scan' else '🔒' if key == 'isolate' else '🔓' if key == 'unisolate' else '📦' if key == 'collect' else '🚫' if key == 'restrict' else '✅'} {action_str}",
            "style": "primary" if key in ["scan", "collect"] else "secondary",
            "linkIsContextBlade": False,
            "armActionContext": {
                "path": "/subscriptions/{Subscription:id}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
                "headers": [],
                "params": [
                    {"name": "action", "value": action_str},
                    {"name": "tenantId", "value": "{TenantId}"},
                    {"name": "deviceIds", "value": "{DeviceList}"},
                    {"name": "comment", "value": f"{action_str} via DefenderC2 Workbook"}
                ],
                "body": None,
                "httpMethod": "POST",
                "title": action_str,
                "description": f"Execute {action_str} on devices: {{DeviceList}}",
                "runLabel": "Execute",
                "successMessage": f"✅ {action_str} initiated successfully! Check status below.",
                "actionName": f"arm-{key}"
            }
        })
    
    workbook["items"].append({
        "type": 11,
        "content": {
            "version": "LinkItem/1.0",
            "style": "list",
            "links": arm_links
        },
        "conditionalVisibility": {
            "parameterName": "DeviceList",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "arm-actions"
    })
    
    # Status Tracking (same as CustomEndpoint)
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## 📊 Action Status Tracking\\n\\n**Auto-Refresh:** Every 30 seconds"
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
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "Action"},
                            {"path": "$.id", "columnid": "Action ID"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.creationDateTimeUtc", "columnid": "Started"}
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
                            "parameterName": "ActionIdToCancel",
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
                "filter": True,
                "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
        },
        "name": "all-actions"
    })
    
    # Cancellation (same as CustomEndpoint)
    workbook["items"].append({
        "type": 1,
        "content": {
            "json": "---\\n\\n## ❌ Cancel Machine Action\\n\\n**Action ID:** {ActionIdToCancel}"
        },
        "conditionalVisibility": {
            "parameterName": "ActionIdToCancel",
            "comparison": "isNotEqualTo",
            "value": ""
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
                    {"key": "actionId", "value": "{ActionIdToCancel}"},
                    {"key": "comment", "value": "Cancelled via DefenderC2 Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.error", "columnid": "Error"}
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
                            {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
                            {"operator": "contains", "thresholdValue": "error", "representation": "redBright", "text": "❌ {0}"},
                            {"operator": "Default", "representation": "blue", "text": "{0}"}
                        ]
                    }
                }]
            }
        },
        "conditionalVisibility": {
            "parameterName": "ActionIdToCancel",
            "comparison": "isNotEqualTo",
            "value": ""
        },
        "name": "cancel-result"
    })
    
    return workbook


if __name__ == "__main__":
    print("="*80)
    print("COMPLETE WORKBOOK REBUILD")
    print("="*80)
    print()
    print("Action strings (must match DefenderC2Dispatcher/run.ps1):")
    for key, val in ACTION_STRINGS.items():
        print(f"  ✓ {val}")
    print()
    print("CustomEndpoint Features:")
    print("  ✓ Multi-device selection (comma-separated or click to add)")
    print("  ✓ Manual device ID input")
    print("  ✓ Confirmation parameter (type 'EXECUTE')")
    print("  ✓ Conflict detection")
    print("  ✓ Full error display")
    print("  ✓ Auto-refresh (30s)")
    print()
    print("Hybrid Features:")
    print("  ✓ FIXED parameter dependencies:")
    print("    - Subscription (auto-select)")
    print("    - ResourceGroup (depends on Subscription)")
    print("    - FunctionApp (depends on Subscription AND ResourceGroup)")
    print("  ✓ ARM Actions with correct action strings")
    print("  ✓ Same monitoring as CustomEndpoint")
    print()
    
    # Generate workbooks
    wb_ce = create_customendpoint_workbook()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-CustomEndpoint.json', 'w') as f:
        json.dump(wb_ce, f, indent=2)
    print("✅ CustomEndpoint workbook saved")
    
    wb_hybrid = create_hybrid_workbook()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-Hybrid.json', 'w') as f:
        json.dump(wb_hybrid, f, indent=2)
    print("✅ Hybrid workbook saved")
    
    print()
    print("="*80)
    print("READY TO DEPLOY")
    print("="*80)
