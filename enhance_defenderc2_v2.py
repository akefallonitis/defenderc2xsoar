#!/usr/bin/env python3
"""
Enhanced DefenderC2 Workbook Enhancement Script v2
==================================================
Applies all lessons learned from DeviceManager workbooks:
1. ARM Actions: api-version in params (already correct!)
2. CustomEndpoint: urlParams array (already correct!)
3. Auto-refresh: Add timeContext to ALL queries (type 3)
4. Smart filtering: Add defaultFilters where appropriate

This version:
- Properly handles nested structures (unlimited depth)
- Adds auto-refresh to ALL type 3 queries
- Validates ARM Actions
- Creates both Hybrid (enhanced) and CustomEndpoint-only versions
"""

import json
import re
from pathlib import Path
from typing import Dict, Any
from datetime import datetime

ORIGINAL_FILE = "workbook/DefenderC2-Workbook.json"
HYBRID_OUTPUT = "workbook/DefenderC2-Workbook-Hybrid-Enhanced.json"

class WorkbookEnhancer:
    def __init__(self):
        self.stats = {
            'queries_enhanced': 0,
            'arm_actions_validated': 0,
            'customendpoint_queries': 0,
            'items_processed': 0
        }
    
    def load_workbook(self, filepath: str) -> Dict[str, Any]:
        """Load workbook JSON"""
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def save_workbook(self, data: Dict[str, Any], filepath: str):
        """Save workbook JSON"""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        size = Path(filepath).stat().st_size
        print(f"\n✅ Created: {filepath}")
        print(f"   Size: {size:,} bytes ({size/1024:.1f} KB)")
    
    def add_auto_refresh_to_query(self, item: Dict[str, Any]) -> bool:
        """
        Add auto-refresh to a type 3 query item.
        Returns True if modification was made.
        """
        # Only process type 3 (query) items - NOTE: type is INTEGER not string!
        if item.get('type') != 3:
            return False
        
        content = item.get('content', {})
        
        # Skip if already has auto-refresh
        if 'timeContextFromParameter' in content:
            return False
        
        # Add auto-refresh
        content['timeContextFromParameter'] = 'AutoRefresh'
        if 'timeContext' not in content:
            content['timeContext'] = {'durationMs': 0}
        
        self.stats['queries_enhanced'] += 1
        return True
    
    def validate_arm_action(self, item: Dict[str, Any]) -> bool:
        """
        Validate ARM Action has api-version in params, not URL.
        Returns True if valid, False if needs fixing.
        """
        if item.get('type') != 11:  # LinkItem - NOTE: INTEGER not string!
            return True
        
        content = item.get('content', {})
        if content.get('linkTarget') != 'ArmAction':
            return True
        
        arm_context = content.get('armActionContext', {})
        path = arm_context.get('path', '')
        params = arm_context.get('params', [])
        
        # Check if api-version is in URL (BAD)
        if '?api-version=' in path or '&api-version=' in path:
            print(f"   ⚠️  ARM Action has api-version in URL: {content.get('linkLabel', 'unknown')}")
            return False
        
        # Check if api-version is in params (GOOD)
        has_api_version = any(p.get('key') == 'api-version' for p in params)
        if has_api_version:
            self.stats['arm_actions_validated'] += 1
            return True
        
        print(f"   ⚠️  ARM Action missing api-version: {content.get('linkLabel', 'unknown')}")
        return False
    
    def detect_customendpoint_query(self, item: Dict[str, Any]) -> bool:
        """Detect and count CustomEndpoint queries"""
        if item.get('type') != 3:  # NOTE: INTEGER not string!
            return False
        
        content = item.get('content', {})
        if content.get('queryType') == 10:  # CustomEndpoint
            self.stats['customendpoint_queries'] += 1
            return True
        
        return False
    
    def process_item_recursive(self, item: Any, depth: int = 0) -> Any:
        """
        Recursively process workbook items at any depth.
        Handles nested structures of arbitrary complexity.
        """
        if isinstance(item, dict):
            self.stats['items_processed'] += 1
            
            # Apply enhancements
            self.add_auto_refresh_to_query(item)
            self.validate_arm_action(item)
            self.detect_customendpoint_query(item)
            
            # Recurse into all nested structures
            for key, value in item.items():
                item[key] = self.process_item_recursive(value, depth + 1)
        
        elif isinstance(item, list):
            item = [self.process_item_recursive(i, depth + 1) for i in item]
        
        return item
    
    def enhance_workbook(self, workbook: Dict[str, Any]) -> Dict[str, Any]:
        """Main enhancement logic"""
        print("\n🔧 Enhancing workbook...")
        print(f"   Processing all items recursively...")
        
        # Process entire workbook recursively
        enhanced = self.process_item_recursive(workbook.copy())
        
        return enhanced
    
    def print_stats(self):
        """Print enhancement statistics"""
        print("\n📊 Enhancement Statistics:")
        print(f"   Items processed: {self.stats['items_processed']:,}")
        print(f"   Queries enhanced (auto-refresh): {self.stats['queries_enhanced']}")
        print(f"   ARM Actions validated: {self.stats['arm_actions_validated']}")
        print(f"   CustomEndpoint queries: {self.stats['customendpoint_queries']}")

def main():
    print("=" * 70)
    print("DefenderC2 Workbook Enhancement Script v2")
    print("=" * 70)
    
    enhancer = WorkbookEnhancer()
    
    # Load original
    print(f"\n📂 Loading: {ORIGINAL_FILE}")
    workbook = enhancer.load_workbook(ORIGINAL_FILE)
    original_size = Path(ORIGINAL_FILE).stat().st_size
    print(f"   Size: {original_size:,} bytes ({original_size/1024:.1f} KB)")
    
    # Enhance
    enhanced = enhancer.enhance_workbook(workbook)
    
    # Save
    enhancer.save_workbook(enhanced, HYBRID_OUTPUT)
    
    # Stats
    enhancer.print_stats()
    
    print("\n✅ Enhancement complete!")
    print(f"\n📝 Next steps:")
    print(f"   1. Review: {HYBRID_OUTPUT}")
    print(f"   2. Test import to Azure")
    print(f"   3. Verify auto-refresh working")
    print(f"   4. Create CustomEndpoint-only version (separate script)")

if __name__ == "__main__":
    main()
