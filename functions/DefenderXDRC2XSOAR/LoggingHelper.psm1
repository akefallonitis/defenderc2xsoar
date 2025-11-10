<#
.SYNOPSIS
    Logging and Telemetry Helper Module for XDR Orchestrator
    
.DESCRIPTION
    Provides structured logging capabilities with Application Insights integration:
    - Request/response logging with correlation IDs
    - Performance metrics tracking
    - Error and exception logging
    - Custom event tracking
    - Dependency tracking for external API calls
    
.NOTES
    Version: 2.1.0
    Part of DefenderXDRC2XSOAR module
#>

# ============================================================================
# LOGGING LEVELS
# ============================================================================

enum LogLevel {
    Trace = 0
    Debug = 1
    Information = 2
    Warning = 3
    Error = 4
    Critical = 5
}

# ============================================================================
# STRUCTURED LOGGING
# ============================================================================

function Write-XDRLog {
    <#
    .SYNOPSIS
        Writes structured log entry with correlation tracking
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception
    )
    
    # Build structured log entry
    $logEntry = @{
        timestamp = (Get-Date).ToString("o")
        level = $Level.ToString()
        message = $Message
    }
    
    if ($CorrelationId) { $logEntry.correlationId = $CorrelationId }
    if ($TenantId) { $logEntry.tenantId = $TenantId }
    if ($Service) { $logEntry.service = $Service }
    if ($Action) { $logEntry.action = $Action }
    
    if ($Properties) {
        $logEntry.properties = $Properties
    }
    
    if ($Exception) {
        $logEntry.exception = @{
            type = $Exception.GetType().FullName
            message = $Exception.Message
            stackTrace = $Exception.StackTrace
        }
    }
    
    # Convert to JSON for structured logging
    $jsonLog = $logEntry | ConvertTo-Json -Depth 5 -Compress
    
    # Write to appropriate stream based on level
    switch ($Level) {
        ([LogLevel]::Trace) { Write-Verbose $jsonLog }
        ([LogLevel]::Debug) { Write-Verbose $jsonLog }
        ([LogLevel]::Information) { Write-Host $jsonLog }
        ([LogLevel]::Warning) { Write-Warning $jsonLog }
        ([LogLevel]::Error) { Write-Error $jsonLog }
        ([LogLevel]::Critical) { Write-Error $jsonLog }
    }
    
    # Send to Application Insights if available
    if ($env:APPLICATIONINSIGHTS_CONNECTION_STRING) {
        Send-ToApplicationInsights -LogEntry $logEntry -Level $Level
    }
}

# ============================================================================
# REQUEST/RESPONSE LOGGING
# ============================================================================

function Write-XDRRequestLog {
    <#
    .SYNOPSIS
        Logs incoming request details
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$UserId,
        
        [Parameter(Mandatory = $false)]
        [string]$SourceIP,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalProperties
    )
    
    $properties = @{
        eventType = "RequestReceived"
        userId = $UserId
        sourceIP = $SourceIP
    }
    
    if ($AdditionalProperties) {
        $AdditionalProperties.GetEnumerator() | ForEach-Object {
            $properties[$_.Key] = $_.Value
        }
    }
    
    Write-XDRLog -Level ([LogLevel]::Information) `
        -Message "Request received" `
        -CorrelationId $CorrelationId `
        -TenantId $TenantId `
        -Service $Service `
        -Action $Action `
        -Properties $properties
}

function Write-XDRResponseLog {
    <#
    .SYNOPSIS
        Logs response details with performance metrics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [int]$StatusCode,
        
        [Parameter(Mandatory = $true)]
        [double]$DurationMs,
        
        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalProperties
    )
    
    $properties = @{
        eventType = "ResponseSent"
        statusCode = $StatusCode
        durationMs = $DurationMs
        success = $Success
    }
    
    if ($ErrorMessage) {
        $properties.errorMessage = $ErrorMessage
    }
    
    if ($AdditionalProperties) {
        $AdditionalProperties.GetEnumerator() | ForEach-Object {
            $properties[$_.Key] = $_.Value
        }
    }
    
    $level = if ($Success) { [LogLevel]::Information } else { [LogLevel]::Error }
    $message = if ($Success) { "Request completed successfully" } else { "Request failed" }
    
    Write-XDRLog -Level $level `
        -Message "$message (${DurationMs}ms)" `
        -CorrelationId $CorrelationId `
        -TenantId $TenantId `
        -Service $Service `
        -Action $Action `
        -Properties $properties
}

# ============================================================================
# AUTHENTICATION LOGGING
# ============================================================================

function Write-XDRAuthLog {
    <#
    .SYNOPSIS
        Logs authentication events
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$AppId,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [bool]$UsedCache = $false,
        
        [Parameter(Mandatory = $false)]
        [double]$DurationMs,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )
    
    $properties = @{
        eventType = "Authentication"
        appId = $AppId
        success = $Success
        usedCache = $UsedCache
        durationMs = $DurationMs
    }
    
    if ($ErrorMessage) {
        $properties.errorMessage = $ErrorMessage
    }
    
    $level = if ($Success) { [LogLevel]::Information } else { [LogLevel]::Warning }
    $message = if ($Success) {
        if ($UsedCache) { "Authentication successful (cached token)" } else { "Authentication successful (new token)" }
    } else {
        "Authentication failed"
    }
    
    Write-XDRLog -Level $level `
        -Message $message `
        -CorrelationId $CorrelationId `
        -TenantId $TenantId `
        -Service $Service `
        -Properties $properties
}

# ============================================================================
# DEPENDENCY TRACKING (API CALLS)
# ============================================================================

function Write-XDRDependencyLog {
    <#
    .SYNOPSIS
        Logs external API dependency calls
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $true)]
        [string]$DependencyName,
        
        [Parameter(Mandatory = $true)]
        [string]$DependencyType,
        
        [Parameter(Mandatory = $true)]
        [string]$Target,
        
        [Parameter(Mandatory = $false)]
        [string]$Data,
        
        [Parameter(Mandatory = $true)]
        [double]$DurationMs,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [int]$ResultCode,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )
    
    $properties = @{
        eventType = "Dependency"
        dependencyName = $DependencyName
        dependencyType = $DependencyType
        target = $Target
        durationMs = $DurationMs
        success = $Success
        resultCode = $ResultCode
    }
    
    if ($Data) {
        $properties.data = $Data
    }
    
    if ($ErrorMessage) {
        $properties.errorMessage = $ErrorMessage
    }
    
    $level = if ($Success) { [LogLevel]::Debug } else { [LogLevel]::Warning }
    $message = "$DependencyName call to $Target"
    
    Write-XDRLog -Level $level `
        -Message $message `
        -CorrelationId $CorrelationId `
        -Properties $properties
}

# ============================================================================
# PERFORMANCE METRICS
# ============================================================================

function New-XDRStopwatch {
    <#
    .SYNOPSIS
        Creates a stopwatch for performance tracking
    #>
    [CmdletBinding()]
    param()
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    return $stopwatch
}

function Get-XDRElapsedMs {
    <#
    .SYNOPSIS
        Gets elapsed milliseconds from stopwatch
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Stopwatch]$Stopwatch
    )
    
    return [Math]::Round($Stopwatch.Elapsed.TotalMilliseconds, 2)
}

function Write-XDRMetric {
    <#
    .SYNOPSIS
        Logs custom metrics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties
    )
    
    $metricProperties = @{
        eventType = "Metric"
        metricName = $MetricName
        value = $Value
    }
    
    if ($Properties) {
        $Properties.GetEnumerator() | ForEach-Object {
            $metricProperties[$_.Key] = $_.Value
        }
    }
    
    Write-XDRLog -Level ([LogLevel]::Information) `
        -Message "Metric: $MetricName = $Value" `
        -CorrelationId $CorrelationId `
        -Properties $metricProperties
    
    # Send to Application Insights if available
    if ($env:APPLICATIONINSIGHTS_CONNECTION_STRING) {
        Send-MetricToApplicationInsights -MetricName $MetricName -Value $Value -Properties $Properties
    }
}

# ============================================================================
# ERROR AND EXCEPTION LOGGING
# ============================================================================

function Write-XDRError {
    <#
    .SYNOPSIS
        Logs error with full context
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties
    )
    
    Write-XDRLog -Level ([LogLevel]::Error) `
        -Message $Message `
        -CorrelationId $CorrelationId `
        -TenantId $TenantId `
        -Service $Service `
        -Action $Action `
        -Properties $Properties `
        -Exception $Exception
}

# ============================================================================
# APPLICATION INSIGHTS INTEGRATION
# ============================================================================

function Send-ToApplicationInsights {
    <#
    .SYNOPSIS
        Sends telemetry to Application Insights
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$LogEntry,
        
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level
    )
    
    # This would integrate with Application Insights REST API or SDK
    # For now, logs are captured by Azure Functions built-in Application Insights integration
    # Future enhancement: Direct telemetry submission for custom dimensions
    
    # Example implementation would use:
    # - Application Insights Ingestion API
    # - Custom dimensions for service, action, tenantId
    # - Custom metrics for performance data
}

function Send-MetricToApplicationInsights {
    <#
    .SYNOPSIS
        Sends custom metric to Application Insights
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties
    )
    
    # Future enhancement: Direct metric submission to Application Insights
    # For now, metrics are logged and captured by Azure Functions integration
}

# ============================================================================
# EXPORT MODULE MEMBERS
# ============================================================================

Export-ModuleMember -Function @(
    'Write-XDRLog',
    'Write-XDRRequestLog',
    'Write-XDRResponseLog',
    'Write-XDRAuthLog',
    'Write-XDRDependencyLog',
    'Write-XDRMetric',
    'Write-XDRError',
    'New-XDRStopwatch',
    'Get-XDRElapsedMs'
)
