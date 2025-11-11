using namespace System.Net

<#
.SYNOPSIS
    Unified Microsoft Defender for Endpoint (MDE) Manager
    
.DESCRIPTION
    Consolidated Azure Function handling ALL MDE operations:
    - Device actions (isolate, unisolate, restrict apps, scans, investigation packages, offboard)
    - Threat Intelligence (indicators: file, IP, URL, domain)
    - Advanced Hunting (KQL queries)
    - Incident Management (get, update, add comments)
    - Custom Detections (get, create, update, delete)
    - Live Response (sessions, commands, files)
    
.NOTES
    Version: 2.1.0
    Replaces: DefenderC2Dispatcher, DefenderC2Orchestrator, DefenderC2IncidentManager, 
              DefenderC2TIManager, DefenderC2HuntManager, DefenderC2CDManager
#>

param($Request, $TriggerMetadata)

Write-Host "DefenderMDEManager function processing request"

# ============================================================================
# PARAMETER EXTRACTION
# ============================================================================

# Extract parameters from query string or request body
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
$indicators = $Request.Query.indicators ?? $Request.Body.indicators
$indicatorValue = $Request.Query.indicatorValue ?? $Request.Body.indicatorValue
$indicatorType = $Request.Query.indicatorType ?? $Request.Body.indicatorType
$title = $Request.Query.title ?? $Request.Body.title
$severity = $Request.Query.severity ?? $Request.Body.severity
$recommendedAction = $Request.Query.recommendedAction ?? $Request.Body.recommendedAction
$description = $Request.Query.description ?? $Request.Body.description
$expirationTime = $Request.Query.expirationTime ?? $Request.Body.expirationTime

# Advanced Hunting parameters
$huntQuery = $Request.Query.huntQuery ?? $Request.Body.huntQuery
$query = $Request.Query.query ?? $Request.Body.query
$huntName = $Request.Query.huntName ?? $Request.Body.huntName
$saveResults = $Request.Query.saveResults ?? $Request.Body.saveResults

# Incident Management parameters
$incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
$status = $Request.Query.status ?? $Request.Body.status
$assignedTo = $Request.Query.assignedTo ?? $Request.Body.assignedTo
$classification = $Request.Query.classification ?? $Request.Body.classification
$determination = $Request.Query.determination ?? $Request.Body.determination
$incidentComment = $Request.Query.incidentComment ?? $Request.Body.incidentComment

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
$fileName = $Request.Query.fileName ?? $Request.Body.fileName

# Filter parameters
$filter = $Request.Query.filter ?? $Request.Body.filter
$top = $Request.Query.top ?? $Request.Body.top
$skip = $Request.Query.skip ?? $Request.Body.skip

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# ============================================================================
# VALIDATION
# ============================================================================

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            service = "MDE"
            action = $action
            error = @{
                code = "MISSING_TENANT_ID"
                message = "Missing required parameter: tenantId"
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
            service = "MDE"
            action = $null
            error = @{
                code = "MISSING_ACTION"
                message = "Missing required parameter: action"
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
            service = "MDE"
            action = $action
            error = @{
                code = "MISSING_CREDENTIALS"
                message = "Function app not configured: APPID and SECRETID environment variables required"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    # Authenticate using centralized AuthManager
    $token = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "MDE"
    
    Write-Host "Processing MDE action: $action for tenant: $tenantId"
    
    # Initialize result structure
    $result = @{
        success = $true
        service = "MDE"
        action = $action
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        data = @{}
    }
    
    # Parse device IDs if provided as comma-separated string
    $deviceIdList = if ($deviceIds) {
        if ($deviceIds -is [string]) {
            $deviceIds.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        } else {
            $deviceIds
        }
    } else {
        @()
    }
    
    # Parse indicators if provided as comma-separated string
    $indicatorList = if ($indicators) {
        if ($indicators -is [string]) {
            $indicators.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        } else {
            $indicators
        }
    } else {
        @()
    }
    
    # ========================================================================
    # ACTION ROUTING
    # ========================================================================
    
    switch -Wildcard ($action) {
        
        # ====================================================================
        # DEVICE ACTIONS
        # ====================================================================
        
        "IsolateDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for isolation"
            }
            $isoType = if ($isolationType) { $isolationType } else { "Full" }
            $commentText = if ($comment) { $comment } else { "Isolated via DefenderMDEManager" }
            
            $responses = Invoke-DeviceIsolation -Token $token -DeviceIds $deviceIdList -Comment $commentText -IsolationType $isoType
            $result.data = @{
                message = "Device isolation ($isoType) initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "UnisolateDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for unisolation"
            }
            $commentText = if ($comment) { $comment } else { "Unisolated via DefenderMDEManager" }
            
            $responses = Invoke-DeviceUnisolation -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.data = @{
                message = "Device unisolation initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "RestrictAppExecution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for app restriction"
            }
            $commentText = if ($comment) { $comment } else { "App execution restricted via DefenderMDEManager" }
            
            $responses = Invoke-RestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.data = @{
                message = "App execution restriction initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "UnrestrictAppExecution" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for unrestricting apps"
            }
            $commentText = if ($comment) { $comment } else { "App execution unrestricted via DefenderMDEManager" }
            
            $responses = Invoke-UnrestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.data = @{
                message = "App execution unrestriction initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "RunAntivirusScan" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for antivirus scan"
            }
            $scan = if ($scanType) { $scanType } else { "Quick" }
            $commentText = if ($comment) { $comment } else { "$scan scan initiated via DefenderMDEManager" }
            
            $responses = Invoke-AntivirusScan -Token $token -DeviceIds $deviceIdList -ScanType $scan -Comment $commentText
            $result.data = @{
                message = "$scan antivirus scan initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "CollectInvestigationPackage" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for collecting investigation package"
            }
            $commentText = if ($comment) { $comment } else { "Investigation package collection initiated via DefenderMDEManager" }
            
            $responses = Invoke-CollectInvestigationPackage -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.data = @{
                message = "Investigation package collection initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
                note = "Large packages may take several minutes to collect"
            }
        }
        
        "StopAndQuarantineFile" {
            if ($deviceIdList.Count -eq 0 -or -not $fileHash) {
                throw "Device IDs and file hash required for quarantine action"
            }
            $commentText = if ($comment) { $comment } else { "File quarantined via DefenderMDEManager" }
            
            $responses = Invoke-StopAndQuarantineFile -Token $token -DeviceIds $deviceIdList -Sha1 $fileHash -Comment $commentText
            $result.data = @{
                message = "File stop and quarantine initiated"
                deviceCount = $deviceIdList.Count
                fileHash = $fileHash
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
            }
        }
        
        "OffboardDevice" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device IDs required for offboarding"
            }
            $commentText = if ($comment) { $comment } else { "Device offboarded via DefenderMDEManager" }
            
            $responses = Invoke-DeviceOffboard -Token $token -DeviceIds $deviceIdList -Comment $commentText
            $result.data = @{
                message = "Device offboarding initiated"
                deviceCount = $deviceIdList.Count
                actionIds = $responses | ForEach-Object { $_.id }
                devices = $deviceIdList
                warning = "Offboarding is irreversible - device will need manual re-onboarding"
            }
        }
        
        "GetDeviceInfo" {
            if (-not $machineId) {
                throw "Machine ID required for getting device info"
            }
            
            $deviceInfo = Get-DeviceInfo -Token $token -MachineId $machineId
            $result.data = @{
                message = "Device information retrieved"
                device = $deviceInfo
            }
        }
        
        "GetAllDevices" {
            $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
            $devices = Get-AllDevices -Token $token @filterParam
            
            # Apply pagination if specified
            if ($top -or $skip) {
                $skipNum = if ($skip) { [int]$skip } else { 0 }
                $topNum = if ($top) { [int]$top } else { 100 }
                $devices = $devices | Select-Object -Skip $skipNum -First $topNum
            }
            
            $result.data = @{
                message = "Device list retrieved"
                count = $devices.Count
                devices = $devices
            }
        }
        
        "GetMachineActionStatus" {
            if (-not $actionId) {
                throw "Action ID required for checking status"
            }
            
            $actionStatus = Get-MachineActionStatus -Token $token -ActionId $actionId
            $result.data = @{
                message = "Machine action status retrieved"
                actionStatus = $actionStatus
            }
        }
        
        "GetAllMachineActions" {
            $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
            $actions = Get-AllMachineActions -Token $token @filterParam
            
            $result.data = @{
                message = "Machine actions retrieved"
                count = $actions.Count
                actions = $actions | Select-Object -First 1000
            }
        }
        
        "StopMachineAction" {
            if (-not $actionId) {
                throw "Action ID required for cancellation"
            }
            $commentText = if ($comment) { $comment } else { "Action cancelled via DefenderMDEManager" }
            
            $response = Stop-MachineAction -Token $token -ActionId $actionId -Comment $commentText
            $result.data = @{
                message = "Machine action cancelled"
                actionId = $actionId
                response = $response
            }
        }
        
        "StartAutomatedInvestigation" {
            if (-not $machineId) {
                throw "Machine ID required for starting investigation"
            }
            $commentText = if ($comment) { $comment } else { "Automated investigation started via DefenderMDEManager" }
            
            $response = Start-AutomatedInvestigation -Token $token -MachineId $machineId -Comment $commentText
            $result.data = @{
                message = "Automated investigation started"
                machineId = $machineId
                investigationId = $response.id
            }
        }
        
        # ====================================================================
        # THREAT INTELLIGENCE INDICATORS
        # ====================================================================
        
        "AddFileIndicator*" {
            if ($indicatorList.Count -eq 0 -and -not $indicatorValue) {
                throw "File hash(es) required for adding file indicators"
            }
            
            $hashList = if ($indicatorValue) { @($indicatorValue) } else { $indicatorList }
            $indicatorTitle = if ($title) { $title } else { "File indicator added via DefenderMDEManager" }
            $indicatorSeverity = if ($severity) { $severity } else { "Medium" }
            $indicatorAction = if ($recommendedAction) { $recommendedAction } else { "Alert" }
            $indicatorDescription = if ($description) { $description } else { "Added via Azure Function" }
            
            $responses = @()
            foreach ($hash in $hashList) {
                try {
                    $response = Add-FileIndicator -Token $token -Sha256 $hash -Title $indicatorTitle `
                        -Severity $indicatorSeverity -Action $indicatorAction -Description $indicatorDescription
                    $responses += $response
                } catch {
                    Write-Warning "Failed to add indicator $hash : $($_.Exception.Message)"
                }
            }
            
            $result.data = @{
                message = "File indicators added"
                successCount = $responses.Count
                totalCount = $hashList.Count
                indicators = $hashList
                indicatorIds = $responses | ForEach-Object { $_.id }
            }
        }
        
        "RemoveFileIndicator*" {
            if (-not $indicatorValue -and $indicatorList.Count -eq 0) {
                throw "File hash required for removing file indicator"
            }
            
            $hashToRemove = if ($indicatorValue) { $indicatorValue } else { $indicatorList[0] }
            $response = Remove-FileIndicator -Token $token -Sha256 $hashToRemove
            
            $result.data = @{
                message = "File indicator removed"
                indicator = $hashToRemove
                response = $response
            }
        }
        
        "AddIPIndicator*" {
            if (-not $indicatorValue) {
                throw "IP address required for adding IP indicator"
            }
            
            $indicatorTitle = if ($title) { $title } else { "IP indicator added via DefenderMDEManager" }
            $indicatorSeverity = if ($severity) { $severity } else { "Medium" }
            $indicatorAction = if ($recommendedAction) { $recommendedAction } else { "Alert" }
            $indicatorDescription = if ($description) { $description } else { "Added via Azure Function" }
            
            $response = Add-IPIndicator -Token $token -IPAddress $indicatorValue -Title $indicatorTitle `
                -Severity $indicatorSeverity -Action $indicatorAction -Description $indicatorDescription
            
            $result.data = @{
                message = "IP indicator added"
                indicator = $indicatorValue
                indicatorId = $response.id
            }
        }
        
        "AddURLIndicator*" {
            if (-not $indicatorValue) {
                throw "URL required for adding URL indicator"
            }
            
            $indicatorTitle = if ($title) { $title } else { "URL indicator added via DefenderMDEManager" }
            $indicatorSeverity = if ($severity) { $severity } else { "Medium" }
            $indicatorAction = if ($recommendedAction) { $recommendedAction } else { "Alert" }
            $indicatorDescription = if ($description) { $description } else { "Added via Azure Function" }
            
            $response = Add-URLIndicator -Token $token -URL $indicatorValue -Title $indicatorTitle `
                -Severity $indicatorSeverity -Action $indicatorAction -Description $indicatorDescription
            
            $result.data = @{
                message = "URL indicator added"
                indicator = $indicatorValue
                indicatorId = $response.id
            }
        }
        
        "GetAllIndicators" {
            $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
            $indicators = Get-AllIndicators -Token $token @filterParam
            
            $result.data = @{
                message = "Indicators retrieved"
                count = $indicators.Count
                indicators = $indicators | Select-Object -First 1000
            }
        }
        
        # ====================================================================
        # ADVANCED HUNTING
        # ====================================================================
        
        "AdvancedHunt*" {
            $queryToExecute = if ($huntQuery) { $huntQuery } elseif ($query) { $query } else { $null }
            
            if (-not $queryToExecute) {
                throw "KQL query required for advanced hunting"
            }
            
            Write-Host "Executing KQL query: $($queryToExecute.Substring(0, [Math]::Min(100, $queryToExecute.Length)))..."
            $huntResults = Invoke-AdvancedHunting -Token $token -Query $queryToExecute
            
            $result.data = @{
                message = "Advanced hunting query executed"
                huntName = $huntName
                resultCount = $huntResults.Count
                query = $queryToExecute
                results = $huntResults | Select-Object -First 1000
            }
            
            if ($saveResults -eq "true" -or $saveResults -eq $true) {
                $result.data.note = "Result saving to Azure Storage not yet implemented"
            }
        }
        
        # ====================================================================
        # INCIDENT MANAGEMENT
        # ====================================================================
        
        "GetIncident*" {
            if ($incidentId) {
                # Get specific incident
                $incident = Get-SecurityIncidents -Token $token -Filter "id eq '$incidentId'"
                
                $result.data = @{
                    message = "Incident retrieved"
                    incidentId = $incidentId
                    incident = if ($incident) { $incident[0] } else { $null }
                }
            } else {
                # Get incidents with optional filters
                $filterParts = @()
                
                if ($severity) { $filterParts += "severity eq '$severity'" }
                if ($status) { $filterParts += "status eq '$status'" }
                
                $filterQuery = if ($filterParts.Count -gt 0) { $filterParts -join " and " } else { $null }
                $filterParam = if ($filterQuery) { @{ Filter = $filterQuery } } else { @{} }
                
                $incidents = Get-SecurityIncidents -Token $token @filterParam
                
                $result.data = @{
                    message = "Incidents retrieved"
                    count = $incidents.Count
                    filters = @{
                        severity = $severity
                        status = $status
                    }
                    incidents = $incidents | Select-Object -First 100
                }
            }
        }
        
        "UpdateIncident*" {
            if (-not $incidentId) {
                throw "Incident ID required for update"
            }
            
            $updateParams = @{
                Token = $token
                IncidentId = $incidentId
            }
            
            if ($status) { $updateParams.Status = $status }
            if ($assignedTo) { $updateParams.AssignedTo = $assignedTo }
            if ($classification) { $updateParams.Classification = $classification }
            if ($determination) { $updateParams.Determination = $determination }
            
            $response = Update-SecurityIncident @updateParams
            
            $result.data = @{
                message = "Incident updated"
                incidentId = $incidentId
                updates = @{
                    status = $status
                    assignedTo = $assignedTo
                    classification = $classification
                    determination = $determination
                }
                response = $response
            }
        }
        
        "AddIncidentComment" {
            if (-not $incidentId -or -not $incidentComment) {
                throw "Incident ID and comment required"
            }
            
            $response = Add-IncidentComment -Token $token -IncidentId $incidentId -Comment $incidentComment
            
            $result.data = @{
                message = "Comment added to incident"
                incidentId = $incidentId
                comment = $incidentComment
                response = $response
            }
        }
        
        # ====================================================================
        # CUSTOM DETECTIONS
        # ====================================================================
        
        "GetCustomDetection*" {
            if ($detectionId) {
                # Get specific detection (implementation depends on API)
                $detections = Get-CustomDetections -Token $token
                $detection = $detections | Where-Object { $_.id -eq $detectionId }
                
                $result.data = @{
                    message = "Custom detection retrieved"
                    detectionId = $detectionId
                    detection = $detection
                }
            } else {
                $detections = Get-CustomDetections -Token $token
                
                $result.data = @{
                    message = "Custom detections retrieved"
                    count = $detections.Count
                    detections = $detections
                }
            }
        }
        
        "CreateCustomDetection" {
            if (-not $detectionName -or -not $detectionQuery) {
                throw "Detection name and query required for creating custom detection"
            }
            
            $response = New-CustomDetection -Token $token -Name $detectionName -Query $detectionQuery `
                -Severity $severity -Enabled:$($enabled -eq "true" -or $enabled -eq $true)
            
            $result.data = @{
                message = "Custom detection created"
                detectionName = $detectionName
                detectionId = $response.id
                enabled = $enabled
            }
        }
        
        "UpdateCustomDetection" {
            if (-not $detectionId) {
                throw "Detection ID required for update"
            }
            
            $updateParams = @{
                Token = $token
                DetectionId = $detectionId
            }
            
            if ($detectionName) { $updateParams.Name = $detectionName }
            if ($detectionQuery) { $updateParams.Query = $detectionQuery }
            if ($severity) { $updateParams.Severity = $severity }
            if ($null -ne $enabled) { $updateParams.Enabled = ($enabled -eq "true" -or $enabled -eq $true) }
            
            $response = Update-CustomDetection @updateParams
            
            $result.data = @{
                message = "Custom detection updated"
                detectionId = $detectionId
                response = $response
            }
        }
        
        "DeleteCustomDetection" {
            if (-not $detectionId) {
                throw "Detection ID required for deletion"
            }
            
            $response = Remove-CustomDetection -Token $token -DetectionId $detectionId
            
            $result.data = @{
                message = "Custom detection deleted"
                detectionId = $detectionId
                response = $response
            }
        }
        
        # ====================================================================
        # LIVE RESPONSE
        # ====================================================================
        
        "StartLiveResponseSession" {
            if (-not $machineId) {
                throw "Machine ID required for starting live response session"
            }
            $commentText = if ($comment) { $comment } else { "Live response session via DefenderMDEManager" }
            
            $session = Start-MDELiveResponseSession -Token $token -MachineId $machineId -Comment $commentText
            
            $result.data = @{
                message = "Live response session started"
                machineId = $machineId
                sessionId = $session.id
                status = $session.status
                session = $session
            }
        }
        
        "GetLiveResponseSession" {
            if (-not $sessionId) {
                throw "Session ID required for getting session details"
            }
            
            $session = Get-MDELiveResponseSession -Token $token -SessionId $sessionId
            
            $result.data = @{
                message = "Live response session retrieved"
                sessionId = $sessionId
                session = $session
            }
        }
        
        "InvokeLiveResponseCommand" {
            if (-not $sessionId -or -not $commandType) {
                throw "Session ID and command type required for executing command"
            }
            
            $cmdResult = Invoke-MDELiveResponseCommand -Token $token -SessionId $sessionId `
                -CommandType $commandType -Parameters $commandParams
            
            $result.data = @{
                message = "Live response command executed"
                sessionId = $sessionId
                commandType = $commandType
                commandId = $cmdResult.id
                command = $cmdResult
            }
        }
        
        "GetLiveResponseCommandResult" {
            if (-not $sessionId -or -not $commandId) {
                throw "Session ID and command ID required for getting command result"
            }
            
            $cmdResult = Get-MDELiveResponseCommandResult -Token $token -SessionId $sessionId -CommandId $commandId
            
            $result.data = @{
                message = "Live response command result retrieved"
                sessionId = $sessionId
                commandId = $commandId
                result = $cmdResult
            }
        }
        
        "WaitLiveResponseCommand" {
            if (-not $sessionId -or -not $commandId) {
                throw "Session ID and command ID required for waiting on command"
            }
            
            $cmdResult = Wait-MDELiveResponseCommand -Token $token -SessionId $sessionId `
                -CommandId $commandId -TimeoutSeconds 300
            
            $result.data = @{
                message = "Live response command completed"
                sessionId = $sessionId
                commandId = $commandId
                result = $cmdResult
            }
        }
        
        "GetLiveResponseFile" {
            if (-not $sessionId -or -not $fileName) {
                throw "Session ID and file name required for retrieving file"
            }
            
            $fileContent = Get-MDELiveResponseFile -Token $token -SessionId $sessionId -FileName $fileName
            
            $result.data = @{
                message = "Live response file retrieved"
                sessionId = $sessionId
                fileName = $fileName
                fileSize = $fileContent.Length
                note = "File content returned as base64"
            }
        }
        
        "SendLiveResponseFile" {
            if (-not $sessionId -or -not $fileName -or -not $filePath) {
                throw "Session ID, file name, and file path required for uploading file"
            }
            
            $uploadResult = Send-MDELiveResponseFile -Token $token -SessionId $sessionId `
                -FileName $fileName -FilePath $filePath
            
            $result.data = @{
                message = "Live response file uploaded"
                sessionId = $sessionId
                fileName = $fileName
                result = $uploadResult
            }
        }
        
        # ====================================================================
        # DEFAULT / UNKNOWN ACTION
        # ====================================================================
        
        default {
            throw "Unknown action: $action. Valid actions include: IsolateDevice, UnisolateDevice, RestrictAppExecution, UnrestrictAppExecution, RunAntivirusScan, CollectInvestigationPackage, StopAndQuarantineFile, OffboardDevice, GetDeviceInfo, GetAllDevices, GetMachineActionStatus, GetAllMachineActions, StopMachineAction, StartAutomatedInvestigation, AddFileIndicator, RemoveFileIndicator, AddIPIndicator, AddURLIndicator, GetAllIndicators, AdvancedHunt, GetIncidents, UpdateIncident, AddIncidentComment, GetCustomDetections, CreateCustomDetection, UpdateCustomDetection, DeleteCustomDetection, StartLiveResponseSession, GetLiveResponseSession, InvokeLiveResponseCommand, GetLiveResponseCommandResult, WaitLiveResponseCommand, GetLiveResponseFile, SendLiveResponseFile"
        }
    }
    
    # Return success response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 10
    })
    
} catch {
    Write-Error "Error processing MDE action: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    
    # Return error response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            service = "MDE"
            action = $action
            tenantId = $tenantId
            error = @{
                code = "MDE_ACTION_FAILED"
                message = $_.Exception.Message
                details = $_.ScriptStackTrace
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
    })
}
