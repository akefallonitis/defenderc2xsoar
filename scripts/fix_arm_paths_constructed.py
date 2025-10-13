#!/usr/bin/env python3
"""
Fix ARM action paths to use constructed path from text parameters.

ROOT CAUSE: ARM actions cannot use {FunctionApp} resource picker directly in path.
Azure ARM API requires path starting with '/subscriptions/...'

FIX: Construct full ARM path using text parameters:
/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{FunctionAppName}/functions/{FunctionName}/invocations

This allows proper parameter substitution in ARM action blade.
"""

import json
import sys
from pathlib import Path


def fix_arm_action_paths(workbook_data):
    """Fix ARM action paths to use constructed text parameter paths"""
    changes = []
    
    # Mapping of function endpoints
    function_endpoints = {
        "DefenderC2Dispatcher": "DefenderC2Dispatcher",
        "DefenderC2TIManager": "DefenderC2TIManager",
        "DefenderC2IncidentManager": "DefenderC2IncidentManager",
        "DefenderC2CDManager": "DefenderC2CDManager",
        "DefenderC2Orchestrator": "DefenderC2Orchestrator"
    }
    
    def process_node(node, path=""):
        """Recursively process all nodes"""
        nonlocal changes
        
        if isinstance(node, dict):
            # Check if this has armActionContext
            if "armActionContext" in node:
                arm_context = node["armActionContext"]
                current_path = arm_context.get("path", "")
                
                # Check if path uses {FunctionApp} pattern
                if current_path.startswith("{FunctionApp}/functions/"):
                    # Extract function name
                    function_name = None
                    for func in function_endpoints:
                        if f"/functions/{func}/invocations" in current_path:
                            function_name = func
                            break
                    
                    if function_name:
                        # Construct new path
                        new_path = f"/subscriptions/{{Subscription}}/resourceGroups/{{ResourceGroup}}/providers/Microsoft.Web/sites/{{FunctionAppName}}/functions/{function_name}/invocations"
                        arm_context["path"] = new_path
                        changes.append(f"Fixed ARM action path at {path}: {function_name}")
            
            # Recursively process all nested structures
            for key, value in node.items():
                new_path = f"{path}.{key}" if path else key
                process_node(value, new_path)
        
        elif isinstance(node, list):
            for i, item in enumerate(node):
                new_path = f"{path}[{i}]" if path else f"[{i}]"
                process_node(item, new_path)
    
    # Process entire workbook
    process_node(workbook_data)
    
    return changes


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 fix_arm_paths_constructed.py <workbook.json>")
        sys.exit(1)
    
    workbook_path = Path(sys.argv[1])
    
    if not workbook_path.exists():
        print(f"❌ Error: File not found: {workbook_path}")
        sys.exit(1)
    
    # Read workbook
    print(f"📖 Reading {workbook_path}...")
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook_data = json.load(f)
    
    # Fix paths
    print("🔧 Fixing ARM action paths...")
    changes = fix_arm_action_paths(workbook_data)
    
    if changes:
        # Write back
        with open(workbook_path, 'w', encoding='utf-8') as f:
            json.dump(workbook_data, f, indent=2, ensure_ascii=False)
        
        # Print changes
        for change in changes:
            print(f"  ✅ {change}")
        
        print(f"\n✅ Applied {len(changes)} ARM action path fixes")
        print("   Changed from: {FunctionApp}/functions/.../invocations")
        print("   Changed to:   /subscriptions/{Subscription}/.../sites/{FunctionAppName}/functions/.../invocations")
        print("\nThis uses text parameters that are properly substituted in ARM action blade!")
    else:
        print("✅ No changes needed - ARM action paths already correct")


if __name__ == "__main__":
    main()
