# DefenderC2 Documentation

This directory contains comprehensive guides for implementing and using the DefenderC2 workbook with Custom Endpoint auto-refresh and ARM Actions.

## 📚 Available Guides

### 1. [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md)
**Complete implementation guide** for Custom Endpoint queries and ARM Actions in Azure Workbooks.

**What's Covered:**
- 📡 Custom Endpoint configuration with auto-refresh
- 🎯 ARM Actions for direct Function App HTTP calls
- 🔄 Auto-refresh setup (recommended: 30s interval)
- 📊 JSONPath transformers for output parsing
- 🔧 Parameter configuration (FunctionAppName, TenantId, etc.)
- 🗂️ Function Endpoints reference (all 6 endpoints)
- 🛠️ Troubleshooting common issues
- ✅ Validation steps and checklists
- 📸 Screenshots and visual references

**Perfect for:**
- Setting up workbook queries from scratch
- Understanding how Custom Endpoints work
- Configuring auto-refresh for real-time updates
- Troubleshooting connection issues
- Learning JSONPath for data transformation

---

### 2. [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](CUSTOM_ENDPOINT_SAMPLE_QUERIES.md)
**Copy-paste ready JSON code samples** for all 7 functional tabs in the DefenderC2 workbook.

**What's Covered:**
- 💻 **Device Manager** - Get Devices, Isolate, Release, AV Scan, Quarantine File
- 🔍 **Threat Intel Manager** - List Indicators, Submit File/IP/URL Indicators
- 📊 **Action Manager** - Machine Actions with auto-refresh, Cancel Action
- 🕵️ **Hunt Manager** - Run Hunt, Hunt Results with conditional refresh
- 🚨 **Incident Manager** - List Incidents, Update Incident, Add Comments
- 🔍 **Detection Manager** - List/Create/Update/Delete Custom Detection Rules
- 💻 **Console** - Unified command interface overview
- 🔧 **Parameter Definitions** - All required parameters with JSON examples

**Perfect for:**
- Quick implementation of all 7 tabs
- Copy-paste JSON for workbook configuration
- Understanding the complete JSON structure
- Implementing specific features (e.g., just Threat Intel)
- Reference for API endpoint payloads

---

## 🎯 Quick Navigation by Use Case

### "I want to set up the workbook for the first time"
1. Start with [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) - Read sections:
   - Overview
   - Quick Start
   - Custom Endpoint Configuration
   - ARM Actions Configuration

2. Then use [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](CUSTOM_ENDPOINT_SAMPLE_QUERIES.md) - Copy JSON for each tab

### "I need to troubleshoot workbook issues"
- [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) → Troubleshooting section
- Common issues: Missing headers, incorrect parameters, JSONPath errors

### "I want to implement auto-refresh"
- [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) → Auto-Refresh Configuration
- [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](CUSTOM_ENDPOINT_SAMPLE_QUERIES.md) → Examples with `isAutoRefreshEnabled: true`

### "I need JSON for a specific tab"
- [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](CUSTOM_ENDPOINT_SAMPLE_QUERIES.md) → Jump to tab section (1-7)

### "I want to understand JSONPath transformers"
- [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) → JSONPath Transformers section

### "I need to know what parameters to define"
- [CUSTOM_ENDPOINT_SAMPLE_QUERIES.md](CUSTOM_ENDPOINT_SAMPLE_QUERIES.md) → Parameter Definitions section
- [WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md](WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md) → Quick Start → Step 2

---

## 📖 Related Documentation

### In Main Repository
- [README.md](../README.md) - Main project overview
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Azure deployment guide
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide

### In Deployment Directory
- [WORKBOOK_PARAMETERS_GUIDE.md](../deployment/WORKBOOK_PARAMETERS_GUIDE.md) - Parameter configuration details
- [WORKBOOK_DEPLOYMENT.md](../deployment/WORKBOOK_DEPLOYMENT.md) - Workbook deployment specifics

### In Archive (Historical/Advanced)
- [WORKBOOK_ADVANCED_FEATURES.md](../archive/feature-guides/WORKBOOK_ADVANCED_FEATURES.md) - Advanced workbook features
- [FILE_OPERATIONS_GUIDE.md](../archive/feature-guides/FILE_OPERATIONS_GUIDE.md) - File operations workbook guide

---

## 🎓 Learning Path

### Beginner
1. Read the **Overview** sections in both guides
2. Follow **Quick Start** in WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md
3. Copy one tab from CUSTOM_ENDPOINT_SAMPLE_QUERIES.md (e.g., Device Manager)
4. Test and validate

### Intermediate
1. Implement all 7 tabs using CUSTOM_ENDPOINT_SAMPLE_QUERIES.md
2. Configure auto-refresh for relevant queries
3. Customize JSONPath transformers for your needs
4. Add custom ARM Actions

### Advanced
1. Create custom Function endpoints
2. Implement conditional auto-refresh
3. Add complex JSONPath transformations
4. Integrate with additional Azure services

---

## 🛠️ Implementation Checklist

Use this checklist when implementing the DefenderC2 workbook:

### Prerequisites
- [ ] Azure Function App deployed with DefenderC2 functions
- [ ] Function App has `APPID` and `SECRETID` environment variables
- [ ] App Registration has MDE API permissions
- [ ] Admin consent granted for API permissions
- [ ] Log Analytics workspace exists

### Parameters
- [ ] FunctionAppName parameter configured
- [ ] Subscription parameter (auto-discovered)
- [ ] Workspace parameter (auto-discovered)
- [ ] TenantId parameter (auto-discovered from workspace)

### Device Manager Tab
- [ ] Get Devices query with auto-refresh (30s)
- [ ] Isolate Devices ARM Action
- [ ] Release from Isolation ARM Action
- [ ] Run Antivirus Scan ARM Action
- [ ] Stop and Quarantine File ARM Action

### Threat Intel Manager Tab
- [ ] List Indicators query
- [ ] Submit File Indicator ARM Action
- [ ] Submit IP Indicator ARM Action
- [ ] Submit URL Indicator ARM Action

### Action Manager Tab
- [ ] Machine Actions query with auto-refresh (30s)
- [ ] Cancel Action ARM Action

### Hunt Manager Tab
- [ ] Run Hunt Query ARM Action
- [ ] Hunt Results query with auto-refresh (conditional)

### Incident Manager Tab
- [ ] List Incidents query with auto-refresh (60s)
- [ ] Update Incident ARM Action
- [ ] Add Comment ARM Action

### Detection Manager Tab
- [ ] List Detections query with auto-refresh (120s)
- [ ] Create Detection ARM Action
- [ ] Update Detection ARM Action
- [ ] Delete Detection ARM Action

### Console Tab
- [ ] Console commands implemented (reusing ARM Actions from other tabs)

### Validation
- [ ] All queries return data successfully
- [ ] Auto-refresh works correctly
- [ ] ARM Actions execute without errors
- [ ] Parameters populate correctly
- [ ] No error messages or warnings

---

## 🤝 Contributing

If you find errors or have improvements:
1. Test changes in a real Azure Workbook environment
2. Validate with actual Function App endpoints
3. Document your changes clearly
4. Submit a pull request

---

## 📞 Support

For issues or questions:
1. Check the **Troubleshooting** section in WORKBOOK_CUSTOM_ENDPOINT_GUIDE.md
2. Review **Validation Steps** to ensure proper configuration
3. Check Function App logs in Application Insights
4. Open an issue on GitHub with details

---

**Last Updated**: 2025-10-11  
**Version**: 2.0  
**Maintainer**: DefenderC2 Team
