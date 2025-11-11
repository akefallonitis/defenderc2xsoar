using namespace System.Net

<#
.SYNOPSIS
    Unified XDR Orchestrator - Single Entry Point for All Microsoft Security Operations
    
.DESCRIPTION
    Master orchestration function routing security actions across all Microsoft XDR services:
    - MDE (Microsoft Defender for Endpoint) - Endpoint security operations
    - MDO (Microsoft Defender for Office 365) - Email security operations  
    - MDC (Microsoft Defender for Cloud) - Cloud security operations
    - MDI (Microsoft Defender for Identity) - Identity threat detection
    - EntraID - Identity and access management
    - Intune - Device management operations
    - Azure - Infrastructure security operations
    
    This function provides a single, unified API endpoint for all XDR operations with:
    - Multi-tenant support via tenant ID in payload
    - Centralized authentication with token caching
    - Structured error handling and logging
    - Correlation ID tracking for distributed tracing
    - Comprehensive validation and sanitization
    
.PARAMETER service
    The Microsoft security service to target (MDE, MDO, MDC, MDI, EntraID, Intune, Azure)
    
.PARAMETER action  
    The specific action to execute within the service
    
.PARAMETER tenantId
    Azure AD tenant ID for multi-tenant operations
    
.EXAMPLE
    POST /api/XDROrchestrator
    {
        "service": "MDE",
        "action": "IsolateDevice", 
        "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "deviceIds": "machineId1,machineId2",
        "comment": "Isolating compromised devices"
    }
    
.EXAMPLE
    POST /api/XDROrchestrator
    {
        "service": "EntraID",
        "action": "RevokeUserSessions",
        "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", 
        "userId": "user@domain.com"
    }
    
.NOTES
    Version: 2.1.0
    Replaces individual function endpoints with unified orchestration
#>

param($Request, $TriggerMetadata)

# Import shared modules
$modulePath = "$PSScriptRoot\..\modules\DefenderXDRIntegrationBridge"

# Load core dependencies first (required by all modules)
try {
    Import-Module "$modulePath\AuthManager.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\ValidationHelper.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\LoggingHelper.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\MDEAuth.psm1" -Force -ErrorAction Stop  # Critical MDE dependency
    Write-Host "✅ Core modules loaded successfully"
} catch {
    Write-Error "❌ CRITICAL: Failed to load core module - $($_.Exception.Message)"
    throw
}

# Import MDE modules for device operations
try {
    Import-Module "$modulePath\MDEDevice.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\MDEHunting.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\MDEIncident.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\MDEThreatIntel.psm1" -Force -ErrorAction Stop
    Import-Module "$modulePath\MDEDetection.psm1" -Force -ErrorAction Stop
    Write-Host "✅ MDE modules loaded successfully"
} catch {
    Write-Warning "⚠️  MDE module load failed: $($_.Exception.Message)"
}

# Import other service modules
Import-Module "$modulePath\MDOEmailRemediation.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulePath\EntraIDIdentity.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulePath\IntuneDeviceManagement.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulePath\DefenderForCloud.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulePath\DefenderForIdentity.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulePath\AzureInfrastructure.psm1" -Force -ErrorAction SilentlyContinue

# Generate correlation ID for request tracking
$correlationId = [guid]::NewGuid().ToString()
$startTime = Get-Date

Write-Host "[$correlationId] XDROrchestrator processing request"

# ============================================================================
# PARAMETER EXTRACTION
# ============================================================================

# Core routing parameters
$service = $Request.Query.service ?? $Request.Body.service
$action = $Request.Query.action ?? $Request.Body.action
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId

# Get app credentials from environment variables
$appId = $env:APPID
$secretId = $env:SECRETID

# ============================================================================
# VALIDATION
# ============================================================================

if (-not $tenantId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $service
            action = $action
            error = @{
                code = "MISSING_TENANT_ID"
                message = "Missing required parameter: tenantId"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

if (-not $service) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $null
            action = $action
            tenantId = $tenantId
            error = @{
                code = "MISSING_SERVICE"
                message = "Missing required parameter: service. Valid values: MDE, MDO, MDC, MDI, EntraID, Intune, Azure"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

if (-not $action) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $service
            action = $null
            tenantId = $tenantId
            error = @{
                code = "MISSING_ACTION"
                message = "Missing required parameter: action"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

if (-not $appId -or -not $secretId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $service
            action = $action
            tenantId = $tenantId
            error = @{
                code = "MISSING_CREDENTIALS"
                message = "Function app not configured: APPID and SECRETID environment variables required"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

# Validate service parameter
$validServices = @("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure")
if ($service -notin $validServices) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $service
            action = $action
            tenantId = $tenantId
            error = @{
                code = "INVALID_SERVICE"
                message = "Invalid service: $service. Valid values: $($validServices -join ', ')"
            }
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json
    })
    return
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

try {
    Write-Host "[$correlationId] Routing request - Service: $service, Action: $action, Tenant: $tenantId"
    
    # Initialize result structure
    $result = @{
        success = $true
        correlationId = $correlationId
        service = $service
        action = $action
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        data = @{}
    }
    
    # ========================================================================
    # WORKER ROUTING - v3.0.0 Architecture
    # ========================================================================
    # Route requests to specialized Worker functions for processing
    # Workers handle authentication, action execution, and response formatting
    # ========================================================================
    
    $functionAppUrl = $env:WEBSITE_HOSTNAME
    
    switch ($service.ToUpper()) {
        
        # ====================================================================
        # MICROSOFT DEFENDER FOR ENDPOINT (MDE)
        # ====================================================================
        
        "MDE" {
            Write-Host "[$correlationId] Routing to DefenderXDRMDEWorker"
            
            # Get MDE OAuth token
            Write-Host "[$correlationId] Acquiring MDE token for tenant: $tenantId"
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "MDE"
            
            if (-not $tokenString) {
                throw "Failed to acquire MDE authentication token"
            }
            
            # Create token object in format expected by modules
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Prepare request for MDE Worker
            $workerRequest = @{
                tenantId = $tenantId
                action = $action
                parameters = $Request.Body
                correlationId = $correlationId
            }
            
            # Extract MDE-specific parameters
            $deviceIds = $Request.Query.deviceIds ?? $Request.Body.deviceIds
            $machineId = $Request.Query.machineId ?? $Request.Body.machineId
            $comment = $Request.Query.comment ?? $Request.Body.comment
            $isolationType = $Request.Query.isolationType ?? $Request.Body.isolationType
            $scanType = $Request.Query.scanType ?? $Request.Body.scanType
            $fileHash = $Request.Query.fileHash ?? $Request.Body.fileHash
            $actionId = $Request.Query.actionId ?? $Request.Body.actionId
            $indicatorValue = $Request.Query.indicatorValue ?? $Request.Body.indicatorValue
            $title = $Request.Query.title ?? $Request.Body.title
            $severity = $Request.Query.severity ?? $Request.Body.severity
            $query = $Request.Query.query ?? $Request.Body.query
            $huntQuery = $Request.Query.huntQuery ?? $Request.Body.huntQuery
            $incidentId = $Request.Query.incidentId ?? $Request.Body.incidentId
            $filter = $Request.Query.filter ?? $Request.Body.filter
            
            # Parse device IDs
            $deviceIdList = if ($deviceIds) {
                if ($deviceIds -is [string]) {
                    $deviceIds.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                } else { $deviceIds }
            } else { @() }
            
            # Route to appropriate MDE function
            switch -Wildcard ($action) {
                "IsolateDevice" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $commentText = if ($comment) { $comment } else { "Isolated via XDROrchestrator" }
                    $isoType = if ($isolationType) { $isolationType } else { "Full" }
                    $responses = Invoke-DeviceIsolation -Token $token -DeviceIds $deviceIdList -Comment $commentText -IsolationType $isoType
                    $result.data = @{
                        message = "Device isolation initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "UnisolateDevice" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $commentText = if ($comment) { $comment } else { "Unisolated via XDROrchestrator" }
                    $responses = Invoke-DeviceUnisolation -Token $token -DeviceIds $deviceIdList -Comment $commentText
                    $result.data = @{
                        message = "Device unisolation initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "RestrictAppExecution" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $commentText = if ($comment) { $comment } else { "App execution restricted via XDROrchestrator" }
                    $responses = Invoke-RestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
                    $result.data = @{
                        message = "App execution restriction initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "UnrestrictAppExecution" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $commentText = if ($comment) { $comment } else { "App execution unrestricted via XDROrchestrator" }
                    $responses = Invoke-UnrestrictAppExecution -Token $token -DeviceIds $deviceIdList -Comment $commentText
                    $result.data = @{
                        message = "App execution unrestriction initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "RunAntivirusScan" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $scan = if ($scanType) { $scanType } else { "Quick" }
                    $commentText = if ($comment) { $comment } else { "$scan scan via XDROrchestrator" }
                    $responses = Invoke-AntivirusScan -Token $token -DeviceIds $deviceIdList -ScanType $scan -Comment $commentText
                    $result.data = @{
                        message = "$scan antivirus scan initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "CollectInvestigationPackage" {
                    if ($deviceIdList.Count -eq 0) { throw "Device IDs required" }
                    $commentText = if ($comment) { $comment } else { "Investigation package via XDROrchestrator" }
                    $responses = Invoke-CollectInvestigationPackage -Token $token -DeviceIds $deviceIdList -Comment $commentText
                    $result.data = @{
                        message = "Investigation package collection initiated"
                        deviceCount = $deviceIdList.Count
                        actionIds = $responses | ForEach-Object { $_.id }
                    }
                }
                "GetDeviceInfo" {
                    if (-not $machineId) { throw "Machine ID required" }
                    $deviceInfo = Get-DeviceInfo -Token $token -MachineId $machineId
                    $result.data = @{ device = $deviceInfo }
                }
                "GetAllDevices" {
                    $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                    $devices = Get-AllDevices -Token $token @filterParam
                    $result.data = @{ count = $devices.Count; devices = $devices | Select-Object -First 1000 }
                }
                "AdvancedHunt*" {
                    $queryToExecute = if ($huntQuery) { $huntQuery } elseif ($query) { $query } else { throw "Query required" }
                    $huntResults = Invoke-AdvancedHunting -Token $token -Query $queryToExecute
                    $result.data = @{
                        resultCount = $huntResults.Count
                        query = $queryToExecute
                        results = $huntResults | Select-Object -First 1000
                    }
                }
                "GetIncident*" {
                    if ($incidentId) {
                        $incident = Get-SecurityIncidents -Token $token -Filter "id eq '$incidentId'"
                        $result.data = @{ incident = if ($incident) { $incident[0] } else { $null } }
                    } else {
                        $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                        $incidents = Get-SecurityIncidents -Token $token @filterParam
                        $result.data = @{ count = $incidents.Count; incidents = $incidents | Select-Object -First 100 }
                    }
                }
                "AddFileIndicator" {
                    if (-not $indicatorValue) { throw "File hash required" }
                    $indicatorTitle = if ($title) { $title } else { "Indicator via XDROrchestrator" }
                    $indicatorSeverity = if ($severity) { $severity } else { "Medium" }
                    $response = Add-FileIndicator -Token $token -Sha256 $indicatorValue -Title $indicatorTitle -Severity $indicatorSeverity
                    $result.data = @{ indicatorId = $response.id; indicator = $indicatorValue }
                }
                "GetAllIndicators" {
                    $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                    $indicators = Get-AllIndicators -Token $token @filterParam
                    $result.data = @{ count = $indicators.Count; indicators = $indicators | Select-Object -First 1000 }
                }
                default {
                    throw "Unknown MDE action: $action"
                }
            }
        }
        
        # ====================================================================
        # MICROSOFT DEFENDER FOR OFFICE 365 (MDO)
        # ====================================================================
        
        "MDO" {
            Write-Host "[$correlationId] Processing MDO action: $action"
            
            # Authenticate to Graph API for MDO operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract MDO-specific parameters
            $emailId = $Request.Query.emailId ?? $Request.Body.emailId
            $recipient = $Request.Query.recipient ?? $Request.Body.recipient
            $sender = $Request.Query.sender ?? $Request.Body.sender
            $subject = $Request.Query.subject ?? $Request.Body.subject
            $url = $Request.Query.url ?? $Request.Body.url
            $userId = $Request.Query.userId ?? $Request.Body.userId
            
            switch -Wildcard ($action) {
                "RemediateEmail*" {
                    if (-not $emailId -and -not $recipient) { throw "Email ID or recipient required" }
                    $response = Invoke-EmailRemediation -Token $token -MessageId $emailId -Recipients $recipient
                    $result.data = @{ message = "Email remediation initiated"; response = $response }
                }
                "SubmitEmailThreat" {
                    if (-not $emailId) { throw "Email ID required" }
                    $response = Submit-EmailThreat -Token $token -MessageId $emailId
                    $result.data = @{ message = "Email submitted for threat analysis"; response = $response }
                }
                "SubmitURLThreat" {
                    if (-not $url) { throw "URL required" }
                    $response = Submit-URLThreat -Token $token -URL $url
                    $result.data = @{ message = "URL submitted for threat analysis"; url = $url; response = $response }
                }
                "RemoveMailForwardingRules" {
                    if (-not $userId) { throw "User ID required" }
                    $response = Remove-MailForwardingRules -Token $token -UserId $userId
                    $result.data = @{ message = "Mail forwarding rules removed"; userId = $userId; response = $response }
                }
                default {
                    throw "Unknown MDO action: $action"
                }
            }
        }
        
        # ====================================================================
        # MICROSOFT DEFENDER FOR CLOUD (MDC)
        # ====================================================================
        
        "MDC" {
            Write-Host "[$correlationId] Processing MDC action: $action"
            
            # Authenticate to Azure RM for MDC operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Azure"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract MDC-specific parameters
            $subscriptionId = $Request.Query.subscriptionId ?? $Request.Body.subscriptionId
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            $status = $Request.Query.status ?? $Request.Body.status
            $filter = $Request.Query.filter ?? $Request.Body.filter
            $defenderPlan = $Request.Query.defenderPlan ?? $Request.Body.defenderPlan
            
            if (-not $subscriptionId) { throw "Subscription ID required for MDC operations" }
            
            switch -Wildcard ($action) {
                "GetSecurityAlerts" {
                    $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                    $alerts = Get-MDCSecurityAlerts -Token $token -SubscriptionId $subscriptionId @filterParam
                    $result.data = @{ count = $alerts.Count; alerts = $alerts | Select-Object -First 100 }
                }
                "UpdateSecurityAlert" {
                    if (-not $alertId -or -not $status) { throw "Alert ID and status required" }
                    $response = Update-MDCSecurityAlert -Token $token -SubscriptionId $subscriptionId -AlertId $alertId -Status $status
                    $result.data = @{ message = "Alert status updated"; alertId = $alertId; status = $status; response = $response }
                }
                "GetRecommendations" {
                    $recommendations = Get-MDCSecurityRecommendations -Token $token -SubscriptionId $subscriptionId
                    $result.data = @{ count = $recommendations.Count; recommendations = $recommendations | Select-Object -First 100 }
                }
                "GetSecureScore" {
                    $secureScore = Get-MDCSecureScore -Token $token -SubscriptionId $subscriptionId
                    $result.data = @{ secureScore = $secureScore }
                }
                "EnableDefenderPlan" {
                    if (-not $defenderPlan) { throw "Defender plan name required" }
                    $response = Enable-MDCDefenderPlan -Token $token -SubscriptionId $subscriptionId -PlanName $defenderPlan
                    $result.data = @{ message = "Defender plan enabled"; plan = $defenderPlan; response = $response }
                }
                "GetDefenderPlans" {
                    $plans = Get-MDCDefenderPlans -Token $token -SubscriptionId $subscriptionId
                    $result.data = @{ plans = $plans }
                }
                default {
                    throw "Unknown MDC action: $action"
                }
            }
        }
        
        # ====================================================================
        # MICROSOFT DEFENDER FOR IDENTITY (MDI)
        # ====================================================================
        
        "MDI" {
            Write-Host "[$correlationId] Processing MDI action: $action"
            
            # Authenticate to Graph API for MDI operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract MDI-specific parameters
            $alertId = $Request.Query.alertId ?? $Request.Body.alertId
            $status = $Request.Query.status ?? $Request.Body.status
            $filter = $Request.Query.filter ?? $Request.Body.filter
            
            switch -Wildcard ($action) {
                "GetAlerts" {
                    $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                    $alerts = Get-MDIAlerts -Token $token @filterParam
                    $result.data = @{ count = $alerts.Count; alerts = $alerts | Select-Object -First 100 }
                }
                "UpdateAlert" {
                    if (-not $alertId -or -not $status) { throw "Alert ID and status required" }
                    $response = Update-MDIAlert -Token $token -AlertId $alertId -Status $status
                    $result.data = @{ message = "Alert updated"; alertId = $alertId; status = $status; response = $response }
                }
                "GetLateralMovementPaths" {
                    $paths = Get-MDILateralMovementPaths -Token $token
                    $result.data = @{ count = $paths.Count; paths = $paths }
                }
                "GetExposedCredentials" {
                    $credentials = Get-MDIExposedCredentials -Token $token
                    $result.data = @{ count = $credentials.Count; credentials = $credentials }
                }
                "GetIdentitySecureScore" {
                    $secureScore = Get-MDIIdentitySecureScore -Token $token
                    $result.data = @{ secureScore = $secureScore }
                }
                default {
                    throw "Unknown MDI action: $action"
                }
            }
        }
        
        # ====================================================================
        # ENTRA ID (IDENTITY & ACCESS MANAGEMENT)
        # ====================================================================
        
        "ENTRAID" {
            Write-Host "[$correlationId] Processing Entra ID action: $action"
            
            # Authenticate to Graph API for Entra ID operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract Entra ID-specific parameters
            $userId = $Request.Query.userId ?? $Request.Body.userId
            $accountEnabled = $Request.Query.accountEnabled ?? $Request.Body.accountEnabled
            $newPassword = $Request.Query.newPassword ?? $Request.Body.newPassword
            $locationName = $Request.Query.locationName ?? $Request.Body.locationName
            $ipRanges = $Request.Query.ipRanges ?? $Request.Body.ipRanges
            
            if (-not $userId -and $action -notlike "*Location*" -and $action -notlike "*Policy*") {
                throw "User ID required for this action"
            }
            
            switch -Wildcard ($action) {
                "DisableUser*" {
                    $response = Set-UserAccountStatus -Token $token -UserId $userId -AccountEnabled $false
                    $result.data = @{ message = "User account disabled"; userId = $userId; response = $response }
                }
                "EnableUser*" {
                    $response = Set-UserAccountStatus -Token $token -UserId $userId -AccountEnabled $true
                    $result.data = @{ message = "User account enabled"; userId = $userId; response = $response }
                }
                "ResetPassword" {
                    $password = if ($newPassword) { $newPassword } else { [System.Web.Security.Membership]::GeneratePassword(16, 4) }
                    $response = Reset-UserPassword -Token $token -UserId $userId -NewPassword $password
                    $result.data = @{ message = "Password reset"; userId = $userId; newPassword = $password }
                }
                "ConfirmCompromised" {
                    $response = Confirm-UserCompromised -Token $token -UserId $userId
                    $result.data = @{ message = "User confirmed as compromised"; userId = $userId; response = $response }
                }
                "DismissRisk" {
                    $response = Dismiss-UserRisk -Token $token -UserId $userId
                    $result.data = @{ message = "User risk dismissed"; userId = $userId; response = $response }
                }
                "RevokeSessions" {
                    $response = Revoke-UserSessions -Token $token -UserId $userId
                    $result.data = @{ message = "User sessions revoked"; userId = $userId; response = $response }
                }
                "GetRiskDetections" {
                    $detections = Get-UserRiskDetections -Token $token -UserId $userId
                    $result.data = @{ count = $detections.Count; riskDetections = $detections }
                }
                "CreateNamedLocation" {
                    if (-not $locationName -or -not $ipRanges) { throw "Location name and IP ranges required" }
                    $response = New-NamedLocation -Token $token -LocationName $locationName -IPRanges $ipRanges
                    $result.data = @{ message = "Named location created"; location = $locationName; response = $response }
                }
                default {
                    throw "Unknown Entra ID action: $action"
                }
            }
        }
        
        # ====================================================================
        # INTUNE (DEVICE MANAGEMENT)
        # ====================================================================
        
        "INTUNE" {
            Write-Host "[$correlationId] Processing Intune action: $action"
            
            # Authenticate to Graph API for Intune operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract Intune-specific parameters
            $deviceId = $Request.Query.deviceId ?? $Request.Body.deviceId
            $filter = $Request.Query.filter ?? $Request.Body.filter
            
            if (-not $deviceId -and $action -notlike "Get*") {
                throw "Device ID required for this action"
            }
            
            switch -Wildcard ($action) {
                "RemoteLock" {
                    $response = Invoke-IntuneDeviceRemoteLock -Token $token -DeviceId $deviceId
                    $result.data = @{ message = "Device remote lock initiated"; deviceId = $deviceId; response = $response }
                }
                "WipeDevice" {
                    $response = Invoke-IntuneDeviceWipe -Token $token -DeviceId $deviceId
                    $result.data = @{ message = "Device wipe initiated"; deviceId = $deviceId; response = $response; warning = "All data will be erased" }
                }
                "RetireDevice" {
                    $response = Invoke-IntuneDeviceRetire -Token $token -DeviceId $deviceId
                    $result.data = @{ message = "Device retirement initiated"; deviceId = $deviceId; response = $response }
                }
                "SyncDevice" {
                    $response = Sync-IntuneDevice -Token $token -DeviceId $deviceId
                    $result.data = @{ message = "Device sync initiated"; deviceId = $deviceId; response = $response }
                }
                "DefenderScan" {
                    $response = Invoke-IntuneDefenderScan -Token $token -DeviceId $deviceId
                    $result.data = @{ message = "Defender scan initiated"; deviceId = $deviceId; response = $response }
                }
                "GetManagedDevices" {
                    $filterParam = if ($filter) { @{ Filter = $filter } } else { @{} }
                    $devices = Get-IntuneManagedDevices -Token $token @filterParam
                    $result.data = @{ count = $devices.Count; devices = $devices | Select-Object -First 1000 }
                }
                default {
                    throw "Unknown Intune action: $action"
                }
            }
        }
        
        # ====================================================================
        # AZURE (INFRASTRUCTURE SECURITY)
        # ====================================================================
        
        "AZURE" {
            Write-Host "[$correlationId] Processing Azure action: $action"
            
            # Authenticate to Azure RM for infrastructure operations
            $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Azure"
            $token = @{
                AccessToken = $tokenString
                TokenType = "Bearer"
                ExpiresIn = 3600
                ExpiresAt = (Get-Date).AddHours(1)
                TenantId = $tenantId
            }
            
            # Extract Azure-specific parameters
            $subscriptionId = $Request.Query.subscriptionId ?? $Request.Body.subscriptionId
            $resourceGroup = $Request.Query.resourceGroup ?? $Request.Body.resourceGroup
            $nsgName = $Request.Query.nsgName ?? $Request.Body.nsgName
            $vmName = $Request.Query.vmName ?? $Request.Body.vmName
            $storageAccountName = $Request.Query.storageAccountName ?? $Request.Body.storageAccountName
            $sourceIP = $Request.Query.sourceIP ?? $Request.Body.sourceIP
            
            if (-not $subscriptionId) { throw "Subscription ID required for Azure operations" }
            if (-not $resourceGroup) { throw "Resource group required for Azure operations" }
            
            switch -Wildcard ($action) {
                "AddNSGDenyRule" {
                    if (-not $nsgName -or -not $sourceIP) { throw "NSG name and source IP required" }
                    $response = Add-NSGDenyRule -Token $token -SubscriptionId $subscriptionId -ResourceGroup $resourceGroup -NSGName $nsgName -SourceIP $sourceIP
                    $result.data = @{ message = "NSG deny rule added"; nsg = $nsgName; sourceIP = $sourceIP; response = $response }
                }
                "StopVM" {
                    if (-not $vmName) { throw "VM name required" }
                    $response = Stop-AzureVM -Token $token -SubscriptionId $subscriptionId -ResourceGroup $resourceGroup -VMName $vmName
                    $result.data = @{ message = "VM stop initiated"; vm = $vmName; response = $response }
                }
                "DisableStoragePublicAccess" {
                    if (-not $storageAccountName) { throw "Storage account name required" }
                    $response = Disable-StorageAccountPublicAccess -Token $token -SubscriptionId $subscriptionId -ResourceGroup $resourceGroup -StorageAccountName $storageAccountName
                    $result.data = @{ message = "Storage public access disabled"; storageAccount = $storageAccountName; response = $response }
                }
                "RemoveVMPublicIP" {
                    if (-not $vmName) { throw "VM name required" }
                    $response = Remove-VMPublicIP -Token $token -SubscriptionId $subscriptionId -ResourceGroup $resourceGroup -VMName $vmName
                    $result.data = @{ message = "VM public IP removed"; vm = $vmName; response = $response }
                }
                "GetVMs" {
                    $vms = Get-AzureVMs -Token $token -SubscriptionId $subscriptionId -ResourceGroup $resourceGroup
                    $result.data = @{ count = $vms.Count; vms = $vms }
                }
                default {
                    throw "Unknown Azure action: $action"
                }
            }
        }
        
        # ====================================================================
        # DEFAULT / UNKNOWN SERVICE
        # ====================================================================
        
        default {
            throw "Unknown service: $service"
        }
    }
    
    # Calculate execution duration
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    $result.durationMs = [Math]::Round($duration, 2)
    
    Write-Host "[$correlationId] Request completed successfully in $($result.durationMs)ms"
    
    # Return success response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 10
    })
    
} catch {
    # Calculate execution duration
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Error "[$correlationId] Error processing request: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    
    # Return error response with structured format
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            correlationId = $correlationId
            service = $service
            action = $action
            tenantId = $tenantId
            error = @{
                code = "XDR_ORCHESTRATION_FAILED"
                message = $_.Exception.Message
                details = $_.ScriptStackTrace
            }
            durationMs = [Math]::Round($duration, 2)
            timestamp = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
    })
}
