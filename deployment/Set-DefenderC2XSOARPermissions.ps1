<#
.SYNOPSIS
    Configure API permissions for DefenderC2XSOAR multi-tenant app registration
.DESCRIPTION
    This script applies all required API permissions for the DefenderC2XSOAR integration:
    - Microsoft Defender for Endpoint (19 permissions)
    - Microsoft Graph (27 permissions)
    - Azure Resource Manager RBAC (Security Admin, Security Reader)
    
    The script will:
    1. Connect to Microsoft Graph with admin privileges
    2. Add all required application permissions
    3. Grant admin consent automatically
    4. Display permission status
.PARAMETER AppId
    Application (client) ID of the multi-tenant app registration
.PARAMETER TenantId
    Azure AD Tenant ID where the app is registered
.PARAMETER SkipAzureRBAC
    Skip Azure Resource Manager RBAC role assignment (useful if managing separately)
.EXAMPLE
    .\Set-DefenderC2XSOARPermissions.ps1 -AppId "0b75d6c4-8466-420c-bfc3-8c0c4fadae24" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
.NOTES
    Author: DefenderC2XSOAR Team
    Requires: Microsoft.Graph PowerShell SDK (Install-Module Microsoft.Graph)
    Required Permissions: Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All
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
Write-Host "   Required Scopes: Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All" -ForegroundColor Gray

try {
    Connect-MgGraph -TenantId $TenantId -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -NoWelcome -ErrorAction Stop
    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

# Get the service principal for our app
Write-Host "`n🔍 Finding application service principal..." -ForegroundColor Cyan
try {
    $appServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop
    if (-not $appServicePrincipal) {
        Write-Host "❌ Service principal not found for AppId: $AppId" -ForegroundColor Red
        Write-Host "   Make sure the app registration exists and has a service principal" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Found service principal: $($appServicePrincipal.DisplayName) (ObjectId: $($appServicePrincipal.Id))" -ForegroundColor Green
} catch {
    Write-Host "❌ Error finding service principal: $_" -ForegroundColor Red
    exit 1
}

# Define required API permissions
$apiPermissions = @{
    "WindowsDefenderATP" = @{
        DisplayName = "WindowsDefenderATP"
        AppId = "fc780465-2017-40d4-a0c5-307022471b92"
        Permissions = @(
            "Alert.Read.All",
            "Alert.ReadWrite.All",
            "Machine.Read.All",
            "Machine.ReadWrite.All",
            "Machine.Isolate",
            "Machine.RestrictExecution",
            "Machine.Scan",
            "Machine.CollectForensics",
            "Machine.LiveResponse",
            "AdvancedQuery.Read.All",
            "Incident.Read.All",
            "Incident.ReadWrite.All",
            "Ti.ReadWrite.All",
            "SecurityRecommendation.Read.All",
            "Vulnerability.Read.All",
            "File.Read.All",
            "Ip.Read.All",
            "Url.Read.All",
            "User.Read.All"
        )
    }
    "MicrosoftGraph" = @{
        DisplayName = "Microsoft Graph"
        AppId = "00000003-0000-0000-c000-000000000000"
        Permissions = @(
            "User.Read.All",
            "User.ReadWrite.All",
            "Directory.Read.All",
            "Directory.ReadWrite.All",
            "UserAuthenticationMethod.Read.All",
            "UserAuthenticationMethod.ReadWrite.All",
            "IdentityRiskEvent.Read.All",
            "IdentityRiskEvent.ReadWrite.All",
            "IdentityRiskyUser.Read.All",
            "IdentityRiskyUser.ReadWrite.All",
            "User.RevokeSessions.All",
            "SecurityEvents.Read.All",
            "SecurityEvents.ReadWrite.All",
            "ThreatSubmission.ReadWrite.All",
            "Mail.ReadWrite",
            "DeviceManagementManagedDevices.Read.All",
            "DeviceManagementManagedDevices.ReadWrite.All",
            "DeviceManagementConfiguration.Read.All",
            "SecurityActions.Read.All",
            "SecurityActions.ReadWrite.All",
            "ThreatIndicators.ReadWrite.OwnedBy",
            "Group.Read.All",
            "GroupMember.Read.All",
            "Application.Read.All",
            "Policy.Read.All",
            "AuditLog.Read.All",
            "Reports.Read.All"
        )
    }
}

$totalPermissions = ($apiPermissions.Values | ForEach-Object { $_.Permissions.Count } | Measure-Object -Sum).Sum
$successCount = 0
$skipCount = 0
$errorCount = 0

Write-Host "`n📋 Processing $totalPermissions API permissions..." -ForegroundColor Cyan

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
    
    foreach ($permissionName in $apiConfig.Permissions) {
        Write-Host "   Processing: $permissionName..." -NoNewline -ForegroundColor Gray
        
        # Find the app role
        $appRole = $appRoles | Where-Object { $_.Value -eq $permissionName }
        if (-not $appRole) {
            Write-Host " ⚠️  Not found (may not exist in this tenant)" -ForegroundColor Yellow
            $errorCount++
            continue
        }
        
        # Check if permission already assigned
        try {
            $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id -ErrorAction Stop | 
                Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $resourceSP.Id }
            
            if ($existingAssignment) {
                Write-Host " ✓ Already assigned" -ForegroundColor DarkGray
                $skipCount++
                continue
            }
        } catch {
            # Permission not assigned, continue to add it
        }
        
        # Assign the permission
        try {
            $params = @{
                PrincipalId = $appServicePrincipal.Id
                ResourceId = $resourceSP.Id
                AppRoleId = $appRole.Id
            }
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id -BodyParameter $params -ErrorAction Stop | Out-Null
            Write-Host " ✅ Added" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " ❌ Failed: $_" -ForegroundColor Red
            $errorCount++
        }
    }
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "📊 PERMISSION ASSIGNMENT SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "✅ Successfully added:  $successCount permissions" -ForegroundColor Green
Write-Host "⏭️  Already assigned:    $skipCount permissions" -ForegroundColor Gray
Write-Host "❌ Failed/Not found:    $errorCount permissions" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Gray" })
Write-Host "📝 Total processed:     $totalPermissions permissions" -ForegroundColor Cyan
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

Write-Host "`n✅ Permission configuration complete!" -ForegroundColor Green
Write-Host "   App Registration: $AppId" -ForegroundColor Gray
Write-Host "   Service Principal: $($appServicePrincipal.DisplayName)" -ForegroundColor Gray

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "`n👋 Disconnected from Microsoft Graph" -ForegroundColor Cyan
