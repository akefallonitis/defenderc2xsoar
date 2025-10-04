# Standalone PowerShell Framework - Architecture

This document describes the architecture and design of the standalone MDE Automator.

## Overview

The standalone framework is designed to be simple, portable, and require zero Azure infrastructure while maintaining the core functionality of the original MDEAutomator.

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                      User's Workstation                        │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐     │
│  │       Start-MDEAutomatorLocal.ps1                    │     │
│  │       (Main Menu & User Interface)                   │     │
│  └────────────────┬──────────────────┬──────────────────┘     │
│                   │                  │                         │
│                   │                  │                         │
│  ┌────────────────▼───────┐  ┌──────▼──────────────────┐     │
│  │   MDEAuth.psm1         │  │   MDEConfig.psm1        │     │
│  │   - OAuth2 Auth        │  │   - Credential Storage  │     │
│  │   - Token Management   │  │   - DPAPI Encryption    │     │
│  └────────────────┬───────┘  └─────────────────────────┘     │
│                   │                                            │
│                   │ Access Token                               │
│  ┌────────────────▼───────────────────────────────────┐       │
│  │           Operation Modules                        │       │
│  │  ┌────────────────┬──────────────────────────┐     │       │
│  │  │ MDEDevice.psm1 │ MDEThreatIntel.psm1      │     │       │
│  │  │ - Isolate      │ - Add Indicators         │     │       │
│  │  │ - Scan         │ - Remove Indicators      │     │       │
│  │  │ - Restrict     │ - List Indicators        │     │       │
│  │  └────────────────┴──────────────────────────┘     │       │
│  │  ┌────────────────┬──────────────────────────┐     │       │
│  │  │ MDEHunting.psm1│ MDEIncident.psm1         │     │       │
│  │  │ - Run Queries  │ - List Incidents         │     │       │
│  │  └────────────────┴──────────────────────────┘     │       │
│  │  ┌────────────────────────────────────────┐        │       │
│  │  │ MDEDetection.psm1                      │        │       │
│  │  │ - Manage Custom Detections             │        │       │
│  │  └────────────────────────────────────────┘        │       │
│  └────────────────────────────────────────────────────┘       │
│                                                                │
└────────────────┬───────────────────────────────────────────────┘
                 │
                 │ HTTPS / REST API
                 │
┌────────────────▼───────────────────────────────────────────────┐
│                      Microsoft Cloud                           │
│                                                                │
│  ┌──────────────────────┐         ┌────────────────────────┐  │
│  │  Azure Active        │         │  Microsoft Defender    │  │
│  │  Directory           │         │  for Endpoint          │  │
│  │  (Authentication)    │◄────────┤  API                   │  │
│  └──────────────────────┘         └────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Component Description

### Main Launcher (`Start-MDEAutomatorLocal.ps1`)

**Purpose**: Provides the main user interface and menu system

**Responsibilities**:
- Display menu-driven UI
- Handle user input and navigation
- Coordinate between modules
- Manage application state

**Key Features**:
- Colorized terminal output
- Input validation
- Error handling and user feedback
- Session management

### Authentication Module (`MDEAuth.psm1`)

**Purpose**: Handles authentication to Microsoft Defender API

**Responsibilities**:
- OAuth2 client credentials flow
- Access token acquisition
- Token validation and expiry checking
- Header generation for API calls

**Functions**:
- `Connect-MDE` - Authenticates and returns access token
- `Test-MDEToken` - Validates token expiration
- `Get-MDEAuthHeaders` - Creates authorization headers

### Configuration Module (`MDEConfig.psm1`)

**Purpose**: Manages secure credential storage

**Responsibilities**:
- Save credentials encrypted on disk
- Load credentials from storage
- Remove saved credentials

**Security**:
- Uses Windows DPAPI for encryption
- Per-user, per-machine encryption
- Stored in `%USERPROFILE%\.mdeautomator\`

**Functions**:
- `Save-MDEConfiguration` - Encrypt and save credentials
- `Get-MDEConfiguration` - Load and decrypt credentials
- `Remove-MDEConfiguration` - Delete saved credentials

### Device Operations Module (`MDEDevice.psm1`)

**Purpose**: Device management and actions

**Responsibilities**:
- Device isolation/unisolation
- App execution restriction
- Antivirus scanning
- Investigation package collection
- File quarantine
- Device information retrieval

**Functions**:
- `Invoke-DeviceIsolation` - Isolate devices
- `Invoke-DeviceUnisolation` - Release from isolation
- `Invoke-RestrictAppExecution` - Restrict app execution
- `Invoke-UnrestrictAppExecution` - Remove restriction
- `Invoke-AntivirusScan` - Initiate AV scan
- `Invoke-CollectInvestigationPackage` - Collect forensics
- `Invoke-StopAndQuarantineFile` - Quarantine file
- `Get-DeviceInfo` - Get device details
- `Get-AllDevices` - List all devices

### Threat Intelligence Module (`MDEThreatIntel.psm1`)

**Purpose**: Threat indicator management

**Responsibilities**:
- Add/remove file indicators (SHA256)
- Add/remove IP indicators
- Add/remove URL/domain indicators
- List all indicators

**Functions**:
- `Add-FileIndicator` - Add file hash indicator
- `Remove-FileIndicator` - Remove indicator
- `Add-IPIndicator` - Add IP indicator
- `Add-URLIndicator` - Add URL/domain indicator
- `Get-AllIndicators` - List all indicators

### Advanced Hunting Module (`MDEHunting.psm1`)

**Purpose**: Execute KQL queries

**Responsibilities**:
- Execute advanced hunting queries
- Return results for analysis

**Functions**:
- `Invoke-AdvancedHunting` - Execute KQL query

### Incident Management Module (`MDEIncident.psm1`)

**Purpose**: Security incident operations

**Responsibilities**:
- List security incidents
- Filter incidents by criteria

**Functions**:
- `Get-SecurityIncidents` - Retrieve incidents

### Custom Detection Module (`MDEDetection.psm1`)

**Purpose**: Custom detection rule management

**Responsibilities**:
- List custom detection rules
- Manage detection configurations

**Functions**:
- `Get-CustomDetections` - List custom detections

## Authentication Flow

```
1. User launches framework
   ↓
2. Framework checks for saved configuration
   ↓
3. If no config found:
   - Prompt for Tenant ID
   - Prompt for App ID
   - Prompt for Client Secret
   - Optionally save config
   ↓
4. Call Connect-MDE with credentials
   ↓
5. OAuth2 client credentials flow:
   - POST to login.microsoftonline.com
   - Exchange credentials for access token
   ↓
6. Receive access token with expiry
   ↓
7. Store token in memory (never on disk)
   ↓
8. Generate auth headers for API calls
   ↓
9. Make API requests to MDE endpoints
```

## API Communication

### Base URLs

- **Authentication**: `https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token`
- **MDE API**: `https://api.securitycenter.microsoft.com/api`
- **Graph API**: `https://graph.microsoft.com/v1.0/security`

### Request Flow

```
Module Function
   ↓
Get Auth Headers (MDEAuth)
   ↓
Construct API Request
   ↓
Invoke-RestMethod
   ↓
Parse Response
   ↓
Return to User
```

## Security Considerations

### Credential Storage

1. **Encryption Method**: Windows DPAPI
   - Per-user encryption
   - Per-machine encryption
   - OS-level protection

2. **Storage Location**: `%USERPROFILE%\.mdeautomator\config.json`

3. **Token Handling**:
   - Tokens stored in memory only
   - Never written to disk
   - Cleared on application exit

### API Security

1. **TLS/HTTPS**: All API calls use HTTPS
2. **Token Expiry**: Automatic validation of token expiration
3. **Scope Limitation**: Token scoped to MDE API only

### Best Practices

1. Use dedicated service account
2. Rotate client secrets regularly
3. Monitor API usage via Azure AD audit logs
4. Use least privilege principle for API permissions
5. Secure the workstation (encryption, screen lock)

## Error Handling

### Strategy

1. **Try-Catch Blocks**: All API calls wrapped in error handling
2. **User-Friendly Messages**: Technical errors translated to actionable messages
3. **Verbose Logging**: Optional `-Verbose` for troubleshooting
4. **Graceful Degradation**: Menu always accessible even if operations fail

### Common Error Scenarios

| Error | Cause | Resolution |
|-------|-------|------------|
| Authentication Failed | Invalid credentials | Verify tenant ID, app ID, secret |
| Token Expired | Token > 1 hour old | Re-authenticate (automatic) |
| Permission Denied | Missing API permission | Add permission in Azure AD |
| Device Not Found | Invalid device ID | Verify device exists |
| Rate Limited | Too many requests | Wait and retry |

## Extensibility

### Adding New Operations

1. Create new function in appropriate module
2. Add menu item in `Start-MDEAutomatorLocal.ps1`
3. Implement error handling
4. Add documentation

### Example: Adding New Device Action

```powershell
# In MDEDevice.psm1
function Invoke-NewAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )
    
    $headers = Get-MDEAuthHeaders -Token $Token
    
    try {
        $uri = "$script:MDEApiBase/machines/$DeviceId/newaction"
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
        return $response
    } catch {
        Write-Error "Failed: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Invoke-NewAction
```

## Performance Considerations

### Token Caching

- Access tokens cached in memory
- Re-used for multiple API calls
- Refreshed when expired

### API Call Optimization

- Batch operations where possible
- Parallel processing for multi-device operations
- Minimal API calls per operation

### Memory Management

- No persistent state beyond session
- Modules loaded on demand
- Clean exit releases all resources

## Comparison with Azure Version

| Aspect | Azure Version | Standalone Version |
|--------|---------------|-------------------|
| **Runtime** | Azure Functions | Local PowerShell |
| **UI** | Azure Workbook (Browser) | Terminal Menu |
| **State** | Stateless (per request) | Session-based |
| **Auth** | Managed Identity | Client Secret |
| **Scalability** | Auto-scaling | Single user |
| **Cost** | ~$50/month | Free |
| **Setup** | ~1 hour | ~10 minutes |
| **Portability** | Cloud-only | Any Windows machine |

## Future Enhancements

Potential improvements for the standalone framework:

1. **GUI Option**: Windows Forms or WPF interface
2. **Scheduled Operations**: Task scheduler integration
3. **Bulk Operations**: CSV import for batch actions
4. **History Tracking**: Local database of operations
5. **Report Generation**: HTML/PDF report exports
6. **Multi-Tenant**: Support multiple tenants in one session
7. **Proxy Support**: Corporate proxy configuration
8. **Linux/macOS**: Cross-platform PowerShell support

## References

- [Microsoft Defender API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api-overview)
- [OAuth 2.0 Client Credentials Flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow)
- [PowerShell Module Design](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-a-windows-powershell-module)
- [Windows Data Protection API (DPAPI)](https://docs.microsoft.com/en-us/dotnet/standard/security/how-to-use-data-protection)
