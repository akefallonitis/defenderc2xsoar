Write-Host 'Creating package...' -ForegroundColor Cyan
Compress-Archive -Path '../functions/*' -DestinationPath 'function-package.zip' -Force
Write-Host 'Package created!' -ForegroundColor Green
