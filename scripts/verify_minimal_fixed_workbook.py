#!/usr/bin/env python3
"""
Verify DefenderC2-Workbook-MINIMAL-FIXED.json configuration
"""

import json
import sys
from pathlib import Path

def verify_workbook():
    """Verify workbook configuration"""
    workbook_path = Path(__file__).parent.parent / 'workbook' / 'DefenderC2-Workbook-MINIMAL-FIXED.json'
    
    print("🔍 Verifying DefenderC2-Workbook-MINIMAL-FIXED.json\n")
    
    with open(workbook_path, 'r') as f:
        workbook = json.load(f)
    
    errors = []
    warnings = []
    
    # Verify parameters
    print("✅ Parameters Check:")
    params = workbook['items'][1]['content']['parameters']
    param_names = [p['name'] for p in params]
    required_params = ['FunctionApp', 'Subscription', 'ResourceGroup', 'FunctionAppName', 'TenantId', 'DeviceList']
    
    for param_name in required_params:
        if param_name not in param_names:
            errors.append(f"Missing parameter: {param_name}")
        else:
            param = [p for p in params if p['name'] == param_name][0]
            if not param.get('isGlobal'):
                warnings.append(f"Parameter {param_name} is not global")
            print(f"  ✓ {param_name}: global={param.get('isGlobal', False)}")
    
    # Verify DeviceList parameter
    print("\n✅ DeviceList Parameter Check:")
    device_list = [p for p in params if p['name'] == 'DeviceList'][0]
    if device_list['queryType'] != 10:
        errors.append(f"DeviceList queryType should be 10, got {device_list['queryType']}")
    else:
        print(f"  ✓ QueryType: {device_list['queryType']} (CustomEndpoint)")
    
    query = json.loads(device_list['query'])
    if query['method'] != 'POST':
        errors.append(f"DeviceList method should be POST, got {query['method']}")
    else:
        print(f"  ✓ Method: {query['method']}")
    
    if query['body'] is not None:
        errors.append(f"DeviceList body should be null, got {query['body']}")
    else:
        print(f"  ✓ Body: null")
    
    if 'urlParams' not in query or len(query['urlParams']) != 2:
        errors.append(f"DeviceList should have 2 urlParams")
    else:
        print(f"  ✓ URLParams: {len(query['urlParams'])} parameters")
    
    criteria_values = [c['value'] for c in device_list['criteriaData']]
    if set(criteria_values) != {'{FunctionApp}', '{FunctionAppName}', '{TenantId}'}:
        errors.append(f"DeviceList criteriaData incorrect: {criteria_values}")
    else:
        print(f"  ✓ CriteriaData: {', '.join(criteria_values)}")
    
    # Verify ARM actions
    print("\n✅ ARM Actions Check:")
    links = workbook['items'][3]['content']['links']
    arm_actions = [link for link in links if 'armActionContext' in link]
    
    for action in arm_actions:
        label = action['linkLabel']
        path = action['armActionContext']['path']
        
        # Check path uses {FunctionApp}
        if not path.startswith('{FunctionApp}/functions/'):
            errors.append(f"{label}: Path should start with '{{FunctionApp}}/functions/', got: {path}")
            print(f"  ✗ {label}: Path uses incorrect pattern")
        else:
            print(f"  ✓ {label}: Path uses {{FunctionApp}}")
        
        # Check body is null
        if action['armActionContext']['body'] is not None:
            errors.append(f"{label}: Body should be null")
        else:
            print(f"    ✓ Body: null")
        
        # Check params array
        params_list = action['armActionContext']['params']
        if not params_list or not any(p['key'] == 'api-version' for p in params_list):
            errors.append(f"{label}: Missing api-version in params")
        else:
            print(f"    ✓ Params: {len(params_list)} parameters")
        
        # Check criteriaData includes ALL required parameters (including derived ones)
        # Note: According to PR #86, criteriaData must include ALL parameters that the action
        # depends on, including derived parameters (Subscription, ResourceGroup, FunctionAppName).
        # This ensures Azure Workbook waits for all parameters to be resolved before executing.
        criteria_values = [c['value'] for c in action['criteriaData']]
        expected_criteria = {'{FunctionApp}', '{TenantId}', '{DeviceList}', 
                           '{Subscription}', '{ResourceGroup}', '{FunctionAppName}'}
        actual_criteria = set(criteria_values)
        
        if actual_criteria != expected_criteria:
            errors.append(f"{label}: criteriaData must include all 6 parameters (FunctionApp, TenantId, DeviceList, Subscription, ResourceGroup, FunctionAppName). Got: {criteria_values}")
            print(f"    ✗ CriteriaData incorrect: {', '.join(criteria_values)}")
        else:
            print(f"    ✓ CriteriaData: {', '.join(sorted(criteria_values))}")
    
    # Verify device grid display
    print("\n✅ Device Grid Display Check:")
    grid = workbook['items'][5]['content']
    if grid['queryType'] != 10:
        errors.append(f"Device grid queryType should be 10, got {grid['queryType']}")
    else:
        print(f"  ✓ QueryType: {grid['queryType']} (CustomEndpoint)")
    
    grid_query = json.loads(grid['query'])
    if grid_query['method'] != 'POST':
        errors.append(f"Device grid method should be POST, got {grid_query['method']}")
    else:
        print(f"  ✓ Method: {grid_query['method']}")
    
    if grid_query['body'] is not None:
        errors.append(f"Device grid body should be null, got {grid_query['body']}")
    else:
        print(f"  ✓ Body: null")
    
    criteria_values = [c['value'] for c in grid['criteriaData']]
    if set(criteria_values) != {'{FunctionApp}', '{FunctionAppName}', '{TenantId}'}:
        errors.append(f"Device grid criteriaData incorrect: {criteria_values}")
    else:
        print(f"  ✓ CriteriaData: {', '.join(criteria_values)}")
    
    # Print summary
    print("\n" + "="*60)
    if errors:
        print("❌ VERIFICATION FAILED")
        print("\nErrors:")
        for error in errors:
            print(f"  - {error}")
    
    if warnings:
        print("\n⚠️  Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    
    if not errors:
        print("✅ VERIFICATION PASSED")
        print("\nAll checks completed successfully!")
        print("\nThe workbook is correctly configured with:")
        print("  • ARM action paths using {FunctionApp} directly")
        print("  • Complete criteriaData including all derived parameters")
        print("  • CustomEndpoint queries with urlParams (not body)")
        print("  • All parameters marked as global")
    
    print("="*60)
    
    return 0 if not errors else 1

if __name__ == '__main__':
    sys.exit(verify_workbook())
