#!/usr/bin/env python3
"""
Final workbook fix with:
1. Correct action strings (with spaces matching DefenderC2Dispatcher/run.ps1)
2. Manual device ID input option
3. Confirmation parameter for destructive actions
4. Fixed auto-population for Hybrid
"""

import json

# Action strings MUST match DefenderC2Dispatcher/run.ps1 exactly:
ACTIONS = {
    "scan": "Run Antivirus Scan",
    "isolate": "Isolate Device",
    "unisolate": "Unisolate Device",
    "collect": "Collect Investigation Package",
    "restrict": "Restrict App Execution",
    "unrestrict": "Unrestrict App Execution"
}

def create_customendpoint():
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
            "json": "# 🖥️ DefenderC2 Device Manager - CustomEndpoint\\n\\n## Device Selection Options:\\n1. **Click** device from inventory\\n2. **Type/Paste** device ID manually\\n\\n## Workflow:\\n✅ Select Device → ✅ Choose Action → ⚠️ Check Conflicts → ✅ Type 'EXECUTE' → ✅ Run"
        },
        "name": "header"
    })
    
    # Parameters with confirmation
    workbook["items"].append({
        "type": 9,
        "content": {
            "version": "KqlParameterItem/1.0",
            "parameters": [
                {"id": "fa", "version": "KqlParameterItem/1.0", "name": "FunctionApp", "label": "Function App", "type": 5, "isRequired": True, "isGlobal": True,
                 "query": "Resources | where type == 'microsoft.web/sites' and kind == 'functionapp' | project id, name",
                 "crossComponentResources": ["value::all"], "typeSettings": {"additionalResourceOptions": ["value::1"], "showDefault": False, "resourceTypeFilter": {"microsoft.web/sites": True}},
                 "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "fn", "version": "KqlParameterItem/1.0", "name": "FunctionAppName", "type": 1, "isRequired": True, "isGlobal": True,
                 "query": "Resources | where id == '{FunctionApp}' | project value = name", "crossComponentResources": ["value::all"], "isHiddenWhenLocked": True,
                 "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "tid", "version": "KqlParameterItem/1.0", "name": "TenantId", "label": "Defender Tenant", "type": 2, "isRequired": True, "isGlobal": True,
                 "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('Tenant: ', tenantId)",
                 "crossComponentResources": ["value::all"], "typeSettings": {"additionalResourceOptions": [], "selectFirstItem": True}, "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "dev", "version": "KqlParameterItem/1.0", "name": "DeviceList", "label": "🖥️ Device ID (click below OR type/paste)", "type": 1, "value": "", "isGlobal": True},
                
                {"id": "act", "version": "KqlParameterItem/1.0", "name": "ActionToExecute", "label": "⚡ Action", "type": 2, "isRequired": True, "isGlobal": True,
                 "jsonData": json.dumps([
                     {"value": "none", "label": "-- Select --"},
                     {"value": ACTIONS["scan"], "label": "🔍 Run Antivirus Scan"},
                     {"value": ACTIONS["isolate"], "label": "🔒 Isolate Device (DESTRUCTIVE)"},
                     {"value": ACTIONS["unisolate"], "label": "🔓 Unisolate Device"},
                     {"value": ACTIONS["collect"], "label": "📦 Collect Package"},
                     {"value": ACTIONS["restrict"], "label": "🚫 Restrict Apps (DESTRUCTIVE)"},
                     {"value": ACTIONS["unrestrict"], "label": "✅ Unrestrict Apps"}
                 ]), "value": "none"},
                
                {"id": "conf", "version": "KqlParameterItem/1.0", "name": "ConfirmExecution", "label": "⚠️ Type 'EXECUTE' to confirm", "type": 1, "value": "", "isGlobal": True},
                {"id": "aid", "version": "KqlParameterItem/1.0", "name": "ActionIdToCancel", "label": "🗑️ Action ID (cancel)", "type": 1, "value": "", "isGlobal": True},
                {"id": "ref", "version": "KqlParameterItem/1.0", "name": "AutoRefresh", "label": "🔄 Refresh", "type": 2, "isGlobal": True,
                 "jsonData": json.dumps([{"value": "0", "label": "Off"}, {"value": "30000", "label": "30s"}, {"value": "60000", "label": "60s"}]), "value": "30000"}
            ],
            "style": "pills", "queryType": 0, "resourceType": "microsoft.operationalinsights/workspaces"
        },
        "name": "params"
    })
    
    # Device Inventory
    workbook["items"].append({"type": 1, "content": {"json": "---\\n## 💻 Device Inventory\\n**Click 'Select' or copy Device ID**"}, "name": "inv-hdr"})
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get Devices"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.devices[*]",
                    "columns": [
                        {"path": "$.id", "columnid": "Device ID"},
                        {"path": "$.computerDnsName", "columnid": "Name"},
                        {"path": "$.osPlatform", "columnid": "OS"},
                        {"path": "$.healthStatus", "columnid": "Health"}
                    ]
                }}]
            }),
            "size": 0, "title": "🖥️ Devices", "queryType": 10, "visualization": "table",
            "gridSettings": {
                "formatters": [
                    {"columnMatch": "Device ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "✅ Select", "parameterName": "DeviceList", "parameterValue": "{0}"}},
                    {"columnMatch": "Health", "formatter": 18, "formatOptions": {"thresholdsOptions": "icons", "thresholdsGrid": [{"operator": "==", "thresholdValue": "Active", "representation": "success", "text": "✅ {0}"}]}}
                ],
                "filter": True
            }
        },
        "name": "inv-table"
    })
    
    # Conflict Check
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ⚠️ Conflict Check\\n**Device:** {DeviceList} | **Action:** {ActionToExecute}"},
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "conf-hdr"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get All Actions"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.actions[?(@.machineId == '{DeviceList}' && @.type == '{ActionToExecute}' && (@.status == 'Pending' || @.status == 'InProgress'))]",
                    "columns": [
                        {"path": "$.type", "columnid": "Action"},
                        {"path": "$.status", "columnid": "Status"},
                        {"path": "$.id", "columnid": "ID"}
                    ]
                }}]
            }),
            "size": 0, "title": "🚨 CONFLICT DETECTED", "noDataMessage": "✅ No conflicts. Safe to execute.", "noDataMessageStyle": 3,
            "timeContext": {"durationMs": 0}, "timeContextFromParameter": "AutoRefresh", "queryType": 10, "visualization": "table",
            "gridSettings": {"formatters": [
                {"columnMatch": "Action", "formatter": 18, "formatOptions": {"thresholdsOptions": "colors", "thresholdsGrid": [{"operator": "Default", "representation": "redBright", "text": "🚨 {0}"}]}},
                {"columnMatch": "ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "❌ Cancel", "parameterName": "ActionIdToCancel", "parameterValue": "{0}"}}
            ]}
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "conf-table"
    })
    
    # Execution
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ⚡ Execute\\n**Confirmation:** {ConfirmExecution}\\n\\n⚠️ **Type 'EXECUTE' above to enable**"},
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"}
        ],
        "name": "exec-hdr"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [
                    {"key": "action", "value": "{ActionToExecute}"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "deviceIds", "value": "{DeviceList}"},
                    {"key": "comment", "value": "Workbook execution"}
                ],
                "transformers": [{"type": "jsonpath", "settings": {
                    "columns": [
                        {"path": "$.message", "columnid": "Result"},
                        {"path": "$.actionIds[0]", "columnid": "Action ID"},
                        {"path": "$.status", "columnid": "Status"}
                    ]
                }}]
            }),
            "size": 0, "title": "✅ Result", "queryType": 10, "visualization": "table",
            "gridSettings": {"formatters": [
                {"columnMatch": "Action ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "📋 Track", "parameterName": "ActionIdToCancel", "parameterValue": "{0}"}},
                {"columnMatch": "Status", "formatter": 18, "formatOptions": {"thresholdsOptions": "colors", "thresholdsGrid": [
                    {"operator": "contains", "thresholdValue": "Initiated", "representation": "green", "text": "✅ {0}"},
                    {"operator": "contains", "thresholdValue": "error", "representation": "redBright", "text": "❌ {0}"}
                ]}}
            ]}
        },
        "conditionalVisibilities": [
            {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
            {"parameterName": "ActionToExecute", "comparison": "isNotEqualTo", "value": "none"},
            {"parameterName": "ConfirmExecution", "comparison": "isEqualTo", "value": "EXECUTE"}
        ],
        "name": "exec-result"
    })
    
    # Status Tracking
    workbook["items"].append({"type": 1, "content": {"json": "---\\n## 📊 Action Status"}, "name": "status-hdr"})
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get All Actions"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.actions[*]",
                    "columns": [
                        {"path": "$.machineId", "columnid": "Device ID"},
                        {"path": "$.computerDnsName", "columnid": "Device"},
                        {"path": "$.type", "columnid": "Action"},
                        {"path": "$.id", "columnid": "ID"},
                        {"path": "$.status", "columnid": "Status"}
                    ]
                }}]
            }),
            "size": 0, "title": "⚙️ All Actions", "timeContext": {"durationMs": 0}, "timeContextFromParameter": "AutoRefresh",
            "queryType": 10, "visualization": "table",
            "gridSettings": {"formatters": [
                {"columnMatch": "ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "❌", "parameterName": "ActionIdToCancel", "parameterValue": "{0}"}},
                {"columnMatch": "Status", "formatter": 18, "formatOptions": {"thresholdsOptions": "icons", "thresholdsGrid": [
                    {"operator": "==", "thresholdValue": "Pending", "representation": "pending", "text": "⏳ {0}"},
                    {"operator": "==", "thresholdValue": "InProgress", "representation": "2", "text": "⚙️ {0}"},
                    {"operator": "==", "thresholdValue": "Succeeded", "representation": "success", "text": "✅ {0}"},
                    {"operator": "==", "thresholdValue": "Failed", "representation": "failed", "text": "❌ {0}"}
                ]}}
            ], "sortBy": [{"itemKey": "ID", "sortOrder": 2}]}
        },
        "name": "status-table"
    })
    
    # Cancel
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ❌ Cancel Action\\n**ID:** {ActionIdToCancel}"},
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-hdr"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [
                    {"key": "action", "value": "Cancel Action"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "actionId", "value": "{ActionIdToCancel}"},
                    {"key": "comment", "value": "Cancelled"}
                ],
                "transformers": [{"type": "jsonpath", "settings": {
                    "columns": [
                        {"path": "$.message", "columnid": "Result"},
                        {"path": "$.status", "columnid": "Status"}
                    ]
                }}]
            }),
            "size": 0, "title": "✅ Cancellation", "queryType": 10, "visualization": "table"
        },
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-result"
    })
    
    return workbook


def create_hybrid():
    """Hybrid with fixed parameter dependencies"""
    workbook = {
        "version": "Notebook/1.0",
        "items": [],
        "styleSettings": {},
        "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
    }
    
    # Header
    workbook["items"].append({
        "type": 1,
        "content": {"json": "# 🖥️ DefenderC2 Device Manager - Hybrid\\n\\n## ARM Actions + Monitoring\\n\\n1. Select Device\\n2. Check Conflicts\\n3. Execute ARM Action"},
        "name": "header"
    })
    
    # Parameters - FIXED: Dependencies must be correct
    workbook["items"].append({
        "type": 9,
        "content": {
            "version": "KqlParameterItem/1.0",
            "parameters": [
                {"id": "sub", "version": "KqlParameterItem/1.0", "name": "Subscription", "label": "Subscription", "type": 6, "isRequired": True, "isGlobal": True,
                 "typeSettings": {"additionalResourceOptions": ["value::1"], "includeAll": False, "showDefault": False}},
                
                {"id": "rg", "version": "KqlParameterItem/1.0", "name": "ResourceGroup", "label": "Resource Group", "type": 2, "isRequired": True, "isGlobal": True,
                 "query": "ResourceContainers | where type == 'microsoft.resources/resourcegroups' and subscriptionId == '{Subscription:id}' | project value = name, label = name",
                 "crossComponentResources": ["{Subscription}"], "typeSettings": {"additionalResourceOptions": [], "showDefault": False},
                 "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "fa", "version": "KqlParameterItem/1.0", "name": "FunctionApp", "label": "Function App", "type": 5, "isRequired": True, "isGlobal": True,
                 "query": "Resources | where type == 'microsoft.web/sites' and kind == 'functionapp' and resourceGroup == '{ResourceGroup}' and subscriptionId == '{Subscription:id}' | project id, name",
                 "crossComponentResources": ["{Subscription}"], "typeSettings": {"additionalResourceOptions": ["value::1"], "showDefault": False, "resourceTypeFilter": {"microsoft.web/sites": True}},
                 "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "fn", "version": "KqlParameterItem/1.0", "name": "FunctionAppName", "type": 1, "isRequired": True, "isGlobal": True,
                 "query": "Resources | where id == '{FunctionApp}' | project value = name", "crossComponentResources": ["{Subscription}"], "isHiddenWhenLocked": True,
                 "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "tid", "version": "KqlParameterItem/1.0", "name": "TenantId", "label": "Defender Tenant", "type": 2, "isRequired": True, "isGlobal": True,
                 "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project tenantId | distinct tenantId | project value = tenantId, label = strcat('Tenant: ', tenantId)",
                 "crossComponentResources": ["value::all"], "typeSettings": {"additionalResourceOptions": [], "selectFirstItem": True}, "queryType": 1, "resourceType": "microsoft.resourcegraph/resources"},
                
                {"id": "dev", "version": "KqlParameterItem/1.0", "name": "DeviceList", "label": "🖥️ Device ID", "type": 1, "value": "", "isGlobal": True},
                {"id": "aid", "version": "KqlParameterItem/1.0", "name": "ActionIdToCancel", "label": "🗑️ Action ID", "type": 1, "value": "", "isGlobal": True},
                {"id": "ref", "version": "KqlParameterItem/1.0", "name": "AutoRefresh", "label": "🔄 Refresh", "type": 2, "isGlobal": True,
                 "jsonData": json.dumps([{"value": "0", "label": "Off"}, {"value": "30000", "label": "30s"}]), "value": "30000"}
            ],
            "style": "pills", "queryType": 0, "resourceType": "microsoft.operationalinsights/workspaces"
        },
        "name": "params"
    })
    
    # Device Inventory
    workbook["items"].append({"type": 1, "content": {"json": "---\\n## 💻 Device Inventory"}, "name": "inv-hdr"})
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get Devices"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.devices[*]",
                    "columns": [
                        {"path": "$.id", "columnid": "Device ID"},
                        {"path": "$.computerDnsName", "columnid": "Name"},
                        {"path": "$.healthStatus", "columnid": "Health"}
                    ]
                }}]
            }),
            "size": 0, "title": "🖥️ Devices", "queryType": 10, "visualization": "table",
            "gridSettings": {"formatters": [
                {"columnMatch": "Device ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "✅", "parameterName": "DeviceList", "parameterValue": "{0}"}}
            ], "filter": True}
        },
        "name": "inv-table"
    })
    
    # Conflict Check
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ⚠️ Conflicts\\n**Device:** {DeviceList}"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "conf-hdr"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get All Actions"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.actions[?(@.machineId == '{DeviceList}' && (@.status == 'Pending' || @.status == 'InProgress'))]",
                    "columns": [
                        {"path": "$.type", "columnid": "Action"},
                        {"path": "$.status", "columnid": "Status"}
                    ]
                }}]
            }),
            "size": 0, "title": "⚙️ Running", "noDataMessage": "✅ No conflicts", "noDataMessageStyle": 3,
            "timeContext": {"durationMs": 0}, "timeContextFromParameter": "AutoRefresh", "queryType": 10, "visualization": "table"
        },
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "conf-table"
    })
    
    # ARM Actions
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ⚡ ARM Actions\\n**Device:** {DeviceList}"},
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "arm-hdr"
    })
    
    workbook["items"].append({
        "type": 11,
        "content": {
            "version": "LinkItem/1.0",
            "style": "list",
            "links": [
                {
                    "id": f"arm-{key}",
                    "linkTarget": "ArmAction",
                    "linkLabel": label,
                    "style": "primary" if key in ["scan", "collect"] else "secondary",
                    "linkIsContextBlade": False,
                    "armActionContext": {
                        "path": "/subscriptions/{Subscription:id}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/DefenderC2Dispatcher/invocations?api-version=2022-03-01",
                        "headers": [],
                        "params": [
                            {"name": "action", "value": action_str},
                            {"name": "tenantId", "value": "{TenantId}"},
                            {"name": "deviceIds", "value": "{DeviceList}"},
                            {"name": "comment", "value": f"{label} via Workbook"}
                        ],
                        "body": None,
                        "httpMethod": "POST",
                        "title": label,
                        "description": f"Execute on {'{DeviceList}'}",
                        "runLabel": "Execute",
                        "successMessage": f"✅ {label} initiated!",
                        "actionName": f"arm-{key}"
                    }
                }
                for key, action_str in ACTIONS.items()
                for label in [action_str.replace(" Device", "").replace(" App Execution", "")]
            ]
        },
        "conditionalVisibility": {"parameterName": "DeviceList", "comparison": "isNotEqualTo", "value": ""},
        "name": "arm-actions"
    })
    
    # Status
    workbook["items"].append({"type": 1, "content": {"json": "---\\n## 📊 Status"}, "name": "status-hdr"})
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [{"key": "action", "value": "Get All Actions"}, {"key": "tenantId", "value": "{TenantId}"}],
                "transformers": [{"type": "jsonpath", "settings": {
                    "tablePath": "$.actions[*]",
                    "columns": [
                        {"path": "$.computerDnsName", "columnid": "Device"},
                        {"path": "$.type", "columnid": "Action"},
                        {"path": "$.id", "columnid": "ID"},
                        {"path": "$.status", "columnid": "Status"}
                    ]
                }}]
            }),
            "size": 0, "title": "⚙️ Actions", "timeContext": {"durationMs": 0}, "timeContextFromParameter": "AutoRefresh",
            "queryType": 10, "visualization": "table",
            "gridSettings": {"formatters": [
                {"columnMatch": "ID", "formatter": 7, "formatOptions": {"linkTarget": "parameter", "linkLabel": "❌", "parameterName": "ActionIdToCancel", "parameterValue": "{0}"}},
                {"columnMatch": "Status", "formatter": 18, "formatOptions": {"thresholdsOptions": "icons", "thresholdsGrid": [
                    {"operator": "==", "thresholdValue": "Succeeded", "representation": "success", "text": "✅ {0}"},
                    {"operator": "==", "thresholdValue": "Failed", "representation": "failed", "text": "❌ {0}"}
                ]}}
            ]}
        },
        "name": "status-table"
    })
    
    # Cancel
    workbook["items"].append({
        "type": 1,
        "content": {"json": "---\\n## ❌ Cancel\\n**ID:** {ActionIdToCancel}"},
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-hdr"
    })
    
    workbook["items"].append({
        "type": 3,
        "content": {
            "version": "KqlItem/1.0",
            "query": json.dumps({
                "version": "CustomEndpoint/1.0", "data": None, "headers": [], "method": "POST",
                "url": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher", "body": None,
                "urlParams": [
                    {"key": "action", "value": "Cancel Action"},
                    {"key": "tenantId", "value": "{TenantId}"},
                    {"key": "actionId", "value": "{ActionIdToCancel}"},
                    {"key": "comment", "value": "Cancelled"}
                ],
                "transformers": [{"type": "jsonpath", "settings": {"columns": [{"path": "$.message", "columnid": "Result"}, {"path": "$.status", "columnid": "Status"}]}}]
            }),
            "size": 0, "title": "✅ Result", "queryType": 10, "visualization": "table"
        },
        "conditionalVisibility": {"parameterName": "ActionIdToCancel", "comparison": "isNotEqualTo", "value": ""},
        "name": "cancel-result"
    })
    
    return workbook


if __name__ == "__main__":
    print("="*70)
    print("CREATING WORKBOOKS WITH FIXES")
    print("="*70)
    print()
    print("KEY FIXES:")
    print("1. Action strings match DefenderC2Dispatcher/run.ps1 EXACTLY:")
    for key, val in ACTIONS.items():
        print(f"   - '{val}'")
    print()
    print("2. CustomEndpoint: Manual device ID input + confirmation parameter")
    print("3. Hybrid: Fixed parameter dependencies (Subscription→ResourceGroup→FunctionApp)")
    print()
    
    # Generate CustomEndpoint
    wb_ce = create_customendpoint()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-CustomEndpoint.json', 'w') as f:
        json.dump(wb_ce, f, indent=2)
    print("✅ CustomEndpoint workbook saved")
    
    # Generate Hybrid
    wb_hybrid = create_hybrid()
    with open('/workspaces/defenderc2xsoar/workbook/DeviceManager-Hybrid.json', 'w') as f:
        json.dump(wb_hybrid, f, indent=2)
    print("✅ Hybrid workbook saved")
    
    print()
    print("="*70)
    print("DEPLOYMENT READY")
    print("="*70)
