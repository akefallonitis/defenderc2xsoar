<#
.SYNOPSIS
    Validation and Sanitization Helper Module for XDR Orchestrator
    
.DESCRIPTION
    Provides comprehensive input validation and sanitization functions to ensure:
    - Data integrity and security
    - Prevention of injection attacks
    - Parameter format validation
    - Action authorization checks
    
.NOTES
    Version: 2.1.0
    Part of DefenderXDRC2XSOAR module
#>

# ============================================================================
# TENANT AND APP ID VALIDATION
# ============================================================================

function Test-TenantId {
    <#
    .SYNOPSIS
        Validates Azure AD tenant ID format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )
    
    # Check if it's a valid GUID
    try {
        [void][System.Guid]::Parse($TenantId)
        return $true
    } catch {
        Write-Warning "Invalid tenant ID format: $TenantId (must be a valid GUID)"
        return $false
    }
}

function Test-AppId {
    <#
    .SYNOPSIS
        Validates application (client) ID format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId
    )
    
    # Check if it's a valid GUID
    try {
        [void][System.Guid]::Parse($AppId)
        return $true
    } catch {
        Write-Warning "Invalid app ID format: $AppId (must be a valid GUID)"
        return $false
    }
}

# ============================================================================
# SERVICE AND ACTION VALIDATION
# ============================================================================

function Get-ValidServices {
    <#
    .SYNOPSIS
        Returns list of valid XDR services
    #>
    return @("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure")
}

function Test-ServiceName {
    <#
    .SYNOPSIS
        Validates service name against allowed list
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service
    )
    
    $validServices = Get-ValidServices
    
    if ($Service -in $validServices) {
        return $true
    } else {
        Write-Warning "Invalid service: $Service. Valid services: $($validServices -join ', ')"
        return $false
    }
}

function Get-ValidActionsForService {
    <#
    .SYNOPSIS
        Returns list of valid actions for a given service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure")]
        [string]$Service
    )
    
    $actionMap = @{
        MDE = @(
            "IsolateDevice", "UnisolateDevice", "RestrictAppExecution", "UnrestrictAppExecution",
            "RunAntivirusScan", "CollectInvestigationPackage", "StopAndQuarantineFile", "OffboardDevice",
            "GetDeviceInfo", "GetAllDevices", "GetMachineActionStatus", "GetAllMachineActions", "StopMachineAction",
            "StartAutomatedInvestigation", "AddFileIndicator", "RemoveFileIndicator", "AddIPIndicator", 
            "AddURLIndicator", "GetAllIndicators", "AdvancedHunt", "GetIncidents", "GetIncidentDetails",
            "UpdateIncident", "AddIncidentComment", "GetCustomDetections", "CreateCustomDetection",
            "UpdateCustomDetection", "DeleteCustomDetection", "StartLiveResponseSession", 
            "GetLiveResponseSession", "InvokeLiveResponseCommand", "GetLiveResponseCommandResult",
            "WaitLiveResponseCommand", "GetLiveResponseFile", "SendLiveResponseFile"
        )
        MDO = @(
            "RemediateEmail", "SubmitEmailThreat", "SubmitURLThreat", "RemoveMailForwardingRules"
        )
        MDC = @(
            "GetSecurityAlerts", "UpdateSecurityAlert", "GetRecommendations", "GetSecureScore",
            "GetRegulatoryCompliance", "EnableDefenderPlan", "GetDefenderPlans", "SetAutoProvisioning",
            "GetJitAccessPolicy", "CreateJitAccessRequest"
        )
        MDI = @(
            "GetAlerts", "UpdateAlert", "GetHealthIssues", "GetLateralMovementPaths",
            "GetIdentitySecureScore", "GetSuspiciousActivities", "GetExposedCredentials",
            "GetAccountEnumeration", "GetPrivilegeEscalation", "GetDomainControllerCoverage",
            "GetReconnaissanceActivities"
        )
        EntraID = @(
            "DisableUser", "EnableUser", "ResetPassword", "ConfirmCompromised", "DismissRisk",
            "RevokeSessions", "GetRiskDetections", "CreateNamedLocation", "UpdateNamedLocation",
            "CreateConditionalAccessPolicy", "CreateSignInRiskPolicy", "CreateUserRiskPolicy",
            "GetNamedLocations"
        )
        Intune = @(
            "RemoteLock", "WipeDevice", "RetireDevice", "SyncDevice", "DefenderScan",
            "GetManagedDevices"
        )
        Azure = @(
            "AddNSGDenyRule", "StopVM", "DisableStoragePublicAccess", "RemoveVMPublicIP", "GetVMs"
        )
    }
    
    return $actionMap[$Service]
}

function Test-ActionName {
    <#
    .SYNOPSIS
        Validates action name for a given service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $true)]
        [string]$Action
    )
    
    $validActions = Get-ValidActionsForService -Service $Service
    
    # Check exact match or wildcard match (for actions like AdvancedHunt*)
    $isValid = $validActions | Where-Object {
        $Action -eq $_ -or $Action -like "$_*"
    }
    
    if ($isValid) {
        return $true
    } else {
        Write-Warning "Invalid action '$Action' for service '$Service'. Valid actions: $($validActions -join ', ')"
        return $false
    }
}

# ============================================================================
# RESOURCE ID VALIDATION
# ============================================================================

function Test-MachineId {
    <#
    .SYNOPSIS
        Validates MDE machine/device ID format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineId
    )
    
    # MDE machine IDs are typically 40-character alphanumeric strings
    if ($MachineId -match '^[a-zA-Z0-9]{40}$') {
        return $true
    } else {
        Write-Warning "Invalid machine ID format: $MachineId"
        return $false
    }
}

function Test-SubscriptionId {
    <#
    .SYNOPSIS
        Validates Azure subscription ID format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    # Subscription IDs are GUIDs
    try {
        [void][System.Guid]::Parse($SubscriptionId)
        return $true
    } catch {
        Write-Warning "Invalid subscription ID format: $SubscriptionId (must be a valid GUID)"
        return $false
    }
}

function Test-UserId {
    <#
    .SYNOPSIS
        Validates user ID (can be GUID or UPN format)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId
    )
    
    # Check if GUID
    try {
        [void][System.Guid]::Parse($UserId)
        return $true
    } catch {
        # Check if UPN format (email)
        if ($UserId -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
            return $true
        } else {
            Write-Warning "Invalid user ID format: $UserId (must be GUID or UPN/email)"
            return $false
        }
    }
}

# ============================================================================
# INPUT SANITIZATION
# ============================================================================

function ConvertTo-SafeString {
    <#
    .SYNOPSIS
        Sanitizes string input to prevent injection attacks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$InputString,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLength = 1000
    )
    
    if ([string]::IsNullOrEmpty($InputString)) {
        return ""
    }
    
    # Limit length
    if ($InputString.Length -gt $MaxLength) {
        Write-Warning "Input string truncated from $($InputString.Length) to $MaxLength characters"
        $InputString = $InputString.Substring(0, $MaxLength)
    }
    
    # Remove potentially dangerous characters for script injection
    # Keep alphanumeric, spaces, common punctuation, but remove script delimiters
    $sanitized = $InputString -replace '[<>{}$`]', ''
    
    return $sanitized
}

function ConvertTo-SafeFileName {
    <#
    .SYNOPSIS
        Sanitizes file name to prevent path traversal attacks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    
    # Remove path traversal attempts
    $sanitized = $FileName -replace '\.\./|\.\.\\', ''
    
    # Remove invalid file name characters
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalidChars) {
        $sanitized = $sanitized -replace [regex]::Escape($char), ''
    }
    
    return $sanitized
}

function Test-IPAddress {
    <#
    .SYNOPSIS
        Validates IPv4 or IPv6 address format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )
    
    try {
        [void][System.Net.IPAddress]::Parse($IPAddress)
        return $true
    } catch {
        Write-Warning "Invalid IP address format: $IPAddress"
        return $false
    }
}

function Test-URL {
    <#
    .SYNOPSIS
        Validates URL format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$URL
    )
    
    try {
        $uri = [System.Uri]$URL
        if ($uri.IsAbsoluteUri -and ($uri.Scheme -eq "http" -or $uri.Scheme -eq "https")) {
            return $true
        } else {
            Write-Warning "Invalid URL format: $URL (must be http or https)"
            return $false
        }
    } catch {
        Write-Warning "Invalid URL format: $URL"
        return $false
    }
}

function Test-FileHash {
    <#
    .SYNOPSIS
        Validates file hash format (SHA256, SHA1, MD5)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hash,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SHA256", "SHA1", "MD5")]
        [string]$HashType = "SHA256"
    )
    
    $lengthMap = @{
        SHA256 = 64
        SHA1   = 40
        MD5    = 32
    }
    
    $expectedLength = $lengthMap[$HashType]
    
    if ($Hash.Length -eq $expectedLength -and $Hash -match '^[a-fA-F0-9]+$') {
        return $true
    } else {
        Write-Warning "Invalid $HashType hash format: $Hash (expected $expectedLength hex characters)"
        return $false
    }
}

# ============================================================================
# PARAMETER VALIDATION
# ============================================================================

function Test-RequiredParameters {
    <#
    .SYNOPSIS
        Validates that all required parameters are present for an action
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $true)]
        [string]$Action,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )
    
    # Define required parameters for each action
    $requiredParamsMap = @{
        "MDE:IsolateDevice" = @("deviceIds")
        "MDE:UnisolateDevice" = @("deviceIds")
        "MDE:RestrictAppExecution" = @("deviceIds")
        "MDE:UnrestrictAppExecution" = @("deviceIds")
        "MDE:RunAntivirusScan" = @("deviceIds")
        "MDE:CollectInvestigationPackage" = @("deviceIds")
        "MDE:StopAndQuarantineFile" = @("deviceIds", "fileHash")
        "MDE:GetDeviceInfo" = @("machineId")
        "MDE:AdvancedHunt" = @("query")
        "MDE:AddFileIndicator" = @("indicatorValue")
        "MDE:UpdateIncident" = @("incidentId")
        
        "MDO:RemediateEmail" = @("emailId")
        "MDO:SubmitEmailThreat" = @("emailId")
        "MDO:SubmitURLThreat" = @("url")
        "MDO:RemoveMailForwardingRules" = @("userId")
        
        "MDC:GetSecurityAlerts" = @("subscriptionId")
        "MDC:UpdateSecurityAlert" = @("subscriptionId", "alertId", "status")
        "MDC:EnableDefenderPlan" = @("subscriptionId", "defenderPlan")
        
        "MDI:UpdateAlert" = @("alertId", "status")
        
        "EntraID:DisableUser" = @("userId")
        "EntraID:EnableUser" = @("userId")
        "EntraID:ResetPassword" = @("userId")
        "EntraID:RevokeSessions" = @("userId")
        "EntraID:CreateNamedLocation" = @("locationName", "ipRanges")
        
        "Intune:RemoteLock" = @("deviceId")
        "Intune:WipeDevice" = @("deviceId")
        "Intune:RetireDevice" = @("deviceId")
        
        "Azure:AddNSGDenyRule" = @("subscriptionId", "resourceGroup", "nsgName", "sourceIP")
        "Azure:StopVM" = @("subscriptionId", "resourceGroup", "vmName")
        "Azure:DisableStoragePublicAccess" = @("subscriptionId", "resourceGroup", "storageAccountName")
    }
    
    $key = "${Service}:${Action}"
    $requiredParams = $requiredParamsMap[$key]
    
    if (-not $requiredParams) {
        # No specific requirements defined, assume valid
        return @{
            IsValid = $true
            MissingParams = @()
        }
    }
    
    $missingParams = @()
    foreach ($param in $requiredParams) {
        if (-not $Parameters.ContainsKey($param) -or [string]::IsNullOrWhiteSpace($Parameters[$param])) {
            $missingParams += $param
        }
    }
    
    return @{
        IsValid = ($missingParams.Count -eq 0)
        MissingParams = $missingParams
    }
}

# ============================================================================
# RATE LIMITING HELPERS
# ============================================================================

$script:RequestTracker = @{}

function Test-RateLimit {
    <#
    .SYNOPSIS
        Checks if rate limit is exceeded for tenant/service combination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRequestsPerMinute = 100
    )
    
    $key = "$TenantId|$Service"
    $now = Get-Date
    
    if (-not $script:RequestTracker.ContainsKey($key)) {
        $script:RequestTracker[$key] = @{
            Requests = @()
        }
    }
    
    # Remove requests older than 1 minute
    $script:RequestTracker[$key].Requests = $script:RequestTracker[$key].Requests | Where-Object {
        ($now - $_).TotalSeconds -lt 60
    }
    
    # Check if limit exceeded
    if ($script:RequestTracker[$key].Requests.Count -ge $MaxRequestsPerMinute) {
        Write-Warning "Rate limit exceeded for tenant $TenantId, service $Service ($($script:RequestTracker[$key].Requests.Count) requests in last minute)"
        return $false
    }
    
    # Add current request
    $script:RequestTracker[$key].Requests += $now
    
    return $true
}

function Clear-RateLimitTracker {
    <#
    .SYNOPSIS
        Clears rate limit tracking data
    #>
    [CmdletBinding()]
    param()
    
    $script:RequestTracker = @{}
    Write-Host "Rate limit tracker cleared"
}

# ============================================================================
# EXPORT MODULE MEMBERS
# ============================================================================

Export-ModuleMember -Function @(
    'Test-TenantId',
    'Test-AppId',
    'Get-ValidServices',
    'Test-ServiceName',
    'Get-ValidActionsForService',
    'Test-ActionName',
    'Test-MachineId',
    'Test-SubscriptionId',
    'Test-UserId',
    'ConvertTo-SafeString',
    'ConvertTo-SafeFileName',
    'Test-IPAddress',
    'Test-URL',
    'Test-FileHash',
    'Test-RequiredParameters',
    'Test-RateLimit',
    'Clear-RateLimitTracker'
)
