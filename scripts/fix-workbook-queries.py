#!/usr/bin/env python3
"""
Fix all CustomEndpoint queries in DefenderC2-Workbook.json to use urlParams instead of body.

This script converts queries from:
  - method: POST with body: {"action":"...", "tenantId":"..."}
To:
  - method: POST with urlParams: [{"key":"action","value":"..."},{"key":"tenantId","value":"..."}]

The function reads query parameters from $Request.Query, so they must be in URL params, not body.
"""

import json
import re
import sys

def parse_body_params(body_str):
    """Extract parameters from body JSON string."""
    try:
        # The body is double-escaped JSON string
        # First unescape the outer quotes
        body_str = body_str.replace('\\"', '"')
        body_json = json.loads(body_str)
        return body_json
    except:
        print(f"Warning: Could not parse body: {body_str[:100]}")
        return {}

def convert_query_to_urlparams(query_str):
    """Convert a CustomEndpoint query from body-based to urlParams-based."""
    try:
        query_obj = json.loads(query_str)
        
        # Check if it's a CustomEndpoint query with body
        if query_obj.get('version') != 'CustomEndpoint/1.0':
            return query_str
        
        # If already has urlParams, skip
        if 'urlParams' in query_obj and query_obj['urlParams']:
            print(f"  ✓ Already has urlParams, skipping")
            return query_str
        
        # Get the body
        body = query_obj.get('body')
        if not body:
            print(f"  ⚠️  No body found, skipping")
            return query_str
        
        # Parse body parameters
        params = parse_body_params(body)
        if not params:
            print(f"  ⚠️  Could not parse body parameters, skipping")
            return query_str
        
        # Convert to urlParams array
        url_params = []
        for key, value in params.items():
            url_params.append({
                "key": key,
                "value": value
            })
        
        # Update query object
        query_obj['urlParams'] = url_params
        query_obj['body'] = None  # Clear body
        query_obj['data'] = None
        query_obj['headers'] = []  # Clear headers
        
        # Remove ?code= from URL if present (not needed for anonymous)
        url = query_obj.get('url', '')
        if '?code=' in url:
            url = url.split('?code=')[0]
            query_obj['url'] = url
        
        # Return as JSON string
        return json.dumps(query_obj, separators=(',', ':'))
        
    except Exception as e:
        print(f"  ❌ Error converting query: {e}")
        return query_str

def fix_workbook(file_path):
    """Fix all CustomEndpoint queries in workbook."""
    print(f"📖 Reading workbook: {file_path}")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find all CustomEndpoint queries
    # The query JSON string is escaped and can span multiple lines or be on one line
    pattern = r'"query":\s*"(\{(?:[^"\\]|\\.)*?CustomEndpoint/1\.0(?:[^"\\]|\\.)*?\})"'
    matches = list(re.finditer(pattern, content, re.DOTALL))
    
    print(f"\n🔍 Found {len(matches)} CustomEndpoint queries\n")
    
    fixed_count = 0
    skipped_count = 0
    
    # Process each match
    for i, match in enumerate(matches, 1):
        query_str = match.group(1)
        # Unescape the JSON string
        query_str_unescaped = query_str.replace('\\"', '"').replace('\\\\', '\\')
        
        print(f"Query {i}/{len(matches)}:")
        
        # Try to get action/function name for display
        try:
            q = json.loads(query_str_unescaped)
            url = q.get('url', '')
            body = q.get('body', '')
            func_name = url.split('/api/')[-1] if '/api/' in url else 'unknown'
            
            # Try to extract action from body
            if body and 'action' in body:
                action_match = re.search(r'"action":"([^"]+)"', body.replace('\\"', '"'))
                if action_match:
                    action = action_match.group(1)
                    print(f"  🎯 {func_name} - {action}")
                else:
                    print(f"  🎯 {func_name}")
            elif body and 'Function' in body:
                func_match = re.search(r'"Function":"([^"]+)"', body.replace('\\"', '"'))
                if func_match:
                    func = func_match.group(1)
                    print(f"  🎯 {func_name} - {func}")
                else:
                    print(f"  🎯 {func_name}")
            else:
                print(f"  🎯 {func_name}")
        except:
            print(f"  🎯 Query {i}")
        
        # Convert query
        new_query_str = convert_query_to_urlparams(query_str_unescaped)
        
        if new_query_str != query_str_unescaped:
            # Escape for JSON
            new_query_str_escaped = new_query_str.replace('\\', '\\\\').replace('"', '\\"')
            
            # Replace in content
            old_pattern = '"query": "' + re.escape(query_str) + '"'
            new_replacement = '"query": "' + new_query_str_escaped + '"'
            
            content = content.replace(
                '"query": "' + query_str + '"',
                '"query": "' + new_query_str_escaped + '"'
            )
            
            print(f"  ✅ Converted to urlParams\n")
            fixed_count += 1
        else:
            print(f"  ⏭️  Skipped\n")
            skipped_count += 1
    
    # Write back
    print(f"💾 Writing updated workbook...")
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"\n" + "="*80)
    print(f"✨ COMPLETE!")
    print(f"="*80)
    print(f"✅ Fixed: {fixed_count} queries")
    print(f"⏭️  Skipped: {skipped_count} queries (already correct or no body)")
    print(f"📊 Total: {len(matches)} queries processed")
    print(f"\n💡 All queries now use urlParams format for anonymous authentication")

if __name__ == '__main__':
    file_path = '/workspaces/defenderc2xsoar/workbook/DefenderC2-Workbook.json'
    fix_workbook(file_path)
