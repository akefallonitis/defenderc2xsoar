#!/usr/bin/env python3
"""
Validate DefenderC2 Workbook Reorganization
Ensures all critical fixes are in place and no regressions.
"""

import json
import sys
from pathlib import Path

def validate_workbook(workbook_path):
    """Validate the reorganized workbook structure"""
    
    print("="*70)
    print("DefenderC2 Workbook Reorganization Validator")
    print("="*70)
    
    with open(workbook_path, 'r') as f:
        wb = json.load(f)
    
    issues = []
    warnings = []
    
    # Test 1: DeviceList is global
    print("\n✓ Test 1: DeviceList is global parameter")
    params = wb['items'][1]['content']['parameters']
    device_list = next((p for p in params if p['name'] == 'DeviceList'), None)
    
    if not device_list:
        issues.append("❌ DeviceList parameter not found!")
    elif not device_list.get('isGlobal'):
        issues.append("❌ DeviceList is not global - INFINITE LOOP WILL OCCUR!")
    else:
        print("   ✅ DeviceList is global (isGlobal=true)")
    
    # Test 2: No duplicate device parameters
    print("\n✓ Test 2: No duplicate device parameters")
    duplicate_names = ['IsolateDeviceIds', 'UnisolateDeviceIds', 'RestrictDeviceIds', 
                      'ScanDeviceIds', 'DeviceIds']
    
    def find_duplicate_params(obj, path=""):
        found = []
        if isinstance(obj, dict):
            if obj.get('type') == 9:
                params = obj.get('content', {}).get('parameters', [])
                for p in params:
                    if p.get('name') in duplicate_names:
                        found.append((p['name'], path))
            for k, v in obj.items():
                found.extend(find_duplicate_params(v, f"{path}/{k}"))
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                found.extend(find_duplicate_params(item, f"{path}[{i}]"))
        return found
    
    duplicates = find_duplicate_params(wb)
    if duplicates:
        for name, path in duplicates:
            issues.append(f"❌ Duplicate parameter found: {name} at {path}")
    else:
        print("   ✅ No duplicate device parameters found")
    
    # Test 3: 8 tabs exist
    print("\n✓ Test 3: 8 tabs exist with proper structure")
    expected_tabs = ['overview', 'devices', 'threatintel', 'incidents', 
                     'detections', 'hunting', 'console', 'library']
    
    tab_groups = [item for item in wb['items'][3:] if item.get('type') in [0, 12]]
    tab_values = [item.get('conditionalVisibility', {}).get('value') for item in tab_groups]
    
    if len(tab_groups) != 8:
        warnings.append(f"⚠️  Expected 8 tabs, found {len(tab_groups)}")
    else:
        print(f"   ✅ Found 8 tab groups")
    
    for expected in expected_tabs:
        if expected not in tab_values:
            warnings.append(f"⚠️  Missing tab: {expected}")
    
    # Test 4: All device actions use {DeviceList}
    print("\n✓ Test 4: Device actions use {DeviceList}")
    content_str = json.dumps(wb)
    
    device_list_refs = content_str.count('{DeviceList}')
    old_refs = sum([
        content_str.count('{IsolateDeviceIds}'),
        content_str.count('{UnisolateDeviceIds}'),
        content_str.count('{RestrictDeviceIds}'),
        content_str.count('{ScanDeviceIds}')
    ])
    
    print(f"   ✅ {device_list_refs} references to {{DeviceList}}")
    
    if old_refs > 0:
        issues.append(f"❌ Found {old_refs} references to old device parameters")
    else:
        print(f"   ✅ 0 references to old device parameters")
    
    # Test 5: Global parameters are properly marked
    print("\n✓ Test 5: Required parameters are global")
    required_global = ['FunctionApp', 'Workspace', 'Subscription', 'ResourceGroup',
                      'FunctionAppName', 'TenantId', 'DeviceList', 'TimeRange']
    
    for param_name in required_global:
        param = next((p for p in params if p['name'] == param_name), None)
        if not param:
            warnings.append(f"⚠️  Missing parameter: {param_name}")
        elif not param.get('isGlobal'):
            issues.append(f"❌ Parameter {param_name} should be global")
        else:
            print(f"   ✅ {param_name} is global")
    
    # Test 6: ARM actions present
    print("\n✓ Test 6: ARM actions are present")
    
    def count_arm_actions(obj):
        count = 0
        if isinstance(obj, dict):
            if 'armActionContext' in obj:
                count += 1
            for v in obj.values():
                count += count_arm_actions(v)
        elif isinstance(obj, list):
            for item in obj:
                count += count_arm_actions(item)
        return count
    
    arm_count = count_arm_actions(wb)
    if arm_count == 0:
        warnings.append("⚠️  No ARM actions found")
    else:
        print(f"   ✅ {arm_count} ARM actions found")
    
    # Test 7: CustomEndpoint queries present
    print("\n✓ Test 7: CustomEndpoint queries are present")
    custom_endpoint_count = content_str.count('"queryType": 10')
    
    if custom_endpoint_count == 0:
        warnings.append("⚠️  No CustomEndpoint queries found")
    else:
        print(f"   ✅ {custom_endpoint_count} CustomEndpoint queries found")
    
    # Test 8: Tab navigation links
    print("\n✓ Test 8: Tab navigation links are correct")
    tab_links = wb['items'][2]
    if tab_links.get('type') != 10:
        issues.append("❌ Tab links item is not type 10 (LinkItem)")
    else:
        links = tab_links.get('content', {}).get('links', [])
        if len(links) != 8:
            warnings.append(f"⚠️  Expected 8 tab links, found {len(links)}")
        else:
            print(f"   ✅ 8 tab navigation links found")
    
    # Summary
    print("\n" + "="*70)
    print("VALIDATION SUMMARY")
    print("="*70)
    
    if issues:
        print("\n❌ CRITICAL ISSUES FOUND:")
        for issue in issues:
            print(f"   {issue}")
    
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"   {warning}")
    
    if not issues and not warnings:
        print("\n✅ ALL TESTS PASSED!")
        print("   - DeviceList is global (no infinite loops)")
        print("   - No duplicate device parameters")
        print("   - All 8 tabs present and configured")
        print("   - ARM actions and CustomEndpoint queries present")
        print("   - Proper parameter structure")
        print("\n🎉 Workbook is ready for deployment!")
        return 0
    elif not issues:
        print("\n✅ All critical tests passed (warnings only)")
        print("⚠️  Review warnings above before deployment")
        return 0
    else:
        print("\n❌ VALIDATION FAILED - Fix critical issues before deployment")
        return 1

if __name__ == "__main__":
    workbook_path = Path(__file__).parent.parent / "workbook" / "DefenderC2-Workbook.json"
    
    if not workbook_path.exists():
        print(f"❌ Workbook not found: {workbook_path}")
        sys.exit(1)
    
    exit_code = validate_workbook(workbook_path)
    sys.exit(exit_code)
