using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "DefenderC2Orchestrator: Processing Live Response request"

# Get parameters from query string or body
$function = $Request.Query.Function
$tenantId = $Request.Query.tenantId
$deviceIds = $Request.Query.DeviceIds
$sessionId = $Request.Query.sessionId
$scriptName = $Request.Query.scriptName
$arguments = $Request.Query.arguments
$filePath = $Request.Query.filePath
$fileName = $Request.Query.fileName
$targetFileName = $Request.Query.TargetFileName
$fileContent = $Request.Query.fileContent
$commandId = $Request.Query.commandId

if ($Request.Body) {
    $function = $Request.Body.Function ?? $function
    $tenantId = $Request.Body.tenantId ?? $tenantId
    $deviceIds = $Request.Body.DeviceIds ?? $deviceIds
    $sessionId = $Request.Body.sessionId ?? $sessionId
    $scriptName = $Request.Body.scriptName ?? $scriptName
    $arguments = $Request.Body.arguments ?? $arguments
    $filePath = $Request.Body.filePath ?? $filePath
    $fileName = $Request.Body.fileName ?? $fileName
    $targetFileName = $Request.Body.TargetFileName ?? $targetFileName
    $fileContent = $Request.Body.fileContent ?? $fileContent
    $commandId = $Request.Body.commandId ?? $commandId
}

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate required parameters
if (-not $function -or -not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters: Function and tenantId are required"
        } | ConvertTo-Json
    })
    return
}

# Validate environment variables are configured
if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = "Function app not configured: APPID and SECRETID environment variables must be set"
        } | ConvertTo-Json
    })
    return
}

# Helper function for API calls with rate limit handling
function Invoke-MDEApiWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Params,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    
    while ($retryCount -le $MaxRetries) {
        try {
            $response = Invoke-RestMethod @Params
            return $response
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            if ($statusCode -eq 429) {
                # Rate limited
                $retryAfter = 30
                if ($_.Exception.Response.Headers['Retry-After']) {
                    $retryAfter = [int]$_.Exception.Response.Headers['Retry-After']
                }
                
                Write-Host "⚠️ Rate limited (429). Waiting $retryAfter seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryAfter
                $retryCount++
            } elseif ($statusCode -ge 500 -and $retryCount -lt $MaxRetries) {
                # Server error - retry with exponential backoff
                $waitTime = [Math]::Pow(2, $retryCount) * 5
                Write-Host "⚠️ Server error ($statusCode). Waiting $waitTime seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $waitTime
                $retryCount++
            } else {
                throw
            }
        }
    }
    
    throw "Max retries exceeded"
}

try {
    # Connect to MDE using App Registration with Client Secret
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

    $result = @{
        function = $function
        status = "Processing"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    # Parse device IDs if provided
    $deviceIdList = if ($deviceIds) { $deviceIds.Split(',').Trim() } else { @() }

    # Execute function based on type
    switch ($function) {
        "GetLiveResponseSessions" {
            Write-Host "📋 Listing Live Response sessions..."
            
            $headers = Get-MDEAuthHeaders -Token $token
            $uri = "https://api.securitycenter.microsoft.com/api/liveresponse/sessions"
            
            $params = @{
                Method = "Get"
                Uri = $uri
                Headers = $headers
            }
            
            $sessions = Invoke-MDEApiWithRetry -Params $params
            
            $result.status = "Success"
            $result.message = "Retrieved Live Response sessions"
            $result.sessions = $sessions.value
            $result.count = $sessions.value.Count
        }
        
        "InvokeLiveResponseScript" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for script execution"
            }
            if (-not $scriptName) {
                throw "Script name required"
            }
            
            Write-Host "🚀 Starting Live Response session and executing script: $scriptName"
            
            $deviceId = $deviceIdList[0]
            
            # Start session
            $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "Script execution via MDEOrchestrator"
            
            Write-Host "⏳ Waiting for session to be ready..."
            Start-Sleep -Seconds 5
            
            # Execute script
            $scriptParams = @{
                ScriptName = $scriptName
            }
            if ($arguments) {
                $scriptParams.Arguments = $arguments
            }
            
            $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "runscript" -Parameters $scriptParams
            
            $result.status = "Initiated"
            $result.message = "Script execution initiated"
            $result.sessionId = $session.id
            $result.commandId = $command.id
            $result.deviceId = $deviceId
        }
        
        "GetLiveResponseOutput" {
            if (-not $commandId) {
                throw "Command ID required"
            }
            
            Write-Host "📊 Getting command output for: $commandId"
            
            $commandResult = Get-MDELiveResponseCommandResult -Token $token -CommandId $commandId
            
            $result.status = $commandResult.status
            $result.message = "Command result retrieved"
            $result.commandId = $commandId
            $result.commandStatus = $commandResult.status
            
            if ($commandResult.status -eq "Completed") {
                $result.output = $commandResult.value
                $result.status = "Success"
            } elseif ($commandResult.status -eq "Failed") {
                $result.error = $commandResult.error
                $result.status = "Failed"
            }
        }
        
        "GetLiveResponseFile" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for file download"
            }
            if (-not $filePath) {
                throw "File path required"
            }
            
            Write-Host "📥 Starting Live Response session and downloading file: $filePath"
            
            $deviceId = $deviceIdList[0]
            
            # Start session
            $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "File download via MDEOrchestrator"
            
            Write-Host "⏳ Waiting for session to be ready..."
            Start-Sleep -Seconds 5
            
            # Execute getfile command
            $fileParams = @{
                Path = $filePath
            }
            
            $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "getfile" -Parameters $fileParams
            
            Write-Host "⏳ Waiting for file download to complete..."
            $commandResult = Wait-MDELiveResponseCommand -Token $token -CommandId $command.id -TimeoutSeconds 300
            
            if ($commandResult -and $commandResult.status -eq "Completed") {
                # Get file content from download URL
                $fileUrl = $commandResult.value
                $headers = Get-MDEAuthHeaders -Token $token
                
                $fileBytes = Invoke-MDEApiWithRetry -Params @{
                    Method = "Get"
                    Uri = $fileUrl
                    Headers = $headers
                }
                
                # Convert to Base64 for return
                $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileBytes))
                $extractedFileName = Split-Path -Leaf $filePath
                
                $result.status = "Success"
                $result.message = "File downloaded successfully"
                $result.fileName = $extractedFileName
                $result.fileContent = $base64Content
                $result.downloadUrl = "data:application/octet-stream;base64,$base64Content"
                $result.sessionId = $session.id
                $result.deviceId = $deviceId
            } else {
                throw "File download failed or timed out"
            }
        }
        
        "PutLiveResponseFile" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for file upload"
            }
            if (-not $targetFileName) {
                throw "Target file name required"
            }
            if (-not $fileContent) {
                throw "File content (Base64) required"
            }
            
            Write-Host "📤 Starting Live Response session and uploading file: $targetFileName"
            
            $deviceId = $deviceIdList[0]
            
            # Start session
            $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "File upload via MDEOrchestrator"
            
            Write-Host "⏳ Waiting for session to be ready..."
            Start-Sleep -Seconds 5
            
            # Upload file to library first
            $headers = Get-MDEAuthHeaders -Token $token
            $libraryUri = "https://api.securitycenter.microsoft.com/api/liveresponse/library/files"
            
            # Ensure Base64 content is clean (no whitespace)
            $cleanBase64 = $fileContent -replace '\s', ''
            
            $uploadBody = @{
                FileName = $targetFileName
                FileContent = $cleanBase64
            } | ConvertTo-Json
            
            Write-Host "⏳ Uploading file to library..."
            $uploadParams = @{
                Method = "Post"
                Uri = $libraryUri
                Headers = $headers
                Body = $uploadBody
                ContentType = "application/json"
            }
            
            $uploadResult = Invoke-MDEApiWithRetry -Params $uploadParams
            
            # Execute putfile command
            $fileParams = @{
                FileName = $targetFileName
            }
            
            Write-Host "⏳ Transferring file to device..."
            $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "putfile" -Parameters $fileParams
            
            Write-Host "⏳ Waiting for file upload to complete..."
            $commandResult = Wait-MDELiveResponseCommand -Token $token -CommandId $command.id -TimeoutSeconds 300
            
            if ($commandResult -and $commandResult.status -eq "Completed") {
                $result.status = "Success"
                $result.message = "File uploaded successfully"
                $result.fileName = $targetFileName
                $result.sessionId = $session.id
                $result.commandId = $command.id
                $result.deviceId = $deviceId
            } else {
                throw "File upload failed or timed out"
            }
        }
        
        "PutLiveResponseFileFromLibrary" {
            if ($deviceIdList.Count -eq 0) {
                throw "Device ID required for file deployment from library"
            }
            if (-not $fileName) {
                throw "File name required"
            }
            
            Write-Host "📥 Retrieving file from Azure Storage library: $fileName"
            
            # Check if storage context is initialized
            if (-not $global:StorageContext) {
                throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
            }
            
            # Sanitize file name
            $sanitizedFileName = [System.IO.Path]::GetFileName($fileName)
            
            # Use fileName as target if not specified
            if (-not $targetFileName) {
                $targetFileName = $sanitizedFileName
            }
            
            # Get file from Azure Storage library
            $blob = Get-AzStorageBlob -Container "library" -Blob $sanitizedFileName -Context $global:StorageContext -ErrorAction Stop
            
            if (-not $blob) {
                throw "File not found in library: $sanitizedFileName"
            }
            
            # Download blob content to memory
            $memoryStream = New-Object System.IO.MemoryStream
            $blob.ICloudBlob.DownloadToStream($memoryStream)
            $memoryStream.Position = 0
            
            # Convert to Base64
            $fileBytes = $memoryStream.ToArray()
            $fileBase64 = [Convert]::ToBase64String($fileBytes)
            
            Write-Host "✅ File retrieved from library: $sanitizedFileName ($($fileBytes.Length) bytes)"
            
            $deviceId = $deviceIdList[0]
            
            # Start Live Response session
            Write-Host "📤 Starting Live Response session for device: $deviceId"
            $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "File deployment from library via DefenderC2Orchestrator"
            
            Write-Host "⏳ Waiting for session to be ready..."
            Start-Sleep -Seconds 5
            
            # Upload file to MDE library
            $headers = Get-MDEAuthHeaders -Token $token
            $libraryUri = "https://api.securitycenter.microsoft.com/api/liveresponse/library/files"
            
            # Ensure Base64 content is clean (no whitespace)
            $cleanBase64 = $fileBase64 -replace '\s', ''
            
            $uploadBody = @{
                FileName = $targetFileName
                FileContent = $cleanBase64
            } | ConvertTo-Json
            
            Write-Host "⏳ Uploading file to MDE library..."
            $uploadParams = @{
                Method = "Post"
                Uri = $libraryUri
                Headers = $headers
                Body = $uploadBody
                ContentType = "application/json"
            }
            
            $uploadResult = Invoke-MDEApiWithRetry -Params $uploadParams
            
            # Execute putfile command
            $fileParams = @{
                FileName = $targetFileName
            }
            
            Write-Host "⏳ Transferring file to device..."
            $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "putfile" -Parameters $fileParams
            
            Write-Host "⏳ Waiting for file transfer to complete..."
            $commandResult = Wait-MDELiveResponseCommand -Token $token -CommandId $command.id -TimeoutSeconds 300
            
            if ($commandResult -and $commandResult.status -eq "Completed") {
                $result.status = "Success"
                $result.message = "File deployed successfully from library to device"
                $result.fileName = $sanitizedFileName
                $result.targetFileName = $targetFileName
                $result.sessionId = $session.id
                $result.commandId = $command.id
                $result.deviceId = $deviceId
            } else {
                throw "File deployment failed or timed out"
            }
        }
        
        "ListLibraryFiles" {
            Write-Host "📋 Retrieving files from library container..."
            
            # Check if storage context is initialized
            if (-not $global:StorageContext) {
                throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
            }
            
            # Get all blobs from library container
            $blobs = Get-AzStorageBlob -Container "library" -Context $global:StorageContext -ErrorAction Stop
            
            # Format file list
            $files = @()
            foreach ($blob in $blobs) {
                $files += @{
                    fileName     = $blob.Name
                    size         = $blob.Length
                    lastModified = $blob.LastModified.DateTime.ToString("o")
                    contentType  = $blob.ICloudBlob.Properties.ContentType
                    etag         = $blob.ICloudBlob.Properties.ETag
                }
            }
            
            Write-Host "✅ Found $($files.Count) file(s) in library"
            
            $result.status = "Success"
            $result.data = $files
            $result.count = $files.Count
        }
        
        "GetLibraryFile" {
            if (-not $fileName) {
                throw "File name required for GetLibraryFile"
            }
            
            Write-Host "📥 Retrieving file: $fileName from library container..."
            
            # Check if storage context is initialized
            if (-not $global:StorageContext) {
                throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
            }
            
            # Sanitize file name to prevent path traversal
            $sanitizedFileName = [System.IO.Path]::GetFileName($fileName)
            
            # Check if blob exists
            $blob = Get-AzStorageBlob -Container "library" -Blob $sanitizedFileName -Context $global:StorageContext -ErrorAction Stop
            
            if (-not $blob) {
                throw "File not found: $sanitizedFileName"
            }
            
            # Download blob content to memory
            $memoryStream = New-Object System.IO.MemoryStream
            $blob.ICloudBlob.DownloadToStream($memoryStream)
            $memoryStream.Position = 0
            
            # Convert to Base64
            $fileBytes = $memoryStream.ToArray()
            $fileBase64 = [Convert]::ToBase64String($fileBytes)
            
            Write-Host "✅ File retrieved successfully: $sanitizedFileName ($($fileBytes.Length) bytes)"
            
            $result.status = "Success"
            $result.fileName = $sanitizedFileName
            $result.fileContent = $fileBase64
            $result.size = $fileBytes.Length
        }
        
        "DeleteLibraryFile" {
            if (-not $fileName) {
                throw "File name required for DeleteLibraryFile"
            }
            
            Write-Host "🗑️ Deleting file: $fileName from library container..."
            
            # Check if storage context is initialized
            if (-not $global:StorageContext) {
                throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
            }
            
            # Sanitize file name to prevent path traversal
            $sanitizedFileName = [System.IO.Path]::GetFileName($fileName)
            
            # Check if blob exists first
            $blob = Get-AzStorageBlob -Container "library" -Blob $sanitizedFileName -Context $global:StorageContext -ErrorAction SilentlyContinue
            
            if (-not $blob) {
                throw "File not found: $sanitizedFileName"
            }
            
            # Delete the blob
            Remove-AzStorageBlob -Container "library" -Blob $sanitizedFileName -Context $global:StorageContext -Force -ErrorAction Stop
            
            Write-Host "✅ File deleted successfully: $sanitizedFileName"
            
            $result.status = "Success"
            $result.message = "File deleted successfully from library"
            $result.fileName = $sanitizedFileName
        }
        
        default {
            throw "Unknown function: $function. Supported functions: GetLiveResponseSessions, InvokeLiveResponseScript, GetLiveResponseOutput, GetLiveResponseFile, PutLiveResponseFile, PutLiveResponseFileFromLibrary, ListLibraryFiles, GetLibraryFile, DeleteLibraryFile"
        }
    }

    # Return success response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($result | ConvertTo-Json -Depth 10)
    })

} catch {
    Write-Error "Error in MDEOrchestrator: $($_.Exception.Message)"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = $_.Exception.Message
            details = $_.Exception.ToString()
            function = $function
        } | ConvertTo-Json
    })
}
