#!/usr/bin/env python3
"""
Fix ARM actions in DefenderC2-Workbook-MINIMAL-FIXED.json to match the correct pattern.

Based on the working main workbook and Azure Sentinel best practices:
1. ARM actions must use full path: /subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/...
2. CriteriaData must include ALL parameters used in the action, including path parameters
3. This ensures proper parameter resolution before ARM action execution
"""

import json
import sys

def fix_arm_actions(workbook_path):
    """Fix ARM actions in the minimal workbook."""
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    fixes = 0
    
    def process_item(obj, path=""):
        nonlocal fixes
        
        if isinstance(obj, dict):
            # Check if this is an ARM action link
            if 'armActionContext' in obj and 'criteriaData' in obj:
                arm_ctx = obj['armActionContext']
                
                # Fix #1: Update path from {FunctionApp}/functions/... to full path
                if 'path' in arm_ctx:
                    current_path = arm_ctx['path']
                    
                    # If using the short {FunctionApp} path, convert to full path
                    if current_path.startswith('{FunctionApp}/functions/'):
                        # Extract function name from current path
                        function_part = current_path.replace('{FunctionApp}/functions/', '')
                        
                        # Build full ARM path
                        new_path = f"/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/functions/{function_part}"
                        
                        arm_ctx['path'] = new_path
                        fixes += 1
                        print(f"✓ Fixed ARM action path at {path}")
                        print(f"  OLD: {current_path}")
                        print(f"  NEW: {new_path}")
                
                # Fix #2: Update criteriaData to include all 6 parameters
                criteria = obj.get('criteriaData', [])
                
                # Required parameters for all ARM actions
                required_params = [
                    '{FunctionApp}',
                    '{TenantId}',
                    '{DeviceList}',  # or other device selection param
                    '{Subscription}',
                    '{ResourceGroup}',
                    '{FunctionAppName}'
                ]
                
                # Get current parameter values
                current_values = [c.get('value') for c in criteria]
                
                # Check if we need to add missing path parameters
                needs_update = False
                for param in ['{Subscription}', '{ResourceGroup}', '{FunctionAppName}']:
                    if param not in current_values:
                        needs_update = True
                        break
                
                if needs_update:
                    # Build new criteriaData with all required parameters
                    new_criteria = []
                    
                    # Keep existing parameters
                    for c in criteria:
                        new_criteria.append(c)
                    
                    # Add missing path parameters
                    for param in ['{Subscription}', '{ResourceGroup}', '{FunctionAppName}']:
                        if param not in current_values:
                            new_criteria.append({
                                "criterionType": "param",
                                "value": param
                            })
                    
                    obj['criteriaData'] = new_criteria
                    fixes += 1
                    print(f"✓ Updated criteriaData at {path}")
                    print(f"  OLD count: {len(criteria)}, NEW count: {len(new_criteria)}")
                    print(f"  Added: {[p for p in ['{Subscription}', '{ResourceGroup}', '{FunctionAppName}'] if p not in current_values]}")
                    print()
            
            # Recurse
            for key, value in obj.items():
                process_item(value, f"{path}.{key}")
        
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                process_item(item, f"{path}[{i}]")
    
    process_item(workbook)
    
    # Write back
    with open(workbook_path, 'w', encoding='utf-8') as f:
        json.dump(workbook, f, indent=2, ensure_ascii=False)
    
    return fixes

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 fix_minimal_workbook_arm_actions.py <workbook.json>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    fixes = fix_arm_actions(file_path)
    
    print(f"\n✅ Applied {fixes} fixes to ARM actions")
    print("\nChanges made:")
    print("  1. Updated ARM action paths to use full Azure Resource Manager format")
    print("     /subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/...")
    print("  2. Added missing parameters to criteriaData:")
    print("     - {Subscription}")
    print("     - {ResourceGroup}")
    print("     - {FunctionAppName}")
    print("\nThis ensures ARM actions wait for all parameters to populate before execution!")
