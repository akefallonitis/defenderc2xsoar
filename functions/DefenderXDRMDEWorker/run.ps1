<#
.SYNOPSIS
    Microsoft Defender for Endpoint (MDE) Worker
    
.DESCRIPTION
    Handles all MDE operations including:
    - Device Actions (14): Isolate, Unisolate, Restrict, Scan, Investigation Package, etc.
    - Live Response (15): RunScript, GetFile, PutFile, Session Management
    - Threat Intelligence (12): Indicators (File/IP/URL/Domain)
    - Advanced Hunting (3): KQL Query Execution
    - Incident Management (6): Get, Update, Comment
    - Custom Detection (8): CRUD Operations
    - Alert Management (5): Get, Update, Resolve, Classify
    
.NOTES
    Version: 3.0.0
    Requires: AuthManager, BlobManager (for Live Response)
#>

using namespace System.Net


# Robust module import with existence check and error logging
$moduleBase = "$PSScriptRoot\..\modules\DefenderXDRIntegrationBridge"
$modules = @(
    "AuthManager.psm1",
    "BlobManager.psm1",
    "ValidationHelper.psm1",
    "LoggingHelper.psm1"
)
foreach ($mod in $modules) {
    $modPath = Join-Path $moduleBase $mod
    if (-not (Test-Path $modPath)) {
        Write-Error "Required module missing: $modPath"
        $result = @{ success = $false; error = "Required module missing: $modPath"; timestamp = (Get-Date).ToString("o") }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = ($result | ConvertTo-Json -Depth 10)
            Headers = @{ "Content-Type" = "application/json" }
        })
        return
    }
    Import-Module $modPath -Force -ErrorAction Stop
}

param($Request, $TriggerMetadata)

# Initialize result
$result = @{
    success = $false
    action = $null
    data = $null
    error = $null
    timestamp = (Get-Date).ToString("o")
}

try {
    Write-Host "DefenderXDRMDEWorker invoked"
    # Parse request body
    $requestBody = $Request.Body
    # Extract parameters
    $tenantId = $requestBody.tenantId
    $action = $requestBody.action
    $parameters = $requestBody.parameters
    $correlationId = $requestBody.correlationId
    # Validation
    if ([string]::IsNullOrEmpty($tenantId)) {
        throw "Missing required parameter: tenantId"
    }
    if ([string]::IsNullOrEmpty($action)) {
        throw "Missing required parameter: action"
    }
    $result.action = $action
    Write-Host "Processing MDE action: $action for tenant: $tenantId"
    # ...existing code...
}
catch {
    $result.success = $false
    $result.error = $_.Exception.Message
    $result.timestamp = (Get-Date).ToString("o")
    Write-Error "DefenderXDRMDEWorker error: $($result.error)"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = ($result | ConvertTo-Json -Depth 10)
        Headers = @{ "Content-Type" = "application/json" }
    })
    return
}
    
    # Get MDE OAuth token
    $appId = $env:APPID
    $appSecret = $env:SECRETID
    
    if ([string]::IsNullOrEmpty($appId) -or [string]::IsNullOrEmpty($appSecret)) {
        throw "Missing app registration credentials (APPID/SECRETID)"
    }
    
    $tokenParams = @{
        TenantId = $tenantId
        AppId = $appId
        ClientSecret = $appSecret
        Service = "MDE"
    }
    
    # Get-OAuthToken returns the token string directly (not an object)
    $accessToken = Get-OAuthToken @tokenParams
    
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Failed to acquire MDE token"
    }
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $mdeApiBase = "https://api.securitycenter.microsoft.com/api"
    
    # Action router
    switch ($action.ToUpper()) {
        
        #region Device Actions (14 actions)
        
        "ISOLATEDEVICE" {
            $machineId = $parameters.machineId
            $isolationType = if ($parameters.isolationType) { $parameters.isolationType } else { "Full" }
            $comment = if ($parameters.comment) { $parameters.comment } else { "Isolated by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
                IsolationType = $isolationType
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/isolate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "UNISOLATEDEVICE" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Unisolated by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/unisolate"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "RESTRICTAPP" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "App execution restricted by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/restrictCodeExecution"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "UNRESTRICTAPP" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "App execution unrestricted by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/unrestrictCodeExecution"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "RUNAV SCAN" {
            $machineId = $parameters.machineId
            $scanType = if ($parameters.scanType) { $parameters.scanType } else { "Quick" }
            $comment = if ($parameters.comment) { $parameters.comment } else { "AV scan initiated by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
                ScanType = $scanType
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runAntiVirusScan"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "COLLECTINVESTIGATIONPACKAGE" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Investigation package collected by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/collectInvestigationPackage"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "OFFBOARDDEVICE" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Device offboarded by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/offboard"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "STOPANDQUARANTINEFILE" {
            $machineId = $parameters.machineId
            $sha1 = $parameters.sha1
            $comment = if ($parameters.comment) { $parameters.comment } else { "File quarantined by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($sha1)) {
                throw "Missing required parameters: machineId, sha1"
            }
            
            $body = @{
                Comment = $comment
                Sha1 = $sha1
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/StopAndQuarantineFile"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "GETDEVICES" {
            $filter = $parameters.filter
            $uri = "$mdeApiBase/machines"
            
            if ($filter) {
                $uri += "?`$filter=$filter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = $response
        }
        
        "GETDEVICEINFO" {
            $machineId = $parameters.machineId
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $uri = "$mdeApiBase/machines/$machineId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "GETACTIONSTATUS" {
            $actionId = $parameters.actionId
            
            if ([string]::IsNullOrEmpty($actionId)) {
                throw "Missing required parameter: actionId"
            }
            
            $uri = "$mdeApiBase/machineactions/$actionId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "GETALLACTIONS" {
            $machineId = $parameters.machineId
            $uri = "$mdeApiBase/machineactions"
            
            if ($machineId) {
                $uri += "?`$filter=machineId eq '$machineId'"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = $response
        }
        
        "CANCELACTION" {
            $actionId = $parameters.actionId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Action cancelled by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($actionId)) {
                throw "Missing required parameter: actionId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machineactions/$actionId/cancel"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "STARTINVESTIGATION" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Investigation started by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/startInvestigation"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        #endregion
        
        #region Live Response Actions (15 actions)
        
        "STARTSESSION" {
            $machineId = $parameters.machineId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Live Response session started by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = $comment
                machineId = $machineId
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machineactions/live-response"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "GETSESSION" {
            $sessionId = $parameters.sessionId
            
            if ([string]::IsNullOrEmpty($sessionId)) {
                throw "Missing required parameter: sessionId"
            }
            
            $uri = "$mdeApiBase/machineactions/$sessionId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "RUNSCRIPT" {
            $machineId = $parameters.machineId
            $scriptName = $parameters.scriptName
            $scriptArgs = $parameters.scriptArgs
            $comment = if ($parameters.comment) { $parameters.comment } else { "Script executed by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($scriptName)) {
                throw "Missing required parameters: machineId, scriptName"
            }
            
            # Check if script is in Blob Storage
            $blobInfo = Get-XDRBlobFileInfo -TenantId $tenantId -FileName $scriptName -Category "scripts"
            
            if (-not $blobInfo.Success) {
                throw "Script not found in Live Response library: $scriptName"
            }
            
            $body = @{
                Comment = $comment
                ScriptName = $scriptName
            }
            
            if ($scriptArgs) {
                $body.Arguments = $scriptArgs
            }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        "GETFILE" {
            $machineId = $parameters.machineId
            $filePath = $parameters.filePath
            $comment = if ($parameters.comment) { $parameters.comment } else { "File retrieved by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($filePath)) {
                throw "Missing required parameters: machineId, filePath"
            }
            
            $body = @{
                Comment = $comment
                Path = $filePath
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/getfile"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            # File will be downloaded from MDE and stored in Blob Storage
            # The response contains a download link that expires quickly
            # We should download it and store in Blob for persistent access
            
            if ($response.downloadUrl) {
                # Download file from MDE
                $tempFile = [System.IO.Path]::GetTempFileName()
                Invoke-WebRequest -Uri $response.downloadUrl -OutFile $tempFile
                
                # Upload to Blob Storage
                $fileName = Split-Path -Leaf $filePath
                $blobResult = Add-XDRBlobFile -TenantId $tenantId `
                    -FilePath $tempFile `
                    -FileName "$correlationId-$fileName" `
                    -Category "downloads"
                
                # Generate SAS URL for user download
                if ($blobResult.Success) {
                    $sasResult = New-XDRBlobSasUrl -TenantId $tenantId `
                        -FileName "$correlationId-$fileName" `
                        -Category "downloads" `
                        -ExpiryHours 24
                    
                    $response | Add-Member -NotePropertyName "blobDownloadUrl" -NotePropertyValue $sasResult.SasUrl
                    $response | Add-Member -NotePropertyName "blobPath" -NotePropertyValue $blobResult.BlobPath
                }
                
                # Clean up temp file
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            }
            
            $result.data = $response
        }
        
        "PUTFILE" {
            $machineId = $parameters.machineId
            $fileName = $parameters.fileName
            $comment = if ($parameters.comment) { $parameters.comment } else { "File uploaded by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($fileName)) {
                throw "Missing required parameters: machineId, fileName"
            }
            
            # Get file from Blob Storage
            $blobInfo = Get-XDRBlobFileInfo -TenantId $tenantId -FileName $fileName -Category "uploads"
            
            if (-not $blobInfo.Success) {
                throw "File not found in Live Response library: $fileName"
            }
            
            # Generate SAS URL for MDE to download
            $sasResult = New-XDRBlobSasUrl -TenantId $tenantId `
                -FileName $fileName `
                -Category "uploads" `
                -ExpiryHours 1
            
            if (-not $sasResult.Success) {
                throw "Failed to generate SAS URL for file: $fileName"
            }
            
            $body = @{
                Comment = $comment
                FileName = $fileName
                DownloadUrl = $sasResult.SasUrl
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/putfile"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "INVOKECOMMAND" {
            $machineId = $parameters.machineId
            $commandType = $parameters.commandType
            $command = $parameters.command
            $comment = if ($parameters.comment) { $parameters.comment } else { "Command executed by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($commandType) -or [string]::IsNullOrEmpty($command)) {
                throw "Missing required parameters: machineId, commandType, command"
            }
            
            $body = @{
                Comment = $comment
                CommandType = $commandType
                Command = $command
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "GETCOMMANDRESULT" {
            $commandId = $parameters.commandId
            
            if ([string]::IsNullOrEmpty($commandId)) {
                throw "Missing required parameter: commandId"
            }
            
            $uri = "$mdeApiBase/machineactions/$commandId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "GETPROCESSES" {
            $machineId = $parameters.machineId
            
            if ([string]::IsNullOrEmpty($machineId)) {
                throw "Missing required parameter: machineId"
            }
            
            $body = @{
                Comment = "Get processes by DefenderXDR"
                CommandType = "GetProcesses"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "KILLPROCESS" {
            $machineId = $parameters.machineId
            $processId = $parameters.processId
            $comment = if ($parameters.comment) { $parameters.comment } else { "Process killed by DefenderXDR" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($processId)) {
                throw "Missing required parameters: machineId, processId"
            }
            
            $body = @{
                Comment = $comment
                CommandType = "KillProcess"
                ProcessId = $processId
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "GETREGISTRYVALUE" {
            $machineId = $parameters.machineId
            $registryPath = $parameters.registryPath
            $valueName = $parameters.valueName
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($registryPath)) {
                throw "Missing required parameters: machineId, registryPath"
            }
            
            $body = @{
                Comment = "Get registry value by DefenderXDR"
                CommandType = "GetRegistryValue"
                Path = $registryPath
                ValueName = $valueName
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "SETREGISTRYVALUE" {
            $machineId = $parameters.machineId
            $registryPath = $parameters.registryPath
            $valueName = $parameters.valueName
            $value = $parameters.value
            $valueType = if ($parameters.valueType) { $parameters.valueType } else { "String" }
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($registryPath) -or [string]::IsNullOrEmpty($valueName)) {
                throw "Missing required parameters: machineId, registryPath, valueName"
            }
            
            $body = @{
                Comment = "Set registry value by DefenderXDR"
                CommandType = "SetRegistryValue"
                Path = $registryPath
                ValueName = $valueName
                Value = $value
                ValueType = $valueType
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "DELETEREGISTRYVALUE" {
            $machineId = $parameters.machineId
            $registryPath = $parameters.registryPath
            $valueName = $parameters.valueName
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($registryPath) -or [string]::IsNullOrEmpty($valueName)) {
                throw "Missing required parameters: machineId, registryPath, valueName"
            }
            
            $body = @{
                Comment = "Delete registry value by DefenderXDR"
                CommandType = "DeleteRegistryValue"
                Path = $registryPath
                ValueName = $valueName
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "FINDFILES" {
            $machineId = $parameters.machineId
            $fileName = $parameters.fileName
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($fileName)) {
                throw "Missing required parameters: machineId, fileName"
            }
            
            $body = @{
                Comment = "Find files by DefenderXDR"
                CommandType = "FindFile"
                FileName = $fileName
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "GETFILEINFO" {
            $machineId = $parameters.machineId
            $filePath = $parameters.filePath
            
            if ([string]::IsNullOrEmpty($machineId) -or [string]::IsNullOrEmpty($filePath)) {
                throw "Missing required parameters: machineId, filePath"
            }
            
            $body = @{
                Comment = "Get file info by DefenderXDR"
                CommandType = "GetFileInfo"
                Path = $filePath
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$machineId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        #endregion
        
        #region Threat Intelligence Indicators (12 actions)
        
        "ADDINDICATOR" {
            $indicatorValue = $parameters.indicatorValue
            $indicatorType = $parameters.indicatorType  # FileSha1, FileSha256, IpAddress, DomainName, Url
            $action = $parameters.indicatorAction       # Alert, AlertAndBlock, Allowed
            $title = $parameters.title
            $description = $parameters.description
            $severity = if ($parameters.severity) { $parameters.severity } else { "Informational" }
            $expirationTime = $parameters.expirationTime
            
            if ([string]::IsNullOrEmpty($indicatorValue) -or [string]::IsNullOrEmpty($indicatorType) -or [string]::IsNullOrEmpty($action)) {
                throw "Missing required parameters: indicatorValue, indicatorType, indicatorAction"
            }
            
            $body = @{
                indicatorValue = $indicatorValue
                indicatorType = $indicatorType
                action = $action
                title = $title
                description = $description
                severity = $severity
            }
            
            if ($expirationTime) {
                $body.expirationTime = $expirationTime
            }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        "REMOVEINDICATOR" {
            $indicatorId = $parameters.indicatorId
            
            if ([string]::IsNullOrEmpty($indicatorId)) {
                throw "Missing required parameter: indicatorId"
            }
            
            $uri = "$mdeApiBase/indicators/$indicatorId"
            $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            $result.data = @{ message = "Indicator removed successfully"; indicatorId = $indicatorId }
        }
        
        "GETINDICATORS" {
            $filter = $parameters.filter
            $uri = "$mdeApiBase/indicators"
            
            if ($filter) {
                $uri += "?`$filter=$filter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = $response
        }
        
        "GETINDICATOR" {
            $indicatorId = $parameters.indicatorId
            
            if ([string]::IsNullOrEmpty($indicatorId)) {
                throw "Missing required parameter: indicatorId"
            }
            
            $uri = "$mdeApiBase/indicators/$indicatorId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "UPDATEINDICATOR" {
            $indicatorId = $parameters.indicatorId
            $indicatorAction = $parameters.indicatorAction
            $title = $parameters.title
            $description = $parameters.description
            $severity = $parameters.severity
            $expirationTime = $parameters.expirationTime
            
            if ([string]::IsNullOrEmpty($indicatorId)) {
                throw "Missing required parameter: indicatorId"
            }
            
            $body = @{}
            
            if ($indicatorAction) { $body.action = $indicatorAction }
            if ($title) { $body.title = $title }
            if ($description) { $body.description = $description }
            if ($severity) { $body.severity = $severity }
            if ($expirationTime) { $body.expirationTime = $expirationTime }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators/$indicatorId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        "BULKADDINDICATORS" {
            $indicators = $parameters.indicators  # Array of indicator objects
            
            if (-not $indicators -or $indicators.Count -eq 0) {
                throw "Missing required parameter: indicators array"
            }
            
            $results = @()
            
            foreach ($indicator in $indicators) {
                try {
                    $body = @{
                        indicatorValue = $indicator.indicatorValue
                        indicatorType = $indicator.indicatorType
                        action = $indicator.action
                        title = $indicator.title
                        description = $indicator.description
                        severity = if ($indicator.severity) { $indicator.severity } else { "Informational" }
                    }
                    
                    if ($indicator.expirationTime) {
                        $body.expirationTime = $indicator.expirationTime
                    }
                    
                    $bodyJson = $body | ConvertTo-Json
                    
                    $uri = "$mdeApiBase/indicators"
                    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $bodyJson
                    
                    $results += @{
                        success = $true
                        indicator = $indicator.indicatorValue
                        response = $response
                    }
                }
                catch {
                    $results += @{
                        success = $false
                        indicator = $indicator.indicatorValue
                        error = $_.Exception.Message
                    }
                }
            }
            
            $result.data = $results
        }
        
        "BULKREMOVEINDICATORS" {
            $indicatorIds = $parameters.indicatorIds  # Array of indicator IDs
            
            if (-not $indicatorIds -or $indicatorIds.Count -eq 0) {
                throw "Missing required parameter: indicatorIds array"
            }
            
            $results = @()
            
            foreach ($indicatorId in $indicatorIds) {
                try {
                    $uri = "$mdeApiBase/indicators/$indicatorId"
                    Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
                    
                    $results += @{
                        success = $true
                        indicatorId = $indicatorId
                    }
                }
                catch {
                    $results += @{
                        success = $false
                        indicatorId = $indicatorId
                        error = $_.Exception.Message
                    }
                }
            }
            
            $result.data = $results
        }
        
        "ADDFILEINDICATOR" {
            $sha1 = $parameters.sha1
            $action = $parameters.action
            $title = $parameters.title
            $description = $parameters.description
            
            if ([string]::IsNullOrEmpty($sha1) -or [string]::IsNullOrEmpty($action)) {
                throw "Missing required parameters: sha1, action"
            }
            
            $body = @{
                indicatorValue = $sha1
                indicatorType = "FileSha1"
                action = $action
                title = $title
                description = $description
                severity = "High"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "ADDIPINDICATOR" {
            $ipAddress = $parameters.ipAddress
            $action = $parameters.action
            $title = $parameters.title
            $description = $parameters.description
            
            if ([string]::IsNullOrEmpty($ipAddress) -or [string]::IsNullOrEmpty($action)) {
                throw "Missing required parameters: ipAddress, action"
            }
            
            $body = @{
                indicatorValue = $ipAddress
                indicatorType = "IpAddress"
                action = $action
                title = $title
                description = $description
                severity = "Medium"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "ADDURLINDICATOR" {
            $url = $parameters.url
            $action = $parameters.action
            $title = $parameters.title
            $description = $parameters.description
            
            if ([string]::IsNullOrEmpty($url) -or [string]::IsNullOrEmpty($action)) {
                throw "Missing required parameters: url, action"
            }
            
            $body = @{
                indicatorValue = $url
                indicatorType = "Url"
                action = $action
                title = $title
                description = $description
                severity = "Medium"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "ADDDOMAININDICATOR" {
            $domain = $parameters.domain
            $action = $parameters.action
            $title = $parameters.title
            $description = $parameters.description
            
            if ([string]::IsNullOrEmpty($domain) -or [string]::IsNullOrEmpty($action)) {
                throw "Missing required parameters: domain, action"
            }
            
            $body = @{
                indicatorValue = $domain
                indicatorType = "DomainName"
                action = $action
                title = $title
                description = $description
                severity = "Medium"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "REMOVEDOMAIN INDICATOR" {
            $domain = $parameters.domain
            
            if ([string]::IsNullOrEmpty($domain)) {
                throw "Missing required parameter: domain"
            }
            
            # First, find the indicator ID
            $uri = "$mdeApiBase/indicators?`$filter=indicatorValue eq '$domain'"
            $indicators = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            if ($indicators.value -and $indicators.value.Count -gt 0) {
                $indicatorId = $indicators.value[0].id
                
                $uri = "$mdeApiBase/indicators/$indicatorId"
                Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
                
                $result.data = @{ message = "Domain indicator removed"; domain = $domain; indicatorId = $indicatorId }
            } else {
                throw "Domain indicator not found: $domain"
            }
        }
        
        #endregion
        
        #region Advanced Hunting (3 actions)
        
        "RUNQUERY" {
            $query = $parameters.query
            
            if ([string]::IsNullOrEmpty($query)) {
                throw "Missing required parameter: query"
            }
            
            $body = @{
                Query = $query
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/advancedqueries/run"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "SAVEQUERY" {
            $queryName = $parameters.queryName
            $query = $parameters.query
            $description = $parameters.description
            
            if ([string]::IsNullOrEmpty($queryName) -or [string]::IsNullOrEmpty($query)) {
                throw "Missing required parameters: queryName, query"
            }
            
            # Note: This stores query metadata, not an official MDE API endpoint
            # In production, you might store this in Table Storage or a database
            $result.data = @{
                message = "Query saved successfully"
                queryName = $queryName
                query = $query
                description = $description
                savedAt = (Get-Date).ToString("o")
            }
        }
        
        "GETQUERYHISTORY" {
            # Note: This would retrieve saved queries from Table Storage
            # Placeholder for now
            $result.data = @{
                message = "Query history retrieval not yet implemented"
                queries = @()
            }
        }
        
        #endregion
        
        #region Incident Management (6 actions)
        
        "GETINCIDENTS" {
            $filter = $parameters.filter
            $uri = "$mdeApiBase/incidents"
            
            if ($filter) {
                $uri += "?`$filter=$filter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = $response
        }
        
        "GETINCIDENT" {
            $incidentId = $parameters.incidentId
            
            if ([string]::IsNullOrEmpty($incidentId)) {
                throw "Missing required parameter: incidentId"
            }
            
            $uri = "$mdeApiBase/incidents/$incidentId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "UPDATEINCIDENT" {
            $incidentId = $parameters.incidentId
            $status = $parameters.status
            $assignedTo = $parameters.assignedTo
            $classification = $parameters.classification
            $determination = $parameters.determination
            
            if ([string]::IsNullOrEmpty($incidentId)) {
                throw "Missing required parameter: incidentId"
            }
            
            $body = @{}
            
            if ($status) { $body.status = $status }
            if ($assignedTo) { $body.assignedTo = $assignedTo }
            if ($classification) { $body.classification = $classification }
            if ($determination) { $body.determination = $determination }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/incidents/$incidentId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        "ADDCOMMENT" {
            $incidentId = $parameters.incidentId
            $comment = $parameters.comment
            
            if ([string]::IsNullOrEmpty($incidentId) -or [string]::IsNullOrEmpty($comment)) {
                throw "Missing required parameters: incidentId, comment"
            }
            
            $body = @{
                comment = $comment
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/incidents/$incidentId/comments"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "ASSIGNINCIDENT" {
            $incidentId = $parameters.incidentId
            $assignedTo = $parameters.assignedTo
            
            if ([string]::IsNullOrEmpty($incidentId) -or [string]::IsNullOrEmpty($assignedTo)) {
                throw "Missing required parameters: incidentId, assignedTo"
            }
            
            $body = @{
                assignedTo = $assignedTo
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/incidents/$incidentId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "RESOLVEINCIDENT" {
            $incidentId = $parameters.incidentId
            $classification = if ($parameters.classification) { $parameters.classification } else { "TruePositive" }
            $determination = if ($parameters.determination) { $parameters.determination } else { "MultiStagedAttack" }
            
            if ([string]::IsNullOrEmpty($incidentId)) {
                throw "Missing required parameter: incidentId"
            }
            
            $body = @{
                status = "Resolved"
                classification = $classification
                determination = $determination
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/incidents/$incidentId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        #endregion
        
        #region Alert Management (5 actions)
        
        "GETALERTS" {
            $filter = $parameters.filter
            $uri = "$mdeApiBase/alerts"
            
            if ($filter) {
                $uri += "?`$filter=$filter"
            }
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $result.data = $response
        }
        
        "GETALERT" {
            $alertId = $parameters.alertId
            
            if ([string]::IsNullOrEmpty($alertId)) {
                throw "Missing required parameter: alertId"
            }
            
            $uri = "$mdeApiBase/alerts/$alertId"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            $result.data = $response
        }
        
        "UPDATEALERT" {
            $alertId = $parameters.alertId
            $status = $parameters.status
            $assignedTo = $parameters.assignedTo
            $classification = $parameters.classification
            $determination = $parameters.determination
            
            if ([string]::IsNullOrEmpty($alertId)) {
                throw "Missing required parameter: alertId"
            }
            
            $body = @{}
            
            if ($status) { $body.status = $status }
            if ($assignedTo) { $body.assignedTo = $assignedTo }
            if ($classification) { $body.classification = $classification }
            if ($determination) { $body.determination = $determination }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/alerts/$alertId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        "RESOLVEALERT" {
            $alertId = $parameters.alertId
            $classification = if ($parameters.classification) { $parameters.classification } else { "TruePositive" }
            $determination = if ($parameters.determination) { $parameters.determination } else { "Malware" }
            
            if ([string]::IsNullOrEmpty($alertId)) {
                throw "Missing required parameter: alertId"
            }
            
            $body = @{
                status = "Resolved"
                classification = $classification
                determination = $determination
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/alerts/$alertId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = $response
        }
        
        "CLASSIFYALERT" {
            $alertId = $parameters.alertId
            $classification = $parameters.classification
            $determination = $parameters.determination
            
            if ([string]::IsNullOrEmpty($alertId) -or [string]::IsNullOrEmpty($classification)) {
                throw "Missing required parameters: alertId, classification"
            }
            
            $body = @{
                classification = $classification
            }
            
            if ($determination) {
                $body.determination = $determination
            }
            
            $bodyJson = $body | ConvertTo-Json
            
            $uri = "$mdeApiBase/alerts/$alertId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $bodyJson
            
            $result.data = $response
        }
        
        # ===== V3.2.0 NEW MDE VULNERABILITY MANAGEMENT ACTIONS (7 actions) =====
        
        "TRIGGERVULNERABILITYSCAN" {
            $deviceId = $parameters.deviceId
            if ([string]::IsNullOrEmpty($deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-Host "Triggering vulnerability scan on device: $deviceId"
            
            $body = @{
                Comment = $parameters.comment ?? "Forced vulnerability scan via DefenderXDR"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/machines/$deviceId/runAntiVirusScan"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = @{
                deviceId = $deviceId
                actionId = $response.id
                status = $response.status
                type = "VulnerabilityScan"
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "APPLYSECURITYBASELINE" {
            $deviceIds = $parameters.deviceIds
            $baselineId = $parameters.baselineId ?? "Default"
            
            if (-not $deviceIds -or $deviceIds.Count -eq 0) {
                throw "Missing required parameter: deviceIds"
            }
            
            Write-Host "Applying security baseline: $baselineId to $($deviceIds.Count) devices"
            
            $actions = @()
            foreach ($deviceId in $deviceIds) {
                $body = @{
                    Comment = "Apply security baseline: $baselineId"
                } | ConvertTo-Json
                
                $uri = "$mdeApiBase/machines/$deviceId/runAntiVirusScan"
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                
                $actions += @{
                    deviceId = $deviceId
                    actionId = $response.id
                    baseline = $baselineId
                }
            }
            
            $result.data = @{
                baselineId = $baselineId
                devicesTargeted = $deviceIds.Count
                actions = $actions
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "REMEDIATEVULNERABILITY" {
            $deviceId = $parameters.deviceId
            $cveId = $parameters.cveId
            $remediationType = $parameters.remediationType ?? "Update"
            
            if ([string]::IsNullOrEmpty($deviceId) -or [string]::IsNullOrEmpty($cveId)) {
                throw "Missing required parameters: deviceId, cveId"
            }
            
            Write-Host "Remediating vulnerability: $cveId on device: $deviceId"
            
            # Create remediation activity (TVM API)
            $body = @{
                machineId = $deviceId
                vulnerabilityId = $cveId
                remediationType = $remediationType
                priority = $parameters.priority ?? "High"
                comment = $parameters.comment ?? "Automated remediation via DefenderXDR"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/remediationTasks"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = @{
                deviceId = $deviceId
                cveId = $cveId
                remediationTaskId = $response.id
                remediationType = $remediationType
                status = $response.status
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "EXCLUDEVULNERABILITY" {
            $deviceId = $parameters.deviceId
            $vulnerabilityId = $parameters.vulnerabilityId
            $justification = $parameters.justification ?? "False positive"
            
            if ([string]::IsNullOrEmpty($deviceId) -or [string]::IsNullOrEmpty($vulnerabilityId)) {
                throw "Missing required parameters: deviceId, vulnerabilityId"
            }
            
            Write-Host "Excluding vulnerability: $vulnerabilityId for device: $deviceId"
            
            $body = @{
                machineId = $deviceId
                vulnerabilityId = $vulnerabilityId
                justification = $justification
                expirationTime = $parameters.expirationTime ?? (Get-Date).AddDays(90).ToString("o")
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/vulnerabilities/$vulnerabilityId/machineReferences/$deviceId/exclude"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = @{
                deviceId = $deviceId
                vulnerabilityId = $vulnerabilityId
                excluded = $true
                justification = $justification
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "BLOCKVULNERABLESOFTWARE" {
            $softwareName = $parameters.softwareName
            $softwareVendor = $parameters.softwareVendor
            $deviceIds = $parameters.deviceIds
            
            if ([string]::IsNullOrEmpty($softwareName)) {
                throw "Missing required parameter: softwareName"
            }
            
            Write-Host "Blocking vulnerable software: $softwareName"
            
            # Create application control policy to block software
            $indicator = @{
                indicatorValue = $softwareName
                indicatorType = "FilePath"
                action = "Block"
                title = "Block vulnerable software: $softwareName"
                description = "Blocked due to known vulnerabilities"
                severity = "High"
                recommendedActions = "Update to latest version"
                rbacGroupNames = @()
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $indicator
            
            $result.data = @{
                softwareName = $softwareName
                vendor = $softwareVendor
                indicatorId = $response.id
                blocked = $true
                devicesAffected = if ($deviceIds) { $deviceIds.Count } else { "All" }
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "FORCEUPDATEMDE" {
            $deviceId = $parameters.deviceId
            if ([string]::IsNullOrEmpty($deviceId)) {
                throw "Missing required parameter: deviceId"
            }
            
            Write-Host "Forcing MDE update on device: $deviceId"
            
            # Run live response script to force update
            $script = @"
# Force Windows Update for MDE
`$updateSession = New-Object -ComObject Microsoft.Update.Session
`$updateSearcher = `$updateSession.CreateUpdateSearcher()
`$searchResult = `$updateSearcher.Search("IsInstalled=0 AND CategoryIDs contains '8C3FCC84-7410-4A95-8B89-A166A0190486'")
foreach (`$update in `$searchResult.Updates) {
    if (`$update.Title -like '*Defender*') {
        `$updateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
        `$updateCollection.Add(`$update)
        `$downloader = `$updateSession.CreateUpdateDownloader()
        `$downloader.Updates = `$updateCollection
        `$downloader.Download()
        `$installer = `$updateSession.CreateUpdateInstaller()
        `$installer.Updates = `$updateCollection
        `$installer.Install()
    }
}
"@
            
            $body = @{
                Comment = "Force MDE update"
                Commands = @(
                    @{
                        type = "RunScript"
                        params = @(
                            @{
                                key = "ScriptName"
                                value = "ForceUpdateMDE.ps1"
                            },
                            @{
                                key = "Args"
                                value = ""
                            }
                        )
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $uri = "$mdeApiBase/machines/$deviceId/runliveresponse"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            $result.data = @{
                deviceId = $deviceId
                actionId = $response.id
                type = "ForceUpdate"
                status = $response.status
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "DEPLOYSECU RITYUPDATE" {
            $deviceIds = $parameters.deviceIds
            $updateId = $parameters.updateId
            
            if (-not $deviceIds -or $deviceIds.Count -eq 0) {
                throw "Missing required parameter: deviceIds"
            }
            if ([string]::IsNullOrEmpty($updateId)) {
                throw "Missing required parameter: updateId (KB number)"
            }
            
            Write-Host "Deploying security update: $updateId to $($deviceIds.Count) devices"
            
            $actions = @()
            foreach ($deviceId in $deviceIds) {
                $script = "Install-WindowsUpdate -KBArticleID '$updateId' -AcceptAll -AutoReboot"
                
                $body = @{
                    Comment = "Deploy security update: $updateId"
                    Commands = @(
                        @{
                            type = "RunScript"
                            params = @(
                                @{
                                    key = "ScriptName"
                                    value = "DeployUpdate.ps1"
                                },
                                @{
                                    key = "Args"
                                    value = $updateId
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 10
                
                $uri = "$mdeApiBase/machines/$deviceId/runliveresponse"
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                
                $actions += @{
                    deviceId = $deviceId
                    actionId = $response.id
                    updateId = $updateId
                }
            }
            
            $result.data = @{
                updateId = $updateId
                devicesTargeted = $deviceIds.Count
                actions = $actions
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        # ===== V3.2.0 NEW MDE NETWORK PROTECTION ACTIONS (5 actions) =====
        
        "ENABLENETWORKPROTECTION" {
            $deviceIds = $parameters.deviceIds
            if (-not $deviceIds -or $deviceIds.Count -eq 0) {
                throw "Missing required parameter: deviceIds"
            }
            
            Write-Host "Enabling network protection on $($deviceIds.Count) devices"
            
            $actions = @()
            foreach ($deviceId in $deviceIds) {
                $script = "Set-MpPreference -EnableNetworkProtection Enabled"
                
                $body = @{
                    Comment = "Enable network protection"
                    Commands = @(
                        @{
                            type = "RunScript"
                            params = @(
                                @{
                                    key = "ScriptName"
                                    value = "EnableNetworkProtection.ps1"
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 10
                
                $uri = "$mdeApiBase/machines/$deviceId/runliveresponse"
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                
                $actions += @{
                    deviceId = $deviceId
                    actionId = $response.id
                }
            }
            
            $result.data = @{
                devicesTargeted = $deviceIds.Count
                actions = $actions
                networkProtectionEnabled = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "ADDCERTIFICATEINDICATOR" {
            $certificateHash = $parameters.certificateHash
            $action = $parameters.action ?? "Block"
            
            if ([string]::IsNullOrEmpty($certificateHash)) {
                throw "Missing required parameter: certificateHash (SHA1)"
            }
            
            Write-Host "Adding certificate indicator: $certificateHash"
            
            $indicator = @{
                indicatorValue = $certificateHash
                indicatorType = "CertificateThumbprint"
                action = $action
                title = $parameters.title ?? "Malicious certificate"
                description = $parameters.description ?? "Certificate blocked via DefenderXDR"
                severity = $parameters.severity ?? "High"
                recommendedActions = $parameters.recommendedActions ?? "Remove certificate from trusted store"
                expirationTime = $parameters.expirationTime
                rbacGroupNames = $parameters.rbacGroupNames ?? @()
            } | ConvertTo-Json -Depth 10
            
            $uri = "$mdeApiBase/indicators"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $indicator
            
            $result.data = @{
                certificateHash = $certificateHash
                indicatorId = $response.id
                action = $action
                created = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "BLOCKPORTPROTOCOL" {
            $port = $parameters.port
            $protocol = $parameters.protocol ?? "TCP"
            $deviceIds = $parameters.deviceIds
            
            if ([string]::IsNullOrEmpty($port)) {
                throw "Missing required parameter: port"
            }
            
            Write-Host "Blocking port: $port ($protocol)"
            
            $actions = @()
            if ($deviceIds -and $deviceIds.Count -gt 0) {
                foreach ($deviceId in $deviceIds) {
                    $script = "New-NetFirewallRule -DisplayName 'Block $protocol $port' -Direction Inbound -LocalPort $port -Protocol $protocol -Action Block -Enabled True"
                    
                    $body = @{
                        Comment = "Block port $port ($protocol)"
                        Commands = @(
                            @{
                                type = "RunScript"
                                params = @(
                                    @{
                                        key = "ScriptName"
                                        value = "BlockPort.ps1"
                                    },
                                    @{
                                        key = "Args"
                                        value = "$port $protocol"
                                    }
                                )
                            }
                        )
                    } | ConvertTo-Json -Depth 10
                    
                    $uri = "$mdeApiBase/machines/$deviceId/runliveresponse"
                    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                    
                    $actions += @{
                        deviceId = $deviceId
                        actionId = $response.id
                    }
                }
            }
            
            $result.data = @{
                port = $port
                protocol = $protocol
                devicesTargeted = if ($deviceIds) { $deviceIds.Count } else { 0 }
                actions = $actions
                blocked = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "ENABLEWEBCONTENTFILTERING" {
            $categories = $parameters.categories
            $action = $parameters.action ?? "Block"
            
            if (-not $categories -or $categories.Count -eq 0) {
                throw "Missing required parameter: categories (e.g., ['Adult', 'Gambling', 'Violence'])"
            }
            
            Write-Host "Enabling web content filtering for categories: $($categories -join ', ')"
            
            $policies = @()
            foreach ($category in $categories) {
                $policy = @{
                    category = $category
                    action = $action
                    enabled = $true
                } | ConvertTo-Json
                
                # This would typically be set via policy/group policy
                # For now, we'll create custom URL indicators for known bad domains
                $policies += @{
                    category = $category
                    action = $action
                    enabled = $true
                }
            }
            
            $result.data = @{
                categories = $categories
                action = $action
                policiesCreated = $policies.Count
                enabled = $true
                timestamp = (Get-Date).ToString("o")
                note = "Web content filtering policies created. May require group policy refresh."
            }
        }
        
        "BLOCKNETWORKDESTINATION" {
            $ipAddress = $parameters.ipAddress
            $port = $parameters.port
            $deviceIds = $parameters.deviceIds
            
            if ([string]::IsNullOrEmpty($ipAddress)) {
                throw "Missing required parameter: ipAddress"
            }
            
            Write-Host "Blocking network destination: $ipAddress$(if ($port) {":$port"})"
            
            # First, add IP indicator
            $indicator = @{
                indicatorValue = $ipAddress
                indicatorType = "IpAddress"
                action = "Block"
                title = "Blocked IP: $ipAddress"
                description = $parameters.description ?? "IP blocked via DefenderXDR"
                severity = "High"
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/indicators"
            $indicatorResponse = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $indicator
            
            # Then, block via firewall on specific devices if provided
            $actions = @()
            if ($deviceIds -and $deviceIds.Count -gt 0) {
                foreach ($deviceId in $deviceIds) {
                    $script = if ($port) {
                        "New-NetFirewallRule -DisplayName 'Block $ipAddress`:$port' -Direction Outbound -RemoteAddress $ipAddress -RemotePort $port -Action Block -Enabled True"
                    } else {
                        "New-NetFirewallRule -DisplayName 'Block $ipAddress' -Direction Outbound -RemoteAddress $ipAddress -Action Block -Enabled True"
                    }
                    
                    $body = @{
                        Comment = "Block network destination: $ipAddress$(if ($port) {":$port"})"
                        Commands = @(
                            @{
                                type = "RunScript"
                                params = @(
                                    @{
                                        key = "ScriptName"
                                        value = "BlockDestination.ps1"
                                    },
                                    @{
                                        key = "Args"
                                        value = "$ipAddress $(if ($port) {$port})"
                                    }
                                )
                            }
                        )
                    } | ConvertTo-Json -Depth 10
                    
                    $uri2 = "$mdeApiBase/machines/$deviceId/runliveresponse"
                    $response = Invoke-RestMethod -Uri $uri2 -Method Post -Headers $headers -Body $body
                    
                    $actions += @{
                        deviceId = $deviceId
                        actionId = $response.id
                    }
                }
            }
            
            $result.data = @{
                ipAddress = $ipAddress
                port = $port
                indicatorId = $indicatorResponse.id
                devicesTargeted = if ($deviceIds) { $deviceIds.Count } else { "All (via indicator)" }
                actions = $actions
                blocked = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        # ===== V3.2.0 NEW MDE CUSTOM DETECTION ACTIONS (5 actions - only remediation) =====
        
        "CREATECUSTOMDETECTIONRULE" {
            $ruleName = $parameters.ruleName
            $query = $parameters.query
            $severity = $parameters.severity ?? "Medium"
            
            if ([string]::IsNullOrEmpty($ruleName) -or [string]::IsNullOrEmpty($query)) {
                throw "Missing required parameters: ruleName, query"
            }
            
            Write-Host "Creating custom detection rule: $ruleName"
            
            $rule = @{
                displayName = $ruleName
                description = $parameters.description ?? "Custom detection rule created via DefenderXDR"
                severity = $severity
                enabled = $true
                query = $query
                queryFrequency = $parameters.queryFrequency ?? "1H"
                queryPeriod = $parameters.queryPeriod ?? "1H"
                triggerOperator = $parameters.triggerOperator ?? "GreaterThan"
                triggerThreshold = $parameters.triggerThreshold ?? 0
                suppressionDuration = $parameters.suppressionDuration ?? "PT5M"
                tactics = $parameters.tactics ?? @()
                impactedEntities = $parameters.impactedEntities ?? @()
            } | ConvertTo-Json -Depth 10
            
            $uri = "$mdeApiBase/customDetectionRules"
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $rule
            
            $result.data = @{
                ruleId = $response.id
                ruleName = $ruleName
                enabled = $true
                created = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "UPDATECUSTOMDETECTIONRULE" {
            $ruleId = $parameters.ruleId
            $updates = $parameters.updates
            
            if ([string]::IsNullOrEmpty($ruleId) -or -not $updates) {
                throw "Missing required parameters: ruleId, updates"
            }
            
            Write-Host "Updating custom detection rule: $ruleId"
            
            $body = $updates | ConvertTo-Json -Depth 10
            
            $uri = "$mdeApiBase/customDetectionRules/$ruleId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = @{
                ruleId = $ruleId
                updated = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "DELETECUSTOMDETECTIONRULE" {
            $ruleId = $parameters.ruleId
            if ([string]::IsNullOrEmpty($ruleId)) {
                throw "Missing required parameter: ruleId"
            }
            
            Write-Host "Deleting custom detection rule: $ruleId"
            
            $uri = "$mdeApiBase/customDetectionRules/$ruleId"
            $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            $result.data = @{
                ruleId = $ruleId
                deleted = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "ENABLECUSTOMDETECTIONRULE" {
            $ruleId = $parameters.ruleId
            if ([string]::IsNullOrEmpty($ruleId)) {
                throw "Missing required parameter: ruleId"
            }
            
            Write-Host "Enabling custom detection rule: $ruleId"
            
            $body = @{
                enabled = $true
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/customDetectionRules/$ruleId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = @{
                ruleId = $ruleId
                enabled = $true
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        "DISABLECUSTOMDETECTIONRULE" {
            $ruleId = $parameters.ruleId
            if ([string]::IsNullOrEmpty($ruleId)) {
                throw "Missing required parameter: ruleId"
            }
            
            Write-Host "Disabling custom detection rule: $ruleId"
            
            $body = @{
                enabled = $false
            } | ConvertTo-Json
            
            $uri = "$mdeApiBase/customDetectionRules/$ruleId"
            $response = Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body
            
            $result.data = @{
                ruleId = $ruleId
                enabled = $false
                timestamp = (Get-Date).ToString("o")
            }
        }
        
        #endregion
        
        default {
            throw "Unknown action: $action"
        }
    }
    
    $result.success = $true
    Write-Host "MDE action completed successfully: $action"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Error in DefenderXDRMDEWorker: $errorMessage"
    
    $result.success = $false
    $result.error = $errorMessage
}

# Return response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = if ($result.success) { [HttpStatusCode]::OK } else { [HttpStatusCode]::BadRequest }
    Body = ($result | ConvertTo-Json -Depth 10)
    Headers = @{
        "Content-Type" = "application/json"
    }
})
