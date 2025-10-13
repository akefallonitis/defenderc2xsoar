#!/usr/bin/env python3
"""
Remove duplicate local device CustomEndpoint parameters and use global DeviceList instead.

ROOT CAUSE: Local parameters (IsolateDeviceIds, UnisolateDeviceIds, etc.) are trying
to call CustomEndpoint queries but getting stuck in loops because they can't properly
access global parameters in their criteriaData from local scope.

SOLUTION: Since global DeviceList already works and contains all devices, replace
local device parameters with simple references to the global DeviceList.

This eliminates redundant API calls and fixes the infinite loop issue.
"""

import json
import sys
from pathlib import Path


def fix_local_device_parameters(workbook_data):
    """Replace local device CustomEndpoint params with references to global DeviceList"""
    changes = []
    
    # List of parameter names to replace
    local_device_params = [
        "IsolateDeviceIds",
        "UnisolateDeviceIds", 
        "RestrictDeviceIds",
        "ScanDeviceIds"
    ]
    
    def process_node(node, path=""):
        """Recursively process all nodes"""
        nonlocal changes
        
        if isinstance(node, dict):
            # Check if this is a parameters array
            if "parameters" in node and isinstance(node["parameters"], list):
                new_params = []
                for param in node["parameters"]:
                    if isinstance(param, dict) and param.get("name") in local_device_params:
                        param_name = param.get("name")
                        # Replace with simple text parameter that references global DeviceList
                        new_param = {
                            "id": param.get("id"),
                            "version": "KqlParameterItem/1.0",
                            "name": param_name,
                            "label": "Select Device(s)",
                            "type": 1,  # Type 1 = Text
                            "isRequired": False,
                            "value": "{DeviceList}",  # Reference global parameter
                            "description": f"Uses devices selected in the global DeviceList parameter at the top of the workbook.",
                            "isHiddenWhenLocked": True  # Hide since it's just a reference
                        }
                        new_params.append(new_param)
                        changes.append(f"Replaced {param_name} with reference to {{DeviceList}} at {path}")
                    else:
                        new_params.append(param)
                
                node["parameters"] = new_params
            
            # Recursively process nested structures
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
        print("Usage: python3 remove_duplicate_device_params.py <workbook.json>")
        sys.exit(1)
    
    workbook_path = Path(sys.argv[1])
    
    if not workbook_path.exists():
        print(f"❌ Error: File not found: {workbook_path}")
        sys.exit(1)
    
    # Read workbook
    print(f"📖 Reading {workbook_path}...")
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook_data = json.load(f)
    
    # Fix parameters
    print("🔧 Replacing local device parameters with global DeviceList references...")
    changes = fix_local_device_parameters(workbook_data)
    
    if changes:
        # Write back
        with open(workbook_path, 'w', encoding='utf-8') as f:
            json.dump(workbook_data, f, indent=2, ensure_ascii=False)
        
        # Print changes
        for change in changes:
            print(f"  ✅ {change}")
        
        print(f"\n✅ Applied {len(changes)} fixes")
        print("\nLocal device parameters now reference the working global DeviceList!")
        print("This eliminates redundant API calls and fixes infinite loop issues.")
    else:
        print("✅ No changes needed - parameters already using global DeviceList")


if __name__ == "__main__":
    main()
