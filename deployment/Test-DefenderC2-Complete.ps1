<#
.SYNOPSIS
    Comprehensive Testing Suite for DefenderXDR C2 v3.0.0

.DESCRIPTION
    Tests all 7 workers with real API calls to validate authentication, routing, and functionality.
    
.PARAMETER FunctionAppUrl
    Base URL of the deployed Function App (e.g., https://sentryxdr.azurewebsites.net)
    
.PARAMETER FunctionKey
    Function key for authentication (from Azure Portal)
    
.PARAMETER TenantId
    Azure AD tenant ID for testing
    
.EXAMPLE
    .\Test-DefenderC2-Complete.ps1 -FunctionAppUrl "https://sentryxdr.azurewebsites.net" -FunctionKey "xxx" -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Remove trailing slash
$FunctionAppUrl = $FunctionAppUrl.TrimEnd('/')

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DefenderXDR C2 v3.0.0 - Comprehensive Testing Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Function App: $FunctionAppUrl" -ForegroundColor Yellow
Write-Host "Tenant ID:    $TenantId" -ForegroundColor Yellow
Write-Host "Timestamp:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

function Invoke-DefenderC2Test {
    param(
        [string]$TestName,
        [string]$Service,
        [string]$Action,
        [hashtable]$AdditionalParams = @{},
        [bool]$ExpectSuccess = $true
    )
    
    $testResults.Total++
    
    Write-Host "─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "TEST $($testResults.Total): $TestName" -ForegroundColor White
    Write-Host "  Service: $Service | Action: $Action" -ForegroundColor Gray
    
    $body = @{
        service = $Service
        action = $Action
        tenantId = $TenantId
    }
    
    # Merge additional parameters
    foreach ($key in $AdditionalParams.Keys) {
        $body[$key] = $AdditionalParams[$key]
    }
    
    $jsonBody = $body | ConvertTo-Json -Depth 5
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
    
    Write-Host "  Request: " -ForegroundColor Gray -NoNewline
    Write-Host $jsonBody.Replace("`n", " ").Replace("`r", "") -ForegroundColor DarkGray
    
    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $jsonBody -ContentType "application/json" -TimeoutSec 30
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $success = $response.success -eq $true -or ($response -and -not $response.error)
        
        if ($ExpectSuccess -eq $success) {
            Write-Host "  ✅ PASS" -ForegroundColor Green -NoNewline
            Write-Host " ($([int]$duration)ms)" -ForegroundColor Gray
            $testResults.Passed++
            $status = "PASS"
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red -NoNewline
            Write-Host " ($([int]$duration)ms)" -ForegroundColor Gray
            Write-Host "  Expected Success: $ExpectSuccess, Got: $success" -ForegroundColor Red
            $testResults.Failed++
            $status = "FAIL"
        }
        
        # Show response summary
        if ($response.data) {
            $dataType = $response.data.GetType().Name
            if ($response.data -is [Array]) {
                Write-Host "  Response: $dataType with $($response.data.Count) items" -ForegroundColor DarkCyan
            } else {
                Write-Host "  Response: $dataType" -ForegroundColor DarkCyan
            }
        } elseif ($response.error) {
            Write-Host "  Error: $($response.error.code) - $($response.error.message)" -ForegroundColor Red
        }
        
        $testResults.Tests += @{
            Name = $TestName
            Service = $Service
            Action = $Action
            Status = $status
            Duration = $duration
            Response = $response
        }
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-Host "  ❌ EXCEPTION" -ForegroundColor Red -NoNewline
        Write-Host " ($([int]$duration)ms)" -ForegroundColor Gray
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "  Details: $($errorDetails.error)" -ForegroundColor Red
            } catch {
                Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
        
        $testResults.Failed++
        $testResults.Tests += @{
            Name = $TestName
            Service = $Service
            Action = $Action
            Status = "EXCEPTION"
            Duration = $duration
            Error = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# ============================================================================
# TEST SUITE: Gateway & Orchestrator Validation
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 1: Gateway & Orchestrator Validation" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "Gateway - Missing TenantId" -Service "MDE" -Action "GetDevices" -ExpectSuccess $false -AdditionalParams @{tenantId = ""}
Invoke-DefenderC2Test -TestName "Gateway - Invalid Service" -Service "INVALID" -Action "GetDevices" -ExpectSuccess $false
Invoke-DefenderC2Test -TestName "Gateway - Missing Action" -Service "MDE" -Action "" -ExpectSuccess $false

# ============================================================================
# TEST SUITE: MDE Worker (Microsoft Defender for Endpoint)
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 2: MDE Worker - Device Management" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "MDE - Get All Devices" -Service "MDE" -Action "GetDevices"
Invoke-DefenderC2Test -TestName "MDE - Get All Machine Actions" -Service "MDE" -Action "GetAllActions"
Invoke-DefenderC2Test -TestName "MDE - Get Indicators (IOCs)" -Service "MDE" -Action "GetIndicators"

# ============================================================================
# TEST SUITE: Advanced Hunting
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 3: MDE Worker - Advanced Hunting" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$huntingQuery = "DeviceInfo | take 5 | project DeviceName, OSPlatform, DeviceId"
Invoke-DefenderC2Test -TestName "MDE - Advanced Hunting Query" -Service "MDE" -Action "RunQuery" -AdditionalParams @{query = $huntingQuery}

# ============================================================================
# TEST SUITE: Incidents & Alerts
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 4: Incident & Alert Management" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "MDE - Get Incidents" -Service "MDE" -Action "GetIncidents"
Invoke-DefenderC2Test -TestName "MDE - Get Alerts" -Service "MDE" -Action "GetAlerts"

# ============================================================================
# TEST SUITE: MDO Worker (Microsoft Defender for Office 365)
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 5: MDO Worker - Email Security" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Note: These may require specific email data to test properly
# Invoke-DefenderC2Test -TestName "MDO - Submit Email Threat" -Service "MDO" -Action "SubmitEmailThreat"

# ============================================================================
# TEST SUITE: EntraID Worker
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 6: EntraID Worker - Identity Protection" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "EntraID - Get Risky Users" -Service "EntraID" -Action "GetRiskyUsers"
Invoke-DefenderC2Test -TestName "EntraID - Get Risk Detections" -Service "EntraID" -Action "GetRiskDetections"
Invoke-DefenderC2Test -TestName "EntraID - Get Conditional Access Policies" -Service "EntraID" -Action "GetConditionalAccessPolicies"

# ============================================================================
# TEST SUITE: Intune Worker
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 7: Intune Worker - Device Management" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "Intune - Get Managed Devices" -Service "Intune" -Action "GetManagedDevices"
Invoke-DefenderC2Test -TestName "Intune - Get Device Compliance Policies" -Service "Intune" -Action "GetCompliancePolicies"

# ============================================================================
# TEST SUITE: Azure Worker
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 8: Azure Worker - Infrastructure Security" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "Azure - Get Resource Groups" -Service "Azure" -Action "GetResourceGroups"
Invoke-DefenderC2Test -TestName "Azure - Get Virtual Machines" -Service "Azure" -Action "GetVMs"
Invoke-DefenderC2Test -TestName "Azure - Get Network Security Groups" -Service "Azure" -Action "GetNSGs"

# ============================================================================
# TEST SUITE: MDI Worker
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 9: MDI Worker - Identity Threat Detection" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "MDI - Get Alerts" -Service "MDI" -Action "GetAlerts"
Invoke-DefenderC2Test -TestName "MDI - Get Lateral Movement Paths" -Service "MDI" -Action "GetLateralMovementPaths"

# ============================================================================
# TEST SUITE: MCAS Worker
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 10: MCAS Worker - Cloud App Security" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Invoke-DefenderC2Test -TestName "MCAS - Get Alerts" -Service "MCAS" -Action "GetAlerts"
Invoke-DefenderC2Test -TestName "MCAS - Get Activities" -Service "MCAS" -Action "GetActivities"

# ============================================================================
# RESULTS SUMMARY
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$passRate = if ($testResults.Total -gt 0) { [math]::Round(($testResults.Passed / $testResults.Total) * 100, 2) } else { 0 }

Write-Host "Total Tests:   $($testResults.Total)" -ForegroundColor White
Write-Host "Passed:        $($testResults.Passed) " -ForegroundColor Green -NoNewline
Write-Host "($passRate%)" -ForegroundColor Gray
Write-Host "Failed:        $($testResults.Failed)" -ForegroundColor Red
Write-Host "Skipped:       $($testResults.Skipped)" -ForegroundColor Yellow
Write-Host ""

# Show failed tests
if ($testResults.Failed -gt 0) {
    Write-Host "FAILED TESTS:" -ForegroundColor Red
    Write-Host "─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $testResults.Tests | Where-Object { $_.Status -ne "PASS" } | ForEach-Object {
        Write-Host "  ❌ $($_.Name)" -ForegroundColor Red
        Write-Host "     Service: $($_.Service) | Action: $($_.Action)" -ForegroundColor Gray
        if ($_.Error) {
            Write-Host "     Error: $($_.Error)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Performance summary
$avgDuration = ($testResults.Tests | Measure-Object -Property Duration -Average).Average
Write-Host "Average Response Time: $([int]$avgDuration)ms" -ForegroundColor Cyan

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Export results
$resultsFile = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile
Write-Host "Results exported to: $resultsFile" -ForegroundColor Gray
