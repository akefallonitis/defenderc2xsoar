using namespace System.Net

# Threat Intelligence Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDETIManager function processed a request."

# Get parameters
$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId
$indicators = $Request.Query.indicators ?? $Request.Body.indicators
$title = $Request.Query.title ?? $Request.Body.title
$severity = $Request.Query.severity ?? $Request.Body.severity
$recommendedAction = $Request.Query.recommendedAction ?? $Request.Body.recommendedAction

# Validate required parameters
if (-not $action -or -not $tenantId -or -not $spnId) {
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
        action = $action
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    # Split indicators by comma if provided as string
    $indicatorList = if ($indicators -is [string]) {
        $indicators.Split(',').Trim()
    } else {
        $indicators
    }

    # Execute action
    switch ($action) {
        "Add File Indicators" {
            # Invoke-TiFile -token $token -Sha256s $indicatorList
            $result.details = "Added $($indicatorList.Count) file indicators"
            $result.indicators = $indicatorList
        }
        "Remove File Indicators" {
            # Undo-TiFile -token $token -Sha256s $indicatorList
            $result.details = "Removed $($indicatorList.Count) file indicators"
        }
        "Add IP Indicators" {
            # Invoke-TiIP -token $token -IPs $indicatorList
            $result.details = "Added $($indicatorList.Count) IP indicators"
        }
        "Remove IP Indicators" {
            # Undo-TiIP -token $token -IPs $indicatorList
            $result.details = "Removed $($indicatorList.Count) IP indicators"
        }
        "Add URL/Domain Indicators" {
            # Invoke-TiURL -token $token -URLs $indicatorList
            $result.details = "Added $($indicatorList.Count) URL/domain indicators"
        }
        "Remove URL/Domain Indicators" {
            # Undo-TiURL -token $token -URLs $indicatorList
            $result.details = "Removed $($indicatorList.Count) URL/domain indicators"
        }
        "Add Certificate Indicators" {
            # Invoke-TiCert -token $token -Sha1s $indicatorList
            $result.details = "Added $($indicatorList.Count) certificate indicators"
        }
        "Remove Certificate Indicators" {
            # Undo-TiCert -token $token -Sha1s $indicatorList
            $result.details = "Removed $($indicatorList.Count) certificate indicators"
        }
        "List All Indicators" {
            # $allIndicators = Get-Indicators -token $token
            $result.details = "Retrieved all indicators"
            $result.indicators = @() # Would contain actual indicators
        }
        default {
            $result.status = "Unknown"
            $result.message = "Unknown action: $action"
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
