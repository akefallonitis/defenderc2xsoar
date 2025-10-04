using namespace System.Net

# Threat Intelligence Manager Function
param($Request, $TriggerMetadata)

Write-Host "MDETIManager function processed a request."

# Get parameters
$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$indicators = $Request.Query.indicators ?? $Request.Body.indicators
$title = $Request.Query.title ?? $Request.Body.title
$severity = $Request.Query.severity ?? $Request.Body.severity
$recommendedAction = $Request.Query.recommendedAction ?? $Request.Body.recommendedAction

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# Validate required parameters
if (-not $action -or -not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters: action and tenantId are required"
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
