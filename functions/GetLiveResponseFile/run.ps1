using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "GetLiveResponseFile: Processing file download request from MDE device"

# Get parameters from query string or body
$deviceId = $Request.Query.DeviceId
$filePath = $Request.Query.FilePath
$tenantId = $Request.Query.tenantId

if ($Request.Body) {
    $deviceId = $Request.Body.DeviceId ?? $deviceId
    $filePath = $Request.Body.FilePath ?? $filePath
    $tenantId = $Request.Body.tenantId ?? $tenantId
}

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate required parameters
if (-not $deviceId -or -not $filePath -or -not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success   = $false
            timestamp = (Get-Date).ToString("o")
            error     = "Missing required parameters: DeviceId, FilePath, and tenantId are required"
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
    Write-Host "🔐 Authenticating to MDE..."
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId
    
    Write-Host "📤 Starting Live Response session for device: $deviceId"
    
    # Start Live Response session
    $session = Start-MDELiveResponseSession -Token $token -DeviceId $deviceId -Comment "File download via Azure Function"
    
    Write-Host "⏳ Waiting for session to be ready..."
    Start-Sleep -Seconds 5
    
    # Execute getfile command
    Write-Host "📥 Retrieving file from device: $filePath"
    $params = @{
        Path = $filePath
    }
    
    $command = Invoke-MDELiveResponseCommand -Token $token -SessionId $session.id -Command "getfile" -Parameters $params
    
    Write-Host "⏳ Waiting for file download to complete..."
    $commandResult = Wait-MDELiveResponseCommand -Token $token -CommandId $command.id -TimeoutSeconds 300
    
    if ($commandResult -and $commandResult.status -eq "Completed") {
        # Download the file from the result URL
        if ($commandResult.value) {
            $fileUrl = $commandResult.value
            $headers = @{
                "Authorization" = "Bearer $($token.AccessToken)"
            }
            
            Write-Host "⏳ Downloading file content..."
            $fileBytes = Invoke-RestMethod -Method Get -Uri $fileUrl -Headers $headers -ResponseHeadersVariable responseHeaders
            
            # If response is not already bytes, convert it
            if ($fileBytes -is [string]) {
                $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($fileBytes)
            }
            
            # Convert to Base64
            $fileBase64 = [Convert]::ToBase64String($fileBytes)
            
            # Extract file name from path
            $fileName = [System.IO.Path]::GetFileName($filePath)
            
            Write-Host "✅ File downloaded successfully: $fileName ($($fileBytes.Length) bytes)"
            
            $result = @{
                success     = $true
                status      = "Success"
                message     = "File downloaded successfully from device"
                fileName    = $fileName
                filePath    = $filePath
                fileContent = $fileBase64
                size        = $fileBytes.Length
                deviceId    = $deviceId
                sessionId   = $session.id
                commandId   = $command.id
                timestamp   = (Get-Date).ToString("o")
                error       = $null
            }
            
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = ($result | ConvertTo-Json -Depth 5)
                Headers = @{
                    "Content-Type" = "application/json"
                }
            })
        } else {
            throw "File download completed but no file URL returned"
        }
    } else {
        throw "File download failed or timed out"
    }

} catch {
    Write-Error "Error in GetLiveResponseFile: $($_.Exception.Message)"
    
    $errorResult = @{
        success   = $false
        status    = "Failed"
        message   = "File download failed"
        filePath  = $filePath
        deviceId  = $deviceId
        timestamp = (Get-Date).ToString("o")
        error     = $_.Exception.Message
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = ($errorResult | ConvertTo-Json -Depth 5)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })
}
