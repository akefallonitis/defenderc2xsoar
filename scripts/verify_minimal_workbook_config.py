#!/usr/bin/env python3
"""
Comprehensive verification of DefenderC2-Workbook-MINIMAL-FIXED.json configuration.

Checks:
1. Parameter auto-discovery patterns
2. CustomEndpoint query configuration
3. ARM action paths and criteriaData
4. Parameter waiting logic (value: null)
5. Consistency with Azure Workbook best practices
"""

import json
import sys

def verify_workbook(workbook_path):
    """Verify workbook configuration."""
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    errors = []
    warnings = []
    successes = []
    
    # Extract items
    items = workbook.get('items', [])
    
    # Find parameter block
    param_block = None
    for item in items:
        if item.get('type') == 9:  # Parameter block
            param_block = item
            break
    
    if not param_block:
        errors.append("No parameter block found!")
        return errors, warnings, successes
    
    params = param_block.get('content', {}).get('parameters', [])
    
    # Check 1: Auto-discovery parameters
    print("=" * 60)
    print("CHECK 1: Auto-Discovery Parameters")
    print("=" * 60)
    
    auto_discover_params = ['Subscription', 'ResourceGroup', 'FunctionAppName']
    for param_name in auto_discover_params:
        param = next((p for p in params if p.get('name') == param_name), None)
        if not param:
            errors.append(f"Missing auto-discovery parameter: {param_name}")
            continue
        
        query = param.get('query', '')
        criteria = param.get('criteriaData', [])
        
        # Check for correct projection pattern
        if f'project value = ' not in query:
            errors.append(f"{param_name}: Must use 'project value = field' pattern")
        else:
            successes.append(f"✓ {param_name}: Correct projection pattern")
        
        # Check criteriaData includes {FunctionApp}
        criteria_values = [c.get('value') for c in criteria]
        if '{FunctionApp}' not in criteria_values:
            errors.append(f"{param_name}: Missing {{FunctionApp}} in criteriaData")
        else:
            successes.append(f"✓ {param_name}: Has {{FunctionApp}} in criteriaData")
    
    # Check 2: CustomEndpoint DeviceList parameter
    print("\n" + "=" * 60)
    print("CHECK 2: CustomEndpoint DeviceList Parameter")
    print("=" * 60)
    
    device_list = next((p for p in params if p.get('name') == 'DeviceList'), None)
    if device_list:
        query_type = device_list.get('queryType')
        if query_type != 10:
            errors.append(f"DeviceList: queryType should be 10 (CustomEndpoint), got {query_type}")
        else:
            successes.append("✓ DeviceList: Correct queryType (10)")
        
        # Parse query JSON
        try:
            query_json = json.loads(device_list.get('query', '{}'))
            
            # Check version
            if query_json.get('version') != 'CustomEndpoint/1.0':
                errors.append(f"DeviceList: Wrong version: {query_json.get('version')}")
            else:
                successes.append("✓ DeviceList: Correct version (CustomEndpoint/1.0)")
            
            # Check method
            if query_json.get('method') != 'POST':
                errors.append(f"DeviceList: Should use POST method, got {query_json.get('method')}")
            else:
                successes.append("✓ DeviceList: Correct method (POST)")
            
            # Check body is null
            if query_json.get('body') is not None:
                errors.append("DeviceList: body should be null (use urlParams instead)")
            else:
                successes.append("✓ DeviceList: body is null (correct)")
            
            # Check urlParams exists
            url_params = query_json.get('urlParams', [])
            if not url_params:
                errors.append("DeviceList: Missing urlParams array")
            else:
                successes.append(f"✓ DeviceList: Has urlParams ({len(url_params)} params)")
            
            # Check URL has parameter substitution
            url = query_json.get('url', '')
            if '{FunctionAppName}' not in url:
                errors.append("DeviceList: URL missing {FunctionAppName} substitution")
            else:
                successes.append("✓ DeviceList: URL has {FunctionAppName} substitution")
        
        except json.JSONDecodeError:
            errors.append("DeviceList: Invalid JSON in query")
        
        # Check criteriaData
        criteria = device_list.get('criteriaData', [])
        required_criteria = ['{FunctionApp}', '{FunctionAppName}', '{TenantId}']
        criteria_values = [c.get('value') for c in criteria]
        
        for req in required_criteria:
            if req not in criteria_values:
                errors.append(f"DeviceList: Missing {req} in criteriaData")
            else:
                successes.append(f"✓ DeviceList: Has {req} in criteriaData")
        
        # Check value is null (waiting pattern)
        if device_list.get('value') is not None:
            warnings.append("DeviceList: value should be null to wait for parameters")
        else:
            successes.append("✓ DeviceList: value is null (waits for parameters)")
    
    else:
        errors.append("DeviceList parameter not found!")
    
    # Check 3: ARM Actions
    print("\n" + "=" * 60)
    print("CHECK 3: ARM Actions")
    print("=" * 60)
    
    arm_action_count = 0
    
    def check_arm_actions(obj):
        nonlocal arm_action_count
        if isinstance(obj, dict):
            if 'armActionContext' in obj and 'criteriaData' in obj:
                arm_action_count += 1
                arm_ctx = obj.get('armActionContext', {})
                criteria = obj.get('criteriaData', [])
                
                # Check path format
                path = arm_ctx.get('path', '')
                if not path.startswith('/subscriptions/'):
                    errors.append(f"ARM Action {arm_action_count}: Path should start with /subscriptions/")
                else:
                    successes.append(f"✓ ARM Action {arm_action_count}: Correct path format")
                
                # Check path has all required parameters
                required_path_params = ['{Subscription}', '{ResourceGroup}', '{FunctionAppName}']
                for param in required_path_params:
                    if param not in path:
                        errors.append(f"ARM Action {arm_action_count}: Path missing {param}")
                
                # Check criteriaData completeness
                criteria_values = [c.get('value') for c in criteria]
                required_criteria = ['{FunctionApp}', '{Subscription}', '{ResourceGroup}', '{FunctionAppName}']
                
                missing = [p for p in required_criteria if p not in criteria_values]
                if missing:
                    errors.append(f"ARM Action {arm_action_count}: Missing in criteriaData: {missing}")
                else:
                    successes.append(f"✓ ARM Action {arm_action_count}: Complete criteriaData ({len(criteria)} params)")
                
                # Check has required metadata
                if not arm_ctx.get('title'):
                    warnings.append(f"ARM Action {arm_action_count}: Missing 'title'")
                if not arm_ctx.get('description'):
                    warnings.append(f"ARM Action {arm_action_count}: Missing 'description'")
                if not arm_ctx.get('actionName'):
                    warnings.append(f"ARM Action {arm_action_count}: Missing 'actionName'")
                
                # Check linkIsContextBlade
                if not obj.get('linkIsContextBlade'):
                    warnings.append(f"ARM Action {arm_action_count}: Should have linkIsContextBlade: true")
            
            for v in obj.values():
                check_arm_actions(v)
        elif isinstance(obj, list):
            for item in obj:
                check_arm_actions(item)
    
    check_arm_actions(workbook)
    
    if arm_action_count == 0:
        errors.append("No ARM actions found!")
    else:
        successes.append(f"✓ Found {arm_action_count} ARM actions")
    
    # Check 4: Device Grid
    print("\n" + "=" * 60)
    print("CHECK 4: Device Grid Display")
    print("=" * 60)
    
    # Find grid (type 3 with queryType 10)
    grid = None
    for item in items:
        if item.get('type') == 3:
            content = item.get('content', {})
            if content.get('queryType') == 10:
                grid = item
                break
    
    if grid:
        content = grid.get('content', {})
        
        # Check queryType
        if content.get('queryType') == 10:
            successes.append("✓ Device Grid: Correct queryType (10)")
        else:
            errors.append(f"Device Grid: Wrong queryType: {content.get('queryType')}")
        
        # Check criteriaData
        criteria = content.get('criteriaData', [])
        criteria_values = [c.get('value') for c in criteria]
        required = ['{FunctionApp}', '{FunctionAppName}', '{TenantId}']
        
        for req in required:
            if req not in criteria_values:
                errors.append(f"Device Grid: Missing {req} in criteriaData")
            else:
                successes.append(f"✓ Device Grid: Has {req} in criteriaData")
    else:
        errors.append("Device Grid (type 3, queryType 10) not found!")
    
    return errors, warnings, successes

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 verify_minimal_workbook_config.py <workbook.json>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    errors, warnings, successes = verify_workbook(file_path)
    
    # Print summary
    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)
    
    if successes:
        print(f"\n✅ PASSED ({len(successes)} checks):")
        for success in successes:
            print(f"  {success}")
    
    if warnings:
        print(f"\n⚠️  WARNINGS ({len(warnings)}):")
        for warning in warnings:
            print(f"  {warning}")
    
    if errors:
        print(f"\n❌ ERRORS ({len(errors)}):")
        for error in errors:
            print(f"  {error}")
        print("\nWorkbook has configuration issues that need to be fixed!")
        sys.exit(1)
    else:
        print("\n✅ All checks passed! Workbook is properly configured.")
        sys.exit(0)
