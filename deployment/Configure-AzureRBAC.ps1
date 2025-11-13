<#
.SYNOPSIS
    Configure Azure RBAC for DefenderXDR C2 Multi-Tenant Operations
    
.DESCRIPTION
    Automates Azure RBAC role assignment for DefenderXDR C2 App Registration.
    Assigns Virtual Machine Contributor + Network Contributor roles to enable
    Azure infrastructure remediation actions (StopVM, AddNSGDenyRule, etc.)
    
    Supports:
    - Subscription-level scope (manage all resources)
    - Resource group-level scope (restricted to specific RG)
    - Idempotent execution (safe to run multiple times)
    - Validation and verification
    
.PARAMETER AppId
    DefenderXDR C2 Application (Client) ID from App Registration
    Default: 0b75d6c4-846e-420c-bf53-8c0c4fadae24
    
.PARAMETER SubscriptionId
    Customer Azure subscription ID to grant access to
    
.PARAMETER ResourceGroup
    Optional: Resource group name to scope permissions (more restrictive)
    If omitted, permissions granted at subscription level
    
.PARAMETER Scope
    Scope level: "Subscription" (default) or "ResourceGroup"
    
.PARAMETER AdditionalRoles
    Optional: Array of additional Azure roles to assign
    Example: @("Storage Account Contributor", "Key Vault Contributor")
    
.PARAMETER Verify
    Switch to verify role assignments after configuration
    
.EXAMPLE
    # Subscription-level access (all resource groups)
    .\Configure-AzureRBAC.ps1 `
        -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
        -SubscriptionId "12345678-1234-1234-1234-123456789012" `
        -Verify
    
.EXAMPLE
    # Resource group-level access (production RG only)
    .\Configure-AzureRBAC.ps1 `
        -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
        -SubscriptionId "12345678-1234-1234-1234-123456789012" `
        -ResourceGroup "production-rg" `
        -Scope "ResourceGroup" `
        -Verify
    
.EXAMPLE
    # Include storage account access
    .\Configure-AzureRBAC.ps1 `
        -AppId "0b75d6c4-846e-420c-bf53-8c0c4fadae24" `
        -SubscriptionId "12345678-1234-1234-1234-123456789012" `
        -AdditionalRoles @("Storage Account Contributor")
    
.NOTES
    Author: DefenderXDR C2 Team
    Version: 3.0.0
    Date: 2025-11-13
    
    Requirements:
    - Azure CLI installed (az command available)
    - Authenticated to Azure (az login)
    - Permissions to assign roles in target subscription
      (User Access Administrator or Owner role required)
    
    Azure Worker Actions Enabled:
    - StopVM, StartVM, RestartVM (Virtual Machine Contributor)
    - AddNSGDenyRule, RemoveVMPublicIP (Network Contributor)
    - GetVMs, GetResourceGroups, GetNSGs (both roles)
    
    See: AZURE_MULTITENANT_ARCHITECTURE.md for complete setup guide
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$AppId = "0b75d6c4-846e-420c-bf53-8c0c4fadae24",
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Subscription", "ResourceGroup")]
    [string]$Scope = "Subscription",
    
    [Parameter(Mandatory=$false)]
    [string[]]$AdditionalRoles = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$Verify
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-AzureCLI {
    <#
    .SYNOPSIS
        Verifies Azure CLI is installed and user is authenticated
    #>
    try {
        $null = az --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Azure CLI not found"
        }
        
        $account = az account show 2>$null | ConvertFrom-Json
        if (-not $account) {
            throw "Not authenticated to Azure"
        }
        
        return $true
    } catch {
        return $false
    }
}

function Get-ServicePrincipal {
    <#
    .SYNOPSIS
        Retrieves service principal for App Registration
    #>
    param([string]$AppId)
    
    try {
        $sp = az ad sp show --id $AppId 2>$null | ConvertFrom-Json
        return $sp
    } catch {
        return $null
    }
}

function Test-RoleAssignment {
    <#
    .SYNOPSIS
        Checks if role assignment already exists
    #>
    param(
        [string]$AppId,
        [string]$Role,
        [string]$ScopePath
    )
    
    $existing = az role assignment list `
        --assignee $AppId `
        --role $Role `
        --scope $ScopePath `
        --query "[].roleDefinitionName" `
        -o tsv 2>$null
    
    return ($existing -eq $Role)
}

function New-RoleAssignment {
    <#
    .SYNOPSIS
        Creates Azure RBAC role assignment
    #>
    param(
        [string]$AppId,
        [string]$Role,
        [string]$ScopePath
    )
    
    try {
        $result = az role assignment create `
            --assignee $AppId `
            --role $Role `
            --scope $ScopePath `
            --description "DefenderXDR C2 v3.0.0 - Azure remediation actions" `
            2>&1
        
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Status "`n╔═══════════════════════════════════════════════════════════════╗" -Color Cyan
Write-Status "║  Configure Azure RBAC - DefenderXDR C2 Multi-Tenant         ║" -Color Cyan
Write-Status "╚═══════════════════════════════════════════════════════════════╝" -Color Cyan

# Step 1: Verify Azure CLI
Write-Status "`n[1/5] Verifying Azure CLI..." -Color Yellow

if (-not (Test-AzureCLI)) {
    Write-Status "  ✗ Azure CLI not found or not authenticated" -Color Red
    Write-Status "`nPlease install Azure CLI: https://aka.ms/azure-cli" -Color Yellow
    Write-Status "Then run: az login" -Color Yellow
    exit 1
}

$currentAccount = az account show | ConvertFrom-Json
Write-Status "  ✓ Azure CLI ready" -Color Green
Write-Status "    Authenticated as: $($currentAccount.user.name)" -Color Gray
Write-Status "    Current subscription: $($currentAccount.name)" -Color Gray

# Step 2: Validate inputs
Write-Status "`n[2/5] Validating configuration..." -Color Yellow

# Set context to target subscription
Write-Status "  Setting context to target subscription..." -Color Gray
az account set --subscription $SubscriptionId 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Status "  ✗ Failed to access subscription: $SubscriptionId" -Color Red
    Write-Status "    Ensure you have access to this subscription" -Color Yellow
    exit 1
}

$subscription = az account show | ConvertFrom-Json
Write-Status "  ✓ Subscription accessible: $($subscription.name)" -Color Green

# Determine scope path
if ($Scope -eq "ResourceGroup") {
    if ([string]::IsNullOrEmpty($ResourceGroup)) {
        Write-Status "  ✗ ResourceGroup parameter required when Scope=ResourceGroup" -Color Red
        exit 1
    }
    
    # Verify resource group exists
    $rg = az group show --name $ResourceGroup 2>$null | ConvertFrom-Json
    if (-not $rg) {
        Write-Status "  ✗ Resource group not found: $ResourceGroup" -Color Red
        exit 1
    }
    
    $scopePath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"
    $scopeDisplay = "Resource Group: $ResourceGroup"
} else {
    $scopePath = "/subscriptions/$SubscriptionId"
    $scopeDisplay = "Subscription: $($subscription.name)"
}

Write-Status "  ✓ Scope: $scopeDisplay" -Color Green
Write-Status "  ✓ Scope path: $scopePath" -Color Gray

# Step 3: Verify service principal exists
Write-Status "`n[3/5] Verifying App Registration..." -Color Yellow

$sp = Get-ServicePrincipal -AppId $AppId
if (-not $sp) {
    Write-Status "  ✗ Service principal not found for App ID: $AppId" -Color Red
    Write-Status "`nPossible causes:" -Color Yellow
    Write-Status "  1. App Registration doesn't exist" -Color Gray
    Write-Status "  2. Admin consent not granted in this tenant" -Color Gray
    Write-Status "  3. Incorrect App ID" -Color Gray
    Write-Status "`nRun admin consent first:" -Color Yellow
    Write-Status "  https://login.microsoftonline.com/$($subscription.tenantId)/adminconsent?client_id=$AppId" -Color Cyan
    exit 1
}

Write-Status "  ✓ Service Principal found" -Color Green
Write-Status "    App ID: $AppId" -Color Gray
Write-Status "    Display Name: $($sp.displayName)" -Color Gray
Write-Status "    Object ID: $($sp.id)" -Color Gray

# Step 4: Assign RBAC roles
Write-Status "`n[4/5] Assigning RBAC roles..." -Color Yellow

# Define required roles for DefenderXDR C2 Azure Worker
$requiredRoles = @(
    @{
        Name = "Virtual Machine Contributor"
        Description = "Required for StopVM, StartVM, RestartVM, RemoveVMPublicIP actions"
    },
    @{
        Name = "Network Contributor"
        Description = "Required for AddNSGDenyRule, network isolation actions"
    }
)

# Add any additional roles
foreach ($role in $AdditionalRoles) {
    $requiredRoles += @{
        Name = $role
        Description = "Additional role (user-specified)"
    }
}

$successCount = 0
$skippedCount = 0
$failedCount = 0

foreach ($roleInfo in $requiredRoles) {
    $roleName = $roleInfo.Name
    $roleDesc = $roleInfo.Description
    
    Write-Status "`n  Processing role: $roleName" -Color Cyan
    Write-Status "    Purpose: $roleDesc" -Color Gray
    
    # Check if already assigned
    if (Test-RoleAssignment -AppId $AppId -Role $roleName -ScopePath $scopePath) {
        Write-Status "    ✓ Already assigned" -Color Green
        $skippedCount++
        continue
    }
    
    # Assign role
    Write-Status "    Assigning role..." -Color Gray
    if (New-RoleAssignment -AppId $AppId -Role $roleName -ScopePath $scopePath) {
        Write-Status "    ✓ Assigned successfully" -Color Green
        $successCount++
    } else {
        Write-Status "    ✗ Assignment failed" -Color Red
        Write-Status "      Possible causes:" -Color Yellow
        Write-Status "        - Insufficient permissions (need User Access Administrator or Owner)" -Color Gray
        Write-Status "        - Role definition not found" -Color Gray
        Write-Status "        - Scope path incorrect" -Color Gray
        $failedCount++
    }
}

# Step 5: Verification (optional)
if ($Verify) {
    Write-Status "`n[5/5] Verifying role assignments..." -Color Yellow
    
    $allAssignments = az role assignment list `
        --assignee $AppId `
        --scope $scopePath `
        --query "[].{Role:roleDefinitionName, Scope:scope}" `
        -o json | ConvertFrom-Json
    
    if ($allAssignments -and $allAssignments.Count -gt 0) {
        Write-Status "  ✓ Found $($allAssignments.Count) role assignment(s)" -Color Green
        foreach ($assignment in $allAssignments) {
            Write-Status "    - $($assignment.Role)" -Color Gray
        }
    } else {
        Write-Status "  ⚠ No role assignments found (may take a few seconds to propagate)" -Color Yellow
    }
} else {
    Write-Status "`n[5/5] Skipping verification (use -Verify to enable)" -Color Gray
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Status "`n╔═══════════════════════════════════════════════════════════════╗" -Color Green
Write-Status "║  Azure RBAC Configuration Complete                           ║" -Color Green
Write-Status "╚═══════════════════════════════════════════════════════════════╝" -Color Green

Write-Status "`n📊 Summary:" -Color Cyan
Write-Status "   Subscription: $($subscription.name)" -Color White
Write-Status "   Scope: $scopeDisplay" -Color White
Write-Status "   App ID: $AppId" -Color White
Write-Status "`n   Results:" -Color White
Write-Status "     ✓ Assigned: $successCount role(s)" -Color Green
Write-Status "     ⊙ Already assigned: $skippedCount role(s)" -Color Gray
if ($failedCount -gt 0) {
    Write-Status "     ✗ Failed: $failedCount role(s)" -Color Red
}

if ($failedCount -gt 0) {
    Write-Status "`n⚠️  Some role assignments failed!" -Color Red
    Write-Status "   Check error messages above for details." -Color Yellow
    Write-Status "   Ensure you have User Access Administrator or Owner role in the subscription." -Color Yellow
    exit 1
}

Write-Status "`n✅ DefenderXDR C2 can now perform Azure operations in this scope" -Color Green

Write-Status "`n📋 Next Steps:" -Color Cyan
Write-Status "   1. Test Azure operations:" -Color White
Write-Status "      POST /api/Gateway" -Color Gray
Write-Status "      {" -Color Gray
Write-Status "        `"tenantId`": `"$($subscription.tenantId)`"," -Color Gray
Write-Status "        `"service`": `"Azure`"," -Color Gray
Write-Status "        `"action`": `"GetResourceGroups`"," -Color Gray
Write-Status "        `"subscriptionId`": `"$SubscriptionId`"" -Color Gray
Write-Status "      }" -Color Gray
Write-Status "`n   2. Verify in Azure Portal:" -Color White
Write-Status "      Subscription → Access control (IAM) → Role assignments" -Color Gray
Write-Status "      Search for: $($sp.displayName)" -Color Gray
Write-Status "`n   3. Document subscription ID in XSOAR playbooks" -Color White

Write-Status "`n💡 Tips:" -Color Cyan
Write-Status "   • Resource group scope: More restrictive, better security" -Color Gray
Write-Status "   • Subscription scope: Manage all resource groups" -Color Gray
Write-Status "   • Custom roles: Create for absolute least privilege" -Color Gray
Write-Status "   • Azure Lighthouse: Consider for managing 100+ customers" -Color Gray

Write-Status "`n📚 Documentation:" -Color Cyan
Write-Status "   AZURE_MULTITENANT_ARCHITECTURE.md - Complete setup guide" -Color Gray
Write-Status "   AZURE_AUTHENTICATION_ANALYSIS.md - Architecture details" -Color Gray

Write-Status "`n✅ Configuration script completed successfully" -Color Green
