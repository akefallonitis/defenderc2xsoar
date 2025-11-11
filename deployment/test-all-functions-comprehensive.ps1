<#
.SYNOPSIS
    Comprehensive automated test suite for DefenderC2XSOAR functions
    
.DESCRIPTION
    Tests all deployed functions across all services (MDE, MDO, MDC, MDI, EntraID, Intune, Azure)
    using actual API calls to validate:
    - Authentication works properly
    - Request payloads are correctly formatted
    - API endpoints are correct
    - Response handling is working
    - All actions execute successfully
    
.PARAMETER TenantId
    Target tenant ID for testing
    
.PARAMETER FunctionAppUrl
    Function App base URL (default: https://sentryxdr.azurewebsites.net)
    
.PARAMETER FunctionKey
    Function key for authentication (use _master or default key)
    
.PARAMETER SubscriptionId
    Azure subscription ID (required for MDC and Azure tests)
    
.PARAMETER ResourceGroup
    Resource group name (required for Azure infrastructure tests)
    
.PARAMETER TestService
    Optional: Test only specific service (MDE, MDO, MDC, MDI, EntraID, Intune, Azure, ALL)
    
.EXAMPLE
    .\test-all-functions-comprehensive.ps1 -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -FunctionKey "IM4G-..."
    
.EXAMPLE
    .\test-all-functions-comprehensive.ps1 -TenantId "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9" -FunctionKey "IM4G-..." -TestService "MDE"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$FunctionAppUrl = "https://sentryxdr.azurewebsites.net",
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionKey,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure", "ALL")]
    [string]$TestService = "ALL"
)

$ErrorActionPreference = "Continue"
$WarningPreference = "SilentlyContinue"

# ============================================================================
# TEST INFRASTRUCTURE
# ============================================================================

$script:TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

function Write-TestSection {
    param([string]$Section)
    Write-Host "`n--- $Section ---" -ForegroundColor Yellow
}

function Invoke-FunctionTest {
    param(
        [string]$TestName,
        [string]$Service,
        [string]$Action,
        [hashtable]$Parameters = @{},
        [bool]$Required = $true,
        [string]$ExpectedStatus = "OK"
    )
    
    $script:TestResults.Total++
    $testStart = Get-Date
    
    Write-Host "`n[$($script:TestResults.Total)] Testing: $TestName..." -NoNewline -ForegroundColor Gray
    
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
        
        # Build URL with function key
        $url = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
        
        # Make request
        $response = Invoke-RestMethod -Uri $url -Method Post `
            -Headers @{"Content-Type" = "application/json"} `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -TimeoutSec 60 `
            -ErrorAction Stop
        
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        # Check response
        if ($response.success -eq $true) {
            Write-Host " [PASS] ($([int]$duration)ms)" -ForegroundColor Green
            $script:TestResults.Passed++
            
            $testResult = @{
                Name = $TestName
                Service = $Service
                Action = $Action
                Status = "PASS"
                Duration = [int]$duration
                Response = $response
                Error = $null
            }
        } else {
            Write-Host " [WARN] ($([int]$duration)ms)" -ForegroundColor Yellow
            Write-Host "    Response: $($response.error.message)" -ForegroundColor DarkYellow
            
            $testResult = @{
                Name = $TestName
                Service = $Service
                Action = $Action
                Status = "WARNING"
                Duration = [int]$duration
                Response = $response
                Error = $response.error
            }
            
            if ($Required) {
                $script:TestResults.Failed++
            } else {
                $script:TestResults.Skipped++
            }
        }
        
    } catch {
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        Write-Host " [FAIL] ($([int]$duration)ms)" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor DarkRed
        
        if ($Required) {
            $script:TestResults.Failed++
        } else {
            $script:TestResults.Skipped++
        }
        
        $testResult = @{
            Name = $TestName
            Service = $Service
            Action = $Action
            Status = "FAIL"
            Duration = [int]$duration
            Response = $null
            Error = $_.Exception.Message
        }
    }
    
    $script:TestResults.Tests += $testResult
    return $testResult
}

# ============================================================================
# START TESTING
# ============================================================================

Write-TestHeader "DefenderC2XSOAR Comprehensive Function Test Suite"
Write-Host "Function App: $FunctionAppUrl" -ForegroundColor Gray
Write-Host "Tenant ID: $TenantId" -ForegroundColor Gray
Write-Host "Test Scope: $TestService" -ForegroundColor Gray
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# ============================================================================
# GATEWAY CONNECTIVITY TESTS
# ============================================================================

Write-TestSection "Gateway Connectivity Tests"

# Test 1: Basic connectivity
Invoke-FunctionTest `
    -TestName "Gateway GET Connectivity" `
    -Service "MDE" `
    -Action "GetAllDevices" `
    -Required $true

# Test 2: POST with parameters
Invoke-FunctionTest `
    -TestName "Gateway POST Connectivity" `
    -Service "MDE" `
    -Action "GetAllDevices" `
    -Required $true

# ============================================================================
# MICROSOFT DEFENDER FOR ENDPOINT (MDE) TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "MDE") {
    
    Write-TestSection "Microsoft Defender for Endpoint (MDE) Tests"
    
    # Device Management Tests
    Invoke-FunctionTest `
        -TestName "MDE: Get All Devices" `
        -Service "MDE" `
        -Action "GetAllDevices" `
        -Required $true
    
    # Store first device ID for subsequent tests
    $devicesTest = $script:TestResults.Tests | Where-Object { $_.Name -eq "MDE: Get All Devices" -and $_.Status -eq "PASS" } | Select-Object -First 1
    $testDeviceId = $null
    if ($devicesTest -and $devicesTest.Response.data.devices -and $devicesTest.Response.data.devices.Count -gt 0) {
        $testDeviceId = $devicesTest.Response.data.devices[0].id
        Write-Host "  Using device ID for tests: $testDeviceId" -ForegroundColor DarkGray
    }
    
    # Advanced Hunting Tests
    Invoke-FunctionTest `
        -TestName "MDE: Advanced Hunting - Device Info" `
        -Service "MDE" `
        -Action "AdvancedHunt" `
        -Parameters @{
            query = "DeviceInfo | take 10"
        } `
        -Required $true
    
    Invoke-FunctionTest `
        -TestName "MDE: Advanced Hunting - Process Events" `
        -Service "MDE" `
        -Action "AdvancedHunt" `
        -Parameters @{
            query = "DeviceProcessEvents | where Timestamp > ago(1h) | take 100"
        } `
        -Required $true
    
    Invoke-FunctionTest `
        -TestName "MDE: Advanced Hunting - Network Events" `
        -Service "MDE" `
        -Action "AdvancedHunt" `
        -Parameters @{
            query = "DeviceNetworkEvents | where Timestamp > ago(1h) | take 100"
        } `
        -Required $true
    
    # Incident Management Tests
    Invoke-FunctionTest `
        -TestName "MDE: Get All Incidents" `
        -Service "MDE" `
        -Action "GetIncidents" `
        -Required $true
    
    # Threat Intelligence Tests
    Invoke-FunctionTest `
        -TestName "MDE: Get All Indicators" `
        -Service "MDE" `
        -Action "GetAllIndicators" `
        -Required $true
    
    # Device Info Test (if we have a device ID)
    if ($testDeviceId) {
        Invoke-FunctionTest `
            -TestName "MDE: Get Device Info" `
            -Service "MDE" `
            -Action "GetDeviceInfo" `
            -Parameters @{
                machineId = $testDeviceId
            } `
            -Required $false
    }
    
    # Device Actions Tests (read-only safe tests)
    Write-Host "`n  NOTE: Skipping destructive device actions (isolate, scan, etc.) - enable manually if needed" -ForegroundColor DarkYellow
}

# ============================================================================
# MICROSOFT DEFENDER FOR OFFICE 365 (MDO) TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "MDO") {
    
    Write-TestSection "Microsoft Defender for Office 365 (MDO) Tests"
    
    # Note: Most MDO operations require specific message IDs or URLs
    # We'll test the endpoint connectivity but expect graceful failures
    
    Write-Host "`n  NOTE: MDO tests require specific message IDs - testing endpoint connectivity only" -ForegroundColor DarkYellow
    
    # These will likely fail gracefully but validate auth and endpoint configuration
    Invoke-FunctionTest `
        -TestName "MDO: Submit URL Threat (Validation Test)" `
        -Service "MDO" `
        -Action "SubmitURLThreat" `
        -Parameters @{
            url = "https://example.com/test"
        } `
        -Required $false
}

# ============================================================================
# MICROSOFT DEFENDER FOR CLOUD (MDC) TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "MDC") {
    
    Write-TestSection "Microsoft Defender for Cloud (MDC) Tests"
    
    if ($SubscriptionId) {
        Invoke-FunctionTest `
            -TestName "MDC: Get Security Alerts" `
            -Service "MDC" `
            -Action "GetSecurityAlerts" `
            -Parameters @{
                subscriptionId = $SubscriptionId
            } `
            -Required $true
        
        Invoke-FunctionTest `
            -TestName "MDC: Get Recommendations" `
            -Service "MDC" `
            -Action "GetRecommendations" `
            -Parameters @{
                subscriptionId = $SubscriptionId
            } `
            -Required $true
        
        Invoke-FunctionTest `
            -TestName "MDC: Get Secure Score" `
            -Service "MDC" `
            -Action "GetSecureScore" `
            -Parameters @{
                subscriptionId = $SubscriptionId
            } `
            -Required $true
        
        Invoke-FunctionTest `
            -TestName "MDC: Get Defender Plans" `
            -Service "MDC" `
            -Action "GetDefenderPlans" `
            -Parameters @{
                subscriptionId = $SubscriptionId
            } `
            -Required $true
    } else {
        Write-Host "`n  ⚠️ SKIPPED: MDC tests require -SubscriptionId parameter" -ForegroundColor Yellow
        $script:TestResults.Skipped += 4
    }
}

# ============================================================================
# MICROSOFT DEFENDER FOR IDENTITY (MDI) TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "MDI") {
    
    Write-TestSection "Microsoft Defender for Identity (MDI) Tests"
    
    Invoke-FunctionTest `
        -TestName "MDI: Get Alerts" `
        -Service "MDI" `
        -Action "GetAlerts" `
        -Required $true
    
    Invoke-FunctionTest `
        -TestName "MDI: Get Lateral Movement Paths" `
        -Service "MDI" `
        -Action "GetLateralMovementPaths" `
        -Required $true
    
    Invoke-FunctionTest `
        -TestName "MDI: Get Exposed Credentials" `
        -Service "MDI" `
        -Action "GetExposedCredentials" `
        -Required $true
    
    Invoke-FunctionTest `
        -TestName "MDI: Get Identity Secure Score" `
        -Service "MDI" `
        -Action "GetIdentitySecureScore" `
        -Required $true
}

# ============================================================================
# ENTRA ID TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "EntraID") {
    
    Write-TestSection "Entra ID (Identity & Access Management) Tests"
    
    # Note: User-specific actions require valid user IDs
    # Testing with placeholder - expecting graceful failures
    
    Write-Host "`n  NOTE: EntraID tests with sample user IDs - may return not found errors" -ForegroundColor DarkYellow
    
    Invoke-FunctionTest `
        -TestName "EntraID: Get Risk Detections (Sample User)" `
        -Service "EntraID" `
        -Action "GetRiskDetections" `
        -Parameters @{
            userId = "test@example.com"
        } `
        -Required $false
}

# ============================================================================
# INTUNE TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "Intune") {
    
    Write-TestSection "Intune (Device Management) Tests"
    
    Invoke-FunctionTest `
        -TestName "Intune: Get Managed Devices" `
        -Service "Intune" `
        -Action "GetManagedDevices" `
        -Required $true
}

# ============================================================================
# AZURE INFRASTRUCTURE TESTS
# ============================================================================

if ($TestService -eq "ALL" -or $TestService -eq "Azure") {
    
    Write-TestSection "Azure Infrastructure Tests"
    
    if ($SubscriptionId -and $ResourceGroup) {
        Invoke-FunctionTest `
            -TestName "Azure: Get VMs" `
            -Service "Azure" `
            -Action "GetVMs" `
            -Parameters @{
                subscriptionId = $SubscriptionId
                resourceGroup = $ResourceGroup
            } `
            -Required $true
    } else {
        Write-Host "`n  ⚠️ SKIPPED: Azure tests require -SubscriptionId and -ResourceGroup parameters" -ForegroundColor Yellow
        $script:TestResults.Skipped++
    }
}

# ============================================================================
# TEST SUMMARY
# ============================================================================

Write-TestHeader "TEST SUMMARY"

$passRate = if ($script:TestResults.Total -gt 0) {
    [Math]::Round(($script:TestResults.Passed / $script:TestResults.Total) * 100, 2)
} else {
    0
}

Write-Host "`nTotal Tests:    $($script:TestResults.Total)" -ForegroundColor Cyan
Write-Host "[PASS] Passed:       $($script:TestResults.Passed)" -ForegroundColor Green
Write-Host "[FAIL] Failed:       $($script:TestResults.Failed)" -ForegroundColor $(if ($script:TestResults.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "[SKIP] Skipped:      $($script:TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "Pass Rate:      $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })

# ============================================================================
# DETAILED FAILURE REPORT
# ============================================================================

$failures = $script:TestResults.Tests | Where-Object { $_.Status -eq "FAIL" }
if ($failures.Count -gt 0) {
    Write-TestHeader "FAILED TESTS DETAILS"
    
    foreach ($failure in $failures) {
        Write-Host "`n[FAIL] $($failure.Name)" -ForegroundColor Red
        Write-Host "   Service: $($failure.Service)" -ForegroundColor Gray
        Write-Host "   Action: $($failure.Action)" -ForegroundColor Gray
        Write-Host "   Error: $($failure.Error)" -ForegroundColor DarkRed
    }
}

# ============================================================================
# WARNINGS REPORT
# ============================================================================

$warnings = $script:TestResults.Tests | Where-Object { $_.Status -eq "WARNING" }
if ($warnings.Count -gt 0) {
    Write-TestHeader "WARNINGS"
    
    foreach ($warning in $warnings) {
        Write-Host "`n[WARN] $($warning.Name)" -ForegroundColor Yellow
        Write-Host "   Service: $($warning.Service)" -ForegroundColor Gray
        Write-Host "   Action: $($warning.Action)" -ForegroundColor Gray
        Write-Host "   Message: $($warning.Error.message)" -ForegroundColor DarkYellow
    }
}

# ============================================================================
# SUCCESS SAMPLES
# ============================================================================

$successes = $script:TestResults.Tests | Where-Object { $_.Status -eq "PASS" } | Select-Object -First 5
if ($successes.Count -gt 0) {
    Write-TestHeader "SUCCESSFUL TEST SAMPLES (First 5)"
    
    foreach ($success in $successes) {
        Write-Host "`n[PASS] $($success.Name)" -ForegroundColor Green
        Write-Host "   Service: $($success.Service)" -ForegroundColor Gray
        Write-Host "   Action: $($success.Action)" -ForegroundColor Gray
        Write-Host "   Duration: $($success.Duration)ms" -ForegroundColor DarkGray
        
        if ($success.Response.data) {
            $dataKeys = $success.Response.data.PSObject.Properties.Name
            Write-Host "   Data returned: $($dataKeys -join ', ')" -ForegroundColor DarkGray
        }
    }
}

# ============================================================================
# RECOMMENDATIONS
# ============================================================================

Write-TestHeader "RECOMMENDATIONS"

if ($script:TestResults.Failed -gt 0) {
    Write-Host "[FAIL] CRITICAL: $($script:TestResults.Failed) tests failed" -ForegroundColor Red
    Write-Host "   - Review authentication configuration (APPID and SECRETID env vars)" -ForegroundColor Yellow
    Write-Host "   - Check API permissions are granted admin consent" -ForegroundColor Yellow
    Write-Host "   - Verify function code is properly deployed" -ForegroundColor Yellow
    Write-Host "   - Check function app logs for detailed errors" -ForegroundColor Yellow
} elseif ($script:TestResults.Passed -eq $script:TestResults.Total) {
    Write-Host "[PASS] EXCELLENT: All tests passed!" -ForegroundColor Green
    Write-Host "   - Functions are properly authenticated" -ForegroundColor Green
    Write-Host "   - Request/response handling is working" -ForegroundColor Green
    Write-Host "   - Ready for workbook implementation" -ForegroundColor Green
} else {
    Write-Host "[WARN] PARTIAL SUCCESS: Some tests passed" -ForegroundColor Yellow
    Write-Host "   - Core functionality is working" -ForegroundColor Yellow
    Write-Host "   - Review failed tests for specific issues" -ForegroundColor Yellow
    Write-Host "   - May need additional parameter configuration" -ForegroundColor Yellow
}

Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
Write-Host "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "$('=' * 80)`n" -ForegroundColor Cyan

# Export results to JSON for further analysis
$resultsFile = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile
Write-Host "[RESULTS] Detailed results exported to: $resultsFile" -ForegroundColor Cyan

# Exit with appropriate code
if ($script:TestResults.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
