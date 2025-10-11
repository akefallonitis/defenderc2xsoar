# DefenderC2 Examples

This directory contains example configurations and workbooks demonstrating different patterns and use cases for DefenderC2.

## Files

### customendpoint-example.json
**Type**: Azure Workbook  
**Purpose**: Demonstrates CustomEndpoint pattern with queryType: 10

This example workbook shows:
- CustomEndpoint queries without Function Key (anonymous access)
- CustomEndpoint queries with optional Function Key parameter
- Auto-refresh configuration for CustomEndpoint queries
- ARM Actions without Function Key
- ARM Actions with optional Function Key
- Comparison between ARMEndpoint and CustomEndpoint patterns

**How to use:**
1. Open Azure Portal → Monitor → Workbooks
2. Click "New" → "Advanced Editor"
3. Paste the contents of `customendpoint-example.json`
4. Click "Apply" → "Done Editing"
5. Configure parameters:
   - Select Subscription
   - Select Workspace (TenantId auto-populates)
   - Enter Function App Name
   - (Optional) Enter Function Key if not using anonymous access

**Key Features:**
- ✅ Full parameter autodiscovery (TenantId from workspace)
- ✅ Optional Function Key support
- ✅ Multiple query pattern examples
- ✅ Auto-refresh demonstration
- ✅ ARM Action examples

### sample-config.md
**Type**: Documentation  
**Purpose**: Example parameter configurations and usage patterns

Contains sample values for:
- Workbook parameters
- Device action examples
- Threat intelligence indicator submission
- Advanced hunting queries
- Custom detection rule examples

## Related Documentation

For complete guides and reference documentation, see:

- **[CUSTOMENDPOINT_GUIDE.md](../deployment/CUSTOMENDPOINT_GUIDE.md)** - Complete guide for CustomEndpoint and ARM Actions with optional Function Key support
- **[WORKBOOK_PARAMETERS_GUIDE.md](../deployment/WORKBOOK_PARAMETERS_GUIDE.md)** - Parameter configuration reference
- **[DYNAMIC_FUNCTION_APP_NAME.md](../deployment/DYNAMIC_FUNCTION_APP_NAME.md)** - Dynamic function app naming patterns

## Pattern Comparison

### ARMEndpoint Pattern (Current Production Workbooks)
```json
{
  "queryType": 12,
  "query": "{\"version\":\"ARMEndpoint/1.0\",\"path\":\"https://{FunctionAppName}.azurewebsites.net/api/...\",\"httpBodySchema\":\"...\"}"
}
```

**Characteristics:**
- Uses queryType: 12
- Body parameter is `httpBodySchema`
- URL parameter is `path`
- Stable and working in production
- Used in DefenderC2-Workbook.json and FileOperations.workbook

### CustomEndpoint Pattern (Recommended for New Implementations)
```json
{
  "queryType": 10,
  "query": "{\"version\":\"CustomEndpoint/1.0\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/...\",\"body\":\"...\"}"
}
```

**Characteristics:**
- Uses queryType: 10
- Body parameter is `body`
- URL parameter is `url`
- Better support for auto-refresh
- Easier parameter substitution (including optional Function Key)
- Demonstrated in customendpoint-example.json

## When to Use Which Pattern

### Use ARMEndpoint (queryType: 12) when:
- Working with existing production workbooks
- Stability and proven reliability are priorities
- No need for advanced auto-refresh features
- Azure ARM resource interactions

### Use CustomEndpoint (queryType: 10) when:
- Creating new workbooks from scratch
- Need advanced auto-refresh capabilities
- Want flexible function key handling
- Calling external APIs or Azure Functions
- Following the latest Azure Workbooks best practices

## Quick Start Examples

### Example 1: Simple CustomEndpoint Query

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\"}",
    "size": 0,
    "queryType": 10,
    "visualization": "table"
  }
}
```

### Example 2: CustomEndpoint with Function Key

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "{\"version\":\"CustomEndpoint/1.0\",\"method\":\"POST\",\"url\":\"https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}\",\"headers\":[{\"name\":\"Content-Type\",\"value\":\"application/json\"}],\"body\":\"{\\\"action\\\":\\\"Get Devices\\\",\\\"tenantId\\\":\\\"{TenantId}\\\"}\"}",
    "size": 0,
    "queryType": 10,
    "visualization": "table"
  }
}
```

### Example 3: ARM Action with Function Key

```json
{
  "type": 11,
  "content": {
    "version": "LinkItem/1.0",
    "links": [{
      "linkTarget": "ArmAction",
      "linkLabel": "Isolate Device",
      "armActionContext": {
        "path": "https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher?code={FunctionKey}",
        "headers": [{"name": "Content-Type", "value": "application/json"}],
        "body": "{\"action\":\"Isolate Device\",\"tenantId\":\"{TenantId}\",\"deviceIds\":\"{DeviceIds}\"}",
        "httpMethod": "POST"
      }
    }]
  }
}
```

## Testing Examples

After importing an example workbook:

1. **Verify Parameters**
   - ✓ Subscription dropdown has values
   - ✓ Workspace dropdown has values
   - ✓ TenantId auto-populates
   - ✓ FunctionAppName is filled
   - ✓ FunctionKey is empty (if using anonymous)

2. **Test CustomEndpoint Queries**
   - Click refresh on a device list query
   - Verify data appears in table
   - Check for errors in browser console (F12)

3. **Test ARM Actions**
   - Click an action button
   - Verify confirmation dialog appears
   - Check Function App logs for request

4. **Test Auto-Refresh**
   - Wait 30 seconds (or configured interval)
   - Verify query automatically refreshes
   - Check timestamp updates

## Troubleshooting Examples

### No Data Returned
**Check:**
- Function App is running
- FunctionAppName parameter is correct
- TenantId is valid
- Data exists in Defender (e.g., devices, incidents)

### 401 Unauthorized
**Check:**
- Function Key is correct (if required)
- Function App authentication level matches configuration

### 404 Not Found
**Check:**
- Function App name is correct
- Function endpoint exists
- URL is properly formatted

### JSON Parse Errors
**Check:**
- Query string is properly escaped
- All quotes are doubled inside JSON string
- No unescaped special characters

## Contributing

To add new examples:

1. Create example workbook JSON or documentation
2. Add entry to this README
3. Test example thoroughly
4. Submit PR with description

## Support

For issues with examples:
- Check the troubleshooting section above
- Review the full documentation in `/deployment/`
- Open a GitHub issue with details

---

**Last Updated**: 2025-10-11  
**Examples**: 2 (customendpoint-example.json, sample-config.md)
