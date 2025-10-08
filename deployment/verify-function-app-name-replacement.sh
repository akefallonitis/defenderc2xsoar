#!/bin/bash
# Verification script for dynamic function app name replacement

set -e

echo "============================================"
echo "Function App Name Dynamic Replacement Check"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📋 Checking Workbook Files..."
echo "------------------------------"

# Check main workbook
WORKBOOK_FILE="$REPO_ROOT/workbook/DefenderC2-Workbook.json"
if [ -f "$WORKBOOK_FILE" ]; then
    if grep -q "__FUNCTION_APP_NAME_PLACEHOLDER__" "$WORKBOOK_FILE"; then
        echo -e "${GREEN}✓${NC} DefenderC2-Workbook.json has placeholder"
        PLACEHOLDER_COUNT=$(grep -o "{FunctionAppName}" "$WORKBOOK_FILE" | wc -l)
        echo "  → Found $PLACEHOLDER_COUNT usages of {FunctionAppName} parameter"
    else
        echo -e "${RED}✗${NC} DefenderC2-Workbook.json missing placeholder"
        exit 1
    fi
    
    # Check for hardcoded defc2
    HARDCODED_COUNT=$(grep -o '"defc2"' "$WORKBOOK_FILE" | wc -l)
    if [ "$HARDCODED_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No hardcoded 'defc2' values found"
    else
        echo -e "${RED}✗${NC} Found $HARDCODED_COUNT hardcoded 'defc2' references"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} DefenderC2-Workbook.json not found"
    exit 1
fi

# Check FileOperations workbook
FILEOPS_FILE="$REPO_ROOT/workbook/FileOperations.workbook"
if [ -f "$FILEOPS_FILE" ]; then
    if grep -q "__FUNCTION_APP_NAME_PLACEHOLDER__" "$FILEOPS_FILE"; then
        echo -e "${GREEN}✓${NC} FileOperations.workbook has placeholder"
        PLACEHOLDER_COUNT=$(grep -o "{FunctionAppName}" "$FILEOPS_FILE" | wc -l)
        echo "  → Found $PLACEHOLDER_COUNT usages of {FunctionAppName} parameter"
    else
        echo -e "${RED}✗${NC} FileOperations.workbook missing placeholder"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} FileOperations.workbook not found (optional)"
fi

echo ""
echo "🔧 Checking ARM Template..."
echo "------------------------------"

ARM_TEMPLATE="$SCRIPT_DIR/azuredeploy.json"
if [ -f "$ARM_TEMPLATE" ]; then
    # Check for replacement mechanism
    if grep -q "replace(base64ToString(variables('workbookContent')), '__FUNCTION_APP_NAME_PLACEHOLDER__', variables('functionAppName'))" "$ARM_TEMPLATE"; then
        echo -e "${GREEN}✓${NC} ARM template has correct replacement mechanism"
    else
        echo -e "${RED}✗${NC} ARM template replacement mechanism not found or incorrect"
        exit 1
    fi
    
    # Check for parameter definition
    if grep -q '"functionAppName"' "$ARM_TEMPLATE"; then
        echo -e "${GREEN}✓${NC} ARM template has functionAppName parameter"
    else
        echo -e "${RED}✗${NC} ARM template missing functionAppName parameter"
        exit 1
    fi
    
    # Check embedded workbook has placeholder
    if grep -q "__FUNCTION_APP_NAME_PLACEHOLDER__" "$ARM_TEMPLATE"; then
        echo -e "${GREEN}✓${NC} Embedded workbook contains placeholder"
    else
        echo -e "${RED}✗${NC} Embedded workbook missing placeholder"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} ARM template not found"
    exit 1
fi

echo ""
echo "📝 Checking PowerShell Deployment Script..."
echo "------------------------------"

PS_SCRIPT="$SCRIPT_DIR/deploy-workbook.ps1"
if [ -f "$PS_SCRIPT" ]; then
    if grep -q 'funcAppParam.value = \$FunctionAppName' "$PS_SCRIPT"; then
        echo -e "${GREEN}✓${NC} PowerShell script has placeholder replacement logic"
    else
        echo -e "${RED}✗${NC} PowerShell script missing placeholder replacement"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} deploy-workbook.ps1 not found"
    exit 1
fi

echo ""
echo "🎯 Checking UI Definition..."
echo "------------------------------"

UI_DEF="$SCRIPT_DIR/createUIDefinition.json"
if [ -f "$UI_DEF" ]; then
    if grep -q '"functionAppName"' "$UI_DEF"; then
        echo -e "${GREEN}✓${NC} UI Definition includes functionAppName input"
    else
        echo -e "${RED}✗${NC} UI Definition missing functionAppName"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} createUIDefinition.json not found (optional for CLI deployments)"
fi

echo ""
echo "============================================"
echo -e "${GREEN}✓ ALL CHECKS PASSED!${NC}"
echo "============================================"
echo ""
echo "Summary:"
echo "--------"
echo "✓ Workbook files use placeholder system"
echo "✓ ARM template replaces placeholder with user input"
echo "✓ PowerShell script handles replacement for script-based deployments"
echo "✓ UI Definition captures user's function app name"
echo "✓ No hardcoded function app names found"
echo ""
echo "The system is configured to work with ANY function app name provided by users!"
echo ""
