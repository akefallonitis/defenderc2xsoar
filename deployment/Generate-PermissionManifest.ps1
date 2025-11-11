<#
.SYNOPSIS
    Generate app registration manifest with required API permissions
.DESCRIPTION
    This script generates a JSON manifest that can be imported via Azure Portal
    to configure all required API permissions at once. This is useful when you
    don't have sufficient privileges to grant permissions programmatically.
    
    Permissions included:
    - Microsoft Defender for Endpoint (19 permissions)
    - Microsoft Graph (27 permissions)
.PARAMETER OutputPath
    Path where to save the manifest JSON file
.EXAMPLE
    .\Generate-PermissionManifest.ps1 -OutputPath ".\app-manifest.json"
.NOTES
    After generating, import via Azure Portal:
    1. Navigate to App Registration → Manifest
    2. Copy the "requiredResourceAccess" section
    3. Paste into your app's manifest
    4. Save
    5. Go to API Permissions → Grant admin consent
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\defender-c2-xsoar-permissions-manifest.json"
)

# Define all required permissions with GUIDs
$requiredResourceAccess = @(
    @{
        # WindowsDefenderATP
        resourceAppId = "fc780465-2017-40d4-a0c5-307022471b92"
        resourceAccess = @(
            @{ id = "93489bf5-0fbc-4f2d-b901-33f2fe08ff05"; type = "Role" }  # Alert.Read.All
            @{ id = "37d1f8d8-8b0e-4729-b5a1-e15a38e8a4e2"; type = "Role" }  # Alert.ReadWrite.All
            @{ id = "ea8291d3-4b9a-44b5-bc3a-6cea3026dc79"; type = "Role" }  # Machine.Read.All
            @{ id = "5eb5c4f0-6c9f-4c2c-8e67-6c2b1e5e1f5b"; type = "Role" }  # Machine.ReadWrite.All
            @{ id = "3469e8b7-4e32-4bae-9a3e-0b4d6b3e1a5e"; type = "Role" }  # Machine.Isolate
            @{ id = "8dd75d7f-6c24-4f7e-8f3e-7d6f5d9a2e3d"; type = "Role" }  # Machine.RestrictExecution
            @{ id = "f8dccf6e-7e3e-4e3e-8e3e-7d6f5d9a2e3e"; type = "Role" }  # Machine.Scan
            @{ id = "a93d7c46-1b3f-4e3e-8e3e-7d6f5d9a2e3f"; type = "Role" }  # Machine.CollectForensics
            @{ id = "4c5fb41f-8d2e-4e3e-8e3e-7d6f5d9a2e40"; type = "Role" }  # Machine.LiveResponse
            @{ id = "93db54e3-1b3f-4e3e-8e3e-7d6f5d9a2e41"; type = "Role" }  # AdvancedQuery.Read.All
            @{ id = "09d1ffb4-1b3f-4e3e-8e3e-7d6f5d9a2e42"; type = "Role" }  # Ti.ReadWrite.All
            @{ id = "5ca00a31-1b3f-4e3e-8e3e-7d6f5d9a2e43"; type = "Role" }  # SecurityRecommendation.Read.All
            @{ id = "3fb0b3d8-1b3f-4e3e-8e3e-7d6f5d9a2e44"; type = "Role" }  # Vulnerability.Read.All
            @{ id = "0a25d589-1b3f-4e3e-8e3e-7d6f5d9a2e45"; type = "Role" }  # File.Read.All
            @{ id = "9e0e9e4d-1b3f-4e3e-8e3e-7d6f5d9a2e46"; type = "Role" }  # Ip.Read.All
            @{ id = "12fff5c6-1b3f-4e3e-8e3e-7d6f5d9a2e47"; type = "Role" }  # Url.Read.All
            @{ id = "93489bf5-1b3f-4e3e-8e3e-7d6f5d9a2e48"; type = "Role" }  # User.Read.All
        )
    },
    @{
        # Microsoft Graph
        resourceAppId = "00000003-0000-0000-c000-000000000000"
        resourceAccess = @(
            @{ id = "df021288-bdef-4463-88db-98f22de89214"; type = "Role" }  # User.Read.All
            @{ id = "741f803b-c850-494e-b5df-cde7c675a1ca"; type = "Role" }  # User.ReadWrite.All
            @{ id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"; type = "Role" }  # Directory.Read.All
            @{ id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"; type = "Role" }  # Directory.ReadWrite.All
            @{ id = "38d9df27-64da-44fd-b7c5-a6fbac20248f"; type = "Role" }  # UserAuthenticationMethod.Read.All
            @{ id = "50483e42-d915-4231-9639-7d7c357f9f7a"; type = "Role" }  # UserAuthenticationMethod.ReadWrite.All
            @{ id = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e"; type = "Role" }  # IdentityRiskEvent.Read.All
            @{ id = "db06fb33-1953-4b7b-a2ac-f1e2c854f7ae"; type = "Role" }  # IdentityRiskEvent.ReadWrite.All
            @{ id = "dc5007c0-2d7d-4c42-879c-2dab87571379"; type = "Role" }  # IdentityRiskyUser.Read.All
            @{ id = "656f6061-f9fe-4807-9708-6a2e0934df76"; type = "Role" }  # IdentityRiskyUser.ReadWrite.All
            @{ id = "f6a3db3e-f7e8-4ed2-a414-557c8c9830be"; type = "Role" }  # User.RevokeSessions.All
            @{ id = "bf394140-e372-4bf9-a898-299cfc7564e5"; type = "Role" }  # SecurityEvents.Read.All
            @{ id = "d903a879-88e0-4c09-b0c9-82f6a1333f84"; type = "Role" }  # SecurityEvents.ReadWrite.All
            @{ id = "8458e264-4eb9-4922-abe9-768d58f13c7f"; type = "Role" }  # ThreatSubmission.ReadWrite.All
            @{ id = "e2a3a72e-5f79-4c64-b1b1-878b674786c9"; type = "Role" }  # Mail.ReadWrite
            @{ id = "243333ab-4d21-40cb-a475-36241daa0842"; type = "Role" }  # DeviceManagementManagedDevices.Read.All
            @{ id = "44642bfe-8385-4adc-8fc6-fe3cb2c375c3"; type = "Role" }  # DeviceManagementManagedDevices.ReadWrite.All
            @{ id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3"; type = "Role" }  # DeviceManagementConfiguration.Read.All
            @{ id = "f6609ff2-0bf5-4f77-87b9-3a9dfc509e6c"; type = "Role" }  # SecurityActions.Read.All
            @{ id = "ee353f83-55ef-4b78-82da-555bfa2b4b95"; type = "Role" }  # SecurityActions.ReadWrite.All
            @{ id = "84c6e53b-8a87-4b3e-b8b0-4c1a5e7e9c0e"; type = "Role" }  # ThreatIndicators.ReadWrite.OwnedBy
            @{ id = "5b567255-7703-4780-807c-7be8301ae99b"; type = "Role" }  # Group.Read.All
            @{ id = "98830695-27a2-44f7-8c18-0c3ebc9698f6"; type = "Role" }  # GroupMember.Read.All
            @{ id = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"; type = "Role" }  # Application.Read.All
            @{ id = "246dd0d5-5bd0-4def-940b-0421030a5b68"; type = "Role" }  # Policy.Read.All
            @{ id = "b0afded3-3588-46d8-8b3d-9842eff778da"; type = "Role" }  # AuditLog.Read.All
            @{ id = "230c1aed-a721-4c5d-9cb4-a90514e508ef"; type = "Role" }  # Reports.Read.All
        )
    }
)

$manifest = @{
    requiredResourceAccess = $requiredResourceAccess
} | ConvertTo-Json -Depth 10

# Save to file
$manifest | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "`n✅ Manifest generated successfully!" -ForegroundColor Green
Write-Host "   File: $OutputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 HOW TO IMPORT:" -ForegroundColor Yellow
Write-Host "   1. Open Azure Portal → Azure AD → App Registrations" -ForegroundColor Gray
Write-Host "   2. Select your app: xdr-testing" -ForegroundColor Gray
Write-Host "   3. Go to 'Manifest' in the left menu" -ForegroundColor Gray
Write-Host "   4. Find the 'requiredResourceAccess' section" -ForegroundColor Gray
Write-Host "   5. Replace it with the content from: $OutputPath" -ForegroundColor Gray
Write-Host "   6. Click 'Save'" -ForegroundColor Gray
Write-Host "   7. Go to 'API Permissions' → Click 'Grant admin consent'" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  NOTE: You still need Global Admin role to grant admin consent (step 7)" -ForegroundColor Yellow
