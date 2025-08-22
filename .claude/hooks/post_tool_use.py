#!/usr/bin/env python3
"""
Post-Tool Hook for Multi-Mode Policy Validation
- Scans Write/Edit operations for policy violations
- Supports suggest/warn/strict validation modes
- Context-aware enforcement based on file location and development phase
- Override mechanisms for prototyping and special cases
"""

import json
import sys
import re
import os
import warnings
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

def get_validation_mode(file_path: str, content: str) -> str:
    """Determine validation mode based on context."""
    
    # Check for explicit override in file
    if "# @policy-override:" in content:
        override_match = re.search(r'# @policy-override:\s*(\w+)', content)
        if override_match:
            return override_match.group(1)
    
    # Check environment variable
    env_mode = os.getenv('CLAUDE_VALIDATION_MODE', '').lower()
    if env_mode in ['suggest', 'warn', 'strict']:
        return env_mode
    
    # Context-based determination
    file_path_lower = file_path.lower()
    
    # Strict mode for production files
    if any(keyword in file_path_lower for keyword in [
        'prod', 'production', 'deploy', 'release', 'main.py', '__init__.py'
    ]):
        return 'strict'
    
    # Suggest mode for prototype/experimental files
    if any(keyword in file_path_lower for keyword in [
        'prototype', 'experimental', 'demo', 'example', 'temp', 'tmp'
    ]):
        return 'suggest'
    
    # Warn mode for development (default)
    return 'warn'

def get_project_context() -> Dict[str, str]:
    """Get project context information."""
    context = {
        'phase': 'development',  # development, production, prototype
        'project_type': 'unknown',
        'has_config': False
    }
    
    # Check for configuration files
    config_files = [
        'config.yaml', 'config.json', '.env', 'settings.yaml',
        'mrst_simulation_scripts/config/', 'obsidian-vault/'
    ]
    
    for config_file in config_files:
        if os.path.exists(config_file):
            context['has_config'] = True
            break
    
    # Detect project type from structure
    if os.path.exists('mrst_simulation_scripts/'):
        context['project_type'] = 'simulation'
    elif os.path.exists('src/'):
        context['project_type'] = 'application'
    elif os.path.exists('tests/'):
        context['project_type'] = 'library'
    
    return context

def scan_policy_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan content for policy violations with mode-aware severity."""
    violations = []
    
    # Canon-First Policy Violations
    violations.extend(scan_hardcoding_violations(content, file_path, mode))
    
    # Data Authority Policy Violations  
    violations.extend(scan_data_authority_violations(content, file_path, mode))
    
    # Fail Fast Policy Violations
    violations.extend(scan_fail_fast_violations(content, file_path, mode))
    
    # Exception Handling Policy Violations
    violations.extend(scan_exception_handling_violations(content, file_path, mode))
    
    # KISS Principle Violations
    violations.extend(scan_kiss_violations(content, file_path, mode))
    
    return violations

def scan_hardcoding_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan for hardcoding violations with mode-aware severity."""
    violations = []
    
    # Magic numbers (context-aware allowlist)
    base_allowed = {0, 1, 2, -1, 100}
    
    if mode == 'suggest':
        # More permissive for prototyping
        allowed_numbers = base_allowed | {3, 4, 5, 10, 20, 50, 200, 404, 500, 1000}
    elif mode == 'strict':
        # Very restrictive for production
        allowed_numbers = base_allowed
    else:  # warn mode
        allowed_numbers = base_allowed | {200, 404, 500}
    
    for match in re.finditer(r'\b(\d{3,})\b', content):
        number = int(match.group(1))
        if number not in allowed_numbers:
            severity = "error" if mode == "strict" else "warning" if mode == "warn" else "suggestion"
            violations.append({
                "type": "magic_number",
                "severity": severity,
                "policy": "canon-first",
                "value": match.group(1),
                "line": content[:match.start()].count('\n') + 1,
                "message": f"Magic number '{number}' should be in config",
                "suggestion": f"Move to config file or define as named constant"
            })
    
    # Hardcoded paths (mode-aware)
    path_patterns = [
        r'["\'](/[^"\'\\]+)',  # Absolute paths
        r'["\'](\.\.?/[^"\'\\]+)',  # Relative paths  
        r'["\'](C:\\[^"\'\\]+)',  # Windows paths
    ]
    
    for pattern in path_patterns:
        for match in re.finditer(pattern, content):
            path = match.group(1)
            # System paths are always allowed
            if any(skip in path for skip in ['/tmp/', '/dev/', '/proc/', '/usr/', '/bin/', '/opt/']):
                continue
                
            # Mode-specific handling
            if mode == 'suggest' and len(path) < 20:  # Short paths ok in prototype
                continue
                
            severity = "error" if mode == "strict" else "warning" if mode == "warn" else "suggestion"
            violations.append({
                "type": "hardcoded_path",
                "severity": severity,
                "policy": "canon-first",
                "value": path,
                "line": content[:match.start()].count('\n') + 1,
                "message": f"Hardcoded path '{path}' should be configurable",
                "suggestion": "Use environment variable or config file"
            })
    
    return violations

def scan_data_authority_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan for data authority violations."""
    violations = []
    
    # Test data hardcoding
    if 'test' not in file_path.lower():  # Allow in test files
        test_patterns = [
            (r'assert.*==\s*[\d.]+', "hardcoded_test_expectation"),
            (r'expected\s*=\s*[\d.]+', "hardcoded_expected_value"),
            (r'result.*should.*[\d.]+', "hardcoded_assertion"),
        ]
        
        for pattern, violation_type in test_patterns:
            for match in re.finditer(pattern, content, re.IGNORECASE):
                severity = "error" if mode == "strict" else "warning"
                violations.append({
                    "type": violation_type,
                    "severity": severity,
                    "policy": "data-authority",
                    "value": match.group(0),
                    "line": content[:match.start()].count('\n') + 1,
                    "message": "Test expectations should be computed, not hardcoded",
                    "suggestion": "Use reference computation or simulator"
                })
    
    return violations

def scan_fail_fast_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan for fail-fast violations."""
    violations = []
    
    # Defensive default patterns
    defensive_patterns = [
        (r'\.get\([^,]+,\s*[^)]+\)', "defensive_default"),
        (r'if\s+not\s+\w+:\s*\w+\s*=\s*[^#\n]+', "fallback_assignment"),
        (r'except.*:\s*\w+\s*=\s*[^#\n]+', "exception_default"),
    ]
    
    for pattern, violation_type in defensive_patterns:
        for match in re.finditer(pattern, content):
            # Skip if it's clearly intentional (has comment)
            line_end = content.find('\n', match.end())
            line = content[match.start():line_end if line_end != -1 else len(content)]
            
            if '#' in line and any(word in line.lower() for word in ['intentional', 'ok', 'allowed']):
                continue
                
            severity = "warning" if mode != "suggest" else "suggestion"
            violations.append({
                "type": violation_type,
                "severity": severity,
                "policy": "fail-fast",
                "value": match.group(0),
                "line": content[:match.start()].count('\n') + 1,
                "message": "Avoid defensive defaults, fail fast instead",
                "suggestion": "Validate requirements explicitly and fail with clear error"
            })
    
    return violations

def scan_exception_handling_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan for exception handling violations."""
    violations = []
    
    # Broad exception handling
    broad_patterns = [
        (r'except\s*:', "bare_except"),
        (r'except\s+Exception\s*:', "broad_exception"),
        (r'except.*:\s*pass', "silent_exception"),
    ]
    
    for pattern, violation_type in broad_patterns:
        for match in re.finditer(pattern, content):
            severity = "error" if mode == "strict" else "warning"
            violations.append({
                "type": violation_type,
                "severity": severity,
                "policy": "exception-handling",
                "value": match.group(0),
                "line": content[:match.start()].count('\n') + 1,
                "message": "Use specific exception handling",
                "suggestion": "Catch specific exceptions and handle appropriately"
            })
    
    return violations

def scan_kiss_violations(content: str, file_path: str = "", mode: str = "warn") -> List[Dict]:
    """Scan for KISS principle violations."""
    violations = []
    
    # Function length (approximate)
    function_pattern = r'def\s+\w+\([^)]*\):'
    for match in re.finditer(function_pattern, content):
        # Find function end (next def or end of file)
        start_line = content[:match.start()].count('\n') + 1
        
        # Simple heuristic: count lines until next def or class
        rest_content = content[match.end():]
        next_def = re.search(r'\n(def|class)\s+', rest_content)
        
        if next_def:
            func_content = rest_content[:next_def.start()]
        else:
            func_content = rest_content
        
        # Count non-empty, non-comment lines
        func_lines = [l.strip() for l in func_content.split('\n') 
                     if l.strip() and not l.strip().startswith('#')]
        
        if len(func_lines) > 40:
            severity = "warning" if mode != "suggest" else "suggestion"
            violations.append({
                "type": "long_function",
                "severity": severity,
                "policy": "kiss-principle",
                "value": f"~{len(func_lines)} lines",
                "line": start_line,
                "message": f"Function is {len(func_lines)} lines, consider breaking down",
                "suggestion": "Split into smaller, focused functions"
            })
    
    return violations

def should_validate_file(file_path: str, tool_name: str) -> bool:
    """Determine if file should be validated."""
    if tool_name not in ["Write", "Edit", "MultiEdit"]:
        return False
    
    # Skip certain file types
    skip_extensions = {'.md', '.txt', '.json', '.yaml', '.yml', '.xml', '.html', '.log'}
    if any(file_path.endswith(ext) for ext in skip_extensions):
        return False
    
    # Skip documentation (they may have intentional examples)
    skip_patterns = ['docs/', 'documentation/', 'examples/', 'demo/']
    if any(pattern in file_path.lower() for pattern in skip_patterns):
        return False
    
    return True

def format_violation_report(violations: List[Dict], mode: str, file_path: str) -> str:
    """Format violations into a readable report."""
    if not violations:
        return ""
    
    # Group by severity
    errors = [v for v in violations if v.get('severity') == 'error']
    warnings = [v for v in violations if v.get('severity') == 'warning']
    suggestions = [v for v in violations if v.get('severity') == 'suggestion']
    
    report = f"POLICY VALIDATION ({mode.upper()} mode) for {file_path}:\n\n"
    
    if errors:
        report += "🚫 ERRORS (blocking):\n"
        for v in errors:
            report += f"  Line {v['line']}: {v['message']}\n"
            report += f"    Policy: {v['policy']} | Type: {v['type']}\n"
            report += f"    Suggestion: {v['suggestion']}\n\n"
    
    if warnings:
        report += "⚠️  WARNINGS:\n"
        for v in warnings:
            report += f"  Line {v['line']}: {v['message']}\n"
            report += f"    Policy: {v['policy']} | Suggestion: {v['suggestion']}\n\n"
    
    if suggestions:
        report += "💡 SUGGESTIONS:\n"
        for v in suggestions:
            report += f"  Line {v['line']}: {v['message']}\n"
            report += f"    Suggestion: {v['suggestion']}\n\n"
    
    # Mode-specific guidance
    if mode == 'suggest':
        report += "ℹ️  Prototyping mode: These are suggestions to improve code quality.\n"
    elif mode == 'warn':
        report += "ℹ️  Development mode: Address warnings before production.\n"
    elif mode == 'strict':
        report += "ℹ️  Production mode: All errors must be fixed.\n"
    
    # Override instructions
    report += "\n🔧 Override options:\n"
    report += "  - Add '# @policy-override: suggest' to file header\n"
    report += "  - Set CLAUDE_VALIDATION_MODE=suggest environment variable\n"
    
    return report

def main():
    """Main validation processor."""
    try:
        # Read tool usage data from stdin
        if not sys.stdin.isatty():
            tool_data = json.load(sys.stdin)
        else:
            # For testing
            tool_data = {
                "tool": "Write",
                "file_path": "test.py", 
                "content": "api_key = 'hardcoded123'\ntimeout = 5000"
            }
        
        tool_name = tool_data.get("tool", "")
        file_path = tool_data.get("file_path", "")
        content = tool_data.get("content", "")
        
        # Skip validation for non-relevant tools/files
        if not should_validate_file(file_path, tool_name):
            print(json.dumps({
                "continue": True,
                "status": "skipped",
                "reason": "file_type_excluded"
            }))
            return
        
        # Determine validation mode
        mode = get_validation_mode(file_path, content)
        context = get_project_context()
        
        # Scan for violations
        violations = scan_policy_violations(content, file_path, mode)
        
        # Filter by severity for blocking decision
        errors = [v for v in violations if v.get('severity') == 'error']
        should_block = len(errors) > 0 and mode == 'strict'
        
        if violations:
            report = format_violation_report(violations, mode, file_path)
            
            print(json.dumps({
                "continue": not should_block,
                "status": "violations_found" if should_block else "violations_warned",
                "mode": mode,
                "violation_count": len(violations),
                "error_count": len(errors),
                "report": report,
                "violations": violations,
                "context": context
            }))
        else:
            # No violations found
            print(json.dumps({
                "continue": True,
                "status": "validated",
                "mode": mode,
                "message": f"No policy violations detected ({mode} mode)",
                "context": context
            }))
        
    except Exception as e:
        # Graceful fallback - don't block on hook errors
        print(json.dumps({
            "continue": True,
            "status": "error",
            "message": f"Validation hook error: {str(e)}"
        }))

if __name__ == "__main__":
    main()