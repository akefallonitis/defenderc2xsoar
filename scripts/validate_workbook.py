#!/usr/bin/env python3
"""
DefenderC2 Workbook Validation Script
Validates workbook structure and configuration
"""

import json
import sys
import os
from pathlib import Path

def validate_json(filepath):
    """Validate JSON structure"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return True, data, None
    except json.JSONDecodeError as e:
        return False, None, f"Invalid JSON: {e}"
    except Exception as e:
        return False, None, f"Error reading file: {e}"

def check_version(wb):
    """Check workbook version"""
    version = wb.get('version', '')
    if version == 'Notebook/1.0':
        return True, "✅ Correct version: Notebook/1.0"
    else:
        return False, f"❌ Invalid version: {version}"

def check_parameters(wb):
    """Check global parameters"""
    required_params = [
        'FunctionApp',
        'Workspace', 
        'Subscription',
        'ResourceGroup',
        'FunctionAppName',
        'TenantId'
    ]
    
    params_item = None
    for item in wb.get('items', []):
        if item.get('name') == 'parameters - configuration':
            params_item = item
            break
    
    if not params_item:
        return False, "❌ No parameters section found"
    
    params = params_item.get('content', {}).get('parameters', [])
    param_names = [p['name'] for p in params]
    
    missing = [p for p in required_params if p not in param_names]
    if missing:
        return False, f"❌ Missing required parameters: {', '.join(missing)}"
    
    # Check if parameters are global
    global_params = [p['name'] for p in params if p.get('isGlobal', False)]
    non_global = [p for p in required_params if p not in global_params]
    if non_global:
        return False, f"❌ Parameters not set as global: {', '.join(non_global)}"
    
    return True, f"✅ All {len(required_params)} required parameters present and global"

def check_tabs(wb):
    """Check tab structure"""
    expected_tabs = [
        'device-manager',
        'threat-intel',
        'action-manager',
        'advanced-hunting',
        'incident-manager',
        'custom-detection',
        'live-response'
    ]
    
    tabs = []
    for item in wb.get('items', []):
        if item.get('type') == 12:  # Tab group
            name = item.get('name', '').replace('group - ', '')
            tabs.append(name)
    
    missing_tabs = [t for t in expected_tabs if t not in tabs]
    extra_tabs = [t for t in tabs if t not in expected_tabs]
    
    if missing_tabs:
        return False, f"❌ Missing tabs: {', '.join(missing_tabs)}"
    
    status = f"✅ All {len(expected_tabs)} tabs present"
    if extra_tabs:
        status += f" (+ {len(extra_tabs)} custom tabs)"
    
    return True, status

def check_customendpoint_queries(wb):
    """Check CustomEndpoint queries"""
    ce_queries = []
    auto_refresh = []
    
    for item in wb.get('items', []):
        if item.get('type') == 12:  # Tab
            group_items = item.get('content', {}).get('items', [])
            for sub_item in group_items:
                if sub_item.get('type') == 3:  # Query
                    content = sub_item.get('content', {})
                    if content.get('queryType') == 10:  # CustomEndpoint
                        ce_queries.append(sub_item.get('name'))
                        if sub_item.get('isAutoRefreshEnabled'):
                            auto_refresh.append(sub_item.get('name'))
    
    if not ce_queries:
        return False, "❌ No CustomEndpoint queries found"
    
    status = f"✅ {len(ce_queries)} CustomEndpoint queries found"
    status += f"\n   {len(auto_refresh)} with auto-refresh enabled"
    
    return True, status

def check_arm_actions(wb):
    """Check ARM actions"""
    arm_actions = []
    
    for item in wb.get('items', []):
        if item.get('type') == 12:  # Tab
            group_items = item.get('content', {}).get('items', [])
            for sub_item in group_items:
                if sub_item.get('type') == 11:  # Links
                    links = sub_item.get('content', {}).get('links', [])
                    for link in links:
                        if link.get('linkTarget') == 'ArmAction':
                            label = link.get('linkLabel', 'Unknown')
                            arm_actions.append(label)
    
    if not arm_actions:
        return False, "❌ No ARM actions found"
    
    status = f"✅ {len(arm_actions)} ARM actions found"
    return True, status

def check_click_to_select(wb):
    """Check click-to-select formatters"""
    formatters = []
    
    for item in wb.get('items', []):
        if item.get('type') == 12:  # Tab
            group_items = item.get('content', {}).get('items', [])
            for sub_item in group_items:
                if sub_item.get('type') == 3:  # Query
                    grid = sub_item.get('content', {}).get('gridSettings', {})
                    fmts = grid.get('formatters', [])
                    for fmt in fmts:
                        if fmt.get('formatter') == 7:  # Link formatter
                            target_param = fmt.get('formatOptions', {}).get('parameterName')
                            if target_param:
                                formatters.append({
                                    'query': sub_item.get('name'),
                                    'column': fmt.get('columnMatch'),
                                    'parameter': target_param
                                })
    
    if not formatters:
        return False, "❌ No click-to-select formatters found"
    
    status = f"✅ {len(formatters)} click-to-select formatters found"
    for fmt in formatters:
        status += f"\n   {fmt['query']}.{fmt['column']} → {fmt['parameter']}"
    
    return True, status

def check_conditional_visibility(wb):
    """Check conditional visibility"""
    cv_items = []
    
    for item in wb.get('items', []):
        if item.get('type') == 12:  # Tab
            group_items = item.get('content', {}).get('items', [])
            for sub_item in group_items:
                cv = sub_item.get('conditionalVisibilities', [])
                if cv:
                    cv_items.append({
                        'item': sub_item.get('name'),
                        'conditions': len(cv)
                    })
    
    if not cv_items:
        return True, "⚠️  No conditional visibility (optional)"
    
    status = f"✅ {len(cv_items)} items with conditional visibility"
    return True, status

def main():
    """Main validation function"""
    print("=" * 60)
    print("DefenderC2 Workbook Validation Tool")
    print("=" * 60)
    print()
    
    # Find workbook file
    workbook_path = 'workbook/DefenderC2-Workbook.json'
    if not os.path.exists(workbook_path):
        workbook_path = '../workbook/DefenderC2-Workbook.json'
    if not os.path.exists(workbook_path):
        print("❌ Error: DefenderC2-Workbook.json not found")
        print("   Please run from repository root or scripts directory")
        return 1
    
    print(f"📄 Validating: {workbook_path}")
    print()
    
    # Validate JSON
    valid, wb, error = validate_json(workbook_path)
    if not valid:
        print(f"❌ JSON Validation Failed: {error}")
        return 1
    print("✅ Valid JSON structure")
    print()
    
    # Run checks
    checks = [
        ("Workbook Version", check_version),
        ("Global Parameters", check_parameters),
        ("Tab Structure", check_tabs),
        ("CustomEndpoint Queries", check_customendpoint_queries),
        ("ARM Actions", check_arm_actions),
        ("Click-to-Select", check_click_to_select),
        ("Conditional Visibility", check_conditional_visibility)
    ]
    
    passed = 0
    failed = 0
    warnings = 0
    
    for check_name, check_func in checks:
        print(f"Checking {check_name}...")
        success, message = check_func(wb)
        print(f"  {message}")
        print()
        
        if success:
            if "⚠️" in message:
                warnings += 1
            else:
                passed += 1
        else:
            failed += 1
    
    # Summary
    print("=" * 60)
    print("Validation Summary")
    print("=" * 60)
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    if warnings:
        print(f"⚠️  Warnings: {warnings}")
    print()
    
    # File info
    wb_json = json.dumps(wb)
    print(f"📊 Workbook Statistics:")
    print(f"   Size: {len(wb_json):,} bytes")
    print(f"   Lines: ~{len(json.dumps(wb, indent=2).split(chr(10))):,}")
    print(f"   Top-level items: {len(wb.get('items', []))}")
    print()
    
    if failed == 0:
        print("✅ Workbook validation PASSED")
        print("   Ready for deployment!")
        return 0
    else:
        print(f"❌ Workbook validation FAILED ({failed} issues)")
        print("   Please fix the issues above before deploying")
        return 1

if __name__ == "__main__":
    sys.exit(main())
