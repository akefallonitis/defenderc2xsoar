# Fix ALL ARM Actions to use proper ARM resource provider paths
# ARM Actions MUST use Azure Management API endpoints, NOT direct HTTPS

$workbookPath = "c:\Users\AlexandrosKefallonit\Desktop\FF\defenderc2xsoar\workbook\DefenderC2-Workbook.json"
$content = Get-Content $workbookPath -Raw

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Fixing ARM Actions to use Azure Management API paths      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Count current state
$directHttpsCount = ([regex]::Matches($content, '"path": "https://{FunctionAppName}\.azurewebsites\.net/api/')).Count
$armPathCount = ([regex]::Matches($content, '"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft\.Web/sites/{FunctionAppName}/host/default/admin/functions/')).Count

Write-Host "Current state:" -ForegroundColor Yellow
Write-Host "  Direct HTTPS paths in armActionContext: $directHttpsCount" -ForegroundColor $(if ($directHttpsCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Proper ARM paths: $armPathCount" -ForegroundColor Green

# Fix pattern: Replace direct HTTPS with ARM resource provider path
# Pattern for each function name
$functionNames = @(
    "DefenderC2Dispatcher",
    "DefenderC2CDManager", 
    "DefenderC2HuntManager",
    "DefenderC2IncidentManager",
    "DefenderC2TIManager",
    "DefenderC2Orchestrator"
)

$totalFixed = 0

foreach ($funcName in $functionNames) {
    # Match the HTTPS pattern with headers array
    $oldPattern = @"
"path": "https://{FunctionAppName}.azurewebsites.net/api/$funcName\?code={FunctionKey}",
                    "headers": \[
                      \{
                        "key": "Content-Type",
                        "value": "application/json"
                      \}
                    \],
"@

    $newPattern = @"
"path": "/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/host/default/admin/functions/$funcName",
                    "headers": [],
                    "params": [
                      {
                        "key": "api-version",
                        "value": "2022-03-01"
                      }
                    ],
"@

    $matches = [regex]::Matches($content, [regex]::Escape($oldPattern.Replace("\?", "?").Replace("\[", "[").Replace("\]", "]").Replace("\{", "{").Replace("\}", "}")))
    
    if ($matches.Count -gt 0) {
        Write-Host "`nFixing $($matches.Count) ARM Actions for function: $funcName" -ForegroundColor Cyan
        $content = $content -replace [regex]::Escape($oldPattern.Replace("\?", "?").Replace("\[", "[").Replace("\]", "]").Replace("\{", "{").Replace("\}", "}")), $newPattern
        $totalFixed += $matches.Count
    }
}

# Save the file
$content | Set-Content $workbookPath -NoNewline

# Verify the fix
$newContent = Get-Content $workbookPath -Raw
$newDirectHttps = ([regex]::Matches($newContent, '"path": "https://{FunctionAppName}\.azurewebsites\.net/api/')).Count
$newArmPaths = ([regex]::Matches($newContent, '"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft\.Web/sites/{FunctionAppName}/host/default/admin/functions/')).Count

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                       FIX COMPLETE!                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Fixed $totalFixed ARM Actions" -ForegroundColor Green
Write-Host "  Remaining Direct HTTPS paths: $newDirectHttps" -ForegroundColor $(if ($newDirectHttps -gt 0) { "Red" } else { "Green" })
Write-Host "  Total ARM paths: $newArmPaths" -ForegroundColor Green

if ($newDirectHttps -eq 0) {
    Write-Host "`n✅ SUCCESS! All ARM Actions now use proper ARM Management API paths!" -ForegroundColor Green
    Write-Host "`nThe ARM Actions will now:" -ForegroundColor Cyan
    Write-Host "  ✓ Use Azure Management API endpoint" -ForegroundColor White
    Write-Host "  ✓ Authenticate via user's Azure RBAC permissions" -ForegroundColor White
    Write-Host "  ✓ Invoke functions through /host/default/admin/functions/{name}" -ForegroundColor White
    Write-Host "  ✓ Work in Azure Portal Workbooks!" -ForegroundColor White
} else {
    Write-Host "`n⚠️  WARNING: Still have $newDirectHttps direct HTTPS paths!" -ForegroundColor Red
    Write-Host "These may be in CustomEndpoint queries (which is OK) or need manual fixing." -ForegroundColor Yellow
}

Write-Host "`n"
