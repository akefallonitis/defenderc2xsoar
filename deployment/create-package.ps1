# Create deployment package for Azure Functions
param(
    [string]$OutputPath = "./deployment/function-package.zip"
)

Write-Host "📦 Creating deployment package..." -ForegroundColor Cyan

# Resolve paths relative to script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptPath

# Set paths
$sourceDir = Join-Path $repoRoot "functions"
$outputFile = Join-Path $repoRoot "deployment" "function-package.zip"

# Verify source directory exists
if (-not (Test-Path $sourceDir)) {
    Write-Host "❌ Functions directory not found: $sourceDir" -ForegroundColor Red
    exit 1
}

# Remove old package
if (Test-Path $outputFile) {
    Write-Host "🗑️  Removing old package..." -ForegroundColor Yellow
    Remove-Item $outputFile -Force
}

# Create zip from functions directory
Write-Host "📦 Packaging functions from: $sourceDir" -ForegroundColor Cyan
try {
    Compress-Archive -Path "$sourceDir/*" -DestinationPath $outputFile -Force
    
    Write-Host "✅ Package created: $outputFile" -ForegroundColor Green
    $sizeInMB = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
    Write-Host "📊 Size: $sizeInMB MB" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to create package: $_" -ForegroundColor Red
    exit 1
}

# List package contents
Write-Host "`n📋 Package contents:" -ForegroundColor Cyan
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($outputFile)
    $zip.Entries | Select-Object -First 20 | ForEach-Object {
        Write-Host "  📄 $($_.FullName)" -ForegroundColor Gray
    }
    $zip.Dispose()
    
    $totalEntries = ([System.IO.Compression.ZipFile]::OpenRead($outputFile)).Entries.Count
    if ($totalEntries -gt 20) {
        Write-Host "  ... and $($totalEntries - 20) more files" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  ⚠️  Could not list package contents" -ForegroundColor Yellow
}

Write-Host "`n⚠️  IMPORTANT: Commit this file to GitHub:" -ForegroundColor Yellow
Write-Host "   git add deployment/function-package.zip" -ForegroundColor White
Write-Host "   git commit -m 'Update deployment package'" -ForegroundColor White
Write-Host "   git push" -ForegroundColor White
