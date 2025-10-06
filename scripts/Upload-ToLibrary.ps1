<#
.SYNOPSIS
    Upload files to Azure Storage library container for MDE Live Response operations

.DESCRIPTION
    This script uploads files to the Azure Storage "library" container, making them
    available for deployment to MDE devices via the PutLiveResponseFileFromLibrary function.
    
    Supports both direct storage access and API-based upload.

.PARAMETER FilePath
    Path to the file to upload

.PARAMETER StorageAccountName
    Name of the Azure Storage account (optional if using connection string)

.PARAMETER ConnectionString
    Azure Storage connection string (alternative to storage account name)

.PARAMETER ResourceGroup
    Resource group containing the storage account (required with StorageAccountName)

.PARAMETER OverwriteExisting
    If specified, overwrites existing files with the same name

.EXAMPLE
    .\Upload-ToLibrary.ps1 -FilePath "C:\tools\script.ps1" -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"

.EXAMPLE
    .\Upload-ToLibrary.ps1 -FilePath "C:\tools\script.ps1" -ConnectionString "DefaultEndpointsProtocol=https;..."

.EXAMPLE
    # Upload multiple files
    Get-ChildItem "C:\tools\*.ps1" | ForEach-Object {
        .\Upload-ToLibrary.ps1 -FilePath $_.FullName -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"
    }
#>

[CmdletBinding(DefaultParameterSetName = 'StorageAccount')]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ConnectionString')]
    [string]$ConnectionString,
    
    [Parameter(Mandatory = $false)]
    [switch]$OverwriteExisting
)

begin {
    Write-Host "📦 Upload to Library - Starting..." -ForegroundColor Cyan
    
    # Check if Az.Storage module is available
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Write-Error "Az.Storage module is not installed. Install it with: Install-Module -Name Az.Storage"
        exit 1
    }
    
    Import-Module Az.Storage -ErrorAction Stop
    
    # Initialize storage context
    try {
        if ($PSCmdlet.ParameterSetName -eq 'StorageAccount') {
            Write-Host "🔐 Connecting to storage account: $StorageAccountName..." -ForegroundColor Yellow
            
            # Check if already authenticated to Azure
            $context = Get-AzContext -ErrorAction SilentlyContinue
            if (-not $context) {
                Write-Host "⚠️  Not authenticated to Azure. Running Connect-AzAccount..." -ForegroundColor Yellow
                Connect-AzAccount
            }
            
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName -ErrorAction Stop
            $script:StorageContext = $storageAccount.Context
        } else {
            Write-Host "🔐 Connecting to storage account using connection string..." -ForegroundColor Yellow
            $script:StorageContext = New-AzStorageContext -ConnectionString $ConnectionString -ErrorAction Stop
        }
        
        # Ensure library container exists
        $container = Get-AzStorageContainer -Name "library" -Context $script:StorageContext -ErrorAction SilentlyContinue
        if (-not $container) {
            Write-Host "📂 Creating library container..." -ForegroundColor Yellow
            New-AzStorageContainer -Name "library" -Context $script:StorageContext -Permission Off | Out-Null
            Write-Host "✅ Library container created" -ForegroundColor Green
        }
        
    } catch {
        Write-Error "Failed to initialize storage context: $($_.Exception.Message)"
        exit 1
    }
}

process {
    try {
        # Validate file exists
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            Write-Error "File not found: $FilePath"
            return
        }
        
        $file = Get-Item $FilePath
        $fileName = $file.Name
        $fileSize = $file.Length
        
        # Check file size
        if ($fileSize -gt 50MB) {
            Write-Warning "File size is $([Math]::Round($fileSize / 1MB, 2)) MB. Files larger than 50MB may have issues with MDE Live Response."
            $continue = Read-Host "Continue upload? (Y/N)"
            if ($continue -ne 'Y') {
                Write-Host "Upload cancelled by user" -ForegroundColor Yellow
                return
            }
        }
        
        # Check if file already exists
        $existingBlob = Get-AzStorageBlob -Container "library" -Blob $fileName -Context $script:StorageContext -ErrorAction SilentlyContinue
        
        if ($existingBlob -and -not $OverwriteExisting) {
            Write-Warning "File already exists in library: $fileName"
            $overwrite = Read-Host "Overwrite existing file? (Y/N)"
            if ($overwrite -ne 'Y') {
                Write-Host "Upload skipped for: $fileName" -ForegroundColor Yellow
                return
            }
        }
        
        Write-Host "📤 Uploading file: $fileName ($([Math]::Round($fileSize / 1KB, 2)) KB)..." -ForegroundColor Yellow
        
        # Upload blob
        $uploadParams = @{
            File      = $FilePath
            Container = "library"
            Blob      = $fileName
            Context   = $script:StorageContext
            Force     = $true
        }
        
        $result = Set-AzStorageBlobContent @uploadParams
        
        Write-Host "✅ File uploaded successfully: $fileName" -ForegroundColor Green
        Write-Host "   Container: library" -ForegroundColor Gray
        Write-Host "   Blob Name: $($result.Name)" -ForegroundColor Gray
        Write-Host "   Size: $([Math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "   Last Modified: $($result.LastModified)" -ForegroundColor Gray
        
    } catch {
        Write-Error "Failed to upload file '$FilePath': $($_.Exception.Message)"
    }
}

end {
    Write-Host ""
    Write-Host "✅ Upload complete!" -ForegroundColor Green
    Write-Host "   You can now deploy this file to devices using the FileOperations workbook or API." -ForegroundColor Cyan
}
