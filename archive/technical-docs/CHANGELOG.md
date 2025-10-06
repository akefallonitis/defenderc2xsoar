# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### File Library Management 📦
- **Complete File Operations with Azure Storage Library**
  - Centralized file library using Azure Storage "library" container
  - Five new PowerShell functions:
    - `ListLibraryFiles` - List all files in storage library
    - `GetLibraryFile` - Retrieve file as Base64 from library
    - `PutLiveResponseFileFromLibrary` - Deploy file from library to MDE device
    - `GetLiveResponseFile` - Download file from MDE device
    - `DeleteLibraryFile` - Remove file from library
  - Helper scripts for file management:
    - `Upload-ToLibrary.ps1` - Upload files with validation and progress
    - `Sync-LibraryFolder.ps1` - Sync entire folder to library container
    - `Get-LibraryFiles.ps1` - List library files (API or direct storage)
    - `Remove-LibraryFile.ps1` - Delete files with confirmation
  - Configuration updates:
    - Added `Az.Storage` module to `requirements.psd1`
    - Enhanced `profile.ps1` with storage context initialization
    - Automatic library container creation on startup
  - Comprehensive documentation:
    - `FILE_OPERATIONS_GUIDE.md` - Complete user guide with workflows
    - `LIBRARY_SETUP.md` - 5-minute quick setup guide
    - API reference for all endpoints
    - Troubleshooting guide
  - Benefits:
    - Upload once, deploy many times
    - No manual Base64 encoding required
    - Team collaboration with shared file library
    - Native browser downloads for retrieved files
    - Minimal cost (~$0.05/month for typical usage)
  - See [FILE_OPERATIONS_GUIDE.md](FILE_OPERATIONS_GUIDE.md) for details

#### Standalone PowerShell Framework 🆕
- **New Standalone Version** for local execution without Azure infrastructure
  - Complete PowerShell framework in `standalone/` directory
  - Menu-driven terminal UI similar to original MDEAutomator
  - Zero Azure infrastructure costs - runs entirely on local workstation
  - Secure credential storage using Windows DPAPI
  - Full feature set including:
    - Device Actions (isolate, scan, restrict, collect packages)
    - Threat Intelligence management (file, IP, URL indicators)
    - Advanced Hunting with KQL queries
    - Incident management
    - Custom detection management
  - Comprehensive documentation:
    - `standalone/README.md` - Complete user guide
    - `standalone/QUICKSTART.md` - 10-minute setup guide
    - `standalone/examples/` - Sample hunting queries
  - PowerShell modules for each operation category
  - Prerequisites installer script
  - CSV export functionality
  - See [standalone/README.md](standalone/README.md) for details

### Fixed
- **Deploy to Azure Button**: Corrected GitHub raw URL format from `/refs/heads/main/` back to `/main/` to match GitHub's raw content URL format (fixes template download errors)
- All deployment documentation URLs updated to use correct GitHub raw content URL format without `refs/heads/` prefix

#### Interactive Console Feature 🖥️
- **New Interactive Console Tab** in main workbook (`workbook/MDEAutomatorWorkbook.json`)
  - Shell-like interface for command execution
  - Async command execution with automatic result polling
  - Configurable auto-refresh intervals (10s, 30s, 1m, 5m, or manual)
  - Support for all MDE operations:
    - Device Actions (isolate, scan, collect packages, etc.)
    - Advanced Hunting queries
    - Threat Intelligence management
    - Incident operations
    - Custom Detection management
  - Real-time status monitoring with visual indicators (✅ ⏳ ⏸️ ❌)
  - Automatic JSON parsing and table display
  - Command execution history (last 20 commands)
  - Export to Excel capability
  - Audit trail for compliance

#### Documentation Enhancements
- **New**: `INTERACTIVE_CONSOLE_GUIDE.md` - Comprehensive guide for the Interactive Console feature
- **New**: `DEPLOYMENT_TROUBLESHOOTING.md` - Detailed troubleshooting for ARM template deployment
- **New**: `CHANGELOG.md` - Project changelog following Keep a Changelog format

#### Deployment Improvements
- Added comprehensive troubleshooting for "Deploy to Azure" button failures
- Added manual template deployment instructions in all deployment guides
- Added alternative deployment methods (CLI, PowerShell, manual)
- Added verification steps for successful deployments
- Added CORS and accessibility guidance

### Changed

#### README.md
- Added Interactive Console feature to Features section (item #7)
- Added troubleshooting guidance for ARM template deployment button
- Added comprehensive example for using Interactive Console
- Updated usage documentation with step-by-step console guide

#### DEPLOYMENT.md
- Added "Option D: Manual Template Deployment" section
- Added warning and alternative methods for button failures
- Enhanced troubleshooting guidance
- Added verification steps post-deployment

#### QUICKSTART.md
- Added inline warning for Deploy button with quick fix
- Improved user guidance for deployment issues

#### deployment/README.md
- Completely rewrote "Troubleshooting" section
- Added three solutions for "Deploy to Azure" button failures:
  1. Manual Template Deployment (with detailed steps)
  2. Azure CLI deployment
  3. Direct template link verification
- Added common causes explanation
- Enhanced template validation guidance
- Added more detailed deployment failure scenarios

#### WORKBOOK_EXAMPLES.md
- Updated "Adding Console Features" section
- Referenced integrated Interactive Console tab
- Added notes about new async polling and JSON parsing features

### Technical Details

#### Workbook Structure Changes (`workbook/MDEAutomatorWorkbook.json`)
- Added new tab link for "🖥️ Interactive Console"
- Added new group "group - console" with 11 items:
  1. Console header with feature overview
  2. Configuration parameters (refresh interval, command type, actions, etc.)
  3. Step 1: Execute Command section with ARM endpoint query
  4. Step 2: Poll for Results section with auto-refresh query
  5. Step 3: View Results section with parsed JSON display
  6. Command History section showing last 20 executions
  7. Architecture documentation and how-it-works guide
- Implemented conditional visibility for results (only show when data available)
- Added parameter exports for chaining queries
- Implemented status formatting with color-coded indicators

#### ARM Template (`deployment/azuredeploy.json`)
- No changes to template itself (already valid and includes CORS)
- Template structure validated and confirmed working
- CORS configuration confirmed for Azure Portal access

### Fixed
- Addressed ARM template download errors by providing multiple deployment alternatives
- Improved documentation to prevent user confusion with deployment button failures
- Enhanced error messages and guidance throughout documentation

### Security
- No security changes (existing managed identity approach maintained)
- CORS properly configured for Azure Portal
- No secrets or credentials in template or workbook

## [Previous Versions]

This is the first formal changelog. Previous changes were tracked in git history only.

---

## Contributing

When making changes:
1. Update this CHANGELOG.md following the format above
2. Add entries under [Unreleased] section
3. Use categories: Added, Changed, Deprecated, Removed, Fixed, Security
4. Include clear descriptions and file paths
5. Reference issues/PRs where applicable

## Links

- [Repository](https://github.com/akefallonitis/defenderc2xsoar)
- [Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
- [Documentation](README.md)
