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
        
        #endregion
        
        default {
            $supportedActions = @(
                # Identity remediation actions
                "DisableUser", "EnableUser", "ResetPassword", "RevokeSessions", 
                "ConfirmCompromised", "DismissRisk", "CreateNamedLocation", "GetNamedLocations",
                # Emergency response actions
                "DeleteAuthenticationMethod", "DeleteAllMFAMethods", "CreateEmergencyCAPolicy", 
                "RemoveAdminRole", "RevokePIMActivation", 
                "GetUserAuthenticationMethods", "GetUserRoleAssignments"
            )
            throw "Unknown action: $action. Supported actions (14 remediation-focused): $($supportedActions -join ', ')"
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
