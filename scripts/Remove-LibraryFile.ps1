<#
.SYNOPSIS
    Delete a file from the Azure Storage library container

.DESCRIPTION
    This script deletes a file from the "library" container with optional confirmation.
    Supports both direct storage access and API-based deletion.

.PARAMETER FileName
    Name of the file to delete

.PARAMETER StorageAccountName
    Name of the Azure Storage account (optional if using API or connection string)

.PARAMETER ConnectionString
    Azure Storage connection string (alternative to storage account name)

.PARAMETER ResourceGroup
    Resource group containing the storage account (required with StorageAccountName)

.PARAMETER UseAPI
    If specified, uses the Azure Function API instead of direct storage access

.PARAMETER FunctionUrl
    URL of the DeleteLibraryFile Azure Function (required with UseAPI)

.PARAMETER FunctionKey
    Function key for authentication (required with UseAPI)

.PARAMETER Force
    If specified, skips confirmation prompt

.EXAMPLE
    .\Remove-LibraryFile.ps1 -FileName "script.ps1" -StorageAccountName "defenderc2" -ResourceGroup "rg-mde"

.EXAMPLE
    # Using API
    .\Remove-LibraryFile.ps1 -FileName "script.ps1" -UseAPI -FunctionUrl "https://myfunc.azurewebsites.net/api/DeleteLibraryFile" -FunctionKey "abc123..."

.EXAMPLE
    # Force delete without confirmation
    .\Remove-LibraryFile.ps1 -FileName "script.ps1" -StorageAccountName "defenderc2" -ResourceGroup "rg-mde" -Force
#>

[CmdletBinding(DefaultParameterSetName = 'StorageAccount', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FileName,
    
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
    [switch]$Force
)

Write-Host "🗑️  Remove Library File - Starting..." -ForegroundColor Cyan

# Sanitize file name
$FileName = [System.IO.Path]::GetFileName($FileName)

try {
    if ($UseAPI) {
        # Use Azure Function API
        Write-Host "🌐 Using Azure Function API..." -ForegroundColor Yellow
        
        # Confirmation
        if (-not $Force -and -not $PSCmdlet.ShouldProcess($FileName, "Delete file from library")) {
            Write-Host "Operation cancelled by user" -ForegroundColor Yellow
            return
        }
        
        $uri = "$FunctionUrl`?code=$FunctionKey"
        $body = @{
            fileName = $FileName
        } | ConvertTo-Json
        
        Write-Host "🗑️  Deleting file: $FileName" -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        
        if ($response.success) {
            Write-Host "✅ File deleted successfully: $FileName" -ForegroundColor Green
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
        
        # Check if blob exists
        Write-Host "🔍 Checking if file exists: $FileName" -ForegroundColor Yellow
        $blob = Get-AzStorageBlob -Container "library" -Blob $FileName -Context $storageContext -ErrorAction SilentlyContinue
        
        if (-not $blob) {
            Write-Error "File not found in library: $FileName"
            exit 1
        }
        
        # Show file details
        Write-Host "   File: $FileName" -ForegroundColor Gray
        Write-Host "   Size: $([Math]::Round($blob.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "   Last Modified: $($blob.LastModified)" -ForegroundColor Gray
        
        # Confirmation
        if (-not $Force -and -not $PSCmdlet.ShouldProcess($FileName, "Delete file from library")) {
            Write-Host "Operation cancelled by user" -ForegroundColor Yellow
            return
        }
        
        Write-Host "🗑️  Deleting file: $FileName" -ForegroundColor Yellow
        Remove-AzStorageBlob -Container "library" -Blob $FileName -Context $storageContext -Force -ErrorAction Stop
        
        Write-Host "✅ File deleted successfully: $FileName" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Failed to delete file: $($_.Exception.Message)"
    exit 1
}
