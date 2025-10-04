# Contributing to defenderc2xsoar

Thank you for your interest in contributing to defenderc2xsoar! This document provides guidelines and instructions for contributing.

## 🤝 How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. **Check Existing Issues**: Search the [issue tracker](https://github.com/akefallonitis/defenderc2xsoar/issues) to see if it's already reported
2. **Create New Issue**: If not found, create a new issue with:
   - Clear, descriptive title
   - Detailed description of the problem or feature
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (Azure region, function app version, etc.)
   - Screenshots if applicable

### Submitting Changes

1. **Fork the Repository**
   ```bash
   # Fork via GitHub UI, then clone your fork
   git clone https://github.com/YOUR-USERNAME/defenderc2xsoar.git
   cd defenderc2xsoar
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Your Changes**
   - Follow the coding standards below
   - Add tests if applicable
   - Update documentation
   - Test thoroughly

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   # or
   git commit -m "fix: resolve bug description"
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template
   - Link related issues

## 📝 Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(workbook): add new threat intelligence tab
fix(functions): resolve authentication timeout issue
docs(readme): update deployment instructions
refactor(dispatcher): simplify device isolation logic
```

## 🏗️ Development Guidelines

### Workbook Development

When modifying the workbook:

1. **Use Advanced Editor**: Edit JSON directly for precision
2. **Test Thoroughly**: Test all parameter combinations
3. **Validate JSON**: Ensure valid JSON structure
4. **Document Parameters**: Add descriptions for new parameters
5. **Follow Naming**: Use consistent naming conventions

#### Workbook Best Practices

```json
{
  "id": "unique-guid-here",
  "version": "KqlParameterItem/1.0",
  "name": "descriptiveName",
  "label": "Human Readable Label",
  "type": 1,  // 1=text, 2=dropdown, 4=time range, etc.
  "isRequired": true,
  "description": "Clear description of what this parameter does"
}
```

### Function Development

When adding or modifying functions:

1. **Follow Structure**: Use the existing function template
2. **Parameter Validation**: Always validate required parameters
3. **Error Handling**: Use try-catch blocks
4. **Logging**: Log important operations
5. **Return Consistent Format**: Use standard JSON response structure

#### Function Template

```powershell
using namespace System.Net

param($Request, $TriggerMetadata)

# Log entry
Write-Host "FunctionName processed a request."

# Extract parameters
$param1 = $Request.Query.param1 ?? $Request.Body.param1
$tenantId = $Request.Query.tenantId ?? $Request.Body.tenantId
$spnId = $Request.Query.spnId ?? $Request.Body.spnId

# Validate
if (-not $tenantId -or -not $spnId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = @{
            error = "Missing required parameters"
            required = @("tenantId", "spnId")
        } | ConvertTo-Json
    })
    return
}

try {
    # Main logic here
    $result = @{
        status = "Success"
        tenantId = $tenantId
        timestamp = (Get-Date).ToString("o")
        data = @{}  # Your data here
    }

    # Return success
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $result | ConvertTo-Json -Depth 5
    })

} catch {
    # Log error
    Write-Error $_.Exception.Message
    
    # Return error
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = @{
            error = $_.Exception.Message
            details = $_.Exception.ToString()
        } | ConvertTo-Json
    })
}
```

### PowerShell Style Guide

1. **Use Consistent Naming**
   - PascalCase for cmdlets and functions
   - camelCase for variables
   - UPPERCASE for constants

2. **Comments**
   ```powershell
   # Single line comment for brief explanation
   
   <#
   .SYNOPSIS
       Multi-line comment for detailed explanation
   .DESCRIPTION
       More details here
   #>
   ```

3. **Error Handling**
   ```powershell
   try {
       # Risky operation
   } catch {
       Write-Error "Failed to perform operation: $($_.Exception.Message)"
       throw
   }
   ```

4. **Parameter Validation**
   ```powershell
   if (-not $requiredParam) {
       throw "requiredParam is required"
   }
   ```

### ARM Template Guidelines

When modifying the ARM template:

1. **Use Parameters**: Make values configurable
2. **Add Descriptions**: Document each parameter
3. **Set Defaults**: Provide sensible defaults
4. **Output Important Values**: Output deployment results
5. **Follow Conventions**: Use Azure naming conventions

### Documentation Standards

1. **README Updates**: Update README.md for major changes
2. **Inline Documentation**: Add comments to complex code
3. **Examples**: Provide usage examples
4. **Screenshots**: Include screenshots for UI changes
5. **Changelog**: Update CHANGELOG.md (if exists)

## 🧪 Testing

### Local Testing

1. **Function Testing**
   ```bash
   # Install Azure Functions Core Tools
   npm install -g azure-functions-core-tools@4
   
   # Run locally
   cd functions
   func start
   
   # Test endpoint
   curl http://localhost:7071/api/MDEDispatcher?action=test
   ```

2. **Workbook Testing**
   - Export workbook JSON
   - Import to test environment
   - Test all parameters
   - Verify all queries
   - Test all actions

### Integration Testing

1. **Deploy to Test Environment**
   ```bash
   az deployment group create \
     --resource-group rg-test \
     --template-file deployment/azuredeploy.json \
     --parameters functionAppName=test-func-app spnId=your-test-app-id
   ```

2. **Test Scenarios**
   - Authentication flow
   - Single device action
   - Bulk device action
   - Threat intelligence operation
   - Hunting query execution
   - Error handling

### Test Checklist

Before submitting:

- [ ] Code runs without errors
- [ ] All parameters are validated
- [ ] Error handling works correctly
- [ ] Logging is appropriate
- [ ] Documentation is updated
- [ ] Examples are provided
- [ ] No secrets in code
- [ ] Function keys not committed
- [ ] .gitignore is updated

## 📋 Pull Request Checklist

- [ ] Fork and branch created
- [ ] Changes are focused and related
- [ ] Commit messages follow convention
- [ ] Code follows style guidelines
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] PR description is clear
- [ ] Related issues linked

## 🎨 Style Preferences

### JSON Formatting

```json
{
  "property": "value",
  "nested": {
    "property": "value"
  },
  "array": [
    "item1",
    "item2"
  ]
}
```

### PowerShell Formatting

```powershell
# Function definition
function Get-Something {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [int]$Count = 10
    )
    
    # Function body
    $result = @{
        name = $Name
        count = $Count
    }
    
    return $result
}
```

### KQL Formatting

```kql
TableName
| where TimeGenerated > ago(7d)
| where Column1 == "value"
| summarize Count=count() by Column2
| order by Count desc
| take 100
```

## 🌟 Enhancement Ideas

Looking for contribution ideas? Consider:

### High Priority
- [ ] Add more sample hunting queries
- [ ] Improve error messages
- [ ] Add more visualization options
- [ ] Enhance multi-tenant switching
- [ ] Add batch operation progress tracking

### Medium Priority
- [x] Create PowerShell module for local use (✨ See [standalone/](standalone/))
- [ ] Add more custom detection examples
- [ ] Improve workbook performance
- [ ] Add export functionality
- [ ] Create deployment scripts

### Nice to Have
- [ ] Add dark mode support
- [ ] Create video tutorials
- [ ] Add notification system
- [ ] Integrate with Teams/Slack
- [ ] Add approval workflows

## 📞 Getting Help

If you need help:

1. **Check Documentation**: Review README, DEPLOYMENT, and QUICKSTART guides
2. **Search Issues**: Look for similar questions
3. **Ask Questions**: Open a discussion or issue
4. **Join Community**: (Add community links if available)

## 🏆 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

## 📜 Code of Conduct

### Our Standards

- **Be Respectful**: Treat everyone with respect
- **Be Constructive**: Provide helpful feedback
- **Be Patient**: Remember everyone is learning
- **Be Inclusive**: Welcome diverse perspectives

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Unprofessional conduct

### Enforcement

Violations may result in:
1. Warning
2. Temporary ban
3. Permanent ban

Report violations to the maintainers.

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You

Thank you for contributing to defenderc2xsoar! Your efforts help make this project better for everyone.

---

**Questions?** Open an issue or reach out to the maintainers.
