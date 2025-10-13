#!/usr/bin/env python3
"""
Fix criteriaData in ARM actions to reference {FunctionApp} instead of old text parameters.
"""

import json
import sys

def fix_criteria_data(workbook_path):
    """Fix criteriaData arrays in ARM actions."""
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    fixes = 0
    
    def process_item(obj, path=""):
        nonlocal fixes
        
        if isinstance(obj, dict):
            # Check if this has an armActionContext with criteriaData
            if 'armActionContext' in obj and 'criteriaData' in obj:
                criteria = obj['criteriaData']
                if isinstance(criteria, list):
                    # Remove old parameter references
                    old_params = ['{Subscription}', '{ResourceGroup}', '{FunctionAppName}']
                    new_criteria = []
                    has_function_app = False
                    
                    for item in criteria:
                        if isinstance(item, dict) and item.get('value') in old_params:
                            # Skip old parameters
                            fixes += 1
                            print(f"  Removed {item.get('value')} from criteriaData at {path}")
                        else:
                            new_criteria.append(item)
                            if item.get('value') == '{FunctionApp}':
                                has_function_app = True
                    
                    # Add {FunctionApp} if not already present
                    if not has_function_app:
                        new_criteria.insert(0, {
                            "criterionType": "param",
                            "value": "{FunctionApp}"
                        })
                        fixes += 1
                        print(f"  Added {{FunctionApp}} to criteriaData at {path}")
                    
                    obj['criteriaData'] = new_criteria
            
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
        print("Usage: python3 fix_criteria_data.py <workbook.json>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    fixes = fix_criteria_data(file_path)
    
    print(f"\n✅ Applied {fixes} criteriaData fixes")
    print("   - Removed references to {Subscription}, {ResourceGroup}, {FunctionAppName}")
    print("   - Added {FunctionApp} to all ARM actions")
    print("\nThis ensures ARM actions refresh when FunctionApp parameter changes!")
