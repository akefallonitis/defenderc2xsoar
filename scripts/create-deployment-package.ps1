# Creates a deployment package for Azure Functions
# This script packages the functions directory into a zip file for deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./deploy-package.zip",
    
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "./functions"
)

Write-Host "🔧 Creating deployment package for Azure Functions..." -ForegroundColor Cyan

# Resolve paths
$OutputPath = Resolve-Path -Path $OutputPath -ErrorAction SilentlyContinue
if (-not $OutputPath) {
    $OutputPath = Join-Path (Get-Location) "deploy-package.zip"
}

$SourcePath = Resolve-Path -Path $SourcePath -ErrorAction SilentlyContinue
if (-not $SourcePath) {
    Write-Host "❌ Source path not found: $SourcePath" -ForegroundColor Red
    exit 1
}

# Remove old package
if (Test-Path $OutputPath) {
    Write-Host "🗑️  Removing old package: $OutputPath" -ForegroundColor Yellow
    Remove-Item $OutputPath -Force
}

# Create zip package
Write-Host "📦 Packaging: $SourcePath -> $OutputPath" -ForegroundColor Green
try {
    Compress-Archive -Path "$SourcePath/*" -DestinationPath $OutputPath -Force
    
    $packageSize = (Get-Item $OutputPath).Length / 1MB
    Write-Host "✅ Deployment package created successfully!" -ForegroundColor Green
    Write-Host "📦 Package path: $OutputPath" -ForegroundColor Cyan
    Write-Host "📏 Package size: $([math]::Round($packageSize, 2)) MB" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to create deployment package: $_" -ForegroundColor Red
    exit 1
}

# List contents
Write-Host "`n📋 Package contents:" -ForegroundColor Cyan
try {
    $zipContents = Expand-Archive -Path $OutputPath -DestinationPath "$env:TEMP/func-preview" -Force -PassThru
    Get-ChildItem "$env:TEMP/func-preview" -Recurse -Directory | ForEach-Object {
        Write-Host "  📁 $($_.FullName.Replace("$env:TEMP/func-preview", '.'))" -ForegroundColor Gray
    }
    Remove-Item "$env:TEMP/func-preview" -Recurse -Force
}
catch {
    Write-Host "  ⚠️  Could not list contents" -ForegroundColor Yellow
}

Write-Host "`n✅ Ready to deploy!" -ForegroundColor Green
Write-Host "Next step: Run quick-deploy.ps1 or upload via Azure Portal" -ForegroundColor Cyan
