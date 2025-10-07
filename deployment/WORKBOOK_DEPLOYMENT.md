# DefenderC2 Workbook Deployment Guide

## Overview

This guide explains how to deploy DefenderC2 workbooks to Azure Monitor. The workbooks include:
1. **DefenderC2 Command & Control Console** - Main operational workbook
2. **DefenderC2 File Operations** - File management workbook

## Prerequisites

- Azure subscription with:
  - Resource group created
  - Log Analytics workspace created
  - DefenderC2 Function App deployed
- Azure CLI installed and configured
- PowerShell 5.1 or later (for automated deployment)

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

Use the PowerShell deployment script for automated, error-free deployment:

```powershell
# Navigate to deployment directory
cd deployment

# Deploy main workbook
.\deploy-workbook.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -WorkspaceResourceId "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}" `
    -FunctionAppName "defc2" `
    -DeployMainWorkbook

# Deploy both workbooks
.\deploy-workbook.ps1 `
    -ResourceGroupName "rg-defenderc2" `
    -WorkspaceResourceId "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}" `
    -FunctionAppName "defc2" `
    -DeployMainWorkbook `
    -DeployFileOpsWorkbook
```

**Script Features:**
- ✅ Automatically loads workbook JSON content
- ✅ Sets Function App Name parameter to your function app
- ✅ Validates all prerequisites
- ✅ Creates proper ARM deployment
- ✅ Provides detailed progress feedback

### Method 2: Manual Azure Portal Import

For users who prefer manual deployment:

#### Step 1: Access Azure Workbooks

1. Open **Azure Portal**
2. Navigate to **Monitor** → **Workbooks**
3. Click **+ New** → **Advanced Editor** (</> icon)

#### Step 2: Import Main Workbook

1. Open `workbook/DefenderC2-Workbook.json` in a text editor
2. Copy the entire JSON content
3. Paste into the Advanced Editor
4. Click **Apply**
5. Click **Done Editing**
6. Click **Save** icon
7. Set Title: `DefenderC2 Command & Control Console`
8. Choose your subscription, resource group, and location
9. Click **Save**

#### Step 3: Configure Function App Parameter

After saving:
1. Open the workbook
2. Find the **Function App Name** parameter at the top
3. Enter your function app name (e.g., `defc2`, `mydefender`)
4. Click **Run** or refresh the page

#### Step 4: Import File Operations Workbook (Optional)

Repeat steps 1-3 with `workbook/FileOperations.workbook`:
- Title: `DefenderC2 File Operations`

### Method 3: Azure CLI Deployment

For DevOps and CI/CD scenarios:

```bash
# Set variables
RESOURCE_GROUP="rg-defenderc2"
WORKSPACE_ID="/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}"
FUNCTION_APP_NAME="defc2"
LOCATION="eastus"

# Load workbook content
WORKBOOK_CONTENT=$(cat workbook/DefenderC2-Workbook.json | jq -c '.')

# Create parameters file
cat > /tmp/workbook-params.json << EOF
{
  "workbookDisplayName": {
    "value": "DefenderC2 Command & Control Console"
  },
  "workbookSourceId": {
    "value": "$WORKSPACE_ID"
  },
  "workbookContent": {
    "value": $WORKBOOK_CONTENT
  },
  "location": {
    "value": "$LOCATION"
  }
}
EOF

# Deploy
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file deployment/workbook-deploy.json \
    --parameters /tmp/workbook-params.json
```

## Understanding Workbook Parameters

The DefenderC2 workbooks use the following parameters:

### 1. Function App Name (Required)
- **Type**: Text input
- **Purpose**: Specifies your DefenderC2 Function App name
- **Example**: `defc2`, `mydefender`, `sec-functions`
- **How it works**: Constructs full URL as `https://{FunctionAppName}.azurewebsites.net`

**Important**: The deployment script automatically sets this to match your function app, but you can change it in the workbook if needed.

### 2. Target Tenant ID (Auto-discovered)
- **Type**: Resource Graph query
- **Purpose**: Gets the workspace customer ID (tenant ID)
- **Auto-populated**: Yes, from selected workspace

### 3. Subscription & Workspace (Required)
- **Type**: Dropdown selectors
- **Purpose**: Define the context for queries
- **User action**: Select from available resources

## Verifying Deployment

### Check Workbook Exists

```powershell
# List workbooks in resource group
az monitor workbook list `
    --resource-group "rg-defenderc2" `
    --output table
```

### Open and Test

1. Go to **Azure Portal** → **Monitor** → **Workbooks**
2. Find `DefenderC2 Command & Control Console`
3. Click to open
4. Verify parameters are set:
   - ✅ Function App Name = your function app
   - ✅ Subscription = your subscription
   - ✅ Workspace = your Log Analytics workspace
   - ✅ Tenant ID = auto-populated
5. Navigate to tabs and verify data loads

## Troubleshooting

### Function App Name Not Set

**Symptom**: Workbook parameters show default `defc2` but your function app has a different name

**Solution**:
1. Open workbook
2. Click **Edit** → **Advanced Editor**
3. Find the FunctionAppName parameter (search for `"name": "FunctionAppName"`)
4. Update the `"value"` field to your function app name
5. Click **Apply** → **Done Editing** → **Save**

### Deployment Script Fails

**Symptom**: PowerShell script exits with error

**Common causes**:
- Not logged in to Azure: Run `az login`
- Wrong resource group: Verify with `az group list`
- Invalid workspace ID: Check in Azure Portal → Log Analytics workspace → Properties
- Missing permissions: Ensure you have Contributor role on resource group

### Workbook Shows "Please provide a valid resource path"

**Symptom**: ARMEndpoint queries fail with validation error

**Solution**:
- Verify Function App Name is correct (case-sensitive)
- Ensure function app is deployed and running
- Check function app is in the same subscription

### No Data in Workbook Tabs

**Symptom**: Workbook loads but shows no data

**Checklist**:
1. Verify Function App is running: `az functionapp show -n {app-name} -g {rg}`
2. Check function app has environment variables set:
   - `APPID` = Your app registration client ID
   - `SECRETID` = Your app registration client secret
3. Verify app registration has Defender API permissions
4. Check admin consent granted for API permissions
5. Review function logs for errors

## Advanced Configuration

### Pin Workbook to Dashboard

1. Open workbook
2. Click **📌 Pin** icon
3. Select dashboard or create new
4. Click **Pin**

### Share Workbook

1. Open workbook
2. Click **Share** icon
3. Choose permissions level
4. Copy link and share

### Update Workbook

To update an existing workbook with new version:

1. **Automated**:
   ```powershell
   # Re-run deployment script
   .\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "..." -FunctionAppName "defc2" -DeployMainWorkbook
   ```

2. **Manual**:
   - Open workbook → **Edit** → **Advanced Editor**
   - Replace entire JSON with new content
   - Click **Apply** → **Done Editing** → **Save**

## Best Practices

1. **Use Automated Deployment**: The PowerShell script ensures correct configuration
2. **Keep Function App Name Consistent**: Use the same name across all deployments
3. **Document Your Setup**: Note your function app name and workspace ID
4. **Test After Deployment**: Verify all tabs load data correctly
5. **Pin to Dashboard**: For quick access
6. **Keep Workbooks Updated**: Pull latest version from repository

## Integration with Main Deployment

### Option 1: Deploy After Function App

```powershell
# 1. Deploy function app
.\deploy-complete.ps1 -FunctionAppName "defc2" ...

# 2. Deploy workbooks
.\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "..." -FunctionAppName "defc2" -DeployMainWorkbook -DeployFileOpsWorkbook
```

### Option 2: One-Line Deployment

```powershell
# Combined deployment
$FunctionAppName = "defc2"
.\deploy-complete.ps1 -FunctionAppName $FunctionAppName ...
.\deploy-workbook.ps1 -ResourceGroupName "rg-defenderc2" -WorkspaceResourceId "..." -FunctionAppName $FunctionAppName -DeployMainWorkbook -DeployFileOpsWorkbook
```

## FAQ

### Q: Can I change the Function App Name after deployment?
**A:** Yes, edit the workbook parameter or redeploy with the new name.

### Q: Do I need to redeploy workbooks when I update function code?
**A:** No, workbooks call the functions via HTTP and don't need redeployment for function code changes.

### Q: Can I deploy to multiple workspaces?
**A:** Yes, run the deployment script multiple times with different workspace IDs.

### Q: What if my function app is in a different subscription?
**A:** The workbooks can call functions in any subscription. Just ensure proper RBAC permissions and CORS configuration.

### Q: Can I customize the workbook?
**A:** Yes! Edit the JSON files in the `workbook/` directory, then redeploy.

## Support

For issues or questions:
- Check this guide first
- Review [DEPLOYMENT.md](../DEPLOYMENT.md) for full deployment instructions
- Check [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
- Open a new issue with:
  - Deployment method used
  - Error messages
  - Azure CLI/PowerShell version
  - Screenshots if applicable

## Version History

- **v2.0** (Current): Simplified FunctionAppName parameter, automated deployment script
- **v1.0**: Initial release with manual configuration

---

**Note**: This guide assumes you have already deployed the DefenderC2 Function App. If not, see [DEPLOYMENT.md](../DEPLOYMENT.md) for complete setup instructions.
