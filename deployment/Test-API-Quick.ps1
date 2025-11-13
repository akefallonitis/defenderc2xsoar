<#
.SYNOPSIS
    Quick Test for DefenderXDR C2 v3.0.0 API

.DESCRIPTION
    Tests key API endpoints to validate deployment

.EXAMPLE
    .\Test-API-Quick.ps1
#>

$FunctionAppUrl = "https://<your-function-app>.azurewebsites.net"
$FunctionKey = "<your-function-key>"
$TenantId = "<your-tenant-id>"

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "DefenderXDR C2 v3.0.0 - Quick API Test" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

function Test-API {
    param(
        [string]$Name,
        [string]$Service,
        [string]$Action
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  Service: $Service | Action: $Action" -ForegroundColor Gray
    
    $body = @{
        service = $Service
        action = $Action
        tenantId = $TenantId
    } | ConvertTo-Json
    
    $uri = "$FunctionAppUrl/api/Gateway?code=$FunctionKey"
    
    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType "application/json" -TimeoutSec 30
        $duration = [int](((Get-Date) - $start).TotalMilliseconds)
        
        if ($response.success -or ($response -and -not $response.error)) {
            Write-Host "  ✅ SUCCESS " -ForegroundColor Green -NoNewline
            Write-Host "($duration ms)" -ForegroundColor Gray
            
            if ($response.data) {
                if ($response.data -is [Array]) {
                    Write-Host "    Returned: $($response.data.Count) items" -ForegroundColor DarkCyan
                } else {
                    Write-Host "    Returned: Data object" -ForegroundColor DarkCyan
                }
            }
        } else {
            Write-Host "  ❌ FAILED " -ForegroundColor Red -NoNewline
            Write-Host "($duration ms)" -ForegroundColor Gray
            Write-Host "    Error: $($response.error)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ❌ EXCEPTION" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            try {
                $err = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "    Details: $($err.error.message)" -ForegroundColor Red
            }
            catch {
                Write-Host "    Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
}

# Run tests
Test-API -Name "MDE - Get Devices" -Service "MDE" -Action "GetDevices"
Test-API -Name "MDE - Get Machine Actions" -Service "MDE" -Action "GetAllActions"
Test-API -Name "MDE - Get Indicators" -Service "MDE" -Action "GetIndicators"
Test-API -Name "MDE - Get Incidents" -Service "MDE" -Action "GetIncidents"
Test-API -Name "MDE - Get Alerts" -Service "MDE" -Action "GetAlerts"

Test-API -Name "EntraID - Get Risky Users" -Service "EntraID" -Action "GetRiskyUsers"
Test-API -Name "EntraID - Get Risk Detections" -Service "EntraID" -Action "GetRiskDetections"

Test-API -Name "Intune - Get Managed Devices" -Service "Intune" -Action "GetManagedDevices"

Test-API -Name "Azure - Get Resource Groups" -Service "Azure" -Action "GetResourceGroups"
Test-API -Name "Azure - Get VMs" -Service "Azure" -Action "GetVMs"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
