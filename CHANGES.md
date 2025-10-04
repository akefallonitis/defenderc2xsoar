# Changes Summary

## Azure Policy Compliance and Multi-Tenant Authentication

This document summarizes the changes made to ensure compliance with Azure Policy requirements and implement proper multi-tenant authentication.

### Problem Statement

The original deployment was failing due to Azure Policy violations requiring three mandatory tags on all resources:
- `Project` - Project name identifier
- `CreatedBy` - Creator identification
- `DeleteAt` - Resource lifecycle management date

Additionally, the solution needed to support multi-tenant app registration with:
- `tenantId` passed via workbook payload per request
- `appId` and `secretId` stored as function app environment variables

### Changes Made

#### 1. ARM Template (deployment/azuredeploy.json)

**Added Parameters:**
- `spnSecret` (securestring) - Client secret for app registration
- `projectTag` (string) - Value for Project tag
- `createdByTag` (string) - Value for CreatedBy tag  
- `deleteAtTag` (string) - Value for DeleteAt tag

**Updated Resources:**
All three resources now include the required tags:
- `Microsoft.Storage/storageAccounts`
- `Microsoft.Web/serverfarms`
- `Microsoft.Web/sites`

**Updated Environment Variables:**
- Changed from `SPNID` to `APPID`
- Added `SECRETID` for client secret

#### 2. UI Definition (deployment/createUIDefinition.json)

**Added Input Fields:**
- Client Secret input (password field with confirmation)
- New "Resource Tags" step with three required tag fields
- Updated outputs to include all new parameters

#### 3. PowerShell Functions

**Updated Authentication Logic:**
All five functions now:
- Read `APPID` and `SECRETID` from environment variables
- No longer accept `spnId` as a request parameter
- Only require `tenantId` from workbook requests
- Validate environment variables are configured

**Affected Functions:**
- `MDEDispatcher/run.ps1`
- `MDETIManager/run.ps1`
- `MDECDManager/run.ps1`
- `MDEHuntManager/run.ps1`
- `MDEIncidentManager/run.ps1`

#### 4. Documentation Updates

**DEPLOYMENT.md:**
- Added Step 4 for creating client secret in app registration
- Updated deployment parameters for all methods (Portal, CLI, PowerShell)
- Removed federated identity credential configuration (no longer needed)
- Added explanation of client credentials authentication flow

**README.md:**
- Updated architecture diagram to show APPID/SECRETID in function app
- Updated deployment parameters list
- Removed Service Principal ID from workbook configuration
- Added client secret creation to Step 1

**deployment/README.md:**
- Updated all deployment examples with new parameters
- Updated parameters table with tag requirements
- Updated post-deployment verification steps

**examples/sample-config.md:**
- Removed Service Principal ID from workbook parameters
- Updated multi-tenant configuration examples
- Updated environment variables section
- Added security note about credential storage

### Authentication Flow

**Before:**
1. Workbook sends `tenantId` and `spnId` to function
2. Function uses managed identity + federated credentials
3. Complex setup with federated identity credentials required

**After:**
1. Workbook sends only `tenantId` to function
2. Function reads `APPID` and `SECRETID` from environment variables
3. Function authenticates using client credentials flow
4. Simpler setup, better multi-tenant support

### Benefits

✅ **Azure Policy Compliance**: All resources now include required tags
✅ **Secure Credential Storage**: Client secret stored in function app settings
✅ **Simplified Workbook**: No credentials in workbook configuration
✅ **True Multi-Tenant**: Single deployment works across all tenants
✅ **Easy Credential Rotation**: Update environment variable without redeploying

### Migration Notes

If upgrading from previous version:

1. Create client secret in your app registration
2. Redeploy function app with new ARM template including:
   - Client secret parameter
   - Tag parameters
3. Update function app code (automatic if using CI/CD)
4. Update workbook (remove Service Principal ID parameter if present)

### Testing Recommendations

Before deploying to production:

1. Validate ARM template syntax
2. Test deployment in non-production environment
3. Verify all three resources have correct tags
4. Verify APPID and SECRETID environment variables are set
5. Test function calls with workbook to ensure authentication works
6. Verify multi-tenant scenarios by changing tenantId parameter

### Security Considerations

- Client secret is stored as `securestring` parameter type
- Environment variables are encrypted at rest in Azure
- No credentials are exposed in workbook or logs
- Limit access to function app configuration in Azure Portal
- Rotate client secret periodically (document expiration date)
- Consider using Azure Key Vault reference for SECRETID in production

### Rollback Plan

If issues arise:

1. Keep previous deployment available as backup
2. ARM template changes are backward compatible
3. Can add tags to existing resources without redeployment
4. Function code changes are isolated and can be rolled back independently
