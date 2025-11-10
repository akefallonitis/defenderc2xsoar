@{
    # Module manifest for DefenderXDRC2XSOAR
    ModuleVersion = '2.0.0'
    GUID = 'a1b2c3d4-e5f6-4789-a012-3456789abcde'
    Author = 'DefenderXDRC2XSOAR Contributors'
    Description = 'Microsoft Defender XDR (MDE, MDO, MDI, Entra ID, Intune, Azure) Automation Module for Azure Functions and XSOAR Integration'
    PowerShellVersion = '7.0'
    
    # Modules to import
    NestedModules = @(
        'MDEAuth.psm1',
        'MDEDevice.psm1',
        'MDEThreatIntel.psm1',
        'MDEHunting.psm1',
        'MDEIncident.psm1',
        'MDEDetection.psm1',
        'MDELiveResponse.psm1',
        'MDEConfig.psm1',
        'MDOEmailRemediation.psm1',
        'EntraIDIdentity.psm1',
        'ConditionalAccess.psm1',
        'IntuneDeviceManagement.psm1',
        'AzureInfrastructure.psm1'
    )
    
    # Functions to export
    FunctionsToExport = @(
        # Authentication
        'Connect-MDE',
        'Test-MDEToken',
        'Get-MDEAuthHeaders',
        'Get-GraphToken',
        
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
        'Get-AzureVMs'
    )
}
