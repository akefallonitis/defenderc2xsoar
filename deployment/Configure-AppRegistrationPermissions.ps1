<#
.SYNOPSIS
    Reset and Configure App Registration Permissions for DefenderXDR C2 v3.0.0

.DESCRIPTION
    Comprehensive script to clean up, renew, and set all required API permissions
    for the DefenderXDR C2 multi-tenant app registration.
    
    Required Permissions for v3.0.0:
    - Microsoft Graph API (75% of operations)
    - Microsoft Defender for Endpoint API (MDE operations)
    - Azure Resource Manager (Azure infrastructure operations)

.PARAMETER AppId
    Application (Client) ID of the App Registration
    
.PARAMETER TenantId
    Azure AD Tenant ID where the app is registered
    
.PARAMETER CreateNewSecret
    Create a new client secret (recommended for security)

.EXAMPLE
    .\Configure-AppRegistrationPermissions.ps1 -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -CreateNewSecret
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateNewSecret
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "DefenderXDR C2 v3.0.0 - App Registration Configuration" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "App ID:     $AppId" -ForegroundColor Yellow
Write-Host "Tenant ID:  $TenantId" -ForegroundColor Yellow
Write-Host ""

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "❌ Microsoft.Graph PowerShell module not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -TenantId $TenantId -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to connect to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 1: Get Application
# ============================================================================

Write-Host "Step 1: Retrieving App Registration..." -ForegroundColor Cyan
try {
    $app = Get-MgApplication -Filter "appId eq '$AppId'"
    if (-not $app) {
        throw "Application not found with App ID: $AppId"
    }
    Write-Host "✅ Found: $($app.DisplayName)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 2: Define Required API Permissions
# ============================================================================

Write-Host "Step 2: Defining Required API Permissions..." -ForegroundColor Cyan

# Microsoft Graph API permissions
$graphAppId = "00000003-0000-0000-c000-000000000000"

$graphPermissions = @(
    # ===================================================================
    # XDR SECURITY OPERATIONS (CORE - REQUIRED)
    # ===================================================================
    # Microsoft Defender XDR incident/alert management
    @{ Id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3"; Name = "SecurityIncident.ReadWrite.All"; Type = "Role" }
    @{ Id = "45cc0394-e837-488b-a098-1918f48d186c"; Name = "SecurityAlert.ReadWrite.All"; Type = "Role" }
    @{ Id = "db06fb33-1953-4b7b-a2ac-f1e2c854f7ae"; Name = "SecurityActions.ReadWrite.All"; Type = "Role" }
    
    # Advanced Hunting queries across XDR
    @{ Id = "dd98c7f5-2d42-42d3-a0e4-633161547251"; Name = "ThreatHunting.Read.All"; Type = "Role" }
    
    # Threat Intelligence Indicators (IOCs)
    @{ Id = "d665a8d9-5a5b-4ce1-88f8-7f7b0e8e3e0f"; Name = "ThreatIndicators.ReadWrite.OwnedBy"; Type = "Role" }
    
    # ===================================================================
    # IDENTITY PROTECTION (ENTRA ID WORKER - REQUIRED)
    # ===================================================================
    # User account management (disable, enable, read)
    @{ Id = "df021288-bdef-4463-88db-98f22de89214"; Name = "User.Read.All"; Type = "Role" }
    @{ Id = "741f803b-c850-494e-b5df-cde7c675a1ca"; Name = "User.ReadWrite.All"; Type = "Role" }
    
    # MFA & Authentication methods (reset MFA, force re-auth)
    @{ Id = "50483e42-d915-4231-9639-7fdb7fd190e5"; Name = "UserAuthenticationMethod.ReadWrite.All"; Type = "Role" }
    
    # Identity Risk (risky users, risk detections)
    @{ Id = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e"; Name = "IdentityRiskyUser.ReadWrite.All"; Type = "Role" }
    
    # Conditional Access Policies (emergency CA policy creation)
    @{ Id = "01c0a623-fc9b-48e9-b794-0756f8e8f067"; Name = "Policy.ReadWrite.ConditionalAccess"; Type = "Role" }
    
    # ===================================================================
    # DEVICE MANAGEMENT (INTUNE WORKER - REQUIRED)
    # ===================================================================
    # Device actions (remote lock, wipe, retire, sync)
    @{ Id = "5b07b0dd-2377-4e44-a38d-703f09a0dc3c"; Name = "DeviceManagementManagedDevices.ReadWrite.All"; Type = "Role" }
    
    # Device configuration (compliance policies)
    @{ Id = "0883f392-0a7a-443d-8c76-16a6d39c7b63"; Name = "DeviceManagementConfiguration.ReadWrite.All"; Type = "Role" }
    
    # ===================================================================
    # EMAIL SECURITY (MDO WORKER - OPTIONAL)
    # ===================================================================
    # ⚠️ ONLY if you need email remediation (soft/hard delete, ZAP)
    # Comment out if NOT using MDO email actions
    @{ Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Name = "Mail.ReadWrite"; Type = "Role" }
    @{ Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96"; Name = "Mail.Send"; Type = "Role" }
    
    # ===================================================================
    # CLOUD APP SECURITY (MCAS WORKER - OPTIONAL)
    # ===================================================================
    # ⚠️ ONLY if you need file quarantine/sharing control
    # Comment out if NOT using MCAS file actions
    @{ Id = "75359482-378d-4052-8f01-80520e7db3cd"; Name = "Files.ReadWrite.All"; Type = "Role" }
    
    # ===================================================================
    # AUDIT LOGGING (RECOMMENDED)
    # ===================================================================
    # Sign-in logs, audit logs for investigation
    @{ Id = "b0afded3-3588-46d8-8b3d-9842eff778da"; Name = "AuditLog.Read.All"; Type = "Role" }
)

# Microsoft Defender for Endpoint API permissions
$mdeAppId = "fc780465-2017-40d4-a0c5-307022471b92"

$mdePermissions = @(
    @{ Id = "7b3f05d5-f68c-4b8d-8c59-a2ecd12f24af"; Name = "Machine.ReadWrite.All"; Type = "Role" }
    @{ Id = "65929c4b-e30c-4c97-a9b8-2c2c19e4a2a8"; Name = "Machine.LiveResponse"; Type = "Role" }
    @{ Id = "93489bf5-0fbc-4f2d-b901-33f2fe08ff05"; Name = "Alert.ReadWrite.All"; Type = "Role" }
    @{ Id = "b27a61ec-b99c-4d6a-b126-c4375d08ae30"; Name = "Ti.ReadWrite.All"; Type = "Role" }
    @{ Id = "ea8291d3-4b9a-44b5-bc3a-6cea3026dc79"; Name = "AdvancedQuery.Read.All"; Type = "Role" }
    @{ Id = "72043a3d-f54e-4988-8c3e-d5dd8a5c4799"; Name = "Library.Manage"; Type = "Role" }
)

Write-Host "  Microsoft Graph API: $($graphPermissions.Count) permissions" -ForegroundColor Gray
Write-Host "  Microsoft Defender for Endpoint API: $($mdePermissions.Count) permissions" -ForegroundColor Gray
Write-Host "  TOTAL: $($graphPermissions.Count + $mdePermissions.Count) permissions" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ℹ️  Email Security (Mail.*) and File Operations (Files.*) are OPTIONAL" -ForegroundColor Yellow
Write-Host "     Comment them out if you don't use MDO email remediation or MCAS file actions" -ForegroundColor Gray
Write-Host "✅ Permissions defined" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 3: Remove Existing Permissions (Clean Slate)
# ============================================================================

Write-Host "Step 3: Removing existing API permissions..." -ForegroundColor Cyan

try {
    # Get current permissions
    $currentPermissions = $app.RequiredResourceAccess
    
    if ($currentPermissions.Count -gt 0) {
        Write-Host "  Found $($currentPermissions.Count) existing resource access configurations" -ForegroundColor Yellow
        
        # Clear all required resource access
        Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @()
        Write-Host "✅ Cleared all existing permissions" -ForegroundColor Green
    }
    else {
        Write-Host "  No existing permissions to remove" -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️  Warning: Could not remove existing permissions: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# STEP 4: Add New API Permissions
# ============================================================================

Write-Host "Step 4: Adding new API permissions..." -ForegroundColor Cyan

$requiredResourceAccess = @()

# Add Microsoft Graph permissions
$graphResourceAccess = @()
foreach ($perm in $graphPermissions) {
    $graphResourceAccess += @{
        Id = $perm.Id
        Type = $perm.Type
    }
    Write-Host "  + Graph: $($perm.Name)" -ForegroundColor DarkGray
}

$requiredResourceAccess += @{
    ResourceAppId = $graphAppId
    ResourceAccess = $graphResourceAccess
}

# Add MDE permissions
$mdeResourceAccess = @()
foreach ($perm in $mdePermissions) {
    $mdeResourceAccess += @{
        Id = $perm.Id
        Type = $perm.Type
    }
    Write-Host "  + MDE: $($perm.Name)" -ForegroundColor DarkGray
}

$requiredResourceAccess += @{
    ResourceAppId = $mdeAppId
    ResourceAccess = $mdeResourceAccess
}

try {
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $requiredResourceAccess
    Write-Host "✅ Added $($graphPermissions.Count + $mdePermissions.Count) API permissions" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to add permissions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 5: Grant Admin Consent (if possible)
# ============================================================================

Write-Host "Step 5: Granting admin consent..." -ForegroundColor Cyan
Write-Host "  ⚠️  Admin consent must be granted manually in Azure Portal" -ForegroundColor Yellow
Write-Host "  Navigate to: Azure Portal > App Registrations > $($app.DisplayName) > API permissions > Grant admin consent" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# STEP 6: Create New Client Secret (if requested)
# ============================================================================

if ($CreateNewSecret) {
    Write-Host "Step 6: Creating new client secret..." -ForegroundColor Cyan
    
    try {
        $passwordCredential = @{
            DisplayName = "DefenderXDR-C2-v3.0.0-$(Get-Date -Format 'yyyyMMdd')"
            EndDateTime = (Get-Date).AddYears(2)
        }
        
        $newSecret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential $passwordCredential
        
        Write-Host "✅ New client secret created" -ForegroundColor Green
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host "⚠️  SAVE THIS SECRET - IT WILL NOT BE SHOWN AGAIN!" -ForegroundColor Red
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Client Secret Value: " -ForegroundColor Yellow -NoNewline
        Write-Host $newSecret.SecretText -ForegroundColor White
        Write-Host ""
        Write-Host "Secret ID: $($newSecret.KeyId)" -ForegroundColor Gray
        Write-Host "Expires: $($newSecret.EndDateTime)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Update Azure Function App environment variables:" -ForegroundColor Cyan
        Write-Host "  APPID     = $AppId" -ForegroundColor White
        Write-Host "  SECRETID  = $($newSecret.SecretText)" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Host "❌ Failed to create client secret: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ============================================================================
# STEP 7: Configuration Summary
# ============================================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Configuration Complete" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ API permissions configured" -ForegroundColor Green
Write-Host "✅ Microsoft Graph API: $($graphPermissions.Count) permissions" -ForegroundColor Green
Write-Host "✅ Microsoft Defender for Endpoint API: $($mdePermissions.Count) permissions" -ForegroundColor Green
Write-Host "✅ TOTAL: $($graphPermissions.Count + $mdePermissions.Count) LEAST-PRIVILEGE permissions" -ForegroundColor Cyan
Write-Host ""
Write-Host "ℹ️  REMOVED (not needed for XDR C2 operations):" -ForegroundColor Yellow
Write-Host "   ❌ eDiscovery.ReadWrite.All (not used)" -ForegroundColor Gray
Write-Host "   ❌ Application.ReadWrite.All (not needed)" -ForegroundColor Gray
Write-Host "   ❌ RoleManagement.ReadWrite.Directory (excessive privilege)" -ForegroundColor Gray
Write-Host "   ❌ Directory.ReadWrite.All (excessive privilege)" -ForegroundColor Gray
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Grant admin consent in Azure Portal (required for application permissions)" -ForegroundColor White
Write-Host "2. Update Function App environment variables with APPID and SECRETID" -ForegroundColor White
Write-Host "3. Restart Function App to apply changes" -ForegroundColor White
Write-Host "4. Test API endpoints" -ForegroundColor White
Write-Host ""

Write-Host "Azure Portal URL:" -ForegroundColor Cyan
Write-Host "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$AppId" -ForegroundColor Blue
Write-Host ""

# Disconnect
Disconnect-MgGraph | Out-Null

Write-Host "================================================================" -ForegroundColor Cyan
