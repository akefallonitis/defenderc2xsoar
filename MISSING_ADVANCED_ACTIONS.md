# Missing Advanced Security Actions - Deep Dive Analysis

**Research Date**: November 13, 2025  
**Scope**: Advanced security actions across Microsoft APIs  

---

## 1. File Detonation & Sandboxing

### ❌ MISSING: Deep File Analysis

**Microsoft Defender for Office 365 - Safe Attachments Detonation**

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **DetonateFile** | `/beta/security/collaboration/files/{id}/detonate` | ⚠️ **MISSING** | **HIGH** |
| **GetDetonationReport** | `/beta/security/collaboration/files/{id}/detonationReport` | ⚠️ **MISSING** | **HIGH** |
| **DetonateURL** | `/beta/security/collaboration/urls/{id}/detonate` | ⚠️ **MISSING** | **HIGH** |

**Use Case**: 
- Submit suspicious files/URLs to Microsoft Defender sandbox
- Get detailed malware analysis reports
- Automated threat intelligence enrichment

**Implementation**:
```powershell
"DETONATEFILE" {
    # Submit file to Microsoft Defender sandbox for analysis
    $fileHash = $body.fileHash  # SHA256
    
    $detonationBody = @{
        "@odata.type" = "#microsoft.graph.security.fileDetonation"
        fileIdentifier = @{
            fileHash = $fileHash
            hashAlgorithm = "sha256"
        }
        priority = "high"
        analysisDepth = "deep"  # quick, normal, deep
    } | ConvertTo-Json
    
    $uri = "$graphBase/beta/security/collaboration/fileDetonations"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $detonationBody
    
    $result = @{
        detonationId = $response.id
        status = $response.status  # queued, analyzing, completed
        fileHash = $fileHash
    }
}
```

---

## 2. Azure Defender for Cloud (MDC) Advanced Actions

### ⚠️ PARTIALLY MISSING: Azure Security Center Operations

**Currently Have**:
- ✅ NSG rules (AddNSGDenyRule)
- ✅ VM operations (StopVM, RemoveVMPublicIP)
- ✅ Azure Firewall (BlockIPInFirewall, BlockDomainInFirewall)

**Missing**:

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **DismissSecurityAlert** | `/subscriptions/{id}/providers/Microsoft.Security/alerts/{id}/dismiss` | ⚠️ **MISSING** | **MEDIUM** |
| **ActivateSecurityAlert** | `/subscriptions/{id}/providers/Microsoft.Security/alerts/{id}/activate` | ⚠️ **MISSING** | **MEDIUM** |
| **ResolveSecurityAlert** | `/subscriptions/{id}/providers/Microsoft.Security/alerts/{id}/resolve` | ⚠️ **MISSING** | **MEDIUM** |
| **GetSecurityRecommendations** | `/subscriptions/{id}/providers/Microsoft.Security/assessments` | ⚠️ **MISSING** | LOW (read-only) |
| **ApplySecurityRecommendation** | `/subscriptions/{id}/providers/Microsoft.Security/assessments/{id}/remediate` | ⚠️ **MISSING** | **MEDIUM** |
| **EnableJITAccess** | `/subscriptions/{id}/providers/Microsoft.Security/jitNetworkAccessPolicies` | ⚠️ **MISSING** | MEDIUM |

**Implementation**:
```powershell
"DISMISSSECURITYALERT" {
    # Dismiss Azure Defender for Cloud alert
    $alertId = $body.alertId
    $subscriptionId = $body.subscriptionId
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/alerts/$alertId/dismiss?api-version=2022-01-01"
    
    $dismissBody = @{
        properties = @{
            state = "Dismissed"
            comment = $body.comment
        }
    } | ConvertTo-Json
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $dismissBody
}
```

---

## 3. Azure Arc Security Actions

### ❌ MISSING: Hybrid/Multi-Cloud Security

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **IsolateArcServer** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.HybridCompute/machines/{id}/isolate` | ⚠️ **MISSING** | **HIGH** |
| **RunArcCommand** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.HybridCompute/machines/{id}/runCommand` | ⚠️ **MISSING** | **HIGH** |
| **EnableDefenderArc** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.HybridCompute/machines/{id}/extensions/MDE` | ⚠️ **MISSING** | MEDIUM |
| **DisconnectArcServer** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.HybridCompute/machines/{id}/disconnect` | ⚠️ **MISSING** | MEDIUM |

**Use Case**:
- Isolate compromised on-premises/AWS/GCP servers
- Run remediation scripts on hybrid infrastructure
- Manage Defender for Servers on Arc-enabled machines

**Implementation**:
```powershell
"ISOLATEARCSERVER" {
    # Isolate Azure Arc-enabled server (similar to MDE isolation)
    $arcMachineName = $body.machineName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.HybridCompute/machines/$arcMachineName/isolate?api-version=2023-10-03"
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    $isolationBody = @{
        properties = @{
            isolationType = "Full"  # Full, Selective
            comment = $body.comment
        }
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $isolationBody
}
```

---

## 4. Storage Account Security

### ⚠️ PARTIALLY MISSING: Advanced Storage Security

**Currently Have**:
- ✅ DisableStoragePublicAccess

**Missing**:

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **RotateStorageAccountKeys** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}/regenerateKey` | ⚠️ **MISSING** | **HIGH** |
| **EnableStorageDefender** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}/defenderSettings` | ⚠️ **MISSING** | MEDIUM |
| **RevokeStorageSAS** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}/revokeUserDelegationKeys` | ⚠️ **MISSING** | **HIGH** |
| **EnableStorageFirewall** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}/firewallRules` | ⚠️ **MISSING** | **MEDIUM** |
| **DisableStorageSoftDelete** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}/blobServices/default` | ⚠️ **MISSING** | LOW |

**Implementation**:
```powershell
"ROTATESTORAGEKEYS" {
    # Rotate storage account access keys (post-compromise)
    $storageAccountName = $body.storageAccountName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    $keyName = if ($body.keyName) { $body.keyName } else { "key1" }
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/regenerateKey?api-version=2023-01-01"
    
    $keyBody = @{
        keyName = $keyName  # key1, key2
    } | ConvertTo-Json
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $keyBody
    
    $result = @{
        storageAccountName = $storageAccountName
        keyName = $keyName
        rotated = $true
        newKey = $response.keys[0].value  # Careful with logging!
    }
}

"REVOKESTORAGESAS" {
    # Revoke all SAS tokens for storage account
    $storageAccountName = $body.storageAccountName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/revokeUserDelegationKeys?api-version=2023-01-01"
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
    
    $result = @{
        storageAccountName = $storageAccountName
        sasTokensRevoked = $true
    }
}
```

---

## 5. Azure SQL Database Security

### ❌ MISSING: Database Security Actions

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **DisableSQLPublicAccess** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{name}/firewallRules/{id}` | ⚠️ **MISSING** | **HIGH** |
| **EnableSQLAudit** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{name}/auditingSettings/default` | ⚠️ **MISSING** | MEDIUM |
| **RotateSQLPassword** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{name}/administrators/ActiveDirectory` | ⚠️ **MISSING** | **HIGH** |
| **EnableSQLTDE** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{name}/databases/{db}/transparentDataEncryption` | ⚠️ **MISSING** | MEDIUM |
| **BlockSQLIP** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{name}/firewallRules/{ruleName}` | ⚠️ **MISSING** | **HIGH** |

**Implementation**:
```powershell
"BLOCKSQLIP" {
    # Block IP address from Azure SQL firewall
    $sqlServerName = $body.sqlServerName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    $ipAddress = $body.ipAddress
    $ruleName = "Block-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Sql/servers/$sqlServerName/firewallRules/$ruleName?api-version=2021-11-01"
    
    $ruleBody = @{
        properties = @{
            startIpAddress = $ipAddress
            endIpAddress = $ipAddress
        }
    } | ConvertTo-Json
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $ruleBody
}

"DISABLESQLPUBLICACCESS" {
    # Disable public network access to Azure SQL
    $sqlServerName = $body.sqlServerName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Sql/servers/$sqlServerName?api-version=2021-11-01"
    
    $updateBody = @{
        properties = @{
            publicNetworkAccess = "Disabled"
        }
    } | ConvertTo-Json
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $updateBody
}
```

---

## 6. Azure Application Gateway / WAF Actions

### ❌ MISSING: Web Application Firewall Security

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **BlockIPInWAF** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/{name}` | ⚠️ **MISSING** | **HIGH** |
| **AddWAFCustomRule** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/{name}/customRules` | ⚠️ **MISSING** | **HIGH** |
| **EnableWAFPreventionMode** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/applicationGateways/{name}/webApplicationFirewallConfiguration` | ⚠️ **MISSING** | MEDIUM |
| **BlockGeoLocationWAF** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/{name}/geoLocationRules` | ⚠️ **MISSING** | MEDIUM |

**Implementation**:
```powershell
"BLOCKIPINWAF" {
    # Block IP in Azure Application Gateway WAF
    $wafPolicyName = $body.wafPolicyName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    $ipAddress = $body.ipAddress
    $ruleName = "BlockIP-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    # Get current WAF policy
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$wafPolicyName?api-version=2023-05-01"
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    $policy = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    
    # Add custom rule
    $customRule = @{
        name = $ruleName
        priority = 100
        ruleType = "MatchRule"
        action = "Block"
        matchConditions = @(
            @{
                matchVariables = @(@{ variableName = "RemoteAddr" })
                operator = "IPMatch"
                matchValues = @($ipAddress)
            }
        )
    }
    
    $policy.properties.customRules += $customRule
    
    $updateBody = $policy | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $updateBody
}
```

---

## 7. Cosmos DB Security

### ❌ MISSING: NoSQL Database Security

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **DisableCosmosPublicAccess** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.DocumentDB/databaseAccounts/{name}` | ⚠️ **MISSING** | **HIGH** |
| **RotateCosmosKeys** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.DocumentDB/databaseAccounts/{name}/regenerateKey` | ⚠️ **MISSING** | **HIGH** |
| **EnableCosmosFirewall** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.DocumentDB/databaseAccounts/{name}/ipRules` | ⚠️ **MISSING** | **MEDIUM** |
| **RevokeCosmosResourceToken** | Cosmos DB SDK | ⚠️ **MISSING** | MEDIUM |

**Implementation**:
```powershell
"ROTATECOSMOSKEYS" {
    # Rotate Cosmos DB keys
    $cosmosAccountName = $body.cosmosAccountName
    $resourceGroup = $body.resourceGroup
    $subscriptionId = $body.subscriptionId
    $keyKind = if ($body.keyKind) { $body.keyKind } else { "primary" }
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosAccountName/regenerateKey?api-version=2023-04-15"
    
    $keyBody = @{
        keyKind = $keyKind  # primary, secondary, primaryReadonly, secondaryReadonly
    } | ConvertTo-Json
    
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
    $headers = @{ "Authorization" = "Bearer $($token.Token)" }
    
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $keyBody
}
```

---

## 8. Azure App Service Security

### ❌ MISSING: PaaS Security Actions

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **DisableAppServicePublicAccess** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{name}/config/web` | ⚠️ **MISSING** | **HIGH** |
| **RestartAppService** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{name}/restart` | ⚠️ **MISSING** | MEDIUM |
| **EnableAppServiceManagedIdentity** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{name}` | ⚠️ **MISSING** | MEDIUM |
| **RotateAppServiceSecrets** | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{name}/config/appsettings` | ⚠️ **MISSING** | **HIGH** |

---

## 9. Advanced Email Actions

### ⚠️ PARTIALLY MISSING: Quarantine Management

**Currently Have**:
- ✅ MoveToJunk (proxy for quarantine)
- ✅ ZAPPhishing / ZAPMalware

**Missing**:

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **QuarantineMessage** | `/beta/security/collaboration/quarantine/messages` | ⚠️ **MISSING** | **MEDIUM** |
| **ReleaseFromQuarantine** | `/beta/security/collaboration/quarantine/messages/{id}/release` | ⚠️ **MISSING** | **MEDIUM** |
| **GetQuarantinedMessages** | `/beta/security/collaboration/quarantine/messages` | ⚠️ **MISSING** | LOW (read) |
| **BulkReleaseQuarantine** | `/beta/security/collaboration/quarantine/messages/bulkRelease` | ⚠️ **MISSING** | MEDIUM |

**Note**: We use `MoveToJunk` as a proxy, but native quarantine API provides better tracking and admin controls.

---

## 10. Advanced Threat Protection

### ❌ MISSING: Proactive Threat Actions

| Action | API | Status | Priority |
|--------|-----|--------|----------|
| **CreateThreatIntelIndicator** | `/beta/security/tiIndicators` | ⚠️ **MISSING** | **MEDIUM** |
| **ExpiresThreatIntelIndicator** | `/beta/security/tiIndicators/{id}/expire` | ⚠️ **MISSING** | MEDIUM |
| **BulkUploadTIIndicators** | `/beta/security/tiIndicators/uploadIndicators` | ⚠️ **MISSING** | **MEDIUM** |

**Note**: We have MDE IoC management (AddIndicator, RemoveIndicator), but Graph Security API threat intel is broader (works across all M365 services).

---

## Summary: Priority Recommendations

### 🔥 HIGH Priority (Add in v3.2.0)

1. **RotateStorageAccountKeys** - Post-compromise key rotation
2. **RevokeStorageSAS** - Revoke SAS tokens
3. **BlockSQLIP** - Block malicious IPs from Azure SQL
4. **DisableSQLPublicAccess** - Disable public SQL access
5. **BlockIPInWAF** - Block IPs in Application Gateway WAF
6. **IsolateArcServer** - Isolate hybrid servers
7. **RotateCosmosKeys** - Cosmos DB key rotation
8. **DisableCosmosPublicAccess** - Disable Cosmos public access
9. **DetonateFile** - File sandbox analysis
10. **DismissSecurityAlert** - Manage Azure Defender alerts

### ⚠️ MEDIUM Priority (Consider for v3.3.0)

1. **ApplySecurityRecommendation** - Auto-remediate Azure Defender findings
2. **QuarantineMessage** - Native email quarantine
3. **ReleaseFromQuarantine** - Release quarantined emails
4. **AddWAFCustomRule** - Custom WAF rules
5. **RunArcCommand** - Execute commands on Arc servers
6. **RotateAppServiceSecrets** - App Service secret rotation
7. **CreateThreatIntelIndicator** - Graph-level threat intel

### ⬇️ LOW Priority (Optional)

1. **EnableJITAccess** - Just-In-Time VM access
2. **GetQuarantinedMessages** - Read-only
3. **GetSecurityRecommendations** - Read-only

---

## Estimated Implementation Effort

| Category | Actions | Effort | Total Hours |
|----------|---------|--------|-------------|
| **Storage Security** | 4 | 2 hours each | 8 hours |
| **Azure SQL** | 3 | 2 hours each | 6 hours |
| **WAF Security** | 2 | 3 hours each | 6 hours |
| **Cosmos DB** | 3 | 2 hours each | 6 hours |
| **Azure Arc** | 2 | 3 hours each | 6 hours |
| **File Detonation** | 3 | 4 hours each | 12 hours |
| **MDC Alerts** | 3 | 2 hours each | 6 hours |
| **Email Quarantine** | 2 | 2 hours each | 4 hours |
| **App Service** | 2 | 2 hours each | 4 hours |
| **Threat Intel** | 3 | 2 hours each | 6 hours |
| **TOTAL** | **27 actions** | **~64 hours** | **~2 weeks** |

---

## Conclusion

DefenderC2 v3.0.1 has excellent coverage of **core AIR actions**, but is **missing advanced infrastructure security** actions:

- ✅ **MDE/MDO/Entra ID/MCAS**: Comprehensive AIR coverage
- ⚠️ **Azure Infrastructure**: Basic coverage (NSG, Firewall, VM) - **missing PaaS security**
- ❌ **Azure Arc**: Not implemented
- ❌ **Database Security**: Not implemented (SQL, Cosmos)
- ❌ **WAF**: Not implemented
- ❌ **Storage Advanced**: Missing key rotation, SAS revocation
- ❌ **File Detonation**: Not implemented

**Recommendation**: Add **10 HIGH-priority actions** in v3.2.0 for comprehensive infrastructure security.
