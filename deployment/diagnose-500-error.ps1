# Diagnose 500 Error from Gateway

Write-Host "Diagnosing 500 Internal Server Error..." -ForegroundColor Cyan

# Test 1: Direct Orchestrator call (if accessible)
Write-Host "`n[Test 1] Testing direct Orchestrator access..." -ForegroundColor Yellow
$body = @{
    service = "MDE"
    action = "GetAllDevices"
    tenantId = "a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest `
        -Uri "https://sentryxdr.azurewebsites.net/api/DefenderXDROrchestrator?code=YOUR_FUNCTION_KEY_HERE" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing
    
    Write-Host "✅ Orchestrator accessible! Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Orchestrator Status: $statusCode" -ForegroundColor Red
    
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        if ($errorBody) {
            Write-Host "Error Response:" -ForegroundColor Yellow
            $errorBody | ConvertFrom-Json | ConvertTo-Json -Depth 5
        }
    } catch {
        Write-Host "Raw error: $errorBody" -ForegroundColor Red
    }
}

# Test 2: Simple health check
Write-Host "`n[Test 2] Testing function app health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "https://sentryxdr.azurewebsites.net/" -UseBasicParsing
    Write-Host "✅ Function app responding: $($health.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Function app not responding" -ForegroundColor Red
}

# Test 3: Check if modules are loading
Write-Host "`n[Test 3] Testing Gateway with minimal payload..." -ForegroundColor Yellow
$minimalBody = '{"service":"MDE","action":"GetAllDevices","tenantId":"a92a42cd-bf8c-46ba-aa4e-64cbc9e030d9"}'

try {
    $response = Invoke-WebRequest `
        -Uri "https://sentryxdr.azurewebsites.net/api/Gateway?code=YOUR_FUNCTION_KEY_HERE" `
        -Method Post `
        -ContentType "application/json" `
        -Body $minimalBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    Write-Host "✅ Gateway working! Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Gateway Status: $statusCode" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS COMPLETE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "`nPossible issues:" -ForegroundColor Yellow
Write-Host "1. Orchestrator route not registered (check function.json)" -ForegroundColor Gray
Write-Host "2. Gateway can't call Orchestrator internally (authentication)" -ForegroundColor Gray
Write-Host "3. Missing environment variables (APPID, SECRETID, WEBSITE_HOSTNAME)" -ForegroundColor Gray
Write-Host "4. Module import failures in Orchestrator" -ForegroundColor Gray
Write-Host "5. Token acquisition failing" -ForegroundColor Gray
