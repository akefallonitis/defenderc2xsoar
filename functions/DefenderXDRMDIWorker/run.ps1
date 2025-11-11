using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/DefenderForIdentity.psm1" -Force

# Extract parameters from request
$action = $Request.Body.action
$tenantId = $Request.Body.tenantId
$body = $Request.Body

Write-XDRLog -Level "Info" -Message "MDIWorker received request" -Data @{
    Action = $action
    TenantId = $tenantId
}

try {
    # Validate required parameters
    if ([string]::IsNullOrEmpty($action)) {
        throw "Missing required parameter: action"
    }
    
    if (-not (Test-TenantId -TenantId $tenantId)) {
        throw "Invalid or missing tenantId"
    }

    # Authenticate to Microsoft Graph
    $tokenParams = @{
        TenantId = $tenantId
        Service = "Graph"
    }
    $token = Get-OAuthToken @tokenParams
    
    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to obtain authentication token"
    }

    # Execute action
    $result = $null
    
    switch ($action) {
        "GetAlerts" {
            Write-XDRLog -Level "Info" -Message "Getting MDI security alerts"
            $alertParams = @{
                Token = $token
            }
            
            if ($body.filter) {
                $alertParams.Filter = $body.filter
            }
            if ($body.top) {
                $alertParams.Top = [int]$body.top
            }
            
            $alerts = Get-MDISecurityAlert @alertParams
            $result = @{
                count = $alerts.Count
                alerts = $alerts
            }
        }
        
        "UpdateAlert" {
            if ([string]::IsNullOrEmpty($body.alertId)) {
                throw "Missing required parameter: alertId"
            }
            if ([string]::IsNullOrEmpty($body.status)) {
                throw "Missing required parameter: status (newAlert, inProgress, resolved, dismissed)"
            }
            
            Write-XDRLog -Level "Info" -Message "Updating MDI alert status" -Data @{
                AlertId = $body.alertId
                Status = $body.status
            }
            
            $updateParams = @{
                Token = $token
                AlertId = $body.alertId
                Status = $body.status
            }
            
            if ($body.assignedTo) {
                $updateParams.AssignedTo = $body.assignedTo
            }
            if ($body.comment) {
                $updateParams.Comment = $body.comment
            }
            
            $updateResult = Update-MDIAlert @updateParams
            $result = @{
                alertId = $body.alertId
                updated = $true
                status = $body.status
            }
        }
        
        "GetLateralMovementPaths" {
            Write-XDRLog -Level "Info" -Message "Getting lateral movement paths"
            $lmpParams = @{
                Token = $token
            }
            
            if ($body.userId) {
                $lmpParams.UserId = $body.userId
            }
            
            $paths = Get-MDILateralMovementPath @lmpParams
            $result = @{
                count = $paths.Count
                paths = $paths
            }
        }
        
        "GetExposedCredentials" {
            Write-XDRLog -Level "Info" -Message "Getting exposed credentials"
            $exposedCreds = Get-MDIExposedCredentials -Token $token
            $result = @{
                count = $exposedCreds.Count
                credentials = $exposedCreds
            }
        }
        
        "GetIdentitySecureScore" {
            Write-XDRLog -Level "Info" -Message "Getting identity secure score"
            $scoreParams = @{
                Token = $token
            }
            
            $score = Get-MDIIdentitySecureScore @scoreParams
            $result = @{
                currentScore = $score.currentScore
                maxScore = $score.maxScore
                percentage = if ($score.maxScore -gt 0) { 
                    [math]::Round(($score.currentScore / $score.maxScore) * 100, 2) 
                } else { 
                    0 
                }
                controlScores = $score.controlScores
            }
        }
        
        "GetSuspiciousActivities" {
            Write-XDRLog -Level "Info" -Message "Getting suspicious activities"
            $activityParams = @{
                Token = $token
            }
            
            if ($body.userId) {
                $activityParams.UserId = $body.userId
            }
            if ($body.filter) {
                $activityParams.Filter = $body.filter
            }
            
            $activities = Get-MDISuspiciousActivities @activityParams
            $result = @{
                count = $activities.Count
                activities = $activities
            }
        }
        
        "GetHealthIssues" {
            Write-XDRLog -Level "Info" -Message "Getting MDI health issues"
            $healthParams = @{
                Token = $token
            }
            
            $healthIssues = Get-MDIHealthIssues @healthParams
            $result = @{
                count = $healthIssues.Count
                issues = $healthIssues
            }
        }
        
        "GetRecommendations" {
            Write-XDRLog -Level "Info" -Message "Getting MDI recommendations"
            $recParams = @{
                Token = $token
            }
            
            $recommendations = Get-MDIRecommendations @recParams
            $result = @{
                count = $recommendations.Count
                recommendations = $recommendations
            }
        }
        
        "GetSensitiveUsers" {
            Write-XDRLog -Level "Info" -Message "Getting sensitive users"
            $sensitiveParams = @{
                Token = $token
            }
            
            $users = Get-MDISensitiveUsers @sensitiveParams
            $result = @{
                count = $users.Count
                users = $users
            }
        }
        
        "GetAlertStatistics" {
            Write-XDRLog -Level "Info" -Message "Getting MDI alert statistics"
            $statsParams = @{
                Token = $token
            }
            
            if ($body.days) {
                $statsParams.Days = [int]$body.days
            }
            
            $stats = Get-MDIAlertStatistics @statsParams
            $result = @{
                statistics = $stats
            }
        }
        
        "GetConfiguration" {
            Write-XDRLog -Level "Info" -Message "Getting MDI configuration"
            $configParams = @{
                Token = $token
            }
            
            $config = Get-MDIConfiguration @configParams
            $result = @{
                configuration = $config
            }
        }
        
        default {
            throw "Unknown action: $action. Supported actions: GetAlerts, UpdateAlert, GetLateralMovementPaths, GetExposedCredentials, GetIdentitySecureScore, GetSuspiciousActivities, GetHealthIssues, GetRecommendations, GetSensitiveUsers, GetAlertStatistics, GetConfiguration"
        }
    }

    # Build success response
    $responseBody = @{
        success = $true
        action = $action
        tenantId = $tenantId
        result = $result
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    Write-XDRLog -Level "Info" -Message "MDIWorker completed successfully" -Data @{
        Action = $action
        Success = $true
    }

    # Return direct HTTP response for workbook compatibility
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($responseBody | ConvertTo-Json -Depth 10 -Compress)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })

} catch {
    $errorMessage = $_.Exception.Message
    Write-XDRLog -Level "Error" -Message "MDIWorker failed" -Data @{
        Action = $action
        Error = $errorMessage
    }

    $responseBody = @{
        success = $false
        action = $action
        tenantId = $tenantId
        error = $errorMessage
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($responseBody | ConvertTo-Json -Depth 10 -Compress)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
}
