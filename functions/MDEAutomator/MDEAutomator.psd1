@{
    # Module manifest for MDEAutomator
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-4789-a012-3456789abcde'
    Author = 'MDEAutomator Contributors'
    Description = 'Microsoft Defender for Endpoint Automation Module for Azure Functions'
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
        'MDEConfig.psm1'
    )
    
    # Functions to export
    FunctionsToExport = @(
        # Authentication
        'Connect-MDE',
        'Test-MDEToken',
        'Get-MDEAuthHeaders',
        
        # Device Operations
        'Invoke-DeviceIsolation',
        'Invoke-DeviceUnisolation',
        'Invoke-RestrictAppExecution',
        'Invoke-UnrestrictAppExecution',
        'Invoke-AntivirusScan',
        'Invoke-CollectInvestigationPackage',
        'Invoke-StopAndQuarantineFile',
        'Get-DeviceInfo',
        'Get-AllDevices',
        
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
        
        # Custom Detections
        'Get-CustomDetections',
        
        # Live Response
        'Start-MDELiveResponseSession',
        'Get-MDELiveResponseSession',
        'Invoke-MDELiveResponseCommand',
        'Get-MDELiveResponseFile',
        'Send-MDELiveResponseFile'
    )
}
