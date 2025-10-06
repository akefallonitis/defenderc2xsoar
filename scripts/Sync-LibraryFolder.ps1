<#
.SYNOPSIS
    Sync an entire folder to Azure Storage library container

.DESCRIPTION
    This script syncs all files from a local folder to the Azure Storage "library" container.
    It can optionally delete files in the library that don't exist locally (mirror mode).

.PARAMETER FolderPath
    Path to the folder to sync

.PARAMETER StorageAccountName
    Name of the Azure Storage account (optional if using connection string)

.PARAMETER ConnectionString
    Azure Storage connection string (alternative to storage account name)

.PARAMETER ResourceGroup
    Resource group containing the storage account (required with StorageAccountName)

.PARAMETER Mirror
    If specified, deletes files in the library that don't exist locally

.PARAMETER Filter
    File filter pattern (default: *.*)

.PARAMETER Recurse
    If specified, includes files from subdirectories

.EXAMPLE
    .\Sync-LibraryFolder.ps1 -FolderPath "C:\tools" -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"

.EXAMPLE
    # Sync only PowerShell scripts
    .\Sync-LibraryFolder.ps1 -FolderPath "C:\scripts" -Filter "*.ps1" -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"

.EXAMPLE
    # Mirror mode (delete remote files not in local folder)
    .\Sync-LibraryFolder.ps1 -FolderPath "C:\tools" -Mirror -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"
#>

[CmdletBinding(DefaultParameterSetName = 'StorageAccount')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FolderPath,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ConnectionString')]
    [string]$ConnectionString,
    
    [Parameter(Mandatory = $false)]
    [switch]$Mirror,
    
    [Parameter(Mandatory = $false)]
    [string]$Filter = "*.*",
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse
)

Write-Host "📦 Sync Library Folder - Starting..." -ForegroundColor Cyan

# Validate folder exists
if (-not (Test-Path $FolderPath -PathType Container)) {
    Write-Error "Folder not found: $FolderPath"
    exit 1
}

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
        $storageContext = $storageAccount.Context
    } else {
        Write-Host "🔐 Connecting to storage account using connection string..." -ForegroundColor Yellow
        $storageContext = New-AzStorageContext -ConnectionString $ConnectionString -ErrorAction Stop
    }
    
    # Ensure library container exists
    $container = Get-AzStorageContainer -Name "library" -Context $storageContext -ErrorAction SilentlyContinue
    if (-not $container) {
        Write-Host "📂 Creating library container..." -ForegroundColor Yellow
        New-AzStorageContainer -Name "library" -Context $storageContext -Permission Off | Out-Null
        Write-Host "✅ Library container created" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Failed to initialize storage context: $($_.Exception.Message)"
    exit 1
}

# Get local files
Write-Host "📂 Scanning local folder: $FolderPath" -ForegroundColor Yellow

$getItemParams = @{
    Path    = $FolderPath
    Filter  = $Filter
    File    = $true
}

if ($Recurse) {
    $getItemParams.Recurse = $true
}

$localFiles = Get-ChildItem @getItemParams

Write-Host "   Found $($localFiles.Count) file(s) to sync" -ForegroundColor Gray

# Get existing blobs
Write-Host "📋 Getting existing library files..." -ForegroundColor Yellow
$existingBlobs = Get-AzStorageBlob -Container "library" -Context $storageContext
$existingBlobNames = $existingBlobs | ForEach-Object { $_.Name }

Write-Host "   Found $($existingBlobs.Count) existing file(s) in library" -ForegroundColor Gray

# Track statistics
$uploaded = 0
$skipped = 0
$deleted = 0
$errors = 0

# Upload/update local files
foreach ($file in $localFiles) {
    try {
        $fileName = $file.Name
        $existingBlob = $existingBlobs | Where-Object { $_.Name -eq $fileName }
        
        $shouldUpload = $false
        
        if (-not $existingBlob) {
            # New file
            $shouldUpload = $true
            Write-Host "📤 Uploading new file: $fileName" -ForegroundColor Yellow
        } else {
            # Check if file has changed (by size or modification time)
            if ($file.Length -ne $existingBlob.Length -or $file.LastWriteTime -gt $existingBlob.LastModified) {
                $shouldUpload = $true
                Write-Host "📤 Updating changed file: $fileName" -ForegroundColor Yellow
            } else {
                Write-Host "⏭️  Skipping unchanged file: $fileName" -ForegroundColor Gray
                $skipped++
            }
        }
        
        if ($shouldUpload) {
            Set-AzStorageBlobContent -File $file.FullName -Container "library" -Blob $fileName -Context $storageContext -Force | Out-Null
            Write-Host "   ✅ Uploaded: $fileName ($([Math]::Round($file.Length / 1KB, 2)) KB)" -ForegroundColor Green
            $uploaded++
        }
        
    } catch {
        Write-Error "Failed to upload '$fileName': $($_.Exception.Message)"
        $errors++
    }
}

# Handle mirror mode - delete remote files not in local folder
if ($Mirror) {
    Write-Host ""
    Write-Host "🔄 Mirror mode: Checking for files to delete..." -ForegroundColor Yellow
    
    $localFileNames = $localFiles | ForEach-Object { $_.Name }
    $filesToDelete = $existingBlobNames | Where-Object { $_ -notin $localFileNames }
    
    if ($filesToDelete.Count -gt 0) {
        Write-Host "   Found $($filesToDelete.Count) file(s) to delete" -ForegroundColor Yellow
        
        foreach ($fileName in $filesToDelete) {
            try {
                Write-Host "🗑️  Deleting: $fileName" -ForegroundColor Yellow
                Remove-AzStorageBlob -Container "library" -Blob $fileName -Context $storageContext -Force -ErrorAction Stop
                Write-Host "   ✅ Deleted: $fileName" -ForegroundColor Green
                $deleted++
            } catch {
                Write-Error "Failed to delete '$fileName': $($_.Exception.Message)"
                $errors++
            }
        }
    } else {
        Write-Host "   No files to delete" -ForegroundColor Gray
    }
}

# Summary
Write-Host ""
Write-Host "✅ Sync complete!" -ForegroundColor Green
Write-Host "   📤 Uploaded: $uploaded" -ForegroundColor Cyan
Write-Host "   ⏭️  Skipped: $skipped" -ForegroundColor Gray
if ($Mirror) {
    Write-Host "   🗑️  Deleted: $deleted" -ForegroundColor Yellow
}
if ($errors -gt 0) {
    Write-Host "   ❌ Errors: $errors" -ForegroundColor Red
}
