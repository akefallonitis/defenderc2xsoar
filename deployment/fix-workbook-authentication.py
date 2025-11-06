#!/usr/bin/env python3
"""
Fix Workbook CustomEndpoint Authentication
Adds FunctionKey parameter and updates all CustomEndpoint URLs with ?code={FunctionKey}
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime

def find_custom_endpoints(obj, path=""):
    """Recursively find all CustomEndpoint queries"""
    endpoints = []
    
    if isinstance(obj, dict):
        # Check if this is a CustomEndpoint query
        if obj.get("version") == "CustomEndpoint/1.0" and "url" in obj:
            endpoints.append((path, obj))
        
        # Recurse into nested dictionaries
        for key, value in obj.items():
            new_path = f"{path}.{key}" if path else key
            endpoints.extend(find_custom_endpoints(value, new_path))
    
    elif isinstance(obj, list):
        # Recurse into list items
        for i, item in enumerate(obj):
            new_path = f"{path}[{i}]"
            endpoints.extend(find_custom_endpoints(item, new_path))
    
    return endpoints

def add_function_key_param(workbook):
    """Add FunctionKey parameter to global parameters"""
    # Find global parameters section
    for item in workbook.get("items", []):
        if item.get("name") == "global-parameters":
            params = item.get("content", {}).get("parameters", [])
            
            # Check if FunctionKey already exists
            if any(p.get("name") == "FunctionKey" for p in params):
                print("ℹ️  FunctionKey parameter already exists")
                return False
            
            # Add FunctionKey parameter
            function_key_param = {
                "id": "function-key-param",
                "version": "KqlParameterItem/1.0",
                "name": "FunctionKey",
                "label": "🔑 Function Key",
                "type": 1,
                "isRequired": True,
                "isGlobal": True,
                "description": "Enter your Function App default host key (from deployment outputs or Azure Portal)",
                "value": ""
            }
            
            params.append(function_key_param)
            print("✅ FunctionKey parameter added")
            return True
    
    print("⚠️  Could not find global-parameters section")
    return False

def update_custom_endpoint_urls(obj):
    """Recursively update CustomEndpoint URLs to include function key"""
    updated_count = 0
    
    if isinstance(obj, dict):
        # Check if this is a query field with embedded JSON
        if "query" in obj and isinstance(obj["query"], str):
            try:
                # Try to parse the query JSON
                query_data = json.loads(obj["query"])
                
                if query_data.get("version") == "CustomEndpoint/1.0" and "url" in query_data:
                    url = query_data["url"]
                    
                    # Check if URL already has code parameter
                    if "code=" not in url and "?code=" not in url:
                        # Add code parameter
                        if "?" in url:
                            query_data["url"] = url + "&code={FunctionKey}"
                        else:
                            query_data["url"] = url + "?code={FunctionKey}"
                        
                        # Update the query field with modified JSON
                        obj["query"] = json.dumps(query_data, separators=(',', ': '))
                        updated_count += 1
                        print(f"  ✅ Updated: {url[:60]}...")
            except (json.JSONDecodeError, TypeError):
                pass
        
        # Recurse into nested objects
        for value in obj.values():
            if isinstance(value, (dict, list)):
                updated_count += update_custom_endpoint_urls(value)
    
    elif isinstance(obj, list):
        for item in obj:
            if isinstance(item, (dict, list)):
                updated_count += update_custom_endpoint_urls(item)
    
    return updated_count

def main():
    script_dir = Path(__file__).parent
    workbook_path = script_dir.parent / "workbook" / "DefenderC2-Workbook.json"
    
    print("🔧 DefenderC2 Workbook Authentication Fix")
    print()
    
    # Create backup
    backup_path = workbook_path.with_suffix(f".backup.{datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
    print(f"📁 Creating backup: {backup_path.name}")
    
    with open(workbook_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Load workbook
    print("📖 Reading workbook...")
    workbook = json.loads(content)
    
    # Add FunctionKey parameter
    print("🔍 Adding FunctionKey parameter...")
    param_added = add_function_key_param(workbook)
    
    # Update CustomEndpoint URLs
    print()
    print("🔄 Updating CustomEndpoint URLs...")
    updated_count = update_custom_endpoint_urls(workbook)
    
    print()
    print(f"📊 Summary: {updated_count} URLs updated")
    
    if updated_count > 0 or param_added:
        # Save updated workbook
        print()
        print("💾 Saving updated workbook...")
        with open(workbook_path, 'w', encoding='utf-8') as f:
            json.dump(workbook, f, indent=2, ensure_ascii=False)
        print("✅ Workbook saved successfully!")
        
        print()
        print("📝 Next Steps:")
        print("  1. Run: deployment\\update-workbook-in-arm.ps1")
        print("  2. Commit the updated workbook")
        print("  3. Deploy the ARM template")
        print("  4. Get function key:")
        print("     az deployment group show -g <rg> -n <deployment> --query properties.outputs.functionKey.value -o tsv")
        print("  5. Paste function key into workbook FunctionKey parameter")
    else:
        print()
        print("ℹ️  No updates needed")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
