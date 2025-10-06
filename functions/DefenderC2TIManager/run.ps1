using namespace System.Net

# Threat Intelligence Manager Function
param($Request, $TriggerMetadata)

Write-Host "DefenderC2TIManager function processed a request."

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
    # Connect to MDE using App Registration with Client Secret
    $token = Connect-MDE -TenantId $tenantId -AppId $appId -ClientSecret $secretId

    $result = @{
        action = $action
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
    }

    # Split indicators by comma if provided as string
    $indicatorList = if ($indicators -is [string]) {
        $indicators.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    } else {
        $indicators
    }

    # Set default values for required parameters
    $indicatorTitle = if ($title) { $title } else { "Indicator added via Azure Function" }
    $indicatorSeverity = if ($severity) { $severity } else { "Medium" }
    $indicatorAction = if ($recommendedAction) { $recommendedAction } else { "Alert" }

    # Execute action
    switch ($action) {
        "Add File Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicators required for adding file indicators"
            }
            $responses = @()
            foreach ($hash in $indicatorList) {
                try {
                    $response = Add-FileIndicator -Token $token -Sha256 $hash -Title $indicatorTitle -Severity $indicatorSeverity -Action $indicatorAction -Description "Added via Azure Function"
                    $responses += $response
                } catch {
                    Write-Warning "Failed to add indicator $hash : $($_.Exception.Message)"
                }
            }
            $result.details = "Added $($responses.Count) of $($indicatorList.Count) file indicators"
            $result.indicators = $indicatorList
            $result.responses = $responses
        }
        "Remove File Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicator IDs required for removing file indicators"
            }
            $removed = 0
            foreach ($indicatorId in $indicatorList) {
                try {
                    Remove-FileIndicator -Token $token -IndicatorId $indicatorId
                    $removed++
                } catch {
                    Write-Warning "Failed to remove indicator $indicatorId : $($_.Exception.Message)"
                }
            }
            $result.details = "Removed $removed of $($indicatorList.Count) file indicators"
        }
        "Add IP Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicators required for adding IP indicators"
            }
            $responses = @()
            foreach ($ip in $indicatorList) {
                try {
                    $response = Add-IPIndicator -Token $token -IPAddress $ip -Title $indicatorTitle -Severity $indicatorSeverity -Action $indicatorAction -Description "Added via Azure Function"
                    $responses += $response
                } catch {
                    Write-Warning "Failed to add IP indicator $ip : $($_.Exception.Message)"
                }
            }
            $result.details = "Added $($responses.Count) of $($indicatorList.Count) IP indicators"
            $result.responses = $responses
        }
        "Remove IP Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicator IDs required for removing IP indicators"
            }
            $removed = 0
            foreach ($indicatorId in $indicatorList) {
                try {
                    Remove-FileIndicator -Token $token -IndicatorId $indicatorId
                    $removed++
                } catch {
                    Write-Warning "Failed to remove indicator $indicatorId : $($_.Exception.Message)"
                }
            }
            $result.details = "Removed $removed of $($indicatorList.Count) IP indicators"
        }
        "Add URL/Domain Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicators required for adding URL/domain indicators"
            }
            $responses = @()
            foreach ($url in $indicatorList) {
                try {
                    $response = Add-URLIndicator -Token $token -URL $url -Title $indicatorTitle -Severity $indicatorSeverity -Action $indicatorAction -Description "Added via Azure Function"
                    $responses += $response
                } catch {
                    Write-Warning "Failed to add URL indicator $url : $($_.Exception.Message)"
                }
            }
            $result.details = "Added $($responses.Count) of $($indicatorList.Count) URL/domain indicators"
            $result.responses = $responses
        }
        "Remove URL/Domain Indicators" {
            if (-not $indicatorList -or $indicatorList.Count -eq 0) {
                throw "Indicator IDs required for removing URL/domain indicators"
            }
            $removed = 0
            foreach ($indicatorId in $indicatorList) {
                try {
                    Remove-FileIndicator -Token $token -IndicatorId $indicatorId
                    $removed++
                } catch {
                    Write-Warning "Failed to remove indicator $indicatorId : $($_.Exception.Message)"
                }
            }
            $result.details = "Removed $removed of $($indicatorList.Count) URL/domain indicators"
        }
        "List All Indicators" {
            $allIndicators = Get-AllIndicators -Token $token
            $result.details = "Retrieved $($allIndicators.Count) indicators"
            $result.indicators = $allIndicators
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
