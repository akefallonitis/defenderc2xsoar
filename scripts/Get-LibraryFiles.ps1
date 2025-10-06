<#
.SYNOPSIS
    List files in the Azure Storage library container

.DESCRIPTION
    This script lists all files in the "library" container of Azure Storage.
    Supports both direct storage access and API-based queries.

.PARAMETER StorageAccountName
    Name of the Azure Storage account (optional if using API or connection string)

.PARAMETER ConnectionString
    Azure Storage connection string (alternative to storage account name)

.PARAMETER ResourceGroup
    Resource group containing the storage account (required with StorageAccountName)

.PARAMETER UseAPI
    If specified, uses the Azure Function API instead of direct storage access

.PARAMETER FunctionUrl
    URL of the ListLibraryFiles Azure Function (required with UseAPI)

.PARAMETER FunctionKey
    Function key for authentication (required with UseAPI)

.PARAMETER Format
    Output format: Table (default), List, or JSON

.EXAMPLE
    .\Get-LibraryFiles.ps1 -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"

.EXAMPLE
    # Using API
    .\Get-LibraryFiles.ps1 -UseAPI -FunctionUrl "https://myfunc.azurewebsites.net/api/ListLibraryFiles" -FunctionKey "abc123..."

.EXAMPLE
    # Export to JSON
    .\Get-LibraryFiles.ps1 -StorageAccountName "defenderc2" -ResourceGroup "rg-mde" -Format JSON | Out-File library-files.json
#>

[CmdletBinding(DefaultParameterSetName = 'StorageAccount')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'StorageAccount')]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ConnectionString')]
    [string]$ConnectionString,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'API')]
    [switch]$UseAPI,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'API')]
    [string]$FunctionUrl,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'API')]
    [string]$FunctionKey,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Table', 'List', 'JSON')]
    [string]$Format = 'Table'
)

Write-Host "📋 Get Library Files - Starting..." -ForegroundColor Cyan

$files = @()

try {
    if ($UseAPI) {
        # Use Azure Function API
        Write-Host "🌐 Querying Azure Function API..." -ForegroundColor Yellow
        
        $uri = "$FunctionUrl`?code=$FunctionKey"
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        
        if ($response.success) {
            $files = $response.data
            Write-Host "✅ Retrieved $($response.count) file(s) from API" -ForegroundColor Green
        } else {
            Write-Error "API returned error: $($response.error)"
            exit 1
        }
        
    } else {
        # Direct storage access
        if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
            Write-Error "Az.Storage module is not installed. Install it with: Install-Module -Name Az.Storage"
            exit 1
        }
        
        Import-Module Az.Storage -ErrorAction Stop
        
        # Initialize storage context
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
        
        # Get blobs
        Write-Host "📋 Retrieving files from library container..." -ForegroundColor Yellow
        $blobs = Get-AzStorageBlob -Container "library" -Context $storageContext -ErrorAction Stop
        
        # Format file list
        foreach ($blob in $blobs) {
            $files += [PSCustomObject]@{
                FileName     = $blob.Name
                Size         = $blob.Length
                SizeKB       = [Math]::Round($blob.Length / 1KB, 2)
                SizeMB       = [Math]::Round($blob.Length / 1MB, 2)
                LastModified = $blob.LastModified.DateTime
                ContentType  = $blob.ICloudBlob.Properties.ContentType
                ETag         = $blob.ICloudBlob.Properties.ETag
            }
        }
        
        Write-Host "✅ Found $($files.Count) file(s) in library" -ForegroundColor Green
    }
    
    # Output based on format
    if ($files.Count -eq 0) {
        Write-Host "   No files found in library container" -ForegroundColor Gray
        return
    }
    
    Write-Host ""
    
    switch ($Format) {
        'Table' {
            $files | Format-Table FileName, SizeKB, LastModified, ContentType -AutoSize
        }
        'List' {
            $files | Format-List FileName, Size, SizeKB, SizeMB, LastModified, ContentType, ETag
        }
        'JSON' {
            $files | ConvertTo-Json -Depth 5
        }
    }
    
} catch {
    Write-Error "Failed to retrieve library files: $($_.Exception.Message)"
    exit 1
}
