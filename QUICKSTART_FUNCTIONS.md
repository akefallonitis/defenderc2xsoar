# Quick Start Guide - Azure Functions

This guide helps you quickly get started with the defenderc2xsoar Azure Functions.

## 🚀 Quick Deployment (15 minutes)

### Prerequisites
- Azure subscription
- Azure AD tenant with Microsoft Defender for Endpoint
- App Registration with MDE API permissions (see below)
- Azure CLI or PowerShell with Az module

### Step 1: Create App Registration (5 minutes)

1. **Navigate to Azure AD** > App Registrations > New Registration
   - Name: `MDE-Automator-App`
   - Supported account types: Single tenant
   - Click **Register**

2. **Create Client Secret**
   - Go to Certificates & secrets
   - New client secret
   - Description: `Azure Function Secret`
   - Expires: Choose appropriate duration
   - **Copy the secret value** (you won't see it again!)

3. **Note App IDs**
   - Copy **Application (client) ID**
   - Copy **Directory (tenant) ID**

4. **Add API Permissions**
   - API permissions > Add a permission
   - Microsoft APIs > Microsoft Threat Protection
   - Application permissions > Select all:
     - `Machine.Isolate`
     - `Machine.RestrictExecution`
     - `Machine.Scan`
     - `Machine.CollectForensics`
     - `Machine.StopAndQuarantine`
     - `Machine.Read.All`
     - `Machine.ReadWrite.All`
     - `Ti.ReadWrite.All`
     - `AdvancedQuery.Read.All`
   - Also add Microsoft Graph permissions:
     - `SecurityIncident.Read.All`
     - `SecurityIncident.ReadWrite.All`
   - Click **Grant admin consent**

### Step 2: Deploy Function App (5 minutes)

**Option A: Azure Portal**
1. Create new Function App
   - Runtime: PowerShell 7.2
   - Region: Choose closest
   - Plan: Consumption or Premium
2. After creation, go to Configuration
3. Add Application Settings:
   - `APPID`: Your Application (client) ID
   - `SECRETID`: Your client secret value

**Option B: Azure CLI**
```bash
# Variables
RESOURCE_GROUP="rg-mde-automator"
LOCATION="eastus"
FUNCTION_APP_NAME="mde-automator-func-${RANDOM}"
STORAGE_ACCOUNT="mdestorage${RANDOM}"
APP_ID="your-app-id"
SECRET_ID="your-secret-value"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create function app
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_ACCOUNT \
  --runtime powershell \
  --runtime-version 7.2 \
  --functions-version 4 \
  --consumption-plan-location $LOCATION

# Configure app settings
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "APPID=$APP_ID" "SECRETID=$SECRET_ID"
```

### Step 3: Deploy Code (5 minutes)

**Option A: VS Code**
1. Install Azure Functions extension
2. Open `functions` folder
3. Right-click > Deploy to Function App
4. Select your function app
5. Wait for deployment to complete

**Option B: Azure Functions Core Tools**
```bash
cd functions
func azure functionapp publish <your-function-app-name>
```

**Option C: Zip Deploy**
```bash
cd functions
zip -r functions.zip .
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --src functions.zip
```

### Step 4: Test Functions

Get your function URL:
```bash
az functionapp function show \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --function-name MDEDispatcher \
  --query "invokeUrlTemplate" -o tsv
```

Test with curl:
```bash
curl -X POST "https://<your-function-app>.azurewebsites.net/api/MDEDispatcher" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "Get Devices",
    "tenantId": "your-tenant-id"
  }'
```

---

## 🎯 Common Use Cases

### Use Case 1: Isolate High-Risk Devices

```powershell
$baseUrl = "https://your-function-app.azurewebsites.net/api"
$tenantId = "your-tenant-id"

# Get high-risk devices
$getDevices = @{
    action = "Get Devices"
    tenantId = $tenantId
    deviceFilter = "riskScore eq 'High'"
} | ConvertTo-Json

$devices = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEDispatcher" -Body $getDevices -ContentType "application/json"

# Isolate each high-risk device
foreach ($device in $devices.devices) {
    $isolate = @{
        action = "Isolate Device"
        tenantId = $tenantId
        deviceIds = $device.id
    } | ConvertTo-Json
    
    $result = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEDispatcher" -Body $isolate -ContentType "application/json"
    Write-Host "Isolated device: $($device.computerDnsName)"
}
```

### Use Case 2: Block Malicious File Hashes

```powershell
# Read hashes from file
$hashes = Get-Content "malicious_hashes.txt"

# Add as indicators
$addIndicators = @{
    action = "Add File Indicators"
    tenantId = $tenantId
    indicators = ($hashes -join ",")
    title = "Malware Campaign X"
    severity = "High"
    recommendedAction = "Block"
} | ConvertTo-Json

$result = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDETIManager" -Body $addIndicators -ContentType "application/json"
Write-Host "Added $($result.responses.Count) indicators"
```

### Use Case 3: Hunt for Suspicious Activity

```powershell
# Define KQL query
$query = @"
DeviceProcessEvents
| where Timestamp > ago(24h)
| where ProcessCommandLine has_any ("powershell", "cmd")
| where ProcessCommandLine has_any ("-enc", "-e", "IEX", "downloadstring")
| project Timestamp, DeviceName, AccountName, FileName, ProcessCommandLine
| take 100
"@

# Execute hunt
$hunt = @{
    tenantId = $tenantId
    huntQuery = $query
    huntName = "Suspicious PowerShell Activity"
} | ConvertTo-Json

$results = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEHuntManager" -Body $hunt -ContentType "application/json"
Write-Host "Found $($results.resultCount) suspicious events"
$results.results | Format-Table
```

### Use Case 4: Incident Response Workflow

```powershell
# Get active high-severity incidents
$getIncidents = @{
    action = "GetIncidents"
    tenantId = $tenantId
    severity = "High"
    status = "Active"
} | ConvertTo-Json

$incidents = Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEIncidentManager" -Body $getIncidents -ContentType "application/json"

# Process each incident
foreach ($incident in $incidents.incidents) {
    Write-Host "Processing incident: $($incident.displayName)"
    
    # Update incident to InProgress
    $update = @{
        action = "UpdateIncident"
        tenantId = $tenantId
        incidentId = $incident.id
        status = "InProgress"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Method Post -Uri "$baseUrl/MDEIncidentManager" -Body $update -ContentType "application/json"
}
```

---

## 🔍 Monitoring & Troubleshooting

### View Logs
```bash
# Stream logs in real-time
az webapp log tail --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME

# View logs in portal
# Navigate to Function App > Monitor > Logs
```

### Common Issues

**Issue: 401 Unauthorized**
- Verify APPID and SECRETID are correct
- Check API permissions are granted
- Verify admin consent was given

**Issue: 403 Forbidden**
- Check API permissions include required scopes
- Verify app registration has admin consent
- Ensure tenant ID is correct

**Issue: Function Not Found**
- Verify code was deployed successfully
- Check function.json files are present
- Restart function app

**Issue: Timeout**
- Long queries may timeout with Consumption plan
- Consider Premium plan for longer timeouts
- Implement pagination for large result sets

### Enable Application Insights

```bash
# Create Application Insights
APP_INSIGHTS="mde-app-insights"
az monitor app-insights component create \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --query "instrumentationKey" -o tsv)

# Configure function app
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```

---

## 📊 Performance Tips

### Optimize Queries
- Use filters to limit result sets
- Take advantage of OData filters
- Implement pagination for large datasets

### Batch Operations
- Use bulk indicator operations
- Process devices in parallel where possible
- Consider async patterns for long operations

### Caching
- Cache device lists if querying frequently
- Store hunt results for later analysis
- Use Azure Storage for large datasets

---

## 🔐 Security Best Practices

1. **Rotate Secrets Regularly**
   - Set expiration on client secrets
   - Update SECRETID in function app settings
   - Document rotation schedule

2. **Use Key Vault** (Recommended)
   - Store secrets in Azure Key Vault
   - Reference in function app: `@Microsoft.KeyVault(SecretUri=...)`
   - Enable managed identity

3. **Restrict Access**
   - Use function authentication keys
   - Configure CORS if needed
   - Implement IP restrictions

4. **Audit Logging**
   - Enable Application Insights
   - Log all operations
   - Monitor for suspicious activity

---

## 📚 Next Steps

1. **Workbook Integration**
   - Deploy workbook templates
   - Configure workbook parameters
   - Test end-to-end workflows

2. **Automation**
   - Create Logic Apps for scheduled hunts
   - Set up automated incident response
   - Implement alert-based actions

3. **Advanced Features**
   - Add Azure Storage integration
   - Implement result caching
   - Create custom dashboards

---

## 🆘 Support

### Documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [FUNCTIONS_REFERENCE.md](FUNCTIONS_REFERENCE.md) - API reference
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Implementation details
- [functions/MDEAutomator/README.md](functions/MDEAutomator/README.md) - Module docs

### Resources
- [Microsoft Defender API Docs](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/apis-intro)
- [Azure Functions PowerShell Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [GitHub Issues](https://github.com/akefallonitis/defenderc2xsoar/issues)

### Getting Help
1. Check function logs in Application Insights
2. Verify configuration (APPID, SECRETID, permissions)
3. Test with curl/PowerShell before workbook
4. Review API rate limits
5. Open GitHub issue with logs and details

---

## ✅ Success Checklist

- [ ] App Registration created with API permissions
- [ ] Client secret created and saved
- [ ] Function App deployed
- [ ] APPID and SECRETID configured
- [ ] Code deployed to Function App
- [ ] Test API call successful
- [ ] Application Insights enabled
- [ ] Workbook deployed (optional)
- [ ] Documentation reviewed
- [ ] Team trained on usage

**Congratulations! Your Azure Functions are ready to use! 🎉**
