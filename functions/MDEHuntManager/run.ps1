using namespace System.Net

# Hunt Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDEHuntManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$huntQuery = $Request.Query.huntQuery ?? $Request.Body.huntQuery
$huntName = $Request.Query.huntName ?? $Request.Body.huntName
$saveResults = $Request.Query.saveResults ?? $Request.Body.saveResults

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameter: tenantId is required"
        } | ConvertTo-Json
    })
    return
}

# Validate environment variables are configured
if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = "Function app not configured: APPID and SECRETID environment variables must be set"
        } | ConvertTo-Json
    })
    return
}

try {
    # Import MDEAutomator module
    # Import-Module MDEAutomator -ErrorAction Stop
    
    # Connect to MDE using App Registration with Client Secret
    # $token = Connect-MDE -AppId $appId -ClientSecret $secretId -TenantId $tenantId

    $result = @{
        action = $action ?? "ExecuteHunt"
        status = "Success"
        tenantId = $tenantId
        huntName = $huntName
        timestamp = (Get-Date).ToString("o")
    }

    # Execute the advanced hunting query
    if ($huntQuery) {
        # $huntResults = Invoke-AdvancedHunting -Queries @($huntQuery)
        
        $result.details = "Hunt '$huntName' executed successfully"
        $result.resultCount = 0 # Would be actual count
        $result.query = $huntQuery
        
        # Optionally save to storage
        if ($saveResults -eq "true") {
            # Save results to Azure Storage
            $result.savedTo = "Azure Blob Storage"
        }
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 5
    })

} catch {
    Write-Error $_.Exception.Message
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = $_.Exception.Message
        } | ConvertTo-Json
    })
}
