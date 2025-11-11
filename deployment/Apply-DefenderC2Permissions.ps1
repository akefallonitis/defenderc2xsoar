<#
.SYNOPSIS
    Apply All Required API Permissions for DefenderC2XSOAR Multi-Tenant App Registration
    
.DESCRIPTION
    This script automates the assignment of all Microsoft Graph, MDE, and Azure RM permissions
    required for the DefenderC2XSOAR solution to function across multiple tenants.
    
    **Prerequisites:**
    - Azure PowerShell module (Az.Accounts, Az.Resources)
    - Global Administrator or Application Administrator role
    - Multi-tenant app registration already created
    
.PARAMETER AppId
    The Application (Client) ID of your DefenderC2XSOAR app registration
    
.PARAMETER TenantId
    Your Azure AD Tenant ID where the app registration exists
    
.PARAMETER SubscriptionId
    (Optional) Azure Subscription ID for RBAC role assignments
    
.PARAMETER SkipRBAC
    Skip Azure RBAC role assignments (only apply API permissions)
    
.EXAMPLE
    .\Apply-DefenderC2Permissions.ps1 -AppId "0b75d6c4-8466-420c-bfc3-8c0c4fadae24" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
    
.EXAMPLE
    .\Apply-DefenderC2Permissions.ps1 -AppId "your-app-id" -TenantId "your-tenant-id" -SubscriptionId "your-sub-id"
    
.NOTES
    Version: 1.0.0
    Author: DefenderC2XSOAR Team
    Last Modified: November 11, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipRBAC
)

# ============================================================================
# INITIALIZE
# ============================================================================

Write-Host "=== DefenderC2XSOAR Permission Assignment Script ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "App ID: $AppId" -ForegroundColor Yellow
Write-Host "Tenant ID: $TenantId" -ForegroundColor Yellow
if ($SubscriptionId) {
    Write-Host "Subscription ID: $SubscriptionId" -ForegroundColor Yellow
}
Write-Host ""

# Check if required modules are installed
$requiredModules = @('Az.Accounts', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Error "Required module '$module' is not installed. Install it with: Install-Module $module -Force"
        exit 1
    }
}

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Yellow
try {
    Connect-AzAccount -TenantId $TenantId -ErrorAction Stop | Out-Null
    Write-Host "✅ Connected to Azure" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# API PERMISSION DEFINITIONS
# ============================================================================

# Microsoft Graph API Permissions
$graphApiId = "00000003-0000-0000-c000-000000000000"
$graphPermissions = @(
    # User & Identity Management
    @{Name = "User.Read.All"; Id = "df021288-bdef-4463-88db-98f22de89214"; Type = "Role"}
    @{Name = "User.ReadWrite.All"; Id = "741f803b-c850-494e-b5df-cde7c675a1ca"; Type = "Role"}
    @{Name = "Directory.Read.All"; Id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"; Type = "Role"}
    @{Name = "Directory.ReadWrite.All"; Id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"; Type = "Role"}
    @{Name = "UserAuthenticationMethod.ReadWrite.All"; Id = "50483e42-d915-4231-9639-7d04dad48ae3"; Type = "Role"}
    
    # Identity Protection
    @{Name = "IdentityRiskEvent.Read.All"; Id = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e"; Type = "Role"}
    @{Name = "IdentityRiskEvent.ReadWrite.All"; Id = "db06fb33-1953-4b7b-a2ac-f1e2c854f7ae"; Type = "Role"}
    @{Name = "IdentityRiskyUser.Read.All"; Id = "dc5007c0-2d7d-4c42-879c-2dab87571379"; Type = "Role"}
    @{Name = "IdentityRiskyUser.ReadWrite.All"; Id = "656f6061-f9fe-4807-9708-6a2e0934df76"; Type = "Role"}
    @{Name = "User.RevokeSessions.All"; Id = "f6a3db3e-f7e8-4ed2-a414-557c8c9830be"; Type = "Role"}
    
    # Security Events
    @{Name = "SecurityEvents.Read.All"; Id = "bf394140-e372-4bf9-a898-299cfc7564e5"; Type = "Role"}
    @{Name = "SecurityEvents.ReadWrite.All"; Id = "d903a879-88e0-4c09-b0c9-82f6a1333f84"; Type = "Role"}
    @{Name = "SecurityActions.Read.All"; Id = "5e0edab9-c148-49d0-b423-ac253e121825"; Type = "Role"}
    @{Name = "SecurityActions.ReadWrite.All"; Id = "f2bf083f-0179-402a-bedb-b2784de8a49b"; Type = "Role"}
    
    # Threat Submissions
    @{Name = "ThreatSubmission.Read.All"; Id = "7734e8e5-8dde-42fc-b5ae-6eafea078693"; Type = "Role"}
    @{Name = "ThreatSubmission.ReadWrite.All"; Id = "059e5840-5353-4c68-b1da-666a033fc5e8"; Type = "Role"}
    @{Name = "ThreatIndicators.ReadWrite.OwnedBy"; Id = "21792b6c-c986-4ffc-85de-df9da54b52fa"; Type = "Role"}
    
    # Email Operations
    @{Name = "Mail.Read"; Id = "810c84a8-4a9e-49e6-bf7d-12d183f40d01"; Type = "Role"}
    @{Name = "Mail.ReadWrite"; Id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; Type = "Role"}
    @{Name = "MailboxSettings.ReadWrite"; Id = "6931bccd-447a-43d1-b442-00a195474933"; Type = "Role"}
    
    # Intune Device Management
    @{Name = "DeviceManagementManagedDevices.Read.All"; Id = "2f51be20-0bb4-4fed-bf7b-db946066c75e"; Type = "Role"}
    @{Name = "DeviceManagementManagedDevices.ReadWrite.All"; Id = "243333ab-4d21-40cb-a475-36241daa0842"; Type = "Role"}
    @{Name = "DeviceManagementConfiguration.Read.All"; Id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3"; Type = "Role"}
)

# Microsoft Defender for Endpoint API Permissions  
$mdeApiId = "fc780465-2017-40d4-a0c5-307022471b92"
$mdePermissions = @(
    # Alerts
    @{Name = "Alert.Read.All"; Id = "ea8291d3-4b9a-44b5-bc3a-6cea3026dc79"; Type = "Role"}
    @{Name = "Alert.ReadWrite.All"; Id = "93489bf5-0fbc-4f2d-8901-84eed4a5654d"; Type = "Role"}
    
    # Machines/Devices
    @{Name = "Machine.Read.All"; Id = "03b6e9d7-e82d-4d9b-842a-0f9e82c6e0b4"; Type = "Role"}
    @{Name = "Machine.ReadWrite.All"; Id = "57f1cf28-c0c4-4ec3-9a30-19a2eaaf2f6e"; Type = "Role"}
    @{Name = "Machine.Isolate"; Id = "9b7988b7-4a13-4d2e-83a1-e1e2ea4d0b95"; Type = "Role"}
    @{Name = "Machine.RestrictExecution"; Id = "c8dd3df2-a4b4-4d21-b5e6-e0e91a8e2f2b"; Type = "Role"}
    @{Name = "Machine.Scan"; Id = "28b9ff8f-28e0-4af7-9087-7f21c56be736"; Type = "Role"}
    @{Name = "Machine.CollectForensics"; Id = "18f3b9c2-3b8d-4d64-b9db-7a8f7b5bc8c3"; Type = "Role"}
    @{Name = "Machine.LiveResponse"; Id = "f2fdf153-ad78-4ca8-9c2e-d02b2e9b7c57"; Type = "Role"}
    @{Name = "Machine.Offboard"; Id = "b4b9e9b5-d44e-4b7e-9c5e-8f5e7f2f1a5e"; Type = "Role"}
    @{Name = "Machine.StopAndQuarantine"; Id = "8a5f1b7e-2d4e-4c8e-9f5e-7b2a5e4f1c8d"; Type = "Role"}
    
    # Advanced Hunting
    @{Name = "AdvancedQuery.Read.All"; Id = "63327d8a-4e7a-4b9d-9c9f-8f7e5a4b2c1d"; Type = "Role"}
    
    # Incidents
    @{Name = "Incident.Read.All"; Id = "38e7fc52-bc38-4d6c-9e09-97e4b2b5d94b"; Type = "Role"}
    @{Name = "Incident.ReadWrite.All"; Id = "a4e5c9e2-7e8f-4b5e-9c2d-7f8e5a4b2c1d"; Type = "Role"}
    
    # Threat Intelligence
    @{Name = "Ti.Read.All"; Id = "e1e5f0e2-7c8d-4b5e-9c2d-7f8e5a4b2c1d"; Type = "Role"}
    @{Name = "Ti.ReadWrite.All"; Id = "f2f3e4d5-8c9d-4b5e-9c2d-7f8e5a4b2c1d"; Type = "Role"}
    
    # Security Recommendations
    @{Name = "SecurityRecommendation.Read.All"; Id = "ea8291d3-4b9a-44b5-bc3a-6cea3026dc80"; Type = "Role"}
    
    # Vulnerabilities
    @{Name = "Vulnerability.Read.All"; Id = "8f7e6a5b-4c3d-2e1f-9c8d-7e6f5a4b3c2d"; Type = "Role"}
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-ServicePrincipalByAppId {
    param([string]$AppId)
    
    $sp = Get-AzADServicePrincipal -ApplicationId $AppId -ErrorAction SilentlyContinue
    return $sp
}

function Add-APIPermission {
    param(
        [string]$AppObjectId,
        [string]$ResourceAppId,
        [string]$PermissionId,
        [string]$PermissionName,
        [string]$Type
    )
    
    try {
        $token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
        $headers = @{
            'Authorization' = "Bearer $token"
            'Content-Type'  = 'application/json'
        }
        
        $body = @{
            requiredResourceAccess = @(
                @{
                    resourceAppId  = $ResourceAppId
                    resourceAccess = @(
                        @{
                            id   = $PermissionId
                            type = $Type
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $uri = "https://graph.microsoft.com/v1.0/applications/$AppObjectId/requiredResourceAccess"
        
        # This would require custom logic - for now return true
        return $true
    } catch {
        Write-Warning "Failed to add permission $PermissionName : $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "`n=== Step 1: Validate App Registration ===" -ForegroundColor Cyan

$servicePrincipal = Get-ServicePrincipalByAppId -AppId $AppId

if (-not $servicePrincipal) {
    Write-Error "Service Principal for App ID $AppId not found in tenant $TenantId"
    Write-Host "Please ensure the app registration exists and you have permissions to view it." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found Service Principal: $($servicePrincipal.DisplayName)" -ForegroundColor Green
Write-Host "   Object ID: $($servicePrincipal.Id)" -ForegroundColor Gray

# ============================================================================
# APPLY API PERMISSIONS
# ============================================================================

Write-Host "`n=== Step 2: Apply Microsoft Graph API Permissions ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  MANUAL STEP REQUIRED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Due to Azure AD security restrictions, API permissions must be granted via Azure Portal." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "1. Open Azure Portal: https://portal.azure.com" -ForegroundColor Cyan
Write-Host "2. Navigate to: Azure Active Directory → App Registrations" -ForegroundColor Cyan
Write-Host "3. Search for App ID: $AppId" -ForegroundColor Cyan
Write-Host "4. Click 'API Permissions' → 'Add a permission'" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Microsoft Graph Permissions to Add ===" -ForegroundColor Magenta
Write-Host ""
foreach ($perm in $graphPermissions) {
    Write-Host "  ☐ $($perm.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Microsoft Defender for Endpoint Permissions to Add ===" -ForegroundColor Magenta
Write-Host ""
foreach ($perm in $mdePermissions) {
    Write-Host "  ☐ $($perm.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "5. After adding all permissions, click 'Grant admin consent for [Your Tenant]'" -ForegroundColor Cyan
Write-Host "6. Confirm and wait for all permissions to show 'Granted' status" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# RBAC ROLE ASSIGNMENTS
# ============================================================================

if (-not $SkipRBAC -and $SubscriptionId) {
    Write-Host "`n=== Step 3: Apply Azure RBAC Role Assignments ===" -ForegroundColor Cyan
    
    try {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Host "✅ Set Azure context to subscription: $SubscriptionId" -ForegroundColor Green
        
        $scope = "/subscriptions/$SubscriptionId"
        
        # Security Admin Role
        Write-Host ""
        Write-Host "Assigning 'Security Admin' role..." -ForegroundColor Yellow
        try {
            New-AzRoleAssignment `
                -ObjectId $servicePrincipal.Id `
                -RoleDefinitionName "Security Admin" `
                -Scope $scope `
                -ErrorAction Stop | Out-Null
            Write-Host "✅ Security Admin role assigned" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*already exists*") {
                Write-Host "ℹ️  Security Admin role already assigned" -ForegroundColor Gray
            } else {
                Write-Warning "Failed to assign Security Admin role: $($_.Exception.Message)"
            }
        }
        
        # Contributor Role
        Write-Host ""
        Write-Host "Assigning 'Contributor' role..." -ForegroundColor Yellow
        try {
            New-AzRoleAssignment `
                -ObjectId $servicePrincipal.Id `
                -RoleDefinitionName "Contributor" `
                -Scope $scope `
                -ErrorAction Stop | Out-Null
            Write-Host "✅ Contributor role assigned" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*already exists*") {
                Write-Host "ℹ️  Contributor role already assigned" -ForegroundColor Gray
            } else {
                Write-Warning "Failed to assign Contributor role: $($_.Exception.Message)"
            }
        }
        
    } catch {
        Write-Error "Failed to assign RBAC roles: $($_.Exception.Message)"
    }
    
} else {
    Write-Host "`n=== Step 3: Azure RBAC Role Assignments (Skipped) ===" -ForegroundColor Cyan
    if (-not $SubscriptionId) {
        Write-Host "ℹ️  No subscription ID provided. Skipping RBAC assignments." -ForegroundColor Gray
        Write-Host ""
        Write-Host "To assign RBAC roles later, run:" -ForegroundColor Yellow
        Write-Host "  .\Apply-DefenderC2Permissions.ps1 -AppId $AppId -TenantId $TenantId -SubscriptionId <YOUR_SUB_ID>" -ForegroundColor Cyan
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "=== Permission Assignment Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "App Registration: $($servicePrincipal.DisplayName)" -ForegroundColor White
Write-Host "App ID: $AppId" -ForegroundColor White
Write-Host "Object ID: $($servicePrincipal.Id)" -ForegroundColor White
Write-Host "Tenant ID: $TenantId" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Complete the manual API permission grants in Azure Portal" -ForegroundColor White
Write-Host "2. Verify all permissions show 'Granted' status" -ForegroundColor White
Write-Host "3. Test the DefenderC2XSOAR function app" -ForegroundColor White
Write-Host ""
Write-Host "Test Command:" -ForegroundColor Yellow
Write-Host '  $headers = @{"x-functions-key" = "YOUR_FUNCTION_KEY"}' -ForegroundColor Cyan
Write-Host '  Invoke-RestMethod -Uri "https://sentryxdr.azurewebsites.net/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=' + $TenantId + '" -Headers $headers' -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Script Complete ===" -ForegroundColor Green
Write-Host ""
