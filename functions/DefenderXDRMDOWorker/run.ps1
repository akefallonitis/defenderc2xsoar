using namespace System.Net

<#
.SYNOPSIS
    Microsoft Defender for Office 365 (MDO) Worker Function
    
.DESCRIPTION
    Dedicated worker for email security operations:
    - Email remediation (soft delete, hard delete, move to junk)
    - Threat submission (email, URL, file)
    - Mail forwarding rule removal
    - Mailbox investigation
    
    Returns direct HTTP response for workbook compatibility
#>

param($Request, $TriggerMetadata)

Write-Host "MDOWorker processing request"

# Extract parameters
$action = if ($Request.Query.action) { $Request.Query.action } else { $Request.Body.action }
$tenantId = if ($Request.Query.tenantId) { $Request.Query.tenantId } else { $Request.Body.tenantId }
$emailId = if ($Request.Query.emailId) { $Request.Query.emailId } else { $Request.Body.emailId }
$messageId = if ($Request.Query.messageId) { $Request.Query.messageId } else { $Request.Body.messageId }
$url = if ($Request.Query.url) { $Request.Query.url } else { $Request.Body.url }
$userId = if ($Request.Query.userId) { $Request.Query.userId } else { $Request.Body.userId }
$remediationType = if ($Request.Query.remediationType) { $Request.Query.remediationType } else { $Request.Body.remediationType }

# Get credentials
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate
if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Missing tenantId parameter"
    })
    return
}

if (-not $action) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Missing action parameter"
    })
try {
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/AuthManager.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/ValidationHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/LoggingHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge/DefenderForOffice.psm1" -ErrorAction Stop
} catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{ error = "Required module import failed: $($_.Exception.Message)" } | ConvertTo-Json
    })
    return
}
    return
}

try {
    # Authenticate to Graph API
    $token = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
    
    # Get access token (raw string for headers)
    $accessToken = $token
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    $graphBase = "https://graph.microsoft.com"
    
    # Execute action
    switch ($action.ToUpper()) {
        
        #region Email Remediation Actions (Graph Beta - NEW API)
        
        "SOFTDELETEEMAILS" {
            # Soft delete emails - Move to Deleted Items folder
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @($emailId, $messageId) | Where-Object { $_ } }
            
            if (-not $emailIds -or $emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array) or emailId"
            }
            
            $body = @{
                emailIds = $emailIds
                remediationAction = "softDelete"
            } | ConvertTo-Json
            
            # Graph Beta endpoint for email remediation
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SoftDeleteEmails"
                    tenantId = $tenantId
                    emailCount = $emailIds.Count
                    emailIds = $emailIds
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "HARDDELETEEMAILS" {
            # Hard delete emails - Permanent deletion
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @($emailId, $messageId) | Where-Object { $_ } }
            
            if (-not $emailIds -or $emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array) or emailId"
            }
            
            $body = @{
                emailIds = $emailIds
                remediationAction = "hardDelete"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "HardDeleteEmails"
                    tenantId = $tenantId
                    emailCount = $emailIds.Count
                    emailIds = $emailIds
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "MOVETOJUNK" {
            # Move emails to Junk folder - Quarantine suspected phishing
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @($emailId, $messageId) | Where-Object { $_ } }
            
            if (-not $emailIds -or $emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array) or emailId"
            }
            
            $body = @{
                emailIds = $emailIds
                remediationAction = "moveToJunk"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "MoveToJunk"
                    tenantId = $tenantId
                    emailCount = $emailIds.Count
                    emailIds = $emailIds
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "MOVETOINBOX" {
            # Move emails to Inbox - Restore false positives
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @($emailId, $messageId) | Where-Object { $_ } }
            
            if (-not $emailIds -or $emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array) or emailId"
            }
            
            $body = @{
                emailIds = $emailIds
                remediationAction = "moveToInbox"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "MoveToInbox"
                    tenantId = $tenantId
                    emailCount = $emailIds.Count
                    emailIds = $emailIds
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "MOVETODELETEDITE MS" {
            # Move emails to Deleted Items - Soft quarantine
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @($emailId, $messageId) | Where-Object { $_ } }
            
            if (-not $emailIds -or $emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array) or emailId"
            }
            
            $body = @{
                emailIds = $emailIds
                remediationAction = "moveToDeletedItems"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "MoveToDeletedItems"
                    tenantId = $tenantId
                    emailCount = $emailIds.Count
                    emailIds = $emailIds
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "BULKEMAILSEARCH" {
            # Search emails across all mailboxes (Graph v1.0 - stable)
            $searchQuery = if ($Request.Body.searchQuery) { $Request.Body.searchQuery } else { $Request.Query.searchQuery }
            $userIds = if ($Request.Body.userIds) { $Request.Body.userIds } else { @() }
            
            if ([string]::IsNullOrEmpty($searchQuery)) {
                throw "Missing required parameter: searchQuery"
            }
            
            $results = @()
            
            # If specific users provided, search their mailboxes
            if ($userIds.Count -gt 0) {
                foreach ($uid in $userIds) {
                    $uri = "$graphBase/v1.0/users/$uid/messages?`$search=`"$searchQuery`"&`$top=50"
                    $messages = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                    $results += $messages.value
                }
            } else {
                # Search all mailboxes (requires Mail.ReadWrite permission)
                $uri = "$graphBase/v1.0/users?`$top=999"
                $users = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                
                foreach ($user in $users.value) {
                    try {
                        $uri = "$graphBase/v1.0/users/$($user.id)/messages?`$search=`"$searchQuery`"&`$top=10"
                        $messages = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction SilentlyContinue
                        if ($messages.value) {
                            $results += $messages.value
                        }
                    } catch {
                        # Skip users without mailboxes
                        continue
                    }
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "BulkEmailSearch"
                    tenantId = $tenantId
                    searchQuery = $searchQuery
                    resultCount = $results.Count
                    results = $results
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "BULKEMAILDELETE" {
            # Bulk delete emails by search query (Graph v1.0 - stable)
            $emailIds = if ($Request.Body.emailIds) { $Request.Body.emailIds } else { @() }
            
            if ($emailIds.Count -eq 0) {
                throw "Missing required parameter: emailIds (array)"
            }
            
            $deletedCount = 0
            $errors = @()
            
            foreach ($msgId in $emailIds) {
                try {
                    # Extract userId from email ID (format: userId|messageId)
                    if ($msgId -match "(.+)\|(.+)") {
                        $uid = $Matches[1]
                        $mid = $Matches[2]
                    } else {
                        # Assume it's just messageId, try to find user
                        $mid = $msgId
                        $uid = $userId
                    }
                    
                    if ($uid -and $mid) {
                        $uri = "$graphBase/v1.0/users/$uid/messages/$mid"
                        Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
                        $deletedCount++
                    }
                } catch {
                    $errors += @{
                        messageId = $msgId
                        error = $_.Exception.Message
                    }
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "BulkEmailDelete"
                    tenantId = $tenantId
                    totalEmails = $emailIds.Count
                    deletedCount = $deletedCount
                    errorCount = $errors.Count
                    errors = $errors
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "ZAPPHISHING" {
            # Zero-Hour Auto Purge for phishing (Graph Beta - NEW)
            $campaignId = if ($Request.Body.campaignId) { $Request.Body.campaignId } else { $Request.Query.campaignId }
            
            if ([string]::IsNullOrEmpty($campaignId)) {
                throw "Missing required parameter: campaignId"
            }
            
            $body = @{
                campaignId = $campaignId
                zapType = "phishing"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/zapPhishing"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "ZAPPhishing"
                    tenantId = $tenantId
                    campaignId = $campaignId
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "ZAPMALWARE" {
            # Zero-Hour Auto Purge for malware (Graph Beta - NEW)
            $campaignId = if ($Request.Body.campaignId) { $Request.Body.campaignId } else { $Request.Query.campaignId }
            
            if ([string]::IsNullOrEmpty($campaignId)) {
                throw "Missing required parameter: campaignId"
            }
            
            $body = @{
                campaignId = $campaignId
                zapType = "malware"
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails/zapMalware"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "ZAPMalware"
                    tenantId = $tenantId
                    campaignId = $campaignId
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "GETANALYZEDEMAILS" {
            # Query analyzed emails (Graph Beta - NEW)
            $filter = if ($Request.Body.filter) { $Request.Body.filter } else { $Request.Query.filter }
            
            $uri = "$graphBase/beta/security/collaboration/analyzedEmails"
            if ($filter) {
                $uri += "?`$filter=$filter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetAnalyzedEmails"
                    tenantId = $tenantId
                    count = $response.value.Count
                    emails = $response.value
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        #endregion
        
        #region Threat Submission (Graph v1.0 - Stable)
        
        "SUBMITEMAILTHRE AT" {
            # Submit email threat to Microsoft (Graph v1.0 - stable)
            $recipientEmail = if ($Request.Body.recipientEmail) { $Request.Body.recipientEmail } else { $Request.Query.recipientEmail }
            $subject = if ($Request.Body.subject) { $Request.Body.subject } else { $Request.Query.subject }
            $category = if ($Request.Body.category) { $Request.Body.category } else { "phishing" }
            
            if ([string]::IsNullOrEmpty($recipientEmail)) {
                throw "Missing required parameter: recipientEmail"
            }
            
            $body = @{
                "@odata.type" = "#microsoft.graph.emailThreat"
                category = $category
                recipientEmail = $recipientEmail
            }
            
            if ($subject) { $body.subject = $subject }
            if ($messageId) { $body.internetMessageId = $messageId }
            
            $uri = "$graphBase/v1.0/security/threatSubmission/emailThreats"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SubmitEmailThreat"
                    tenantId = $tenantId
                    recipientEmail = $recipientEmail
                    category = $category
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "SUBMITURLTH REAT" {
            # Submit URL threat to Microsoft (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($url)) {
                throw "Missing required parameter: url"
            }
            
            $category = if ($Request.Body.category) { $Request.Body.category } else { "malware" }
            
            $body = @{
                "@odata.type" = "#microsoft.graph.urlThreat"
                category = $category
                url = $url
            } | ConvertTo-Json
            
            $uri = "$graphBase/v1.0/security/threatSubmission/urlThreats"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SubmitURLThreat"
                    tenantId = $tenantId
                    url = $url
                    category = $category
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "SUBMITFILETHREAT" {
            # Submit file threat to Microsoft (Graph v1.0 - stable)
            $fileName = if ($Request.Body.fileName) { $Request.Body.fileName } else { $Request.Query.fileName }
            $fileHash = if ($Request.Body.fileHash) { $Request.Body.fileHash } else { $Request.Query.fileHash }
            
            if ([string]::IsNullOrEmpty($fileName)) {
                throw "Missing required parameter: fileName"
            }
            
            $category = if ($Request.Body.category) { $Request.Body.category } else { "malware" }
            
            $body = @{
                "@odata.type" = "#microsoft.graph.fileThreat"
                category = $category
                fileName = $fileName
            }
            
            if ($fileHash) { $body.fileHash = $fileHash }
            
            $uri = "$graphBase/v1.0/security/threatSubmission/fileThreats"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SubmitFileThreat"
                    tenantId = $tenantId
                    fileName = $fileName
                    category = $category
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        #endregion
        
        #region Mail Flow & Rules (Graph v1.0 - Stable)
        
        "REMOVEMAILFORWARDINGRULES" {
            # Remove mail forwarding rules (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($userId)) {
                throw "Missing required parameter: userId"
            }
            
            $uri = "$graphBase/v1.0/users/$userId/mailFolders/inbox/messageRules"
            $rules = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $removedRules = @()
            foreach ($rule in $rules.value) {
                # Check if rule has forwarding action
                if ($rule.actions.forwardTo -or $rule.actions.forwardAsAttachmentTo -or $rule.actions.redirect) {
                    $deleteUri = "$graphBase/v1.0/users/$userId/mailFolders/inbox/messageRules/$($rule.id)"
                    Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
                    $removedRules += $rule
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "RemoveMailForwardingRules"
                    tenantId = $tenantId
                    userId = $userId
                    removedCount = $removedRules.Count
                    removedRules = $removedRules
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "GETMAILBOXFO RWARDERS" {
            # Get all users with mail forwarding configured (Graph v1.0 - stable)
            $uri = "$graphBase/v1.0/users?`$select=id,displayName,userPrincipalName,mailboxSettings&`$top=999"
            $users = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $forwarders = @()
            foreach ($user in $users.value) {
                if ($user.mailboxSettings.automaticRepliesSetting.externalAudience -or 
                    $user.mailboxSettings.forwardingSmtpAddress) {
                    $forwarders += @{
                        userId = $user.id
                        displayName = $user.displayName
                        userPrincipalName = $user.userPrincipalName
                        forwardingAddress = $user.mailboxSettings.forwardingSmtpAddress
                    }
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "GetMailboxForwarders"
                    tenantId = $tenantId
                    forwarderCount = $forwarders.Count
                    forwarders = $forwarders
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "DISABLEMAILBOXFORWARDING" {
            # Disable mailbox forwarding for specific user (Graph v1.0 - stable)
            if ([string]::IsNullOrEmpty($userId)) {
                throw "Missing required parameter: userId"
            }
            
            $body = @{
                mailboxSettings = @{
                    forwardingSmtpAddress = $null
                }
            } | ConvertTo-Json -Depth 3
            
            $uri = "$graphBase/v1.0/users/$userId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "DisableMailboxForwarding"
                    tenantId = $tenantId
                    userId = $userId
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                "SoftDeleteEmails", "HardDeleteEmails", "MoveToJunk", "MoveToInbox", "MoveToDeletedItems",
                "BulkEmailSearch", "BulkEmailDelete", "ZAPPhishing", "ZAPMalware", "GetAnalyzedEmails",
                "SubmitEmailThreat", "SubmitURLThreat", "SubmitFileThreat",
                "RemoveMailForwardingRules", "GetMailboxForwarders", "DisableMailboxForwarding"
            )
            
            throw "Unknown action: $action. Supported actions: $($supportedActions -join ', ')"
        }
    }
    
} catch {
    Write-Error $_.Exception.Message
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            action = $action
            tenantId = $tenantId
            error = $_.Exception.Message
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
}
