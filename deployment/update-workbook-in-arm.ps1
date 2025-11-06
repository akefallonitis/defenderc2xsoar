# Update ARM template with latest DefenderC2-Workbook.json
$ErrorActionPreference = "Stop"

$workbookPath = Join-Path $PSScriptRoot "..\workbook\DefenderC2-Workbook.json"
$armTemplatePath = Join-Path $PSScriptRoot "azuredeploy.json"

Write-Host "Reading workbook from: $workbookPath"
$workbookContent = Get-Content $workbookPath -Raw -Encoding UTF8

Write-Host "Converting to base64..."
$bytes = [System.Text.Encoding]::UTF8.GetBytes($workbookContent)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "Base64 length: $($base64.Length) bytes"

Write-Host "Reading ARM template..."
$armContent = Get-Content $armTemplatePath -Raw -Encoding UTF8

# Find and replace the workbookContent variable
$pattern = '("workbookContent":\s*")([^"]+)(")'
if ($armContent -match $pattern) {
    Write-Host "Found workbookContent in ARM template"
    $armContent = $armContent -replace $pattern, "`$1$base64`$3"
    
    Write-Host "Writing updated ARM template..."
    $armContent | Set-Content $armTemplatePath -Encoding UTF8 -NoNewline
    
    Write-Host "✅ ARM template updated successfully!" -ForegroundColor Green
    Write-Host "   New workbookContent length: $($base64.Length) bytes" -ForegroundColor Cyan
} else {
    Write-Error "Could not find workbookContent variable in ARM template"
}
