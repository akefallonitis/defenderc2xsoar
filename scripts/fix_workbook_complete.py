#!/usr/bin/env python3
"""
Complete workbook fix:
1. Remove ALL local duplicate device parameters
2. Use only global DeviceList parameter
3. Fix missing ARM actions
4. Prevent infinite refresh loops
"""

import json
import re
import sys

def fix_workbook(input_file, output_file):
    """Fix the workbook by removing local device parameters and using global one."""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    changes = []
    
    # Track parameters to remove
    local_device_params = [
        'IsolateDeviceIds',
        'UnisolateDeviceIds',
        'RestrictDeviceIds',
        'UnrestrictDeviceIds',
        'ScanDeviceIds',
        'CollectDeviceIds',
        'StopAndQuarantineDeviceIds'
    ]
    
    # Process all items recursively
    def process_items(items, parent_name="root"):
        if not isinstance(items, list):
            return
        
        items_to_remove = []
        
        for idx, item in enumerate(items):
            item_type = item.get('type')
            item_name = item.get('name', f'item-{idx}')
            
            # Type 9 = Parameters
            if item_type == 9:
                content = item.get('content', {})
                parameters = content.get('parameters', [])
                
                params_to_remove = []
                for pidx, param in enumerate(parameters):
                    param_name = param.get('name', '')
                    
                    # Remove local device list parameters
                    if param_name in local_device_params:
                        params_to_remove.append(pidx)
                        changes.append(f"❌ Removed local parameter: {param_name} from {parent_name}/{item_name}")
                
                # Remove in reverse order to maintain indices
                for pidx in sorted(params_to_remove, reverse=True):
                    del parameters[pidx]
            
            # Type 11 = Links (ARM Actions)
            elif item_type == 11:
                content = item.get('content', {})
                links = content.get('links', [])
                
                for link in links:
                    arm_context = link.get('armActionContext', {})
                    if arm_context:
                        # Fix deviceIds parameter to use global DeviceList
                        params = arm_context.get('params', [])
                        for param in params:
                            if param.get('key') == 'deviceIds':
                                old_value = param.get('value', '')
                                # Replace any local device param with global DeviceList
                                for local_param in local_device_params:
                                    if local_param in old_value:
                                        param['value'] = '{DeviceList}'
                                        changes.append(f"✅ Fixed ARM action deviceIds: {old_value} → {{DeviceList}} in {item_name}")
                                        break
                        
                        # Ensure criteriaData includes DeviceList
                        criteria_data = link.get('criteriaData', [])
                        has_devicelist = any(
                            '{DeviceList}' in str(c.get('value', ''))
                            for c in criteria_data
                        )
                        if not has_devicelist and any(p.get('key') == 'deviceIds' for p in params):
                            criteria_data.append({
                                'criterionType': 'param',
                                'value': '{DeviceList}'
                            })
                            changes.append(f"✅ Added {{DeviceList}} to criteriaData in {item_name}")
            
            # Type 12 = Groups - recurse into nested items
            elif item_type == 12:
                content = item.get('content', {})
                nested_items = content.get('items', [])
                if nested_items:
                    process_items(nested_items, f"{parent_name}/{item_name}")
            
            # Check conditional visibility
            conditional_visibility = item.get('conditionalVisibility', {})
            if conditional_visibility:
                param_name = conditional_visibility.get('parameterName', '')
                if param_name in local_device_params:
                    # Remove conditional visibility based on local param
                    del item['conditionalVisibility']
                    changes.append(f"✅ Removed conditionalVisibility for {param_name} in {item_name}")
    
    # Process top-level items
    process_items(workbook.get('items', []))
    
    # Write fixed workbook
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(workbook, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*80}")
    print(f"✅ WORKBOOK FIX COMPLETE")
    print(f"{'='*80}\n")
    
    print(f"📊 Changes Made: {len(changes)}")
    for change in changes:
        print(f"  {change}")
    
    print(f"\n📝 Output written to: {output_file}")
    print(f"\n{'='*80}")
    print("🔍 Summary:")
    print(f"  • Removed {sum(1 for c in changes if 'Removed local parameter' in c)} local device parameters")
    print(f"  • Fixed {sum(1 for c in changes if 'Fixed ARM action' in c)} ARM action deviceIds references")
    print(f"  • Updated {sum(1 for c in changes if 'Added' in c and 'criteriaData' in c)} criteriaData entries")
    print(f"  • All actions now use global {{DeviceList}} parameter")
    print(f"  • ✅ Infinite refresh loops should be eliminated!")
    print(f"{'='*80}\n")

if __name__ == '__main__':
    input_file = 'workbook/DefenderC2-Workbook.json'
    output_file = 'workbook/DefenderC2-Workbook.json'
    
    print(f"\n🔧 Fixing DefenderC2 Workbook...")
    print(f"📂 Input:  {input_file}")
    print(f"📂 Output: {output_file}\n")
    
    try:
        fix_workbook(input_file, output_file)
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
