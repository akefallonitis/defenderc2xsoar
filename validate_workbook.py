import json
import os

# Validate DefenderC2-Complete.json
workbook_path = 'workbook/DefenderC2-Complete.json'

try:
    with open(workbook_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print('✅ DefenderC2-Complete.json is valid JSON')
    print(f'   Size: {len(json.dumps(data))} bytes')
    print(f'   Parameters: {len(data.get("parameters", []))}')
    
    # Check for FunctionKey parameter
    params = data.get('parameters', [])
    has_funckey = any(p.get('name') == 'FunctionKey' for p in params)
    
    if has_funckey:
        print('✅ FunctionKey parameter found')
    else:
        print('❌ FunctionKey parameter NOT found')
    
    # Count ARM actions (Type 11 with linkTarget: ArmAction)
    items = data.get('items', [])
    arm_action_count = 0
    
    def count_arm_actions(items):
        count = 0
        for item in items:
            if isinstance(item, dict):
                if item.get('type') == 11:
                    content = item.get('content', {})
                    links = content.get('links', [])
                    for link in links:
                        if link.get('linkTarget') == 'ArmAction':
                            count += 1
                
                # Check nested items
                if 'items' in item:
                    count += count_arm_actions(item['items'])
        return count
    
    arm_action_count = count_arm_actions(items)
    print(f'✅ ARM Actions found: {arm_action_count}')
    
    print('\n✅ Workbook validation successful!')
    
except json.JSONDecodeError as e:
    print(f'❌ JSON validation failed: {e}')
    exit(1)
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
