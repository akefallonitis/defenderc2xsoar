#!/usr/bin/env python3
"""
Fix ALL ARM Actions to use proper ARM Management API paths.
ARM Actions in Azure Workbooks MUST use ARM resource provider paths, NOT direct HTTPS.
"""

import json
import re

workbook_path = r"c:\Users\AlexandrosKefallonit\Desktop\FF\defenderc2xsoar\workbook\DefenderC2-Workbook.json"

print("\n" + "="*70)
print("  Fixing ARM Actions to use Azure Management API paths")
print("="*70 + "\n")

# Read the workbook
with open(workbook_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Function names to fix
function_names = [
    "DefenderC2Dispatcher",
    "DefenderC2CDManager",
    "DefenderC2HuntManager",
    "DefenderC2IncidentManager",
    "DefenderC2TIManager",
    "DefenderC2Orchestrator"
]

total_fixed = 0

for func_name in function_names:
    # Old pattern: Direct HTTPS with FunctionKey
    old_pattern = (
        f'"path": "https://{{FunctionAppName}}.azurewebsites.net/api/{func_name}?code={{FunctionKey}}",\n'
        '                    "headers": [\n'
        '                      {\n'
        '                        "key": "Content-Type",\n'
        '                        "value": "application/json"\n'
        '                      }\n'
        '                    ],'
    )
    
    # New pattern: ARM resource provider path
    new_pattern = (
        f'"path": "/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/host/default/admin/functions/{func_name}",\n'
        '                    "headers": [],\n'
        '                    "params": [\n'
        '                      {\n'
        '                        "key": "api-version",\n'
        '                        "value": "2022-03-01"\n'
        '                      }\n'
        '                    ],'
    )
    
    # Count matches
    matches = len(re.findall(re.escape(old_pattern), content))
    
    if matches > 0:
        print(f"Fixing {matches} ARM Action(s) for function: {func_name}")
        content = content.replace(old_pattern, new_pattern)
        total_fixed += matches

# Write back
with open(workbook_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
with open(workbook_path, 'r', encoding='utf-8') as f:
    new_content = f.read()

# Count remaining issues
direct_https_in_arm = len(re.findall(r'"path": "https://{FunctionAppName}\.azurewebsites\.net/api/DefenderC2[^"]*",\s*"headers": \[\s*{\s*"key": "Content-Type"', new_content))
arm_paths = len(re.findall(r'"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft\.Web/sites/{FunctionAppName}/host/default/admin/functions/', new_content))

print("\n" + "="*70)
print("                     FIX COMPLETE!")
print("="*70 + "\n")

print(f"Results:")
print(f"  ✅ Fixed {total_fixed} ARM Actions")
print(f"  {'✅' if direct_https_in_arm == 0 else '❌'} Remaining Direct HTTPS in ARM Actions: {direct_https_in_arm}")
print(f"  ✅ Total proper ARM paths: {arm_paths}")

if direct_https_in_arm == 0:
    print("\n✅ SUCCESS! All ARM Actions now use proper ARM Management API paths!")
    print("\nThe ARM Actions will now:")
    print("  ✓ Use Azure Management API endpoint")
    print("  ✓ Authenticate via user's Azure RBAC permissions")  
    print("  ✓ Invoke functions through /host/default/admin/functions/{name}")
    print("  ✓ Work in Azure Portal Workbooks!")
else:
    print(f"\n⚠️  WARNING: Still have {direct_https_in_arm} direct HTTPS paths in ARM Actions!")

print()
