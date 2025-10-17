#!/usr/bin/env python3
"""
FINAL FIX: Hybrid Workbook + Enhanced CustomEndpoint

FIXES:
1. Hybrid: Use working pattern - FunctionApp first, derive Subscription/ResourceGroup from it
2. CustomEndpoint: Enhanced cancellation and results tracking
"""

import json

ACTION_STRINGS = {
    "scan": "Run Antivirus Scan",
    "isolate": "Isolate Device",
    "unisolate": "Unisolate Device",
    "collect": "Collect Investigation Package",
    "restrict": "Restrict App Execution",
    "unrestrict": "Unrestrict App Execution"
}

def create_hybrid_fixed():
    """Fix Hybrid with working parameter pattern from workingexamples"""
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - Hybrid\\n\\n## ⚡ ARM Actions + 📊 Live Monitoring\\n\\n### ✅ Workflow:\\n1. Select Function App (auto-selects subscription/RG)\\n2. Select devices from inventory\\n3. Check conflicts\\n4. Execute ARM Actions\\n5. Monitor status with auto-refresh\\n\\n**Features**: Native ARM execution | Multi-device | Conflict detection | Auto-refresh | Cancellation"
        },
        "name": "header"
    })
    
    # FIXED Parameters - Use Working Pattern!
    params = [
        # FunctionApp FIRST (no dependencies)
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
        # Subscription - DERIVED from FunctionApp
        {
            "id": "sub",
            "version": "KqlParameterItem/1.0",
            "name": "Subscription",
            "type": 1,
            "isRequired": True,
            "isGlobal": True,
            "query": "Resources | where id == '{FunctionApp}' | project value = subscriptionId",
            "crossComponentResources": ["value::all"],
            "isHiddenWhenLocked": True,
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
        },
        # ResourceGroup - DERIVED from FunctionApp
        {
            "id": "rg",
            "version": "KqlParameterItem/1.0",
            "name": "ResourceGroup",
            "type": 1,
            "isRequired": True,
            "isGlobal": True,
            "query": "Resources | where id == '{FunctionApp}' | project value = resourceGroup",
            "crossComponentResources": ["value::all"],
            "isHiddenWhenLocked": True,
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
        },
        # FunctionAppName - DERIVED from FunctionApp
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
        # TenantId
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
        # DeviceList
        {
            "id": "dev",
            "version": "KqlParameterItem/1.0",
            "name": "DeviceList",
            "label": "🖥️ Selected Devices (comma-separated)",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
        # ActionIdToCancel
        {
            "id": "aid",
            "version": "KqlParameterItem/1.0",
            "name": "ActionIdToCancel",
            "label": "🗑️ Action ID",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
        # AutoRefresh
        {
            "id": "ref",
            "version": "KqlParameterItem/1.0",
            "name": "AutoRefresh",
            "label": "🔄 Auto Refresh",
            "type": 2,
            "isGlobal": True,
            "typeSettings": {"additionalResourceOptions": [], "showDefault": False},
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
    
    # Device Inventory
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 💻 Device Inventory\\n\\n**Click '✅ Select' to add devices**"},
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
                            {"path": "$.riskScore", "columnid": "Risk"}
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
                        "columnMatch": "Risk",
                        "formatter": 8,
                        "formatOptions": {"palette": "redGreen"}
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
        "content": {"json": "---\\n\\n## ⚠️ Conflict Check\\n\\n**Devices:** {DeviceList}"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
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
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "Running Action"},
                            {"path": "$.id", "columnid": "Action ID"},
                            {"path": "$.status", "columnid": "Status"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Running Actions on Selected Devices",
            "noDataMessage": "✅ No conflicts - safe to execute",
            "noDataMessageStyle": 3,
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
                    }
                ],
                "filter": True
            }
        },
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "conflict-check"
    })
    
    # ARM Actions
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚡ ARM Actions\\n\\n**Devices:** {DeviceList}"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
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
                "path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
                "headers": [],
                "params": [
                    {"name": "action", "value": action_str},
                    {"name": "tenantId", "value": "{TenantId}"},
                    {"name": "deviceIds", "value": "{DeviceList}"},
                    {"name": "comment", "value": f"{action_str} via Workbook"}
                ],
                "body": None,
                "httpMethod": "POST",
                "title": action_str,
                "description": f"Execute {action_str} on: {{DeviceList}}",
                "runLabel": "Execute",
                "successMessage": f"✅ {action_str} initiated!",
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
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "arm-actions"
    })
    
    # Status Tracking
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 📊 Status Tracking"},
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
            "title": "⚙️ All Actions",
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
    
    # Cancellation
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ❌ Cancel Action\\n\\n**Action ID:** {ActionIdToCancel}"},
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
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
                    {"key": "comment", "value": "Cancelled via Workbook"}
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
            "visualization": "table"
        },
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-result"
    })
    
    return workbook


def create_customendpoint_enhanced():
    """Enhanced CustomEndpoint with better cancellation and results"""
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - CustomEndpoint\\n\\n## 🚀 Full-Featured Control Panel\\n\\n### ✅ Workflow:\\n1. Select devices from inventory\\n2. Check for conflicts\\n3. Choose action + type 'EXECUTE'\\n4. Monitor results in real-time\\n5. Cancel actions if needed\\n\\n**Features**: Multi-device | Conflict detection | Confirmation | Auto-refresh | Enhanced cancellation | Result tracking"
        },
        "name": "header"
    })
    
    # Parameters (same as before but cleaner)
    params = [
        # FunctionApp
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
        # FunctionAppName
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
        # TenantId
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
        # DeviceList
        {
            "id": "dev",
            "version": "KqlParameterItem/1.0",
            "name": "DeviceList",
            "label": "🖥️ Selected Devices",
            "type": 1,
            "isGlobal": True,
            "value": "",
            "description": "Click devices below or paste IDs (comma-separated)"
        },
        # ActionToExecute
        {
            "id": "act",
            "version": "KqlParameterItem/1.0",
            "name": "ActionToExecute",
            "label": "⚡ Action",
            "type": 2,
            "isRequired": True,
            "isGlobal": True,
            "typeSettings": {"additionalResourceOptions": [], "showDefault": False},
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
        # ConfirmExecution
        {
            "id": "conf",
            "version": "KqlParameterItem/1.0",
            "name": "ConfirmExecution",
            "label": "⚠️ Confirmation",
            "type": 1,
            "isGlobal": True,
            "value": "",
            "description": "Type 'EXECUTE' to confirm"
        },
        # ActionIdToCancel
        {
            "id": "aid",
            "version": "KqlParameterItem/1.0",
            "name": "ActionIdToCancel",
            "label": "🗑️ Action ID",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
        # AutoRefresh
        {
            "id": "ref",
            "version": "KqlParameterItem/1.0",
            "name": "AutoRefresh",
            "label": "🔄 Auto Refresh",
            "type": 2,
            "isGlobal": True,
            "typeSettings": {"additionalResourceOptions": [], "showDefault": False},
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
    
    # Device Inventory (same structure)
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 💻 Device Inventory\\n\\n**Click '✅ Select' to add devices**"},
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
                            {"path": "$.riskScore", "columnid": "Risk"}
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
                    }
                ],
                "filter": True
            }
        },
        "name": "inventory"
    })
    
    # Conflict Detection
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚠️ Conflict Detection\\n\\n**Devices:** {DeviceList} | **Action:** {ActionToExecute}"},
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
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "Running Action"},
                            {"path": "$.id", "columnid": "Action ID"},
                            {"path": "$.status", "columnid": "Status"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Running Actions",
            "noDataMessage": "✅ NO CONFLICTS - Safe to execute",
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
                                {"operator": "==", "thresholdValue": "{ActionToExecute}", "representation": "redBright", "text": "🚨 {0} - CONFLICT!"},
                                {"operator": "Default", "representation": "orange", "text": "⚠️ {0}"}
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
    
    # Execution Instructions
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚡ Execute Action\\n\\n**Devices:** {DeviceList}  \\n**Action:** {ActionToExecute}  \\n**Confirmation:** {ConfirmExecution}\\n\\n### ✅ Checklist:\\n- ✓ Devices selected\\n- ✓ Action chosen\\n- ✓ No conflicts detected\\n- ⚠️ **Type 'EXECUTE' above**\\n\\n### 🚨 Warning:\\nIf conflict detected, cancel it first!"},
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "exec-instructions"
    })
    
    # Execution Result
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
                    {"key": "comment", "value": "{ActionToExecute} via Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "✅ Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.details", "columnid": "Details"},
                            {"path": "$.actionIds[0]", "columnid": "First Action ID"},
                            {"path": "$.actionIds", "columnid": "All Action IDs"},
                            {"path": "$.error", "columnid": "❌ Error"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "🚀 Execution Result",
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
                                {"operator": "contains", "thresholdValue": "success", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
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
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"},
            {"parameterName": "ConfirmExecution", "comparison": "isEqualTo", "value": "EXECUTE"}
        ],
        "name": "execution-result"
    })
    
    # Status Tracking
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 📊 Status Tracking"},
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
            "title": "⚙️ All Actions",
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
    
    # Enhanced Cancellation Section
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ❌ Cancel Machine Action\\n\\n**Action ID:** {ActionIdToCancel}\\n\\n**How to Cancel:**\\n1. Click any Action ID in tables above\\n2. Parameter auto-populates\\n3. Cancellation executes automatically\\n4. Result shows below"},
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
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
                    {"key": "comment", "value": "Cancelled via Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "✅ Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.details", "columnid": "Details"},
                            {"path": "$.error", "columnid": "❌ Error"}
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
                                {"operator": "contains", "thresholdValue": "success", "representation": "green", "text": "✅ {0}"},
                                {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
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
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-result"
    })
    
    return workbook


if __name__ == "__main__":
    print("="*80)
    print("FINAL FIX: Hybrid Parameter Chain + Enhanced CustomEndpoint")
    print("="*80)
    print()
    print("HYBRID FIX:")
    print("  ✓ FunctionApp selected FIRST (no dependencies)")
    print("  ✓ Subscription DERIVED from FunctionApp")
    print("  ✓ ResourceGroup DERIVED from FunctionApp")
    print("  ✓ FunctionAppName DERIVED from FunctionApp")
    print("  ✓ Uses crossComponentResources: ['value::all']")
    print()
    print("CUSTOMENDPOINT ENHANCEMENTS:")
    print("  ✓ Enhanced cancellation section with instructions")
    print("  ✓ Better result display with all Action IDs")
    print("  ✓ Improved formatting and icons")
    print("  ✓ Clearer workflow steps")
    print()
    
    wb_hybrid = create_hybrid_fixed()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-Hybrid.json', 'w') as f:
        json.dump(wb_hybrid, f, indent=2)
    print("✅ Hybrid workbook FIXED and saved")
    
    wb_ce = create_customendpoint_enhanced()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-CustomEndpoint.json', 'w') as f:
        json.dump(wb_ce, f, indent=2)
    print("✅ CustomEndpoint workbook ENHANCED and saved")
    
    print()
    print("="*80)
    print("READY TO DEPLOY - Parameters will now auto-populate!")
    print("="*80)
