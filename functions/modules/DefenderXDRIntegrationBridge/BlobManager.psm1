<#
.SYNOPSIS
    Azure Blob Storage Manager for DefenderXDR Live Response File Library
    
.DESCRIPTION
    Provides centralized Blob Storage operations for MDE Live Response file management:
    - Upload files to Live Response library (scripts, tools, remediation files)
    - Download files from devices via Live Response GetFile
    - Generate SAS URLs for secure file access
    - List and manage files in tenant-specific containers
    - Automatic cleanup of old files
    
    Uses Managed Identity for secure, keyless authentication to Azure Storage.
    
.NOTES
    Version: 3.0.0
    Requires: Az.Storage module (included in Azure Functions runtime)
    Container Structure:
      liveresponse/
        ├─ {tenantId}/scripts/        - Pre-uploaded scripts for Live Response
        ├─ {tenantId}/uploads/         - Files staged for PutFile operations
        └─ {tenantId}/downloads/       - Files retrieved via GetFile operations
#>

#Requires -Modules Az.Storage

# Module-level variables
$script:storageAccountName = $env:STORAGE_ACCOUNT_NAME
$script:containerName = "liveresponse"
$script:storageContext = $null

<#
.SYNOPSIS
    Initialize Blob Storage context with Managed Identity
    
.DESCRIPTION
    Creates storage context using Function App's Managed Identity.
    No connection strings or keys required.
    
.PARAMETER StorageAccountName
    Name of the Azure Storage Account. If not provided, uses STORAGE_ACCOUNT_NAME environment variable.
    
.EXAMPLE
    Initialize-XDRBlobStorage -StorageAccountName "xdrstorage12345"
#>
function Initialize-XDRBlobStorage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$StorageAccountName
    )
    
    try {
        # Use provided storage account or environment variable
        $storageAcct = if ($StorageAccountName) { $StorageAccountName } else { $script:storageAccountName }
        
        if ([string]::IsNullOrEmpty($storageAcct)) {
            throw "Storage account name not provided and STORAGE_ACCOUNT_NAME environment variable not set"
        }
        
        Write-Verbose "Initializing Blob Storage context for account: $storageAcct"
        
        # Create storage context using Managed Identity
        # UseConnectedAccount means use the Managed Identity of the Azure Function
        $script:storageContext = New-AzStorageContext -StorageAccountName $storageAcct -UseConnectedAccount
        $script:storageAccountName = $storageAcct
        
        # Verify container exists, create if not
        $container = Get-AzStorageContainer -Name $script:containerName -Context $script:storageContext -ErrorAction SilentlyContinue
        
        if (-not $container) {
            Write-Verbose "Container '$script:containerName' not found. Creating..."
            New-AzStorageContainer -Name $script:containerName -Context $script:storageContext -Permission Off | Out-Null
            Write-Verbose "Container '$script:containerName' created successfully"
        }
        
        return @{
            Success = $true
            StorageAccountName = $script:storageAccountName
            ContainerName = $script:containerName
            Message = "Blob Storage initialized successfully"
        }
    }
    catch {
        Write-Error "Failed to initialize Blob Storage: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Upload file to Live Response library
    
.DESCRIPTION
    Uploads a file to tenant-specific folder in Blob Storage.
    Used for staging files before Live Response PutFile operations.
    
.PARAMETER TenantId
    Azure AD tenant ID (for folder isolation)
    
.PARAMETER FilePath
    Local file path to upload
    
.PARAMETER FileName
    Name for the blob (if different from local filename)
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads
    
.PARAMETER OverwriteExisting
    Overwrite file if it already exists
    
.EXAMPLE
    Add-XDRBlobFile -TenantId "xxx" -FilePath "C:\scripts\remediation.ps1" -Category "scripts"
    
.EXAMPLE
    Add-XDRBlobFile -TenantId "xxx" -FilePath "C:\tool.exe" -FileName "forensics-tool.exe" -Category "uploads"
#>
function Add-XDRBlobFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category = "uploads",
        
        [Parameter(Mandatory = $false)]
        [switch]$OverwriteExisting
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Validate file exists
        if (-not (Test-Path -Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        # Determine blob name
        $blobFileName = if ($FileName) { $FileName } else { Split-Path -Leaf $FilePath }
        
        # Construct blob path: {tenantId}/{category}/{filename}
        $blobPath = "$TenantId/$Category/$blobFileName"
        
        Write-Verbose "Uploading file to blob: $blobPath"
        
        # Upload file
        $uploadParams = @{
            File = $FilePath
            Container = $script:containerName
            Blob = $blobPath
            Context = $script:storageContext
            Force = $OverwriteExisting.IsPresent
        }
        
        $blob = Set-AzStorageBlobContent @uploadParams
        
        return @{
            Success = $true
            TenantId = $TenantId
            Category = $Category
            FileName = $blobFileName
            BlobPath = $blobPath
            BlobUri = $blob.ICloudBlob.Uri.AbsoluteUri
            Size = (Get-Item $FilePath).Length
            UploadTime = (Get-Date).ToString("o")
        }
    }
    catch {
        Write-Error "Failed to upload file to Blob Storage: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Download file from Blob Storage
    
.DESCRIPTION
    Downloads a file from tenant-specific folder in Blob Storage.
    Used for retrieving files downloaded from devices via Live Response GetFile.
    
.PARAMETER TenantId
    Azure AD tenant ID
    
.PARAMETER FileName
    Name of the blob to download
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads
    
.PARAMETER DestinationPath
    Local path to save the downloaded file
    
.EXAMPLE
    Get-XDRBlobFile -TenantId "xxx" -FileName "security.evtx" -Category "downloads" -DestinationPath "C:\forensics\"
#>
function Get-XDRBlobFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category = "downloads",
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct blob path
        $blobPath = "$TenantId/$Category/$FileName"
        
        Write-Verbose "Downloading blob: $blobPath"
        
        # Ensure destination directory exists
        $destDir = Split-Path -Parent $DestinationPath
        if ($destDir -and -not (Test-Path -Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Download file
        $downloadParams = @{
            Blob = $blobPath
            Container = $script:containerName
            Destination = $DestinationPath
            Context = $script:storageContext
            Force = $true
        }
        
        $result = Get-AzStorageBlobContent @downloadParams
        
        return @{
            Success = $true
            TenantId = $TenantId
            Category = $Category
            FileName = $FileName
            BlobPath = $blobPath
            LocalPath = $DestinationPath
            Size = (Get-Item $DestinationPath).Length
            DownloadTime = (Get-Date).ToString("o")
        }
    }
    catch {
        Write-Error "Failed to download file from Blob Storage: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Generate SAS URL for secure blob access
    
.DESCRIPTION
    Creates a time-limited SAS URL for secure access to a blob without requiring authentication.
    Useful for providing download links to users or external systems.
    
.PARAMETER TenantId
    Azure AD tenant ID
    
.PARAMETER FileName
    Name of the blob
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads
    
.PARAMETER ExpiryHours
    Hours until SAS URL expires (default: 1 hour)
    
.PARAMETER Permission
    Permissions: r (read), w (write), d (delete), l (list)
    
.EXAMPLE
    New-XDRBlobSasUrl -TenantId "xxx" -FileName "report.pdf" -Category "downloads" -ExpiryHours 24
#>
function New-XDRBlobSasUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category = "downloads",
        
        [Parameter(Mandatory = $false)]
        [int]$ExpiryHours = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$Permission = "r"
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct blob path
        $blobPath = "$TenantId/$Category/$FileName"
        
        Write-Verbose "Generating SAS URL for blob: $blobPath"
        
        # Calculate expiry time
        $startTime = (Get-Date).ToUniversalTime()
        $expiryTime = $startTime.AddHours($ExpiryHours)
        
        # Generate SAS token
        $sasToken = New-AzStorageBlobSASToken -Container $script:containerName `
            -Blob $blobPath `
            -Context $script:storageContext `
            -Permission $Permission `
            -StartTime $startTime `
            -ExpiryTime $expiryTime
        
        # Construct full URL
        $blobUri = "https://$($script:storageAccountName).blob.core.windows.net/$($script:containerName)/$blobPath"
        $sasUrl = "$blobUri$sasToken"
        
        return @{
            Success = $true
            TenantId = $TenantId
            Category = $Category
            FileName = $FileName
            BlobPath = $blobPath
            SasUrl = $sasUrl
            ExpiryTime = $expiryTime.ToString("o")
            Permission = $Permission
        }
    }
    catch {
        Write-Error "Failed to generate SAS URL: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    List files in tenant folder
    
.DESCRIPTION
    Lists all blobs in a tenant-specific category folder.
    
.PARAMETER TenantId
    Azure AD tenant ID
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads (optional - lists all if not specified)
    
.PARAMETER MaxCount
    Maximum number of blobs to return (default: 1000)
    
.EXAMPLE
    Get-XDRBlobFileList -TenantId "xxx" -Category "scripts"
    
.EXAMPLE
    Get-XDRBlobFileList -TenantId "xxx"  # Lists all categories
#>
function Get-XDRBlobFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCount = 1000
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct prefix
        $prefix = if ($Category) { "$TenantId/$Category/" } else { "$TenantId/" }
        
        Write-Verbose "Listing blobs with prefix: $prefix"
        
        # List blobs
        $blobs = Get-AzStorageBlob -Container $script:containerName `
            -Context $script:storageContext `
            -Prefix $prefix `
            -MaxCount $MaxCount
        
        # Format results
        $fileList = $blobs | ForEach-Object {
            $pathParts = $_.Name.Split('/')
            @{
                TenantId = $pathParts[0]
                Category = if ($pathParts.Count -gt 1) { $pathParts[1] } else { "" }
                FileName = if ($pathParts.Count -gt 2) { $pathParts[2] } else { $pathParts[-1] }
                BlobPath = $_.Name
                BlobUri = $_.ICloudBlob.Uri.AbsoluteUri
                Size = $_.Length
                LastModified = $_.LastModified.ToString("o")
                ContentType = $_.ICloudBlob.Properties.ContentType
            }
        }
        
        return @{
            Success = $true
            TenantId = $TenantId
            Category = $Category
            Count = $fileList.Count
            Files = $fileList
        }
    }
    catch {
        Write-Error "Failed to list files in Blob Storage: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Delete file from Blob Storage
    
.DESCRIPTION
    Removes a blob from tenant-specific folder.
    
.PARAMETER TenantId
    Azure AD tenant ID
    
.PARAMETER FileName
    Name of the blob to delete
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads
    
.EXAMPLE
    Remove-XDRBlobFile -TenantId "xxx" -FileName "old-script.ps1" -Category "scripts"
#>
function Remove-XDRBlobFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category = "downloads"
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct blob path
        $blobPath = "$TenantId/$Category/$FileName"
        
        if ($PSCmdlet.ShouldProcess($blobPath, "Delete blob")) {
            Write-Verbose "Deleting blob: $blobPath"
            
            Remove-AzStorageBlob -Container $script:containerName `
                -Blob $blobPath `
                -Context $script:storageContext `
                -Force
            
            return @{
                Success = $true
                TenantId = $TenantId
                Category = $Category
                FileName = $FileName
                BlobPath = $blobPath
                Message = "Blob deleted successfully"
            }
        }
    }
    catch {
        Write-Error "Failed to delete blob: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Clean up old files from Blob Storage
    
.DESCRIPTION
    Removes blobs older than specified age.
    Useful for automatic cleanup of temporary files.
    
.PARAMETER TenantId
    Azure AD tenant ID (optional - cleans all tenants if not specified)
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads (optional - cleans all if not specified)
    
.PARAMETER OlderThanDays
    Delete files older than this many days (default: 30)
    
.EXAMPLE
    Clear-XDRBlobOldFiles -TenantId "xxx" -Category "downloads" -OlderThanDays 7
    
.EXAMPLE
    Clear-XDRBlobOldFiles -OlderThanDays 90  # Clean all tenants, all categories
#>
function Clear-XDRBlobOldFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [int]$OlderThanDays = 30
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct prefix
        $prefix = if ($TenantId -and $Category) { 
            "$TenantId/$Category/" 
        } elseif ($TenantId) { 
            "$TenantId/" 
        } else { 
            "" 
        }
        
        Write-Verbose "Cleaning up blobs older than $OlderThanDays days with prefix: $prefix"
        
        # Calculate cutoff date
        $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
        
        # List all blobs
        $blobs = Get-AzStorageBlob -Container $script:containerName `
            -Context $script:storageContext `
            -Prefix $prefix
        
        # Filter old blobs
        $oldBlobs = $blobs | Where-Object { $_.LastModified -lt $cutoffDate }
        
        $deletedCount = 0
        $totalSize = 0
        
        foreach ($blob in $oldBlobs) {
            if ($PSCmdlet.ShouldProcess($blob.Name, "Delete old blob")) {
                Remove-AzStorageBlob -Container $script:containerName `
                    -Blob $blob.Name `
                    -Context $script:storageContext `
                    -Force
                
                $deletedCount++
                $totalSize += $blob.Length
            }
        }
        
        return @{
            Success = $true
            DeletedCount = $deletedCount
            TotalSize = $totalSize
            OlderThanDays = $OlderThanDays
            Message = "Cleaned up $deletedCount blobs ($([math]::Round($totalSize/1MB, 2)) MB)"
        }
    }
    catch {
        Write-Error "Failed to clean up old files: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Get blob file metadata
    
.DESCRIPTION
    Retrieves properties and metadata for a specific blob without downloading it.
    
.PARAMETER TenantId
    Azure AD tenant ID
    
.PARAMETER FileName
    Name of the blob
    
.PARAMETER Category
    Category folder: scripts, uploads, downloads
    
.EXAMPLE
    Get-XDRBlobFileInfo -TenantId "xxx" -FileName "script.ps1" -Category "scripts"
#>
function Get-XDRBlobFileInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("scripts", "uploads", "downloads")]
        [string]$Category = "downloads"
    )
    
    try {
        # Initialize storage if not already done
        if (-not $script:storageContext) {
            Initialize-XDRBlobStorage | Out-Null
        }
        
        # Construct blob path
        $blobPath = "$TenantId/$Category/$FileName"
        
        Write-Verbose "Getting blob info: $blobPath"
        
        # Get blob properties
        $blob = Get-AzStorageBlob -Container $script:containerName `
            -Blob $blobPath `
            -Context $script:storageContext
        
        return @{
            Success = $true
            TenantId = $TenantId
            Category = $Category
            FileName = $FileName
            BlobPath = $blobPath
            BlobUri = $blob.ICloudBlob.Uri.AbsoluteUri
            Size = $blob.Length
            ContentType = $blob.ICloudBlob.Properties.ContentType
            ContentMD5 = $blob.ICloudBlob.Properties.ContentMD5
            LastModified = $blob.LastModified.ToString("o")
            Created = $blob.ICloudBlob.Properties.Created.ToString("o")
            ETag = $blob.ICloudBlob.Properties.ETag
            Metadata = $blob.ICloudBlob.Metadata
        }
    }
    catch {
        Write-Error "Failed to get blob info: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-XDRBlobStorage',
    'Add-XDRBlobFile',
    'Get-XDRBlobFile',
    'New-XDRBlobSasUrl',
    'Get-XDRBlobFileList',
    'Remove-XDRBlobFile',
    'Clear-XDRBlobOldFiles',
    'Get-XDRBlobFileInfo'
)
