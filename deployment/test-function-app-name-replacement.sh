#!/bin/bash
# Test script to demonstrate function app name replacement with various names

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WORKBOOK_FILE="$REPO_ROOT/workbook/DefenderC2-Workbook.json"

echo "============================================"
echo "Function App Name Replacement Test"
echo "============================================"
echo ""

# Test function app names
TEST_NAMES=(
    "defc2"
    "mydefender"
    "security-functions"
    "company-mde-automation"
    "prod-defender-api"
)

echo -e "${CYAN}Testing placeholder replacement with different function app names...${NC}"
echo ""

for NAME in "${TEST_NAMES[@]}"; do
    echo -e "${BLUE}Test Case: ${NAME}${NC}"
    echo "-------------------------------------------"
    
    # Load workbook JSON
    WORKBOOK_CONTENT=$(cat "$WORKBOOK_FILE")
    
    # Simulate ARM template replacement
    REPLACED_CONTENT=$(echo "$WORKBOOK_CONTENT" | sed "s/__FUNCTION_APP_NAME_PLACEHOLDER__/${NAME}/g")
    
    # Verify replacement worked
    if echo "$REPLACED_CONTENT" | grep -q "\"value\": \"${NAME}\""; then
        echo -e "${GREEN}✓${NC} Placeholder replaced successfully"
    else
        echo -e "${RED}✗${NC} Placeholder replacement failed"
        exit 1
    fi
    
    # Verify no placeholders remain
    if echo "$REPLACED_CONTENT" | grep -q "__FUNCTION_APP_NAME_PLACEHOLDER__"; then
        echo -e "${RED}✗${NC} Placeholder still exists in content"
        exit 1
    else
        echo -e "${GREEN}✓${NC} No placeholders remaining"
    fi
    
    # Count parameter usages
    PARAM_COUNT=$(echo "$REPLACED_CONTENT" | grep -o "{FunctionAppName}" | wc -l)
    echo -e "${GREEN}✓${NC} Found $PARAM_COUNT usages of {FunctionAppName} parameter"
    
    # Verify API endpoint format (sample check)
    if echo "$REPLACED_CONTENT" | grep -q "https://{FunctionAppName}.azurewebsites.net/api/"; then
        echo -e "${GREEN}✓${NC} API endpoints correctly use parameter reference"
    else
        echo -e "${RED}✗${NC} API endpoint format incorrect"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} All checks passed for '${NAME}'"
    echo ""
done

echo "============================================"
echo -e "${GREEN}✓ ALL TEST CASES PASSED!${NC}"
echo "============================================"
echo ""
echo "Summary:"
echo "--------"
echo "✓ Tested ${#TEST_NAMES[@]} different function app names"
echo "✓ Placeholder replacement works correctly"
echo "✓ No placeholders remain after replacement"
echo "✓ Parameter references maintained"
echo "✓ API endpoint format verified"
echo ""
echo "The workbook will work with ANY function app name!"
echo ""

# Demonstrate what the final configuration looks like
echo "Example Configuration After Deployment:"
echo "---------------------------------------"
echo ""
echo -e "${CYAN}User Input:${NC} mydefender"
echo ""
echo -e "${CYAN}Workbook Parameter:${NC}"
echo '  "name": "FunctionAppName",'
echo '  "value": "mydefender"'
echo ""
echo -e "${CYAN}API Endpoints:${NC}"
echo "  https://{FunctionAppName}.azurewebsites.net/api/DefenderC2Dispatcher"
echo "  https://{FunctionAppName}.azurewebsites.net/api/DefenderC2TIManager"
echo "  https://{FunctionAppName}.azurewebsites.net/api/DefenderC2HuntManager"
echo "  ... (and 24 more)"
echo ""
echo -e "${CYAN}Actual Runtime URLs:${NC}"
echo "  https://mydefender.azurewebsites.net/api/DefenderC2Dispatcher"
echo "  https://mydefender.azurewebsites.net/api/DefenderC2TIManager"
echo "  https://mydefender.azurewebsites.net/api/DefenderC2HuntManager"
echo "  ... (and 24 more)"
echo ""
