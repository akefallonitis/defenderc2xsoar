<#
.SYNOPSIS
    Comprehensive multi-service test for DefenderC2XSOAR
.DESCRIPTION
    Tests all 7 services with proper parameters for multi-tenant environments
.PARAMETER TenantId
    Azure AD Tenant ID
.PARAMETER FunctionKey
    Function App host key
.PARAMETER SubscriptionId
    Azure Subscription ID (for MDC and Azure services)
.PARAMETER UserId
    User ID for EntraID tests (optional)
.EXAMPLE
    .\test-all-services-complete.ps1 -TenantId "xxx" -FunctionKey "xxx" -SubscriptionId "xxx"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionKey,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$UserId,
    
    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "https://sentryxdr.azurewebsites.net/api/Gateway"
)

$ErrorActionPreference = "Continue"

# Test results
$results = @()
$totalTests = 0
$passedTests = 0

function Invoke-ServiceTest {
    param(
        [string]$Service,
        [string]$Action,
        [hashtable]$Parameters,
        [string]$Description
    )
    
    $script:totalTests++
    Write-Host "`n[$script:totalTests] Testing: $Service - $Action" -ForegroundColor Cyan
    Write-Host "    Description: $Description" -ForegroundColor Gray
    
    try {
        # Build request body
        $body = @{
            service = $Service
            action = $Action
            tenantId = $TenantId
        }
        
        # Add additional parameters
        foreach ($key in $Parameters.Keys) {
            $body[$key] = $Parameters[$key]
        }
        
        $bodyJson = $body | ConvertTo-Json -Depth 10
        Write-Host "    Request: $bodyJson" -ForegroundColor DarkGray
        
        # Make request
        $url = "$BaseUrl`?code=$FunctionKey"
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $bodyJson -ContentType "application/json" -ErrorAction Stop
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        # Check response
        if ($response.status -eq "success") {
            $script:passedTests++
            Write-Host "    ✅ PASS" -ForegroundColor Green
            Write-Host "    Duration: $($duration)s" -ForegroundColor Gray
            
            # Show data summary
            if ($response.data) {
                if ($response.data.count) {
                    Write-Host "    Data: $($response.data.count) items returned" -ForegroundColor Gray
                } elseif ($response.data.message) {
                    Write-Host "    Message: $($response.data.message)" -ForegroundColor Gray
                }
            }
            
            $script:results += @{
                Service = $Service
                Action = $Action
                Description = $Description
                Status = "✅ PASS"
                Duration = [Math]::Round($duration, 2)
                Message = "Success"
            }
            return $true
        } else {
            Write-Host "    ❌ FAIL: $($response.message)" -ForegroundColor Red
            $script:results += @{
                Service = $Service
                Action = $Action
                Description = $Description
                Status = "❌ FAIL"
                Duration = [Math]::Round($duration, 2)
                Message = $response.message
            }
            return $false
        }
    }
    catch {
        Write-Host "    ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:results += @{
            Service = $Service
            Action = $Action
            Description = $Description
            Status = "❌ FAIL"
            Duration = 0
            Message = $_.Exception.Message
        }
        return $false
    }
}

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "DefenderC2XSOAR - COMPREHENSIVE MULTI-SERVICE TEST SUITE" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Tenant ID:        $TenantId" -ForegroundColor Gray
Write-Host "Subscription ID:  $SubscriptionId" -ForegroundColor Gray
Write-Host "Base URL:         $BaseUrl" -ForegroundColor Gray
Write-Host "=====================================================================" -ForegroundColor Cyan

# ====================================================================
# SERVICE 1: MDE (Microsoft Defender for Endpoint)
# ====================================================================

Write-Host "`n🛡️  SERVICE 1: MICROSOFT DEFENDER FOR ENDPOINT (MDE)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

Invoke-ServiceTest -Service "MDE" -Action "GetAllDevices" -Parameters @{} `
    -Description "List all MDE-enrolled devices"

Invoke-ServiceTest -Service "MDE" -Action "GetIncidents" -Parameters @{} `
    -Description "List security incidents from Defender XDR"

Invoke-ServiceTest -Service "MDE" -Action "AdvancedHunt" -Parameters @{
    query = "DeviceInfo | take 5"
} -Description "Run KQL advanced hunting query"

Invoke-ServiceTest -Service "MDE" -Action "GetAllIndicators" -Parameters @{} `
    -Description "List threat indicators"

# ====================================================================
# SERVICE 2: MDO (Microsoft Defender for Office 365)
# ====================================================================

Write-Host "`n📧 SERVICE 2: MICROSOFT DEFENDER FOR OFFICE 365 (MDO)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow
Write-Host "⚠️  Note: MDO only has write operations (email remediation)" -ForegroundColor Yellow
Write-Host "    Skipping MDO tests (requires email ID for remediation)" -ForegroundColor Gray

# MDO tests skipped - only write operations available

# ====================================================================
# SERVICE 3: MDC (Microsoft Defender for Cloud)
# ====================================================================

Write-Host "`n☁️  SERVICE 3: MICROSOFT DEFENDER FOR CLOUD (MDC)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

Invoke-ServiceTest -Service "MDC" -Action "GetSecurityAlerts" -Parameters @{
    subscriptionId = $SubscriptionId
} -Description "List cloud security alerts"

Invoke-ServiceTest -Service "MDC" -Action "GetRecommendations" -Parameters @{
    subscriptionId = $SubscriptionId
} -Description "Get security recommendations"

Invoke-ServiceTest -Service "MDC" -Action "GetSecureScore" -Parameters @{
    subscriptionId = $SubscriptionId
} -Description "Get secure score"

Invoke-ServiceTest -Service "MDC" -Action "GetDefenderPlans" -Parameters @{
    subscriptionId = $SubscriptionId
} -Description "List enabled Defender plans"

# ====================================================================
# SERVICE 4: MDI (Microsoft Defender for Identity)
# ====================================================================

Write-Host "`n🔐 SERVICE 4: MICROSOFT DEFENDER FOR IDENTITY (MDI)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

Invoke-ServiceTest -Service "MDI" -Action "GetAlerts" -Parameters @{} `
    -Description "List MDI security alerts"

# ====================================================================
# SERVICE 5: EntraID (Azure AD Identity)
# ====================================================================

Write-Host "`n👤 SERVICE 5: ENTRA ID (AZURE AD IDENTITY)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

# Test actions that don't require userId
Invoke-ServiceTest -Service "EntraID" -Action "GetRiskyUsers" -Parameters @{} `
    -Description "List users flagged as risky"

Invoke-ServiceTest -Service "EntraID" -Action "GetConditionalAccessPolicies" -Parameters @{} `
    -Description "List conditional access policies"

if ($UserId) {
    Invoke-ServiceTest -Service "EntraID" -Action "GetRiskDetections" -Parameters @{
        userId = $UserId
    } -Description "Get risk detections for specific user"
} else {
    Write-Host "    ⏭️  Skipping GetRiskDetections (no userId provided)" -ForegroundColor Gray
}

# ====================================================================
# SERVICE 6: Intune (Device Management)
# ====================================================================

Write-Host "`n📱 SERVICE 6: INTUNE (DEVICE MANAGEMENT)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

Invoke-ServiceTest -Service "Intune" -Action "GetManagedDevices" -Parameters @{} `
    -Description "List Intune-managed devices"

Invoke-ServiceTest -Service "Intune" -Action "GetDeviceComplianceStatus" -Parameters @{} `
    -Description "Get device compliance status"

# ====================================================================
# SERVICE 7: Azure (Infrastructure Security)
# ====================================================================

Write-Host "`n🏗️  SERVICE 7: AZURE (INFRASTRUCTURE SECURITY)" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

Invoke-ServiceTest -Service "Azure" -Action "GetResourceGroups" -Parameters @{
    subscriptionId = $SubscriptionId
} -Description "List resource groups"

# Note: GetVirtualMachines requires resourceGroup parameter
# Skipping for now as we don't know valid resource group names

# ====================================================================
# SUMMARY
# ====================================================================

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$passRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests:  $totalTests" -ForegroundColor White
Write-Host "✅ Passed:    $passedTests" -ForegroundColor Green
Write-Host "❌ Failed:    $($totalTests - $passedTests)" -ForegroundColor Red
Write-Host "Pass Rate:    $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "📋 DETAILED RESULTS BY SERVICE" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$serviceGroups = $results | Group-Object -Property Service
foreach ($group in $serviceGroups | Sort-Object Name) {
    $servicePassed = ($group.Group | Where-Object { $_.Status -eq "✅ PASS" }).Count
    $serviceTotal = $group.Count
    $serviceRate = [Math]::Round(($servicePassed / $serviceTotal) * 100, 0)
    
    Write-Host ""
    Write-Host ('{0}: {1}/{2} ({3}%)' -f $group.Name, $servicePassed, $serviceTotal, $serviceRate) -ForegroundColor Cyan
    foreach ($result in $group.Group) {
        Write-Host ('  {0} {1} - {2}' -f $result.Status, $result.Action, $result.Description) -ForegroundColor Gray
        if ($result.Message -ne 'Success') {
            Write-Host ('      Error: {0}' -f $result.Message) -ForegroundColor Red
        }
    }
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "✅ Testing complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
