using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "GetLibraryFile: Processing request to retrieve library file"

# Get parameters from query string or body
$fileName = $Request.Query.fileName
if ($Request.Body) {
    $fileName = $Request.Body.fileName ?? $fileName
}

# Validate required parameters
if (-not $fileName) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success   = $false
            timestamp = (Get-Date).ToString("o")
            error     = "Missing required parameter: fileName"
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
    
    # Sanitize file name to prevent path traversal
    $fileName = [System.IO.Path]::GetFileName($fileName)
    
    Write-Host "📥 Retrieving file: $fileName from library container..."
    
    # Check if blob exists
    $blob = Get-AzStorageBlob -Container "library" -Blob $fileName -Context $global:StorageContext -ErrorAction Stop
    
    if (-not $blob) {
        throw "File not found: $fileName"
    }
    
    # Download blob content to memory
    $memoryStream = New-Object System.IO.MemoryStream
    $blob.ICloudBlob.DownloadToStream($memoryStream)
    $memoryStream.Position = 0
    
    # Convert to Base64
    $fileBytes = $memoryStream.ToArray()
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    
    Write-Host "✅ File retrieved successfully: $fileName ($($fileBytes.Length) bytes)"
    
    # Return success response
    $result = @{
        success     = $true
        fileName    = $fileName
        fileContent = $fileBase64
        size        = $fileBytes.Length
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

} catch {
    Write-Error "Error in GetLibraryFile: $($_.Exception.Message)"
    
    $statusCode = if ($_.Exception.Message -like "*not found*") {
        [HttpStatusCode]::NotFound
    } else {
        [HttpStatusCode]::InternalServerError
    }
    
    $errorResult = @{
        success   = $false
        fileName  = $fileName
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
