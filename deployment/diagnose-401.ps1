<#
.SYNOPSIS
    Diagnose 401 Unauthorized errors from Azure Function App
    
.DESCRIPTION
    Tests various scenarios to identify why 401 errors occur
#>

param(
    [string]$FunctionAppUrl = "https://sentryxdr.azurewebsites.net",
    [string]$FunctionKey = "8rCM_tzrHgQ4cqsSQNWY91QIzs6Mt-VXreZ0UNxcGVWZAzFurPNLWQ==",
    [string]$TenantId = "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  401 Unauthorized Diagnostic Tool" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n[Test 1] Function App Health Check" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$FunctionAppUrl" -Method Get -UseBasicParsing -TimeoutSec 10
    Write-Host "  Status: $($response.StatusCode) - Function app is responding" -ForegroundColor Green
} catch {
    Write-Host "  Status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[Test 2] Gateway Endpoint - No Auth" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$FunctionAppUrl/api/Gateway" -Method Get -UseBasicParsing -TimeoutSec 10
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  Status: $statusCode" -ForegroundColor $(if ($statusCode -eq 401) { "Yellow" } else { "Red" })
    if ($statusCode -eq 401) {
        Write-Host "  This is EXPECTED - function requires auth" -ForegroundColor Gray
    }
}

Write-Host "`n[Test 3] Gateway Endpoint - With Function Key (Query String)" -ForegroundColor Yellow
try {
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
    Write-Host "  URI: $uri" -ForegroundColor Gray
    $response = Invoke-WebRequest -Uri $uri -Method Get -UseBasicParsing -TimeoutSec 10
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  Status: $statusCode" -ForegroundColor Red
    if ($statusCode -eq 401) {
        Write-Host "  ERROR: Function key is invalid or function not loaded" -ForegroundColor Red
    }
}

Write-Host "`n[Test 4] Gateway Endpoint - With Function Key (Header)" -ForegroundColor Yellow
try {
    $headers = @{
        "x-functions-key" = $FunctionKey
    }
    $response = Invoke-WebRequest -Uri "$FunctionAppUrl/api/Gateway" -Method Get -Headers $headers -UseBasicParsing -TimeoutSec 10
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  Status: $statusCode" -ForegroundColor Red
}

Write-Host "`n[Test 5] Gateway POST with Valid Payload" -ForegroundColor Yellow
try {
    $body = @{
        service = "MDE"
        action = "GetAllDevices"
        tenantId = $TenantId
    } | ConvertTo-Json
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
    $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $body -UseBasicParsing -TimeoutSec 60
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response:" -ForegroundColor Gray
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  Status: $statusCode" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get response body
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        if ($responseBody) {
            Write-Host "  Response Body:" -ForegroundColor Yellow
            $responseBody | Write-Host -ForegroundColor Gray
        }
    } catch {
        Write-Host "  No response body available" -ForegroundColor Gray
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nPossible Issues:" -ForegroundColor Yellow
Write-Host "1. Function key is incorrect or expired" -ForegroundColor Gray
Write-Host "   Solution: Regenerate key in Azure Portal -> sentryxdr -> App keys" -ForegroundColor White
Write-Host ""
Write-Host "2. Function app hasn't loaded the code yet" -ForegroundColor Gray
Write-Host "   Solution: Wait 2-3 more minutes or check Deployment Center status" -ForegroundColor White
Write-Host ""
Write-Host "3. Function code has syntax/startup errors" -ForegroundColor Gray
Write-Host "   Solution: Check Azure Portal -> sentryxdr -> Log stream for errors" -ForegroundColor White
Write-Host ""
Write-Host "4. WEBSITE_RUN_FROM_PACKAGE URL inaccessible" -ForegroundColor Gray
Write-Host "   Solution: Verify GitHub URL is accessible and package exists" -ForegroundColor White
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
