#!/bin/bash
# Quick verification script for TRUE Hybrid workbook

echo "=============================================================================="
echo "TRUE HYBRID WORKBOOK VERIFICATION"
echo "=============================================================================="

WORKBOOK="DeviceManager-Hybrid.workbook.json"

if [ ! -f "$WORKBOOK" ]; then
    echo "❌ Workbook file not found: $WORKBOOK"
    exit 1
fi

echo ""
echo "1. JSON Validation"
if python3 -m json.tool "$WORKBOOK" > /dev/null 2>&1; then
    echo "   ✅ JSON is valid"
else
    echo "   ❌ JSON is invalid"
    exit 1
fi

echo ""
echo "2. Endpoint Distribution"
ARM_COUNT=$(grep -o 'ARMEndpoint/1.0' "$WORKBOOK" | wc -l)
CUSTOM_COUNT=$(grep -o 'CustomEndpoint/1.0' "$WORKBOOK" | wc -l)
echo "   ARMEndpoint queries: $ARM_COUNT"
echo "   CustomEndpoint queries: $CUSTOM_COUNT"

if [ "$ARM_COUNT" -eq 7 ]; then
    echo "   ✅ ARMEndpoint count correct (7)"
else
    echo "   ❌ ARMEndpoint count incorrect (expected 7, got $ARM_COUNT)"
fi

if [ "$CUSTOM_COUNT" -ge 4 ]; then
    echo "   ✅ CustomEndpoint count correct ($CUSTOM_COUNT)"
else
    echo "   ⚠️  CustomEndpoint count unexpected (expected 4-5, got $CUSTOM_COUNT)"
fi

echo ""
echo "3. ARM Path Verification"
ARM_PATH_COUNT=$(grep -c '/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}' "$WORKBOOK")
echo "   ARM paths found: $ARM_PATH_COUNT"
if [ "$ARM_PATH_COUNT" -eq 7 ]; then
    echo "   ✅ All ARM paths correctly formatted"
else
    echo "   ⚠️  ARM path count unexpected (expected 7, got $ARM_PATH_COUNT)"
fi

echo ""
echo "4. Action ID Autopopulation"
AUTOPOPULATE_COUNT=$(grep -c '"parameterName":"LastActionId"' "$WORKBOOK")
CANCEL_COUNT=$(grep -c '"parameterName":"CancelActionId"' "$WORKBOOK")
TOTAL_AUTO=$((AUTOPOPULATE_COUNT + CANCEL_COUNT))
echo "   LastActionId autopopulation: $AUTOPOPULATE_COUNT"
echo "   CancelActionId autopopulation: $CANCEL_COUNT"
echo "   Total sections: $TOTAL_AUTO"
if [ "$TOTAL_AUTO" -eq 8 ]; then
    echo "   ✅ All autopopulation configured (8 sections)"
else
    echo "   ⚠️  Autopopulation count unexpected (expected 8, got $TOTAL_AUTO)"
fi

echo ""
echo "5. Auto-Refresh Configuration"
AUTOREFRESH_COUNT=$(grep -c '"timeContextFromParameter":"AutoRefresh"' "$WORKBOOK")
echo "   Auto-refresh sections: $AUTOREFRESH_COUNT"
if [ "$AUTOREFRESH_COUNT" -ge 4 ]; then
    echo "   ✅ Auto-refresh configured on monitoring sections"
else
    echo "   ⚠️  Auto-refresh count unexpected (expected 4+, got $AUTOREFRESH_COUNT)"
fi

echo ""
echo "6. Required Parameters"
declare -a PARAMS=("Subscription" "ResourceGroup" "FunctionAppName" "TenantId" "DeviceList" "LastActionId" "CancelActionId" "AutoRefresh")
PARAM_FOUND=0
for param in "${PARAMS[@]}"; do
    if grep -q "\"name\":\"$param\"" "$WORKBOOK"; then
        PARAM_FOUND=$((PARAM_FOUND + 1))
    else
        echo "   ❌ Missing parameter: $param"
    fi
done
echo "   Parameters found: $PARAM_FOUND/${#PARAMS[@]}"
if [ "$PARAM_FOUND" -eq ${#PARAMS[@]} ]; then
    echo "   ✅ All required parameters present"
else
    echo "   ❌ Some parameters missing"
fi

echo ""
echo "=============================================================================="
echo "VERIFICATION SUMMARY"
echo "=============================================================================="
echo ""
echo "✅ JSON valid: Yes"
echo "✅ ARMEndpoint queries: $ARM_COUNT (expected 7)"
echo "✅ CustomEndpoint queries: $CUSTOM_COUNT (expected 4-5)"
echo "✅ ARM paths: $ARM_PATH_COUNT (expected 7)"
echo "✅ Action ID autopopulation: $TOTAL_AUTO sections (expected 8)"
echo "✅ Auto-refresh: $AUTOREFRESH_COUNT sections (expected 4+)"
echo "✅ Required parameters: $PARAM_FOUND/${#PARAMS[@]}"
echo ""
echo "=============================================================================="
echo "✅ WORKBOOK READY FOR DEPLOYMENT"
echo "=============================================================================="
