# Workbook Examples

This repository includes several example Azure Workbooks that demonstrate advanced functionality and provide inspiration for customizing your MDE automation experience.

## Available Examples

### 1. Advanced Workbook Concepts.json
A comprehensive example showcasing advanced workbook features:
- Complex parameter handling
- Dynamic queries with user input
- Advanced visualizations
- Multi-step workflows
- Conditional rendering

**Use this when:** You want to learn advanced workbook patterns and techniques for building sophisticated automation interfaces.

### 2. DefenderC2 Advanced Console.json
An enhanced console interface for Defender operations:
- Streamlined command and control interface
- Quick-action buttons
- Status monitoring
- Bulk operations support

**Use this when:** You need a simplified, console-style interface for MDE operations.

### 3. Investigation Insights.json & Investigation Insights Original.json
Two versions of an investigation-focused workbook:
- Threat analysis workflows
- Evidence collection
- Timeline visualization
- Cross-reference capabilities
- Investigation notes and documentation

**Use this when:** You're performing security investigations and need structured workflows for evidence gathering and analysis.

### 4. Sentinel360 XDR Investigation-Remediation Console Enhanced.json
Enhanced XDR (Extended Detection and Response) console:
- Cross-platform threat detection
- Integrated remediation actions
- Multi-tenant support
- Advanced filtering and search
- Export capabilities

**Use this when:** You need comprehensive XDR capabilities across multiple security platforms.

### 5. Sentinel360-MDR-Console.json (v1 and latest)
Managed Detection and Response (MDR) console with multiple versions:
- SOC analyst-focused interface
- Case management
- Alert triage workflows
- SLA tracking
- Escalation procedures

**Use this when:** You're running an MDR service or SOC and need analyst-focused workflows.

### 6. Sentinel360-XDR-Auditing.json
Audit and compliance-focused workbook:
- Compliance reporting
- Action logging and review
- User activity tracking
- Change management
- Audit trail visualization

**Use this when:** You need audit trails and compliance reporting for security operations.

## How to Use These Examples

### 1. Import into Azure Monitor

1. Go to Azure Portal > Monitor > Workbooks
2. Click "New" > Click the "Advanced Editor" button (`</>`)
3. Delete the default JSON
4. Copy the content from one of the example JSON files
5. Paste it into the editor
6. Click "Apply"
7. Explore the features and functionality

### 2. Customize for Your Needs

Each example workbook can be used as a starting point:

1. **Study the structure:** Open the JSON and examine how queries, parameters, and UI elements are structured
2. **Copy useful patterns:** Extract specific features or UI patterns you like
3. **Adapt to your environment:** Modify queries and parameters to match your data sources and requirements
4. **Combine features:** Mix and match elements from multiple examples

### 3. Learn Advanced Techniques

These workbooks demonstrate:
- **Dynamic queries:** Using parameters to modify KQL queries at runtime
- **Conditional visibility:** Showing/hiding UI elements based on conditions
- **Custom visualizations:** Creating charts, graphs, and custom renderings
- **ARM actions:** Calling Azure Function Apps and APIs from workbooks
- **Multi-step workflows:** Guiding users through complex processes
- **Data transformation:** Processing and formatting query results
- **Export capabilities:** Downloading data in various formats

## Integration with MDE Automator

The main workbook for this project is located at `/workbook/MDEAutomatorWorkbook.json`. However, you can enhance it with features from these examples:

### Adding Investigation Workflows
From `Investigation Insights.json`:
- Evidence collection steps
- Timeline builders
- Cross-reference queries

### Adding Console Features
From `DefenderC2 Advanced Console.json` (now integrated into main workbook):
- Quick-action buttons
- Status monitors
- Simplified interfaces
- **Interactive Console Tab** - Shell-like interface with async execution and auto-polling
- Real-time command status monitoring
- Automatic JSON result parsing

### Adding Audit Capabilities
From `Sentinel360-XDR-Auditing.json`:
- Action logging
- Compliance reports
- Audit trails

## Common Patterns Found in Examples

### 1. Parameter Cascading
```json
{
  "type": "parameter",
  "name": "TenantSelection",
  "query": "Resources | distinct tenantId"
}
```

### 2. Dynamic Queries with Parameters
```json
{
  "type": "query",
  "query": "SecurityAlert | where TenantId == '{TenantSelection}'"
}
```

### 3. ARM Actions
```json
{
  "type": "button",
  "action": "ARM",
  "uri": "https://{functionAppUrl}/api/MDEDispatcher"
}
```

### 4. Conditional Rendering
```json
{
  "type": "conditional",
  "condition": "{ResultCount} > 0",
  "elements": [...]
}
```

## Best Practices from Examples

1. **User Guidance:** Include info boxes and tooltips to guide users
2. **Error Handling:** Display clear error messages when operations fail
3. **Progressive Disclosure:** Show advanced options only when needed
4. **Consistent Layout:** Use tabs and sections to organize functionality
5. **Validation:** Validate inputs before executing actions
6. **Feedback:** Show operation results and status clearly

## Customization Tips

### Starting Simple
1. Begin with the main `MDEAutomatorWorkbook.json`
2. Add one feature at a time from examples
3. Test thoroughly after each change
4. Save versions as you progress

### Advanced Customization
1. Combine multiple example features
2. Create custom queries for your environment
3. Build organization-specific workflows
4. Add branding and custom styling

### Troubleshooting
- Use the workbook's "View JSON" option to debug
- Test queries in Azure Resource Graph Explorer first
- Validate JSON syntax before applying changes
- Check Application Insights for function app errors

## Contributing

If you create useful workbook enhancements or find better patterns, consider contributing them back to the repository!

## Related Documentation

- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [KQL Reference](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [ARM Actions in Workbooks](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-automate)
- Main project [DEPLOYMENT.md](DEPLOYMENT.md)
- Main project [README.md](README.md)

## Support

For questions about these examples or the MDE Automator project:
1. Review the main documentation
2. Check existing GitHub issues
3. Open a new issue with details about your use case

---

**Note:** These examples are provided for reference and learning. Always test workbooks in a non-production environment before deploying to production.
