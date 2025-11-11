using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/EntraID.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/EntraIDProtection.psm1" -Force

# Extract parameters from request
$action = $Request.Body.action
$tenantId = $Request.Body.tenantId
$body = $Request.Body

Write-XDRLog -Level "Info" -Message "EntraIDWorker received request" -Data @{
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
        "DisableUser" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling user account" -Data @{
                UserId = $body.userId
            }
            
            $disableParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $disableResult = Disable-EntraIDUser @disableParams
            $result = @{
                userId = $body.userId
                disabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableUser" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling user account" -Data @{
                UserId = $body.userId
            }
            
            $enableParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $enableResult = Enable-EntraIDUser @enableParams
            $result = @{
                userId = $body.userId
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ResetPassword" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Resetting user password" -Data @{
                UserId = $body.userId
            }
            
            $resetParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            if ($body.temporaryPassword) {
                $resetParams.TemporaryPassword = $body.temporaryPassword
            }
            if ($body.forceChangePasswordNextSignIn) {
                $resetParams.ForceChangePasswordNextSignIn = [bool]$body.forceChangePasswordNextSignIn
            }
            
            $resetResult = Reset-EntraIDUserPassword @resetParams
            $result = @{
                userId = $body.userId
                passwordReset = $true
                temporaryPassword = $resetResult.temporaryPassword
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RevokeSessions" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Revoking user sessions" -Data @{
                UserId = $body.userId
            }
            
            $revokeParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $revokeResult = Revoke-EntraIDUserSessions @revokeParams
            $result = @{
                userId = $body.userId
                sessionsRevoked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ConfirmCompromised" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Confirming user as compromised" -Data @{
                UserId = $body.userId
            }
            
            $confirmParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $confirmResult = Confirm-EntraIDUserCompromised @confirmParams
            $result = @{
                userId = $body.userId
                confirmedCompromised = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DismissRisk" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Dismissing user risk" -Data @{
                UserId = $body.userId
            }
            
            $dismissParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $dismissResult = Dismiss-EntraIDUserRisk @dismissParams
            $result = @{
                userId = $body.userId
                riskDismissed = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GetRiskDetections" {
            Write-XDRLog -Level "Info" -Message "Getting risk detections"
            $riskParams = @{
                Token = $token
            }
            
            if ($body.userId) {
                $riskParams.UserId = $body.userId
            }
            if ($body.filter) {
                $riskParams.Filter = $body.filter
            }
            if ($body.top) {
                $riskParams.Top = [int]$body.top
            }
            
            $detections = Get-EntraIDRiskDetections @riskParams
            $result = @{
                count = $detections.Count
                detections = $detections
            }
        }
        
        "GetRiskyUsers" {
            Write-XDRLog -Level "Info" -Message "Getting risky users"
            $riskyParams = @{
                Token = $token
            }
            
            if ($body.filter) {
                $riskyParams.Filter = $body.filter
            }
            if ($body.top) {
                $riskyParams.Top = [int]$body.top
            }
            
            $riskyUsers = Get-EntraIDRiskyUsers @riskyParams
            $result = @{
                count = $riskyUsers.Count
                users = $riskyUsers
            }
        }
        
        "CreateNamedLocation" {
            if ([string]::IsNullOrEmpty($body.displayName)) {
                throw "Missing required parameter: displayName"
            }
            if ([string]::IsNullOrEmpty($body.ipRanges)) {
                throw "Missing required parameter: ipRanges"
            }
            
            Write-XDRLog -Level "Info" -Message "Creating named location" -Data @{
                DisplayName = $body.displayName
            }
            
            $locationParams = @{
                Token = $token
                DisplayName = $body.displayName
                IpRanges = $body.ipRanges
            }
            
            if ($body.isTrusted) {
                $locationParams.IsTrusted = [bool]$body.isTrusted
            }
            
            $location = New-EntraIDNamedLocation @locationParams
            $result = @{
                locationId = $location.id
                displayName = $location.displayName
                created = $true
            }
        }
        
        "GetConditionalAccessPolicies" {
            Write-XDRLog -Level "Info" -Message "Getting conditional access policies"
            $caParams = @{
                Token = $token
            }
            
            $policies = Get-EntraIDConditionalAccessPolicies @caParams
            $result = @{
                count = $policies.Count
                policies = $policies
            }
        }
        
        "GetSignInLogs" {
            Write-XDRLog -Level "Info" -Message "Getting sign-in logs"
            $signInParams = @{
                Token = $token
            }
            
            if ($body.userId) {
                $signInParams.UserId = $body.userId
            }
            if ($body.filter) {
                $signInParams.Filter = $body.filter
            }
            if ($body.top) {
                $signInParams.Top = [int]$body.top
            }
            
            $signIns = Get-EntraIDSignInLogs @signInParams
            $result = @{
                count = $signIns.Count
                signIns = $signIns
            }
        }
        
        "GetAuditLogs" {
            Write-XDRLog -Level "Info" -Message "Getting audit logs"
            $auditParams = @{
                Token = $token
            }
            
            if ($body.filter) {
                $auditParams.Filter = $body.filter
            }
            if ($body.top) {
                $auditParams.Top = [int]$body.top
            }
            
            $auditLogs = Get-EntraIDAuditLogs @auditParams
            $result = @{
                count = $auditLogs.Count
                auditLogs = $auditLogs
            }
        }
        
        "GetUser" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting user details" -Data @{
                UserId = $body.userId
            }
            
            $userParams = @{
                Token = $token
                UserId = $body.userId
            }
            
            $user = Get-EntraIDUser @userParams
            $result = @{
                user = $user
            }
        }
        
        default {
            throw "Unknown action: $action. Supported actions: DisableUser, EnableUser, ResetPassword, RevokeSessions, ConfirmCompromised, DismissRisk, GetRiskDetections, GetRiskyUsers, CreateNamedLocation, GetConditionalAccessPolicies, GetSignInLogs, GetAuditLogs, GetUser"
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

    Write-XDRLog -Level "Info" -Message "EntraIDWorker completed successfully" -Data @{
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
    Write-XDRLog -Level "Error" -Message "EntraIDWorker failed" -Data @{
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
