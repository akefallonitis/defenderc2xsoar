using namespace System.Net

<#
.SYNOPSIS
    Microsoft Defender for Cloud (MDC) Worker Function
    
.DESCRIPTION
    Dedicated worker for cloud security operations.
    Returns direct HTTP response for workbook compatibility.
#>

param($Request, $TriggerMetadata)

Write-Host "MDCWorker processing request"

# Extract parameters
$action = if ($Request.Query.action) { $Request.Query.action } else { $Request.Body.action }
$tenantId = if ($Request.Query.tenantId) { $Request.Query.tenantId } else { $Request.Body.tenantId }
$subscriptionId = if ($Request.Query.subscriptionId) { $Request.Query.subscriptionId } else { $Request.Body.subscriptionId }
$alertId = if ($Request.Query.alertId) { $Request.Query.alertId } else { $Request.Body.alertId }
$status = if ($Request.Query.status) { $Request.Query.status } else { $Request.Body.status }
$filter = if ($Request.Query.filter) { $Request.Query.filter } else { $Request.Body.filter }
$defenderPlan = if ($Request.Query.defenderPlan) { $Request.Query.defenderPlan } else { $Request.Body.defenderPlan }

$appId = $env:APPID
$secretId = $env:SECRETID

if (-not $tenantId -or -not $subscriptionId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Missing tenantId or subscriptionId"
    })
    return
}

try {
    $token = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "AzureRM"
    
    switch ($action) {
        "GetSecurityAlerts" {
            $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
            $alerts = Get-MDCSecurityAlerts -Token $token -SubscriptionId $subscriptionId @filterParam
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetSecurityAlerts"
                    count = $alerts.Count
                    alerts = $alerts
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 10
            })
        }
        
        "UpdateSecurityAlert" {
            if (-not $alertId -or -not $status) { throw "AlertId and status required" }
            $response = Update-MDCSecurityAlert -Token $token -SubscriptionId $subscriptionId -AlertId $alertId -Status $status
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "UpdateSecurityAlert"
                    alertId = $alertId
                    status = $status
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "GetRecommendations" {
            $recommendations = Get-MDCSecurityRecommendations -Token $token -SubscriptionId $subscriptionId
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetRecommendations"
                    count = $recommendations.Count
                    recommendations = $recommendations
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 10
            })
        }
        
        "GetSecureScore" {
            $secureScore = Get-MDCSecureScore -Token $token -SubscriptionId $subscriptionId
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetSecureScore"
                    secureScore = $secureScore
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "EnableDefenderPlan" {
            if (-not $defenderPlan) { throw "DefenderPlan required" }
            $response = Enable-MDCDefenderPlan -Token $token -SubscriptionId $subscriptionId -PlanName $defenderPlan
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "EnableDefenderPlan"
                    plan = $defenderPlan
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "GetDefenderPlans" {
            $plans = Get-MDCDefenderPlans -Token $token -SubscriptionId $subscriptionId
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetDefenderPlans"
                    plans = $plans
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 10
            })
        }
        
        default {
            throw "Unknown action: $action"
        }
    }
    
} catch {
    Write-Error $_.Exception.Message
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            action = $action
            error = $_.Exception.Message
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
}
