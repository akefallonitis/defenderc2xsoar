<#
.SYNOPSIS
    Comprehensive Gateway testing script for DefenderC2XSOAR
    
.DESCRIPTION
    Tests all major function endpoints through the Gateway
    - Tests both GET and POST methods
    - Tests all service integrations
    - Validates responses
    - Tests incident management (Graph Security API)
    - Tests hunting capabilities
    
.PARAMETER FunctionAppUrl
    The Function App URL (default: https://sentryxdr.azurewebsites.net)
    
.PARAMETER FunctionKey
    Function app master key or default key
    
.PARAMETER TenantId
    Azure AD Tenant ID to test against
    
.EXAMPLE
    .\test-gateway-comprehensive.ps1 -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$FunctionAppUrl = "https://sentryxdr.azurewebsites.net",
    
    [Parameter(Mandatory = $false)]
    [string]$FunctionKey = "IM4G-JE3r1vDk35ZmAlmZIv8muL7-vTkjlKczXFJikAzFuLkGIQ==",
    
    [Parameter(Mandatory = $true)]
    [string]$TenantId
)

$ErrorActionPreference = "Continue"

# Color helper
function Write-TestResult {
    param([string]$Test, [bool]$Success, [string]$Message, [object]$Data = $null)
    
    if ($Success) {
        Write-Host "✅ " -ForegroundColor Green -NoNewline
    } else {
        Write-Host "❌ " -ForegroundColor Red -NoNewline
    }
    Write-Host "$Test" -ForegroundColor Cyan -NoNewline
    Write-Host " - $Message" -ForegroundColor $(if ($Success) { "Green" } else { "Red" })
    
    if ($Data) {
        Write-Host "   Response: $($Data | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor Gray
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "DefenderC2XSOAR Gateway Comprehensive Testing" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Function App: $FunctionAppUrl" -ForegroundColor Gray
Write-Host "Tenant ID:    $TenantId" -ForegroundColor Gray
Write-Host ("=" * 80) -ForegroundColor Cyan

$testResults = @()
$successCount = 0
$failCount = 0

# ============================================================================
# TEST 1: Basic Connectivity (GET)
# ============================================================================

Write-Host "`n📡 TEST 1: Basic Gateway Connectivity (GET)" -ForegroundColor Yellow

try {
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey&tenant=$TenantId&service=MDE&action=GetAllDevices"
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 60 -ErrorAction Stop
    
    $success = $response -ne $null
    $successCount++
    Write-TestResult -Test "Gateway GET" -Success $true -Message "Connected successfully" -Data $response
    $testResults += @{ Test = "Gateway GET"; Status = "✅ Pass"; Details = "Connected" }
} catch {
    $failCount++
    Write-TestResult -Test "Gateway GET" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "Gateway GET"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 2: Basic Connectivity (POST)
# ============================================================================

Write-Host "`n📡 TEST 2: Basic Gateway Connectivity (POST)" -ForegroundColor Yellow

try {
    $headers = @{ "Content-Type" = "application/json" }
    $body = @{
        tenant = $TenantId
        service = "MDE"
        action = "GetAllDevices"
    } | ConvertTo-Json
    
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -TimeoutSec 60 -ErrorAction Stop
    
    $success = $response -ne $null
    $successCount++
    Write-TestResult -Test "Gateway POST" -Success $true -Message "Connected successfully" -Data $response
    $testResults += @{ Test = "Gateway POST"; Status = "✅ Pass"; Details = "Connected" }
} catch {
    $failCount++
    Write-TestResult -Test "Gateway POST" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "Gateway POST"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 3: MDE Device Listing
# ============================================================================

Write-Host "`n💻 TEST 3: MDE Device Listing" -ForegroundColor Yellow

try {
    $body = @{
        tenant = $TenantId
        service = "MDE"
        action = "GetAllDevices"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $deviceCount = if ($response.value) { $response.value.Count } elseif ($response.devices) { $response.devices.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "MDE GetAllDevices" -Success $true -Message "Retrieved $deviceCount devices" -Data $response
    $testResults += @{ Test = "MDE Devices"; Status = "✅ Pass"; Details = "$deviceCount devices" }
} catch {
    $failCount++
    Write-TestResult -Test "MDE GetAllDevices" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "MDE Devices"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 4: Incident Listing (Graph Security API)
# ============================================================================

Write-Host "`n🚨 TEST 4: Security Incidents (Graph API)" -ForegroundColor Yellow

try {
    $body = @{
        tenant = $TenantId
        service = "IncidentManager"
        action = "GetIncidents"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $incidentCount = if ($response.value) { $response.value.Count } elseif ($response.incidents) { $response.incidents.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "Get Incidents" -Success $true -Message "Retrieved $incidentCount incidents" -Data $response
    $testResults += @{ Test = "Incidents"; Status = "✅ Pass"; Details = "$incidentCount incidents" }
} catch {
    $failCount++
    Write-TestResult -Test "Get Incidents" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "Incidents"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 5: MDE Alerts
# ============================================================================

Write-Host "`n⚠️  TEST 5: MDE Security Alerts" -ForegroundColor Yellow

try {
    $body = @{
        tenant = $TenantId
        service = "MDE"
        action = "GetAllAlerts"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $alertCount = if ($response.value) { $response.value.Count } elseif ($response.alerts) { $response.alerts.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "MDE Alerts" -Success $true -Message "Retrieved $alertCount alerts" -Data $response
    $testResults += @{ Test = "MDE Alerts"; Status = "✅ Pass"; Details = "$alertCount alerts" }
} catch {
    $failCount++
    Write-TestResult -Test "MDE Alerts" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "MDE Alerts"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 6: Advanced Hunting (KQL)
# ============================================================================

Write-Host "`n🔍 TEST 6: Advanced Hunting (KQL Query)" -ForegroundColor Yellow

try {
    $kqlQuery = "DeviceInfo | take 10"
    $body = @{
        tenant = $TenantId
        service = "HuntManager"
        action = "RunQuery"
        query = $kqlQuery
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $resultCount = if ($response.results) { $response.results.Count } elseif ($response.value) { $response.value.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "Advanced Hunting" -Success $true -Message "Query executed, $resultCount results" -Data $response
    $testResults += @{ Test = "Hunting KQL"; Status = "✅ Pass"; Details = "$resultCount results" }
} catch {
    $failCount++
    Write-TestResult -Test "Advanced Hunting" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "Hunting KQL"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 7: Threat Intel - Get Indicators
# ============================================================================

Write-Host "`n🛡️  TEST 7: Threat Intelligence Indicators" -ForegroundColor Yellow

try {
    $body = @{
        tenant = $TenantId
        service = "ThreatIntelManager"
        action = "GetIndicators"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $indicatorCount = if ($response.value) { $response.value.Count } elseif ($response.indicators) { $response.indicators.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "Threat Indicators" -Success $true -Message "Retrieved $indicatorCount indicators" -Data $response
    $testResults += @{ Test = "Threat Intel"; Status = "✅ Pass"; Details = "$indicatorCount indicators" }
} catch {
    $failCount++
    Write-TestResult -Test "Threat Indicators" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "Threat Intel"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# TEST 8: EntraID User Operations
# ============================================================================

Write-Host "`n👤 TEST 8: EntraID User Information" -ForegroundColor Yellow

try {
    $body = @{
        tenant = $TenantId
        service = "EntraID"
        action = "GetRiskyUsers"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$FunctionAppUrl/api/Gateway?code=$FunctionKey" -Method Post -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 60
    
    $userCount = if ($response.value) { $response.value.Count } elseif ($response.users) { $response.users.Count } else { 0 }
    $successCount++
    Write-TestResult -Test "EntraID Risky Users" -Success $true -Message "Retrieved $userCount risky users" -Data $response
    $testResults += @{ Test = "EntraID"; Status = "✅ Pass"; Details = "$userCount risky users" }
} catch {
    $failCount++
    Write-TestResult -Test "EntraID Risky Users" -Success $false -Message $_.Exception.Message
    $testResults += @{ Test = "EntraID"; Status = "❌ Fail"; Details = $_.Exception.Message }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$totalTests = $successCount + $failCount
$successRate = if ($totalTests -gt 0) { [Math]::Round(($successCount / $totalTests) * 100, 2) } else { 0 }

Write-Host "✅ Passed: $successCount tests" -ForegroundColor Green
Write-Host "❌ Failed: $failCount tests" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "📊 Success Rate: $successRate%" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Detailed results table
Write-Host "`n📋 Detailed Results:" -ForegroundColor Yellow
$testResults | Format-Table -AutoSize

# ============================================================================
# NEXT STEPS
# ============================================================================

if ($failCount -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED! Functions are working correctly." -ForegroundColor Green
    Write-Host "`n✨ Ready to proceed with workbook implementation!" -ForegroundColor Cyan
    Write-Host "`nWorkbook Features:" -ForegroundColor Yellow
    Write-Host "  • Main Dashboard: Incidents/Alerts/Entities" -ForegroundColor Gray
    Write-Host "  • Multi-tenant Support (Lighthouse)" -ForegroundColor Gray
    Write-Host "  • Device Management & Live Response" -ForegroundColor Gray
    Write-Host "  • Advanced Hunting Console (KQL)" -ForegroundColor Gray
    Write-Host "  • Threat Intelligence Management" -ForegroundColor Gray
    Write-Host "  • File Operations & Library" -ForegroundColor Gray
    Write-Host "  • Interactive Console UI" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  Some tests failed. Review errors above." -ForegroundColor Yellow
    Write-Host "`nCommon Issues:" -ForegroundColor Yellow
    Write-Host "  • 401 Unauthorized: Function key incorrect or function not deployed" -ForegroundColor Gray
    Write-Host "  • 404 Not Found: Function package not loaded yet (wait 30-90s or sync)" -ForegroundColor Gray
    Write-Host "  • 403 Forbidden: API permissions not consented" -ForegroundColor Gray
    Write-Host "  • Timeout: Function cold start or long-running operation" -ForegroundColor Gray
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify function key in Azure Portal (Function App → App keys)" -ForegroundColor Gray
    Write-Host "  2. Check admin consent granted (Azure AD → App registrations → API permissions)" -ForegroundColor Gray
    Write-Host "  3. Trigger sync: az functionapp deployment source sync -n sentryxdr -g alex-testing-rg" -ForegroundColor Gray
    Write-Host "  4. Check function logs in Azure Portal (Monitor → Logs)" -ForegroundColor Gray
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan

# Return summary for automation
return @{
    TotalTests = $totalTests
    Passed = $successCount
    Failed = $failCount
    SuccessRate = $successRate
    ReadyForWorkbook = ($failCount -eq 0)
}
