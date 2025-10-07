# Archived GitHub Actions Workflows

## Why These Are Archived

These GitHub Actions workflows are **optional** and **not recommended** for most users. They have been archived because:

1. **The ARM template is simpler**: The main `deployment/azuredeploy.json` ARM template deploys EVERYTHING (Azure Functions + Workbook) with one click
2. **No GitHub secrets needed**: The one-click "Deploy to Azure" button doesn't require any GitHub repository configuration
3. **End users don't need CI/CD**: These workflows are primarily useful for repository maintainers, not for end users deploying the solution

## Primary Deployment Method

✅ **Use the one-click "Deploy to Azure" button** in the main README.md

This deploys:
- Azure Function App with all 6 functions
- Storage Account  
- App Service Plan
- DefenderC2 Workbook with auto-discovery
- All necessary configurations

No GitHub configuration required!

## When To Use These Workflows

These workflows are only useful if you are:
- A **repository maintainer** who wants automatic deployments on code changes
- Forking this repository and want CI/CD for your fork
- Testing changes before deployment

## Workflows Included

### 1. `deploy-azure-functions.yml`
- **Purpose**: Automatically deploys function code to an existing Function App when changes are pushed to `functions/` directory
- **Triggers**: Push to `main` branch, manual trigger
- **Required Secrets**: `AZURE_FUNCTIONAPP_PUBLISH_PROFILE`

### 2. `deploy-workbook.yml`
- **Purpose**: Automatically deploys workbook JSON to Azure when changes are pushed to `workbook/` directory  
- **Triggers**: Push to `main` branch, manual trigger
- **Required Secrets**: `AZURE_CREDENTIALS`, `AZURE_WORKSPACE_RESOURCE_ID`, `AZURE_LOCATION`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`

### 3. `create-deployment-package.yml`
- **Purpose**: Creates a deployment package for distribution
- **Triggers**: Manual trigger, releases
- **Required Secrets**: None

## Setup (If You Really Want To Use These)

If you're a maintainer and want to enable these workflows:

1. Copy the workflow files from `archive/github-workflows/` to `.github/workflows/`
2. Configure the required GitHub secrets (see individual workflow files for details)
3. See `archive/deployment-guides/AUTOMATED_DEPLOYMENT.md` for detailed setup instructions

## For End Users: Ignore This Directory

If you're just deploying DefenderC2, **you don't need anything in this directory**. 

Use the "Deploy to Azure" button instead:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

See the main [DEPLOYMENT.md](../../DEPLOYMENT.md) or [QUICKSTART.md](../../QUICKSTART.md) guides.
