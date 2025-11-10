# Microsoft Defender for Office 365 (MDO) - Email Remediation Module
# Provides email remediation capabilities via Microsoft Graph API

function Get-GraphToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$true)]
        [string]$AppId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )
    
    $body = @{
        client_id     = $AppId
        client_secret = $ClientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }
    
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
    
    return $response.access_token
}

function Invoke-EmailRemediation {
    <#
    .SYNOPSIS
        Remediates emails using Microsoft Graph API
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER Action
        Remediation action: softDelete, hardDelete, moveToJunk, moveToInbox
    
    .PARAMETER NetworkMessageId
        Email network message ID
    
    .PARAMETER RecipientEmailAddress
        Recipient email address
    
    .PARAMETER DisplayName
        Optional display name for the remediation action
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("softDelete", "hardDelete", "moveToJunk", "moveToInbox")]
        [string]$Action,
        
        [Parameter(Mandatory=$true)]
        [string]$NetworkMessageId,
        
        [Parameter(Mandatory=$true)]
        [string]$RecipientEmailAddress,
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName = "Email remediation via DefenderXDRC2XSOAR"
    )
    
    $uri = "https://graph.microsoft.com/beta/security/collaboration/analyzedEmails/remediate"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        displayName = $DisplayName
        action = $Action
        analyzedEmails = @(
            @{
                networkMessageId = $NetworkMessageId
                recipientEmailAddress = $RecipientEmailAddress
            }
        )
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        return $response
    } catch {
        Write-Error "Email remediation failed: $($_.Exception.Message)"
        throw
    }
}

function Submit-EmailThreat {
    <#
    .SYNOPSIS
        Submits an email as a threat to Microsoft
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER Category
        Threat category: phishing, spam, malware
    
    .PARAMETER RecipientEmailAddress
        Recipient email address
    
    .PARAMETER MessageUrl
        Graph API URL to the message
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("phishing", "spam", "malware")]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$RecipientEmailAddress,
        
        [Parameter(Mandatory=$true)]
        [string]$MessageUrl
    )
    
    $uri = "https://graph.microsoft.com/beta/security/threatSubmission/emailThreats"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        "@odata.type" = "#microsoft.graph.security.emailUrlThreatSubmission"
        category = $Category
        recipientEmailAddress = $RecipientEmailAddress
        messageUrl = $MessageUrl
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        return $response
    } catch {
        Write-Error "Email threat submission failed: $($_.Exception.Message)"
        throw
    }
}

function Submit-URLThreat {
    <#
    .SYNOPSIS
        Submits a URL as a threat to Microsoft
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER Category
        Threat category: phishing, malware
    
    .PARAMETER Url
        The malicious URL to submit
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("phishing", "malware")]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    
    $uri = "https://graph.microsoft.com/beta/security/threatSubmission/urlThreats"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        "@odata.type" = "#microsoft.graph.security.urlThreatSubmission"
        category = $Category
        url = $Url
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        return $response
    } catch {
        Write-Error "URL threat submission failed: $($_.Exception.Message)"
        throw
    }
}

function Remove-MailForwardingRules {
    <#
    .SYNOPSIS
        Removes external mail forwarding rules for a user
    
    .PARAMETER Token
        Graph API authentication token
    
    .PARAMETER UserId
        User email address or ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [Parameter(Mandatory=$true)]
        [string]$UserId
    )
    
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/mailFolders/Inbox/messageRules"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $rules = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        $removedRules = @()
        
        foreach ($rule in $rules.value) {
            if ($rule.actions.forwardTo) {
                $deleteUri = "$uri/$($rule.id)"
                Invoke-RestMethod -Method Delete -Uri $deleteUri -Headers $headers | Out-Null
                $removedRules += $rule.displayName
                Write-Host "Removed forwarding rule: $($rule.displayName)"
            }
        }
        
        return @{
            removedRules = $removedRules
            count = $removedRules.Count
        }
    } catch {
        Write-Error "Failed to remove forwarding rules: $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-GraphToken',
    'Invoke-EmailRemediation',
    'Submit-EmailThreat',
    'Submit-URLThreat',
    'Remove-MailForwardingRules'
)
