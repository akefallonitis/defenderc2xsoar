@{
    # Module manifest for DefenderXDRC2XSOAR
    ModuleVersion = '2.1.0'
    GUID = 'a1b2c3d4-e5f6-4789-a012-3456789abcde'
    Author = 'DefenderXDRC2XSOAR Contributors'
    Description = 'Microsoft Defender XDR (MDE, MDO, MDC, MDI, Entra ID, Intune, Azure) Automation Module for Azure Functions and XSOAR Integration - Complete Security Orchestration Platform'
    PowerShellVersion = '7.0'
    
    # Modules to import
    NestedModules = @(
        # Core Infrastructure (MUST load first)
        'AuthManager.psm1',
        'ValidationHelper.psm1',
        'LoggingHelper.psm1',
        
        # MDE (Endpoint Security)
        'MDEAuth.psm1',
        'MDEDevice.psm1',
        'MDEThreatIntel.psm1',
        'MDEHunting.psm1',
        'MDEIncident.psm1',
        'MDEDetection.psm1',
        'MDELiveResponse.psm1',
        'MDEConfig.psm1',
        
        # Email Security
        'MDOEmailRemediation.psm1',
        
        # Identity & Access
        'EntraIDIdentity.psm1',
        'ConditionalAccess.psm1',
        
        # Device Management
        'IntuneDeviceManagement.psm1',
        
        # Cloud Security
        'AzureInfrastructure.psm1',
        'DefenderForCloud.psm1',
        'DefenderForIdentity.psm1'
    )
    
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
