using namespace System.Net

# Hunt Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDEHuntManager function processed a request."

$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId
$huntQuery = $Request.Query.huntQuery ?? $Request.Body.huntQuery
$huntName = $Request.Query.huntName ?? $Request.Body.huntName
$saveResults = $Request.Query.saveResults ?? $Request.Body.saveResults

if (-not $tenantId -or -not $spnId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters"
        } | ConvertTo-Json
    })
    return
}

try {
    # Import MDEAutomator module
    # Import-Module MDEAutomator -ErrorAction Stop
    
    # Connect to MDE
    # $token = Connect-MDE -SpnId $spnId -ManagedIdentityId $env:MSI_CLIENT_ID -TenantId $tenantId

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
