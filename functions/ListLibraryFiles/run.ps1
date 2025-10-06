using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "ListLibraryFiles: Processing request to list library files"

try {
    # Check if storage context is initialized
    if (-not $global:StorageContext) {
        throw "Storage context not initialized. Ensure AzureWebJobsStorage is configured."
    }
    
    Write-Host "📋 Retrieving files from library container..."
    
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
    
    # Return success response
    $result = @{
        success   = $true
        data      = $files
        count     = $files.Count
        timestamp = (Get-Date).ToString("o")
        error     = $null
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ($result | ConvertTo-Json -Depth 5)
        Headers = @{
            "Content-Type" = "application/json"
        }
    })

} catch {
    Write-Error "Error in ListLibraryFiles: $($_.Exception.Message)"
    
    $errorResult = @{
        success   = $false
        data      = @()
        count     = 0
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
