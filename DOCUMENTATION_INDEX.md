# Documentation Index - v3.3.0

**Microsoft Defender XDR to Azure Sentinel SOAR Integration**  
**Version**: 3.3.0 | **Last Updated**: November 2025  
**Status**: Production Ready | **Actions**: 219 | **Batch Support**: ✅

---

## Quick Navigation

| I want to... | Start here |
|--------------|------------|
| Deploy the solution | [README.md](#readmemd) → [DEPLOYMENT_GUIDE.md](#deployment_guidemd) |
| See all 219 actions | [V3.2.0_COMPLETE_200_PLUS_ACTIONS.md](#v320_complete_200_plus_actionsmd) |
| Understand architecture | [README.md](#readmemd) (Architecture section) |
| Configure permissions | [PERMISSIONS.md](#permissionsmd) |
| Troubleshoot issues | [DEPLOYMENT_GUIDE.md](#deployment_guidemd) (Troubleshooting) |
| See implementation details | [V3.2.0_IMPLEMENTATION_PROGRESS.md](#v320_implementation_progressmd) |

---

## Core Documentation

### README.md
**Primary repository documentation** - Start here!

- Complete overview of 219 actions across 6 security services
- Quick start and deployment instructions
- Architecture diagram (Gateway → Orchestrator → Workers)
- Action coverage by service (MDE, MDO, MCAS, EntraID, Intune, Azure)
- Action tracking features (history, cancellation, audit logging)
- API reference and usage examples
- Monitoring and troubleshooting

**When to use**: First time user, deployment overview, action catalog

---

### PERMISSIONS.md
**Required API permissions for App Registration**

- Complete list of Microsoft Graph permissions
- Security API permissions (Microsoft Threat Protection)
- Intune, Azure Management permissions
- Permission justifications and scope explanations
- Setup instructions for App Registration

**When to use**: Setting up App Registration, permission errors

---

### DEPLOYMENT_GUIDE.md
**Comprehensive deployment guide**

- Prerequisites and requirements
- Step-by-step deployment (Azure Portal + Manual)
- Configuration details (App Settings, Managed Identity)
- Workbook deployment
- Troubleshooting common issues
- Post-deployment validation

**When to use**: Deploying for first time, deployment issues

---

## Version Documentation

### V3.2.0_COMPLETE_200_PLUS_ACTIONS.md
**Complete action catalog** - All 219 actions documented

- Actions organized by service:
  - **MDE (52)**: Device isolation, TVM, network protection, custom detection
  - **MDO (25)**: Email remediation, quarantine, phishing response
  - **MCAS (23)**: OAuth, DLP, shadow IT, session control
  - **EntraID (34)**: Identity protection, PIM, Conditional Access
  - **Intune (33)**: Device management, encryption, app control
  - **Azure (52)**: Storage, SQL, Arc, WAF, MDC, Sentinel
- API endpoints and parameters
- Use cases and examples

**When to use**: Finding specific actions, understanding capabilities

---

### V3.2.0_IMPLEMENTATION_PROGRESS.md
**Implementation details and technical architecture**

- Development progress tracking
- Module dependencies and structure
- Technical decisions and rationale
- Testing results and validation
- Known limitations

**When to use**: Understanding implementation, technical details

---

### V3.3.0_SIMPLIFICATION_AND_BATCHING.md
**v3.3.0 Simplification & Batch Processing**

- Architecture simplification (removed IntegrationBridge folder)
- Comprehensive batch processing support
- Removed DiagnosticCheck (use Application Insights)
- BatchHelper.psm1 module documentation
- Migration guide from v3.2.0

**When to use**: Understanding v3.3.0 changes, batch operations, App Insights

---

## Deployment Documentation

All deployment-related files in `deployment/` directory:

### deployment/README.md
- Deployment options overview
- Quick links to deployment methods

### deployment/FUNCTION_APP_DEPLOYMENT.md
- Function App specific deployment details
- Application settings configuration
- Managed Identity setup
- Monitoring and logging setup

### deployment/Configure-AppPermissions.ps1
**PowerShell script for automated permission configuration**
- Creates App Registration
- Grants required API permissions
- Configures client secrets

### deployment/Deploy-DefenderC2.ps1
**PowerShell script for automated deployment**
- Creates Resource Group
- Deploys Function App
- Configures Application Settings
- Deploys Storage Account

### deployment/diagnose-function-app.ps1
**Function App diagnostics tool**
- Checks Function App status
- Validates configuration
- Tests connectivity

### deployment/test-all-services.ps1
**Integration testing script**
- Tests all 6 workers
- Validates API responses
- Generates test report

### deployment/CUSTOMENDPOINT_GUIDE.md
- Custom API endpoint configuration
- Integration patterns
- Sample requests

### deployment/WORKBOOK_PARAMETERS_GUIDE.md
- Workbook parameter configuration
- Parameter dependencies
- Best practices

### deployment/WORKBOOK_PARAMETERS_REQUIRED.md
- Mandatory workbook parameters
- Required settings
- Validation rules

### deployment/PACKAGE_UPDATE_PROCESS.md
- Package update procedures
- Version management
- Release process

### deployment/V2.3.0_DEPLOYMENT_GUIDE.md
**ARCHIVED** - Old version deployment guide (kept for reference)

---

## Workbook Documentation

All workbook-related files in `workbook/` directory:

### workbook/README.md
**Azure Sentinel Workbook documentation**
- Workbook installation instructions
- Feature overview
- Tab descriptions
- Usage examples

### workbook/ARCHITECTURE.md
- Workbook architecture and design
- Component structure
- Data flow diagrams
- Parameter cascading

### workbook/QUICKREF.md
- Quick reference guide
- Common operations
- Action shortcuts
- Parameter usage

### workbook/DEVICEMANAGER_README.md
- Device Manager tab documentation
- MDE device operations
- Isolation and remediation workflows

### Workbook Files
- `DefenderXDR-v3.0.0.workbook` - Main workbook JSON
- `DefenderXDR-Complete.json` - Complete workbook
- `DefenderC2-Hybrid.json` - Hybrid configuration
- `FileOperations.workbook` - File operations module

---

## Technical Documentation

### docs/ARM_ACTIONS_CORRECT_PATTERN.md
- ARM template action patterns
- Best practices for workbook actions
- Parameter passing examples
- Error handling patterns

### docs/CUSTOM_ENDPOINT_SAMPLE_QUERIES.md
- Sample KQL queries for custom endpoints
- Log Analytics query patterns
- Use case examples

### docs/WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md
- Workbook custom endpoint integration
- Configuration steps
- Query customization

---

## Examples

### examples/README.md
- Example configurations
- Sample playbook implementations
- Use case demonstrations

### examples/customendpoint-example.json
- Custom endpoint JSON example
- Parameter definitions
- Sample requests and responses

### examples/sample-config.md
- Sample configuration files
- Configuration templates

---

## Function Architecture

### Azure Functions (8 total)

Located in `functions/` directory:

| Function | Purpose | Actions | Status |
|----------|---------|---------|--------|
| **DefenderXDRGateway** | HTTP entry point, action tracking | N/A | Core |
| **DefenderXDROrchestrator** | Service routing logic | N/A | Core |
| **DefenderXDRAzureWorker** | Azure infrastructure security | 52 | ✅ |
| **DefenderXDRMDEWorker** | Endpoint protection (MDE) | 52 | ✅ |
| **DefenderXDRMDOWorker** | Email security (MDO) | 25 | ✅ |
| **DefenderXDRMCASWorker** | Cloud app security (MCAS) | 23 | ✅ |
| **DefenderXDREntraIDWorker** | Identity protection | 34 | ✅ |
| **DefenderXDRIntuneWorker** | Device management | 33 | ✅ |

**Total: 219 remediation actions**

### Core Modules

Located in `functions/modules/`:

| Module | Purpose | Used By |
|--------|---------|---------|
| **AuthManager.psm1** | OAuth authentication, token management | All workers |
| **ValidationHelper.psm1** | Input validation, tenant ID verification | All workers |
| **LoggingHelper.psm1** | Structured logging (Write-XDRLog) | All workers |
| **ActionTracker.psm1** | Action tracking, history, audit logging | Gateway |
| **BatchHelper.psm1** | Batch processing, comma-separated values | All workers |

### Module Functions

**AuthManager.psm1**:
- `Get-DefenderToken` - Microsoft Threat Protection token
- `Get-GraphToken` - Microsoft Graph token
- `Get-SecurityToken` - Security API token
- `Get-AzureManagementToken` - Azure Management token

**ValidationHelper.psm1**:
- `Test-TenantId` - Validate tenant ID format
- `Test-RequiredParameters` - Validate required parameters

**LoggingHelper.psm1**:
- `Write-XDRLog` - Structured logging with levels (Info, Warning, Error)

**ActionTracker.psm1**:
- `Start-ActionTracking` - Initialize action tracking
- `Update-ActionProgress` - Update progress
- `Complete-ActionTracking` - Mark complete
- `Request-ActionCancellation` - Request cancellation
- `Get-ActionHistory` - Retrieve history
- `Get-ActionAuditTrail` - Get audit trail
- `Export-ActionAuditLog` - Export logs (JSON/CSV/CEF)
- `Test-ActionCancellation` - Check cancellation status

---

## API Reference

### Primary Endpoints

**POST /api/Gateway**
- Main action execution endpoint
- Request body: `{ action, tenantId, service, body }`
- Returns: `{ success, action, actionId, result, timestamp }`

**GET /api/DiagnosticCheck**
- Environment diagnostics
- Returns: Configuration status, module validation, credential checks

### Action Tracking (PowerShell Module Functions)

Used internally by Gateway and available for custom integrations:

- `Get-ActionHistory -TenantId <id> -Service <service> -StartDate <date>`
- `Get-ActionAuditTrail -ActionId <id>`
- `Request-ActionCancellation -ActionId <id> -Reason <reason>`
- `Export-ActionAuditLog -TenantId <id> -Format JSON|CSV|SIEM`

---

## Archive

The `archive/` directory contains historical documentation:

- **deployment-guides/** - Old deployment documentation
- **feature-guides/** - Legacy feature guides
- **github-workflows/** - Old CI/CD workflows
- **old-deployment-docs/** - Superseded deployment docs
- **old-docs/** - Previous version documentation
- **old-modules/** - Deprecated code modules
- **old-workbook-tests/** - Legacy test files
- **old-workbooks/** - Previous workbook versions
- **standalone/** - Old standalone modules
- **technical-docs/** - Historical technical documentation
- **working-docs/** - Development notes and planning

**Note**: Archive is kept for reference only. Use current documentation above.

---

## Common Tasks

### Deploying the Solution

1. **Prerequisites** → [PERMISSIONS.md](#permissionsmd)
2. **Deploy** → [DEPLOYMENT_GUIDE.md](#deployment_guidemd)
3. **Configure** → [deployment/WORKBOOK_PARAMETERS_GUIDE.md](#deploymentworkbook_parameters_guidemd)
4. **Verify** → DiagnosticCheck endpoint

### Finding Actions

1. Browse all actions → [V3.2.0_COMPLETE_200_PLUS_ACTIONS.md](#v320_complete_200_plus_actionsmd)
2. Search by service (MDE, MDO, MCAS, EntraID, Intune, Azure)
3. Check API parameters in action descriptions

### Troubleshooting

1. **Authentication issues** → [PERMISSIONS.md](#permissionsmd), check App Registration
2. **Deployment problems** → [DEPLOYMENT_GUIDE.md](#deployment_guidemd) troubleshooting section
3. **Worker errors** → Check Application Insights logs
4. **Workbook issues** → [workbook/README.md](#workbookreadmemd)

### Monitoring

1. **Application Insights** - Auto-configured with Function App
2. **Action History** - Use `Get-ActionHistory` PowerShell function
3. **Audit Logs** - Use `Export-ActionAuditLog` for SIEM integration
4. **Diagnostics** - `/api/DiagnosticCheck` endpoint

---

## Quick Links

### Getting Started
- [README.md](README.md) - Start here
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deploy
- [PERMISSIONS.md](PERMISSIONS.md) - Configure permissions

### Action Reference
- [V3.2.0_COMPLETE_200_PLUS_ACTIONS.md](V3.2.0_COMPLETE_200_PLUS_ACTIONS.md) - All 219 actions

### Technical Details
- [V3.2.0_IMPLEMENTATION_PROGRESS.md](V3.2.0_IMPLEMENTATION_PROGRESS.md) - Implementation
- [workbook/ARCHITECTURE.md](workbook/ARCHITECTURE.md) - Workbook design
- [docs/ARM_ACTIONS_CORRECT_PATTERN.md](docs/ARM_ACTIONS_CORRECT_PATTERN.md) - Patterns

### Deployment
- [deployment/](deployment/) - All deployment files
- [workbook/](workbook/) - Workbook files
- [examples/](examples/) - Examples

---

## Support

- **Issues**: GitHub Issues for bug reports and feature requests
- **Documentation**: This index + linked documents
- **Diagnostics**: `/api/DiagnosticCheck` endpoint
- **Logs**: Application Insights (auto-configured)

---

## Version History

### v3.3.0 (Current - November 2025)
- ✅ Comprehensive batch processing (comma-separated values)
- ✅ Simplified module structure (removed IntegrationBridge folder)
- ✅ Removed DiagnosticCheck (use Application Insights)
- ✅ Removed MDIWorker (not integrated)
- ✅ Added BatchHelper.psm1 module
- ✅ Net reduction: 742 lines of code

### v3.2.0 (November 2025)
- ✅ 219 total actions (103 existing + 116 new)
- ✅ Action tracking infrastructure (ActionTracker.psm1)
- ✅ All 6 security services enhanced
- ✅ Complete audit logging and cancellation support
- ✅ Repository cleanup (removed unused modules and docs)

### v3.0.0 (Previous)
- Initial production release
- 103 actions across 6 services
- Basic Gateway/Orchestrator/Workers architecture

---

**Documentation Index v3.3.0**  
*Last Updated: November 2025*  
*219 Actions | 6 Security Services | 8 Functions | 5 Core Modules | Batch Support*
