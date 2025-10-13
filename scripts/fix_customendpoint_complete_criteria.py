#!/usr/bin/env python3
"""
Fix CustomEndpoint criteriaData to include all required parameters.

ROOT CAUSE: CustomEndpoints use {FunctionAppName} and {TenantId} in their
URLs/urlParams, but criteriaData only has {FunctionApp}. This causes the
CustomEndpoint to execute before {FunctionAppName} and {TenantId} are populated,
leading to "stuck in refreshing" state.

FIX: Add {FunctionAppName} and {TenantId} to criteriaData for all CustomEndpoints
that use these parameters in their query URL or urlParams.

This ensures proper evaluation order:
  {FunctionApp} → {FunctionAppName} & {TenantId} → CustomEndpoint executes
"""

import json
import sys
from pathlib import Path
import re


def fix_customendpoint_complete_criteria(workbook_data):
    """Add missing parameters to CustomEndpoint criteriaData"""
    changes = []
    
    def process_node(node, path=""):
        """Recursively process all nodes"""
        nonlocal changes
        
        if isinstance(node, dict):
            # Check if this is a CustomEndpoint query (queryType 10)
            if node.get("queryType") == 10 and "query" in node:
                name = node.get("name", "unnamed")
                query_str = node.get("query", "")
                criteria = node.get("criteriaData", [])
                
                # Parse the query to see what parameters it uses
                uses_functionappname = "{FunctionAppName}" in query_str
                uses_tenantid = "{TenantId}" in query_str
                
                # Get current criteriaData values
                current_values = [c.get("value") for c in criteria if c.get("criterionType") == "param"]
                
                # Determine what needs to be added
                needs_update = False
                new_criteria = list(criteria)  # Copy existing
                
                # Ensure {FunctionApp} is first (if query uses {FunctionAppName})
                if uses_functionappname and "{FunctionApp}" not in current_values:
                    new_criteria.insert(0, {
                        "criterionType": "param",
                        "value": "{FunctionApp}"
                    })
                    needs_update = True
                    changes.append(f"Added {{FunctionApp}} to criteriaData for '{name}' at {path}")
                
                # Add {FunctionAppName} if used in query but not in criteriaData
                if uses_functionappname and "{FunctionAppName}" not in current_values:
                    # Insert after {FunctionApp}
                    insert_pos = 1 if "{FunctionApp}" in current_values or needs_update else 0
                    new_criteria.insert(insert_pos, {
                        "criterionType": "param",
                        "value": "{FunctionAppName}"
                    })
                    needs_update = True
                    changes.append(f"Added {{FunctionAppName}} to criteriaData for '{name}' at {path}")
                
                # Add {TenantId} if used in query but not in criteriaData
                if uses_tenantid and "{TenantId}" not in current_values:
                    new_criteria.append({
                        "criterionType": "param",
                        "value": "{TenantId}"
                    })
                    needs_update = True
                    changes.append(f"Added {{TenantId}} to criteriaData for '{name}' at {path}")
                
                if needs_update:
                    node["criteriaData"] = new_criteria
            
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
        print("Usage: python3 fix_customendpoint_complete_criteria.py <workbook.json>")
        sys.exit(1)
    
    workbook_path = Path(sys.argv[1])
    
    if not workbook_path.exists():
        print(f"❌ Error: File not found: {workbook_path}")
        sys.exit(1)
    
    # Read workbook
    print(f"📖 Reading {workbook_path}...")
    with open(workbook_path, 'r', encoding='utf-8') as f:
        workbook_data = json.load(f)
    
    # Fix criteriaData
    print("🔧 Fixing CustomEndpoint criteriaData to include all required parameters...")
    changes = fix_customendpoint_complete_criteria(workbook_data)
    
    if changes:
        # Write back
        with open(workbook_path, 'w', encoding='utf-8') as f:
            json.dump(workbook_data, f, indent=2, ensure_ascii=False)
        
        # Print changes
        for change in changes:
            print(f"  ✅ {change}")
        
        print(f"\n✅ Applied {len(changes)} CustomEndpoint criteriaData fixes")
        print("\nThis ensures CustomEndpoints wait for all required parameters before executing!")
    else:
        print("✅ No changes needed - CustomEndpoint criteriaData already complete")


if __name__ == "__main__":
    main()
