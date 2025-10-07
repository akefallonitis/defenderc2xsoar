# Deployment Simplification - Why GitHub Actions Are No Longer Promoted

## Summary

GitHub Actions workflows have been archived and are no longer the recommended deployment method. The one-click ARM template deployment is now the primary and recommended approach.

## Problem Statement

The repository previously promoted two deployment methods:
1. **GitHub Actions workflows** - Automated CI/CD deployment
2. **ARM template** - One-click Azure deployment

This created confusion because:
- Users had to choose between two approaches
- GitHub Actions required complex setup (service principals, multiple secrets)
- GitHub Actions still required the ARM template for initial deployment (chicken-and-egg problem)
- The ARM template already deploys everything in one click

## Solution

**Archived GitHub Actions workflows** and made the one-click ARM template the primary method because:

### ✅ ARM Template Advantages
- **No GitHub configuration needed** - No secrets, no repository setup
- **Simpler for end users** - Click button, fill form, deploy
- **Complete deployment** - Functions + Workbook in single operation
- **Works everywhere** - No need for GitHub account or repository access
- **Faster** - Deploy immediately, no CI/CD setup required

### ❌ GitHub Actions Disadvantages  
- **Complex setup** - Requires 5+ GitHub secrets configuration
- **Prerequisites needed** - Must deploy Function App via ARM template first anyway
- **Not needed by users** - Only useful for repository maintainers
- **Maintenance burden** - Workflows need updating when Azure APIs change

## Who Should Use GitHub Actions?

GitHub Actions are now **optional** and only recommended for:

1. **Repository Maintainers** - To automate deployments when pushing code changes
2. **Contributors** - To test changes in personal forks before submitting PRs
3. **Organizations** - Managing customized forks with CI/CD requirements

## Migration Guide

### For End Users (Most People)

**Just use the "Deploy to Azure" button:**

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakefallonitis%2Fdefenderc2xsoar%2Fmain%2Fdeployment%2Fazuredeploy.json)

See [DEPLOYMENT.md](DEPLOYMENT.md) or [QUICKSTART.md](QUICKSTART.md) for complete instructions.

### For Maintainers Who Want GitHub Actions

1. **Copy workflow files** from `archive/github-workflows/` to `.github/workflows/`
2. **Configure secrets** as described in `archive/deployment-guides/AUTOMATED_DEPLOYMENT.md`
3. **Push workflows** to your repository
4. **Test** the workflows in your fork before using in production

## Changes Made

| File/Directory | Change | Reason |
|----------------|--------|--------|
| `README.md` | Removed GitHub Actions badges | Simplified header, emphasize one-click deployment |
| `.github/workflows/*.yml` | Moved to `archive/github-workflows/` | Not needed by end users |
| `archive/github-workflows/README.md` | Created | Explain why archived and when to use |
| `archive/deployment-guides/AUTOMATED_DEPLOYMENT.md` | Added warning banner | Clarify this is optional/advanced |

## References

- **Primary deployment**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Quick start**: [QUICKSTART.md](QUICKSTART.md)  
- **ARM template**: [deployment/azuredeploy.json](deployment/azuredeploy.json)
- **Archived workflows**: [archive/github-workflows/](archive/github-workflows/)
- **Advanced CI/CD guide**: [archive/deployment-guides/AUTOMATED_DEPLOYMENT.md](archive/deployment-guides/AUTOMATED_DEPLOYMENT.md)

## FAQ

### Q: Will GitHub Actions workflows be removed completely?
**A:** No, they're archived in `archive/github-workflows/` and can still be used by maintainers who need CI/CD.

### Q: Will I lose any functionality by not using GitHub Actions?
**A:** No, the ARM template deploys the exact same infrastructure. GitHub Actions are only for automated deployments on code changes.

### Q: What if I already set up GitHub Actions?
**A:** It will continue to work. The workflows are just no longer promoted as the primary deployment method.

### Q: Can I still contribute to the repository without GitHub Actions?
**A:** Yes, absolutely. The workflows are for automated deployment, not for development or contribution.

### Q: What changed in the ARM template?
**A:** Nothing. The ARM template has always deployed everything. We just removed the confusion of promoting two deployment methods.

---

**Last Updated**: 2024-10-07  
**Status**: ✅ Complete  
**Related Issue**: GitHub issue requesting clarification on deployment approach
