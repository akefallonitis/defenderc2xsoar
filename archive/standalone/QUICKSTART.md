# Quick Start Guide - MDE Automator Local

Get up and running with the standalone MDE Automator in 10 minutes!

## Prerequisites Check

Before starting, ensure you have:

- [ ] **PowerShell 7.0+** installed ([Download](https://github.com/PowerShell/PowerShell/releases))
- [ ] **Azure AD Admin Access** to create app registrations
- [ ] **MDE Admin Permissions** to grant API permissions
- [ ] **Internet Connection** for API access

## Step 1: Create App Registration (5 minutes)

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App Registrations**
3. Click **+ New registration**
   
   ![image](https://user-images.githubusercontent.com/placeholder/app-reg-new.png)

4. Configure:
   - **Name**: `MDE-Automator-Local`
   - **Account types**: `Accounts in this organizational directory only`
   - Click **Register**

5. Copy the **Application (client) ID** and **Directory (tenant) ID** - you'll need these!

## Step 2: Create Client Secret (2 minutes)

1. In your app registration, go to **Certificates & secrets**
2. Click **+ New client secret**
3. Set description: `MDE Local Access`
4. Set expiration: Choose based on your policy (24 months recommended)
5. Click **Add**
6. **IMPORTANT**: Copy the secret **Value** immediately (you won't see it again!)

## Step 3: Configure API Permissions (5 minutes)

1. In your app registration, go to **API permissions**
2. Click **+ Add a permission**

### WindowsDefenderATP Permissions

3. Select **APIs my organization uses**
4. Search for and select **WindowsDefenderATP**
5. Select **Application permissions**
6. Add these permissions:
   - [x] `AdvancedQuery.Read.All`
   - [x] `Alert.Read.All`
   - [x] `Machine.Isolate`
   - [x] `Machine.ReadWrite.All`
   - [x] `Machine.Scan`
   - [x] `Machine.StopAndQuarantine`
   - [x] `Machine.RestrictExecution`
   - [x] `Machine.CollectForensics`
   - [x] `Ti.ReadWrite.All`
   - [x] `Library.Manage`

### Microsoft Graph Permissions

7. Click **+ Add a permission** again
8. Select **Microsoft Graph**
9. Select **Application permissions**
10. Add these permissions:
    - [x] `SecurityIncident.ReadWrite.All`
    - [x] `ThreatIndicators.ReadWrite.OwnedBy`

### Grant Admin Consent

11. Click **Grant admin consent for [Your Tenant]**
12. Confirm by clicking **Yes**
13. Verify all permissions show a green checkmark ✓

## Step 4: Download and Setup (2 minutes)

### Option A: Using Git

```powershell
# Clone the repository
git clone https://github.com/akefallonitis/defenderc2xsoar.git

# Navigate to standalone folder
cd defenderc2xsoar/standalone
```

### Option B: Manual Download

1. Download ZIP from [GitHub](https://github.com/akefallonitis/defenderc2xsoar/archive/main.zip)
2. Extract to a folder (e.g., `C:\Tools\MDEAutomator`)
3. Navigate to the `standalone` subfolder

## Step 5: First Launch (1 minute)

```powershell
# Start the framework
.\Start-MDEAutomatorLocal.ps1
```

On first run, you'll be prompted to enter:

```
Enter your Tenant ID: [paste your tenant ID]
Enter your Application (Client) ID: [paste your app ID]
Enter your Client Secret: [paste your secret]

Save configuration for future sessions? (Y/N): Y
```

The framework will:
1. Encrypt and save your credentials
2. Authenticate to Microsoft Defender
3. Display the main menu

## Step 6: Test Connection (1 minute)

Let's verify everything works:

1. From the main menu, select **2** (Device Actions)
2. Select **9** (List All Devices)
3. You should see a list of devices in your tenant!

**Success!** You're now ready to use the standalone MDE Automator.

## Quick Actions Guide

### Isolate a Device

```
Main Menu > 2 (Device Actions) > 1 (Isolate Device)
Enter Device ID: [device-id]
Enter reason: Security investigation
Isolation type: Full
```

### Add Threat Indicator

```
Main Menu > 3 (Threat Intelligence) > 1 (Add File Indicator)
Enter SHA256: [file-hash]
Enter title: Malware signature
Severity: High
Action: Block
```

### Run Hunting Query

```
Main Menu > 4 (Advanced Hunting) > 1 (Execute Custom Query)
Enter query: DeviceInfo | take 10
```

## Common Issues & Solutions

### ❌ "Authentication failed"

**Problem**: Cannot authenticate to MDE API

**Solution**:
1. Verify tenant ID, app ID, and secret are correct
2. Check client secret hasn't expired
3. Ensure admin consent is granted

### ❌ "Module not found"

**Problem**: PowerShell cannot load modules

**Solution**:
```powershell
# Ensure you're in the standalone directory
cd C:\path\to\standalone

# Check modules exist
dir modules
```

### ❌ "Permission denied"

**Problem**: Missing API permissions

**Solution**:
1. Go back to Step 3
2. Verify all required permissions are added
3. Ensure admin consent is granted (green checkmarks)

### ❌ "Device not found"

**Problem**: Invalid device ID

**Solution**:
1. List all devices first (Option 2 > 9)
2. Copy the exact device ID from the list
3. Use that ID in your operation

## Next Steps

Now that you're set up, explore these features:

- 📊 **Device Management**: Isolate, scan, and manage endpoints
- 🛡️ **Threat Intelligence**: Add and manage indicators
- 🔍 **Advanced Hunting**: Run custom KQL queries
- 📋 **Incident Response**: View and triage security incidents
- 💾 **Export Data**: Export results to CSV for analysis

## Additional Resources

- [Full README](README.md) - Complete documentation
- [Sample Queries](examples/sample-hunting-queries.kql) - Pre-built hunting queries
- [Main Project Docs](../README.md) - Azure-based version documentation
- [API Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api-overview) - Microsoft Defender API reference

## Getting Help

Having issues?

1. Review the [Troubleshooting](README.md#-troubleshooting) section
2. Check [existing issues](https://github.com/akefallonitis/defenderc2xsoar/issues)
3. Open a [new issue](https://github.com/akefallonitis/defenderc2xsoar/issues/new) with:
   - Error message
   - Steps to reproduce
   - PowerShell version (`$PSVersionTable.PSVersion`)

## Updating

To update to the latest version:

```powershell
cd defenderc2xsoar
git pull origin main

# Your configuration is preserved
cd standalone
.\Start-MDEAutomatorLocal.ps1
```

---

**🎉 Congratulations!** You're now ready to automate Microsoft Defender for Endpoint operations from your local machine!
