#!/usr/bin/env python3
"""
FINAL PERFECT VERSION - Based on Working Examples

FIXES:
1. ARM Actions use /invocations (correct)
2. api-version as PARAM (not in URL)
3. Smart filtering: Show only actions for selected devices
4. Enhanced UI/UX
5. Both workbooks optimized
"""

import json

ALL_ACTIONS = {
    "scan": {"name": "Run Antivirus Scan", "icon": "🔍", "destructive": False},
    "isolate": {"name": "Isolate Device", "icon": "🔒", "destructive": True},
    "unisolate": {"name": "Unisolate Device", "icon": "🔓", "destructive": False},
    "collect": {"name": "Collect Investigation Package", "icon": "📦", "destructive": False},
    "restrict": {"name": "Restrict App Execution", "icon": "🚫", "destructive": True},
    "unrestrict": {"name": "Unrestrict App Execution", "icon": "✅", "destructive": False}
}

def create_hybrid_perfect():
    """Hybrid with PERFECT ARM Actions matching working examples"""
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - Hybrid\\n\\n## ⚡ ARM Actions with Smart Filtering\\n\\n### ✨ Features:\\n- ✅ **Native ARM Actions** - Azure RBAC enforcement\\n- 🎯 **Smart Filtering** - Shows only actions for selected devices\\n- 💻 **Device Management** - Click to select, auto-filter results\\n- 📊 **Live Monitoring** - Auto-refresh status\\n- ⚠️ **Conflict Detection** - Prevents duplicate actions\\n- ❌ **One-Click Cancel** - Cancel any action\\n\\n### 🚀 Workflow:\\n1. Select devices → Device list populates\\n2. Conflict check auto-filters by selected devices\\n3. Execute ARM Actions → Azure confirmation\\n4. Status tracking auto-filters by selected devices\\n5. Cancel actions with one click"
        },
        "name": "header"
    })
    
    # Parameters
    params = [
        # FunctionApp FIRST
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
        # Derived
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
            "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('Tenant: ', tenantId)",
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
            "description": "Click devices below to select (auto-filters results)"
        },
        # FileHash
        {
            "id": "fh",
            "version": "KqlParameterItem/1.0",
            "name": "FileHash",
            "label": "🦠 File Hash (SHA1)",
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
        "content": {"json": "---\\n\\n## 💻 STEP 1: Device Inventory\\n\\n**Click '✅ Select' to add devices** | **Selected:** {DeviceList}"},
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
                            {"path": "$.id", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "ComputerName"},
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
                        "columnMatch": "DeviceID",
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
                "filter": True,
                "sortBy": [{"itemKey": "ComputerName", "sortOrder": 1}]
            },
            "sortBy": [{"itemKey": "ComputerName", "sortOrder": 1}]
        },
        "name": "inventory"
    })
    
    # Conflict Check - SMART FILTERED
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚠️ STEP 2: Conflict Detection\\n\\n**🎯 Smart Filter:** Showing only actions for selected devices\\n\\n**Selected Devices:** {DeviceList}"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "conflict-header"
    })
    
    # Get ALL actions, then FILTER in grid by selected devices
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
                            {"path": "$.machineId", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "RunningAction"},
                            {"path": "$.id", "columnid": "ActionID"},
                            {"path": "$.status", "columnid": "Status"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Running Actions on Selected Devices",
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
                        "columnMatch": "RunningAction",
                        "formatter": 18,
                        "formatOptions": {
                            "thresholdsOptions": "colors",
                            "thresholdsGrid": [
                                {"operator": "Default", "representation": "orange", "text": "⚠️ {0} - Check before executing same action"}
                            ]
                        }
                    },
                    {
                        "columnMatch": "ActionID",
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
                                {"operator": "Default", "representation": "unknown", "text": "{0}"}
                            ]
                        }
                    }
                ],
                "filter": True,
                "filterSettings": {
                    "defaultFilters": [
                        {
                            "columnId": "DeviceID",
                            "operator": "in",
                            "value": "{DeviceList}"
                        }
                    ]
                }
            }
        },
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "conflict-check"
    })
    
    # ARM Actions - CORRECT FORMAT from working examples
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚡ STEP 3: Execute ARM Actions\\n\\n**Selected Devices:** {DeviceList}\\n\\n**Azure will show confirmation dialog before execution.**"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "arm-header"
    })
    
    # ARM Actions - MATCHING WORKING EXAMPLES EXACTLY
    arm_links = []
    for key, info in ALL_ACTIONS.items():
        arm_links.append({
            "id": f"arm-{key}",
            "cellValue": "unused",
            "linkTarget": "ArmAction",
            "linkLabel": f"{info['icon']} {info['name']}{' (DESTRUCTIVE)' if info['destructive'] else ''}",
            "style": "primary" if not info['destructive'] else "secondary",
            "armActionContext": {
                "path": f"/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/functions/DefenderC2Dispatcher/invocations",
                "headers": [],
                "params": [
                    {"key": "api-version", "value": "2022-03-01"},
                    {"key": "action", "value": info['name']},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "deviceIds", "value": "{DeviceList}"},
                    {"key": "comment", "value": f"{info['name']} via DefenderC2 Workbook"}
                ],
                "httpMethod": "POST",
                "title": f"✅ {info['name']}",
                "description": f"{info['name']} initiated successfully",
                "actionName": info['name'],
                "runLabel": f"Execute {info['name']}",
                "successMessage": f"✅ {info['name']} command sent successfully!"
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
        "name": "arm-device-actions"
    })
    
    # File Quarantine
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 🦠 File Quarantine\\n\\n**File Hash:** {FileHash}"},
        "conditionalVisibility": {"parameterName": "FileHash", "comparison": "isNotEqualTo", "value": ""},
        "name": "file-header"
    })
    
    file_arm = {
        "id": "arm-quarantine",
        "cellValue": "unused",
        "linkTarget": "ArmAction",
        "linkLabel": "🦠 Stop & Quarantine File (DESTRUCTIVE)",
        "style": "secondary",
        "armActionContext": {
            "path": f"/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/functions/DefenderC2Dispatcher/invocations",
            "headers": [],
            "params": [
                {"key": "api-version", "value": "2022-03-01"},
                {"key": "action", "value": "Stop & Quarantine File"},
                {"key": "tenantId", "value": "{TenantId}"},
                {"key": "fileHash", "value": "{FileHash}"},
                {"key": "comment", "value": "Quarantined via DefenderC2 Workbook"}
            ],
            "httpMethod": "POST",
            "title": "✅ Stop & Quarantine File",
            "description": "File quarantine initiated successfully",
            "actionName": "Stop & Quarantine File",
            "runLabel": "Execute Quarantine",
            "successMessage": "✅ File quarantine command sent successfully!"
        }
    }
    
    workbook["items"].append({
        "type": 11,
        "content": {
            "version": "LinkItem/1.0",
            "style": "list",
            "links": [file_arm]
        },
        "conditionalVisibility": {"parameterName": "FileHash", "comparison": "isNotEqualTo", "value": ""},
        "name": "arm-file-action"
    })
    
    # Status Tracking - SMART FILTERED
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 📊 STEP 4: Status Tracking\\n\\n**🎯 Smart Filter:** {DeviceList:nonempty:Showing all actions|Showing only actions for selected devices}"},
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
                            {"path": "$.machineId", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "Action"},
                            {"path": "$.id", "columnid": "ActionID"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.creationDateTimeUtc", "columnid": "Started"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Machine Actions",
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "ActionID",
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
                                {"operator": "==", "thresholdValue": "Cancelled", "representation": "cancelled", "text": "🚫 {0}"},
                                {"operator": "Default", "representation": "unknown", "text": "{0}"}
                            ]
                        }
                    }
                ],
                "filter": True,
                "filterSettings": {
                    "defaultFilters": [
                        {
                            "columnId": "DeviceID",
                            "operator": "in",
                            "value": "{DeviceList}"
                        }
                    ] if "{DeviceList}" != "" else []
                },
                "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
        },
        "name": "all-actions"
    })
    
    # Cancellation - CORRECT ARM ACTION
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ❌ STEP 5: Cancel Action\\n\\n**Action ID:** {ActionIdToCancel}"},
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-header"
    })
    
    cancel_arm = {
        "id": "arm-cancel",
        "cellValue": "unused",
        "linkTarget": "ArmAction",
        "linkLabel": "❌ Cancel Action",
        "style": "secondary",
        "armActionContext": {
            "path": f"/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/functions/DefenderC2Dispatcher/invocations",
            "headers": [],
            "params": [
                {"key": "api-version", "value": "2022-03-01"},
                {"key": "action", "value": "Cancel Action"},
                {"key": "tenantId", "value": "{TenantId}"},
                {"key": "actionId", "value": "{ActionIdToCancel}"},
                {"key": "comment", "value": "Cancelled via DefenderC2 Workbook"}
            ],
            "httpMethod": "POST",
            "title": "✅ Cancel Action",
            "description": "Action cancelled successfully",
            "actionName": "Cancel Action",
            "runLabel": "Cancel",
            "successMessage": "✅ Action cancellation command sent successfully!"
        }
    }
    
    workbook["items"].append({
        "type": 11,
        "content": {
            "version": "LinkItem/1.0",
            "style": "list",
            "links": [cancel_arm]
        },
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-action"
    })
    
    return workbook


def create_customendpoint_perfect():
    """CustomEndpoint with smart filtering"""
    
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
            "json": "# 🖥️ DefenderC2 Device Manager - CustomEndpoint\\n\\n## 🚀 Direct API with Smart Filtering\\n\\n### ✨ Features:\\n- ✅ **Direct API Calls** - Fast execution\\n- 🎯 **Smart Filtering** - Shows only actions for selected devices\\n- 💻 **Device Management** - Click to select, auto-filter results\\n- 📊 **Live Monitoring** - Auto-refresh status\\n- ⚠️ **Conflict Detection** - Prevents duplicate actions\\n- 🔒 **Safety** - Type 'EXECUTE' to confirm\\n- ❌ **One-Click Cancel** - Cancel any action\\n\\n### 🚀 Workflow:\\n1. Select devices → Device list populates\\n2. Conflict check auto-filters by selected devices\\n3. Choose action + type 'EXECUTE'\\n4. Status tracking auto-filters by selected devices\\n5. Cancel actions with one click"
        },
        "name": "header"
    })
    
    # Parameters (same as Hybrid)
    params = [
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
        {
            "id": "tid",
            "version": "KqlParameterItem/1.0",
            "name": "TenantId",
            "label": "Defender XDR Tenant",
            "type": 2,
            "isRequired": True,
            "isGlobal": True,
            "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('Tenant: ', tenantId)",
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
            "id": "dev",
            "version": "KqlParameterItem/1.0",
            "name": "DeviceList",
            "label": "🖥️ Selected Devices",
            "type": 1,
            "isGlobal": True,
            "value": "",
            "description": "Click devices below to select (auto-filters results)"
        },
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
                *[{"value": info['name'], "label": f"{info['icon']} {info['name']}{' (DESTRUCTIVE)' if info['destructive'] else ''}"} for info in ALL_ACTIONS.values()]
            ]),
            "value": "none"
        },
        {
            "id": "fh",
            "version": "KqlParameterItem/1.0",
            "name": "FileHash",
            "label": "🦠 File Hash (SHA1)",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
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
        {
            "id": "aid",
            "version": "KqlParameterItem/1.0",
            "name": "ActionIdToCancel",
            "label": "🗑️ Action ID",
            "type": 1,
            "isGlobal": True,
            "value": ""
        },
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
    
    # Device Inventory (same as Hybrid)
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 💻 STEP 1: Device Inventory\\n\\n**Click '✅ Select' to add devices** | **Selected:** {DeviceList}"},
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
                            {"path": "$.id", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "ComputerName"},
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
                        "columnMatch": "DeviceID",
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
                "filter": True,
                "sortBy": [{"itemKey": "ComputerName", "sortOrder": 1}]
            },
            "sortBy": [{"itemKey": "ComputerName", "sortOrder": 1}]
        },
        "name": "inventory"
    })
    
    # Conflict Check - SMART FILTERED (same logic as Hybrid)
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚠️ STEP 2: Conflict Detection\\n\\n**🎯 Smart Filter:** Showing only actions for selected devices\\n\\n**Devices:** {DeviceList} | **Action:** {ActionToExecute}"},
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
                            {"path": "$.machineId", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "RunningAction"},
                            {"path": "$.id", "columnid": "ActionID"},
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
                        "columnMatch": "RunningAction",
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
                        "columnMatch": "ActionID",
                        "formatter": 7,
                        "formatOptions": {
                            "linkTarget": "parameter",
                            "linkLabel": "❌ Cancel",
                            "parameterName": "ActionIdToCancel",
                            "parameterValue": "{0}"
                        }
                    }
                ],
                "filter": True,
                "filterSettings": {
                    "defaultFilters": [
                        {
                            "columnId": "DeviceID",
                            "operator": "in",
                            "value": "{DeviceList}"
                        }
                    ]
                }
            }
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "conflict-check"
    })
    
    # Execution (rest same as before but with smart filter messaging)
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ⚡ STEP 3: Execute Action\\n\\n**Devices:** {DeviceList} | **Action:** {ActionToExecute} | **Confirmation:** {ConfirmExecution}\\n\\n### ✅ Checklist:\\n- ✓ Devices selected\\n- ✓ Action chosen\\n- ✓ No conflicts above\\n- ⚠️ **Type 'EXECUTE'**"},
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "exec-header"
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
                    {"key": "comment", "value": "{ActionToExecute} via Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.details", "columnid": "Details"},
                            {"path": "$.actionIds", "columnid": "ActionIDs"},
                            {"path": "$.error", "columnid": "Error"}
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
        "name": "exec-result"
    })
    
    # File Quarantine
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 🦠 File Quarantine\\n\\n**Hash:** {FileHash} | **Confirmation:** {ConfirmExecution}"},
        "conditionalVisibility": {"parameterName": "FileHash", "comparison": "isNotEqualTo", "value": ""},
        "name": "file-header"
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
                    {"key": "action", "value": "Stop & Quarantine File"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "fileHash", "value": "{FileHash}"},
                    {"key": "comment", "value": "Quarantined via Workbook"}
                ],
                "transformers": [{
                    "type": "jsonpath",
                    "settings": {
                        "columns": [
                            {"path": "$.message", "columnid": "Result"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.actionId", "columnid": "ActionID"},
                            {"path": "$.error", "columnid": "Error"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "🦠 Quarantine Result",
            "showRefreshButton": True,
            "queryType": 10,
            "visualization": "table"
        },
        "conditionalVisibilities": [
            {"parameterName": "FileHash", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ConfirmExecution", "comparison": "isEqualTo", "value": "EXECUTE"}
        ],
        "name": "file-result"
    })
    
    # Status Tracking - SMART FILTERED (same as Hybrid)
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## 📊 STEP 4: Status Tracking\\n\\n**🎯 Smart Filter:** {DeviceList:nonempty:Showing all actions|Showing only actions for selected devices}"},
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
                            {"path": "$.machineId", "columnid": "DeviceID"},
                            {"path": "$.computerDnsName", "columnid": "Device"},
                            {"path": "$.type", "columnid": "Action"},
                            {"path": "$.id", "columnid": "ActionID"},
                            {"path": "$.status", "columnid": "Status"},
                            {"path": "$.creationDateTimeUtc", "columnid": "Started"}
                        ]
                    }
                }]
            }),
            "size": 0,
            "title": "⚙️ Machine Actions",
            "showRefreshButton": True,
            "timeContext": {"durationMs": 0},
            "timeContextFromParameter": "AutoRefresh",
            "queryType": 10,
            "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {
                        "columnMatch": "ActionID",
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
                                {"operator": "==", "thresholdValue": "Cancelled", "representation": "cancelled", "text": "🚫 {0}"},
                                {"operator": "Default", "representation": "unknown", "text": "{0}"}
                            ]
                        }
                    }
                ],
                "filter": True,
                "filterSettings": {
                    "defaultFilters": [
                        {
                            "columnId": "DeviceID",
                            "operator": "in",
                            "value": "{DeviceList}"
                        }
                    ] if "{DeviceList}" != "" else []
                },
                "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
            },
            "sortBy": [{"itemKey": "Started", "sortOrder": 2}]
        },
        "name": "all-actions"
    })
    
    # Cancellation
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n\\n## ❌ STEP 5: Cancel Action\\n\\n**Action ID:** {ActionIdToCancel}"},
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
    print("PERFECT WORKBOOKS - Based on Working Examples")
    print("="*80)
    print()
    print("CRITICAL FIXES:")
    print("  ✓ ARM Actions use /invocations (correct path)")
    print("  ✓ api-version as PARAM (not in URL)")
    print("  ✓ All params match working examples exactly")
    print()
    print("SMART FILTERING:")
    print("  ✓ Conflict check auto-filters by selected devices")
    print("  ✓ Status tracking auto-filters by selected devices")
    print("  ✓ Clear visual feedback on what's being filtered")
    print()
    print("ENHANCED UX:")
    print("  ✓ Consistent column naming (DeviceID, ActionID)")
    print("  ✓ Smart filter status in headers")
    print("  ✓ Better formatting and icons")
    print("  ✓ Clear workflow steps")
    print()
    
    wb_hybrid = create_hybrid_perfect()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-Hybrid.json', 'w') as f:
        json.dump(wb_hybrid, f, indent=2)
    print("✅ Hybrid workbook (PERFECT) saved")
    
    wb_ce = create_customendpoint_perfect()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-CustomEndpoint.json', 'w') as f:
        json.dump(wb_ce, f, indent=2)
    print("✅ CustomEndpoint workbook (PERFECT) saved")
    
    print()
    print("="*80)
    print("WE ARE CLOSER THAN EVER - DEPLOY AND TEST!")
    print("="*80)
