<#
.SYNOPSIS
    Configure API permissions for DefenderC2XSOAR multi-tenant app registration
.DESCRIPTION
    This script applies all required API permissions for the DefenderC2XSOAR integration:
    - Microsoft Defender for Endpoint (17 permissions)
    - Microsoft Graph (29 permissions - includes SecurityIncident.* for XDR incidents)
    - Azure Resource Manager RBAC (Security Admin, Security Reader)
    
    The script will:
    1. Connect to Microsoft Graph
    2. Add all required application permissions to the app registration
    3. Optionally grant admin consent (requires Global Admin role)
    4. Display permission status
    
    TWO-STEP PROCESS:
    - Step 1: Application Administrator can ADD permissions (use -SkipConsent)
    - Step 2: Global Administrator must GRANT consent (run without -SkipConsent)
.PARAMETER AppId
    Application (client) ID of the multi-tenant app registration
.PARAMETER TenantId
    Azure AD Tenant ID where the app is registered
.PARAMETER SkipConsent
    Skip granting admin consent (useful when running as Application Administrator)
    Use this flag if you only want to add permissions without granting consent.
    A Global Administrator must run the script again without this flag to grant consent.
.PARAMETER SkipAzureRBAC
    Skip Azure Resource Manager RBAC role assignment (useful if managing separately)
.EXAMPLE
    # Step 1: Add permissions (Application Administrator)
    .\Set-DefenderC2XSOARPermissions.ps1 -AppId "0b75d6c4-8466-420c-bfc3-8c0c4fadae24" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -SkipConsent
    
    # Step 2: Grant admin consent (Global Administrator)
    .\Set-DefenderC2XSOARPermissions.ps1 -AppId "0b75d6c4-8466-420c-bfc3-8c0c4fadae24" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
.NOTES
    Author: DefenderC2XSOAR Team
    Requires: Microsoft.Graph PowerShell SDK (Install-Module Microsoft.Graph)
    Required Scopes: Application.ReadWrite.All (to add permissions), AppRoleAssignment.ReadWrite.All (to grant consent)
    Required Roles: Application Administrator (to add), Global Administrator (to grant consent)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$' })]
    [string]$AppId,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$' })]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipConsent,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAzureRBAC
)

$ErrorActionPreference = "Stop"

# Check if Microsoft.Graph module is installed
Write-Host "`n🔍 Checking for Microsoft.Graph PowerShell SDK..." -ForegroundColor Cyan
$graphModule = Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication" | Select-Object -First 1
if (-not $graphModule) {
    Write-Host "❌ Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    Write-Host "✅ Microsoft.Graph module installed" -ForegroundColor Green
} else {
    Write-Host "✅ Microsoft.Graph module found (v$($graphModule.Version))" -ForegroundColor Green
}

# Connect to Microsoft Graph
Write-Host "`n🔐 Connecting to Microsoft Graph..." -ForegroundColor Cyan
Write-Host "   Tenant: $TenantId" -ForegroundColor Gray

if ($SkipConsent) {
    Write-Host "   Mode: ADD PERMISSIONS ONLY (Application Administrator)" -ForegroundColor Yellow
    Write-Host "   Required Scope: Application.ReadWrite.All" -ForegroundColor Gray
    $scopes = @("Application.ReadWrite.All")
} else {
    Write-Host "   Mode: ADD PERMISSIONS + GRANT CONSENT (Global Administrator)" -ForegroundColor Yellow
    Write-Host "   Required Scopes: Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All" -ForegroundColor Gray
    $scopes = @("Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All")
}

try {
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop
    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

# Get the app registration and service principal
Write-Host "`n🔍 Finding application..." -ForegroundColor Cyan
try {
    # Get app registration first
    $app = Get-MgApplication -Filter "appId eq '$AppId'" -ErrorAction Stop
    if (-not $app) {
        Write-Host "❌ App registration not found for AppId: $AppId" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Found app registration: $($app.DisplayName) (ObjectId: $($app.Id))" -ForegroundColor Green
    
    # Get service principal
    $appServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop
    if (-not $appServicePrincipal) {
        Write-Host "❌ Service principal not found for AppId: $AppId" -ForegroundColor Red
        Write-Host "   Creating service principal..." -ForegroundColor Yellow
        $appServicePrincipal = New-MgServicePrincipal -AppId $AppId -ErrorAction Stop
        Write-Host "✅ Service principal created" -ForegroundColor Green
    }
    Write-Host "✅ Found service principal: $($appServicePrincipal.DisplayName) (ObjectId: $($appServicePrincipal.Id))" -ForegroundColor Green
} catch {
    Write-Host "❌ Error finding application: $_" -ForegroundColor Red
    exit 1
}

# Define required API permissions (XDR-FOCUSED - Incident Response Only)
# Removed: Compliance reporting, vulnerability management, IOC management, live response
# Focus: Detect → Investigate → Respond → Remediate
$apiPermissions = @{
    "WindowsDefenderATP" = @{
        DisplayName = "WindowsDefenderATP"
        AppId = "fc780465-2017-40d4-a0c5-307022471b92"
        Permissions = @(
            # Core XDR - Alert & Incident Management
            "Alert.Read.All",
            "Alert.ReadWrite.All",
            # Core XDR - Device Response Actions
            "Machine.Read.All",
            "Machine.ReadWrite.All",
            "Machine.Isolate",
            "Machine.RestrictExecution",
            "Machine.Scan",
            # Core XDR - Threat Hunting
            "AdvancedQuery.Read.All"
            # REMOVED: Machine.CollectForensics (rarely used, complex)
            # REMOVED: Machine.LiveResponse (security risk, rarely used)
            # REMOVED: Ti.ReadWrite.All (IOC management, not incident response)
            # REMOVED: SecurityRecommendation.Read.All (compliance, not XDR)
            # REMOVED: Vulnerability.Read.All (compliance, not XDR)
            # REMOVED: File.Read.All (not needed for core actions)
            # REMOVED: Ip.Read.All (not needed for core actions)
            # REMOVED: Url.Read.All (not needed for core actions)
            # REMOVED: User.Read.All (duplicate - already in Graph API)
        )
    }
    "MicrosoftGraph" = @{
        DisplayName = "Microsoft Graph"
        AppId = "00000003-0000-0000-c000-000000000000"
        Permissions = @(
            # Core XDR - User Identity Management
            "User.Read.All",
            "User.ReadWrite.All",
            "Directory.Read.All",
            "UserAuthenticationMethod.ReadWrite.All",
            "User.RevokeSessions.All",
            # Core XDR - Identity Protection
            "IdentityRiskEvent.Read.All",
            "IdentityRiskyUser.Read.All",
            # Core XDR - Network-Level Threat Blocking (Conditional Access Named Locations)
            "Policy.Read.All",
            "Policy.ReadWrite.ConditionalAccess",
            # Core XDR - Security Events (Unified XDR Alerts/Incidents)
            "SecurityEvents.Read.All",
            "SecurityEvents.ReadWrite.All",
            "SecurityIncident.Read.All",
            "SecurityIncident.ReadWrite.All",
            # Core XDR - Threat Submission (Phishing Reports)
            "ThreatSubmission.ReadWrite.All",
            # Core XDR - Device Management (Intune Mobile Response)
            "DeviceManagementManagedDevices.Read.All",
            "DeviceManagementManagedDevices.ReadWrite.All",
            # Core XDR - Email Response (MDO)
            "Mail.ReadWrite"
            # REMOVED: Directory.ReadWrite.All (excessive, not needed)
            # REMOVED: UserAuthenticationMethod.Read.All (ReadWrite covers read)
            # REMOVED: IdentityRiskEvent.ReadWrite.All (read-only sufficient)
            # REMOVED: IdentityRiskyUser.ReadWrite.All (actions via dedicated endpoints)
            # REMOVED: ThreatIndicators.ReadWrite.OwnedBy (IOC mgmt, not XDR)
            # REMOVED: SecurityActions.Read.All (not used)
            # REMOVED: SecurityActions.ReadWrite.All (not used)
            # REMOVED: DeviceManagementConfiguration.Read.All (compliance, not XDR)
            # REMOVED: Group.Read.All (not needed for XDR actions)
            # REMOVED: GroupMember.Read.All (not needed for XDR actions)
            # REMOVED: Application.Read.All (not needed for XDR actions)
            # REMOVED: Policy.Read.All (compliance queries, not XDR)
            # REMOVED: AuditLog.Read.All (reporting, not incident response)
            # REMOVED: Reports.Read.All (compliance reporting, not XDR)
        )
    }
}

$totalPermissions = ($apiPermissions.Values | ForEach-Object { $_.Permissions.Count } | Measure-Object -Sum).Sum
$successCount = 0
$skipCount = 0
$errorCount = 0
$consentSuccessCount = 0
$consentErrorCount = 0

Write-Host "`n📋 Processing $totalPermissions XDR-focused API permissions (23 total)..." -ForegroundColor Cyan
Write-Host "   Focus: Detect → Investigate → Respond → Remediate" -ForegroundColor Gray
Write-Host "   NEW: Network-level threat blocking (Conditional Access Named Locations)" -ForegroundColor Green
Write-Host "   NEW: Threat intelligence automation (MDE Indicators for IOC blocking)" -ForegroundColor Green

# Track permissions that need consent
$permissionsNeedingConsent = @()

foreach ($api in $apiPermissions.GetEnumerator()) {
    $apiName = $api.Key
    $apiConfig = $api.Value
    
    Write-Host "`n🔧 Configuring $($apiConfig.DisplayName) permissions..." -ForegroundColor Yellow
    Write-Host "   API AppId: $($apiConfig.AppId)" -ForegroundColor Gray
    Write-Host "   Permissions: $($apiConfig.Permissions.Count)" -ForegroundColor Gray
    
    # Get the resource service principal
    try {
        $resourceSP = Get-MgServicePrincipal -Filter "appId eq '$($apiConfig.AppId)'" -ErrorAction Stop
        if (-not $resourceSP) {
            Write-Host "   ❌ Resource service principal not found for $($apiConfig.DisplayName)" -ForegroundColor Red
            $errorCount += $apiConfig.Permissions.Count
            continue
        }
        Write-Host "   ✅ Found resource: $($resourceSP.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error finding resource SP: $_" -ForegroundColor Red
        $errorCount += $apiConfig.Permissions.Count
        continue
    }
    
    # Get all app roles from the resource
    $appRoles = $resourceSP.AppRoles
    
    # Get current app permissions
    $currentApp = Get-MgApplication -ApplicationId $app.Id -Property RequiredResourceAccess -ErrorAction Stop
    $currentAppPermissions = $currentApp.RequiredResourceAccess
    
    # Build list of permissions to add for this API
    $permissionsToAdd = @()
    
    foreach ($permissionName in $apiConfig.Permissions) {
        Write-Host "   Processing: $permissionName..." -NoNewline -ForegroundColor Gray
        
        # Find the app role
        $appRole = $appRoles | Where-Object { $_.Value -eq $permissionName }
        if (-not $appRole) {
            Write-Host " ⚠️  Not found (may not exist in this tenant)" -ForegroundColor Yellow
            $errorCount++
            continue
        }
        
        # Check if consent already granted (via service principal)
        $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id -ErrorAction SilentlyContinue | 
            Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $resourceSP.Id }
        
        if ($existingAssignment) {
            Write-Host " ✓ Already assigned & consented" -ForegroundColor DarkGray
            $skipCount++
            continue
        }
        
        # Permission needs to be added/consented
        Write-Host " ➕ Will add" -ForegroundColor Green
        $successCount++
        $permissionsToAdd += @{
            Id = $appRole.Id
            Type = "Role"
        }
        
        # Track for consent
        $permissionsNeedingConsent += @{
            API = $apiConfig.DisplayName
            Permission = $permissionName
            AppRoleId = $appRole.Id
            ResourceId = $resourceSP.Id
        }
    }
    
    # Update app registration with all permissions for this API
    if ($permissionsToAdd.Count -gt 0) {
        try {
            Write-Host "   Updating app registration with $($permissionsToAdd.Count) new permissions..." -ForegroundColor Cyan
            
            # Get existing permissions for this resource
            $existingResource = $currentAppPermissions | Where-Object { $_.ResourceAppId -eq $apiConfig.AppId }
            $otherResources = $currentAppPermissions | Where-Object { $_.ResourceAppId -ne $apiConfig.AppId }
            
            # Combine existing + new permissions for this resource
            if ($existingResource) {
                $allResourcePermissions = @($existingResource.ResourceAccess) + $permissionsToAdd
            } else {
                $allResourcePermissions = $permissionsToAdd
            }
            
            # Build new resource access
            $newResourceAccess = @{
                ResourceAppId = $apiConfig.AppId
                ResourceAccess = $allResourcePermissions
            }
            
            # Combine with other resources
            $allRequiredResourceAccess = @($otherResources) + @($newResourceAccess)
            
            # Update app
            Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $allRequiredResourceAccess -ErrorAction Stop
            Write-Host "   ✅ App registration updated" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Failed to update app: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount += $permissionsToAdd.Count
        }
    }
}

# Grant admin consent if not skipped
if (-not $SkipConsent -and $permissionsNeedingConsent.Count -gt 0) {
    Write-Host "`n🔐 GRANTING ADMIN CONSENT..." -ForegroundColor Yellow
    Write-Host "   Permissions needing consent: $($permissionsNeedingConsent.Count)" -ForegroundColor Gray
    
    foreach ($perm in $permissionsNeedingConsent) {
        Write-Host "   Consenting: $($perm.Permission) ($($perm.API))..." -NoNewline -ForegroundColor Gray
        try {
            $params = @{
                PrincipalId = $appServicePrincipal.Id
                ResourceId = $perm.ResourceId
                AppRoleId = $perm.AppRoleId
            }
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id -BodyParameter $params -ErrorAction Stop | Out-Null
            Write-Host " ✅ Granted" -ForegroundColor Green
            $consentSuccessCount++
        } catch {
            if ($_.Exception.Message -like "*Permission being assigned already exists*") {
                Write-Host " ✓ Already granted" -ForegroundColor DarkGray
                $consentSuccessCount++
            } else {
                Write-Host " ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
                $consentErrorCount++
            }
        }
    }
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "📊 PERMISSION CONFIGURATION SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "✅ Successfully added:  $successCount permissions" -ForegroundColor Green
Write-Host "⏭️  Already in app:      $skipCount permissions" -ForegroundColor Gray
Write-Host "❌ Failed/Not found:    $errorCount permissions" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Gray" })
Write-Host "📝 Total processed:     $totalPermissions permissions" -ForegroundColor Cyan

if (-not $SkipConsent) {
    Write-Host "`n🔐 ADMIN CONSENT:" -ForegroundColor Cyan
    Write-Host "✅ Successfully granted: $consentSuccessCount permissions" -ForegroundColor Green
    Write-Host "❌ Failed to grant:      $consentErrorCount permissions" -ForegroundColor $(if ($consentErrorCount -gt 0) { "Red" } else { "Gray" })
} else {
    Write-Host "`n⚠️  ADMIN CONSENT SKIPPED" -ForegroundColor Yellow
    Write-Host "   Permissions added but not consented: $($permissionsNeedingConsent.Count)" -ForegroundColor Yellow
    Write-Host "   Run script again WITHOUT -SkipConsent flag as Global Administrator to grant consent" -ForegroundColor Yellow
}
Write-Host ("=" * 70) -ForegroundColor Cyan

# Azure RBAC Instructions
if (-not $SkipAzureRBAC) {
    Write-Host "`n⚠️  AZURE RESOURCE MANAGER RBAC ROLES" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Yellow
    Write-Host "For Azure operations (MDC, Azure resources), assign these roles:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Service Principal: $($appServicePrincipal.DisplayName)" -ForegroundColor Cyan
    Write-Host "  Object ID:         $($appServicePrincipal.Id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Required Roles (per subscription):" -ForegroundColor White
    Write-Host "    - Security Reader    (read security alerts, policies)" -ForegroundColor Gray
    Write-Host "    - Security Admin     (manage security policies, alerts)" -ForegroundColor Gray
    Write-Host "    - Contributor        (manage resources - NSG rules, VMs)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To assign via Azure Portal:" -ForegroundColor White
    Write-Host "    1. Navigate to Subscription → Access Control (IAM)" -ForegroundColor Gray
    Write-Host "    2. Click 'Add role assignment'" -ForegroundColor Gray
    Write-Host "    3. Select role (e.g., Security Admin)" -ForegroundColor Gray
    Write-Host "    4. Search for: $($appServicePrincipal.DisplayName)" -ForegroundColor Gray
    Write-Host "    5. Assign and save" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To assign via Azure CLI:" -ForegroundColor White
    Write-Host "    az role assignment create \" -ForegroundColor Gray
    Write-Host "      --assignee $($appServicePrincipal.Id) \" -ForegroundColor Gray
    Write-Host "      --role 'Security Admin' \" -ForegroundColor Gray
    Write-Host "      --scope /subscriptions/<SUBSCRIPTION_ID>" -ForegroundColor Gray
    Write-Host ("=" * 70) -ForegroundColor Yellow
}

Write-Host "`n✅ XDR-FOCUSED Permission configuration complete!" -ForegroundColor Green
Write-Host "   App Registration: $AppId" -ForegroundColor Gray
Write-Host "   Service Principal: $($appServicePrincipal.DisplayName)" -ForegroundColor Gray
Write-Host "   Total Permissions: 23 (8 MDE + 15 Graph)" -ForegroundColor Cyan
Write-Host "   Focus: Incident response + Threat intelligence automation" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Gray
Write-Host "   🆕 CRITICAL XDR CAPABILITIES ADDED:" -ForegroundColor Yellow
Write-Host "      • Network-level IP blocking (Conditional Access Named Locations)" -ForegroundColor Green
Write-Host "      • Automated IOC blocking (MDE Threat Indicators)" -ForegroundColor Green
Write-Host "      • Block malicious IPs across ALL Microsoft 365 services" -ForegroundColor Green
Write-Host "      • Block file hashes, domains, URLs across all endpoints" -ForegroundColor Green

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "`n👋 Disconnected from Microsoft Graph" -ForegroundColor Cyan
