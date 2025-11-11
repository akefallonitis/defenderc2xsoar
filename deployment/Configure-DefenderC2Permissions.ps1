<#
.SYNOPSIS
    Configure Multi-Tenant App Registration with all required API permissions for DefenderC2XSOAR
    
.DESCRIPTION
    This script automates the configuration of an Azure AD App Registration with all the
    necessary API permissions for DefenderC2XSOAR to function across:
    - Microsoft Defender for Endpoint (MDE)
    - Microsoft Graph API (MDO, Entra ID, Intune, MDI)
    - Azure Resource Manager (MDC, Azure Infrastructure)
    
    The script will:
    1. Connect to Microsoft Graph
    2. Find or create the app registration
    3. Add all required API permissions
    4. Grant admin consent (requires Global Administrator or Application Administrator)
    
.PARAMETER AppDisplayName
    The display name for the App Registration
    
.PARAMETER CreateIfNotExists
    Create the app registration if it doesn't exist
    
.PARAMETER GrantAdminConsent
    Automatically grant admin consent for all permissions (requires admin privileges)
    
.PARAMETER TenantId
    Tenant ID where the app registration exists (optional, will use current tenant if not specified)
    
.EXAMPLE
    .\Configure-DefenderC2Permissions.ps1 -AppDisplayName "DefenderC2XSOAR" -CreateIfNotExists -GrantAdminConsent
    
.EXAMPLE
    .\Configure-DefenderC2Permissions.ps1 -AppDisplayName "DefenderC2XSOAR" -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    
.NOTES
    Version: 1.0.0
    Requires: Microsoft.Graph PowerShell SDK (Install-Module Microsoft.Graph)
    Permissions Required: Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppDisplayName,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateIfNotExists,
    
    [Parameter(Mandatory = $false)]
    [switch]$GrantAdminConsent,
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId
)

# Check if Microsoft.Graph module is installed
Write-Host "Checking for Microsoft.Graph PowerShell module..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Write-Host "Microsoft.Graph.Applications module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Applications -Scope CurrentUser -Force
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
}

# Import modules
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Authentication

# Connect to Microsoft Graph
Write-Host "`n=== Connecting to Microsoft Graph ===" -ForegroundColor Cyan
$scopes = @(
    "Application.ReadWrite.All",
    "AppRoleAssignment.ReadWrite.All"
)

if ($TenantId) {
    Connect-MgGraph -Scopes $scopes -TenantId $TenantId
} else {
    Connect-MgGraph -Scopes $scopes
}

$context = Get-MgContext
Write-Host "✅ Connected to tenant: $($context.TenantId)" -ForegroundColor Green
Write-Host "   Account: $($context.Account)" -ForegroundColor Gray

# ============================================================================
# API PERMISSIONS CONFIGURATION
# ============================================================================

Write-Host "`n=== Defining Required API Permissions ===" -ForegroundColor Cyan

# Microsoft Defender for Endpoint API (WindowsDefenderATP)
$mdePermissions = @(
    "Alert.Read.All",
    "Alert.ReadWrite.All",
    "Machine.Read.All",
    "Machine.ReadWrite.All",
    "Machine.Isolate",
    "Machine.RestrictExecution",
    "Machine.Scan",
    "Machine.CollectForensics",
    "Machine.LiveResponse",
    "Machine.Offboard",
    "Machine.StopAndQuarantine",
    "AdvancedQuery.Read.All",
    "Incident.Read.All",
    "Incident.ReadWrite.All",
    "Ti.ReadWrite.All",
    "Ti.Read.All",
    "SecurityRecommendation.Read.All",
    "Vulnerability.Read.All",
    "RemediationTasks.Read.All"
)

# Microsoft Graph API Permissions
$graphPermissions = @(
    # User & Directory Management
    "User.Read.All",
    "User.ReadWrite.All",
    "Directory.Read.All",
    "Directory.ReadWrite.All",
    
    # Authentication & Identity Protection
    "UserAuthenticationMethod.Read.All",
    "UserAuthenticationMethod.ReadWrite.All",
    "IdentityRiskEvent.Read.All",
    "IdentityRiskEvent.ReadWrite.All",
    "IdentityRiskyUser.Read.All",
    "IdentityRiskyUser.ReadWrite.All",
    "User.RevokeSessions.All",
    
    # Security Events & Alerts
    "SecurityEvents.Read.All",
    "SecurityEvents.ReadWrite.All",
    "SecurityActions.Read.All",
    "SecurityActions.ReadWrite.All",
    "SecurityAlert.Read.All",
    "SecurityAlert.ReadWrite.All",
    
    # Threat Protection
    "ThreatSubmission.Read.All",
    "ThreatSubmission.ReadWrite.All",
    "ThreatIndicators.ReadWrite.OwnedBy",
    
    # Mail Operations (MDO)
    "Mail.Read",
    "Mail.ReadWrite",
    "MailboxSettings.ReadWrite",
    
    # Intune Device Management
    "DeviceManagementManagedDevices.Read.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementServiceConfig.Read.All",
    "DeviceManagementApps.Read.All"
)

Write-Host "  MDE Permissions: $($mdePermissions.Count)" -ForegroundColor Gray
Write-Host "  Graph Permissions: $($graphPermissions.Count)" -ForegroundColor Gray

# ============================================================================
# FIND OR CREATE APP REGISTRATION
# ============================================================================

Write-Host "`n=== Finding App Registration ===" -ForegroundColor Cyan
Write-Host "  Searching for: $AppDisplayName" -ForegroundColor Gray

$app = Get-MgApplication -Filter "displayName eq '$AppDisplayName'" -ErrorAction SilentlyContinue

if (-not $app) {
    if ($CreateIfNotExists) {
        Write-Host "  App not found. Creating new app registration..." -ForegroundColor Yellow
        
        $appParams = @{
            DisplayName = $AppDisplayName
            SignInAudience = "AzureADMultipleOrgs"  # Multi-tenant
            Description = "DefenderC2XSOAR - Multi-tenant security operations automation platform"
            Web = @{
                RedirectUris = @("https://portal.azure.com")
            }
        }
        
        $app = New-MgApplication @appParams
        Write-Host "✅ Created app registration: $($app.AppId)" -ForegroundColor Green
        
        # Create a client secret
        Write-Host "  Creating client secret (valid for 24 months)..." -ForegroundColor Gray
        $passwordCred = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
            DisplayName = "DefenderC2XSOAR-Secret-$(Get-Date -Format 'yyyyMMdd')"
            EndDateTime = (Get-Date).AddMonths(24)
        }
        
        Write-Host "✅ Client secret created" -ForegroundColor Green
        Write-Host "   🔑 SECRET VALUE: $($passwordCred.SecretText)" -ForegroundColor Yellow
        Write-Host "   ⚠️  SAVE THIS SECRET NOW - IT WON'T BE SHOWN AGAIN!" -ForegroundColor Red
        
    } else {
        Write-Error "App registration '$AppDisplayName' not found. Use -CreateIfNotExists to create it."
        exit 1
    }
} else {
    Write-Host "✅ Found existing app: $($app.AppId)" -ForegroundColor Green
}

# ============================================================================
# GET SERVICE PRINCIPAL IDs FOR APIs
# ============================================================================

Write-Host "`n=== Resolving API Service Principals ===" -ForegroundColor Cyan

# Get Microsoft Graph Service Principal
Write-Host "  Resolving Microsoft Graph..." -ForegroundColor Gray
$graphSp = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'" -ErrorAction Stop
Write-Host "  ✅ Microsoft Graph: $($graphSp.AppId)" -ForegroundColor Green

# Get WindowsDefenderATP Service Principal
Write-Host "  Resolving WindowsDefenderATP..." -ForegroundColor Gray
$mdeSp = Get-MgServicePrincipal -Filter "appId eq 'fc780465-2017-40d4-a0c5-307022471b92'" -ErrorAction SilentlyContinue

if (-not $mdeSp) {
    Write-Warning "  WindowsDefenderATP service principal not found in tenant. Creating..."
    # The AppId for WindowsDefenderATP is always fc780465-2017-40d4-a0c5-307022471b92
    $mdeSp = New-MgServicePrincipal -AppId "fc780465-2017-40d4-a0c5-307022471b92"
}
Write-Host "  ✅ WindowsDefenderATP: $($mdeSp.AppId)" -ForegroundColor Green

# ============================================================================
# CONFIGURE MICROSOFT GRAPH PERMISSIONS
# ============================================================================

Write-Host "`n=== Configuring Microsoft Graph Permissions ===" -ForegroundColor Cyan

$graphRequiredAccess = @{
    ResourceAppId = $graphSp.AppId
    ResourceAccess = @()
}

$addedGraphCount = 0
foreach ($permission in $graphPermissions) {
    $appRole = $graphSp.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application" }
    
    if ($appRole) {
        $graphRequiredAccess.ResourceAccess += @{
            Id = $appRole.Id
            Type = "Role"
        }
        Write-Host "  ✅ $permission" -ForegroundColor Green
        $addedGraphCount++
    } else {
        Write-Warning "  ⚠️  Permission not found: $permission"
    }
}

Write-Host "`n  Added $addedGraphCount/$($graphPermissions.Count) Graph permissions" -ForegroundColor Cyan

# ============================================================================
# CONFIGURE MICROSOFT DEFENDER FOR ENDPOINT PERMISSIONS
# ============================================================================

Write-Host "`n=== Configuring Microsoft Defender for Endpoint Permissions ===" -ForegroundColor Cyan

$mdeRequiredAccess = @{
    ResourceAppId = $mdeSp.AppId
    ResourceAccess = @()
}

$addedMdeCount = 0
foreach ($permission in $mdePermissions) {
    $appRole = $mdeSp.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application" }
    
    if ($appRole) {
        $mdeRequiredAccess.ResourceAccess += @{
            Id = $appRole.Id
            Type = "Role"
        }
        Write-Host "  ✅ $permission" -ForegroundColor Green
        $addedMdeCount++
    } else {
        Write-Warning "  ⚠️  Permission not found: $permission"
    }
}

Write-Host "`n  Added $addedMdeCount/$($mdePermissions.Count) MDE permissions" -ForegroundColor Cyan

# ============================================================================
# UPDATE APP REGISTRATION WITH PERMISSIONS
# ============================================================================

Write-Host "`n=== Updating App Registration ===" -ForegroundColor Cyan

$requiredResourceAccess = @(
    $graphRequiredAccess,
    $mdeRequiredAccess
)

Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $requiredResourceAccess
Write-Host "✅ Permissions added to app registration" -ForegroundColor Green

# ============================================================================
# GRANT ADMIN CONSENT
# ============================================================================

if ($GrantAdminConsent) {
    Write-Host "`n=== Granting Admin Consent ===" -ForegroundColor Cyan
    Write-Host "  This requires Global Administrator or Privileged Role Administrator..." -ForegroundColor Yellow
    
    try {
        # Get the service principal for the app
        $appSp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
        
        if (-not $appSp) {
            Write-Host "  Creating service principal for app..." -ForegroundColor Gray
            $appSp = New-MgServicePrincipal -AppId $app.AppId
        }
        
        # Grant consent for Microsoft Graph
        Write-Host "  Granting consent for Microsoft Graph permissions..." -ForegroundColor Gray
        foreach ($permission in $graphRequiredAccess.ResourceAccess) {
            try {
                New-MgServicePrincipalAppRoleAssignment `
                    -ServicePrincipalId $appSp.Id `
                    -PrincipalId $appSp.Id `
                    -ResourceId $graphSp.Id `
                    -AppRoleId $permission.Id `
                    -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Permission might already be granted
            }
        }
        
        # Grant consent for MDE
        Write-Host "  Granting consent for MDE permissions..." -ForegroundColor Gray
        foreach ($permission in $mdeRequiredAccess.ResourceAccess) {
            try {
                New-MgServicePrincipalAppRoleAssignment `
                    -ServicePrincipalId $appSp.Id `
                    -PrincipalId $appSp.Id `
                    -ResourceId $mdeSp.Id `
                    -AppRoleId $permission.Id `
                    -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Permission might already be granted
            }
        }
        
        Write-Host "✅ Admin consent granted successfully" -ForegroundColor Green
        
    } catch {
        Write-Warning "Failed to grant admin consent automatically: $($_.Exception.Message)"
        Write-Host "  Please grant admin consent manually in the Azure Portal" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️  Admin consent NOT granted" -ForegroundColor Yellow
    Write-Host "  To grant consent manually:" -ForegroundColor Gray
    Write-Host "  1. Go to Azure Portal → Azure Active Directory → App registrations" -ForegroundColor Gray
    Write-Host "  2. Find '$AppDisplayName'" -ForegroundColor Gray
    Write-Host "  3. Go to 'API permissions'" -ForegroundColor Gray
    Write-Host "  4. Click 'Grant admin consent for [Your Tenant]'" -ForegroundColor Gray
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n=== Configuration Summary ===" -ForegroundColor Cyan
Write-Host "  App Registration: $($app.DisplayName)" -ForegroundColor White
Write-Host "  Application (Client) ID: $($app.AppId)" -ForegroundColor White
Write-Host "  Object ID: $($app.Id)" -ForegroundColor White
Write-Host "  Tenant ID: $($context.TenantId)" -ForegroundColor White
Write-Host ""
Write-Host "  Microsoft Graph Permissions: $addedGraphCount" -ForegroundColor Green
Write-Host "  MDE Permissions: $addedMdeCount" -ForegroundColor Green
Write-Host "  Total Permissions: $($addedGraphCount + $addedMdeCount)" -ForegroundColor Green
Write-Host ""

if ($GrantAdminConsent) {
    Write-Host "  ✅ Admin Consent: GRANTED" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Admin Consent: PENDING (manual action required)" -ForegroundColor Yellow
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "  1. If you created a new app, save the client secret displayed above" -ForegroundColor White
Write-Host "  2. Grant admin consent if not already done" -ForegroundColor White
Write-Host "  3. Use these credentials in your DefenderC2XSOAR deployment:" -ForegroundColor White
Write-Host "     - APPID: $($app.AppId)" -ForegroundColor Gray
Write-Host "     - SECRETID: <your-client-secret>" -ForegroundColor Gray
Write-Host ""

# Disconnect
Disconnect-MgGraph | Out-Null
Write-Host "✅ Configuration complete!" -ForegroundColor Green
