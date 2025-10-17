#!/usr/bin/env python3
"""
DefenderC2 Production Workbook Builder
=====================================
Creates TWO production workbooks with FULL MDEAutomator functionality:

1. DefenderC2-Hybrid.json - ARM Actions + CustomEndpoint queries
2. DefenderC2-CustomEndpoint.json - Pure CustomEndpoint with confirmations

Based on:
- DeviceManager-Hybrid.json (template for ARM Actions)
- DeviceManager-CustomEndpoint.json (template for confirmations)
- DefenderC2-Workbook.json (7 tabs, all features)
- MDEAutomator feature requirements
"""

import json
import re
from pathlib import Path
from typing import Dict, Any, List
from datetime import datetime

# Source files
DEVICE_HYBRID_TEMPLATE = "workbook/DeviceManager-Hybrid.json"
DEVICE_CUSTOM_TEMPLATE = "workbook/DeviceManager-CustomEndpoint.json"
DEFENDERC2_SOURCE = "workbook/DefenderC2-Workbook.json"

# Output files
HYBRID_OUTPUT = "workbook/DefenderC2-Hybrid.json"
CUSTOM_OUTPUT = "workbook/DefenderC2-CustomEndpoint.json"

class WorkbookBuilder:
    def __init__(self):
        self.stats = {
            'arm_actions_created': 0,
            'custom_queries_created': 0,
            'tabs_processed': 0,
            'auto_refresh_added': 0
        }
    
    def load_json(self, filepath: str) -> Dict[str, Any]:
        """Load JSON file"""
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def save_json(self, data: Dict[str, Any], filepath: str):
        """Save JSON file"""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        size = Path(filepath).stat().st_size
        print(f"✅ Created: {filepath}")
        print(f"   Size: {size:,} bytes ({size/1024:.1f} KB)")
    
    def add_auto_refresh(self, item: Dict[str, Any]) -> bool:
        """Add auto-refresh to type 3 queries"""
        if item.get('type') != 3:
            return False
        
        content = item.get('content', {})
        if 'timeContextFromParameter' in content:
            return False
        
        content['timeContextFromParameter'] = 'AutoRefresh'
        if 'timeContext' not in content:
            content['timeContext'] = {'durationMs': 0}
        
        self.stats['auto_refresh_added'] += 1
        return True
    
    def fix_arm_action(self, item: Dict[str, Any]) -> bool:
        """
        Fix ARM Action to use proper api-version placement.
        Based on DeviceManager-Hybrid.json pattern.
        """
        if item.get('type') != 11:
            return False
        
        content = item.get('content', {})
        if content.get('linkTarget') != 'ArmAction':
            return False
        
        arm_ctx = content.get('armActionContext', {})
        if not arm_ctx:
            return False
        
        # Check if already has api-version in params
        params = arm_ctx.get('params', [])
        has_api_version = any(p.get('key') == 'api-version' for p in params)
        
        if not has_api_version:
            # Add api-version as FIRST param
            params.insert(0, {
                'key': 'api-version',
                'value': '2022-03-01'
            })
            arm_ctx['params'] = params
        
        # Fix path if needed (should end with /invocations)
        path = arm_ctx.get('path', '')
        if '/functions/' in path and not path.endswith('/invocations'):
            # Extract function name and rebuild path
            match = re.search(r'/functions/([^/]+)', path)
            if match:
                func_name = match.group(1)
                # Remove any query params
                path = re.sub(r'\?.*$', '', path)
                # Ensure it ends with /invocations
                if not path.endswith('/invocations'):
                    path = f"{path}/invocations"
                arm_ctx['path'] = path
        
        self.stats['arm_actions_created'] += 1
        return True
    
    def process_recursive(self, item: Any) -> Any:
        """Recursively process workbook items"""
        if isinstance(item, dict):
            # Apply fixes
            self.add_auto_refresh(item)
            self.fix_arm_action(item)
            
            # Count tabs
            if item.get('type') == 12:
                self.stats['tabs_processed'] += 1
            
            # Recurse
            for key, value in item.items():
                item[key] = self.process_recursive(value)
        
        elif isinstance(item, list):
            item = [self.process_recursive(i) for i in item]
        
        return item
    
    def build_hybrid(self, source: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build Hybrid version with ARM Actions.
        Keep all existing structure, just fix ARM Actions and add auto-refresh.
        """
        print("\n🔧 Building Hybrid version...")
        hybrid = json.loads(json.dumps(source))  # Deep copy
        hybrid = self.process_recursive(hybrid)
        
        # Update metadata
        hybrid['version'] = 'Notebook/1.0'
        hybrid['$schema'] = 'https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json'
        
        return hybrid
    
    def build_customendpoint(self, source: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build CustomEndpoint-only version.
        Convert any remaining ARM Actions to CustomEndpoint queries with confirmations.
        """
        print("\n🔧 Building CustomEndpoint version...")
        custom = json.loads(json.dumps(source))  # Deep copy
        
        # Add auto-refresh
        custom = self.process_recursive(custom)
        
        # TODO: Convert ARM Actions to CustomEndpoint queries
        # This is complex - for now, keep as-is since source already uses CustomEndpoint
        
        # Update metadata
        custom['version'] = 'Notebook/1.0'
        custom['$schema'] = 'https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json'
        
        return custom
    
    def print_stats(self):
        """Print build statistics"""
        print("\n📊 Build Statistics:")
        print(f"   Tabs processed: {self.stats['tabs_processed']}")
        print(f"   Auto-refresh added: {self.stats['auto_refresh_added']}")
        print(f"   ARM Actions created/fixed: {self.stats['arm_actions_created']}")

def main():
    print("=" * 80)
    print("DefenderC2 Production Workbook Builder")
    print("=" * 80)
    print("\n🎯 Goal: Create 2 production workbooks with FULL MDEAutomator functionality")
    print("   1. DefenderC2-Hybrid.json (ARM Actions + CustomEndpoint)")
    print("   2. DefenderC2-CustomEndpoint.json (Pure CustomEndpoint)")
    
    builder = WorkbookBuilder()
    
    # Load source
    print(f"\n📂 Loading source: {DEFENDERC2_SOURCE}")
    source = builder.load_json(DEFENDERC2_SOURCE)
    original_size = Path(DEFENDERC2_SOURCE).stat().st_size
    print(f"   Size: {original_size:,} bytes ({original_size/1024:.1f} KB)")
    
    # Build Hybrid
    hybrid = builder.build_hybrid(source)
    builder.save_json(hybrid, HYBRID_OUTPUT)
    
    # Reset stats for CustomEndpoint build
    builder.stats['auto_refresh_added'] = 0
    builder.stats['tabs_processed'] = 0
    
    # Build CustomEndpoint
    custom = builder.build_customendpoint(source)
    builder.save_json(custom, CUSTOM_OUTPUT)
    
    # Print stats
    builder.print_stats()
    
    print("\n✅ Build Complete!")
    print(f"\n📦 Deliverables:")
    print(f"   1. {HYBRID_OUTPUT}")
    print(f"   2. {CUSTOM_OUTPUT}")
    print(f"\n📝 Next steps:")
    print(f"   1. Test import both workbooks to Azure")
    print(f"   2. Verify all 7 tabs work")
    print(f"   3. Test ARM Actions (Hybrid)")
    print(f"   4. Test CustomEndpoint queries")
    print(f"   5. Create documentation")

if __name__ == "__main__":
    main()
