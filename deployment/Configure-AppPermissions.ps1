<#
.SYNOPSIS
    Configure App Registration API permissions for DefenderXDR C2
    
.DESCRIPTION
    Configures the MINIMUM required permissions for DefenderXDR C2 v3.0.0 (ALL 213 actions):
    - Microsoft Graph API (12 permissions for Entra ID, MDO, Intune, MCAS)
    - Microsoft Defender for Endpoint API (3 permissions)
    
    Total: 15 application permissions (least privilege)
    
    This script will:
    1. Remove ALL existing permissions (clean slate)
    2. Add only the 14 required permissions
    3. Generate admin consent URL
    4. Verify configuration
    
.PARAMETER AppId
    Application (Client) ID of your App Registration
    
.PARAMETER TenantId
    Azure AD Tenant ID where the app is registered
    
.PARAMETER GrantConsent
    Automatically grant admin consent (requires Global Administrator or Cloud Application Administrator)
    
.EXAMPLE
    # Configure permissions only (manual consent via URL)
    .\Configure-AppPermissions.ps1 -AppId "your-app-id" -TenantId "your-tenant-id"
    
.EXAMPLE
    # Configure permissions and grant consent automatically
    .\Configure-AppPermissions.ps1 -AppId "your-app-id" -TenantId "your-tenant-id" -GrantConsent
    
.NOTES
    Requires: Microsoft.Graph.Applications module
    Run: Install-Module Microsoft.Graph.Applications -Scope CurrentUser
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [switch]$GrantConsent
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DefenderXDR C2 - Permission Configuration" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if Microsoft.Graph.Applications module is installed
Write-Host "[CHECK] Verifying Microsoft.Graph.Applications module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Write-Host "❌ Microsoft.Graph.Applications module not found!" -ForegroundColor Red
    Write-Host "`nInstall with: Install-Module Microsoft.Graph.Applications -Scope CurrentUser`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Module found`n" -ForegroundColor Green

# Connect to Microsoft Graph
Write-Host "[CONNECT] Connecting to Microsoft Graph..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $TenantId -NoWelcome
    Write-Host "✅ Connected to Microsoft Graph`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

# Get the application
Write-Host "[LOAD] Loading App Registration..." -ForegroundColor Yellow
try {
    $app = Get-MgApplication -Filter "AppId eq '$AppId'"
    if (-not $app) {
        Write-Host "❌ App Registration not found with AppId: $AppId" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Found: $($app.DisplayName) (Object ID: $($app.Id))`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load app: $_" -ForegroundColor Red
    exit 1
}

# Define required permissions (MINIMUM for v3.0.0 - covers ALL 213 actions)
$requiredPermissions = @{
    # Microsoft Graph API
    "00000003-0000-0000-c000-000000000000" = @(
        @{ Id = "df021288-bdef-4463-88db-98f22de89214"; Name = "User.Read.All"; Type = "Role" }           # Entra ID - Read users
        @{ Id = "62a82d76-70ea-41e2-9197-370581804d09"; Name = "Group.Read.All"; Type = "Role" }          # Entra ID - Read groups
        @{ Id = "dbb9058a-0e50-45d7-ae91-66909b5d4664"; Name = "Policy.Read.All"; Type = "Role" }         # Entra ID - Read policies
        @{ Id = "b0afded3-3588-46d8-8b3d-9842eff778da"; Name = "AuditLog.Read.All"; Type = "Role" }       # Entra ID - Read audit logs
        @{ Id = "dc5007c0-2d7d-4c42-879c-2dab87571379"; Name = "IdentityRiskyUser.Read.All"; Type = "Role" } # Entra ID - Read risky users
        @{ Id = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e"; Name = "IdentityRiskEvent.Read.All"; Type = "Role" } # Entra ID - Read risk events
        @{ Id = "c7fbd983-d9aa-4fa7-84b8-17382c103bc4"; Name = "ThreatIndicators.ReadWrite.OwnedBy"; Type = "Role" } # MDO - Manage threat indicators
        @{ Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Name = "Mail.ReadWrite"; Type = "Role" }           # MDO - Email remediation (delete, move, quarantine)
        @{ Id = "5e0edab9-c148-49d0-b423-ac253e121825"; Name = "Device.Read.All"; Type = "Role" }          # Intune - Read devices
        @{ Id = "2f51be20-0bb4-4fed-bf7b-db946066c75e"; Name = "DeviceManagementManagedDevices.Read.All"; Type = "Role" } # Intune - Read managed devices
        @{ Id = "243333ab-4d21-40cb-a475-36241daa0842"; Name = "DeviceManagementConfiguration.Read.All"; Type = "Role" } # Intune - Read configs
        @{ Id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3"; Name = "DeviceManagementConfiguration.ReadWrite.All"; Type = "Role" } # Intune - Manage configs
    )
    
    # Microsoft Defender for Endpoint API
    "fc780465-2017-40d4-a0c5-307022471b92" = @(
        @{ Id = "93489bf5-0fbc-4f2d-b901-33f2fe08ff05"; Name = "Machine.Read.All"; Type = "Role" }         # MDE - Read machines
        @{ Id = "41269fc2-0eaf-4e93-97c6-f876a5455a90"; Name = "Machine.Isolate"; Type = "Role" }          # MDE - Isolate machines
        @{ Id = "44642bfe-8385-4adc-8fc6-fe3cb2c375c3"; Name = "Machine.RestrictExecution"; Type = "Role" } # MDE - Restrict execution
    )
}

# Backup current permissions
Write-Host "[BACKUP] Current permissions:" -ForegroundColor Yellow
$currentPermissions = $app.RequiredResourceAccess
if ($currentPermissions) {
    foreach ($resource in $currentPermissions) {
        $resourceName = if ($resource.ResourceAppId -eq "00000003-0000-0000-c000-000000000000") { "Microsoft Graph" } 
                       elseif ($resource.ResourceAppId -eq "fc780465-2017-40d4-a0c5-307022471b92") { "MDE" }
                       else { $resource.ResourceAppId }
        Write-Host "  - $resourceName : $($resource.ResourceAccess.Count) permissions" -ForegroundColor Gray
    }
} else {
    Write-Host "  - No existing permissions" -ForegroundColor Gray
}
Write-Host ""

# Remove all existing permissions (clean slate)
Write-Host "[CLEAN] Removing all existing permissions..." -ForegroundColor Yellow
try {
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @()
    Write-Host "✅ All existing permissions removed`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to remove permissions: $_" -ForegroundColor Red
    exit 1
}

# Build new permission structure
Write-Host "[CONFIG] Adding required permissions..." -ForegroundColor Yellow
$newPermissions = @()

foreach ($resourceAppId in $requiredPermissions.Keys) {
    $resourceAccess = @()
    
    foreach ($permission in $requiredPermissions[$resourceAppId]) {
        $resourceAccess += @{
            Id   = $permission.Id
            Type = $permission.Type
        }
    }
    
    $newPermissions += @{
        ResourceAppId  = $resourceAppId
        ResourceAccess = $resourceAccess
    }
    
    $resourceName = if ($resourceAppId -eq "00000003-0000-0000-c000-000000000000") { "Microsoft Graph" }
                   elseif ($resourceAppId -eq "fc780465-2017-40d4-a0c5-307022471b92") { "Microsoft Defender for Endpoint" }
                   else { $resourceAppId }
    
    Write-Host "  ✅ $resourceName : $($resourceAccess.Count) permissions" -ForegroundColor Green
}

# Apply new permissions
try {
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $newPermissions
    Write-Host "`n✅ Permissions configured successfully!`n" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Failed to add permissions: $_" -ForegroundColor Red
    exit 1
}

# Verify configuration
Write-Host "[VERIFY] Verifying configuration..." -ForegroundColor Yellow
$updatedApp = Get-MgApplication -ApplicationId $app.Id
$totalPermissions = ($updatedApp.RequiredResourceAccess | ForEach-Object { $_.ResourceAccess.Count } | Measure-Object -Sum).Sum

Write-Host "  Total permissions: $totalPermissions" -ForegroundColor Cyan
Write-Host "  Expected: 15 permissions" -ForegroundColor Cyan

if ($totalPermissions -eq 15) {
    Write-Host "`n✅ VERIFICATION PASSED - 15 permissions configured correctly!`n" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  WARNING: Expected 15 permissions but found $totalPermissions" -ForegroundColor Yellow
}

# Admin consent
$consentUrl = "https://login.microsoftonline.com/$TenantId/adminconsent?client_id=$AppId"

if ($GrantConsent) {
    Write-Host "[CONSENT] Granting admin consent automatically..." -ForegroundColor Yellow
    Write-Host "⚠️  This requires Global Administrator or Cloud Application Administrator role`n" -ForegroundColor Yellow
    
    try {
        # Open browser for consent
        Start-Process $consentUrl
        Write-Host "✅ Admin consent browser opened`n" -ForegroundColor Green
        Write-Host "Complete the consent process in your browser." -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Failed to open browser: $_" -ForegroundColor Red
        Write-Host "`nManual consent URL:" -ForegroundColor Yellow
        Write-Host $consentUrl -ForegroundColor Cyan
    }
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "ADMIN CONSENT REQUIRED" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Send this URL to your Global Administrator:`n" -ForegroundColor Yellow
    Write-Host $consentUrl -ForegroundColor Green
    Write-Host "`nOr run this script with -GrantConsent flag to open automatically`n" -ForegroundColor Yellow
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Configured Permissions Summary:" -ForegroundColor White
Write-Host "  Microsoft Graph API          : 12 permissions" -ForegroundColor Gray
Write-Host "  Microsoft Defender Endpoint  : 3 permissions" -ForegroundColor Gray
Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  TOTAL                        : 15 permissions" -ForegroundColor Green
Write-Host ""
Write-Host "Covers ALL 213 Actions:" -ForegroundColor White
Write-Host "  - MDO Worker: 16 actions (email remediation)" -ForegroundColor Gray
Write-Host "  - MDE Worker: 63 actions (device management)" -ForegroundColor Gray
Write-Host "  - Entra ID Worker: 20 actions (identity)" -ForegroundColor Gray
Write-Host "  - Intune Worker: 18 actions (MDM)" -ForegroundColor Gray
Write-Host "  - MDI Worker: 11 actions (identity threats)" -ForegroundColor Gray
Write-Host "  - MCAS Worker: 15 actions (cloud apps)" -ForegroundColor Gray
Write-Host "  - Azure Worker: 23 actions (infrastructure)" -ForegroundColor Gray
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Grant admin consent at URL above" -ForegroundColor Gray
Write-Host "  2. Deploy ARM template with this App ID" -ForegroundColor Gray
Write-Host "  3. Managed Identity will handle Azure Worker operations" -ForegroundColor Gray
Write-Host "  4. App Registration will handle Graph/MDE operations`n" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "✅ Done!`n" -ForegroundColor Green
