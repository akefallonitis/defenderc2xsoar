# Quick Action Plan - Path to 100% Coverage

**Goal**: Achieve 188/188 actions (100% XDR coverage)  
**Current**: 175/188 (93%)  
**Gap**: 13 actions  
**Timeline**: 4-5 days

---

## ✅ DONE (Today)

### Phase 1: MCAS Worker Routing (30 min) ✅
- [x] Added MCAS routing to Orchestrator (line 924-969)
- [x] Updated Gateway validation to include MCAS
- [x] Updated error messages with valid services list
- [x] **Result**: 15 MCAS actions now accessible via API

---

## 🔴 CRITICAL PATH TO 100%

### Step 1: Deploy Missing Permissions (2 hours) 🔴 BLOCKER

**Prerequisite for all remaining work**

**New Graph Permissions Needed**:
```json
// Add to Azure AD App Registration
{
  "resourceAppId": "00000003-0000-0000-c000-000000000000",
  "resourceAccess": [
    {
      "id": "...",
      "type": "Role",
      "value": "TenantAllowBlockList.ReadWrite.All"
    },
    {
      "id": "...",
      "type": "Role",
      "value": "eDiscovery.ReadWrite.All"
    },
    {
      "id": "...",
      "type": "Role",
      "value": "SecurityActions.ReadWrite.All"
    },
    {
      "id": "...",
      "type": "Role",
      "value": "DetectionRules.ReadWrite.All"
    }
  ]
}
```

**Deployment Script**:
```powershell
# Use existing deployment script
.\deployment\Apply-APIPermissions.ps1 -AppId <app-id> -TenantId <tenant-id>
```

**Update File**: `PERMISSIONS_COMPLETE.md` - Add new permissions to tracking doc

---

### Step 2: Implement 6 MDO Actions (8 hours) 🔴 HIGH

**File**: `functions/DefenderXDRMDOWorker/run.ps1`

**Actions to Add**:

#### 2.1 Tenant Allow/Block List (3 actions) - 3 hours

```powershell
"BLOCKSENDERDOMAIN" {
    $uri = "https://graph.microsoft.com/beta/security/collaboration/tenantAllowBlockList/senders"
    $body = @{
        value = $parameters.domain
        action = "Block"
        expirationDateTime = $parameters.expiryDate
        notes = "Blocked by XDR - CorrelationId: $correlationId"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "BlockSenderDomain"
        domain = $parameters.domain
        blockListEntryId = $response.id
    }
}

"BLOCKSPECIFICSENDER" {
    # Same API, scope to email address instead of domain
    $uri = "https://graph.microsoft.com/beta/security/collaboration/tenantAllowBlockList/senders"
    $body = @{
        value = $parameters.senderEmail
        action = "Block"
        expirationDateTime = $parameters.expiryDate
        notes = "Blocked specific sender - CorrelationId: $correlationId"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "BlockSpecificSender"
        sender = $parameters.senderEmail
        blockListEntryId = $response.id
    }
}

"BLOCKURLPATTERN" {
    $uri = "https://graph.microsoft.com/beta/security/collaboration/tenantAllowBlockList/urls"
    $body = @{
        value = $parameters.urlPattern
        action = "Block"
        expirationDateTime = $parameters.expiryDate
        notes = "Blocked URL - CorrelationId: $correlationId"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "BlockURLPattern"
        urlPattern = $parameters.urlPattern
        blockListEntryId = $response.id
    }
}
```

#### 2.2 Threat Submission (1 action) - 2 hours

```powershell
"SUBMITATTACHMENTTHREAT" {
    $uri = "https://graph.microsoft.com/v1.0/security/threatSubmission/emailAttachmentThreats"
    $body = @{
        "@odata.type" = "#microsoft.graph.security.emailAttachmentThreatSubmission"
        fileHash = $parameters.fileHash
        recipientEmailAddress = $parameters.recipientEmail
        messageId = $parameters.messageId
        category = "malware"  # or "phishing"
        submissionSource = "administrator"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "SubmitAttachmentThreat"
        submissionId = $response.id
        status = $response.status
    }
}
```

#### 2.3 eDiscovery (2 actions) - 3 hours

```powershell
"CREATEEDISCOVERYSEARCH" {
    $uri = "https://graph.microsoft.com/v1.0/security/cases/ediscoveryCases/$($parameters.caseId)/searches"
    $body = @{
        displayName = $parameters.searchName
        description = $parameters.description
        contentQuery = $parameters.kqlQuery
        dataSourceScopes = "allCaseSources"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "CreateeDiscoverySearch"
        searchId = $response.id
        searchName = $response.displayName
        status = $response.status
    }
}

"PURGESEARCHRESULTS" {
    $uri = "https://graph.microsoft.com/v1.0/security/cases/ediscoveryCases/$($parameters.caseId)/searches/$($parameters.searchId)/purgeData"
    $body = @{
        purgeType = $parameters.purgeType  # "softDelete" or "hardDelete"
        purgeAreas = "mailboxes"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "PurgeSearchResults"
        operationId = $response.id
        status = "initiated"
        message = "Purge operation started. This may take several minutes."
    }
}
```

**Insert Location**: After existing MDO actions in run.ps1 switch statement

**Testing Commands**:
```powershell
# Test BlockSenderDomain
Invoke-RestMethod -Uri "https://your-app.azurewebsites.net/api/Gateway" -Method Post -Body (@{
    service = "MDO"
    action = "BlockSenderDomain"
    tenantId = "your-tenant-id"
    domain = "malicious-domain.com"
    expiryDate = "2025-12-31T23:59:59Z"
} | ConvertTo-Json) -ContentType "application/json"
```

**Result**: 181/188 actions (96% coverage)

---

### Step 3: Create XDR Platform Worker (16 hours) 🔴 HIGH

**New Worker**: `functions/DefenderXDRPlatformWorker/`

#### 3.1 Create Function Structure (2 hours)

**File**: `functions/DefenderXDRPlatformWorker/function.json`
```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "Request",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "Response"
    }
  ]
}
```

**File**: `functions/DefenderXDRPlatformWorker/run.ps1` (skeleton)
```powershell
param($Request, $TriggerMetadata)

$modulePath = "$PSScriptRoot\..\modules\DefenderXDRIntegrationBridge"
Import-Module "$modulePath\AuthManager.psm1" -Force
Import-Module "$modulePath\ValidationHelper.psm1" -Force
Import-Module "$modulePath\LoggingHelper.psm1" -Force

$action = $Request.Query.action ?? $Request.Body.action
$parameters = $Request.Body
$correlationId = $Request.Body.correlationId ?? [guid]::NewGuid().ToString()

try {
    # Get Graph token
    $token = Get-OAuthToken -TenantId $parameters.tenantId -AppId $env:AppId -ClientSecret $env:ClientSecret -Service "Graph"
    $headers = @{
        Authorization = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    switch ($action.ToUpper()) {
        # Incident Management (4 actions) - 4 hours
        # Detection Rules (4 actions) - 4 hours
        # AIR Actions (4 actions) - 4 hours
        
        default {
            throw "Unknown XDR Platform action: $action"
        }
    }
    
    # Return success
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = @{
            success = $true
            action = $action
            result = $result
            correlationId = $correlationId
        } | ConvertTo-Json -Depth 10
    })
} catch {
    # Return error
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            success = $false
            error = $_.Exception.Message
            correlationId = $correlationId
        } | ConvertTo-Json
    })
}
```

#### 3.2 Implement Actions (12 hours)

**Incident Management** (4 actions - 4 hours):
- `MergeIncidents` - `POST /v1.0/security/incidents/{id}/merge`
- `LinkAlertToIncident` - `POST /v1.0/security/incidents/{id}/alerts/$ref`
- `SuppressAlert` - `PATCH /v1.0/security/alerts_v2/{id}`
- `CreateIncident` - `POST /v1.0/security/incidents`

**Detection Rules** (4 actions - 4 hours):
- `CreateDetectionRule` - `POST /beta/security/rules/detectionRules`
- `UpdateDetectionRule` - `PATCH /beta/security/rules/detectionRules/{id}`
- `EnableDisableDetectionRule` - `PATCH /beta/security/rules/detectionRules/{id}`
- `DeleteDetectionRule` - `DELETE /beta/security/rules/detectionRules/{id}`

**AIR Actions** (4 actions - 4 hours):
- `TriggerInvestigation` - `POST /beta/security/investigations`
- `ApproveAIRActions` - `POST /beta/security/investigations/{id}/actions/approve`
- `RejectAIRActions` - `POST /beta/security/investigations/{id}/actions/reject`
- `CancelInvestigation` - `POST /beta/security/investigations/{id}/cancel`

**Implementation Pattern** (example):
```powershell
"MERGEINCIDENTS" {
    $uri = "https://graph.microsoft.com/v1.0/security/incidents/$($parameters.sourceIncidentId)/merge"
    $body = @{
        targetIncidentId = $parameters.targetIncidentId
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    $result = @{
        success = $true
        action = "MergeIncidents"
        mergedIncidentId = $response.id
    }
}
```

#### 3.3 Add Orchestrator Routing (30 min)

**File**: `functions/DefenderXDROrchestrator/run.ps1`

**Add before default case**:
```powershell
# ====================================================================
# XDR PLATFORM (Cross-Service Actions)
# ====================================================================

"XDR" {
    Write-Host "[$correlationId] Routing to DefenderXDRPlatformWorker"
    
    # Get Graph OAuth token
    $tokenString = Get-OAuthToken -TenantId $tenantId -AppId $appId -ClientSecret $secretId -Service "Graph"
    
    if (-not $tokenString) {
        throw "Failed to acquire Graph authentication token for XDR Platform"
    }
    
    # Prepare request for XDR Platform Worker
    $workerRequest = @{
        tenantId = $tenantId
        action = $action
        parameters = $Request.Body
        correlationId = $correlationId
        token = $tokenString
    }
    
    # Call XDR Platform Worker
    $workerUrl = "https://$functionAppUrl/api/DefenderXDRPlatformWorker"
    $workerResponse = Invoke-RestMethod -Uri $workerUrl -Method Post -Body ($workerRequest | ConvertTo-Json -Depth 10) -ContentType "application/json"
    
    $result.data = $workerResponse
    $result.action = $action
}
```

**Update Gateway validation**:
```powershell
validServices = @("MDE", "MDO", "MDC", "MDI", "EntraID", "Intune", "Azure", "MCAS", "XDR")
```

#### 3.4 Testing (2 hours)

**Test Each Category**:
```powershell
# Test Incident Management
Invoke-RestMethod -Uri "https://your-app.azurewebsites.net/api/Gateway" -Method Post -Body (@{
    service = "XDR"
    action = "MergeIncidents"
    tenantId = "your-tenant-id"
    sourceIncidentId = "123"
    targetIncidentId = "456"
} | ConvertTo-Json) -ContentType "application/json"

# Test Detection Rules
Invoke-RestMethod -Uri "https://your-app.azurewebsites.net/api/Gateway" -Method Post -Body (@{
    service = "XDR"
    action = "CreateDetectionRule"
    tenantId = "your-tenant-id"
    ruleName = "Suspicious PowerShell Activity"
    kqlQuery = "DeviceProcessEvents | where ProcessCommandLine has 'Invoke-WebRequest'"
    severity = "high"
} | ConvertTo-Json) -ContentType "application/json"

# Test AIR Actions
Invoke-RestMethod -Uri "https://your-app.azurewebsites.net/api/Gateway" -Method Post -Body (@{
    service = "XDR"
    action = "TriggerInvestigation"
    tenantId = "your-tenant-id"
    entityId = "device-id-here"
    entityType = "device"
} | ConvertTo-Json) -ContentType "application/json"
```

**Result**: 188/188 actions (100% coverage) 🎯

---

## 🎯 COMPLETION CHECKLIST

### Phase 1 ✅ DONE
- [x] Add MCAS routing to Orchestrator
- [x] Update Gateway validation
- [x] Document changes

### Phase 2 ⏳ IN PROGRESS
- [ ] Deploy Graph permissions (TenantAllowBlockList, eDiscovery, SecurityActions, DetectionRules)
- [ ] Add BlockSenderDomain to MDO Worker
- [ ] Add BlockSpecificSender to MDO Worker
- [ ] Add BlockURLPattern to MDO Worker
- [ ] Add SubmitAttachmentThreat to MDO Worker
- [ ] Add CreateeDiscoverySearch to MDO Worker
- [ ] Add PurgeSearchResults to MDO Worker
- [ ] Test all 6 MDO actions
- [ ] Update documentation

### Phase 3 ⏳ PENDING
- [ ] Create DefenderXDRPlatformWorker folder structure
- [ ] Create function.json
- [ ] Create run.ps1 skeleton
- [ ] Implement 4 Incident Management actions
- [ ] Implement 4 Detection Rule actions
- [ ] Implement 4 AIR actions
- [ ] Add XDR routing to Orchestrator
- [ ] Update Gateway validation for XDR
- [ ] Test all 12 XDR actions
- [ ] Update documentation

### Phase 4 ⏳ OPTIONAL (Technical Debt)
- [ ] Audit Orchestrator for MDEAuth usage
- [ ] Remove MDEAuth import from Orchestrator
- [ ] Add deprecation warnings to MDEAuth
- [ ] Test MDE operations

---

## 📊 DAILY PROGRESS TRACKING

### Day 1 ✅ (Today)
- [x] Add MCAS routing (30 min)
- [x] Update Gateway (5 min)
- [x] Create consolidation docs (2 hours)
- **Status**: Phase 1 complete, 175/188 (93%)

### Day 2 📅 (Tomorrow)
- [ ] Deploy Graph permissions (2 hours)
- [ ] Implement 3 Tenant Block List actions (3 hours)
- [ ] Implement SubmitAttachmentThreat (2 hours)
- **Target**: 179/188 (95%)

### Day 3 📅
- [ ] Implement 2 eDiscovery actions (3 hours)
- [ ] Test all 6 MDO actions (2 hours)
- [ ] Create XDR Platform worker structure (2 hours)
- **Target**: 181/188 (96%)

### Day 4 📅
- [ ] Implement 4 Incident Management actions (4 hours)
- [ ] Implement 4 Detection Rule actions (4 hours)
- **Target**: 185/188 (98%)

### Day 5 📅
- [ ] Implement 4 AIR actions (4 hours)
- [ ] Add XDR routing to Orchestrator (30 min)
- [ ] Comprehensive testing (2 hours)
- **Target**: 188/188 (100%) 🎯✅

---

## 🚀 IMMEDIATE NEXT STEPS

1. **NOW**: Review this action plan
2. **TODAY**: Deploy Graph permissions (prerequisite for everything)
3. **TOMORROW**: Start implementing MDO actions (low-hanging fruit)
4. **THIS WEEK**: Complete XDR Platform Worker
5. **NEXT WEEK**: Celebrate 100% coverage milestone 🎉

---

**Timeline**: 5 days  
**Effort**: 28 hours  
**Outcome**: 100% XDR coverage (188 actions)

