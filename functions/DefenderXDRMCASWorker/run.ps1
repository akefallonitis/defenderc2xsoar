using namespace System.Net

param($Request, $TriggerMetadata)

# Import required modules
Import-Module "$PSScriptRoot/../modules/AuthManager.psm1" -Force
Import-Module "$PSScriptRoot/../modules/ValidationHelper.psm1" -Force
Import-Module "$PSScriptRoot/../modules/LoggingHelper.psm1" -Force

# Extract parameters from request
$action = $Request.Body.action
$tenantId = $Request.Body.tenantId
$body = $Request.Body

Write-XDRLog -Level "Info" -Message "MCASWorker received request" -Data @{
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

    # Authenticate to Microsoft Graph (MCAS uses Graph API)
    $tokenParams = @{
        TenantId = $tenantId
        Service = "Graph"
    }
    $token = Get-OAuthToken @tokenParams
    
    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to obtain authentication token"
    }

    # Prepare common headers
    $accessToken = $token
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    $graphBase = "https://graph.microsoft.com"

    # Execute action
    $result = $null
    
    switch ($action.ToUpper()) {
        
        #region OAuth App Management (Graph v1.0 - Stable)
        
        "REVOKEOAUTHPERMISSIONS" {
            # Revoke OAuth permissions from risky app (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId) -or [string]::IsNullOrEmpty($body.clientId)) {
                throw "Missing required parameters: userId, clientId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking OAuth permissions for risky app" -Data @{
                UserId = $body.userId
                ClientId = $body.clientId
            }
            
            # Get OAuth2 permission grants
            $uri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($body.clientId)' and principalId eq '$($body.userId)'"
            $grants = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $revokedGrants = @()
            foreach ($grant in $grants.value) {
                $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                $revokedGrants += @{
                    grantId = $grant.id
                    scope = $grant.scope
                    resourceId = $grant.resourceId
                }
            }
            
            $result = @{
                userId = $body.userId
                clientId = $body.clientId
                revokedCount = $revokedGrants.Count
                revokedGrants = $revokedGrants
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BANRISKYAPP" {
            # Ban risky OAuth application tenant-wide (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.servicePrincipalId)) {
                throw "Missing required parameter: servicePrincipalId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Banning risky OAuth application" -Data @{
                ServicePrincipalId = $body.servicePrincipalId
            }
            
            # Disable the service principal (blocks all user consent)
            $updateBody = @{
                accountEnabled = $false
                appRoleAssignmentRequired = $true
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/servicePrincipals/$($body.servicePrincipalId)"
            $updateResult = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $updateBody
            
            # Revoke all user consents
            $grantsUri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($body.servicePrincipalId)'"
            $grants = Invoke-RestMethod -Uri $grantsUri -Method Get -Headers $headers
            
            $revokedCount = 0
            foreach ($grant in $grants.value) {
                try {
                    $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $revokedCount++
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to revoke grant" -Data @{
                        GrantId = $grant.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            $result = @{
                servicePrincipalId = $body.servicePrincipalId
                banned = $true
                revokedGrantsCount = $revokedCount
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "REVOKEUSERCONSENT" {
            # Revoke all user consents for specific app (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking all user app consents" -Data @{
                UserId = $body.userId
            }
            
            # Get all OAuth2 grants for user
            $uri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=principalId eq '$($body.userId)'"
            $grants = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $revokedApps = @()
            foreach ($grant in $grants.value) {
                # Optionally filter by specific clientId if provided
                if ($body.clientId -and $grant.clientId -ne $body.clientId) {
                    continue
                }
                
                try {
                    $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $revokedApps += @{
                        grantId = $grant.id
                        clientId = $grant.clientId
                        scope = $grant.scope
                    }
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to revoke consent" -Data @{
                        GrantId = $grant.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            $result = @{
                userId = $body.userId
                revokedCount = $revokedApps.Count
                revokedApps = $revokedApps
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region Session Management (Graph v1.0 - Stable)
        
        "TERMINATEACTIVESESSION" {
            # Terminate active user sessions (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Terminating active user sessions" -Data @{
                UserId = $body.userId
            }
            
            # Revoke all sign-in sessions
            $uri = "$graphBase/v1.0/users/$($body.userId)/revokeSignInSessions"
            $revokeResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                userId = $body.userId
                sessionsTerminated = $true
                revokeResult = $revokeResult
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BLOCKUSERFROMAPP" {
            # Block user from accessing specific application (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId) -or [string]::IsNullOrEmpty($body.servicePrincipalId)) {
                throw "Missing required parameters: userId, servicePrincipalId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking user from application" -Data @{
                UserId = $body.userId
                ServicePrincipalId = $body.servicePrincipalId
            }
            
            # Remove existing app role assignments
            $assignmentsUri = "$graphBase/v1.0/users/$($body.userId)/appRoleAssignments?`$filter=resourceId eq '$($body.servicePrincipalId)'"
            $assignments = Invoke-RestMethod -Uri $assignmentsUri -Method Get -Headers $headers
            
            $removedAssignments = @()
            foreach ($assignment in $assignments.value) {
                try {
                    $deleteUri = "$graphBase/v1.0/users/$($body.userId)/appRoleAssignments/$($assignment.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $removedAssignments += $assignment.id
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to remove assignment" -Data @{
                        AssignmentId = $assignment.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            # Revoke OAuth permissions
            $grantsUri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($body.servicePrincipalId)' and principalId eq '$($body.userId)'"
            $grants = Invoke-RestMethod -Uri $grantsUri -Method Get -Headers $headers
            
            foreach ($grant in $grants.value) {
                $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
            }
            
            $result = @{
                userId = $body.userId
                servicePrincipalId = $body.servicePrincipalId
                removedAssignmentsCount = $removedAssignments.Count
                blocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "REQUIREREAUTHENTICATION" {
            # Force user to re-authenticate by revoking refresh tokens (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Requiring user re-authentication" -Data @{
                UserId = $body.userId
            }
            
            # Invalidate all refresh tokens
            $uri = "$graphBase/v1.0/users/$($body.userId)/invalidateAllRefreshTokens"
            $invalidateResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            $result = @{
                userId = $body.userId
                refreshTokensInvalidated = $true
                invalidateResult = $invalidateResult
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region File Management (Graph v1.0 - Stable)
        
        "QUARANTINECLOUDFILE" {
            # Quarantine malicious file in OneDrive/SharePoint (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.driveId) -or [string]::IsNullOrEmpty($body.fileId)) {
                throw "Missing required parameters: driveId, fileId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Quarantining cloud file" -Data @{
                DriveId = $body.driveId
                FileId = $body.fileId
            }
            
            # Move file to quarantine folder
            $quarantineFolderName = if ($body.quarantineFolder) { $body.quarantineFolder } else { "Quarantine" }
            
            # Check if quarantine folder exists, create if not
            $searchUri = "$graphBase/v1.0/drives/$($body.driveId)/root:/Quarantine"
            try {
                $quarantineFolder = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $headers
            } catch {
                # Create quarantine folder
                $createFolderBody = @{
                    name = "Quarantine"
                    folder = @{}
                    "@microsoft.graph.conflictBehavior" = "rename"
                } | ConvertTo-Json
                
                $createUri = "$graphBase/v1.0/drives/$($body.driveId)/root/children"
                $quarantineFolder = Invoke-RestMethod -Uri $createUri -Method Post -Headers $headers -Body $createFolderBody
            }
            
            # Move file to quarantine
            $moveBody = @{
                parentReference = @{
                    id = $quarantineFolder.id
                }
                name = "QUARANTINED-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($body.fileId)"
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)"
            $moveResult = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $moveBody
            
            $result = @{
                driveId = $body.driveId
                fileId = $body.fileId
                quarantineFolderId = $quarantineFolder.id
                newFileName = $moveResult.name
                quarantined = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "REMOVEEXTERNALSHARING" {
            # Remove external sharing links from file (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.driveId) -or [string]::IsNullOrEmpty($body.fileId)) {
                throw "Missing required parameters: driveId, fileId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing external file sharing" -Data @{
                DriveId = $body.driveId
                FileId = $body.fileId
            }
            
            # Get all permissions
            $uri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)/permissions"
            $permissions = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $removedPermissions = @()
            foreach ($permission in $permissions.value) {
                # Remove permissions with sharing links or external users
                if ($permission.link -or ($permission.grantedToIdentitiesV2 -and $permission.grantedToIdentitiesV2[0].user.email -notlike "*@*.$($tenantId)*")) {
                    try {
                        $deleteUri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)/permissions/$($permission.id)"
                        Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                        $removedPermissions += @{
                            permissionId = $permission.id
                            type = if ($permission.link) { "SharingLink" } else { "ExternalUser" }
                        }
                    } catch {
                        Write-XDRLog -Level "Warning" -Message "Failed to remove permission" -Data @{
                            PermissionId = $permission.id
                            Error = $_.Exception.Message
                        }
                    }
                }
            }
            
            $result = @{
                driveId = $body.driveId
                fileId = $body.fileId
                removedPermissionsCount = $removedPermissions.Count
                removedPermissions = $removedPermissions
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "APPLYSENSITIVITYLABEL" {
            # Apply sensitivity label to file (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.driveId) -or [string]::IsNullOrEmpty($body.fileId) -or [string]::IsNullOrEmpty($body.labelId)) {
                throw "Missing required parameters: driveId, fileId, labelId"
            }
            
            Write-XDRLog -Level "Info" -Message "Applying sensitivity label to file" -Data @{
                DriveId = $body.driveId
                FileId = $body.fileId
                LabelId = $body.labelId
            }
            
            # Apply sensitivity label
            $labelBody = @{
                assignmentMethod = "privileged"
                labelId = $body.labelId
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)/assignSensitivityLabel"
            $labelResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $labelBody
            
            $result = @{
                driveId = $body.driveId
                fileId = $body.fileId
                labelId = $body.labelId
                applied = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "RESTOREFROMQUARANTINE" {
            # Restore file from quarantine (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.driveId) -or [string]::IsNullOrEmpty($body.fileId) -or [string]::IsNullOrEmpty($body.targetFolderId)) {
                throw "Missing required parameters: driveId, fileId, targetFolderId"
            }
            
            Write-XDRLog -Level "Info" -Message "Restoring file from quarantine" -Data @{
                DriveId = $body.driveId
                FileId = $body.fileId
            }
            
            # Get current file name and remove quarantine prefix
            $fileUri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)"
            $file = Invoke-RestMethod -Uri $fileUri -Method Get -Headers $headers
            
            $originalName = $file.name -replace '^QUARANTINED-\d{8}-\d{6}-', ''
            
            # Move file back to target folder
            $moveBody = @{
                parentReference = @{
                    id = $body.targetFolderId
                }
                name = $originalName
            } | ConvertTo-Json
            
            $moveResult = Invoke-RestMethod -Uri $fileUri -Method Patch -Headers $headers -Body $moveBody
            
            $result = @{
                driveId = $body.driveId
                fileId = $body.fileId
                targetFolderId = $body.targetFolderId
                restoredName = $originalName
                restored = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        #region Governance & Discovery (Graph v1.0 - Stable)
        
        "BLOCKUNSANCTIONEDAPP" {
            # Block unsanctioned cloud app via Conditional Access (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.applicationId)) {
                throw "Missing required parameter: applicationId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking unsanctioned cloud app" -Data @{
                ApplicationId = $body.applicationId
            }
            
            $displayName = if ($body.policyName) { $body.policyName } else { "Block Unsanctioned App - $($body.applicationId) - $(Get-Date -Format 'yyyyMMdd-HHmmss')" }
            
            # Create Conditional Access policy to block the app
            $policyBody = @{
                displayName = $displayName
                state = "enabled"
                conditions = @{
                    applications = @{
                        includeApplications = @($body.applicationId)
                    }
                    users = @{
                        includeUsers = @("All")
                    }
                }
                grantControls = @{
                    operator = "OR"
                    builtInControls = @("block")
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                applicationId = $body.applicationId
                policyId = $policy.id
                policyName = $policy.displayName
                blocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "REMOVEAPPACCESS" {
            # Remove all user access to application (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.servicePrincipalId)) {
                throw "Missing required parameter: servicePrincipalId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing all app access" -Data @{
                ServicePrincipalId = $body.servicePrincipalId
            }
            
            # Get all app role assignments
            $assignmentsUri = "$graphBase/v1.0/servicePrincipals/$($body.servicePrincipalId)/appRoleAssignedTo"
            $assignments = Invoke-RestMethod -Uri $assignmentsUri -Method Get -Headers $headers
            
            $removedUsers = @()
            foreach ($assignment in $assignments.value) {
                try {
                    $deleteUri = "$graphBase/v1.0/servicePrincipals/$($body.servicePrincipalId)/appRoleAssignedTo/$($assignment.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $removedUsers += @{
                        principalId = $assignment.principalId
                        principalDisplayName = $assignment.principalDisplayName
                        assignmentId = $assignment.id
                    }
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to remove assignment" -Data @{
                        AssignmentId = $assignment.id
                        Error = $_.Exception.Message
                    }
                }
            }
            
            # Revoke all OAuth grants
            $grantsUri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($body.servicePrincipalId)'"
            $grants = Invoke-RestMethod -Uri $grantsUri -Method Get -Headers $headers
            
            foreach ($grant in $grants.value) {
                $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
            }
            
            $result = @{
                servicePrincipalId = $body.servicePrincipalId
                removedUsersCount = $removedUsers.Count
                removedUsers = $removedUsers
                accessRemoved = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GETOAUTHAPPS" {
            # Get all OAuth applications with user consents (Graph v1.0 - stable)
            Write-XDRLog -Level "Info" -Message "Getting OAuth applications"
            
            $uri = "$graphBase/v1.0/oauth2PermissionGrants?`$top=999"
            $grants = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            # Group by clientId and aggregate
            $apps = @{}
            foreach ($grant in $grants.value) {
                if (-not $apps.ContainsKey($grant.clientId)) {
                    $apps[$grant.clientId] = @{
                        clientId = $grant.clientId
                        grantCount = 0
                        users = @()
                        scopes = @()
                    }
                }
                $apps[$grant.clientId].grantCount++
                $apps[$grant.clientId].users += $grant.principalId
                $apps[$grant.clientId].scopes += $grant.scope
            }
            
            $result = @{
                appCount = $apps.Count
                apps = $apps.Values
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "GETUSERAPPCONSENTS" {
            # Get all app consents for specific user (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Info" -Message "Getting user app consents" -Data @{
                UserId = $body.userId
            }
            
            $uri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=principalId eq '$($body.userId)'"
            $grants = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            # Enrich with app details
            $enrichedGrants = @()
            foreach ($grant in $grants.value) {
                try {
                    $spUri = "$graphBase/v1.0/servicePrincipals/$($grant.clientId)"
                    $sp = Invoke-RestMethod -Uri $spUri -Method Get -Headers $headers
                    
                    $enrichedGrants += @{
                        grantId = $grant.id
                        clientId = $grant.clientId
                        appDisplayName = $sp.displayName
                        scope = $grant.scope
                        consentType = $grant.consentType
                    }
                } catch {
                    $enrichedGrants += @{
                        grantId = $grant.id
                        clientId = $grant.clientId
                        scope = $grant.scope
                        consentType = $grant.consentType
                    }
                }
            }
            
            $result = @{
                userId = $body.userId
                consentCount = $enrichedGrants.Count
                consents = $enrichedGrants
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW MCAS DLP ACTIONS (4 actions) =====
        
        "APPLYDLPPOLICY" {
            if ([string]::IsNullOrEmpty($body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Applying DLP policy to cloud apps" -Data @{
                PolicyName = $body.policyName
            }
            
            # Create DLP policy using Information Protection
            $policyBody = @{
                displayName = $body.policyName
                description = $body.description ?? "DLP policy for cloud app security"
                priority = $body.priority ?? 0
                mode = $body.mode ?? "Enforce"
                locations = @(
                    @{
                        name = "OneDriveForBusiness"
                        enabled = $true
                    },
                    @{
                        name = "SharePointOnline"
                        enabled = $true
                    },
                    @{
                        name = "Exchange"
                        enabled = $body.includeExchange ?? $true
                    }
                )
                rules = @(
                    @{
                        name = "Detect sensitive content"
                        conditions = @{
                            contentContainsSensitiveInformation = $body.sensitiveTypes ?? @(
                                @{ name = "Credit Card Number"; minCount = 1 }
                            )
                        }
                        actions = @(
                            @{
                                type = $body.action ?? "BlockAccess"
                            }
                        )
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/informationProtection/policy/labels"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyName = $body.policyName
                policyId = $policy.id
                applied = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BLOCKFILEDOWNLOAD" {
            if ([string]::IsNullOrEmpty($body.fileId)) {
                throw "Missing required parameter: fileId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking file download" -Data @{
                FileId = $body.fileId
            }
            
            # Get file details
            $fileUri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)"
            $file = Invoke-RestMethod -Uri $fileUri -Method Get -Headers $headers
            
            # Remove download permissions
            $permissionsUri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)/permissions"
            $permissions = Invoke-RestMethod -Uri $permissionsUri -Method Get -Headers $headers
            
            $revokedCount = 0
            foreach ($permission in $permissions.value) {
                if ($permission.roles -contains "read" -or $permission.roles -contains "write") {
                    try {
                        $deleteUri = "$graphBase/v1.0/drives/$($body.driveId)/items/$($body.fileId)/permissions/$($permission.id)"
                        Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                        $revokedCount++
                    } catch {
                        Write-XDRLog -Level "Warning" -Message "Failed to revoke permission" -Data @{ PermissionId = $permission.id }
                    }
                }
            }
            
            $result = @{
                fileId = $body.fileId
                fileName = $file.name
                downloadBlocked = $true
                permissionsRevoked = $revokedCount
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "REVOKEFILESHARING" {
            if ([string]::IsNullOrEmpty($body.fileId)) {
                throw "Missing required parameter: fileId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Revoking file sharing permissions" -Data @{
                FileId = $body.fileId
            }
            
            # Get all sharing links
            $driveId = $body.driveId ?? "root"
            $permissionsUri = "$graphBase/v1.0/drives/$driveId/items/$($body.fileId)/permissions"
            $permissions = Invoke-RestMethod -Uri $permissionsUri -Method Get -Headers $headers
            
            $revokedLinks = @()
            foreach ($permission in $permissions.value) {
                # Revoke sharing links (anonymous, organization, specific people)
                if ($permission.link) {
                    try {
                        $deleteUri = "$graphBase/v1.0/drives/$driveId/items/$($body.fileId)/permissions/$($permission.id)"
                        Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                        $revokedLinks += @{
                            permissionId = $permission.id
                            linkType = $permission.link.type
                            scope = $permission.link.scope
                        }
                    } catch {
                        Write-XDRLog -Level "Warning" -Message "Failed to revoke link" -Data @{ PermissionId = $permission.id }
                    }
                }
            }
            
            $result = @{
                fileId = $body.fileId
                driveId = $driveId
                sharingRevoked = $true
                revokedLinksCount = $revokedLinks.Count
                revokedLinks = $revokedLinks
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "DELETESENSITIVEFILE" {
            if ([string]::IsNullOrEmpty($body.fileId)) {
                throw "Missing required parameter: fileId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deleting sensitive file" -Data @{
                FileId = $body.fileId
                Reason = $body.reason
            }
            
            $driveId = $body.driveId ?? "root"
            
            # Get file metadata first
            $fileUri = "$graphBase/v1.0/drives/$driveId/items/$($body.fileId)"
            $file = Invoke-RestMethod -Uri $fileUri -Method Get -Headers $headers
            
            # Delete the file
            Invoke-RestMethod -Uri $fileUri -Method Delete -Headers $headers
            
            $result = @{
                fileId = $body.fileId
                fileName = $file.name
                fileSize = $file.size
                deleted = $true
                reason = $body.reason ?? "Sensitive content detected"
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW MCAS SHADOW IT ACTIONS (4 actions) =====
        
        "BANCLOUDAPP" {
            if ([string]::IsNullOrEmpty($body.appId)) {
                throw "Missing required parameter: appId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Banning cloud application" -Data @{
                AppId = $body.appId
            }
            
            # Disable service principal to block app access
            $disableBody = @{
                accountEnabled = $false
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/servicePrincipals/$($body.appId)"
            $app = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $disableBody
            
            # Also revoke all user consents
            $grantsUri = "$graphBase/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($body.appId)'"
            $grants = Invoke-RestMethod -Uri $grantsUri -Method Get -Headers $headers
            
            $revokedCount = 0
            foreach ($grant in $grants.value) {
                try {
                    $deleteUri = "$graphBase/v1.0/oauth2PermissionGrants/$($grant.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $revokedCount++
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to revoke grant" -Data @{ GrantId = $grant.id }
                }
            }
            
            $result = @{
                appId = $body.appId
                appName = $app.displayName
                banned = $true
                accountDisabled = $true
                consentsRevoked = $revokedCount
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "SANCTIONCLOUDAPP" {
            if ([string]::IsNullOrEmpty($body.appId)) {
                throw "Missing required parameter: appId"
            }
            
            Write-XDRLog -Level "Info" -Message "Sanctioning cloud application" -Data @{
                AppId = $body.appId
            }
            
            # Enable service principal
            $enableBody = @{
                accountEnabled = $true
                tags = @("WindowsAzureActiveDirectoryIntegratedApp", "Sanctioned")
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/servicePrincipals/$($body.appId)"
            $app = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $enableBody
            
            $result = @{
                appId = $body.appId
                appName = $app.displayName
                sanctioned = $true
                accountEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BLOCKAPPCATEGORY" {
            if ([string]::IsNullOrEmpty($body.category)) {
                throw "Missing required parameter: category"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking app category" -Data @{
                Category = $body.category
            }
            
            # Get all service principals with specific tag/category
            $uri = "$graphBase/v1.0/servicePrincipals?`$filter=tags/any(t:t eq '$($body.category)')"
            $apps = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $blockedApps = @()
            foreach ($app in $apps.value) {
                try {
                    $disableBody = @{ accountEnabled = $false } | ConvertTo-Json
                    $updateUri = "$graphBase/v1.0/servicePrincipals/$($app.id)"
                    Invoke-RestMethod -Uri $updateUri -Method Patch -Headers $headers -Body $disableBody
                    $blockedApps += @{
                        appId = $app.id
                        appName = $app.displayName
                    }
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to block app" -Data @{ AppId = $app.id }
                }
            }
            
            $result = @{
                category = $body.category
                appsFound = $apps.value.Count
                appsBlocked = $blockedApps.Count
                blockedApps = $blockedApps
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ENABLEAPPGOVERNANCE" {
            Write-XDRLog -Level "Info" -Message "Enabling app governance policies"
            
            # Create app governance policy
            $policyBody = @{
                displayName = "App Governance - Risk Detection"
                description = "Automated app risk detection and governance"
                isEnabled = $true
                conditions = @{
                    riskScore = @{
                        minimumScore = $body.minimumRiskScore ?? 50
                    }
                    permissions = @{
                        highRiskPermissions = $body.monitorPermissions ?? @("Mail.ReadWrite", "Files.ReadWrite.All")
                    }
                }
                actions = @{
                    notifyAdmins = $true
                    disableApp = $body.autoDisable ?? $false
                    requireJustification = $true
                }
            } | ConvertTo-Json -Depth 10
            
            # Use beta endpoint for app governance
            $uri = "$graphBase/beta/security/appGovernancePolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                governanceEnabled = $true
                autoDisable = $body.autoDisable ?? $false
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        # ===== V3.2.0 NEW MCAS SESSION POLICY ACTIONS (4 actions) =====
        
        "CREATESESSIONPOLICY" {
            if ([string]::IsNullOrEmpty($body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Creating session control policy" -Data @{
                PolicyName = $body.policyName
            }
            
            # Create Conditional Access session control policy
            $policyBody = @{
                displayName = $body.policyName
                state = "enabled"
                conditions = @{
                    applications = @{
                        includeApplications = $body.applications ?? @("All")
                    }
                    users = @{
                        includeUsers = $body.users ?? @("All")
                    }
                    locations = @{
                        includeLocations = $body.locations ?? @("All")
                    }
                }
                sessionControls = @{
                    cloudAppSecurity = @{
                        cloudAppSecurityType = $body.controlType ?? "monitorOnly"
                        isEnabled = $true
                    }
                    signInFrequency = @{
                        value = $body.signInFrequency ?? 1
                        type = "hours"
                        isEnabled = $true
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                controlType = $body.controlType ?? "monitorOnly"
                created = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "BLOCKDOWNLOADSESSION" {
            if ([string]::IsNullOrEmpty($body.sessionId)) {
                throw "Missing required parameter: sessionId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking downloads in session" -Data @{
                SessionId = $body.sessionId
            }
            
            # Create session policy to block downloads
            $policyBody = @{
                displayName = "Block Downloads - Session $($body.sessionId)"
                state = "enabled"
                sessionControls = @{
                    cloudAppSecurity = @{
                        cloudAppSecurityType = "blockDownloads"
                        isEnabled = $true
                    }
                }
                conditions = @{
                    applications = @{
                        includeApplications = $body.applications ?? @("All")
                    }
                    users = @{
                        includeUsers = @($body.userId)
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                sessionId = $body.sessionId
                policyId = $policy.id
                downloadsBlocked = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "ENABLEMONITORONLY" {
            if ([string]::IsNullOrEmpty($body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Enabling monitor-only session policy" -Data @{
                PolicyName = $body.policyName
            }
            
            # Create monitor-only session policy
            $policyBody = @{
                displayName = $body.policyName
                state = "enabled"
                conditions = @{
                    applications = @{
                        includeApplications = $body.applications ?? @("All")
                    }
                    users = @{
                        includeUsers = $body.users ?? @("All")
                    }
                }
                sessionControls = @{
                    cloudAppSecurity = @{
                        cloudAppSecurityType = "monitorOnly"
                        isEnabled = $true
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                policyId = $policy.id
                policyName = $policy.displayName
                monitorOnlyEnabled = $true
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        "FORCEREAUTHENTICATION" {
            if ([string]::IsNullOrEmpty($body.userId)) {
                throw "Missing required parameter: userId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Forcing re-authentication" -Data @{
                UserId = $body.userId
            }
            
            # Revoke refresh tokens to force re-auth
            $uri = "$graphBase/v1.0/users/$($body.userId)/revokeSignInSessions"
            $revoke = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
            
            # Create session policy requiring immediate re-auth
            $policyBody = @{
                displayName = "Force Re-auth - $($body.userId)"
                state = "enabled"
                conditions = @{
                    users = @{
                        includeUsers = @($body.userId)
                    }
                    applications = @{
                        includeApplications = @("All")
                    }
                }
                sessionControls = @{
                    signInFrequency = @{
                        value = 0
                        type = "hours"
                        isEnabled = $true
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $policyUri = "$graphBase/v1.0/identity/conditionalAccess/policies"
            $policy = Invoke-RestMethod -Uri $policyUri -Method Post -Headers $headers -Body $policyBody
            
            $result = @{
                userId = $body.userId
                sessionsRevoked = $true
                policyCreated = $true
                policyId = $policy.id
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # OAuth Management (3 existing)
                "RevokeOAuthPermissions", "BanRiskyApp", "RevokeUserConsent",
                # Session Management (3 existing)
                "TerminateActiveSession", "BlockUserFromApp", "RequireReAuthentication",
                # File Management (4 existing)
                "QuarantineCloudFile", "RemoveExternalSharing", "ApplySensitivityLabel", "RestoreFromQuarantine",
                # Governance & Discovery (4 existing)
                "BlockUnsanctionedApp", "RemoveAppAccess", "GetOAuthApps", "GetUserAppConsents",
                # V3.2.0 DLP (4 new)
                "ApplyDLPPolicy", "BlockFileDownload", "RevokeFileSharing", "DeleteSensitiveFile",
                # V3.2.0 Shadow IT (4 new)
                "BanCloudApp", "SanctionCloudApp", "BlockAppCategory", "EnableAppGovernance",
                # V3.2.0 Session Policy (4 new)
                "CreateSessionPolicy", "BlockDownloadSession", "EnableMonitorOnly", "ForceReAuthentication"
            )
            throw "Unknown action: $action. Supported actions (26 total, 12 new in v3.2.0): $($supportedActions -join ', ')"
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

    Write-XDRLog -Level "Info" -Message "MCASWorker completed successfully" -Data @{
        Action = $action
        Success = $true
    }

    # Return HTTP response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($responseBody | ConvertTo-Json -Depth 10 -Compress)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })

} catch {
    $errorMessage = $_.Exception.Message
    Write-XDRLog -Level "Error" -Message "MCASWorker failed" -Data @{
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
