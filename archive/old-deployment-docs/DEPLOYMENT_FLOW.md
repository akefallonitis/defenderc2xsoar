# DefenderC2 Deployment Flow Diagram

## Complete Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     deploy-all.ps1                              │
│              One-Command Complete Deployment                     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ├─────────────────────┬───────────────────┐
                            │                     │                   │
                            ▼                     ▼                   ▼
              ┌─────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
              │  deploy-complete.ps1│  │deploy-workbook.ps1│  │  Parameters     │
              │                     │  │                   │  │                 │
              │ Function App        │  │ Workbooks         │  │ - ResourceGroup │
              │ Deployment          │  │ Deployment        │  │ - FunctionApp   │
              └──────────┬──────────┘  └─────────┬─────────┘  │ - WorkspaceID   │
                         │                       │             │ - AppId/Secret  │
                         │                       │             └─────────────────┘
                         │                       │
                         ▼                       ▼
            ┌────────────────────┐   ┌───────────────────────┐
            │ azuredeploy.json   │   │workbook-deploy.json   │
            │                    │   │                       │
            │ ARM Template       │   │ ARM Template          │
            └────────┬───────────┘   └──────────┬────────────┘
                     │                          │
                     │                          │
                     ▼                          ▼
        ┌────────────────────────┐  ┌──────────────────────────┐
        │  Azure Resources       │  │  Azure Monitor           │
        │                        │  │                          │
        │  • Function App        │  │  • DefenderC2 Workbook   │
        │  • Storage Account     │  │  • File Ops Workbook     │
        │  • App Service Plan    │  │                          │
        │  • Managed Identity    │  │  Parameters Set:         │
        │                        │  │  ✓ FunctionAppName       │
        │  Env Variables Set:    │  │  ✓ WorkspaceID          │
        │  ✓ APPID               │  │  ✓ Subscription         │
        │  ✓ SECRETID            │  │                          │
        └────────────────────────┘  └──────────────────────────┘
```

## Deployment Script Relationships

```
deploy-all.ps1
  │
  ├─> Parameter Validation
  │     ├─ ResourceGroupName
  │     ├─ FunctionAppName
  │     ├─ AppId/ClientSecret
  │     └─ WorkspaceResourceId
  │
  ├─> Step 1: Function App (if not skipped)
  │     │
  │     └─> deploy-complete.ps1
  │           │
  │           ├─> Create resource group (if needed)
  │           ├─> Register app (if needed)
  │           ├─> Deploy ARM template (azuredeploy.json)
  │           │     └─> Creates:
  │           │         • Function App
  │           │         • Storage Account
  │           │         • App Service Plan
  │           │         • Sets APPID/SECRETID env vars
  │           └─> Deploy function code
  │
  └─> Step 2: Workbooks (if not skipped)
        │
        └─> deploy-workbook.ps1
              │
              ├─> Load DefenderC2-Workbook.json
              │     └─> Update FunctionAppName parameter
              │
              ├─> Load FileOperations.workbook
              │     └─> Update FunctionAppName parameter
              │
              └─> Deploy via ARM template (workbook-deploy.json)
                    └─> Creates workbooks in Azure Monitor
```

## Parameter Flow

```
User Input Parameters
    │
    ├─ FunctionAppName: "defc2"
    │    │
    │    ├─> azuredeploy.json
    │    │    └─> Creates: https://defc2.azurewebsites.net
    │    │
    │    └─> deploy-workbook.ps1
    │         └─> Sets in workbook JSON:
    │              {
    │                "name": "FunctionAppName",
    │                "value": "defc2"  ◄── Automatically set
    │              }
    │
    ├─ AppId: "12345..."
    │    └─> azuredeploy.json
    │         └─> Sets env var: APPID=12345...
    │
    ├─ ClientSecret: "secret..."
    │    └─> azuredeploy.json
    │         └─> Sets env var: SECRETID=secret...
    │
    └─ WorkspaceResourceId: "/subscriptions/.../workspaces/..."
         └─> workbook-deploy.json
              └─> Links workbook to workspace
```

## Workbook Parameter Configuration

```
Workbook JSON File (DefenderC2-Workbook.json)
    │
    ├─> FunctionAppName Parameter
    │     ├─ Type: Text input (1)
    │     ├─ Default: "defc2"  ◄── Updated by deploy-workbook.ps1
    │     ├─ Required: true
    │     └─ Used in: All ARMEndpoint paths
    │           Example: "https://{FunctionAppName}.azurewebsites.net/api/..."
    │
    ├─> TenantId Parameter
    │     ├─ Type: Resource Graph query (1)
    │     ├─ Auto-discovered: from workspace
    │     └─> Query: workspace.properties.customerId
    │
    ├─> Subscription Parameter
    │     ├─ Type: Dropdown
    │     └─ User selects: subscription context
    │
    └─> Workspace Parameter
          ├─ Type: Dropdown
          └─ User selects: Log Analytics workspace
```

## ARMEndpoint Query Execution Flow

```
User Action in Workbook (e.g., "Get Devices" button)
    │
    ▼
Workbook ARMEndpoint Query
    │
    ├─> Path: "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher"
    │    │
    │    └─> Resolves to: "https://defc2.azurewebsites.net/api/DefenderC2Dispatcher"
    │
    ├─> Method: POST
    │
    ├─> Headers: Content-Type: application/json
    │
    └─> Body (httpBodySchema):
         {
           "action": "Get Devices",
           "tenantId": "{TenantId}"  ◄── From TenantId parameter
         }
         │
         ▼
Azure Function (DefenderC2Dispatcher)
    │
    ├─> Read env vars: APPID, SECRETID
    │
    ├─> Authenticate to Azure AD
    │
    ├─> Call Microsoft Defender API
    │    └─> GET /api/machines
    │
    └─> Return devices JSON
         │
         ▼
Workbook Table Display
    └─> Shows device list with columns:
        • Device Name
        • Risk Score
        • Health Status
        • Last IP
        • Last Seen
```

## Comparison: Manual vs Automated Deployment

### Manual Deployment (Old Way)

```
1. Deploy Function App
   └─> Azure Portal or ARM template
        └─> Set APPID/SECRETID manually

2. Go to Azure Portal > Workbooks

3. Create new workbook

4. Copy DefenderC2-Workbook.json content

5. Paste into Advanced Editor

6. Find FunctionAppName parameter in JSON
   └─> Search through 2000+ lines

7. Update value from "defc2" to your function app

8. Click Apply, Done Editing, Save

9. Open workbook

10. Select subscription, workspace

11. Test queries
    └─> If errors, debug parameter configuration

12. Repeat for FileOperations.workbook

Total time: 20-30 minutes
Error rate: High
Consistency: Low
```

### Automated Deployment (New Way)

```
1. Run deploy-all.ps1 with parameters
   │
   └─> Script does everything:
       ├─ Deploy Function App
       ├─ Set environment variables
       ├─ Load workbook JSON
       ├─ Update FunctionAppName parameter
       ├─ Deploy to Azure Monitor
       └─ Validate deployment

2. Open workbook in Portal

3. Select subscription, workspace

4. Start using immediately

Total time: 5 minutes
Error rate: Very low
Consistency: High
```

## Decision Tree: Which Deployment Method?

```
                        Start
                          │
                          ▼
              Do you have everything deployed?
                    /              \
                  NO                YES
                  │                  │
                  ▼                  ▼
         Need Function App?    Need Workbooks Only?
              /        \              │
            YES        NO             ▼
             │          │       deploy-workbook.ps1
             │          │             │
             ▼          │             └─> Fast workbook update
    deploy-all.ps1     │
         │              │
         │              ▼
         │        deploy-workbook.ps1
         │              │
         └──────────────┴─> Done!
```

## File Dependencies

```
deployment/
  │
  ├─ Scripts (Run these)
  │  ├─ deploy-all.ps1          ◄── Orchestrator
  │  ├─ deploy-complete.ps1     ◄── Function App
  │  └─ deploy-workbook.ps1     ◄── Workbooks
  │
  ├─ Templates (Used by scripts)
  │  ├─ azuredeploy.json        ◄── Function App ARM
  │  ├─ workbook-deploy.json    ◄── Workbook ARM
  │  └─ createUIDefinition.json ◄── Portal UI
  │
  ├─ Documentation (Read these)
  │  ├─ README.md                     ◄── Overview
  │  ├─ WORKBOOK_DEPLOYMENT.md        ◄── Detailed guide
  │  ├─ WORKBOOK_PARAMETERS_GUIDE.md  ◄── Parameter reference
  │  └─ DEPLOYMENT_FLOW.md            ◄── This file
  │
  └─ Examples (Reference)
     └─ workbook-deploy.parameters.example.json

workbook/
  ├─ DefenderC2-Workbook.json   ◄── Main workbook content
  └─ FileOperations.workbook     ◄── File ops workbook content
```

## Success Indicators

After successful deployment, you should see:

```
✅ Function App
   ├─ Status: Running
   ├─ URL: https://defc2.azurewebsites.net
   └─ Environment Variables:
       ├─ APPID: Set
       └─ SECRETID: Set

✅ Workbooks in Azure Monitor
   ├─ DefenderC2 Command & Control Console
   │   └─ Parameters:
   │       ├─ FunctionAppName: "defc2" ✓
   │       ├─ TenantId: Auto-populated ✓
   │       ├─ Subscription: Selected ✓
   │       └─ Workspace: Selected ✓
   │
   └─ DefenderC2 File Operations
       └─ Parameters: Same as above ✓

✅ Queries Work
   ├─ Get Devices: Returns data
   ├─ Get Incidents: Returns data
   └─ No error messages
```

## Troubleshooting Flow

```
Workbook shows errors?
    │
    ├─> "Please provide a valid resource path"
    │    └─> Check FunctionAppName parameter
    │         ├─ Is it set?
    │         ├─ Does it match your function app?
    │         └─> Fix: Update parameter or redeploy
    │
    ├─> "404 Not Found"
    │    └─> Function app doesn't exist
    │         └─> Verify: az functionapp show -n {name} -g {rg}
    │
    ├─> "500 Internal Server Error"
    │    └─> Function app configuration issue
    │         └─> Check: APPID and SECRETID env vars
    │
    └─> "No data"
         └─> Query succeeded, no data available
              └─> This is normal (not an error)
```

## Quick Reference Commands

```bash
# Check if function app exists
az functionapp show -n defc2 -g rg-defenderc2

# List workbooks
az monitor workbook list -g rg-defenderc2 --output table

# View function app environment variables
az functionapp config appsettings list -n defc2 -g rg-defenderc2

# Tail function app logs
az webapp log tail -n defc2 -g rg-defenderc2

# Delete and redeploy workbook
# (Delete via Portal, then:)
.\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "..." -FunctionAppName "defc2" -DeployMainWorkbook
```

---

## Summary

This diagram shows how the deployment scripts work together to:

1. ✅ Deploy Function App with correct environment variables
2. ✅ Deploy workbooks with FunctionAppName parameter set
3. ✅ Ensure all parameters are populated correctly
4. ✅ Provide one-command deployment option
5. ✅ Enable easy troubleshooting and verification

The automated approach eliminates manual configuration errors and ensures consistent deployments.
