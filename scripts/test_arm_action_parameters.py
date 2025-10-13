#!/usr/bin/env python3
"""
Test script to verify that all parameters used in ARM actions are marked as global.
This ensures ARM actions can access parameters from any workbook component.

Usage:
    python3 test_arm_action_parameters.py
"""

import json
import sys
import os
import re

def test_workbook_arm_parameters(file_path):
    """
    Test that all parameters used in ARM action bodies are marked as global.
    
    Returns:
        tuple: (bool success, list of issues)
    """
    if not os.path.exists(file_path):
        return False, [f"File not found: {file_path}"]
    
    with open(file_path, 'r') as f:
        workbook = json.load(f)
    
    # Find all parameters and their global status
    def find_params(obj):
        results = []
        if isinstance(obj, dict):
            if obj.get('version') == 'KqlParameterItem/1.0' and 'name' in obj:
                results.append({
                    'name': obj['name'],
                    'isGlobal': obj.get('isGlobal', False),
                    'queryType': obj.get('queryType', 'N/A')
                })
            for v in obj.values():
                results.extend(find_params(v))
        elif isinstance(obj, list):
            for item in obj:
                results.extend(find_params(item))
        return results
    
    # Find all ARM actions and extract parameter names from bodies
    def find_arm_action_params(obj):
        results = set()
        if isinstance(obj, dict):
            if 'armActionContext' in obj:
                ctx = obj['armActionContext']
                body = ctx.get('body', '')
                path = ctx.get('path', '')
                
                # Extract parameters from body
                if body:
                    params_in_body = re.findall(r'\{(\w+)\}', body)
                    results.update(params_in_body)
                
                # Extract parameters from path
                if path:
                    params_in_path = re.findall(r'\{(\w+)\}', path)
                    results.update(params_in_path)
            
            for v in obj.values():
                results.update(find_arm_action_params(v))
        elif isinstance(obj, list):
            for item in obj:
                results.update(find_arm_action_params(item))
        return results
    
    params = find_params(workbook)
    arm_params = find_arm_action_params(workbook)
    
    # Create a mapping of parameter name to global status
    param_dict = {p['name']: p for p in params}
    
    # Check that all ARM action parameters are global
    issues = []
    success = True
    
    print(f"\n{'='*80}")
    print(f"Testing: {os.path.basename(file_path)}")
    print(f"{'='*80}")
    
    print(f"\nParameters used in ARM actions: {len(arm_params)}")
    print(f"Parameters defined in workbook: {len(params)}")
    
    if not arm_params:
        print("\n⚠️  No ARM actions found in this workbook")
        return True, []
    
    print(f"\nChecking if ARM action parameters are global:")
    for param_name in sorted(arm_params):
        if param_name in param_dict:
            p = param_dict[param_name]
            if p['isGlobal']:
                print(f"  ✅ {param_name}: Global")
            else:
                print(f"  ❌ {param_name}: NOT GLOBAL (queryType: {p['queryType']})")
                issues.append(f"{param_name} is used in ARM actions but not marked as global")
                success = False
        else:
            print(f"  ⚠️  {param_name}: Not found in parameter definitions")
            # This might be OK if it's a system parameter or comes from elsewhere
    
    if success and arm_params:
        print(f"\n✅✅✅ ALL ARM ACTION PARAMETERS ARE GLOBAL ✅✅✅")
    elif issues:
        print(f"\n❌ FOUND {len(issues)} ISSUE(S)")
        for issue in issues:
            print(f"   - {issue}")
    
    return success, issues

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    
    files = [
        os.path.join(repo_root, 'workbook', 'DefenderC2-Workbook.json'),
        os.path.join(repo_root, 'workbook', 'FileOperations.workbook')
    ]
    
    print("\n" + "="*80)
    print("ARM Action Parameter Global Status Test")
    print("="*80)
    
    all_success = True
    all_issues = []
    
    for file_path in files:
        success, issues = test_workbook_arm_parameters(file_path)
        all_success = all_success and success
        all_issues.extend(issues)
    
    print("\n" + "="*80)
    if all_success:
        print("🎉 SUCCESS: All ARM action parameters are correctly marked as global!")
        print("="*80)
        return 0
    else:
        print(f"❌ FAILURE: Found {len(all_issues)} issue(s)")
        print("="*80)
        for issue in all_issues:
            print(f"  - {issue}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
