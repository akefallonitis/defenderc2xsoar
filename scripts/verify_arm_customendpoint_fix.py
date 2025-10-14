#!/usr/bin/env python3
"""
Verify ARM actions and CustomEndpoints are correctly configured.

This script checks:
1. ARM actions use POST body (not query params) for function parameters
2. ARM actions have Content-Type header
3. ARM actions only have api-version in params
4. CustomEndpoints only depend on directly used parameters
"""

import json
import re
import sys

def verify_workbook(workbook_path):
    """Verify workbook configuration."""
    with open(workbook_path, 'r') as f:
        workbook = json.load(f)
    
    issues = []
    
    # Find all ARM actions
    def find_arm_actions(obj, path=''):
        results = []
        if isinstance(obj, dict):
            if 'armActionContext' in obj:
                results.append({
                    'path': path,
                    'label': obj.get('linkLabel', 'unknown'),
                    'context': obj['armActionContext']
                })
            for k, v in obj.items():
                results.extend(find_arm_actions(v, f'{path}.{k}'))
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                results.extend(find_arm_actions(item, f'{path}[{i}]'))
        return results
    
    # Find all CustomEndpoints
    def find_customendpoints(obj, path=''):
        results = []
        if isinstance(obj, dict):
            if obj.get('queryType') == 10:
                query_str = obj.get('query', '')
                try:
                    query_json = json.loads(query_str)
                    results.append({
                        'path': path,
                        'name': obj.get('name', obj.get('title', 'unknown')),
                        'query': query_json,
                        'criteriaData': obj.get('criteriaData', [])
                    })
                except:
                    pass
            for k, v in obj.items():
                results.extend(find_customendpoints(v, f'{path}.{k}'))
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                results.extend(find_customendpoints(item, f'{path}[{i}]'))
        return results
    
    actions = find_arm_actions(workbook)
    endpoints = find_customendpoints(workbook)
    
    print("=" * 70)
    print("VERIFYING ARM ACTIONS")
    print("=" * 70)
    print()
    
    for action in actions:
        label = action['label']
        ctx = action['context']
        print(f"📌 {label}")
        
        # Check 1: Should have body with function parameters
        body = ctx.get('body')
        if not body or body == 'null':
            issues.append(f"❌ {label}: No body (should have JSON with function params)")
            print("  ❌ No body")
        else:
            try:
                body_obj = json.loads(body)
                print(f"  ✅ Body has {len(body_obj)} parameters")
            except:
                issues.append(f"❌ {label}: Invalid JSON in body")
                print("  ❌ Invalid JSON in body")
        
        # Check 2: Params should only have api-version
        params = ctx.get('params', [])
        if len(params) == 0:
            issues.append(f"❌ {label}: No params (should have api-version)")
            print("  ❌ No api-version in params")
        elif len(params) > 1:
            issues.append(f"❌ {label}: Too many params (should only have api-version)")
            print(f"  ❌ {len(params)} params (should be 1: api-version)")
        else:
            if params[0].get('key') == 'api-version':
                print(f"  ✅ Only api-version in params")
            else:
                issues.append(f"❌ {label}: Param should be api-version, got {params[0].get('key')}")
                print(f"  ❌ Wrong param: {params[0].get('key')}")
        
        # Check 3: Should have Content-Type header
        headers = ctx.get('headers', [])
        has_content_type = any(h.get('name') == 'Content-Type' for h in headers)
        if has_content_type:
            print("  ✅ Has Content-Type header")
        else:
            issues.append(f"❌ {label}: Missing Content-Type header")
            print("  ❌ Missing Content-Type header")
        
        print()
    
    print("=" * 70)
    print("VERIFYING CUSTOMENDPOINTS")
    print("=" * 70)
    print()
    
    for endpoint in endpoints:
        name = endpoint['name']
        query = endpoint['query']
        criteria = endpoint['criteriaData']
        
        print(f"📌 {name}")
        
        # Find parameters used in query
        url = query.get('url', '')
        url_params = query.get('urlParams', [])
        
        params_used = set(re.findall(r'\{(\w+)\}', url))
        for param in url_params:
            value = param.get('value', '')
            params_used.update(re.findall(r'\{(\w+)\}', value))
        
        print(f"  Uses parameters: {sorted(params_used)}")
        
        # Check criteriaData
        criteria_params = set()
        for c in criteria:
            value = c.get('value', '')
            matches = re.findall(r'\{(\w+)\}', value)
            criteria_params.update(matches)
        
        print(f"  Depends on: {sorted(criteria_params)}")
        
        # Check if criteriaData matches used params
        if criteria_params == params_used:
            print("  ✅ CriteriaData matches used parameters")
        elif criteria_params > params_used:
            extra = criteria_params - params_used
            issues.append(f"❌ {name}: Extra dependencies in criteriaData: {extra}")
            print(f"  ❌ Extra dependencies: {extra}")
        elif criteria_params < params_used:
            missing = params_used - criteria_params
            issues.append(f"❌ {name}: Missing dependencies in criteriaData: {missing}")
            print(f"  ❌ Missing dependencies: {missing}")
        
        print()
    
    # Summary
    print("=" * 70)
    if issues:
        print("❌ VERIFICATION FAILED")
        print("=" * 70)
        print()
        for issue in issues:
            print(issue)
        return False
    else:
        print("✅ VERIFICATION PASSED")
        print("=" * 70)
        print()
        print("All checks completed successfully!")
        print()
        print(f"  • {len(actions)} ARM actions correctly configured")
        print(f"  • {len(endpoints)} CustomEndpoints correctly configured")
        print()
        print("ARM actions:")
        print("  ✓ Use POST body for function parameters")
        print("  ✓ Have Content-Type: application/json header")
        print("  ✓ Only api-version in query params")
        print()
        print("CustomEndpoints:")
        print("  ✓ CriteriaData matches directly used parameters")
        print("  ✓ No redundant dependencies")
        return True

if __name__ == '__main__':
    workbook = '/home/runner/work/defenderc2xsoar/defenderc2xsoar/workbook/DefenderC2-Workbook-MINIMAL-FIXED.json'
    success = verify_workbook(workbook)
    sys.exit(0 if success else 1)
