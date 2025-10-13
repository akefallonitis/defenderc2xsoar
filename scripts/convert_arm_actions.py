#!/usr/bin/env python3
"""
Convert DefenderC2 Workbook ARM actions from POST body to query parameters.

This script converts all ARM action definitions from using JSON POST body to 
using URL query parameters, matching the pattern used by the working DeviceList parameter.
"""

import json
import re
import sys

def convert_body_to_params(arm_action):
    """Convert ARM action from POST body to query parameters."""
    if 'body' not in arm_action or not arm_action['body']:
        return arm_action
    
    try:
        # Parse the JSON body string
        body_str = arm_action['body']
        body_json = json.loads(body_str)
        
        # Get existing params or create new list
        params = arm_action.get('params', [])
        if not isinstance(params, list):
            params = []
        
        # Keep api-version param
        params = [p for p in params if p.get('key') == 'api-version']
        
        # Add body fields as query parameters
        for key, value in body_json.items():
            params.append({
                "key": key,
                "value": value
            })
        
        # Update ARM action
        arm_action['params'] = params
        arm_action['body'] = None
        arm_action['headers'] = []
        
    except (json.JSONDecodeError, KeyError, TypeError) as e:
        print(f"Warning: Could not parse body: {e}", file=sys.stderr)
    
    return arm_action

def process_workbook(file_path):
    """Process the workbook JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse JSON
    workbook = json.loads(content)
    
    conversions = 0
    
    # Recursively find and convert ARM actions
    def find_and_convert(obj, path=""):
        nonlocal conversions
        
        if isinstance(obj, dict):
            # Check if this is an ARM action
            if 'armActionContext' in obj:
                arm_ctx = obj['armActionContext']
                if arm_ctx.get('body') and arm_ctx['body'] not in [None, 'null', '']:
                    print(f"Converting ARM action at {path}")
                    print(f"  Body: {arm_ctx['body'][:80]}...")
                    convert_body_to_params(arm_ctx)
                    conversions += 1
            
            # Recurse into dict values
            for key, value in obj.items():
                find_and_convert(value, f"{path}.{key}")
        
        elif isinstance(obj, list):
            # Recurse into list items
            for i, item in enumerate(obj):
                find_and_convert(item, f"{path}[{i}]")
    
    find_and_convert(workbook)
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(workbook, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Converted {conversions} ARM actions from POST body to query parameters")
    return conversions

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 convert_arm_actions.py <workbook.json>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    conversions = process_workbook(file_path)
    
    if conversions > 0:
        print(f"\n🎯 Success! Modified {file_path}")
        print("   All ARM actions now use query parameters (matching working DeviceList pattern)")
    else:
        print(f"\n⚠️  No ARM actions found with POST body")
