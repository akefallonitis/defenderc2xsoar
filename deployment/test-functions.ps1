# Function Testing Script for DefenderC2XSOAR
# Run this to test all deployed function endpoints

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppUrl = "https://sentryxdr.azurewebsites.net",
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId = "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
)

Write-Host "=== DefenderC2XSOAR Function Testing ===" -ForegroundColor Cyan
Write-Host "Function App: $FunctionAppUrl" -ForegroundColor Yellow
Write-Host "Tenant ID: $TenantId" -ForegroundColor Yellow
Write-Host ""

$headers = @{
    "x-functions-key" = $FunctionKey
}

$testResults = @()

function Test-FunctionEndpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = $null
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  URL: $Url" -NoNewline
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $Url -Method Get -Headers $headers -TimeoutSec 30
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method Post -Headers $headers -Body ($Body | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
        }
        
        Write-Host " ✅ SUCCESS" -ForegroundColor Green
        
        # Display key info
        if ($response.success) {
            Write-Host "  Response: Success" -ForegroundColor Green
            if ($response.data) {
                if ($response.data.count) {
                    Write-Host "  Data Count: $($response.data.count)" -ForegroundColor Cyan
                }
                if ($response.data.message) {
                    Write-Host "  Message: $($response.data.message)" -ForegroundColor Cyan
                }
            }
        }
        
        $script:testResults += @{
            Test = $Name
            Status = "PASS"
            Response = $response
        }
        
        return $true
    }
    catch {
        Write-Host " ❌ FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $script:testResults += @{
            Test = $Name
            Status = "FAIL"
            Error = $_.Exception.Message
        }
        
        return $false
    }
    
    Write-Host ""
}

# ============================================================================
# TEST SUITE
# ============================================================================

Write-Host "`n--- MDE (Microsoft Defender for Endpoint) Tests ---`n" -ForegroundColor Magenta

# Test 1: Get All Devices
Test-FunctionEndpoint -Name "MDE - Get All Devices" `
    -Url "$FunctionAppUrl/api/XDROrchestrator?service=MDE&action=GetAllDevices&tenantId=$TenantId"

# Test 2: Advanced Hunting
$huntBody = @{
    service = "MDE"
    action = "AdvancedHunt"
    tenantId = $TenantId
    query = "DeviceInfo | take 5"
}
Test-FunctionEndpoint -Name "MDE - Advanced Hunting" `
    -Url "$FunctionAppUrl/api/XDROrchestrator" `
    -Method "POST" `
    -Body $huntBody

# Test 3: Get Incidents
Test-FunctionEndpoint -Name "MDE - Get Incidents" `
    -Url "$FunctionAppUrl/api/XDROrchestrator?service=MDE&action=GetIncidents&tenantId=$TenantId"

# Test 4: Get All Indicators
Test-FunctionEndpoint -Name "MDE - Get Threat Indicators" `
    -Url "$FunctionAppUrl/api/XDROrchestrator?service=MDE&action=GetAllIndicators&tenantId=$TenantId"

Write-Host "`n--- Entra ID Tests ---`n" -ForegroundColor Magenta

# Test 5: Get Risky Users
Test-FunctionEndpoint -Name "Entra ID - Get Risky Users" `
    -Url "$FunctionAppUrl/api/XDROrchestrator?service=EntraID&action=GetRiskyUsers&tenantId=$TenantId"

Write-Host "`n--- Gateway Function Tests ---`n" -ForegroundColor Magenta

# Test 6: Gateway - Get Devices (simplified API)
Test-FunctionEndpoint -Name "Gateway - Get All Devices" `
    -Url "$FunctionAppUrl/api/Gateway?service=MDE&action=GetAllDevices&tenant=$TenantId"

# ============================================================================
# TEST SUMMARY
# ============================================================================

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host ""

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Test)" -ForegroundColor Red
        Write-Host "    Error: $($_.Error)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan

# Return summary
return @{
    Total = $totalCount
    Passed = $passCount
    Failed = $failCount
    Results = $testResults
}
