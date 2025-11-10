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
    return
}

try {
    # Authenticate to Graph API
    $token = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
    
    # Execute action
    switch ($action) {
        "RemediateEmail" {
            if (-not $emailId -and -not $messageId) {
                throw "Email ID or Message ID required"
            }
            
            $msgId = if ($emailId) { $emailId } else { $messageId }
            $remediation = if ($remediationType) { $remediationType } else { "SoftDelete" }
            
            $response = Invoke-EmailRemediation -Token $token -MessageId $msgId -RemediationType $remediation
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "RemediateEmail"
                    tenantId = $tenantId
                    messageId = $msgId
                    remediationType = $remediation
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "SubmitEmailThreat" {
            if (-not $emailId -and -not $messageId) {
                throw "Email ID or Message ID required"
            }
            
            $msgId = if ($emailId) { $emailId } else { $messageId }
            $response = Submit-EmailThreat -Token $token -MessageId $msgId
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SubmitEmailThreat"
                    tenantId = $tenantId
                    messageId = $msgId
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "SubmitURLThreat" {
            if (-not $url) {
                throw "URL required"
            }
            
            $response = Submit-URLThreat -Token $token -URL $url
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "SubmitURLThreat"
                    tenantId = $tenantId
                    url = $url
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
            })
        }
        
        "RemoveMailForwardingRules" {
            if (-not $userId) {
                throw "User ID required"
            }
            
            $response = Remove-MailForwardingRules -Token $token -UserId $userId
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = @{
                    success = $true
                    action = "RemoveMailForwardingRules"
                    tenantId = $tenantId
                    userId = $userId
                    result = $response
                    timestamp = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 5
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
            tenantId = $tenantId
            error = $_.Exception.Message
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
}
