# Workbook Deployment Fix - Verification Guide

## Summary of Changes

This fix addresses the workbook deployment failure by ensuring the `FunctionAppUrl` parameter is properly configured as required across all workbooks.

### Root Cause
The embedded workbook in the ARM template (`deployment/azuredeploy.json`) had `FunctionAppUrl` parameter set to `isRequired: false`, which could cause deployment failures if auto-discovery didn't find a Function App.

### Files Modified
1. **`deployment/azuredeploy.json`** 
   - Changed `FunctionAppUrl.isRequired: false` → `true` in embedded workbook
   - Ensures deployment fails gracefully with clear error if Function App URL is not discovered

2. **`workbook/DefenderC2-Workbook.json`**
   - Updated label to "Function App (Auto-Discovered)" for clarity
   - Aligned description with ARM template version

3. **`workbook/FileOperations.workbook`**
   - Updated label to "Function App (Auto-Discovered)" for consistency
   - Aligned description with other workbooks

## How It Works

### Auto-Discovery Flow
1. **Azure Resource Graph Query**: The workbook uses an ARG query to find Function Apps:
   ```kql
   Resources 
   | where type =~ 'microsoft.web/sites' 
   | where kind =~ 'functionapp' 
   | where name contains 'defenderc2' or tags['Project'] =~ 'defenderc2'
   | extend FunctionUrl = strcat('https://', name, '.azurewebsites.net')
   | project FunctionUrl 
   | limit 1
   ```

2. **Search Criteria**:
   - Function App name contains `defenderc2`, OR
   - Function App has tag `Project=defenderc2`

3. **Fallback**: If auto-discovery fails, the parameter being `isRequired: true` ensures users must manually enter the URL.

## Testing Instructions

### Test 1: One-Click Deploy to Azure Button
1. Click the "Deploy to Azure" button in README.md
2. Verify the deployment form loads successfully
3. Check that all parameters are present
4. If a DefenderC2 Function App exists in the subscription:
   - The `FunctionAppUrl` should auto-populate
5. If no Function App is found:
   - The `FunctionAppUrl` field should be empty but marked as required
   - Users should be prompted to enter the URL manually

### Test 2: GitHub Actions Workflow
1. Make a change to `workbook/DefenderC2-Workbook.json`
2. Commit and push to main branch
3. Verify the "Deploy Azure Workbook" workflow runs successfully
4. Check that the workbook is deployed to Azure Monitor

### Test 3: Workbook Functionality
After deployment:
1. Open Azure Portal → Monitor → Workbooks
2. Find "DefenderC2 Command & Control Console"
3. Select Subscription and Workspace
4. Verify TenantId auto-populates
5. Verify FunctionAppUrl parameter shows discovered URL or prompts for manual entry
6. Test a basic action (e.g., Get Devices) to ensure the workbook functions correctly

## Expected Behavior

### ✅ Success Scenarios
- **Auto-discovery works**: Function App URL is automatically populated, users can immediately use the workbook
- **Auto-discovery fails**: Users see a clear required field for Function App URL with helpful description
- **Manual entry**: Users can enter the Function App URL manually if needed

### ❌ Previous Failure Scenario (Now Fixed)
- **Before fix**: If auto-discovery failed and `isRequired: false`, the parameter would be empty, causing API calls to fail with invalid paths
- **After fix**: If auto-discovery fails, deployment forces manual entry, preventing invalid configurations

## Validation Commands

Run these commands to verify the changes locally:

```bash
# Validate ARM template JSON
python3 -c "import json; json.load(open('deployment/azuredeploy.json'))" && echo "✓ ARM template valid"

# Validate standalone workbook
python3 -c "import json; json.load(open('workbook/DefenderC2-Workbook.json'))" && echo "✓ DefenderC2 workbook valid"

# Validate FileOperations workbook
python3 -c "import json; json.load(open('workbook/FileOperations.workbook'))" && echo "✓ FileOperations workbook valid"

# Run template validation script (requires Azure CLI)
cd deployment && bash validate-template.sh
```

## Troubleshooting

### If FunctionAppUrl is not auto-discovered:
1. **Check Function App naming**: Ensure the name contains `defenderc2`
2. **Check tags**: Add `Project=defenderc2` tag to the Function App
3. **Check permissions**: Ensure you have Reader permissions on the subscription
4. **Manual entry**: Enter the URL manually: `https://your-function-app.azurewebsites.net`

### If deployment still fails:
1. Check Azure Activity Log for detailed error messages
2. Verify the ARM template is using the correct version from main branch
3. Ensure all prerequisites are met (App Registration, permissions, etc.)
4. Check GitHub Actions workflow logs for specific errors

## References

- [workbook/README.md](workbook/README.md) - Workbook documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [ENHANCED_AUTO_DISCOVERY.md](ENHANCED_AUTO_DISCOVERY.md) - Auto-discovery implementation details
- [WORKBOOK_FIX_SUMMARY.md](WORKBOOK_FIX_SUMMARY.md) - Previous workbook fixes
