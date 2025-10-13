#!/usr/bin/env python3
"""
Fix CustomEndpoint criteriaData to prevent infinite refresh loops.

ROOT CAUSE: CustomEndpoint parameters reference {FunctionAppName} in criteriaData,
which creates circular dependency because {FunctionAppName} is derived from {FunctionApp}.

FIX: Change criteriaData to reference {FunctionApp} instead of {FunctionAppName}.
This ensures proper evaluation order:
  {FunctionApp} selected → CustomEndpoint evaluates → {FunctionAppName} populated

This is the same pattern we used to fix ARM actions.
"""

import json
import sys
from pathlib import Path


def fix_customendpoint_criteria(workbook_data):
    """Fix criteriaData in all CustomEndpoint parameters (Type 2 with queryType 10)"""
    changes = []
    
    def process_node(node, path=""):
        """Recursively process all nodes in the workbook"""
        nonlocal changes
        
        if isinstance(node, dict):
            # Check if this is a parameter with CustomEndpoint query
            # Type 2 = Dropdown, queryType 10 = CustomEndpoint
            if node.get("queryType") == 10 and "criteriaData" in node:
                name = node.get("name", "unnamed")
                criteria = node.get("criteriaData", [])
                
                # Find and replace {FunctionAppName} with {FunctionApp}
                new_criteria = []
                modified = False
                
                for criterion in criteria:
                    if criterion.get("value") == "{FunctionAppName}":
                        # Replace with {FunctionApp}
                        new_criteria.append({
                            "criterionType": "param",
                            "value": "{FunctionApp}"
                        })
                        changes.append(f"Changed {{FunctionAppName}} → {{FunctionApp}} in criteriaData for parameter '{name}' at {path}")
                        modified = True
                    else:
                        new_criteria.append(criterion)
                
                if modified:
                    node["criteriaData"] = new_criteria
            
            # Recursively process all nested structures
            for key, value in node.items():
                if key in ["content", "items", "parameters"]:
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
        print("Usage: python3 fix_customendpoint_criteria.py <workbook.json>")
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
    print("🔧 Fixing CustomEndpoint criteriaData...")
    changes = fix_customendpoint_criteria(workbook_data)
    
    if changes:
        # Write back
        with open(workbook_path, 'w', encoding='utf-8') as f:
            json.dump(workbook_data, f, indent=2, ensure_ascii=False)
        
        # Print changes
        for change in changes:
            print(f"  {change}")
        
        print(f"\n✅ Applied {len(changes)} CustomEndpoint criteriaData fixes")
        print("   - Changed {FunctionAppName} → {FunctionApp} in criteriaData")
        print("\nThis prevents infinite refresh loops by breaking circular dependencies!")
    else:
        print("✅ No changes needed - CustomEndpoint criteriaData already correct")


if __name__ == "__main__":
    main()
