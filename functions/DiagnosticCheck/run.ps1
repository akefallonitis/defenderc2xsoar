using namespace System.Net

<#
.SYNOPSIS
    Diagnostic endpoint to check environment configuration

.DESCRIPTION
    Returns environment variables and configuration status for troubleshooting
#>

param($Request, $TriggerMetadata)

Write-Host "Diagnostic - Checking environment configuration"

$diagnostics = @{
    timestamp = (Get-Date).ToString("o")
    functionApp = @{
        hostname = $env:WEBSITE_HOSTNAME
        resourceGroup = $env:WEBSITE_RESOURCE_GROUP
        siteName = $env:WEBSITE_SITE_NAME
        runFrom Package = $env:WEBSITE_RUN_FROM_PACKAGE
    }
    credentials = @{
        appIdConfigured = [bool]$env:APPID
        appIdValue = if ($env:APPID) { "$($env:APPID.Substring(0,8))..." } else { "NOT SET" }
        secretIdConfigured = [bool]$env:SECRETID
        secretIdValue = if ($env:SECRETID) { "***CONFIGURED***" } else { "NOT SET" }
    }
    storage = @{
        accountConfigured = [bool]$env:AzureWebJobsStorage
        accountName = if ($env:STORAGE_ACCOUNT_NAME) { $env:STORAGE_ACCOUNT_NAME } else { "Not set in env" }
    }
    runtime = @{
        psVersion = $PSVersionTable.PSVersion.ToString()
        osVersion = $env:OS
        workerRuntime = $env:FUNCTIONS_WORKER_RUNTIME
        extensionVersion = $env:FUNCTIONS_EXTENSION_VERSION
    }
}

# Test module loading
try {
    $modulePath = "$PSScriptRoot\..\modules\DefenderXDRIntegrationBridge"
    $diagnostics.modules = @{
        basePath = $modulePath
        authManagerExists = Test-Path "$modulePath\AuthManager.psm1"
        validationHelperExists = Test-Path "$modulePath\ValidationHelper.psm1"
        loggingHelperExists = Test-Path "$modulePath\LoggingHelper.psm1"
    }
}
catch {
    $diagnostics.modules = @{
        error = $_.Exception.Message
    }
}

# Return diagnostics
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $diagnostics | ConvertTo-Json -Depth 5
    Headers = @{ "Content-Type" = "application/json" }
})
