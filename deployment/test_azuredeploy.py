#!/usr/bin/env python3
"""
Test script to validate the azuredeploy.json ARM template.
This script verifies that the listKeys function calls are complete
and properly formatted on lines 132 and 136.
"""

import json
import sys
import re


def test_json_validity():
    """Test that the JSON file is syntactically valid."""
    print("Testing JSON validity...")
    try:
        with open('azuredeploy.json', 'r') as f:
            template = json.load(f)
        print("  ✅ JSON is syntactically valid")
        return True, template
    except json.JSONDecodeError as e:
        print(f"  ❌ JSON syntax error: {e}")
        return False, None


def test_required_sections(template):
    """Test that all required ARM template sections are present."""
    print("\nTesting required sections...")
    required_sections = ['$schema', 'contentVersion', 'parameters', 'variables', 'resources', 'outputs']
    all_present = True
    for section in required_sections:
        if section in template:
            print(f"  ✅ Has required section: {section}")
        else:
            print(f"  ❌ Missing required section: {section}")
            all_present = False
    return all_present


def test_listkeys_function_calls(template):
    """Test that listKeys function calls are complete on lines 132 and 136."""
    print("\nTesting listKeys function calls...")
    
    # Get the function app resource (3rd resource)
    function_app = template['resources'][2]
    app_settings = function_app['properties']['siteConfig']['appSettings']
    
    # Settings to check
    settings_to_check = [
        'AzureWebJobsStorage',
        'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    ]
    
    all_complete = True
    for setting_name in settings_to_check:
        setting = next((s for s in app_settings if s['name'] == setting_name), None)
        if not setting:
            print(f"  ❌ Missing setting: {setting_name}")
            all_complete = False
            continue
        
        value = setting['value']
        
        # Check for required components of the listKeys call
        required_components = [
            ('listKeys function', 'listKeys('),
            ('resourceId function', 'resourceId('),
            ('Storage account resource type', "'Microsoft.Storage/storageAccounts'"),
            ('Storage account variable', "variables('storageAccountName')"),
            ('API version', "'2021-08-01'"),
            ('Keys array access', '.keys[0].value'),
            ('Proper closing', '.keys[0].value)')
        ]
        
        print(f"\n  Checking {setting_name}:")
        setting_complete = True
        for component_name, component_text in required_components:
            if component_text in value:
                print(f"    ✅ Has {component_name}")
            else:
                print(f"    ❌ Missing {component_name}")
                setting_complete = False
                all_complete = False
        
        # Verify the complete expected pattern
        expected_pattern = r"listKeys\(resourceId\('Microsoft\.Storage/storageAccounts',\s*variables\('storageAccountName'\)\),\s*'2021-08-01'\)\.keys\[0\]\.value"
        if re.search(expected_pattern, value):
            print(f"    ✅ Matches expected pattern for complete listKeys call")
        else:
            print(f"    ❌ Does not match expected pattern")
            setting_complete = False
            all_complete = False
        
        # Check that it's not truncated
        if '[...]' in value:
            print(f"    ❌ Contains truncation marker '[...]'")
            setting_complete = False
            all_complete = False
        else:
            print(f"    ✅ No truncation markers found")
    
    return all_complete


def test_connection_string_format(template):
    """Test that connection strings have the correct format."""
    print("\nTesting connection string format...")
    
    function_app = template['resources'][2]
    app_settings = function_app['properties']['siteConfig']['appSettings']
    
    settings_to_check = [
        'AzureWebJobsStorage',
        'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    ]
    
    all_valid = True
    for setting_name in settings_to_check:
        setting = next((s for s in app_settings if s['name'] == setting_name), None)
        if not setting:
            continue
        
        value = setting['value']
        
        # Check for required connection string components
        required_parts = [
            'DefaultEndpointsProtocol=https',
            'AccountName=',
            'EndpointSuffix=',
            'AccountKey='
        ]
        
        print(f"\n  Checking {setting_name}:")
        for part in required_parts:
            if part in value:
                print(f"    ✅ Has {part}")
            else:
                print(f"    ❌ Missing {part}")
                all_valid = False
    
    return all_valid


def main():
    """Run all tests."""
    print("=" * 70)
    print("AZURE DEPLOYMENT TEMPLATE VALIDATION")
    print("Testing: deployment/azuredeploy.json")
    print("=" * 70)
    
    # Run tests
    json_valid, template = test_json_validity()
    if not json_valid:
        print("\n❌ VALIDATION FAILED: JSON is not valid")
        sys.exit(1)
    
    sections_valid = test_required_sections(template)
    listkeys_valid = test_listkeys_function_calls(template)
    connection_string_valid = test_connection_string_format(template)
    
    # Summary
    print("\n" + "=" * 70)
    print("VALIDATION SUMMARY")
    print("=" * 70)
    
    all_tests = [
        ("JSON Syntax", json_valid),
        ("Required Sections", sections_valid),
        ("listKeys Function Calls", listkeys_valid),
        ("Connection String Format", connection_string_valid)
    ]
    
    all_passed = True
    for test_name, result in all_tests:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status}: {test_name}")
        if not result:
            all_passed = False
    
    print("=" * 70)
    
    if all_passed:
        print("\n✅✅✅ ALL TESTS PASSED ✅✅✅")
        print("\nThe azuredeploy.json template is:")
        print("  ✅ Syntactically valid")
        print("  ✅ Has complete listKeys function calls (lines 132 and 136)")
        print("  ✅ Ready for deployment to Azure")
        print("  ✅ Meets all acceptance criteria")
        return 0
    else:
        print("\n❌❌❌ SOME TESTS FAILED ❌❌❌")
        return 1


if __name__ == '__main__':
    sys.exit(main())
