<#
.SYNOPSIS
    Creates deployment package for DefenderXDR v3.0.0
    
.DESCRIPTION
    Bundles all 13 functions + modules into function-package.zip for Azure deployment.
    Includes all Workers (renamed with DefenderXDR prefix), BlobManager module, and shared modules.
    
.NOTES
    Version: 3.0.0
    Run from deployment/ folder
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\function-package.zip"
)

Write-Host "=== Creating DefenderXDR v3.0.0 Deployment Package ===" -ForegroundColor Cyan

# Get script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$functionsPath = Join-Path $rootPath "functions"

# Create temp directory
$tempPath = Join-Path $env:TEMP "defenderxdr-package-$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-Host "Creating temp directory: $tempPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

try {
    # Copy core files
    Write-Host "`nCopying core files..." -ForegroundColor Yellow
    Copy-Item -Path (Join-Path $functionsPath "host.json") -Destination $tempPath -Force
    Copy-Item -Path (Join-Path $functionsPath "profile.ps1") -Destination $tempPath -Force
    Copy-Item -Path (Join-Path $functionsPath "requirements.psd1") -Destination $tempPath -Force
    Write-Host "  ✓ host.json, profile.ps1, requirements.psd1" -ForegroundColor Green
    
    # Copy all 13 functions
    Write-Host "`nCopying functions..." -ForegroundColor Yellow
    
    $functions = @(
        "DefenderXDRGateway",
        "DefenderXDROrchestrator",
        "DefenderXDRMDEWorker",
        "DefenderXDRMDOWorker",
        "DefenderXDRMDCWorker",
        "DefenderXDRMDIWorker",
        "DefenderXDREntraIDWorker",
        "DefenderXDRIntuneWorker",
        "DefenderXDRAzureWorker",
        "DefenderXDRHuntManager",
        "DefenderXDRIncidentManager",
        "DefenderXDRThreatIntelManager",
        "DefenderXDRCustomDetectionManager"
    )
    
    $copiedCount = 0
    foreach ($func in $functions) {
        $sourcePath = Join-Path $functionsPath $func
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $tempPath $func
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Host "  ✓ $func" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Warning "  ✗ $func not found at $sourcePath"
        }
    }
    
    Write-Host "`nCopied $copiedCount/$($functions.Count) functions" -ForegroundColor $(if ($copiedCount -eq $functions.Count) { "Green" } else { "Yellow" })
    
    # Copy modules (including BlobManager)
    Write-Host "`nCopying modules..." -ForegroundColor Yellow
    $modulesSource = Join-Path $functionsPath "modules"
    $modulesDest = Join-Path $tempPath "modules"
    
    if (Test-Path $modulesSource) {
        Copy-Item -Path $modulesSource -Destination $modulesDest -Recurse -Force
        
        # List key modules
        $keyModules = @(
            "DefenderXDRIntegrationBridge\AuthManager.psm1",
            "DefenderXDRIntegrationBridge\BlobManager.psm1",
            "DefenderXDRIntegrationBridge\QueueManager.psm1",
            "DefenderXDRIntegrationBridge\StatusTracker.psm1",
            "DefenderXDRIntegrationBridge\ValidationHelper.psm1",
            "DefenderXDRIntegrationBridge\LoggingHelper.psm1"
        )
        
        foreach ($module in $keyModules) {
            $modulePath = Join-Path $modulesDest $module
            if (Test-Path $modulePath) {
                Write-Host "  ✓ $module" -ForegroundColor Green
            } else {
                Write-Warning "  ✗ $module not found"
            }
        }
    } else {
        Write-Warning "Modules folder not found at $modulesSource"
    }
    
    # Create ZIP package
    Write-Host "`nCreating ZIP package..." -ForegroundColor Yellow
    
    $outputFullPath = Join-Path $scriptPath $OutputPath
    
    # Remove existing package
    if (Test-Path $outputFullPath) {
        Remove-Item $outputFullPath -Force
        Write-Host "  Removed existing package" -ForegroundColor Gray
    }
    
    # Create ZIP
    Compress-Archive -Path "$tempPath\*" -DestinationPath $outputFullPath -Force
    
    $packageSize = (Get-Item $outputFullPath).Length / 1MB
    Write-Host "  ✓ Package created: $outputFullPath" -ForegroundColor Green
    Write-Host "  Size: $([math]::Round($packageSize, 2)) MB" -ForegroundColor Cyan
    
    # Verify package contents
    Write-Host "`nVerifying package contents..." -ForegroundColor Yellow
    $zipContents = Get-ChildItem -Path $tempPath -Recurse -File
    $fileCount = $zipContents.Count
    Write-Host "  Total files: $fileCount" -ForegroundColor Cyan
    
    # Verify critical files
    $criticalFiles = @(
        "host.json",
        "profile.ps1",
        "requirements.psd1",
        "modules\DefenderXDRIntegrationBridge\BlobManager.psm1",
        "DefenderXDRMDEWorker\run.ps1"
    )
    
    $allCriticalPresent = $true
    foreach ($file in $criticalFiles) {
        $filePath = Join-Path $tempPath $file
        if (Test-Path $filePath) {
            Write-Host "  ✓ $file" -ForegroundColor Green
        } else {
            Write-Warning "  ✗ $file missing!"
            $allCriticalPresent = $false
        }
    }
    
    if ($allCriticalPresent) {
        Write-Host "`n=== PACKAGE CREATION SUCCESSFUL ===" -ForegroundColor Green
        Write-Host "Package: $outputFullPath" -ForegroundColor Cyan
        Write-Host "Ready for deployment to Azure Functions" -ForegroundColor Green
    } else {
        Write-Warning "`nPackage created but some critical files are missing. Review warnings above."
    }
    
} finally {
    # Cleanup temp directory
    Write-Host "`nCleaning up temp directory..." -ForegroundColor Gray
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nDone!" -ForegroundColor Cyan
