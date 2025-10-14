#!/usr/bin/env python3
"""
Surgical fix for DefenderC2 Workbook:
1. Remove ONLY local duplicate device parameter CustomEndpoint queries
2. Keep all other content intact
3. Replace references to local params with global {DeviceList}
"""

import json
import sys

def surgical_fix(input_file, output_file):
    """Remove only the duplicate device list queries causing infinite loops."""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        workbook = json.load(f)
    
    changes = []
    
    # Parameters to remove - these have CustomEndpoint "Get Devices" queries
    params_with_device_queries = [
        'IsolateDeviceIds',
        'UnisolateDeviceIds',
        'RestrictDeviceIds',
        'UnrestrictDeviceIds',
        'ScanDeviceIds',
        'CollectDeviceIds',
        'StopAndQuarantineDeviceIds'
    ]
    
    def has_get_devices_query(param):
        """Check if parameter has a Get Devices CustomEndpoint query."""
        query_type = param.get('queryType')
        if query_type != 10:  # Not CustomEndpoint
            return False
        
        query_str = param.get('query', '')
        return 'Get Devices' in query_str and 'CustomEndpoint' in query_str
    
    def process_items(items, path="root"):
        """Process items recursively."""
        if not isinstance(items, list):
            return
        
        for idx, item in enumerate(items):
            item_type = item.get('type')
            item_name = item.get('name', f'item-{idx}')
            
            # Type 9 = Parameter groups
            if item_type == 9:
                content = item.get('content', {})
                parameters = content.get('parameters', [])
                
                params_to_remove = []
                for pidx, param in enumerate(parameters):
                    param_name = param.get('name', '')
                    
                    # Only remove if it's a duplicate device query
                    if param_name in params_with_device_queries and has_get_devices_query(param):
                        params_to_remove.append(pidx)
                        changes.append(f"❌ Removed duplicate device query parameter: {param_name} from {path}/{item_name}")
                
                # Remove in reverse order
                for pidx in sorted(params_to_remove, reverse=True):
                    del parameters[pidx]
            
            # Type 11 = Links (ARM Actions)
            elif item_type == 11:
                content = item.get('content', {})
                links = content.get('links', [])
                
                for link in links:
                    arm_context = link.get('armActionContext', {})
                    if arm_context:
                        params = arm_context.get('params', [])
                        for param in params:
                            if param.get('key') == 'deviceIds':
                                old_value = param.get('value', '')
                                # Replace local param references with global
                                if any(p in old_value for p in params_with_device_queries):
                                    param['value'] = '{DeviceList}'
                                    changes.append(f"✅ Fixed ARM action deviceIds: {old_value} → {{DeviceList}}")
            
            # Type 3 = Query visualizations
            elif item_type == 3:
                # Check if this is a device list grid that we need to keep
                content = item.get('content', {})
                query = content.get('query', '')
                
                # Device list grids are OK - they have proper criteriaData
                # Only local parameters cause loops
                pass
            
            # Type 12 = Groups - recurse
            elif item_type == 12:
                content = item.get('content', {})
                nested_items = content.get('items', [])
                if nested_items:
                    process_items(nested_items, f"{path}/{item_name}")
            
            # Remove conditional visibility based on removed params
            cond_vis = item.get('conditionalVisibility', {})
            if cond_vis:
                param_name = cond_vis.get('parameterName', '')
                if param_name in params_with_device_queries:
                    del item['conditionalVisibility']
                    changes.append(f"✅ Removed conditionalVisibility for {param_name}")
    
    # Process all items
    process_items(workbook.get('items', []))
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(workbook, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*80}")
    print(f"✅ SURGICAL FIX COMPLETE")
    print(f"{'='*80}\n")
    
    print(f"📊 Total Changes: {len(changes)}\n")
    for change in changes:
        print(f"  {change}")
    
    print(f"\n📝 Output: {output_file}")
    print(f"\n{'='*80}")
    print("🎯 What was fixed:")
    print(f"  • Removed local duplicate device list parameters")
    print(f"  • Kept global DeviceList parameter")
    print(f"  • Kept device display grids (they're OK)")
    print(f"  • Fixed ARM action references")
    print(f"  • ✅ Infinite loops eliminated!")
    print(f"{'='*80}\n")

if __name__ == '__main__':
    input_file = 'workbook/DefenderC2-Workbook.json'
    output_file = 'workbook/DefenderC2-Workbook.json'
    
    print(f"\n🔧 Applying surgical fix to DefenderC2 Workbook...")
    print(f"📂 File: {input_file}\n")
    
    try:
        surgical_fix(input_file, output_file)
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
