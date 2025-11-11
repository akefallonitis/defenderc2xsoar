# Comprehensive Service Test - All DefenderC2XSOAR Services
# Tests all 7 services with available read operations

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionKey
)

$baseUrl = "https://sentryxdr.azurewebsites.net/api/Gateway"

$allTests = @()

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "DefenderC2XSOAR - Comprehensive Service Test Suite" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Tenant: $TenantId" -ForegroundColor Gray
Write-Host "Testing: All 7 Services" -ForegroundColor Gray
Write-Host ("=" * 80) -ForegroundColor Cyan

# Test definition
$tests = @(
    @{
        Service = "MDE"
        Name = "MDE: Get All Devices"
        Action = "GetAllDevices"
        Body = @{service="MDE";action="GetAllDevices";tenantId=$TenantId}
    },
    @{
        Service = "MDE"
        Name = "MDE: Get All Incidents"
        Action = "GetIncidents"
        Body = @{service="MDE";action="GetIncidents";tenantId=$TenantId}
    },
    @{
        Service = "MDC"
        Name = "MDC: Get Security Alerts"
        Action = "GetSecurityAlerts"
        Body = @{service="MDC";action="GetSecurityAlerts";tenantId=$TenantId}
    },
    @{
        Service = "MDI"
        Name = "MDI: Get Alerts"
        Action = "GetAlerts"
        Body = @{service="MDI";action="GetAlerts";tenantId=$TenantId}
    },
    @{
        Service = "EntraID"
        Name = "EntraID: Get Risk Detections"
        Action = "GetRiskDetections"
        Body = @{service="EntraID";action="GetRiskDetections";tenantId=$TenantId;userId="test@test.com"}
    },
    @{
        Service = "Intune"
        Name = "Intune: Get Managed Devices"
        Action = "GetManagedDevices"
        Body = @{service="Intune";action="GetManagedDevices";tenantId=$TenantId}
    },
    @{
        Service = "Azure"
        Name = "Azure: Get Resource Groups"
        Action = "GetResourceGroups"
        Body = @{service="Azure";action="GetResourceGroups";tenantId=$TenantId}
    }
)

$passCount = 0
$failCount = 0

foreach ($test in $tests) {
    Write-Host "`n[$($test.Service)] Testing: $($test.Name)..." -NoNewline -ForegroundColor Yellow
    
    $bodyJson = $test.Body | ConvertTo-Json -Compress
    
    try {
        $startTime = Get-Date
        $url = "$baseUrl`?code=$FunctionKey"
        $response = Invoke-RestMethod `
            -Uri $url `
            -Method Post `
            -ContentType "application/json" `
            -Body $bodyJson `
            -TimeoutSec 30 `
            -ErrorAction Stop
        
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        if ($response.success -eq $true) {
            Write-Host " ✅ PASS ($([Math]::Round($duration, 0))ms)" -ForegroundColor Green
            $passCount++
            $testResult = @{
                Service = $test.Service
                Name = $test.Name
                Action = $test.Action
                Status = "PASS"
                Duration = [Math]::Round($duration, 0)
                DataReturned = if ($response.data) { ($response.data.PSObject.Properties.Name -join ", ") } else { "none" }
                Error = $null
            }
        } else {
            Write-Host " ⚠️ UNEXPECTED ($([Math]::Round($duration, 0))ms)" -ForegroundColor Yellow
            Write-Host "   Response: success=$($response.success)" -ForegroundColor Gray
            $failCount++
            $testResult = @{
                Service = $test.Service
                Name = $test.Name
                Action = $test.Action
                Status = "FAIL"
                Duration = [Math]::Round($duration, 0)
                DataReturned = $null
                Error = "success=false in response"
            }
        }
        
        $allTests += $testResult
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
        
        Write-Host " ❌ FAIL ($statusCode)" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkGray
        
        $failCount++
        $testResult = @{
            Service = $test.Service
            Name = $test.Name
            Action = $test.Action
            Status = "FAIL"
            Duration = [Math]::Round($duration, 0)
            DataReturned = $null
            Error = $_.Exception.Message
        }
        
        $allTests += $testResult
    }
}

# Summary
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Total Tests:  $($tests.Count)" -ForegroundColor White
Write-Host "✅ Passed:     $passCount" -ForegroundColor Green
Write-Host "❌ Failed:     $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate:    $([Math]::Round(($passCount / $tests.Count) * 100, 2))%" -ForegroundColor $(if ($passCount -eq $tests.Count) { "Green" } else { "Yellow" })

# Service breakdown
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "SERVICE BREAKDOWN" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$serviceGroups = $allTests | Group-Object -Property Service
foreach ($group in $serviceGroups) {
    $servicePassed = ($group.Group | Where-Object { $_.Status -eq "PASS" }).Count
    $serviceTotal = $group.Count
    $serviceRate = [Math]::Round(($servicePassed / $serviceTotal) * 100, 0)
    
    $statusColor = if ($serviceRate -eq 100) { "Green" } elseif ($serviceRate -gt 50) { "Yellow" } else { "Red" }
    Write-Host "$($group.Name): $servicePassed/$serviceTotal ($serviceRate%)" -ForegroundColor $statusColor
}

# Failed tests
if ($failCount -gt 0) {
    Write-Host "`n" + ("=" * 80) -ForegroundColor Red
    Write-Host "FAILED TESTS" -ForegroundColor Red
    Write-Host ("=" * 80) -ForegroundColor Red
    
    $failedTests = $allTests | Where-Object { $_.Status -eq "FAIL" }
    foreach ($failed in $failedTests) {
        Write-Host "`n❌ $($failed.Name)" -ForegroundColor Red
        Write-Host "   Service: $($failed.Service)" -ForegroundColor Gray
        Write-Host "   Action:  $($failed.Action)" -ForegroundColor Gray
        Write-Host "   Error:   $($failed.Error)" -ForegroundColor DarkRed
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "Test completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ("=" * 80) -ForegroundColor Cyan
