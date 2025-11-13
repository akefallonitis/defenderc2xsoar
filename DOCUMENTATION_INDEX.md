# DefenderXDR Documentation Index# DefenderC2 Documentation Index



**Version**: 3.0.0 | **Last Updated**: January 2025## 📚 Complete Guide to DefenderC2 Workbook Documentation



Quick guide to DefenderXDR documentation. Old docs archived to `archive/old-docs/`.This index helps you quickly find the right documentation for your needs.



------



## 📚 Essential Documentation (Start Here)## 🚀 Quick Start



| Document | Purpose |**New to DefenderC2?** Start here:

|----------|---------|

| **[README.md](README.md)** | Overview, architecture, quick start |1. **[README.md](README.md)** - Project overview and quick start

| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | Complete deployment instructions |2. **[QUICKSTART.md](QUICKSTART.md)** - Fast deployment guide

| **[PERMISSIONS.md](PERMISSIONS.md)** | Required API permissions |3. **[QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md)** - 60-second health check

| **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** | Upgrade from v2.x to v3.0 |

---

---

## 🔧 Deployment & Configuration

## 📊 Reference Documentation

### Deployment Guides

| Document | Purpose |

|----------|---------|- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment instructions

| **[XDR_REMEDIATION_ACTION_MATRIX.md](XDR_REMEDIATION_ACTION_MATRIX.md)** | All 213 actions reference |- **[DEPLOYMENT_READY.md](DEPLOYMENT_READY.md)** - Pre-deployment checklist

| **[ACTION_COUNT_VERIFICATION.md](ACTION_COUNT_VERIFICATION.md)** | Verified action counts by worker |- **[DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md)** - Step-by-step verification (NEW)

| **[WORKBOOK_INTEGRATION_APIS.md](WORKBOOK_INTEGRATION_APIS.md)** | Dynamic workbook integration APIs |

| **[COMPREHENSIVE_CLEANUP_COMPLETE.md](COMPREHENSIVE_CLEANUP_COMPLETE.md)** | Latest cleanup summary |### Configuration Guides



---- **[AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md)** - Best practices for Azure Workbooks

- **[FUNCTION_APP_AUTH_CONFIG.md](FUNCTION_APP_AUTH_CONFIG.md)** - Authentication configuration

## 🏗️ Architecture (v3.0.0)- **[PARAMETER_DEPENDENCY_FLOW.md](PARAMETER_DEPENDENCY_FLOW.md)** - How parameters cascade



```---

Gateway → Orchestrator → 9 Workers

## 🐛 Troubleshooting

11 Functions | 213 Actions | 21 Modules

```### Problem-Solving Guides



**Workers**:- **[TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)** - Comprehensive troubleshooting (NEW)

- MDE (52 actions) - Endpoint security- **[QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md)** - 60-second health check (NEW)

- Azure (22) - Infrastructure- **[AUTHENTICATION_TROUBLESHOOTING.md](AUTHENTICATION_TROUBLESHOOTING.md)** - Authentication issues

- Entra ID (20) - Identity & access

- Intune (18) - Device management### Common Issues

- MCAS (14) - Cloud apps

- MDO (12) - Email security- **[ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md](ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md)** - CustomEndpoint fixes

- MDI (11) - Identity threats- **[ISSUE_ANALYSIS_SUMMARY.md](ISSUE_ANALYSIS_SUMMARY.md)** - Complete issue analysis (NEW)

- Plus 2 more workers- **[FUNCTIONAPP_FILTER_FIX.md](FUNCTIONAPP_FILTER_FIX.md)** - FunctionApp dropdown issues



**Modules** (in `functions/modules/DefenderXDRIntegrationBridge/`):---

- Core: AuthManager, ValidationHelper, LoggingHelper

- Services: 13 service-specific modules## 📖 Technical Documentation

- Utilities: BlobManager, QueueManager, StatusTracker, ConditionalAccess

### Workbook Configuration

---

- **[ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md)** - ARM action configuration

## 📁 Directory Structure- **[PARAMETER_AUTOPOPULATION_FIX.md](PARAMETER_AUTOPOPULATION_FIX.md)** - Parameter auto-population

- **[TENANTID_FUNCTIONAPP_FIX.md](TENANTID_FUNCTIONAPP_FIX.md)** - TenantId discovery fix

```- **[WORKBOOK_AUTOPOPULATION_FIX.md](WORKBOOK_AUTOPOPULATION_FIX.md)** - Auto-population fixes

defenderc2xsoar/

├── functions/           ✅ 11 functions (Gateway + Orchestrator + 9 workers)### CustomEndpoint Configuration

│   └── modules/DefenderXDRIntegrationBridge/  ✅ 21 shared modules

├── deployment/          ✅ ARM templates, deployment scripts- **[CUSTOMENDPOINT_IMPLEMENTATION_SUMMARY.md](CUSTOMENDPOINT_IMPLEMENTATION_SUMMARY.md)** - CustomEndpoint implementation

├── workbook/            ✅ Azure Workbook JSON- **[WORKBOOK_URLPARAMS_FIX.md](WORKBOOK_URLPARAMS_FIX.md)** - URL parameters fix

├── docs/                ✅ Additional documentation- **[SESSION_SUMMARY.md](SESSION_SUMMARY.md)** - Complete session summary

├── examples/            ✅ Sample code

├── scripts/             ✅ Utility scripts### API Reference

└── archive/             📦 Old docs and standalone modules

```- **[archive/technical-docs/FUNCTIONS_REFERENCE.md](archive/technical-docs/FUNCTIONS_REFERENCE.md)** - Function App API reference



------



## 🎯 Quick Reference## ✅ Verification & Testing



**I want to...**### Validation Tools



- **Deploy** → README.md, then DEPLOYMENT_GUIDE.md- **[scripts/verify_workbook_config.py](scripts/verify_workbook_config.py)** - Automated configuration validation

- **See available actions** → XDR_REMEDIATION_ACTION_MATRIX.md- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Comprehensive testing guide

- **Understand architecture** → ACTION_COUNT_VERIFICATION.md- **[VERIFICATION_SUMMARY.md](VERIFICATION_SUMMARY.md)** - Verification results

- **Integrate workbook** → WORKBOOK_INTEGRATION_APIS.md

- **Upgrade from v2.x** → MIGRATION_GUIDE.md### Test Results

- **View cleanup work** → COMPREHENSIVE_CLEANUP_COMPLETE.md

- **[VERIFICATION_COMPLETE.md](VERIFICATION_COMPLETE.md)** - Complete verification status

---- **[WORKBOOK_VERIFICATION_REPORT.md](WORKBOOK_VERIFICATION_REPORT.md)** - Workbook verification report

- **[COMPLETE_VERIFICATION_REPORT.md](COMPLETE_VERIFICATION_REPORT.md)** - All verification results

## 📦 Archived Documentation

---

Moved to `archive/old-docs/` (19 files):

- Old architecture analyses## 📊 Project Status & Summaries

- Historical implementation plans

- Outdated testing status### Current Status

- Superseded by current docs

- **[PROJECT_COMPLETE.md](PROJECT_COMPLETE.md)** - Overall project completion status

**Note**: `standalone/` directory also archived (no longer used).- **[IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md)** - Implementation status

- **[ISSUE_ANALYSIS_SUMMARY.md](ISSUE_ANALYSIS_SUMMARY.md)** - Latest issue analysis (NEW)

---

### Change Summaries

**Repository**: github.com/akefallonitis/defenderc2xsoar  

**Status**: Production Ready  - **[PR_SUMMARY.md](PR_SUMMARY.md)** - Pull request summary

**Actions**: 213 verified across 9 workers- **[WORKBOOK_FIXES_SUMMARY.md](WORKBOOK_FIXES_SUMMARY.md)** - All workbook fixes

- **[CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)** - Cleanup operations

---

## 🎯 Use Case Specific Guides

### By User Role

#### For Developers
1. [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md)
2. [ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md)
3. [CUSTOMENDPOINT_IMPLEMENTATION_SUMMARY.md](CUSTOMENDPOINT_IMPLEMENTATION_SUMMARY.md)
4. [scripts/verify_workbook_config.py](scripts/verify_workbook_config.py)

#### For Operators
1. [DEPLOYMENT.md](DEPLOYMENT.md)
2. [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md) ⭐ NEW
3. [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md) ⭐ NEW
4. [DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md) ⭐ NEW

#### For End Users
1. [QUICKSTART.md](QUICKSTART.md)
2. [README.md](README.md)
3. [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

### By Problem Type

#### "Workbook not working / stuck in refreshing"
1. [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md) - Start here ⭐
2. [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md) - Detailed help ⭐
3. [ISSUE_ANALYSIS_SUMMARY.md](ISSUE_ANALYSIS_SUMMARY.md) - Understanding the issue ⭐

#### "Parameters not auto-populating"
1. [ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md](ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md)
2. [PARAMETER_AUTOPOPULATION_FIX.md](PARAMETER_AUTOPOPULATION_FIX.md)
3. [PARAMETER_DEPENDENCY_FLOW.md](PARAMETER_DEPENDENCY_FLOW.md)

#### "Function App dropdown empty"
1. [FUNCTIONAPP_FILTER_FIX.md](FUNCTIONAPP_FILTER_FIX.md)
2. [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md) ⭐

#### "ARM actions failing"
1. [ARM_ACTION_FIX_SUMMARY.md](ARM_ACTION_FIX_SUMMARY.md)
2. [BEFORE_AFTER_ARM_ACTIONS.md](BEFORE_AFTER_ARM_ACTIONS.md)

#### "Authentication issues"
1. [AUTHENTICATION_TROUBLESHOOTING.md](AUTHENTICATION_TROUBLESHOOTING.md)
2. [FUNCTION_APP_AUTH_CONFIG.md](FUNCTION_APP_AUTH_CONFIG.md)

#### "Deployment issues"
1. [DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md) ⭐ NEW
2. [DEPLOYMENT.md](DEPLOYMENT.md)
3. [DEPLOYMENT_READY.md](DEPLOYMENT_READY.md)

---

## 🆕 Latest Documentation (October 2025)

### New Comprehensive Guides

1. **[TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)** (10.7 KB)
   - Complete troubleshooting guide
   - Common issues and solutions
   - Diagnostic procedures
   - Advanced debugging

2. **[DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md)** (11.0 KB)
   - Step-by-step deployment verification
   - Pre/post-deployment checks
   - Success criteria
   - Rollback procedures

3. **[QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md)** (5.2 KB)
   - 60-second health check
   - Quick command reference
   - Rapid troubleshooting

4. **[ISSUE_ANALYSIS_SUMMARY.md](ISSUE_ANALYSIS_SUMMARY.md)** (12.6 KB)
   - Complete issue analysis
   - Root cause identification
   - Configuration validation
   - Solution mapping

---

## 🔍 Finding What You Need

### Common Questions

**Q: My workbook is stuck refreshing. Where do I start?**  
A: [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md) → [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)

**Q: How do I deploy the workbook?**  
A: [QUICKSTART.md](QUICKSTART.md) → [DEPLOYMENT.md](DEPLOYMENT.md) → [DEPLOYMENT_VERIFICATION_CHECKLIST.md](DEPLOYMENT_VERIFICATION_CHECKLIST.md)

**Q: How do I verify my configuration is correct?**  
A: Run `python3 scripts/verify_workbook_config.py` → See [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md)

**Q: What was fixed in the latest updates?**  
A: [ISSUE_ANALYSIS_SUMMARY.md](ISSUE_ANALYSIS_SUMMARY.md) → [PROJECT_COMPLETE.md](PROJECT_COMPLETE.md)

**Q: How do parameters auto-populate?**  
A: [PARAMETER_DEPENDENCY_FLOW.md](PARAMETER_DEPENDENCY_FLOW.md) → [PARAMETER_AUTOPOPULATION_FIX.md](PARAMETER_AUTOPOPULATION_FIX.md)

**Q: What are the best practices?**  
A: [AZURE_WORKBOOK_BEST_PRACTICES.md](AZURE_WORKBOOK_BEST_PRACTICES.md)

---

## 📦 Documentation by Category

### 🏗️ Architecture & Design
- AZURE_WORKBOOK_BEST_PRACTICES.md
- PARAMETER_DEPENDENCY_FLOW.md
- archive/technical-docs/ARCHITECTURE.md

### 🔧 Configuration
- ARM_ACTION_FIX_SUMMARY.md
- PARAMETER_AUTOPOPULATION_FIX.md
- TENANTID_FUNCTIONAPP_FIX.md
- WORKBOOK_AUTOPOPULATION_FIX.md
- WORKBOOK_URLPARAMS_FIX.md

### 🚀 Deployment
- DEPLOYMENT.md
- DEPLOYMENT_READY.md
- DEPLOYMENT_VERIFICATION_CHECKLIST.md ⭐ NEW
- QUICKSTART.md

### 🐛 Troubleshooting
- TROUBLESHOOTING_PARAMETER_BINDING.md ⭐ NEW
- QUICK_VERIFICATION_GUIDE.md ⭐ NEW
- AUTHENTICATION_TROUBLESHOOTING.md
- ISSUE_RESOLUTION_CUSTOMENDPOINT_PARAMETERS.md

### ✅ Verification
- QUICK_VERIFICATION_GUIDE.md ⭐ NEW
- DEPLOYMENT_VERIFICATION_CHECKLIST.md ⭐ NEW
- TESTING_GUIDE.md
- VERIFICATION_COMPLETE.md
- scripts/verify_workbook_config.py

### 📊 Analysis & Reports
- ISSUE_ANALYSIS_SUMMARY.md ⭐ NEW
- PROJECT_COMPLETE.md
- VERIFICATION_SUMMARY.md
- WORKBOOK_VERIFICATION_REPORT.md

### 🔍 Reference
- QUICK_REFERENCE.md
- archive/technical-docs/FUNCTIONS_REFERENCE.md
- REPOSITORY_STRUCTURE.md

---

## 🛠️ Tools & Scripts

### Validation Scripts
```bash
# Verify workbook configuration
python3 scripts/verify_workbook_config.py

# Fix workbook queries (if needed)
python3 scripts/fix-workbook-queries.py
```

### Azure CLI Commands
```bash
# Check CORS
az functionapp cors show --name ${FUNCTION_APP} --resource-group ${RESOURCE_GROUP}

# Test API endpoint
curl "https://${FUNCTION_APP}.azurewebsites.net/api/DefenderC2Dispatcher?action=Get%20Devices&tenantId=${TENANT_ID}"

# View logs
az functionapp log tail --name ${FUNCTION_APP} --resource-group ${RESOURCE_GROUP}
```

See [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md) for complete command reference.

---

## 📅 Documentation Updates

### October 13, 2025
- ✨ Added TROUBLESHOOTING_PARAMETER_BINDING.md
- ✨ Added DEPLOYMENT_VERIFICATION_CHECKLIST.md
- ✨ Added QUICK_VERIFICATION_GUIDE.md
- ✨ Added ISSUE_ANALYSIS_SUMMARY.md
- ✨ Added DOCUMENTATION_INDEX.md (this file)

### October 12, 2025
- ✅ Completed PR #72 - Parameter binding fixes
- 📝 Created comprehensive fix documentation
- ✅ Verified all configurations

See [PROJECT_COMPLETE.md](PROJECT_COMPLETE.md) for complete history.

---

## 🎯 Recommended Reading Paths

### For First-Time Users
1. README.md
2. QUICKSTART.md
3. QUICK_VERIFICATION_GUIDE.md ⭐
4. DEPLOYMENT_VERIFICATION_CHECKLIST.md ⭐

### For Troubleshooting Issues
1. QUICK_VERIFICATION_GUIDE.md ⭐
2. TROUBLESHOOTING_PARAMETER_BINDING.md ⭐
3. ISSUE_ANALYSIS_SUMMARY.md ⭐

### For Understanding Technical Details
1. AZURE_WORKBOOK_BEST_PRACTICES.md
2. PARAMETER_DEPENDENCY_FLOW.md
3. ARM_ACTION_FIX_SUMMARY.md
4. ISSUE_ANALYSIS_SUMMARY.md ⭐

### For Deployment Planning
1. DEPLOYMENT.md
2. DEPLOYMENT_READY.md
3. DEPLOYMENT_VERIFICATION_CHECKLIST.md ⭐
4. TESTING_GUIDE.md

---

## 💡 Tips for Using This Documentation

1. **Start with Quick Guides** - Use QUICKSTART.md or QUICK_VERIFICATION_GUIDE.md
2. **Use the Index** - This file helps you find what you need quickly
3. **Follow Checklists** - Use DEPLOYMENT_VERIFICATION_CHECKLIST.md step-by-step
4. **Search by Problem** - Look in "By Problem Type" section above
5. **Check Latest** - New documents marked with ⭐

---

## 🆘 Getting Help

### Self-Service
1. Check [QUICK_VERIFICATION_GUIDE.md](QUICK_VERIFICATION_GUIDE.md)
2. Review [TROUBLESHOOTING_PARAMETER_BINDING.md](TROUBLESHOOTING_PARAMETER_BINDING.md)
3. Run `python3 scripts/verify_workbook_config.py`
4. Search this index for your problem

### Community Support
1. Check GitHub Issues
2. Review closed issues for similar problems
3. Check discussions

### Creating an Issue
Include:
- Output of `python3 scripts/verify_workbook_config.py`
- Browser console errors (F12)
- Function App logs
- Steps to reproduce

---

## 📄 License & Contributing

- **License**: See [LICENSE](LICENSE)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Repository**: https://github.com/akefallonitis/defenderc2xsoar

---

**Index Version:** 1.0  
**Last Updated:** October 13, 2025  
**Total Documentation Files:** 50+  
**New Guides (Oct 2025):** 4 comprehensive guides ⭐

_This index is maintained to help users quickly find relevant documentation. If you can't find what you need, please create an issue._
