@{
    # Module manifest for DefenderXDRC2XSOAR
    ModuleVersion = '2.1.0'
    GUID = 'a1b2c3d4-e5f6-4789-a012-3456789abcde'
    Author = 'DefenderXDRC2XSOAR Contributors'
    Description = 'Microsoft Defender XDR (MDE, MDO, MDC, MDI, Entra ID, Intune, Azure) Automation Module for Azure Functions and XSOAR Integration - Complete Security Orchestration Platform'
    PowerShellVersion = '7.0'
    
    # Modules to import (Refactored v2.4.0 - 21 modules reduced to 7)
    NestedModules = @(
        # === SHARED UTILITY MODULES (6) ===
        # These provide reusable infrastructure for all workers
        
        # Authentication & Token Management
        'AuthManager.psm1',          # Multi-service auth with token caching
        
        # Input Validation & Security
        'ValidationHelper.psm1',     # Parameter validation, sanitization, rate limiting
        
        # Logging & Telemetry
        'LoggingHelper.psm1',        # Structured logging, metrics, tracing
        
        # Storage Operations
        'BlobManager.psm1',          # Live Response file operations
        'QueueManager.psm1',         # Batch operation queuing
        
        # Operation Tracking
        'StatusTracker.psm1',        # Long-running operation status tracking
        
        # === SERVICE-SPECIFIC MODULES (1) ===
        # Only DefenderForIdentity - actively used by MDIWorker
        'DefenderForIdentity.psm1'   # MDI-specific Graph API operations
    )
    
    # ============================================================================
    # ARCHITECTURE REFACTORING NOTES (v2.4.0)
    # ============================================================================
    #
    # REMOVED (13 service modules - archived to archive/old-modules/):
    #   - Business logic embedded in workers, not separate modules
    #   - Workers are self-contained with inline action handlers
    #   - Orchestrator only needs utilities (auth, validation, logging)
    #
    # Archived Service Modules:
    #   MDE:     MDEDevice, MDEIncident, MDEHunting, MDEThreatIntel, 
    #            MDEDetection, MDELiveResponse
    #   MDO:     MDOEmailRemediation
    #   EntraID: EntraIDIdentity, ConditionalAccess
    #   Intune:  IntuneDeviceManagement
    #   Azure:   AzureInfrastructure
    #
    # Archived Duplicates (2):
    #   - MDEAuth.psm1   (duplicate of AuthManager.psm1)
    #   - MDEConfig.psm1 (not used in Azure Functions)
    #
    # Benefits:
    #   - 71% module reduction (21 → 7)
    #   - Faster cold starts (less imports)
    #   - Clearer architecture (utilities vs business logic)
    #   - Easier maintenance (no duplicate code paths)
    #
    # Migration: All functionality preserved - logic moved to workers inline
    # ============================================================================
    
    # Functions to export
    FunctionsToExport = @(
        # Centralized Authentication
        'Get-OAuthToken',
        'Connect-DefenderXDR',
        'Get-AuthHeaders',
        'Clear-TokenCache',
        'Get-TokenCacheStats',
        
        # Input Validation & Sanitization
        'Test-TenantId',
        'Test-AppId',
        'Test-ServiceName',
        'Get-ValidServices',
        'Get-ValidActionsForService',
        'Test-ActionName',
        'Test-MachineId',
        'Test-SubscriptionId',
        'Test-UserId',
        'ConvertTo-SafeString',
        'ConvertTo-SafeFileName',
        'Test-IPAddress',
        'Test-URL',
        'Test-FileHash',
        'Test-RequiredParameters',
        'Test-RateLimit',
        'Clear-RateLimitTracker',
        
        # Logging & Telemetry
        'Write-XDRLog',
        'Write-XDRRequestLog',
        'Write-XDRResponseLog',
        'Write-XDRAuthLog',
        'Write-XDRDependencyLog',
        'Write-XDRMetric',
        'Write-XDRError',
        'New-XDRStopwatch',
        'Get-XDRElapsedMs',
        
        # Legacy Authentication (Backward Compatible)
        'Connect-MDE',
        'Test-MDEToken',
        'Get-MDEAuthHeaders',
        'Get-GraphToken',
        'Get-AzureAccessToken',
        
        # Device Operations (MDE)
        'Invoke-DeviceIsolation',
        'Invoke-DeviceUnisolation',
        'Invoke-RestrictAppExecution',
        'Invoke-UnrestrictAppExecution',
        'Invoke-AntivirusScan',
        'Invoke-CollectInvestigationPackage',
        'Invoke-StopAndQuarantineFile',
        'Invoke-DeviceOffboard',
        'Start-AutomatedInvestigation',
        'Get-DeviceInfo',
        'Get-AllDevices',
        'Get-MachineActionStatus',
        'Get-AllMachineActions',
        'Stop-MachineAction',
        
        # Threat Intelligence
        'Add-FileIndicator',
        'Remove-FileIndicator',
        'Add-IPIndicator',
        'Add-URLIndicator',
        'Get-AllIndicators',
        
        # Advanced Hunting
        'Invoke-AdvancedHunting',
        
        # Incident Management
        'Get-SecurityIncidents',
        'Update-SecurityIncident',
        'Add-IncidentComment',
        
        # Custom Detections
        'Get-CustomDetections',
        'New-CustomDetection',
        'Update-CustomDetection',
        'Remove-CustomDetection',
        
        # Live Response
        'Start-MDELiveResponseSession',
        'Get-MDELiveResponseSession',
        'Invoke-MDELiveResponseCommand',
        'Get-MDELiveResponseCommandResult',
        'Wait-MDELiveResponseCommand',
        'Get-MDELiveResponseFile',
        'Send-MDELiveResponseFile',
        
        # Email Remediation (MDO)
        'Invoke-EmailRemediation',
        'Submit-EmailThreat',
        'Submit-URLThreat',
        'Remove-MailForwardingRules',
        
        # Identity & Access (Entra ID)
        'Set-UserAccountStatus',
        'Reset-UserPassword',
        'Confirm-UserCompromised',
        'Dismiss-UserRisk',
        'Revoke-UserSessions',
        'Get-UserRiskDetections',
        
        # Conditional Access
        'New-NamedLocation',
        'Update-NamedLocation',
        'New-ConditionalAccessPolicy',
        'New-SignInRiskPolicy',
        'New-UserRiskPolicy',
        'Get-NamedLocations',
        
        # Intune Device Management
        'Invoke-IntuneDeviceRemoteLock',
        'Invoke-IntuneDeviceWipe',
        'Invoke-IntuneDeviceRetire',
        'Sync-IntuneDevice',
        'Invoke-IntuneDefenderScan',
        'Get-IntuneManagedDevices',
        
        # Azure Infrastructure
        'Get-AzureAccessToken',
        'Add-NSGDenyRule',
        'Stop-AzureVM',
        'Disable-StorageAccountPublicAccess',
        'Remove-VMPublicIP',
        'Get-AzureVMs',
        
        # Microsoft Defender for Cloud (NEW)
        'Get-MDCSecurityAlerts',
        'Update-MDCSecurityAlert',
        'Get-MDCSecurityRecommendations',
        'Get-MDCSecureScore',
        'Get-MDCRegulatoryCompliance',
        'Enable-MDCDefenderPlan',
        'Get-MDCDefenderPlans',
        'Set-MDCAutoProvisioning',
        'Get-MDCJitAccessPolicy',
        'New-MDCJitAccessRequest',
        
        # Microsoft Defender for Identity (NEW)
        'Get-MDIAlerts',
        'Update-MDIAlert',
        'Get-MDIHealthIssues',
        'Get-MDILateralMovementPaths',
        'Get-MDIIdentitySecureScore',
        'Get-MDISuspiciousActivities',
        'Get-MDIExposedCredentials',
        'Get-MDIAccountEnumeration',
        'Get-MDIPrivilegeEscalation',
        'Get-MDIDomainControllerCoverage',
        'Get-MDIReconnaissanceActivities'
    )
}
