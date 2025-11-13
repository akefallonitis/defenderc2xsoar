# Create DefenderXDR C2 XSOAR Deployment Package
# Version: 3.0.0
# Creates .zip package for Azure Function App deployment

param(
    [string]$OutputPath = ".\function-app-v3.0.0.zip",
    [switch]$IncludeTests = $false
)

Write-Host "DefenderXDR C2 XSOAR - Package Creator v3.0.0" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Define source directory
$FunctionsDir = Join-Path $ProjectRoot "functions"

if (-not (Test-Path $FunctionsDir)) {
    Write-Error "Functions directory not found: $FunctionsDir"
    exit 1
}

# Create temporary directory for packaging
$TempDir = Join-Path $env:TEMP "defenderxdr-package-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

Write-Host "[1/5] Preparing package structure..." -ForegroundColor Yellow

try {
    # Copy all function directories
    $FunctionFolders = @(
        "DefenderXDRGateway",
        "DefenderXDROrchestrator",
        "DefenderXDRMDEWorker",
        "DefenderXDRMDOWorker",
        "DefenderXDRMDIWorker",
        "DefenderXDREntraIDWorker",
        "DefenderXDRIntuneWorker",
        "DefenderXDRAzureWorker",
        "DefenderXDRMCASWorker"
    )

    foreach ($folder in $FunctionFolders) {
        $SourcePath = Join-Path $FunctionsDir $folder
        $DestPath = Join-Path $TempDir $folder
        
        if (Test-Path $SourcePath) {
            Write-Host "  Copying $folder..." -ForegroundColor Gray
            Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
        } else {
            Write-Warning "  Skipping $folder (not found)"
        }
    }

    Write-Host "[2/5] Copying modules..." -ForegroundColor Yellow
    
    # Copy IntegrationBridge module
    $ModulesSource = Join-Path $FunctionsDir "modules"
    $ModulesDestDir = Join-Path $TempDir "modules"
    
    if (Test-Path $ModulesSource) {
        Copy-Item -Path $ModulesSource -Destination $ModulesDestDir -Recurse -Force
        Write-Host "  Copied DefenderXDRIntegrationBridge (7 modules)" -ForegroundColor Gray
    }

    Write-Host "[3/5] Copying configuration files..." -ForegroundColor Yellow
    
    # Copy root-level files
    $RootFiles = @(
        "host.json",
        "profile.ps1",
        "requirements.psd1"
    )
    
    foreach ($file in $RootFiles) {
        $SourceFile = Join-Path $FunctionsDir $file
        $DestFile = Join-Path $TempDir $file
        
        if (Test-Path $SourceFile) {
            Copy-Item -Path $SourceFile -Destination $DestFile -Force
            Write-Host "  Copied $file" -ForegroundColor Gray
        } else {
            Write-Warning "  Missing: $file"
        }
    }

    Write-Host "[4/5] Cleaning up package..." -ForegroundColor Yellow
    
    # Remove unnecessary files
    $ExcludePatterns = @(
        "*.md",
        "*.ps1~",
        ".git*",
        "*.tmp",
        "*.log"
    )
    
    if (-not $IncludeTests) {
        $ExcludePatterns += "*.Tests.ps1"
        $ExcludePatterns += "test-*.ps1"
    }
    
    foreach ($pattern in $ExcludePatterns) {
        $FilesToRemove = Get-ChildItem -Path $TempDir -Filter $pattern -Recurse -File
        foreach ($file in $FilesToRemove) {
            Remove-Item $file.FullName -Force
            Write-Host "  Removed: $($file.Name)" -ForegroundColor DarkGray
        }
    }

    Write-Host "[5/5] Creating .zip package..." -ForegroundColor Yellow
    
    # Resolve output path
    if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath = Join-Path (Get-Location) $OutputPath
    }
    
    # Create parent directory if needed
    $OutputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Remove existing package
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
        Write-Host "  Removed existing package" -ForegroundColor DarkGray
    }
    
    # Create zip (PowerShell 5+ has Compress-Archive)
    Compress-Archive -Path "$TempDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal
    
    # Get package info
    $PackageSize = (Get-Item $OutputPath).Length
    $PackageSizeMB = [math]::Round($PackageSize / 1MB, 2)
    
    Write-Host ""
    Write-Host "✅ Package created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Package Details:" -ForegroundColor Cyan
    Write-Host "  Location: $OutputPath" -ForegroundColor White
    Write-Host "  Size: $PackageSizeMB MB" -ForegroundColor White
    Write-Host "  Functions: $($FunctionFolders.Count)" -ForegroundColor White
    Write-Host "  Modules: 7 (DefenderXDRIntegrationBridge)" -ForegroundColor White
    Write-Host ""
    Write-Host "Deployment Instructions:" -ForegroundColor Cyan
    Write-Host "  1. Upload to Azure Function App:" -ForegroundColor White
    Write-Host "     az functionapp deployment source config-zip \\" -ForegroundColor Gray
    Write-Host "       --resource-group <RG> \\" -ForegroundColor Gray
    Write-Host "       --name <FunctionAppName> \\" -ForegroundColor Gray
    Write-Host "       --src $OutputPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Or use ARM template:" -ForegroundColor White
    Write-Host "     Update packageUrl in azuredeploy.json to point to this package" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Verify deployment:" -ForegroundColor White
    Write-Host "     Test Gateway endpoint: https://<app>.azurewebsites.net/api/DefenderXDRGateway" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Error "Package creation failed: $_"
    exit 1
} finally {
    # Cleanup temp directory
    if (Test-Path $TempDir) {
        Write-Host "Cleaning up temporary files..." -ForegroundColor DarkGray
        Remove-Item $TempDir -Recurse -Force
    }
}

Write-Host "Package creation complete!" -ForegroundColor Green
