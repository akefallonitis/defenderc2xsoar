using namespace System.Net

# Hunt Manager Function
param($Request, $TriggerMetadata)

Write-Host "DefenderC2HuntManager function processed a request."

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
    # Connect to MDE using App Registration with Client Secret
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

    $result = @{
        action = $action ?? "ExecuteHunt"
        status = "Success"
        tenantId = $tenantId
        huntName = $huntName
        timestamp = (Get-Date).ToString("o")
    }

    # Execute the advanced hunting query
    if ($huntQuery) {
        $huntResults = Invoke-AdvancedHunting -Token $token -Query $huntQuery
        
        $result.details = "Hunt '$huntName' executed successfully"
        $result.resultCount = $huntResults.Count
        $result.query = $huntQuery
        $result.results = $huntResults | Select-Object -First 1000  # Limit results for response size
        
        # Optionally save to storage
        if ($saveResults -eq "true") {
            # In a production scenario, you would save to Azure Storage here
            # For now, just indicate the intent
            $result.savedTo = "Azure Blob Storage (not implemented)"
            $result.note = "Saving to storage would require additional Azure Storage configuration"
        }
    } else {
        throw "Hunt query is required"
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
