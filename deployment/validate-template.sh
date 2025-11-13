#!/bin/bash
# ARM Template Validation Script
# This script validates the ARM template and parameters before deployment

set -e

TEMPLATE_FILE="${1:-azuredeploy.json}"
RESOURCE_GROUP="${2:-rg-defenderc2-test}"
LOCATION="${3:-eastus}"

echo -e "\033[36mARM Template Validation Script\033[0m"
echo -e "\033[36m===============================\033[0m"
echo ""

# Check if Azure CLI is installed
echo -e "\033[33mChecking Azure CLI...\033[0m"
if command -v az &> /dev/null; then
    echo -e "\033[32m✓ Azure CLI found\033[0m"
else
    echo -e "\033[31m✗ Azure CLI not found. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli\033[0m"
    exit 1
fi

# Check if jq is installed
echo -e "\033[33mChecking jq (JSON processor)...\033[0m"
if command -v jq &> /dev/null; then
    echo -e "\033[32m✓ jq found\033[0m"
else
    echo -e "\033[31m✗ jq not found. Install with: sudo apt-get install jq (Ubuntu) or brew install jq (Mac)\033[0m"
    exit 1
fi

# Check if template file exists
echo -e "\033[33mChecking template file...\033[0m"
if [ -f "$TEMPLATE_FILE" ]; then
    echo -e "\033[32m✓ Template file found: $TEMPLATE_FILE\033[0m"
else
    echo -e "\033[31m✗ Template file not found: $TEMPLATE_FILE\033[0m"
    exit 1
fi

# Validate JSON syntax
echo -e "\033[33mValidating JSON syntax...\033[0m"
if jq empty "$TEMPLATE_FILE" 2>/dev/null; then
    echo -e "\033[32m✓ JSON syntax is valid\033[0m"
else
    echo -e "\033[31m✗ JSON syntax error\033[0m"
    exit 1
fi

# Check for required parameters
echo -e "\033[33mChecking required parameters...\033[0m"
REQUIRED_PARAMS=("functionAppName" "spnId" "spnSecret" "projectTag" "createdByTag" "deleteAtTag")
MISSING_PARAMS=()

for param in "${REQUIRED_PARAMS[@]}"; do
    if ! jq -e ".parameters.$param" "$TEMPLATE_FILE" > /dev/null 2>&1; then
        MISSING_PARAMS+=("$param")
    fi
done

if [ ${#MISSING_PARAMS[@]} -eq 0 ]; then
    echo -e "\033[32m✓ All required parameters present: ${REQUIRED_PARAMS[*]}\033[0m"
else
    echo -e "\033[31m✗ Missing parameters: ${MISSING_PARAMS[*]}\033[0m"
    exit 1
fi

# Check resources have tags
echo -e "\033[33mChecking resources for required tags...\033[0m"
REQUIRED_TAGS=("Project" "CreatedBy" "DeleteAt")
RESOURCES_WITHOUT_TAGS=()

RESOURCE_COUNT=$(jq '.resources | length' "$TEMPLATE_FILE")
for ((i=0; i<$RESOURCE_COUNT; i++)); do
    RESOURCE_TYPE=$(jq -r ".resources[$i].type" "$TEMPLATE_FILE")
    
    for tag in "${REQUIRED_TAGS[@]}"; do
        if ! jq -e ".resources[$i].tags.$tag" "$TEMPLATE_FILE" > /dev/null 2>&1; then
            RESOURCES_WITHOUT_TAGS+=("$RESOURCE_TYPE (missing: $tag)")
        fi
    done
done

if [ ${#RESOURCES_WITHOUT_TAGS[@]} -eq 0 ]; then
    echo -e "\033[32m✓ All resources have required tags\033[0m"
else
    echo -e "\033[31m✗ Resources missing tags:\033[0m"
    for resource in "${RESOURCES_WITHOUT_TAGS[@]}"; do
        echo -e "\033[31m  - $resource\033[0m"
    done
    exit 1
fi

# Check function app environment variables
echo -e "\033[33mChecking function app environment variables...\033[0m"
REQUIRED_SETTINGS=("APPID" "SECRETID" "FUNCTIONS_WORKER_RUNTIME" "FUNCTIONS_EXTENSION_VERSION")
MISSING_SETTINGS=()

for setting in "${REQUIRED_SETTINGS[@]}"; do
    if ! jq -e ".resources[] | select(.type == \"Microsoft.Web/sites\") | .properties.siteConfig.appSettings[] | select(.name == \"$setting\")" "$TEMPLATE_FILE" > /dev/null 2>&1; then
        MISSING_SETTINGS+=("$setting")
    fi
done

if [ ${#MISSING_SETTINGS[@]} -eq 0 ]; then
    echo -e "\033[32m✓ All required environment variables configured\033[0m"
else
    echo -e "\033[31m✗ Missing environment variables: ${MISSING_SETTINGS[*]}\033[0m"
    exit 1
fi

# Test Azure connection
echo -e "\033[33mTesting Azure connection...\033[0m"
if az account show &> /dev/null; then
    ACCOUNT_NAME=$(az account show --query "user.name" -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)
    echo -e "\033[32m✓ Connected to Azure as $ACCOUNT_NAME\033[0m"
    echo -e "\033[90m  Subscription: $SUBSCRIPTION_NAME\033[0m"
else
    echo -e "\033[31m✗ Not connected to Azure. Run: az login\033[0m"
    exit 1
fi

# Create test parameters file
echo -e "\033[33mValidating template deployment...\033[0m"
TEST_PARAMS_FILE=$(mktemp)
cat > "$TEST_PARAMS_FILE" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "functionAppName": {
      "value": "test-func-app"
    },
    "spnId": {
      "value": "00000000-0000-0000-0000-000000000000"
    },
    "spnSecret": {
      "value": "test-secret-value"
    },
    "projectTag": {
      "value": "TestProject"
    },
    "createdByTag": {
      "value": "test@example.com"
    },
    "deleteAtTag": {
      "value": "Never"
    }
  }
}
EOF

# Validate template
if az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$TEST_PARAMS_FILE" \
    --location "$LOCATION" \
    --no-prompt \
    &> /dev/null; then
    echo -e "\033[32m✓ Template validation successful\033[0m"
else
    echo -e "\033[31m✗ Template validation failed\033[0m"
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$TEST_PARAMS_FILE" \
        --location "$LOCATION" \
        --no-prompt
    rm -f "$TEST_PARAMS_FILE"
    exit 1
fi

rm -f "$TEST_PARAMS_FILE"

echo ""
echo -e "\033[36m===============================\033[0m"
echo -e "\033[32m✓ All validation checks passed!\033[0m"
echo -e "\033[36m===============================\033[0m"
echo ""
echo -e "\033[36mNext steps:\033[0m"
echo -e "\033[37m1. Create or update your app registration with a client secret\033[0m"
echo -e "\033[37m2. Deploy using the Azure Portal, Azure CLI, or PowerShell\033[0m"
echo -e "\033[37m3. Deploy function code to the function app\033[0m"
echo -e "\033[37m4. Configure the workbook with your function app URL\033[0m"
echo ""
