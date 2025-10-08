#!/usr/bin/env python3
"""
Comprehensive Workbook Deployment Verification Script

This script verifies that the workbooks are correctly configured with:
1. Auto-discovery functionality (FunctionAppName parameter)
2. Correct custom endpoint configuration
3. Auto-refresh settings where appropriate
4. ARM action endpoints with correct parameters
5. Proper deployment in ARM template
"""

import json
import sys
import base64
from typing import Dict, List, Tuple


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[32m'
    RED = '\033[31m'
    YELLOW = '\033[33m'
    BLUE = '\033[36m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def print_header(text: str):
    """Print a formatted header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'=' * 70}{Colors.RESET}")
    print(f"{Colors.BLUE}{Colors.BOLD}{text}{Colors.RESET}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'=' * 70}{Colors.RESET}\n")


def print_success(text: str):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {text}{Colors.RESET}")


def print_error(text: str):
    """Print error message"""
    print(f"{Colors.RED}❌ {text}{Colors.RESET}")


def print_info(text: str):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ️  {text}{Colors.RESET}")


def find_armendpoint_queries(obj, path="") -> List[Dict]:
    """Recursively find all ARMEndpoint queries in a workbook structure"""
    results = []
    
    if isinstance(obj, dict):
        # Check if this has a query field with ARMEndpoint
        if 'query' in obj:
            query = obj.get('query', '')
            if isinstance(query, str) and 'ARMEndpoint' in query:
                try:
                    query_obj = json.loads(query)
                    if query_obj.get('version') == 'ARMEndpoint/1.0':
                        results.append({
                            'path': path,
                            'query_obj': query_obj,
                            'parent': obj
                        })
                except:
                    pass
        
        # Recurse into dict values
        for key, value in obj.items():
            results.extend(find_armendpoint_queries(value, f"{path}.{key}"))
    
    elif isinstance(obj, list):
        # Recurse into list items
        for i, item in enumerate(obj):
            results.extend(find_armendpoint_queries(item, f"{path}[{i}]"))
    
    return results


def verify_functionappname_parameter(workbook: Dict, workbook_name: str) -> Tuple[bool, Dict]:
    """Verify FunctionAppName parameter exists and is correctly configured"""
    print(f"\n{Colors.BOLD}Checking FunctionAppName parameter in {workbook_name}...{Colors.RESET}")
    
    issues = []
    
    # Find parameters configuration
    for item in workbook.get('items', []):
        if item.get('type') == 9:  # parameters type
            params = item.get('content', {}).get('parameters', [])
            for param in params:
                if 'FunctionAppName' in param.get('name', ''):
                    print_success(f"Found FunctionAppName parameter")
                    
                    # Check if required
                    is_required = param.get('isRequired', False)
                    if is_required:
                        print_success(f"  Parameter is required: {is_required}")
                    else:
                        print_error(f"  Parameter should be required but is: {is_required}")
                        issues.append("FunctionAppName parameter is not required")
                    
                    # Check default value
                    default_value = param.get('value', 'N/A')
                    print_info(f"  Default value: {default_value}")
                    
                    # Check description
                    description = param.get('description', '')
                    if description:
                        print_success(f"  Has description")
                    else:
                        issues.append("FunctionAppName parameter missing description")
                    
                    return len(issues) == 0, {
                        'found': True,
                        'required': is_required,
                        'default': default_value,
                        'description': description,
                        'issues': issues
                    }
    
    print_error("FunctionAppName parameter not found")
    return False, {'found': False, 'issues': ['FunctionAppName parameter not found']}


def verify_custom_endpoints(workbook: Dict, workbook_name: str) -> Tuple[bool, Dict]:
    """Verify all custom endpoints use correct FunctionAppName pattern"""
    print(f"\n{Colors.BOLD}Checking custom endpoints in {workbook_name}...{Colors.RESET}")
    
    queries = find_armendpoint_queries(workbook)
    
    if not queries:
        print_error("No ARMEndpoint queries found")
        return False, {'queries': 0, 'issues': ['No ARMEndpoint queries found']}
    
    print_success(f"Found {len(queries)} ARMEndpoint queries")
    
    issues = []
    correct_endpoints = 0
    
    for i, q in enumerate(queries, 1):
        query_obj = q['query_obj']
        path = query_obj.get('path', '')
        method = query_obj.get('method', '')
        
        # Check if using FunctionAppName placeholder
        if '{FunctionAppName}' in path:
            correct_endpoints += 1
            # Check if using correct pattern
            if path.startswith('https://{FunctionAppName}.azurewebsites.net/api/'):
                print_success(f"  Query {i}: Correct endpoint pattern")
                print_info(f"    Path: {path}")
            else:
                print_error(f"  Query {i}: Incorrect endpoint pattern")
                print_info(f"    Path: {path}")
                issues.append(f"Query {i} has incorrect endpoint pattern")
        else:
            print_error(f"  Query {i}: Not using FunctionAppName placeholder")
            print_info(f"    Path: {path}")
            issues.append(f"Query {i} not using FunctionAppName placeholder")
    
    if correct_endpoints == len(queries):
        print_success(f"All {len(queries)} queries use correct custom endpoint pattern")
    else:
        print_error(f"Only {correct_endpoints}/{len(queries)} queries use correct pattern")
    
    return len(issues) == 0, {
        'total_queries': len(queries),
        'correct_endpoints': correct_endpoints,
        'issues': issues
    }


def verify_auto_refresh(workbook: Dict, workbook_name: str) -> Tuple[bool, Dict]:
    """Verify auto-refresh configuration"""
    print(f"\n{Colors.BOLD}Checking auto-refresh configuration in {workbook_name}...{Colors.RESET}")
    
    queries = find_armendpoint_queries(workbook)
    
    auto_refresh_queries = []
    
    for i, q in enumerate(queries, 1):
        parent = q['parent']
        query_obj = q['query_obj']
        path = query_obj.get('path', '')
        
        is_auto_refresh = parent.get('isAutoRefreshEnabled', False)
        
        if is_auto_refresh:
            refresh_settings = parent.get('autoRefreshSettings', {})
            interval = refresh_settings.get('intervalInSeconds', 'N/A')
            condition = refresh_settings.get('refreshCondition', 'N/A')
            
            auto_refresh_queries.append({
                'query_num': i,
                'path': path,
                'interval': interval,
                'condition': condition
            })
            
            print_success(f"Query {i} has auto-refresh enabled")
            print_info(f"    Endpoint: {path.split('/api/')[-1] if '/api/' in path else path}")
            print_info(f"    Interval: {interval} seconds")
            if condition != 'N/A':
                print_info(f"    Condition: {condition}")
    
    if auto_refresh_queries:
        print_success(f"Found {len(auto_refresh_queries)} queries with auto-refresh")
    else:
        print_info("No queries with auto-refresh enabled")
    
    # According to docs, there should be 2 auto-refresh queries
    expected_auto_refresh = 2
    if len(auto_refresh_queries) >= expected_auto_refresh:
        print_success(f"Expected at least {expected_auto_refresh} auto-refresh queries")
        return True, {
            'auto_refresh_count': len(auto_refresh_queries),
            'queries': auto_refresh_queries,
            'issues': []
        }
    else:
        print_error(f"Expected at least {expected_auto_refresh} auto-refresh queries, found {len(auto_refresh_queries)}")
        return False, {
            'auto_refresh_count': len(auto_refresh_queries),
            'queries': auto_refresh_queries,
            'issues': [f"Expected {expected_auto_refresh} auto-refresh queries, found {len(auto_refresh_queries)}"]
        }


def verify_arm_action_endpoints(workbook: Dict, workbook_name: str) -> Tuple[bool, Dict]:
    """Verify ARM action endpoints have correct parameters"""
    print(f"\n{Colors.BOLD}Checking ARM action endpoint parameters in {workbook_name}...{Colors.RESET}")
    
    queries = find_armendpoint_queries(workbook)
    
    issues = []
    endpoint_checks = []
    
    for i, q in enumerate(queries, 1):
        query_obj = q['query_obj']
        path = query_obj.get('path', '')
        # Check both 'body' (new format) and 'httpBodySchema' (old format) for backward compatibility
        body_schema = query_obj.get('body', query_obj.get('httpBodySchema', ''))
        
        # Extract endpoint name
        endpoint_name = path.split('/api/')[-1] if '/api/' in path else 'Unknown'
        
        # Check if body schema has required parameters
        # action can be: "action": "hardcoded", "action": "{Variable}", or "action": "{CommandType}"
        # The body schema may have escaped quotes (e.g., \"action\")
        body_lower = body_schema.lower()
        has_action = 'action' in body_lower and (':' in body_lower or '=' in body_lower)
        has_tenant_id = 'tenantid' in body_lower
        
        endpoint_checks.append({
            'query_num': i,
            'endpoint': endpoint_name,
            'has_action': has_action,
            'has_tenant_id': has_tenant_id,
            'body_schema_length': len(body_schema)
        })
        
        if has_action and has_tenant_id:
            print_success(f"Query {i} ({endpoint_name}): Has correct parameters")
        else:
            print_error(f"Query {i} ({endpoint_name}): Missing parameters")
            if not has_action:
                print_info(f"    Missing: action parameter")
            if not has_tenant_id:
                print_info(f"    Missing: tenantId parameter")
            issues.append(f"Query {i} ({endpoint_name}) missing required parameters")
    
    return len(issues) == 0, {
        'total_queries': len(queries),
        'checks': endpoint_checks,
        'issues': issues
    }


def verify_arm_action_contexts(workbook: Dict, workbook_name: str) -> Tuple[bool, Dict]:
    """Verify ARM action contexts have Content-Type headers"""
    print(f"\n{Colors.BOLD}Checking ARM action contexts in {workbook_name}...{Colors.RESET}")
    
    def find_arm_actions(obj):
        """Recursively find all ARM action contexts"""
        results = []
        if isinstance(obj, dict):
            if 'armActionContext' in obj:
                results.append(obj['armActionContext'])
            for v in obj.values():
                results.extend(find_arm_actions(v))
        elif isinstance(obj, list):
            for item in obj:
                results.extend(find_arm_actions(item))
        return results
    
    actions = find_arm_actions(workbook)
    
    if not actions:
        print_info("No ARM action contexts found")
        return True, {'total_actions': 0, 'issues': []}
    
    print_success(f"Found {len(actions)} ARM action contexts")
    
    issues = []
    correct_actions = 0
    
    for i, action in enumerate(actions, 1):
        action_name = action.get('actionName', 'Unknown')
        path = action.get('path', '')
        headers = action.get('headers', [])
        
        # Check for Content-Type header
        has_content_type = any(
            h.get('name') == 'Content-Type' and h.get('value') == 'application/json'
            for h in headers
        )
        
        # Check URL pattern
        correct_pattern = path.startswith('https://{FunctionAppName}.azurewebsites.net/api/')
        
        if has_content_type and correct_pattern:
            correct_actions += 1
            print_success(f"  Action {i} ({action_name}): Correct configuration")
        else:
            if not has_content_type:
                print_error(f"  Action {i} ({action_name}): Missing Content-Type header")
                issues.append(f"Action {i} ({action_name}) missing Content-Type header")
            if not correct_pattern:
                print_error(f"  Action {i} ({action_name}): Incorrect URL pattern")
                issues.append(f"Action {i} ({action_name}) incorrect URL pattern")
    
    if correct_actions == len(actions):
        print_success(f"All {len(actions)} ARM actions correctly configured")
    else:
        print_error(f"Only {correct_actions}/{len(actions)} actions correctly configured")
    
    return len(issues) == 0, {
        'total_actions': len(actions),
        'correct_actions': correct_actions,
        'issues': issues
    }


def verify_arm_template_deployment(template_path: str) -> Tuple[bool, Dict]:
    """Verify ARM template has correctly embedded workbook"""
    print_header("Verifying ARM Template Deployment")
    
    try:
        with open(template_path, 'r') as f:
            template = json.load(f)
    except Exception as e:
        print_error(f"Failed to load ARM template: {e}")
        return False, {'issues': [f"Failed to load ARM template: {e}"]}
    
    issues = []
    
    # Find workbook resource
    workbook_resource = None
    for r in template.get('resources', []):
        if 'workbook' in r.get('type', '').lower():
            workbook_resource = r
            break
    
    if not workbook_resource:
        print_error("No workbook resource found in ARM template")
        return False, {'issues': ['No workbook resource found']}
    
    print_success("Found workbook resource in ARM template")
    
    # Check for workbookContent variable
    variables = template.get('variables', {})
    if 'workbookContent' not in variables:
        print_error("workbookContent variable not found")
        issues.append("workbookContent variable not found")
    else:
        print_success("Found workbookContent variable")
        
        # Try to decode and verify
        try:
            content = variables['workbookContent']
            decoded = base64.b64decode(content).decode('utf-8')
            wb_content = json.loads(decoded)
            
            print_success(f"Successfully decoded embedded workbook (size: {len(decoded)} bytes)")
            
            # Check for FunctionAppName
            content_str = json.dumps(wb_content)
            
            if 'FunctionAppName' in content_str:
                count = content_str.count('FunctionAppName')
                print_success(f"Embedded workbook contains FunctionAppName ({count} occurrences)")
            else:
                print_error("Embedded workbook missing FunctionAppName")
                issues.append("Embedded workbook missing FunctionAppName")
            
            # Check for placeholder
            if '__FUNCTION_APP_NAME_PLACEHOLDER__' in content_str:
                count = content_str.count('__FUNCTION_APP_NAME_PLACEHOLDER__')
                print_success(f"Found placeholder for replacement ({count} occurrences)")
            
            # Check ARMEndpoint queries
            if 'ARMEndpoint' in content_str:
                count = content_str.count('ARMEndpoint')
                print_success(f"Embedded workbook has {count} ARMEndpoint references")
            else:
                print_error("Embedded workbook missing ARMEndpoint queries")
                issues.append("Embedded workbook missing ARMEndpoint queries")
                
        except Exception as e:
            print_error(f"Failed to decode/verify workbook content: {e}")
            issues.append(f"Failed to decode workbook: {e}")
    
    # Check serializedData uses correct replacement
    properties = workbook_resource.get('properties', {})
    serialized = properties.get('serializedData', '')
    
    if 'replace(' in serialized and '__FUNCTION_APP_NAME_PLACEHOLDER__' in serialized:
        print_success("ARM template uses correct placeholder replacement mechanism")
    else:
        print_error("ARM template missing placeholder replacement")
        issues.append("ARM template missing placeholder replacement")
    
    return len(issues) == 0, {'issues': issues}


def main():
    """Run all verification checks"""
    print(f"{Colors.BOLD}{Colors.BLUE}")
    print("=" * 70)
    print("WORKBOOK DEPLOYMENT COMPREHENSIVE VERIFICATION")
    print("=" * 70)
    print(Colors.RESET)
    
    all_passed = True
    results = {}
    
    # Verify DefenderC2-Workbook.json
    print_header("Verifying DefenderC2-Workbook.json")
    
    try:
        with open('../workbook/DefenderC2-Workbook.json', 'r') as f:
            main_workbook = json.load(f)
        
        # Run checks
        param_passed, param_results = verify_functionappname_parameter(main_workbook, "DefenderC2-Workbook")
        endpoint_passed, endpoint_results = verify_custom_endpoints(main_workbook, "DefenderC2-Workbook")
        refresh_passed, refresh_results = verify_auto_refresh(main_workbook, "DefenderC2-Workbook")
        action_passed, action_results = verify_arm_action_endpoints(main_workbook, "DefenderC2-Workbook")
        arm_ctx_passed, arm_ctx_results = verify_arm_action_contexts(main_workbook, "DefenderC2-Workbook")
        
        results['main_workbook'] = {
            'parameter': param_results,
            'endpoints': endpoint_results,
            'auto_refresh': refresh_results,
            'actions': action_results,
            'arm_contexts': arm_ctx_results
        }
        
        if not all([param_passed, endpoint_passed, refresh_passed, action_passed, arm_ctx_passed]):
            all_passed = False
            
    except Exception as e:
        print_error(f"Failed to load DefenderC2-Workbook.json: {e}")
        all_passed = False
    
    # Verify FileOperations.workbook
    print_header("Verifying FileOperations.workbook")
    
    try:
        with open('../workbook/FileOperations.workbook', 'r') as f:
            file_ops_workbook = json.load(f)
        
        # Run checks (skip auto-refresh check for FileOperations)
        param_passed, param_results = verify_functionappname_parameter(file_ops_workbook, "FileOperations")
        endpoint_passed, endpoint_results = verify_custom_endpoints(file_ops_workbook, "FileOperations")
        arm_ctx_passed, arm_ctx_results = verify_arm_action_contexts(file_ops_workbook, "FileOperations")
        
        results['file_operations'] = {
            'parameter': param_results,
            'endpoints': endpoint_results,
            'arm_contexts': arm_ctx_results
        }
        
        if not all([param_passed, endpoint_passed, arm_ctx_passed]):
            all_passed = False
            
    except Exception as e:
        print_error(f"Failed to load FileOperations.workbook: {e}")
        all_passed = False
    
    # Verify ARM template
    template_passed, template_results = verify_arm_template_deployment('azuredeploy.json')
    results['arm_template'] = template_results
    
    if not template_passed:
        all_passed = False
    
    # Print summary
    print_header("VERIFICATION SUMMARY")
    
    print(f"\n{Colors.BOLD}DefenderC2-Workbook.json:{Colors.RESET}")
    main_wb = results.get('main_workbook', {})
    print(f"  Parameter Configuration: {'✅ PASS' if main_wb.get('parameter', {}).get('found') else '❌ FAIL'}")
    print(f"  Custom Endpoints: {'✅ PASS' if not main_wb.get('endpoints', {}).get('issues') else '❌ FAIL'}")
    print(f"  Auto-Refresh: {'✅ PASS' if not main_wb.get('auto_refresh', {}).get('issues') else '❌ FAIL'}")
    print(f"  ARM Actions: {'✅ PASS' if not main_wb.get('actions', {}).get('issues') else '❌ FAIL'}")
    print(f"  ARM Action Contexts: {'✅ PASS' if not main_wb.get('arm_contexts', {}).get('issues') else '❌ FAIL'}")
    
    print(f"\n{Colors.BOLD}FileOperations.workbook:{Colors.RESET}")
    file_ops = results.get('file_operations', {})
    print(f"  Parameter Configuration: {'✅ PASS' if file_ops.get('parameter', {}).get('found') else '❌ FAIL'}")
    print(f"  Custom Endpoints: {'✅ PASS' if not file_ops.get('endpoints', {}).get('issues') else '❌ FAIL'}")
    print(f"  ARM Action Contexts: {'✅ PASS' if not file_ops.get('arm_contexts', {}).get('issues') else '❌ FAIL'}")
    
    print(f"\n{Colors.BOLD}ARM Template Deployment:{Colors.RESET}")
    print(f"  Workbook Embedding: {'✅ PASS' if not template_results.get('issues') else '❌ FAIL'}")
    
    # Overall result
    print(f"\n{Colors.BOLD}{'=' * 70}{Colors.RESET}")
    if all_passed:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ ALL VERIFICATION CHECKS PASSED ✅{Colors.RESET}")
        print(f"\n{Colors.GREEN}The workbooks are correctly configured with:{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ Auto-discovery via FunctionAppName parameter{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ Correct custom endpoint configuration{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ Auto-refresh settings where appropriate{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ ARM action endpoints with correct parameters{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ ARM action contexts with Content-Type headers{Colors.RESET}")
        print(f"{Colors.GREEN}  ✅ Properly deployed in ARM template{Colors.RESET}")
        return 0
    else:
        print(f"{Colors.RED}{Colors.BOLD}❌ SOME VERIFICATION CHECKS FAILED ❌{Colors.RESET}")
        
        # Print all issues
        print(f"\n{Colors.RED}{Colors.BOLD}Issues Found:{Colors.RESET}")
        for section, data in results.items():
            if isinstance(data, dict):
                for check, info in data.items():
                    if isinstance(info, dict) and info.get('issues'):
                        for issue in info['issues']:
                            print(f"{Colors.RED}  - [{section}.{check}] {issue}{Colors.RESET}")
        
        return 1


if __name__ == '__main__':
    sys.exit(main())
