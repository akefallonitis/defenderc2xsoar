# Test Specific Actions with Detailed Error Output

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionKey,
    
    [Parameter(Mandatory = $true)]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$Service = "MDE",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$AdditionalParams = @{}
)

$baseUrl = "https://sentryxdr.azurewebsites.net/api/Gateway"

# Build request body
$body = @{
    service = $Service
    action = $Action
    tenantId = $TenantId
}

# Add additional parameters
foreach ($key in $AdditionalParams.Keys) {
    $body[$key] = $AdditionalParams[$key]
}

$bodyJson = $body | ConvertTo-Json -Depth 5

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Action: $Service : $Action" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $bodyJson -ForegroundColor White

try {
    $url = "$baseUrl?code=$FunctionKey"
    $response = Invoke-WebRequest `
        -Uri $url `
        -Method Post `
        -ContentType "application/json" `
        -Body $bodyJson `
        -UseBasicParsing `
        -TimeoutSec 60
    
    Write-Host "`n✅ SUCCESS - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "`n❌ FAILED - Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get response body
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        if ($errorBody) {
            Write-Host "`nError Response Body:" -ForegroundColor Yellow
            try {
                $errorBody | ConvertFrom-Json | ConvertTo-Json -Depth 10
            } catch {
                Write-Host $errorBody
            }
        }
    } catch {
        Write-Host "Could not read error response body" -ForegroundColor Gray
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
