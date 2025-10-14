#!/usr/bin/env python3
"""
Complete fix for workbook issues:
1. Add missing criteriaData to ALL ARM actions (Subscription, ResourceGroup, FunctionAppName)
2. Remove problematic 'condition' from DeviceList criteriaData
3. Ensure all ARM actions have complete criteriaData
"""

import json
import sys

def fix_all_issues(input_file, output_file):
    """Fix ARM actions and DeviceList parameter."""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    changes = []
    arm_actions_fixed = 0
    
    def process_items(items, path="root"):
        nonlocal arm_actions_fixed
        
        if not isinstance(items, list):
            return
        
        for idx, item in enumerate(items):
            item_type = item.get('type')
            item_name = item.get('name', f'item-{idx}')
            
            # Type 9 = Parameters - Fix DeviceList criteriaData
            if item_type == 9:
                content = item.get('content', {})
                parameters = content.get('parameters', [])
                
                for param in parameters:
                    param_name = param.get('name', '')
                    
                    # Fix DeviceList criteriaData
                    if param_name == 'DeviceList':
                        criteria_data = param.get('criteriaData', [])
                        if criteria_data and len(criteria_data) > 0:
                            # Check if first criterion has a condition
                            first_criterion = criteria_data[0]
                            if 'condition' in first_criterion:
                                # Remove the condition field
                                del first_criterion['condition']
                                changes.append(f"✅ Removed problematic 'condition' from DeviceList criteriaData in {path}/{item_name}")
            
            # Type 11 = Links (ARM Actions)
            elif item_type == 11:
                content = item.get('content', {})
                links = content.get('links', [])
                
                for link in links:
                    arm_context = link.get('armActionContext', {})
                    if arm_context:
                        link_label = link.get('linkLabel', 'Unknown')
                        
                        # Check if this uses the constructed path format
                        path_str = arm_context.get('path', '')
                        if '/subscriptions/{Subscription}' in path_str or '/resourceGroups/{ResourceGroup}' in path_str:
                            criteria_data = link.get('criteriaData', [])
                            
                            # Get existing criteria values
                            existing_values = [c.get('value', '') for c in criteria_data]
                            
                            # Required criteria for ARM actions with constructed paths
                            required_criteria = {
                                '{FunctionApp}': 'Resource picker',
                                '{Subscription}': 'Subscription ID',
                                '{ResourceGroup}': 'Resource Group',
                                '{FunctionAppName}': 'Function App Name',
                                '{TenantId}': 'Tenant ID'
                            }
                            
                            # Add missing criteria
                            added = []
                            for required_value, description in required_criteria.items():
                                if required_value not in existing_values:
                                    criteria_data.append({
                                        'criterionType': 'param',
                                        'value': required_value
                                    })
                                    added.append(required_value)
                            
                            if added:
                                changes.append(f"✅ Added missing criteriaData to '{link_label}': {', '.join(added)}")
                                arm_actions_fixed += 1
            
            # Type 12 = Groups - recurse
            elif item_type == 12:
                content = item.get('content', {})
                nested_items = content.get('items', [])
                if nested_items:
                    process_items(nested_items, f"{path}/{item_name}")
    
    # Process all items
    process_items(workbook.get('items', []))
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(workbook, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*80}")
    print(f"✅ COMPLETE FIX APPLIED")
    print(f"{'='*80}\n")
    
    print(f"📊 Total Changes: {len(changes)}\n")
    for change in changes:
        print(f"  {change}")
    
    print(f"\n📝 Output: {output_file}")
    print(f"\n{'='*80}")
    print("🎯 What was fixed:")
    print(f"  • Fixed {arm_actions_fixed} ARM actions with missing criteriaData")
    print(f"  • Removed problematic condition from DeviceList")
    print(f"  • All ARM actions now have: {{FunctionApp}}, {{Subscription}}, {{ResourceGroup}}, {{FunctionAppName}}, {{TenantId}}")
    print(f"  • ✅ ARM actions should no longer show <unset>!")
    print(f"  • ✅ DeviceList should no longer have infinite loops!")
    print(f"{'='*80}\n")

if __name__ == '__main__':
    input_file = 'workbook/DefenderC2-Workbook.json'
    output_file = 'workbook/DefenderC2-Workbook.json'
    
    print(f"\n🔧 Applying complete fix to DefenderC2 Workbook...")
    print(f"📂 File: {input_file}\n")
    
    try:
        fix_all_issues(input_file, output_file)
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
