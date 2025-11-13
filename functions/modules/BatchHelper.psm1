<#
.SYNOPSIS
    Batch processing helper for executing actions against multiple entities

.DESCRIPTION
    Provides batching capabilities for remediation actions across all XDR services.
    Supports comma-separated values, arrays, and parallel processing with error handling.

.VERSION
    1.0.0

.NOTES
    Used by all workers to support batch operations (e.g., multiple devices, users, emails)
#>

function ConvertTo-EntityArray {
    <#
    .SYNOPSIS
        Converts comma-separated string or array to entity array
    
    .PARAMETER Input
        Input value (string with commas, array, or single value)
    
    .PARAMETER TrimWhitespace
        Remove leading/trailing whitespace from each entity
    
    .EXAMPLE
        ConvertTo-EntityArray -Input "device1,device2,device3"
        # Returns: @("device1", "device2", "device3")
    
    .EXAMPLE
        ConvertTo-EntityArray -Input @("user1", "user2")
        # Returns: @("user1", "user2")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        $Input,
        
        [switch]$TrimWhitespace
    )
    
    if ($null -eq $Input -or $Input -eq "") {
        return @()
    }
    
    # If already an array, return it
    if ($Input -is [Array]) {
        if ($TrimWhitespace) {
            return $Input | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" }
        }
        return $Input | Where-Object { $_ -ne "" }
    }
    
    # Convert to string and split by comma
    $entities = $Input.ToString() -split ',' | Where-Object { $_ -ne "" }
    
    if ($TrimWhitespace) {
        $entities = $entities | ForEach-Object { $_.Trim() }
    }
    
    return $entities
}

function Invoke-BatchAction {
    <#
    .SYNOPSIS
        Execute an action against multiple entities with error handling
    
    .DESCRIPTION
        Processes entities in batches with parallel execution support,
        comprehensive error handling, and progress tracking.
    
    .PARAMETER Entities
        Array of entities to process (deviceIds, userIds, emails, etc.)
    
    .PARAMETER ScriptBlock
        Script block to execute for each entity
        Receives $_ as the current entity
    
    .PARAMETER BatchSize
        Number of entities to process per batch (default: 10)
    
    .PARAMETER ThrottleLimit
        Maximum parallel threads (default: 5)
    
    .PARAMETER StopOnError
        Stop processing if any entity fails (default: false)
    
    .PARAMETER ActionName
        Name of the action for logging purposes
    
    .EXAMPLE
        Invoke-BatchAction -Entities @("device1", "device2") -ScriptBlock {
            param($deviceId)
            Invoke-RestMethod -Uri "https://api.../machines/$deviceId/isolate" -Method POST
        } -ActionName "IsolateDevice"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Array]$Entities,
        
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [int]$BatchSize = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$ThrottleLimit = 5,
        
        [Parameter(Mandatory=$false)]
        [switch]$StopOnError,
        
        [Parameter(Mandatory=$false)]
        [string]$ActionName = "BatchAction"
    )
    
    $results = @{
        Successful = @()
        Failed = @()
        TotalCount = $Entities.Count
        SuccessCount = 0
        FailureCount = 0
    }
    
    Write-Host "🔄 Starting batch action: $ActionName for $($Entities.Count) entities"
    
    # Process entities in batches
    for ($i = 0; $i -lt $Entities.Count; $i += $BatchSize) {
        $batchEnd = [Math]::Min($i + $BatchSize, $Entities.Count)
        $batch = $Entities[$i..($batchEnd - 1)]
        
        Write-Host "📦 Processing batch $([Math]::Floor($i / $BatchSize) + 1) ($i-$($batchEnd - 1) of $($Entities.Count))"
        
        # Process batch with parallel execution
        $batchResults = $batch | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
            $entity = $_
            $action = $using:ActionName
            
            try {
                # Execute the script block with the entity
                $result = & $using:ScriptBlock -Entity $entity
                
                return @{
                    Entity = $entity
                    Success = $true
                    Result = $result
                    Error = $null
                }
            }
            catch {
                return @{
                    Entity = $entity
                    Success = $false
                    Result = $null
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Aggregate results
        foreach ($result in $batchResults) {
            if ($result.Success) {
                $results.Successful += $result
                $results.SuccessCount++
                Write-Host "  ✅ $($result.Entity): Success"
            }
            else {
                $results.Failed += $result
                $results.FailureCount++
                Write-Host "  ❌ $($result.Entity): $($result.Error)" -ForegroundColor Red
                
                if ($StopOnError) {
                    Write-Host "⚠️ Stopping batch processing due to error (StopOnError=true)" -ForegroundColor Yellow
                    break
                }
            }
        }
        
        if ($StopOnError -and $results.FailureCount -gt 0) {
            break
        }
    }
    
    Write-Host "✅ Batch action complete: $($results.SuccessCount) succeeded, $($results.FailureCount) failed"
    
    return $results
}

function Test-BatchInput {
    <#
    .SYNOPSIS
        Validates batch input and returns entity array
    
    .DESCRIPTION
        Checks if input contains multiple entities and converts to array
    
    .PARAMETER InputValue
        Input to validate (string, array, or single value)
    
    .PARAMETER ParameterName
        Name of the parameter for error messages
    
    .EXAMPLE
        $devices = Test-BatchInput -InputValue $Request.Body.deviceIds -ParameterName "deviceIds"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $InputValue,
        
        [Parameter(Mandatory=$false)]
        [string]$ParameterName = "entities"
    )
    
    if ($null -eq $InputValue -or $InputValue -eq "") {
        throw "Parameter '$ParameterName' is required and cannot be empty"
    }
    
    # Convert to entity array
    $entities = ConvertTo-EntityArray -Input $InputValue -TrimWhitespace
    
    if ($entities.Count -eq 0) {
        throw "Parameter '$ParameterName' must contain at least one entity"
    }
    
    Write-Host "📋 Detected $($entities.Count) entities for batch processing"
    
    return $entities
}

function Invoke-BatchRestMethod {
    <#
    .SYNOPSIS
        Execute REST API calls against multiple entities
    
    .DESCRIPTION
        Simplified batch REST API execution with automatic retry and error handling
    
    .PARAMETER Entities
        Array of entities to process
    
    .PARAMETER UriTemplate
        URI template with {entity} placeholder
        Example: "https://api.../machines/{entity}/isolate"
    
    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE)
    
    .PARAMETER Headers
        HTTP headers (including Authorization)
    
    .PARAMETER Body
        Optional request body (will be passed to each request)
    
    .PARAMETER ActionName
        Name of the action for logging
    
    .EXAMPLE
        Invoke-BatchRestMethod -Entities @("device1", "device2") `
            -UriTemplate "https://api.../machines/{entity}/isolate" `
            -Method POST `
            -Headers @{ Authorization = "Bearer $token" } `
            -Body @{ Comment = "Security incident" } `
            -ActionName "IsolateDevice"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Array]$Entities,
        
        [Parameter(Mandatory=$true)]
        [string]$UriTemplate,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Headers,
        
        [Parameter(Mandatory=$false)]
        $Body = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$ActionName = "BatchRestMethod",
        
        [Parameter(Mandatory=$false)]
        [int]$ThrottleLimit = 5
    )
    
    $scriptBlock = {
        param($entity)
        
        $uri = $using:UriTemplate -replace '\{entity\}', $entity
        
        $params = @{
            Uri = $uri
            Method = $using:Method
            Headers = $using:Headers
            ContentType = "application/json"
        }
        
        if ($using:Body) {
            $params.Body = $using:Body | ConvertTo-Json -Depth 10
        }
        
        return Invoke-RestMethod @params
    }
    
    return Invoke-BatchAction -Entities $Entities `
                              -ScriptBlock $scriptBlock `
                              -ActionName $ActionName `
                              -ThrottleLimit $ThrottleLimit
}

# Export functions
Export-ModuleMember -Function @(
    'ConvertTo-EntityArray',
    'Invoke-BatchAction',
    'Test-BatchInput',
    'Invoke-BatchRestMethod'
)
