# Feature Overview

A comprehensive guide to all features available in defenderc2xsoar.

## 🎯 Core Capabilities

### 1. Device Response Actions (MDEAutomator Tab)

#### Isolation & Containment
- **Isolate Device**: Network isolate endpoints with selective isolation rules
- **Unisolate Device**: Remove network isolation from endpoints
- **Restrict App Execution**: Allow only Microsoft-signed binaries to run
- **Unrestrict App Execution**: Remove app execution restrictions

#### Investigation & Forensics
- **Collect Investigation Package**: Gather comprehensive forensic artifacts
  - Event logs
  - Registry hives
  - Memory dumps (optional)
  - Network configuration
  - Running processes
  - File system information

#### Threat Mitigation
- **Run Antivirus Scan**: Execute full disk scans
- **Stop & Quarantine File**: Stop and quarantine malicious files by hash

#### Live Response Operations
- **Run Live Response Script**: Execute PowerShell scripts from LR library
- **Get File**: Retrieve files from endpoints for analysis
- **Put File**: Push scripts/tools to endpoints
- **Upload to LR Library**: Add new scripts to the library

#### Targeting Options
- **Specific Devices**: Target by device ID (comma-separated)
- **Dynamic Filters**: Use OData filters for bulk operations
  - Risk score: `riskScore eq 'High'`
  - Tags: `contains(machineTags, 'Critical')`
  - OS Platform: `contains(osPlatform, 'Windows')`
  - Health status: `healthStatus eq 'Active'`
  - Onboarding status: `onboardingStatus eq 'Onboarded'`

### 2. Threat Intelligence Management (TI Manager Tab)

#### File Indicators
- **Supported Hash Types**: SHA1, SHA256
- **Actions**: Alert, Block, Allowed
- **Bulk Import**: Comma-separated or CSV upload
- **Title & Description**: Document indicator context
- **Severity Levels**: Informational, Low, Medium, High
- **Expiration**: Automatic expiration after configurable period

#### Network Indicators
- **IP Addresses**: IPv4 and IPv6 support
- **URLs and Domains**: Full URL or domain-only
- **Actions**: Alert, Block, Allowed
- **Bulk Operations**: Import hundreds of indicators at once

#### Certificate Indicators
- **Certificate Thumbprints**: SHA1 thumbprints
- **Code Signing Certs**: Block malicious signed code
- **Actions**: Alert, Block

#### Management Operations
- **List All Indicators**: View all active indicators
- **Bulk Remove**: Remove multiple indicators at once
- **Filter & Search**: Find specific indicators
- **Export**: Download indicator lists for backup

### 3. Action Management (Action Manager Tab)

#### Action Monitoring
- **Recent Actions**: View last 60 days of machine actions
- **Action Types**:
  - Isolation/Unisolation
  - Restrict/Unrestrict app execution
  - Antivirus scans
  - Investigation packages
  - Live response operations
  - File collection
  - Stop and quarantine

#### Action Status
- **Pending**: Action queued but not yet executed
- **In Progress**: Action currently executing
- **Completed**: Action finished successfully
- **Failed**: Action encountered an error
- **Cancelled**: Action was cancelled

#### Safety Features
- **Cancel All Actions**: Emergency stop for all pending actions
- **Action Details**: View full details of each action
- **Action Results**: Download outputs and logs
- **Timeline View**: Visualize actions over time

#### Statistics & Reporting
- **Action Type Distribution**: See most common actions
- **Success Rate**: Monitor action completion rates
- **Device Coverage**: See which devices have recent actions
- **Failure Analysis**: Identify common failure patterns

### 4. Threat Hunting (Hunt Manager Tab)

#### Query Execution
- **Advanced Hunting**: Execute KQL queries against MDE
- **Multiple Tables**: Query across all MDE advanced hunting tables
  - DeviceProcessEvents
  - DeviceNetworkEvents
  - DeviceFileEvents
  - DeviceLogonEvents
  - DeviceRegistryEvents
  - DeviceImageLoadEvents
  - DeviceEvents
  - And more...

#### Query Management
- **Save Queries**: Name and save frequently used queries
- **Query Library**: Pre-built queries for common scenarios
- **Query History**: Track executed queries
- **Share Queries**: Export/import query definitions

#### Results Handling
- **Real-time Results**: See results as they come in
- **Export Options**: CSV, JSON export
- **Azure Storage**: Optionally save to blob storage
- **Result Parsing**: Automatic JSON parsing and display

#### Sample Hunt Scenarios
- Suspicious PowerShell activity
- Lateral movement detection
- Persistence mechanisms
- Credential dumping
- Network anomalies
- File creation patterns
- Registry modifications

### 5. Incident Management (Incident Manager Tab)

#### Incident Viewing
- **Filter by Severity**: High, Medium, Low, Informational
- **Filter by Status**: Active, Resolved, Redirected
- **Time Range**: Last 7, 30, 60, 90 days
- **Search**: Find specific incidents

#### Incident Details
- **Alert Information**: All associated alerts
- **Evidence**: Devices, files, processes, network, users
- **Timeline**: Incident progression
- **Attack Story**: Automated attack chain analysis

#### Incident Management
- **Update Status**: Change incident state
- **Assign**: Assign to team members
- **Classify**: True positive, false positive, informational
- **Determine**: Malware, phishing, compromised account, etc.
- **Add Comments**: Document investigation progress
- **Resolve**: Close with resolution notes

#### Statistics & Insights
- **Incidents by Severity**: Pie chart visualization
- **Incidents by Status**: Distribution view
- **Trend Analysis**: Incidents over time
- **MTTR Tracking**: Mean time to resolve

### 6. Custom Detection Management (CD Manager Tab)

#### Detection Rules
- **Create Rules**: Build custom detection logic with KQL
- **Update Rules**: Modify existing detections
- **Delete Rules**: Remove outdated detections
- **Enable/Disable**: Temporarily disable without deleting

#### Rule Components
- **Name**: Descriptive rule name
- **Description**: What the detection identifies
- **Severity**: Informational, Low, Medium, High
- **Query**: KQL query logic
- **Frequency**: How often to run (1h, 6h, 12h, 24h)
- **Actions**: Alert, Block, Allow

#### Management Features
- **List All Detections**: View all custom rules
- **Backup Detections**: Export to Azure Storage
- **Restore Detections**: Import from backup
- **Version Control**: Track rule changes

#### Sample Detection Categories
- Suspicious process execution
- Credential access attempts
- Lateral movement
- Persistence mechanisms
- Defense evasion
- Command and control
- Exfiltration attempts

## 🌐 Multi-Tenant Features

### Single Deployment, Multiple Tenants
- **Tenant Parameter**: Specify target tenant per request
- **Tenant Isolation**: Complete data separation
- **Shared Resources**: One function app serves all tenants
- **Per-Tenant Consent**: Admin consent required per tenant

### Tenant Management
- **Tenant Switching**: Change tenant via parameter
- **Tenant List**: Maintain list of managed tenants
- **Cross-Tenant Reporting**: Aggregate data across tenants
- **Tenant-Specific Policies**: Different actions per tenant

## 🔒 Security Features

### Authentication
- **Managed Identity**: No secrets to manage
- **Federated Credentials**: Automatic credential rotation
- **Per-Tenant Tokens**: Tokens scoped to specific tenant
- **Token Caching**: Efficient token reuse

### Authorization
- **API Permissions**: Granular permission control
- **Admin Consent**: Required per tenant
- **RBAC**: Azure role-based access control
- **Function Keys**: Optional additional security layer

### Audit & Compliance
- **Activity Logging**: All actions logged
- **Application Insights**: Detailed telemetry
- **Azure Monitor**: Centralized monitoring
- **Alert Rules**: Automated alerting on anomalies

## 📊 Visualization & Reporting

### Workbook Visualizations
- **Grid Views**: Sortable, filterable data tables
- **Charts**: Pie, bar, line, area charts
- **Timelines**: Time-series visualizations
- **Heatmaps**: Activity distribution
- **Gauges**: KPI monitoring

### Data Sources
- **Log Analytics**: MDE data in workspace
- **Azure Resource Graph**: Resource metadata
- **Function Responses**: Real-time API data
- **Custom Queries**: KQL flexibility

### Export Options
- **CSV Export**: Export grid data
- **JSON Export**: Structured data export
- **Screenshot**: Capture workbook views
- **Print**: Printer-friendly format

## 🔄 Automation Capabilities

### Scheduled Operations
- **Recurring Hunts**: Schedule regular threat hunts
- **Periodic Scans**: Auto-scan at intervals
- **Maintenance Windows**: Schedule bulk operations
- **Report Generation**: Automated reporting

### Event-Driven Actions
- **Alert Triggers**: Respond to specific alerts
- **Threshold-Based**: Act when metrics exceed limits
- **Sentinel Integration**: Respond to Sentinel incidents
- **Logic Apps**: Complex workflow orchestration

### Batch Operations
- **Bulk Isolation**: Isolate multiple devices
- **Mass Indicator Upload**: Add hundreds of IOCs
- **Fleet-Wide Scans**: Scan entire device population
- **Batch File Retrieval**: Collect files from many devices

## 🛠️ Advanced Features

### Query Builder
- **Visual Query Builder**: Build KQL without coding
- **Query Templates**: Pre-built query patterns
- **Query Validation**: Syntax checking
- **Query Optimization**: Performance suggestions

### Custom Integrations
- **Webhooks**: Trigger external systems
- **API Endpoints**: Expose custom endpoints
- **Data Export**: Push to external systems
- **Import Capabilities**: Ingest external data

### Performance Optimization
- **Caching**: Reduce API calls
- **Batch Processing**: Efficient bulk operations
- **Parallel Execution**: Concurrent operations
- **Retry Logic**: Automatic retry on transient failures

## 📈 Analytics & Insights

### Device Analytics
- **Risk Score Distribution**: See device risk levels
- **Health Status**: Monitor device health
- **OS Distribution**: Platform breakdown
- **Tag Analysis**: Device categorization

### Threat Analytics
- **Indicator Statistics**: IOC effectiveness
- **Detection Coverage**: What's being detected
- **Alert Trends**: Alert patterns over time
- **Incident Metrics**: MTTR, false positive rate

### Operational Analytics
- **Action Success Rate**: Monitor automation health
- **API Performance**: Track API response times
- **User Activity**: Who's doing what
- **Cost Analysis**: Track Azure consumption

## 🎓 Learning & Documentation

### In-App Help
- **Sample Queries**: Learn by example
- **Field Descriptions**: Hover tooltips
- **Action Guidance**: What each action does
- **Best Practices**: Recommended approaches

### Documentation
- **Quick Start Guide**: Get running in 30 minutes
- **Deployment Guide**: Step-by-step setup
- **Architecture Guide**: Technical deep-dive
- **Sample Configurations**: Real-world examples

## 🔮 Extensibility

### Custom Functions
- **Add New Endpoints**: Extend functionality
- **Custom Actions**: Create new action types
- **Plugin Architecture**: Modular design
- **Integration Points**: Connect to other systems

### Customization
- **Workbook Editing**: Modify UI as needed
- **Query Customization**: Tailor queries
- **Parameter Addition**: Add new parameters
- **Branding**: Add company branding

## 🌟 Unique Advantages

### vs. Original MDEAutomator
1. **Cost**: 80-90% cheaper (~$10-20/month vs ~$220/month)
2. **Maintenance**: Minimal (no web app to maintain)
3. **Security**: No secrets management needed
4. **Deployment**: Simpler (single ARM template)
5. **Scaling**: Automatic serverless scaling

### vs. Manual MDE Portal
1. **Bulk Operations**: Act on hundreds of devices at once
2. **Automation**: Script repetitive tasks
3. **Multi-Tenant**: Manage multiple tenants from one place
4. **Advanced Hunting**: More powerful query capabilities
5. **Integration**: Connect to other systems

### vs. Other Automation Tools
1. **Native Integration**: Built for Azure/MDE
2. **No Infrastructure**: Serverless architecture
3. **Security Model**: Managed identity, no secrets
4. **Cost Model**: Pay only for what you use
5. **Flexibility**: Customize to your needs

## 🎯 Use Cases

### Incident Response
- Rapid device isolation
- Evidence collection
- Threat containment
- Investigation automation
- Response orchestration

### Threat Hunting
- Proactive threat detection
- IOC pivot analysis
- Pattern discovery
- Campaign tracking
- Historical analysis

### Security Operations
- Daily health checks
- Compliance monitoring
- Patch verification
- Configuration management
- Fleet management

### Threat Intelligence
- IOC lifecycle management
- Threat feed integration
- Intelligence sharing
- Detection engineering
- False positive reduction

---

**Note**: Features continue to evolve. Check the repository for the latest updates and capabilities.
