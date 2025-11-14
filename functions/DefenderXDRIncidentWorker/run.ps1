using namespace System.Net

<#
.SYNOPSIS
    Dedicated Incident and Alert Management Worker for Microsoft Defender XDR
    
.DESCRIPTION
    Centralized worker for incident and alert lifecycle management across all Microsoft Security services.
    Provides unified incident/alert operations using Microsoft Graph Security API v2.
    
    Services Supported:
    - Microsoft Defender for Endpoint (MDE)
    - Microsoft Defender for Office 365 (MDO)
    - Microsoft Defender for Cloud (MDC)
    - Microsoft Defender for Identity (MDI)
    - Microsoft Defender for Cloud Apps (MCAS)
    
    Capabilities:
    - Incident CRUD operations (Get, Update, Close, Reopen)
    - Alert lifecycle management (Resolve, Suppress, Classify)
    - Bulk operations (multiple incidents/alerts)
    - Assignment and ownership management
    - Comments and collaboration
    - Statistics and analytics
    
.PARAMETER action
    The incident/alert action to execute
    
.PARAMETER tenantId
    Azure AD tenant ID
    
.NOTES
    Version: 3.4.0
    API: Microsoft Graph Security API v2
    Endpoints:
    - /security/incidents
    - /security/alerts_v2
#>

param($Request, $TriggerMetadata)

# Import shared authentication module
$moduleBase = "$PSScriptRoot\..\modules"
Import-Module "$moduleBase\AuthManager.psm1" -Force

$correlationId = [guid]::NewGuid().ToString()
$startTime = Get-Date

Write-Host "[$correlationId] IncidentWorker started"

# ============================================================================
# PARAMETER EXTRACTION
# ============================================================================

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$appId = $env:APPID
$secretId = $env:SECRETID

# ============================================================================
# VALIDATION
# ============================================================================

if (-not $tenantId -or -not $action) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            error = "Missing required parameters: tenantId and action"
        } | ConvertTo-Json
    })
    return
}

# ============================================================================
# AUTHENTICATION
# ============================================================================

Write-Host "[$correlationId] Acquiring Graph token for tenant: $tenantId"
$tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"

if (-not $tokenString) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = @{
            success = $false
            correlationId = $correlationId
            error = "Failed to acquire authentication token"
        } | ConvertTo-Json
    })
    return
}

$headers = @{
    Authorization = "Bearer $tokenString"
    "Content-Type" = "application/json"
}

# ============================================================================
# ACTION ROUTING
# ============================================================================

try {
    $result = @{
        success = $true
        correlationId = $correlationId
        action = $action
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        data = @{}
    }
    
    Write-Host "[$correlationId] Processing action: $action"
    
    switch -Wildcard ($action) {
        
        # ====================================================================
        # INCIDENT MANAGEMENT (15 ACTIONS)
        # ====================================================================
        
        "GetAllIncidents" {
            $filter = $Request.Query.filter ?? $Request.Body.filter
            $top = $Request.Query.top ?? $Request.Body.top ?? 100
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents?`$top=$top"
            if ($filter) { $uri += "&`$filter=$filter" }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{
                count = $response.value.Count
                incidents = $response.value
            }
        }
        
        "GetIncidentById" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $incident = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{ incident = $incident }
        }
        
        "GetIncidentAlerts" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId/alerts"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{
                incidentId = $incidentId
                alertCount = $response.value.Count
                alerts = $response.value
            }
        }
        
        "GetIncidentComments" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            # Note: Comments API may vary - using standard Graph pattern
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $incident = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{
                incidentId = $incidentId
                comments = $incident.comments ?? @()
            }
        }
        
        "UpdateIncident" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            $updates = @{}
            if ($Request.Body.status) { $updates.status = $Request.Body.status }
            if ($Request.Body.classification) { $updates.classification = $Request.Body.classification }
            if ($Request.Body.determination) { $updates.determination = $Request.Body.determination }
            if ($Request.Body.severity) { $updates.severity = $Request.Body.severity }
            if ($Request.Body.tags) { $updates.tags = $Request.Body.tags }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $body = $updates | ConvertTo-Json -Depth 5
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Incident updated successfully"
                incidentId = $incidentId
                updates = $updates
            }
        }
        
        "AssignIncident" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            $assignedTo = $Request.Query.assignedTo ?? $Request.Body.assignedTo
            if (-not $incidentId -or -not $assignedTo) { throw "incidentId and assignedTo required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $body = @{ assignedTo = $assignedTo } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Incident assigned successfully"
                incidentId = $incidentId
                assignedTo = $assignedTo
            }
        }
        
        "CloseIncident" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            $classification = $Request.Query.classification ?? $Request.Body.classification ?? "truePositive"
            $determination = $Request.Query.determination ?? $Request.Body.determination ?? "multiStagedAttack"
            
            if (-not $incidentId) { throw "incidentId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $body = @{
                status = "resolved"
                classification = $classification
                determination = $determination
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Incident closed successfully"
                incidentId = $incidentId
                classification = $classification
                determination = $determination
            }
        }
        
        "ReopenIncident" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $body = @{ status = "active" } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Incident reopened successfully"
                incidentId = $incidentId
            }
        }
        
        "AddIncidentComment" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            $comment = $Request.Query.comment ?? $Request.Body.comment
            if (-not $incidentId -or -not $comment) { throw "incidentId and comment required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId/comments"
            $body = @{ comment = $comment } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            
            $result.data = @{
                message = "Comment added successfully"
                incidentId = $incidentId
            }
        }
        
        "AddIncidentTag" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            $tags = $Request.Query.tags ?? $Request.Body.tags
            if (-not $incidentId -or -not $tags) { throw "incidentId and tags required" }
            
            # Convert comma-separated tags to array
            $tagArray = if ($tags -is [array]) { $tags } else { $tags -split ',' | ForEach-Object { $_.Trim() } }
            
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $body = @{ tags = $tagArray } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Tags added successfully"
                incidentId = $incidentId
                tags = $tagArray
            }
        }
        
        "BulkUpdateIncidents" {
            $incidentIds = $Request.Body.incidentIds
            $updates = $Request.Body.updates
            if (-not $incidentIds -or -not $updates) { throw "incidentIds and updates required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($incidentId in $incidentIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
                    $body = $updates | ConvertTo-Json -Depth 5
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $incidentId
                }
                catch {
                    $results.failed += @{ incidentId = $incidentId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk update completed"
                totalCount = $incidentIds.Count
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "BulkAssignIncidents" {
            $incidentIds = $Request.Body.incidentIds
            $assignedTo = $Request.Body.assignedTo
            if (-not $incidentIds -or -not $assignedTo) { throw "incidentIds and assignedTo required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($incidentId in $incidentIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
                    $body = @{ assignedTo = $assignedTo } | ConvertTo-Json
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $incidentId
                }
                catch {
                    $results.failed += @{ incidentId = $incidentId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk assignment completed"
                assignedTo = $assignedTo
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "BulkCloseIncidents" {
            $incidentIds = $Request.Body.incidentIds
            $classification = $Request.Body.classification ?? "truePositive"
            $determination = $Request.Body.determination ?? "multiStagedAttack"
            if (-not $incidentIds) { throw "incidentIds required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($incidentId in $incidentIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
                    $body = @{
                        status = "resolved"
                        classification = $classification
                        determination = $determination
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $incidentId
                }
                catch {
                    $results.failed += @{ incidentId = $incidentId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk close completed"
                classification = $classification
                determination = $determination
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "GetIncidentStatistics" {
            $uri = "https://graph.microsoft.com/v1.0/security/incidents?`$top=1000"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $incidents = $response.value
            $stats = @{
                total = $incidents.Count
                byStatus = $incidents | Group-Object status | Select-Object Name, Count
                bySeverity = $incidents | Group-Object severity | Select-Object Name, Count
                byClassification = $incidents | Group-Object classification | Select-Object Name, Count
                byService = $incidents | ForEach-Object { $_.alerts } | Group-Object serviceSource | Select-Object Name, Count
            }
            
            $result.data = $stats
        }
        
        "GetIncidentTimeline" {
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            if (-not $incidentId) { throw "incidentId required" }
            
            # Get incident details
            $uri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId"
            $incident = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            # Get associated alerts
            $alertsUri = "https://graph.microsoft.com/v1.0/security/incidents/$incidentId/alerts"
            $alertsResponse = Invoke-RestMethod -Uri $alertsUri -Method Get -Headers $headers
            
            $timeline = @{
                incidentId = $incidentId
                createdDateTime = $incident.createdDateTime
                lastUpdateDateTime = $incident.lastUpdateDateTime
                status = $incident.status
                alertCount = $alertsResponse.value.Count
                alerts = $alertsResponse.value | Select-Object alertId, createdDateTime, severity, title, status | Sort-Object createdDateTime
            }
            
            $result.data = $timeline
        }
        
        # ====================================================================
        # ALERT MANAGEMENT (12 ACTIONS)
        # ====================================================================
        
        "GetAllAlerts" {
            $filter = $Request.Query.filter ?? $Request.Body.filter
            $top = $Request.Query.top ?? $Request.Body.top ?? 100
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=$top"
            if ($filter) { $uri += "&`$filter=$filter" }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{
                count = $response.value.Count
                alerts = $response.value
            }
        }
        
        "GetAlertById" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            if (-not $alertId) { throw "alertId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $alert = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{ alert = $alert }
        }
        
        "GetAlertEvidence" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            if (-not $alertId) { throw "alertId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $alert = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = @{
                alertId = $alertId
                evidenceCount = $alert.evidence.Count
                evidence = $alert.evidence
            }
        }
        
        "UpdateAlert" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            if (-not $alertId) { throw "alertId required" }
            
            $updates = @{}
            if ($Request.Body.status) { $updates.status = $Request.Body.status }
            if ($Request.Body.classification) { $updates.classification = $Request.Body.classification }
            if ($Request.Body.determination) { $updates.determination = $Request.Body.determination }
            if ($Request.Body.assignedTo) { $updates.assignedTo = $Request.Body.assignedTo }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $body = $updates | ConvertTo-Json -Depth 5
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Alert updated successfully"
                alertId = $alertId
                updates = $updates
            }
        }
        
        "ResolveAlert" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            $classification = $Request.Body.classification ?? "truePositive"
            if (-not $alertId) { throw "alertId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $body = @{
                status = "resolved"
                classification = $classification
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Alert resolved successfully"
                alertId = $alertId
                classification = $classification
            }
        }
        
        "SuppressAlert" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            if (-not $alertId) { throw "alertId required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $body = @{ status = "dismissed" } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Alert suppressed successfully"
                alertId = $alertId
            }
        }
        
        "ClassifyAlert" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            $classification = $Request.Body.classification
            $determination = $Request.Body.determination
            if (-not $alertId -or -not $classification) { throw "alertId and classification required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
            $body = @{
                classification = $classification
                determination = $determination
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
            
            $result.data = @{
                message = "Alert classified successfully"
                alertId = $alertId
                classification = $classification
                determination = $determination
            }
        }
        
        "AddAlertComment" {
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            $comment = $Request.Body.comment
            if (-not $alertId -or -not $comment) { throw "alertId and comment required" }
            
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId/comments"
            $body = @{ comment = $comment } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            
            $result.data = @{
                message = "Comment added successfully"
                alertId = $alertId
            }
        }
        
        "BulkResolveAlerts" {
            $alertIds = $Request.Body.alertIds
            $classification = $Request.Body.classification ?? "truePositive"
            if (-not $alertIds) { throw "alertIds required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($alertId in $alertIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
                    $body = @{
                        status = "resolved"
                        classification = $classification
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $alertId
                }
                catch {
                    $results.failed += @{ alertId = $alertId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk resolve completed"
                classification = $classification
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "BulkSuppressAlerts" {
            $alertIds = $Request.Body.alertIds
            if (-not $alertIds) { throw "alertIds required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($alertId in $alertIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
                    $body = @{ status = "dismissed" } | ConvertTo-Json
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $alertId
                }
                catch {
                    $results.failed += @{ alertId = $alertId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk suppress completed"
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "BulkClassifyAlerts" {
            $alertIds = $Request.Body.alertIds
            $classification = $Request.Body.classification
            $determination = $Request.Body.determination
            if (-not $alertIds -or -not $classification) { throw "alertIds and classification required" }
            
            $results = @{
                successful = @()
                failed = @()
            }
            
            foreach ($alertId in $alertIds) {
                try {
                    $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2/$alertId"
                    $body = @{
                        classification = $classification
                        determination = $determination
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $body
                    $results.successful += $alertId
                }
                catch {
                    $results.failed += @{ alertId = $alertId; error = $_.Exception.Message }
                }
            }
            
            $result.data = @{
                message = "Bulk classify completed"
                classification = $classification
                determination = $determination
                successCount = $results.successful.Count
                failureCount = $results.failed.Count
                results = $results
            }
        }
        
        "GetAlertStatistics" {
            $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=1000"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $alerts = $response.value
            $stats = @{
                total = $alerts.Count
                byStatus = $alerts | Group-Object status | Select-Object Name, Count
                bySeverity = $alerts | Group-Object severity | Select-Object Name, Count
                byClassification = $alerts | Group-Object classification | Select-Object Name, Count
                byService = $alerts | Group-Object serviceSource | Select-Object Name, Count
                byCategory = $alerts | Group-Object category | Select-Object Name, Count
            }
            
            $result.data = $stats
        }
        
        default {
            throw "Unknown action: $action. Supported actions: GetAllIncidents, GetIncidentById, UpdateIncident, AssignIncident, CloseIncident, GetAllAlerts, GetAlertById, UpdateAlert, ResolveAlert, SuppressAlert, etc."
        }
    }
    
    # Calculate duration
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    $result.durationMs = [Math]::Round($duration, 2)
    
    Write-Host "[$correlationId] Action completed successfully in $($result.durationMs)ms"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 10
    })
    
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Error "[$correlationId] Error: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            correlationId = $correlationId
            action = $action
            tenantId = $tenantId
            error = @{
                code = "INCIDENT_WORKER_FAILED"
                message = $_.Exception.Message
                details = $_.ScriptStackTrace
            }
            durationMs = [Math]::Round($duration, 2)
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
    })
}
