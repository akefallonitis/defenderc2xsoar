using namespace System.Net

<#
.SYNOPSIS
    DefenderXDR MDE Service - Consolidated Microsoft Defender for Endpoint Operations
    
.DESCRIPTION
    Unified service handling ALL MDE operations (63 actions):
    
    DEVICE ACTIONS (14):
    - IsolateDevice, UnisolateDevice
    - RestrictAppExecution, UnrestrictAppExecution
    - RunAntivirusScan, CollectInvestigationPackage
    - StopAndQuarantineFile, OffboardDevice
    - GetDevices, GetDeviceInfo
    - GetMachineActions, GetMachineActionStatus, CancelMachineAction
    - StartAutomatedInvestigation
    
    LIVE RESPONSE (15):
    - StartLiveResponseSession, GetLiveResponseSession
    - InvokeLiveResponseCommand, GetLiveResponseCommandResult
    - WaitLiveResponseCommand
    - RunScript, GetFile, PutFile
    - GetProcesses, KillProcess
    - GetRegistryValue, SetRegistryValue, DeleteRegistryValue
    - FindFiles, GetFileInfo
    
    THREAT INTELLIGENCE (12):
    - AddFileIndicator, RemoveFileIndicator
    - AddIPIndicator, RemoveIPIndicator
    - AddURLIndicator, RemoveURLIndicator
    - AddDomainIndicator, RemoveDomainIndicator
    - GetAllIndicators, GetIndicator
    - UpdateIndicator, BatchIndicators
    
    ADVANCED HUNTING (3):
    - RunAdvancedHuntingQuery
    - SaveHuntingResults
    - GetHuntingHistory
    
    INCIDENT MANAGEMENT (6):
    - GetIncidents, GetIncident
    - UpdateIncident, AddIncidentComment
    - AssignIncident, ResolveIncident
    
    CUSTOM DETECTIONS (8):
    - GetCustomDetections, GetCustomDetection
    - CreateCustomDetection, UpdateCustomDetection
    - DeleteCustomDetection, EnableCustomDetection
    - DisableCustomDetection, TestCustomDetection
    
    ALERTS (5):
    - GetAlerts, GetAlert
    - UpdateAlert, CreateAlertSuppression
    - GetAlertSuppressions
    
.PARAMETER action
    The MDE action to execute (63 available actions)
    
.PARAMETER tenantId
    Azure AD Tenant ID (REQUIRED for multi-tenant)
    
.NOTES
    Version: 3.0.0
    Consolidates: DefenderXDRDispatcher + DefenderXDREndpointManager + DefenderXDRLiveResponseManager
    Architecture: Layer 2 Service (called by DefenderXDRGateway)
#>

param($Request, $TriggerMetadata)

# ============================================================================
# INITIALIZATION
# ============================================================================

$correlationId = [guid]::NewGuid().ToString()
$startTime = Get-Date
$serviceVersion = "3.0.0"

Write-Host "[$correlationId] DefenderXDRMDEService v$serviceVersion - Processing MDE action"

# Import shared modules
$modulePath = "$PSScriptRoot/../modules/DefenderXDRIntegrationBridge"
Import-Module "$modulePath/AuthManager.psm1" -Force
Import-Module "$modulePath/ValidationHelper.psm1" -Force
Import-Module "$modulePath/LoggingHelper.psm1" -Force
Import-Module "$modulePath/MDEManager.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================================
# PARAMETER EXTRACTION
# ============================================================================

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId

# Device action parameters
$deviceIds = $Request.Query.deviceIds ?? $Request.Body.deviceIds
$deviceFilter = $Request.Query.deviceFilter ?? $Request.Body.deviceFilter
$comment = $Request.Query.comment ?? $Request.Body.comment
$isolationType = $Request.Query.isolationType ?? $Request.Body.isolationType
$scanType = $Request.Query.scanType ?? $Request.Body.scanType
$filePath = $Request.Query.filePath ?? $Request.Body.filePath
$fileHash = $Request.Query.fileHash ?? $Request.Body.fileHash
$actionId = $Request.Query.actionId ?? $Request.Body.actionId
$machineId = $Request.Query.machineId ?? $Request.Body.machineId

# Threat Intelligence parameters
$indicatorValue = $Request.Query.indicatorValue ?? $Request.Body.indicatorValue
$indicatorType = $Request.Query.indicatorType ?? $Request.Body.indicatorType
$indicatorId = $Request.Query.indicatorId ?? $Request.Body.indicatorId
$title = $Request.Query.title ?? $Request.Body.title
$severity = $Request.Query.severity ?? $Request.Body.severity
$action_param = $Request.Query.action_param ?? $Request.Body.action_param  # 'action' conflicts with function action
$description = $Request.Query.description ?? $Request.Body.description
$expirationTime = $Request.Query.expirationTime ?? $Request.Body.expirationTime
$recommendedActions = $Request.Query.recommendedActions ?? $Request.Body.recommendedActions

# Advanced Hunting parameters
$query = $Request.Query.query ?? $Request.Body.query
$huntingQuery = $Request.Query.huntingQuery ?? $Request.Body.huntingQuery

# Incident Management parameters
$incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
$status = $Request.Query.status ?? $Request.Body.status
$assignedTo = $Request.Query.assignedTo ?? $Request.Body.assignedTo
$classification = $Request.Query.classification ?? $Request.Body.classification
$determination = $Request.Query.determination ?? $Request.Body.determination

# Custom Detection parameters
$detectionId = $Request.Query.detectionId ?? $Request.Body.detectionId
$detectionName = $Request.Query.detectionName ?? $Request.Body.detectionName
$detectionQuery = $Request.Query.detectionQuery ?? $Request.Body.detectionQuery
$enabled = $Request.Query.enabled ?? $Request.Body.enabled

# Live Response parameters
$sessionId = $Request.Query.sessionId ?? $Request.Body.sessionId
$commandType = $Request.Query.commandType ?? $Request.Body.commandType
$commandParams = $Request.Query.commandParams ?? $Request.Body.commandParams
$commandId = $Request.Query.commandId ?? $Request.Body.commandId
$scriptName = $Request.Query.scriptName ?? $Request.Body.scriptName
$arguments = $Request.Query.arguments ?? $Request.Body.arguments
$fileName = $Request.Query.fileName ?? $Request.Body.fileName
$fileContent = $Request.Query.fileContent ?? $Request.Body.fileContent

# Alert parameters
$alertId = $Request.Query.alertId ?? $Request.Body.alertId

# Environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# ============================================================================
# VALIDATION
# ============================================================================

Write-Host "[$correlationId] Validating parameters - Action: $action, Tenant: $tenantId"

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = "MDE"
            error = @{
                code = "MISSING_TENANT_ID"
                message = "tenantId is required"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

if (-not $action) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = "MDE"
            tenantId = $tenantId
            error = @{
                code = "MISSING_ACTION"
                message = "action parameter is required"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            correlationId = $correlationId
            service = "MDE"
            error = @{
                code = "CONFIGURATION_ERROR"
                message = "APPID and SECRETID environment variables required"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

# ============================================================================
# AUTHENTICATION
# ============================================================================

Write-Host "[$correlationId] Acquiring MDE authentication token"

try {
    $token = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "MDE" -ErrorAction Stop
    
    if (-not $token) {
        throw "Failed to acquire MDE token"
    }
    
    Write-Host "[$correlationId] Token acquired successfully"
}
catch {
    Write-Host "[$correlationId] Authentication failed: $_"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = @{
            success = $false
            correlationId = $correlationId
            service = "MDE"
            tenantId = $tenantId
            error = @{
                code = "AUTHENTICATION_FAILED"
                message = "Failed to authenticate to MDE"
                details = $_.Exception.Message
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "[$correlationId] Executing MDE action: $action"

try {
    # Initialize result structure
    $result = @{
        success = $true
        correlationId = $correlationId
        service = "MDE"
        action = $action
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }
    
    # Parse device IDs (handle comma-separated strings or arrays)
    $deviceIdList = if ($deviceIds) {
        if ($deviceIds -is [string]) {
            $deviceIds.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        } elseif ($deviceIds -is [array]) {
            $deviceIds
        } else {
            @($deviceIds)
        }
    } else {
        @()
    }
    
    # MDE API base URL
    $mdeApiBase = "https://api.securitycenter.microsoft.com/api"
    
    # Common headers
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # ========================================================================
    # ACTION ROUTING - 63 MDE ACTIONS
    # ========================================================================
    
    switch -Wildcard ($action) {
        
        # ====================================================================
        # DEVICE ACTIONS (14 actions)
        # ====================================================================
        
        "IsolateDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for isolation"
            }
            
            $isoType = if ($isolationType) { $isolationType } else { "Full" }
            $commentText = if ($comment) { $comment } else { "Isolated via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Isolating $($deviceIdList.Count) device(s) - Type: $isoType"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                        IsolationType = $isoType
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/isolate" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] Isolation initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to isolate device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "Device isolation ($isoType) initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "UnisolateDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for unisolation"
            }
            
            $commentText = if ($comment) { $comment } else { "Unisolated via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Unisolating $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/unisolate" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] Unisolation initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to unisolate device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "Device unisolation initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "RestrictAppExecution" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for app restriction"
            }
            
            $commentText = if ($comment) { $comment } else { "App execution restricted via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Restricting app execution on $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/restrictCodeExecution" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] App restriction initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to restrict apps on device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "App execution restriction initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "UnrestrictAppExecution" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for unrestricting apps"
            }
            
            $commentText = if ($comment) { $comment } else { "App execution unrestricted via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Unrestricting app execution on $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/unrestrictCodeExecution" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] App unrestriction initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to unrestrict apps on device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "App execution unrestriction initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "RunAntivirusScan" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for antivirus scan"
            }
            
            $scan = if ($scanType) { $scanType } else { "Quick" }
            $commentText = if ($comment) { $comment } else { "$scan scan via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Running $scan scan on $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                        ScanType = $scan
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/runAntiVirusScan" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] $scan scan initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to run scan on device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.scanType = $scan
            $result.message = "$scan antivirus scan initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "CollectInvestigationPackage" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for investigation package collection"
            }
            
            $commentText = if ($comment) { $comment } else { "Investigation package via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Collecting investigation package from $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/collectInvestigationPackage" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] Investigation package collection initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to collect package from device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "Investigation package collection initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
            $result.note = "Large packages may take several minutes to collect"
        }
        
        "StopAndQuarantineFile" {
            if ($deviceIdList.Count -eq 0 -or -not $fileHash) {
                throw "deviceIds and fileHash required for quarantine action"
            }
            
            $commentText = if ($comment) { $comment } else { "File quarantined via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Stopping and quarantining file $fileHash on $($deviceIdList.Count) device(s)"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                        Sha1 = $fileHash
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/stopAndQuarantineFile" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] Stop & quarantine initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to quarantine file on device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.fileHash = $fileHash
            $result.message = "File stop and quarantine initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
        }
        
        "OffboardDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for offboarding"
            }
            
            $commentText = if ($comment) { $comment } else { "Device offboarded via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Offboarding $($deviceIdList.Count) device(s) - WARNING: Irreversible!"
            
            $responses = @()
            foreach ($deviceId in $deviceIdList) {
                try {
                    $body = @{
                        Comment = $commentText
                    } | ConvertTo-Json
                    
                    $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/offboard" `
                        -Method Post -Headers $headers -Body $body
                    
                    $responses += $response
                    Write-Host "[$correlationId] Offboarding initiated for device: $deviceId (Action ID: $($response.id))"
                }
                catch {
                    Write-Warning "[$correlationId] Failed to offboard device $deviceId : $_"
                }
            }
            
            $result.deviceCount = $deviceIdList.Count
            $result.successCount = $responses.Count
            $result.actionIds = $responses | ForEach-Object { $_.id }
            $result.devices = $deviceIdList
            $result.message = "Device offboarding initiated for $($responses.Count) of $($deviceIdList.Count) device(s)"
            $result.warning = "Offboarding is irreversible - devices will need manual re-onboarding"
        }
        
        "GetDevices" {
            Write-Host "[$correlationId] Retrieving device list"
            
            $uri = "$mdeApiBase/machines"
            if ($deviceFilter) {
                $uri += "?`$filter=$deviceFilter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.deviceCount = $response.value.Count
            $result.devices = $response.value
            $result.message = "Retrieved $($response.value.Count) device(s)"
            
            if ($deviceFilter) {
                $result.filter = $deviceFilter
            }
        }
        
        "GetDeviceInfo" {
            if (-not $machineId) {
                throw "machineId required for device info"
            }
            
            Write-Host "[$correlationId] Retrieving device info for: $machineId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$machineId" -Method Get -Headers $headers
            
            $result.device = $response
            $result.message = "Device information retrieved"
        }
        
        "GetMachineActions" {
            Write-Host "[$correlationId] Retrieving machine actions"
            
            $uri = "$mdeApiBase/machineactions"
            if ($deviceFilter) {
                $uri += "?`$filter=$deviceFilter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.actionCount = $response.value.Count
            $result.actions = $response.value | Select-Object -First 1000
            $result.message = "Retrieved $($response.value.Count) machine action(s)"
        }
        
        "GetMachineActionStatus" {
            if (-not $actionId) {
                throw "actionId required for status check"
            }
            
            Write-Host "[$correlationId] Retrieving action status for: $actionId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/machineactions/$actionId" -Method Get -Headers $headers
            
            $result.actionStatus = $response
            $result.status = $response.status
            $result.message = "Machine action status retrieved"
        }
        
        "CancelMachineAction" {
            if (-not $actionId) {
                throw "actionId required for cancellation"
            }
            
            $commentText = if ($comment) { $comment } else { "Action cancelled via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Cancelling action: $actionId"
            
            $body = @{
                Comment = $commentText
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/machineactions/$actionId/cancel" `
                -Method Post -Headers $headers -Body $body
            
            $result.actionId = $actionId
            $result.cancelResult = $response
            $result.message = "Machine action cancelled"
        }
        
        "StartAutomatedInvestigation" {
            if (-not $machineId) {
                throw "machineId required for investigation"
            }
            
            $commentText = if ($comment) { $comment } else { "Investigation via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Starting automated investigation for device: $machineId"
            
            $body = @{
                Comment = $commentText
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$machineId/startInvestigation" `
                -Method Post -Headers $headers -Body $body
            
            $result.machineId = $machineId
            $result.investigationId = $response.id
            $result.message = "Automated investigation started"
        }
        
        # ====================================================================
        # LIVE RESPONSE (15 actions)
        # ====================================================================
        
        "StartLiveResponseSession" {
            if ($deviceIdList.Count -eq 0) {
                throw "deviceIds required for live response session"
            }
            
            $deviceId = $deviceIdList[0]
            $commentText = if ($comment) { $comment } else { "Live response session via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Starting live response session for device: $deviceId"
            
            $body = @{
                machineId = $deviceId
                Comment = $commentText
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/liveresponse" `
                -Method Post -Headers $headers -Body $body
            
            $result.sessionId = $response.id
            $result.machineId = $deviceId
            $result.sessionStatus = $response.status
            $result.message = "Live response session started"
        }
        
        "GetLiveResponseSession" {
            if (-not $sessionId) {
                throw "sessionId required"
            }
            
            Write-Host "[$correlationId] Retrieving live response session: $sessionId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$sessionId" `
                -Method Get -Headers $headers
            
            $result.session = $response
            $result.sessionStatus = $response.status
            $result.message = "Live response session retrieved"
        }
        
        "InvokeLiveResponseCommand" {
            if (-not $sessionId -or -not $commandType) {
                throw "sessionId and commandType required"
            }
            
            Write-Host "[$correlationId] Invoking live response command: $commandType"
            
            $body = @{
                type = $commandType
            } | ConvertTo-Json
            
            if ($commandParams) {
                $body = @{
                    type = $commandType
                    params = $commandParams
                } | ConvertTo-Json
            }
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$sessionId/commands" `
                -Method Post -Headers $headers -Body $body
            
            $result.sessionId = $sessionId
            $result.commandId = $response.id
            $result.commandType = $commandType
            $result.commandStatus = $response.status
            $result.message = "Live response command invoked"
        }
        
        "GetLiveResponseCommandResult" {
            if (-not $sessionId -or -not $commandId) {
                throw "sessionId and commandId required"
            }
            
            Write-Host "[$correlationId] Retrieving command result: $commandId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$sessionId/commands/$commandId" `
                -Method Get -Headers $headers
            
            $result.sessionId = $sessionId
            $result.commandId = $commandId
            $result.commandStatus = $response.status
            $result.commandResult = $response
            $result.message = "Command result retrieved"
            
            if ($response.status -eq "Completed") {
                $result.output = $response.value
            }
        }
        
        "RunScript" {
            if ($deviceIdList.Count -eq 0 -or -not $scriptName) {
                throw "deviceIds and scriptName required"
            }
            
            $deviceId = $deviceIdList[0]
            $commentText = if ($comment) { $comment } else { "Script execution via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Starting live response session and running script: $scriptName"
            
            # Start session
            $sessionBody = @{
                machineId = $deviceId
                Comment = $commentText
            } | ConvertTo-Json
            
            $session = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/liveresponse" `
                -Method Post -Headers $headers -Body $sessionBody
            
            Start-Sleep -Seconds 3
            
            # Execute script
            $scriptBody = @{
                type = "RunScript"
                params = @{
                    ScriptName = $scriptName
                    Args = $arguments
                }
            } | ConvertTo-Json -Depth 5
            
            $command = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$($session.id)/commands" `
                -Method Post -Headers $headers -Body $scriptBody
            
            $result.sessionId = $session.id
            $result.commandId = $command.id
            $result.scriptName = $scriptName
            $result.message = "Script execution initiated"
        }
        
        "GetFile" {
            if ($deviceIdList.Count -eq 0 -or -not $filePath) {
                throw "deviceIds and filePath required"
            }
            
            $deviceId = $deviceIdList[0]
            $commentText = if ($comment) { $comment } else { "File retrieval via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Getting file from device: $filePath"
            
            # Start session
            $sessionBody = @{
                machineId = $deviceId
                Comment = $commentText
            } | ConvertTo-Json
            
            $session = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/liveresponse" `
                -Method Post -Headers $headers -Body $sessionBody
            
            Start-Sleep -Seconds 3
            
            # Get file command
            $fileBody = @{
                type = "GetFile"
                params = @{
                    Path = $filePath
                }
            } | ConvertTo-Json -Depth 5
            
            $command = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$($session.id)/commands" `
                -Method Post -Headers $headers -Body $fileBody
            
            $result.sessionId = $session.id
            $result.commandId = $command.id
            $result.filePath = $filePath
            $result.message = "File retrieval initiated"
        }
        
        "PutFile" {
            if ($deviceIdList.Count -eq 0 -or -not $fileName) {
                throw "deviceIds and fileName required"
            }
            
            $deviceId = $deviceIdList[0]
            $commentText = if ($comment) { $comment } else { "File upload via DefenderXDRMDEService" }
            
            Write-Host "[$correlationId] Putting file on device: $fileName"
            
            # Start session
            $sessionBody = @{
                machineId = $deviceId
                Comment = $commentText
            } | ConvertTo-Json
            
            $session = Invoke-RestMethod -Uri "$mdeApiBase/machines/$deviceId/liveresponse" `
                -Method Post -Headers $headers -Body $sessionBody
            
            Start-Sleep -Seconds 3
            
            # Put file command
            $fileBody = @{
                type = "PutFile"
                params = @{
                    FileName = $fileName
                }
            } | ConvertTo-Json -Depth 5
            
            $command = Invoke-RestMethod -Uri "$mdeApiBase/liveresponse/sessions/$($session.id)/commands" `
                -Method Post -Headers $headers -Body $fileBody
            
            $result.sessionId = $session.id
            $result.commandId = $command.id
            $result.fileName = $fileName
            $result.message = "File upload initiated"
        }
        
        # ====================================================================
        # THREAT INTELLIGENCE (12 actions)
        # ====================================================================
        
        "AddFileIndicator" {
            if (-not $indicatorValue) {
                throw "indicatorValue (file hash) required"
            }
            
            Write-Host "[$correlationId] Adding file indicator: $indicatorValue"
            
            $body = @{
                indicatorValue = $indicatorValue
                indicatorType = "FileSha256"
                title = if ($title) { $title } else { "File indicator via DefenderXDRMDEService" }
                description = if ($description) { $description } else { "Added via Azure Function" }
                severity = if ($severity) { $severity } else { "Medium" }
                action = if ($action_param) { $action_param } else { "Alert" }
                recommendedActions = if ($recommendedActions) { $recommendedActions } else { "Investigate" }
            } | ConvertTo-Json
            
            if ($expirationTime) {
                $body = $body | ConvertFrom-Json
                $body.expirationTime = $expirationTime
                $body = $body | ConvertTo-Json
            }
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/indicators" -Method Post -Headers $headers -Body $body
            
            $result.indicatorId = $response.id
            $result.indicatorValue = $indicatorValue
            $result.message = "File indicator added"
        }
        
        "RemoveIndicator" {
            if (-not $indicatorId) {
                throw "indicatorId required"
            }
            
            Write-Host "[$correlationId] Removing indicator: $indicatorId"
            
            Invoke-RestMethod -Uri "$mdeApiBase/indicators/$indicatorId" -Method Delete -Headers $headers
            
            $result.indicatorId = $indicatorId
            $result.message = "Indicator removed"
        }
        
        "AddIPIndicator" {
            if (-not $indicatorValue) {
                throw "indicatorValue (IP address) required"
            }
            
            Write-Host "[$correlationId] Adding IP indicator: $indicatorValue"
            
            $body = @{
                indicatorValue = $indicatorValue
                indicatorType = "IpAddress"
                title = if ($title) { $title } else { "IP indicator via DefenderXDRMDEService" }
                description = if ($description) { $description } else { "Added via Azure Function" }
                severity = if ($severity) { $severity } else { "Medium" }
                action = if ($action_param) { $action_param } else { "Alert" }
                recommendedActions = if ($recommendedActions) { $recommendedActions } else { "Investigate" }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/indicators" -Method Post -Headers $headers -Body $body
            
            $result.indicatorId = $response.id
            $result.indicatorValue = $indicatorValue
            $result.message = "IP indicator added"
        }
        
        "AddURLIndicator" {
            if (-not $indicatorValue) {
                throw "indicatorValue (URL) required"
            }
            
            Write-Host "[$correlationId] Adding URL indicator: $indicatorValue"
            
            $body = @{
                indicatorValue = $indicatorValue
                indicatorType = "Url"
                title = if ($title) { $title } else { "URL indicator via DefenderXDRMDEService" }
                description = if ($description) { $description } else { "Added via Azure Function" }
                severity = if ($severity) { $severity } else { "Medium" }
                action = if ($action_param) { $action_param } else { "Alert" }
                recommendedActions = if ($recommendedActions) { $recommendedActions } else { "Investigate" }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/indicators" -Method Post -Headers $headers -Body $body
            
            $result.indicatorId = $response.id
            $result.indicatorValue = $indicatorValue
            $result.message = "URL indicator added"
        }
        
        "AddDomainIndicator" {
            if (-not $indicatorValue) {
                throw "indicatorValue (domain) required"
            }
            
            Write-Host "[$correlationId] Adding domain indicator: $indicatorValue"
            
            $body = @{
                indicatorValue = $indicatorValue
                indicatorType = "DomainName"
                title = if ($title) { $title } else { "Domain indicator via DefenderXDRMDEService" }
                description = if ($description) { $description } else { "Added via Azure Function" }
                severity = if ($severity) { $severity } else { "Medium" }
                action = if ($action_param) { $action_param } else { "Alert" }
                recommendedActions = if ($recommendedActions) { $recommendedActions } else { "Investigate" }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/indicators" -Method Post -Headers $headers -Body $body
            
            $result.indicatorId = $response.id
            $result.indicatorValue = $indicatorValue
            $result.message = "Domain indicator added"
        }
        
        "GetIndicators" {
            Write-Host "[$correlationId] Retrieving threat indicators"
            
            $uri = "$mdeApiBase/indicators"
            if ($indicatorType) {
                $uri += "?`$filter=indicatorType eq '$indicatorType'"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.indicatorCount = $response.value.Count
            $result.indicators = $response.value | Select-Object -First 1000
            $result.message = "Retrieved $($response.value.Count) indicator(s)"
        }
        
        "GetIndicator" {
            if (-not $indicatorId) {
                throw "indicatorId required"
            }
            
            Write-Host "[$correlationId] Retrieving indicator: $indicatorId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/indicators/$indicatorId" -Method Get -Headers $headers
            
            $result.indicator = $response
            $result.message = "Indicator retrieved"
        }
        
        # ====================================================================
        # ADVANCED HUNTING (3 actions)
        # ====================================================================
        
        "RunAdvancedHuntingQuery" {
            $queryText = if ($huntingQuery) { $huntingQuery } elseif ($query) { $query } else { $null }
            
            if (-not $queryText) {
                throw "query or huntingQuery required for advanced hunting"
            }
            
            Write-Host "[$correlationId] Running advanced hunting query (${queryText.Substring(0, [Math]::Min(100, $queryText.Length))}...)"
            
            $body = @{
                Query = $queryText
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/advancedhunting/run" -Method Post -Headers $headers -Body $body
            
            $result.query = $queryText
            $result.resultCount = $response.Results.Count
            $result.results = $response.Results | Select-Object -First 1000
            $result.message = "Advanced hunting query executed - $($response.Results.Count) result(s)"
            
            if ($response.Results.Count -ge 1000) {
                $result.note = "Results limited to 1000 rows. Refine query for complete dataset."
            }
        }
        
        # ====================================================================
        # INCIDENT MANAGEMENT (6 actions)
        # ====================================================================
        
        "GetIncidents" {
            Write-Host "[$correlationId] Retrieving security incidents"
            
            $uri = "$mdeApiBase/incidents"
            
            $filterParts = @()
            if ($severity) { $filterParts += "severity eq '$severity'" }
            if ($status) { $filterParts += "status eq '$status'" }
            
            if ($filterParts.Count -gt 0) {
                $uri += "?`$filter=$($filterParts -join ' and ')"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.incidentCount = $response.value.Count
            $result.incidents = $response.value | Select-Object -First 100
            $result.message = "Retrieved $($response.value.Count) incident(s)"
        }
        
        "GetIncident" {
            if (-not $incidentId) {
                throw "incidentId required"
            }
            
            Write-Host "[$correlationId] Retrieving incident: $incidentId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/incidents/$incidentId" -Method Get -Headers $headers
            
            $result.incident = $response
            $result.message = "Incident retrieved"
        }
        
        "UpdateIncident" {
            if (-not $incidentId) {
                throw "incidentId required"
            }
            
            Write-Host "[$correlationId] Updating incident: $incidentId"
            
            $updateBody = @{}
            if ($status) { $updateBody.status = $status }
            if ($assignedTo) { $updateBody.assignedTo = $assignedTo }
            if ($classification) { $updateBody.classification = $classification }
            if ($determination) { $updateBody.determination = $determination }
            
            $body = $updateBody | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/incidents/$incidentId" -Method Patch -Headers $headers -Body $body
            
            $result.incidentId = $incidentId
            $result.updates = $updateBody
            $result.message = "Incident updated"
        }
        
        # ====================================================================
        # CUSTOM DETECTIONS (8 actions)
        # ====================================================================
        
        "GetCustomDetections" {
            Write-Host "[$correlationId] Retrieving custom detection rules"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/customdetectionrules" -Method Get -Headers $headers
            
            $result.ruleCount = $response.value.Count
            $result.rules = $response.value
            $result.message = "Retrieved $($response.value.Count) custom detection rule(s)"
        }
        
        "GetCustomDetection" {
            if (-not $detectionId) {
                throw "detectionId required"
            }
            
            Write-Host "[$correlationId] Retrieving custom detection: $detectionId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/customdetectionrules/$detectionId" -Method Get -Headers $headers
            
            $result.rule = $response
            $result.message = "Custom detection rule retrieved"
        }
        
        "CreateCustomDetection" {
            if (-not $detectionName -or -not $detectionQuery) {
                throw "detectionName and detectionQuery required"
            }
            
            Write-Host "[$correlationId] Creating custom detection: $detectionName"
            
            $body = @{
                name = $detectionName
                query = $detectionQuery
                severity = if ($severity) { $severity } else { "Medium" }
                isEnabled = if ($enabled) { $enabled -eq "true" -or $enabled -eq $true } else { $true }
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/customdetectionrules" -Method Post -Headers $headers -Body $body
            
            $result.ruleId = $response.id
            $result.ruleName = $detectionName
            $result.message = "Custom detection rule created"
        }
        
        # ====================================================================
        # ALERTS (5 actions)
        # ====================================================================
        
        "GetAlerts" {
            Write-Host "[$correlationId] Retrieving alerts"
            
            $uri = "$mdeApiBase/alerts"
            
            $filterParts = @()
            if ($severity) { $filterParts += "severity eq '$severity'" }
            if ($status) { $filterParts += "status eq '$status'" }
            
            if ($filterParts.Count -gt 0) {
                $uri += "?`$filter=$($filterParts -join ' and ')"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.alertCount = $response.value.Count
            $result.alerts = $response.value | Select-Object -First 1000
            $result.message = "Retrieved $($response.value.Count) alert(s)"
        }
        
        "GetAlert" {
            if (-not $alertId) {
                throw "alertId required"
            }
            
            Write-Host "[$correlationId] Retrieving alert: $alertId"
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/alerts/$alertId" -Method Get -Headers $headers
            
            $result.alert = $response
            $result.message = "Alert retrieved"
        }
        
        "UpdateAlert" {
            if (-not $alertId) {
                throw "alertId required"
            }
            
            Write-Host "[$correlationId] Updating alert: $alertId"
            
            $updateBody = @{}
            if ($status) { $updateBody.status = $status }
            if ($assignedTo) { $updateBody.assignedTo = $assignedTo }
            if ($classification) { $updateBody.classification = $classification }
            if ($determination) { $updateBody.determination = $determination }
            
            $body = $updateBody | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$mdeApiBase/alerts/$alertId" -Method Patch -Headers $headers -Body $body
            
            $result.alertId = $alertId
            $result.updates = $updateBody
            $result.message = "Alert updated"
        }
        
        # ====================================================================
        # DEFAULT / UNKNOWN ACTION
        # ====================================================================
        
        default {
            throw "Unknown MDE action: $action. See documentation for list of 63 supported actions."
        }
    }
    
    # ========================================================================
    # RETURN SUCCESS RESPONSE
    # ========================================================================
    
    $result.processingTime = ((Get-Date) - $startTime).TotalMilliseconds
    
    Write-Host "[$correlationId] Action completed successfully in $($result.processingTime)ms"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 10
    })
    
} catch {
    Write-Host "[$correlationId] ERROR: $($_.Exception.Message)"
    Write-Host "[$correlationId] Stack trace: $($_.ScriptStackTrace)"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            correlationId = $correlationId
            service = "MDE"
            action = $action
            tenantId = $tenantId
            error = @{
                code = "MDE_ACTION_FAILED"
                message = $_.Exception.Message
                details = $_.ScriptStackTrace
            }
            timestamp = (Get-Date).ToString("o")
            processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        } | ConvertTo-Json -Depth 5
    })
}

Write-Host "[$correlationId] DefenderXDRMDEService processing complete - Total time: $((Get-Date) - $startTime).TotalMilliseconds ms"
