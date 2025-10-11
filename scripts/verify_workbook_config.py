#!/usr/bin/env python3
"""
Verification script for DefenderC2 Workbook configuration.
Checks that all ARMEndpoint queries and ARM Actions have the required api-version parameter.

Usage:
    python3 verify_workbook_config.py [workbook_file]

If no file is specified, checks both DefenderC2-Workbook.json and FileOperations.workbook
"""

import json
import sys
import os

def verify_workbook(file_path):
    """Verify a single workbook file"""
    
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        return False
    
    try:
        with open(file_path, 'r') as f:
            workbook = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in {file_path}: {e}")
        return False
    
    print(f"\n{'='*80}")
    print(f"Verifying: {os.path.basename(file_path)}")
    print(f"{'='*80}")
    
    results = {
        'arm_endpoint_queries': {'total': 0, 'with_api_version': 0},
        'arm_actions': {'total': 0, 'with_api_version': 0},
        'device_params': {'total': 0, 'with_custom_endpoint': 0}
    }
    
    def check_object(obj):
        if isinstance(obj, dict):
            # Check ARMEndpoint queries
            if 'query' in obj and isinstance(obj['query'], str) and 'ARMEndpoint/1.0' in obj['query']:
                results['arm_endpoint_queries']['total'] += 1
                if 'api-version' in obj['query']:
                    results['arm_endpoint_queries']['with_api_version'] += 1
            
            # Check ARM Actions
            if 'armActionContext' in obj:
                results['arm_actions']['total'] += 1
                ctx = obj['armActionContext']
                params = ctx.get('params', [])
                if any(p.get('key') == 'api-version' or p.get('name') == 'api-version' for p in params):
                    results['arm_actions']['with_api_version'] += 1
            
            # Check device parameters
            if 'name' in obj and obj['name'] in ['DeviceList', 'IsolateDeviceIds', 'UnisolateDeviceIds', 'RestrictDeviceIds', 'ScanDeviceIds']:
                results['device_params']['total'] += 1
                query = obj.get('query', '')
                if obj.get('queryType') == 10 and 'CustomEndpoint/1.0' in query:
                    results['device_params']['with_custom_endpoint'] += 1
            
            for v in obj.values():
                check_object(v)
        elif isinstance(obj, list):
            for item in obj:
                check_object(item)
    
    check_object(workbook)
    
    # Print results
    all_pass = True
    
    if results['arm_endpoint_queries']['total'] > 0:
        total = results['arm_endpoint_queries']['total']
        with_api = results['arm_endpoint_queries']['with_api_version']
        status = "✅" if with_api == total else "❌"
        print(f"\n{status} ARMEndpoint Queries: {with_api}/{total} with api-version")
        if with_api < total:
            all_pass = False
    
    if results['arm_actions']['total'] > 0:
        total = results['arm_actions']['total']
        with_api = results['arm_actions']['with_api_version']
        status = "✅" if with_api == total else "❌"
        print(f"{status} ARM Actions: {with_api}/{total} with api-version")
        if with_api < total:
            all_pass = False
    
    if results['device_params']['total'] > 0:
        total = results['device_params']['total']
        with_ce = results['device_params']['with_custom_endpoint']
        status = "✅" if with_ce == total else "❌"
        print(f"{status} Device Parameters: {with_ce}/{total} with CustomEndpoint")
        if with_ce < total:
            all_pass = False
    
    if all_pass and (results['arm_endpoint_queries']['total'] > 0 or 
                     results['arm_actions']['total'] > 0 or 
                     results['device_params']['total'] > 0):
        print(f"\n✅✅✅ ALL CHECKS PASSED ✅✅✅")
    elif all_pass:
        print(f"\n⚠️  No ARMEndpoint/ARM Actions found in this workbook")
    else:
        print(f"\n❌ SOME CHECKS FAILED")
    
    print(f"{'='*80}\n")
    
    return all_pass

def main():
    if len(sys.argv) > 1:
        # Verify specified file
        files = sys.argv[1:]
    else:
        # Verify default workbooks
        script_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(script_dir)
        files = [
            os.path.join(repo_root, 'workbook', 'DefenderC2-Workbook.json'),
            os.path.join(repo_root, 'workbook', 'FileOperations.workbook')
        ]
    
    print("\n" + "="*80)
    print("DefenderC2 Workbook Configuration Verification")
    print("="*80)
    
    all_files_pass = True
    for file_path in files:
        if not verify_workbook(file_path):
            all_files_pass = False
    
    if all_files_pass:
        print("\n🎉 SUCCESS: All workbooks are correctly configured!")
        return 0
    else:
        print("\n❌ FAILURE: Some workbooks have configuration issues")
        return 1

if __name__ == '__main__':
    sys.exit(main())
