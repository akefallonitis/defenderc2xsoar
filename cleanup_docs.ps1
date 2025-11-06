# Cleanup unnecessary documentation files
# Run this to clean up old/duplicate documentation

Write-Host "🧹 Cleaning up unnecessary documentation files..." -ForegroundColor Cyan

# Files to DELETE (duplicates, outdated, or superseded)
$filesToDelete = @(
    "ARM_ACTIONS_ANALYSIS.md",
    "ARM_ACTIONS_FIXED.md",
    "ARM_ACTIONS_NOW_WORK.md",
    "ARM_PATHS_FIXED_FINAL.md",
    "ARM_PATH_ISSUE_CRITICAL.md",
    "AUTO_FETCH_KEYS_GUIDE.md",
    "CRITICAL_ARM_ACTION_BUG.md",
    "CRITICAL_ARM_CANNOT_INVOKE_FUNCTIONS.md",
    "CRITICAL_FIX_COMPLETE.md",
    "CRITICAL_FIX_REQUIRED.md",
    "DEFENDERC2_COMPLETE_WORKBOOK.md",
    "DEFENDERC2_ENHANCEMENT_SUMMARY.md",
    "DEFENDERC2_PRODUCTION_PLAN.md",
    "DEFENDERC2_PRODUCTION_WORKBOOKS.md",
    "DEFENDERC2_PROJECT_SUMMARY.md",
    "DELIVERY_COMPLETE.md",
    "DEPLOYMENT_COMPLETE_GUIDE.md",
    "DEPLOYMENT_FINAL_v3.md",
    "DEPLOYMENT_GUIDE_PERFECT.md",
    "DEPLOYMENT_PACKAGE_UPDATE.md",
    "DEPLOYMENT_READY.md",
    "DEPLOYMENT_READY_v3.md",
    "DEPLOYMENT_VERIFICATION_CHECKLIST.md",
    "DEPLOY_FIXED_WORKBOOK.md",
    "DEPLOY_MINIMAL_WORKBOOK.md",
    "DEPLOY_NOW.md",
    "DEPLOY_NOW_v4.md",
    "DEPLOY_PARAMETER_WAITING_FIX.md",
    "DeviceManager-CustomEndpoint-Only.workbook.json",
    "FINAL_DELIVERY_COMPLETE.md",
    "FINAL_FIX_COMPLETE.md",
    "FINAL_STATUS_REPORT.md",
    "QUICKSTART_DEPLOYMENT.md",
    "QUICK_DEPLOY_NOW.md",
    "THE_ACTUAL_SOLUTION.md",
    "TRANSFORMATION_SUMMARY.md",
    "WORKBOOK_COMPLETE.md",
    "WORKBOOK_COMPLETE_SUMMARY.md",
    "WORKBOOK_FIX_COMPLETE.md",
    "WORKBOOK_VISUAL_GUIDE.md"
)

# Move to archive instead of delete
$archivePath = "archive\old-docs"
if (-not (Test-Path $archivePath)) {
    New-Item -Path $archivePath -ItemType Directory -Force | Out-Null
}

$moved = 0
$notFound = 0

foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Move-Item -Path $fullPath -Destination $archivePath -Force
        Write-Host "✅ Moved: $file" -ForegroundColor Green
        $moved++
    } else {
        Write-Host "⚠️  Not found: $file" -ForegroundColor Yellow
        $notFound++
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Moved to archive: $moved files" -ForegroundColor Green
Write-Host "  Not found: $notFound files" -ForegroundColor Yellow

Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
Write-Host "`nKept essential files:" -ForegroundColor Cyan
Write-Host "  - README.md (Main documentation)" -ForegroundColor White
Write-Host "  - QUICKSTART.md (Quick start guide)" -ForegroundColor White
Write-Host "  - DEPLOYMENT.md (Deployment guide)" -ForegroundColor White
Write-Host "  - DEFENDERC2_QUICKREF.md (Quick reference)" -ForegroundColor White
Write-Host "  - DOCUMENTATION_INDEX.md (Documentation index)" -ForegroundColor White
Write-Host "  - AUTH_LEVEL_UPDATE.md (Latest auth level changes)" -ForegroundColor White
Write-Host "  - CRITICAL_FINDING.md (ARM action auth level issue)" -ForegroundColor White
