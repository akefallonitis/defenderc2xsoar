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
    Import-Module "$PSScriptRoot/../modules/AuthManager.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/ValidationHelper.psm1" -ErrorAction Stop
    Import-Module "$PSScriptRoot/../modules/LoggingHelper.psm1" -ErrorAction Stop
    # NOTE: Business logic is inline - no external module needed
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
        
        # ===== V3.2.0 NEW MDO QUARANTINE MANAGEMENT ACTIONS (5 actions) =====
        
        "RELEASEQUARANTINEEMAIL" {
            if ([string]::IsNullOrEmpty($Request.Body.quarantineMessageId)) {
                throw "Missing required parameter: quarantineMessageId"
            }
            
            Write-XDRLog -Level "Info" -Message "Releasing quarantined email" -Data @{
                QuarantineMessageId = $Request.Body.quarantineMessageId
            }
            
            $releaseBody = @{
                releaseToAll = $Request.Body.releaseToAll ?? $false
            } | ConvertTo-Json
            
            $uri = "$graphBase/beta/security/collaboration/quarantine/emailMessages/$($Request.Body.quarantineMessageId)/release"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "ReleaseQuarantineEmail"
                    tenantId = $tenantId
                    quarantineMessageId = $Request.Body.quarantineMessageId
                    releaseToAll = $Request.Body.releaseToAll ?? $false
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "DELETEQUARANTINEEMAIL" {
            if ([string]::IsNullOrEmpty($Request.Body.quarantineMessageId)) {
                throw "Missing required parameter: quarantineMessageId"
            }
            
            Write-XDRLog -Level "Warning" -Message "Deleting quarantined email" -Data @{
                QuarantineMessageId = $Request.Body.quarantineMessageId
            }
            
            $uri = "$graphBase/beta/security/collaboration/quarantine/emailMessages/$($Request.Body.quarantineMessageId)"
            Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "DeleteQuarantineEmail"
                    tenantId = $tenantId
                    quarantineMessageId = $Request.Body.quarantineMessageId
                    deleted = $true
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "BULKRELEASEQUARANTINE" {
            if (-not $Request.Body.quarantineMessageIds -or $Request.Body.quarantineMessageIds.Count -eq 0) {
                throw "Missing required parameter: quarantineMessageIds (array)"
            }
            
            Write-XDRLog -Level "Info" -Message "Bulk releasing quarantined emails" -Data @{
                MessageCount = $Request.Body.quarantineMessageIds.Count
            }
            
            $released = @()
            $failed = @()
            
            foreach ($qId in $Request.Body.quarantineMessageIds) {
                try {
                    $releaseBody = @{ releaseToAll = $false } | ConvertTo-Json
                    $uri = "$graphBase/beta/security/collaboration/quarantine/emailMessages/$qId/release"
                    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseBody
                    $released += $qId
                } catch {
                    $failed += @{
                        quarantineMessageId = $qId
                        error = $_.Exception.Message
                    }
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "BulkReleaseQuarantine"
                    tenantId = $tenantId
                    releasedCount = $released.Count
                    failedCount = $failed.Count
                    released = $released
                    failed = $failed
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "EXPORTQUARANTINEREPORT" {
            $startDate = $Request.Body.startDate ?? (Get-Date).AddDays(-7).ToString("o")
            $endDate = $Request.Body.endDate ?? (Get-Date).ToString("o")
            
            Write-XDRLog -Level "Info" -Message "Exporting quarantine report" -Data @{
                StartDate = $startDate
                EndDate = $endDate
            }
            
            $uri = "$graphBase/beta/security/collaboration/quarantine/emailMessages?`$filter=receivedDateTime ge $startDate and receivedDateTime le $endDate"
            $quarantinedEmails = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $report = @{
                startDate = $startDate
                endDate = $endDate
                totalQuarantined = $quarantinedEmails.value.Count
                byThreatType = @{}
                byAction = @{}
            }
            
            foreach ($email in $quarantinedEmails.value) {
                $threatType = $email.threatType ?? "Unknown"
                if (-not $report.byThreatType.ContainsKey($threatType)) {
                    $report.byThreatType[$threatType] = 0
                }
                $report.byThreatType[$threatType]++
                
                $action = $email.quarantineReason ?? "Unknown"
                if (-not $report.byAction.ContainsKey($action)) {
                    $report.byAction[$action] = 0
                }
                $report.byAction[$action]++
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "ExportQuarantineReport"
                    tenantId = $tenantId
                    report = $report
                    messages = $quarantinedEmails.value
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "UPDATEQUARANTINEPOLICY" {
            if ([string]::IsNullOrEmpty($Request.Body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Updating quarantine policy" -Data @{
                PolicyName = $Request.Body.policyName
            }
            
            $policyBody = @{
                displayName = $Request.Body.policyName
                endUserSpamNotificationFrequency = $Request.Body.notificationFrequency ?? 3
                endUserSpamNotificationLimit = $Request.Body.notificationLimit ?? 0
                adminNotificationEmailAddresses = $Request.Body.adminEmails ?? @()
            } | ConvertTo-Json -Depth 10
            
            # Use Security & Compliance PowerShell endpoint
            $uri = "$graphBase/beta/security/collaboration/quarantine/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "UpdateQuarantinePolicy"
                    tenantId = $tenantId
                    policyName = $Request.Body.policyName
                    policyId = $policy.id
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        # ===== V3.2.0 NEW MDO ADVANCED EMAIL ACTIONS (5 actions) =====
        
        "BLOCKSENDERDOMAIN" {
            if ([string]::IsNullOrEmpty($Request.Body.domain)) {
                throw "Missing required parameter: domain"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking sender domain" -Data @{
                Domain = $Request.Body.domain
            }
            
            # Add to tenant block list
            $blockBody = @{
                "@odata.type" = "#microsoft.graph.security.tenantAllowOrBlockListBlockEntry"
                value = $Request.Body.domain
                listType = "sender"
                action = "block"
                notes = $Request.Body.reason ?? "Blocked via DefenderXDR automation"
                expirationDateTime = $Request.Body.expirationDate ?? (Get-Date).AddDays(30).ToString("o")
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/inboundFlow/tenantAllowBlockList/entries"
            $blockEntry = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $blockBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "BlockSenderDomain"
                    tenantId = $tenantId
                    domain = $Request.Body.domain
                    blockEntryId = $blockEntry.id
                    expiresAt = $blockEntry.expirationDateTime
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "ADDSAFESENDER" {
            if ([string]::IsNullOrEmpty($Request.Body.sender)) {
                throw "Missing required parameter: sender (email or domain)"
            }
            
            Write-XDRLog -Level "Info" -Message "Adding safe sender" -Data @{
                Sender = $Request.Body.sender
            }
            
            $allowBody = @{
                "@odata.type" = "#microsoft.graph.security.tenantAllowOrBlockListAllowEntry"
                value = $Request.Body.sender
                listType = "sender"
                action = "allow"
                notes = $Request.Body.reason ?? "Allowed via DefenderXDR automation"
                expirationDateTime = $Request.Body.expirationDate ?? (Get-Date).AddDays(30).ToString("o")
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/inboundFlow/tenantAllowBlockList/entries"
            $allowEntry = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $allowBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "AddSafeSender"
                    tenantId = $tenantId
                    sender = $Request.Body.sender
                    allowEntryId = $allowEntry.id
                    expiresAt = $allowEntry.expirationDateTime
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "REMOVESAFESENDER" {
            if ([string]::IsNullOrEmpty($Request.Body.entryId)) {
                throw "Missing required parameter: entryId"
            }
            
            Write-XDRLog -Level "Info" -Message "Removing safe sender entry" -Data @{
                EntryId = $Request.Body.entryId
            }
            
            $uri = "$graphBase/beta/security/collaboration/inboundFlow/tenantAllowBlockList/entries/$($Request.Body.entryId)"
            Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "RemoveSafeSender"
                    tenantId = $tenantId
                    entryId = $Request.Body.entryId
                    removed = $true
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "UPDATESPAMPOLICY" {
            if ([string]::IsNullOrEmpty($Request.Body.policyName)) {
                throw "Missing required parameter: policyName"
            }
            
            Write-XDRLog -Level "Info" -Message "Updating spam filter policy" -Data @{
                PolicyName = $Request.Body.policyName
            }
            
            $policyBody = @{
                displayName = $Request.Body.policyName
                spamAction = $Request.Body.spamAction ?? "MoveToJmf"
                highConfidenceSpamAction = $Request.Body.highConfidenceSpamAction ?? "Quarantine"
                phishSpamAction = $Request.Body.phishSpamAction ?? "Quarantine"
                bulkSpamAction = $Request.Body.bulkSpamAction ?? "MoveToJmf"
                bulkThreshold = $Request.Body.bulkThreshold ?? 7
                markAsSpamBulkMail = $true
                increaseScopeOnBulkMail = $true
                enableEndUserSpamNotifications = $Request.Body.enableNotifications ?? $true
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/inboundFlow/spamFilterPolicies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "UpdateSpamPolicy"
                    tenantId = $tenantId
                    policyName = $Request.Body.policyName
                    policyId = $policy.id
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "ENABLEATPSAFEATTACHMENTS" {
            Write-XDRLog -Level "Info" -Message "Enabling ATP Safe Attachments"
            
            $policyBody = @{
                displayName = "ATP Safe Attachments - Global"
                action = $Request.Body.action ?? "Block"
                redirect = $Request.Body.redirect ?? $false
                redirectAddress = $Request.Body.redirectAddress
                enableForInternalSenders = $Request.Body.enableInternal ?? $true
                scanTimeout = $Request.Body.scanTimeout ?? 30
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/attachmentProtection/policies"
            $policy = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $policyBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "EnableATPSafeAttachments"
                    tenantId = $tenantId
                    policyId = $policy.id
                    protectionEnabled = $true
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        # ===== V3.2.0 NEW MDO PHISHING RESPONSE ACTIONS (5 actions) =====
        
        "REPORTPHISHINGCAMPAIGN" {
            if ([string]::IsNullOrEmpty($Request.Body.campaignName)) {
                throw "Missing required parameter: campaignName"
            }
            
            Write-XDRLog -Level "Warning" -Message "Reporting phishing campaign" -Data @{
                CampaignName = $Request.Body.campaignName
            }
            
            $campaignBody = @{
                name = $Request.Body.campaignName
                description = $Request.Body.description
                threatType = "phishing"
                indicators = $Request.Body.indicators ?? @()
                severity = $Request.Body.severity ?? "high"
                firstSeenDateTime = $Request.Body.firstSeen ?? (Get-Date).ToString("o")
                affectedUsersCount = $Request.Body.affectedUsers ?? 0
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/campaigns"
            $campaign = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $campaignBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "ReportPhishingCampaign"
                    tenantId = $tenantId
                    campaignName = $Request.Body.campaignName
                    campaignId = $campaign.id
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "BLOCKPHISHINGURL" {
            if ([string]::IsNullOrEmpty($Request.Body.url)) {
                throw "Missing required parameter: url"
            }
            
            Write-XDRLog -Level "Warning" -Message "Blocking phishing URL" -Data @{
                URL = $Request.Body.url
            }
            
            $blockBody = @{
                "@odata.type" = "#microsoft.graph.security.tenantAllowOrBlockListBlockEntry"
                value = $Request.Body.url
                listType = "url"
                action = "block"
                notes = $Request.Body.reason ?? "Phishing URL blocked via automation"
                expirationDateTime = $Request.Body.expirationDate ?? (Get-Date).AddDays(90).ToString("o")
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/collaboration/inboundFlow/tenantAllowBlockList/entries"
            $blockEntry = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $blockBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "BlockPhishingURL"
                    tenantId = $tenantId
                    url = $Request.Body.url
                    blockEntryId = $blockEntry.id
                    expiresAt = $blockEntry.expirationDateTime
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "REMOVEPHISHINGEMAILS" {
            if ([string]::IsNullOrEmpty($Request.Body.subject) -and [string]::IsNullOrEmpty($Request.Body.sender)) {
                throw "Missing required parameter: subject or sender"
            }
            
            Write-XDRLog -Level "Warning" -Message "Removing phishing emails" -Data @{
                Subject = $Request.Body.subject
                Sender = $Request.Body.sender
            }
            
            # Build search filter
            $filterParts = @()
            if ($Request.Body.subject) {
                $filterParts += "subject eq '$($Request.Body.subject)'"
            }
            if ($Request.Body.sender) {
                $filterParts += "senderAddress eq '$($Request.Body.sender)'"
            }
            $filter = $filterParts -join " and "
            
            # Search for matching emails
            $searchUri = "$graphBase/beta/security/collaboration/analyzedEmails?`$filter=$filter"
            $emails = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $headers
            
            # Hard delete matching emails
            $deletedCount = 0
            foreach ($email in $emails.value) {
                try {
                    $deleteBody = @{
                        emailIds = @($email.id)
                        remediationAction = "hardDelete"
                    } | ConvertTo-Json
                    
                    $remediateUri = "$graphBase/beta/security/collaboration/analyzedEmails/remediate"
                    Invoke-RestMethod -Uri $remediateUri -Method Post -Headers $headers -Body $deleteBody
                    $deletedCount++
                } catch {
                    Write-XDRLog -Level "Warning" -Message "Failed to delete email" -Data @{ EmailId = $email.id; Error = $_.Exception.Message }
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "RemovePhishingEmails"
                    tenantId = $tenantId
                    subject = $Request.Body.subject
                    sender = $Request.Body.sender
                    foundCount = $emails.value.Count
                    deletedCount = $deletedCount
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "TRACEEMAILPATH" {
            if ([string]::IsNullOrEmpty($Request.Body.messageId)) {
                throw "Missing required parameter: messageId"
            }
            
            Write-XDRLog -Level "Info" -Message "Tracing email delivery path" -Data @{
                MessageId = $Request.Body.messageId
            }
            
            # Get message trace
            $startDate = $Request.Body.startDate ?? (Get-Date).AddDays(-7).ToString("o")
            $endDate = $Request.Body.endDate ?? (Get-Date).ToString("o")
            
            $uri = "$graphBase/beta/security/collaboration/messageTrace?`$filter=messageId eq '$($Request.Body.messageId)' and receivedDateTime ge $startDate and receivedDateTime le $endDate"
            $trace = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $traceDetails = @()
            foreach ($message in $trace.value) {
                $traceDetails += @{
                    recipient = $message.recipientAddress
                    status = $message.status
                    deliveryAction = $message.action
                    timestamp = $message.receivedDateTime
                    fromIP = $message.fromIP
                    size = $message.size
                }
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "TraceEmailPath"
                    tenantId = $tenantId
                    messageId = $Request.Body.messageId
                    recipientCount = $traceDetails.Count
                    trace = $traceDetails
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "SIMULATEPHISHING" {
            if ([string]::IsNullOrEmpty($Request.Body.campaignName)) {
                throw "Missing required parameter: campaignName"
            }
            if (-not $Request.Body.targetUsers -or $Request.Body.targetUsers.Count -eq 0) {
                throw "Missing required parameter: targetUsers (array)"
            }
            
            Write-XDRLog -Level "Info" -Message "Creating phishing simulation campaign" -Data @{
                CampaignName = $Request.Body.campaignName
                TargetUserCount = $Request.Body.targetUsers.Count
            }
            
            $simulationBody = @{
                displayName = $Request.Body.campaignName
                description = $Request.Body.description ?? "Phishing awareness training simulation"
                payloadDeliveryPlatform = $Request.Body.platform ?? "email"
                target = @{
                    type = "addressBook"
                    addressBookAccountTargets = $Request.Body.targetUsers
                }
                payload = @{
                    phishingUrl = $Request.Body.phishingUrl ?? "https://contoso.com/phish"
                    simulatedFromUser = $Request.Body.fromUser ?? "security@contoso.com"
                    subject = $Request.Body.subject ?? "Urgent: Password Reset Required"
                }
                simulationAutomationId = $Request.Body.automationId
                launchDateTime = $Request.Body.launchDate ?? (Get-Date).AddMinutes(30).ToString("o")
                completionDateTime = $Request.Body.completionDate ?? (Get-Date).AddDays(7).ToString("o")
            } | ConvertTo-Json -Depth 10
            
            $uri = "$graphBase/beta/security/attackSimulation/simulations"
            $simulation = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $simulationBody
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SimulatePhishing"
                    tenantId = $tenantId
                    campaignName = $Request.Body.campaignName
                    simulationId = $simulation.id
                    targetUserCount = $Request.Body.targetUsers.Count
                    launchDateTime = $simulation.launchDateTime
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        #endregion
        
        default {
            $supportedActions = @(
                # Email remediation (10 existing)
                "SoftDeleteEmails", "HardDeleteEmails", "MoveToJunk", "MoveToInbox", "MoveToDeletedItems",
                "BulkEmailSearch", "BulkEmailDelete", "ZAPPhishing", "ZAPMalware", "GetAnalyzedEmails",
                "SubmitEmailThreat", "SubmitURLThreat", "SubmitFileThreat",
                "RemoveMailForwardingRules", "GetMailboxForwarders", "DisableMailboxForwarding",
                # V3.2.0 Quarantine Management (5 new)
                "ReleaseQuarantineEmail", "DeleteQuarantineEmail", "BulkReleaseQuarantine",
                "ExportQuarantineReport", "UpdateQuarantinePolicy",
                # V3.2.0 Advanced Email (5 new)
                "BlockSenderDomain", "AddSafeSender", "RemoveSafeSender",
                "UpdateSpamPolicy", "EnableATPSafeAttachments",
                # V3.2.0 Phishing Response (5 new)
                "ReportPhishingCampaign", "BlockPhishingURL", "RemovePhishingEmails",
                "TraceEmailPath", "SimulatePhishing"
            )
            
            throw "Unknown action: $action. Supported actions (31 total, 15 new in v3.2.0): $($supportedActions -join ', ')"
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
