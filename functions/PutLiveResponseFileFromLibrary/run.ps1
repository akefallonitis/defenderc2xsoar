using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PutLiveResponseFileFromLibrary: Processing file deployment request"

# Get parameters from query string or body
$fileName = $Request.Query.fileName
$deviceIds = $Request.Query.DeviceIds
$tenantId = $Request.Query.tenantId
$targetFileName = $Request.Query.TargetFileName

if ($Request.Body) {
    $fileName = $Request.Body.fileName ?? $fileName
    $deviceIds = $Request.Body.DeviceIds ?? $deviceIds
    $tenantId = $Request.Body.tenantId ?? $tenantId
    $targetFileName = $Request.Body.TargetFileName ?? $targetFileName
}

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate required parameters
if (-not $fileName -or -not $deviceIds -or -not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success   = $false
            timestamp = (Get-Date).ToString("o")
            error     = "Missing required parameters: fileName, DeviceIds, and tenantId are required"
        } | ConvertTo-Json
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
    return
}

# Validate environment variables are configured
if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success   = $false
            timestamp = (Get-Date).ToString("o")
            error     = "Function app not configured: APPID and SECRETID environment variables must be set"
        } | ConvertTo-Json
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
    return
}

try {
    # Check if storage context is initialized
    if (-not $global:StorageContext) {
        throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
    }
    
    # Sanitize file name
    $fileName = [System.IO.Path]::GetFileName($fileName)
    
    # Use fileName as target if not specified
    if (-not $targetFileName) {
        $targetFileName = $fileName
    }
    
    Write-Host "📥 Retrieving file: $fileName from library container..."
    
    # Get file from library
    $blob = Get-AzStorageBlob -Container "library" -Blob $fileName -Context $global:StorageContext -ErrorAction Stop
    
    if (-not $blob) {
        throw "File not found in library: $fileName"
    }
    
    # Download blob content to memory
    $memoryStream = New-Object System.IO.MemoryStream
    $blob.ICloudBlob.DownloadToStream($memoryStream)
    $memoryStream.Position = 0
    
    # Convert to Base64
    $fileBytes = $memoryStream.ToArray()
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    
    Write-Host "✅ File retrieved from library: $fileName ($($fileBytes.Length) bytes)"
    
    # Connect to MDE
    Write-Host "🔐 Authenticating to MDE..."
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId
    
    # Parse device IDs
    $deviceIdList = $deviceIds.Split(',').Trim()
    $deviceId = $deviceIdList[0]
    
    Write-Host "📤 Starting Live Response session for device: $deviceId"
    
    # Start Live Response session
    $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "File deployment from library via Azure Function"
    
    Write-Host "⏳ Waiting for session to be ready..."
    Start-Sleep -Seconds 5
    
    # Upload file to MDE library first
    $headers = @{
        "Authorization" = "Bearer $($token.AccessToken)"
        "Content-Type" = "application/json"
    }
    
    $libraryUri = "https://api.securitycenter.microsoft.com/api/liveresponse/library/files"
    
    # Ensure Base64 content is clean (no whitespace)
    $cleanBase64 = $fileBase64 -replace '\s', ''
    
    $uploadBody = @{
        FileName = $targetFileName
        FileContent = $cleanBase64
    } | ConvertTo-Json
    
    Write-Host "⏳ Uploading file to MDE library..."
    $uploadResult = Invoke-RestMethod -Method Post -Uri $libraryUri -Headers $headers -Body $uploadBody -ContentType "application/json"
    
    # Execute putfile command
    $fileParams = @{
        FileName = $targetFileName
    }
    
    Write-Host "⏳ Transferring file to device..."
    $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "putfile" -Parameters $fileParams
    
    Write-Host "⏳ Waiting for file upload to complete..."
    $commandResult = Wait-MDELiveResponseCommand -Token $token -CommandId $command.id -TimeoutSeconds 300
    
    if ($commandResult -and $commandResult.status -eq "Completed") {
        Write-Host "✅ File deployed successfully to device"
        
        $result = @{
            success         = $true
            status          = "Success"
            message         = "File deployed successfully from library to device"
            fileName        = $fileName
            targetFileName  = $targetFileName
            deviceId        = $deviceId
            sessionId       = $session.id
            commandId       = $command.id
            timestamp       = (Get-Date).ToString("o")
            error           = $null
        }
        
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = ($result | ConvertTo-Json -Depth 5)
            Headers = @{
                "Content-Type" = "application/json"
            }
        })
    } else {
        throw "File deployment failed or timed out"
    }

} catch {
    Write-Error "Error in PutLiveResponseFileFromLibrary: $($_.Exception.Message)"
    
    $statusCode = if ($_.Exception.Message -like "*not found*") {
        [HttpStatusCode]::NotFound
    } else {
        [HttpStatusCode]::InternalServerError
    }
    
    $errorResult = @{
        success   = $false
        status    = "Failed"
        message   = "File deployment failed"
        fileName  = $fileName
        deviceId  = $deviceIds
        timestamp = (Get-Date).ToString("o")
        error     = $_.Exception.Message
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Body = ($errorResult | ConvertTo-Json -Depth 5)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
}
