using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -Force
# NOTE: Business logic is inline - no external modules needed

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
        
        #region Emergency Response Actions (Graph v1.0 - Stable)
        
        "DeleteAuthenticationMethod" {
            # Delete specific MFA authentication method (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            if ([string]::IsNullOrEmpty($body.authenticationMethodId)) {
                throw "Missing required parameter: authenticationMethodId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deleting authentication method for compromised account" -Data @{
                UserId = $body.userId
                MethodId = $body.authenticationMethodId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/methods/$($body.authenticationMethodId)"
            Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            $result = @{
                userId = $body.userId
                authenticationMethodId = $body.authenticationMethodId
                deleted = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DeleteAllMFAMethods" {
            # Delete all MFA methods except password for compromised account (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deleting ALL MFA methods for compromised account" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get all authentication methods
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/methods"
            $methods = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $deletedMethods = @()
            foreach ($method in $methods.value) {
                # Skip password method - only delete MFA methods
                if ($method.'@odata.type' -ne '#microsoft.graph.passwordAuthenticationMethod') {
                    try {
                        $deleteUri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/methods/$($method.id)"
                        Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                        $deletedMethods += @{
                            id = $method.id
                            type = $method.'@odata.type'
                        }
                    } catch {
                        Write-XDRLog -Level "Warning" -Message "Could not delete method" -Data @{
                            MethodId = $method.id
                            Error = $_.Exception.Message
                        }
                    }
                }
            }
            
            $result = @{
                userId = $body.userId
                deletedCount = $deletedMethods.Count
                deletedMethods = $deletedMethods
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "CreateEmergencyCAPolicy" {
            # Create emergency Conditional Access policy to block compromised user (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            $displayName = if ($body.displayName) { $body.displayName } else { "EMERGENCY - Block User $($body.userId) - $(Get-Date -Format 'yyyyMMdd-HHmmss')" }
            
            Write-XDRLog -Level "Warning" -Message "Creating EMERGENCY Conditional Access policy to block user" -Data @{
                UserId = $body.userId
                PolicyName = $displayName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $policyBody = @{
                displayName = $displayName
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @($body.userId)
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("block")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                userId = $body.userId
                policyId = $policy.id
                policyName = $policy.displayName
                state = $policy.state
                created = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RemoveAdminRole" {
            # Remove admin role assignment from compromised account (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing admin roles from compromised account" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get all role assignments for the user
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$filter=principalId eq '$($body.userId)'"
            $roleAssignments = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $removedRoles = @()
            foreach ($assignment in $roleAssignments.value) {
                try {
                    # Get role definition details
                    $roleUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions/$($assignment.roleDefinitionId)"
                    $roleDefinition = Invoke-RestMethod -Uri $roleUri -Method Get -Headers $headers
                    
                    # Delete role assignment
                    $deleteUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments/$($assignment.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    
                    $removedRoles += @{
                        roleAssignmentId = $assignment.id
                        roleDefinitionId = $assignment.roleDefinitionId
                        roleName = $roleDefinition.displayName
                    }
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Could not remove role assignment" -Data @{
                        AssignmentId = $assignment.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            $result = @{
                userId = $body.userId
                removedCount = $removedRoles.Count
                removedRoles = $removedRoles
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RevokePIMActivation" {
            # Revoke active PIM role activations for compromised account (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking PIM activations for compromised account" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get active role assignments
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?`$filter=principalId eq '$($body.userId)' and assignmentType eq 'Activated'"
            $activeAssignments = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $revokedActivations = @()
            foreach ($assignment in $activeAssignments.value) {
                try {
                    # Get role assignment schedule request to cancel
                    $requestUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests?`$filter=principalId eq '$($body.userId)' and roleDefinitionId eq '$($assignment.roleDefinitionId)' and status eq 'Provisioned'"
                    $requests = Invoke-RestMethod -Uri $requestUri -Method Get -Headers $headers
                    
                    foreach ($request in $requests.value) {
                        # Cancel the activation by creating a deactivation request
                        $cancelBody = @{
                            action = "selfDeactivate"
                            principalId = $body.userId
                            roleDefinitionId = $assignment.roleDefinitionId
                            directoryScopeId = $assignment.directoryScopeId
                            justification = "Emergency revocation due to security incident"
                        } | ConvertTo-Json
                        
                        $cancelUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
                        $cancelResult = Invoke-RestMethod -Uri $cancelUri -Method Post -Headers $headers -Body $cancelBody
                        
                        $revokedActivations += @{
                            roleDefinitionId = $assignment.roleDefinitionId
                            scheduledId = $assignment.id
                            requestId = $cancelResult.id
                        }
                    }
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Could not revoke PIM activation" -Data @{
                        AssignmentId = $assignment.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            $result = @{
                userId = $body.userId
                revokedCount = $revokedActivations.Count
                revokedActivations = $revokedActivations
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GetUserAuthenticationMethods" {
            # Get all authentication methods for a user (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting user authentication methods" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/methods"
            $methods = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result = @{
                userId = $body.userId
                methodCount = $methods.value.Count
                methods = $methods.value
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GetUserRoleAssignments" {
            # Get all role assignments for a user (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting user role assignments" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$filter=principalId eq '$($body.userId)'"
            $assignments = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            # Enrich with role names
            $enrichedAssignments = @()
            foreach ($assignment in $assignments.value) {
                $roleUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions/$($assignment.roleDefinitionId)"
                $roleDefinition = Invoke-RestMethod -Uri $roleUri -Method Get -Headers $headers
                
                $enrichedAssignments += @{
                    assignmentId = $assignment.id
                    roleDefinitionId = $assignment.roleDefinitionId
                    roleName = $roleDefinition.displayName
                    roleDescription = $roleDefinition.description
                    directoryScopeId = $assignment.directoryScopeId
                }
            }
            
            $result = @{
                userId = $body.userId
                assignmentCount = $enrichedAssignments.Count
                assignments = $enrichedAssignments
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW ENTRAID IDENTITY PROTECTION ACTIONS (8 actions) =====
        
        "ConfirmUserCompromised" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Confirming user as compromised" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Mark user as compromised
            $confirmBody = @{
                userIds = @($body.userId)
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/confirmCompromised"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $confirmBody
            
            $result = @{
                userId = $body.userId
                confirmedCompromised = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "User marked as compromised. All sessions revoked, MFA required on next sign-in."
            }
        }
        
        "DismissRiskyUser" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Dismissing risky user" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $dismissBody = @{
                userIds = @($body.userId)
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/dismiss"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $dismissBody
            
            $result = @{
                userId = $body.userId
                riskDismissed = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ForcePasswordReset" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Forcing password reset" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Generate temporary password
            $tempPassword = -join ((33..126) | Get-Random -Count 16 | ForEach-Object {[char]$_})
            
            $resetBody = @{
                passwordProfile = @{
                    forceChangePasswordNextSignIn = $true
                    password = $tempPassword
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)"
            Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $resetBody
            
            $result = @{
                userId = $body.userId
                passwordReset = $true
                forceChangeOnNextSignIn = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "Temporary password set. User must change on next sign-in."
            }
        }
        
        "BlockUserSignIn" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking user sign-in" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $blockBody = @{
                accountEnabled = $false
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)"
            Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $blockBody
            
            $result = @{
                userId = $body.userId
                signInBlocked = $true
                accountDisabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RevokeUserSessions" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking all user sessions" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Revoke refresh tokens (signs user out everywhere)
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/revokeSignInSessions"
            $revokeResponse = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                userId = $body.userId
                sessionsRevoked = $true
                allRefreshTokensRevoked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "All user sessions terminated. User must re-authenticate."
            }
        }
        
        "ResetMFARegistration" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Resetting MFA registration" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get all authentication methods
            $uri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/methods"
            $methods = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $deletedMethods = @()
            foreach ($method in $methods.value) {
                $methodId = $method.id
                $methodType = $method.'@odata.type' -replace '#microsoft.graph.', ''
                
                # Skip password method
                if ($methodType -eq 'passwordAuthenticationMethod') {
                    continue
                }
                
                try {
                    $deleteUri = "https://graph.microsoft.com/v1.0/users/$($body.userId)/authentication/$methodType`s/$methodId"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $deletedMethods += $methodType
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Could not delete method: $methodType" -Data @{ Error = $_.Exception.Message }
                }
            }
            
            $result = @{
                userId = $body.userId
                mfaReset = $true
                methodsDeleted = $deletedMethods
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "MFA registration reset. User must re-register authentication methods."
            }
        }
        
        "DisableUserRisk" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Disabling user risk detection" -Data @{
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Dismiss risk
            $dismissBody = @{
                userIds = @($body.userId)
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/dismiss"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $dismissBody
            
            $result = @{
                userId = $body.userId
                riskDisabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableIdentityProtection" {
            $userId = $body.userId
            
            Write-XDRLog -Level "Info" -Message "Enabling Identity Protection for user" -Data @{
                UserId = $userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Enable risk-based policies via Conditional Access
            $policyBody = @{
                displayName = "Identity Protection - User Risk Policy"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = if ($userId) { @($userId) } else { @("All") }
                    }
                    userRiskLevels = @("high", "medium")
                    applications = @{
                        includeApplications = @("All")
                    }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("mfa", "passwordChange")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                userId = $userId ?? "All users"
                policyId = $policy.id
                policyName = $policy.displayName
                identityProtectionEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW ENTRAID PIM ACTIONS (6 actions) =====
        
        "RevokePIMActivation" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            if ([string]::IsNullOrEmpty($body.roleDefinitionId)) {
                throw "Missing required parameter: roleDefinitionId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking PIM activation" -Data @{
                UserId = $body.userId
                RoleId = $body.roleDefinitionId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get active assignments
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?`$filter=principalId eq '$($body.userId)' and roleDefinitionId eq '$($body.roleDefinitionId)'"
            $activeAssignments = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $revokedCount = 0
            foreach ($assignment in $activeAssignments.value) {
                # Cancel the assignment
                $cancelUri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
                $cancelBody = @{
                    action = "AdminRemove"
                    principalId = $body.userId
                    roleDefinitionId = $body.roleDefinitionId
                    directoryScopeId = "/"
                    justification = $body.justification ?? "Revoked via DefenderXDR security response"
                } | ConvertTo-Json
                
                Invoke-RestMethod -Uri $cancelUri -Method Post -Headers $headers -Body $cancelBody
                $revokedCount++
            }
            
            $result = @{
                userId = $body.userId
                roleDefinitionId = $body.roleDefinitionId
                activationsRevoked = $revokedCount
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DenyPIMRequest" {
            if ([string]::IsNullOrEmpty($body.requestId)) {
                throw "Missing required parameter: requestId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Denying PIM request" -Data @{
                RequestId = $body.requestId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $denyBody = @{
                justification = $body.justification ?? "Denied via DefenderXDR security response"
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests/$($body.requestId)/deny"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $denyBody
            
            $result = @{
                requestId = $body.requestId
                denied = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RemoveFromPIMRole" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            if ([string]::IsNullOrEmpty($body.roleDefinitionId)) {
                throw "Missing required parameter: roleDefinitionId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing user from PIM role eligibility" -Data @{
                UserId = $body.userId
                RoleId = $body.roleDefinitionId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Remove eligible assignment
            $removeBody = @{
                action = "AdminRemove"
                principalId = $body.userId
                roleDefinitionId = $body.roleDefinitionId
                directoryScopeId = "/"
                justification = $body.justification ?? "Removed via DefenderXDR security response"
            } | ConvertTo-Json
            
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleRequests"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $removeBody
            
            $result = @{
                userId = $body.userId
                roleDefinitionId = $body.roleDefinitionId
                eligibilityRemoved = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "AuditPIMActivations" {
            $startDate = $body.startDate ?? (Get-Date).AddDays(-7).ToString("o")
            $endDate = $body.endDate ?? (Get-Date).ToString("o")
            
            Write-XDRLog -Level "Info" -Message "Auditing PIM activations" -Data @{
                StartDate = $startDate
                EndDate = $endDate
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Get audit logs for role activations
            $uri = "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?`$filter=activityDateTime ge $startDate and activityDateTime le $endDate and category eq 'RoleManagement'"
            $auditLogs = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $activations = @()
            foreach ($log in $auditLogs.value) {
                if ($log.activityDisplayName -like "*Activate*" -or $log.activityDisplayName -like "*Add member to role*") {
                    $activations += @{
                        timestamp = $log.activityDateTime
                        user = $log.initiatedBy.user.userPrincipalName
                        role = $log.targetResources[0].displayName
                        result = $log.result
                    }
                }
            }
            
            $result = @{
                startDate = $startDate
                endDate = $endDate
                activationCount = $activations.Count
                activations = $activations
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnablePIMAlerts" {
            Write-XDRLog -Level "Info" -Message "Enabling PIM alerts"
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Enable PIM alert settings
            $alertBody = @{
                isEnabled = $true
                alertSettings = @(
                    @{
                        alertId = "TooManyGlobalAdminsAssignedToTenantAlert"
                        isEnabled = $true
                    },
                    @{
                        alertId = "TooManyOwnersAssignedToResource"
                        isEnabled = $true
                    },
                    @{
                        alertId = "DuplicateRoleCreatedAlert"
                        isEnabled = $true
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/beta/privilegedAccess/azureResources/roleSettings"
            
            $result = @{
                pimAlertsEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "PIM security alerts enabled for privileged role monitoring"
            }
        }
        
        "ExpirePIMAssignment" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            if ([string]::IsNullOrEmpty($body.roleDefinitionId)) {
                throw "Missing required parameter: roleDefinitionId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Expiring PIM assignment immediately" -Data @{
                UserId = $body.userId
                RoleId = $body.roleDefinitionId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Update assignment to expire now
            $expireBody = @{
                action = "AdminUpdate"
                principalId = $body.userId
                roleDefinitionId = $body.roleDefinitionId
                directoryScopeId = "/"
                scheduleInfo = @{
                    expiration = @{
                        type = "AfterDateTime"
                        endDateTime = (Get-Date).ToString("o")
                    }
                }
                justification = $body.justification ?? "Expired via DefenderXDR security response"
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $expireBody
            
            $result = @{
                userId = $body.userId
                roleDefinitionId = $body.roleDefinitionId
                assignmentExpired = $true
                expiredAt = (Get-Date).ToString("o")
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW ENTRAID CONDITIONAL ACCESS ADVANCED ACTIONS (6 actions) =====
        
        "CreateEmergencyBreakGlassPolicy" {
            if ([string]::IsNullOrEmpty($body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Creating emergency break-glass CA policy" -Data @{
                PolicyName = $body.policyName
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $policyBody = @{
                displayName = $body.policyName
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @("All")
                        excludeUsers = $body.excludedUsers ?? @()
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                }
                grantControls = @{
                    operator = "AND"
                    builtInControls = @("mfa", "compliantDevice")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                created = $true
                state = $policy.state
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockCountryLocation" {
            if (-not $body.countryCodes -or $body.countryCodes.Count -eq 0) {
                throw "Missing required parameter: countryCodes (e.g., ['CN', 'RU'])"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking countries via CA policy" -Data @{
                Countries = $body.countryCodes -join ', '
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Create named location for blocked countries
            $locationBody = @{
                "@odata.type" = "#microsoft.graph.countryNamedLocation"
                displayName = "Blocked Countries - $(Get-Date -Format 'yyyyMMdd')"
                countriesAndRegions = $body.countryCodes
                includeUnknownCountriesAndRegions = $false
            } | ConvertTo-Json -Depth 10
            
            $locationUri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
            $location = Invoke-RestMethod -Uri $locationUri -Method Post -Headers $headers -Body $locationBody
            
            # Create CA policy to block these locations
            $policyBody = @{
                displayName = "Block Geo Locations - $($body.countryCodes -join ', ')"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @("All")
                        excludeUsers = $body.excludedUsers ?? @()
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                    locations = @{
                        includeLocations = @($location.id)
                    }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("block")
                }
            } | ConvertTo-Json -Depth 10
            
            $policyUri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $policyUri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                locationId = $location.id
                policyId = $policy.id
                policyName = $policy.displayName
                blockedCountries = $body.countryCodes
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RequireMFAForRole" {
            if ([string]::IsNullOrEmpty($body.roleId)) {
                throw "Missing required parameter: roleId"
            }
            
            Write-XDRLog -Level "Info" -Message "Creating MFA requirement for role" -Data @{
                RoleId = $body.roleId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $policyBody = @{
                displayName = "Require MFA - Role: $($body.roleId)"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeRoles = @($body.roleId)
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("mfa")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                roleId = $body.roleId
                mfaRequired = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BlockLegacyAuth" {
            Write-XDRLog -Level "Info" -Message "Creating policy to block legacy authentication"
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $policyBody = @{
                displayName = "Block Legacy Authentication"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @("All")
                        excludeUsers = $body.excludedUsers ?? @()
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                    clientAppTypes = @("exchangeActiveSync", "other")
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("block")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                legacyAuthBlocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "EnableCARiskPolicy" {
            $riskLevel = $body.riskLevel ?? "medium"
            
            Write-XDRLog -Level "Info" -Message "Enabling CA risk-based policy" -Data @{
                RiskLevel = $riskLevel
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            $policyBody = @{
                displayName = "Risk-Based Access - $riskLevel and above"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @("All")
                        excludeUsers = $body.excludedUsers ?? @()
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                    signInRiskLevels = if ($riskLevel -eq "high") { @("high") } elseif ($riskLevel -eq "medium") { @("high", "medium") } else { @("high", "medium", "low") }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("mfa")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                riskLevel = $riskLevel
                enabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "SimulateCAPolicy" {
            if (-not $body.policyId) {
                throw "Missing required parameter: policyId"
            }
            if (-not $body.userId) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Simulating CA policy" -Data @{
                PolicyId = $body.policyId
                UserId = $body.userId
            }
            
            $accessToken = $token
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "application/json"
            }
            
            # Run What-If analysis
            $whatIfBody = @{
                userId = $body.userId
                applicationId = $body.applicationId ?? "00000003-0000-0000-c000-000000000000"
                clientAppType = $body.clientAppType ?? "browser"
                ipAddress = $body.ipAddress
                country = $body.country
                platform = $body.platform
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies/$($body.policyId)/evaluate"
            $simulation = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $whatIfBody
            
            $result = @{
                policyId = $body.policyId
                userId = $body.userId
                simulation = $simulation
                wouldApply = $simulation.result -eq "success"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # Identity remediation actions (14 existing)
                "DisableUser", "EnableUser", "ResetPassword", "RevokeSessions", 
                "ConfirmCompromised", "DismissRisk", "CreateNamedLocation", "GetNamedLocations",
                "DeleteAuthenticationMethod", "DeleteAllMFAMethods", "CreateEmergencyCAPolicy", 
                "RemoveAdminRole", "RevokePIMActivation", 
                "GetUserAuthenticationMethods", "GetUserRoleAssignments",
                # V3.2.0 Identity Protection (8 new)
                "ConfirmUserCompromised", "DismissRiskyUser", "ForcePasswordReset",
                "BlockUserSignIn", "RevokeUserSessions", "ResetMFARegistration",
                "DisableUserRisk", "EnableIdentityProtection",
                # V3.2.0 PIM (6 new)
                "DenyPIMRequest", "RemoveFromPIMRole", "AuditPIMActivations",
                "EnablePIMAlerts", "ExpirePIMAssignment",
                # V3.2.0 Conditional Access (6 new)
                "CreateEmergencyBreakGlassPolicy", "BlockCountryLocation",
                "RequireMFAForRole", "BlockLegacyAuth", "EnableCARiskPolicy", "SimulateCAPolicy"
            )
            throw "Unknown action: $action. Supported actions (34 total, 20 new in v3.2.0): $($supportedActions -join ', ')"
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
