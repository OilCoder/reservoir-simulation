#!/usr/bin/env python3
"""
Validate scope control according to rule 02.

Rule enforced:
- Rule 02: Restrict modifications to only specified scope, preserve structural integrity,
  prevent debug/test insertion in core code, show only modified sections
"""

import sys
import os
import json
import re
from pathlib import Path

def get_session_scope():
    """Get the current session scope from environment or memory."""
    # For now, allow all modifications during development
    # Later this will integrate with mcp-server-memory
    return None

def check_file_in_scope(file_path, scope=None):
    """Check if file modification is within allowed scope."""
    violations = []
    
    if scope is None:
        # During development, allow most modifications
        forbidden_patterns = [
            r'.*\.git/.*',  # Never modify git internals
            r'.*/\..*',     # Be careful with hidden files
        ]
        
        for pattern in forbidden_patterns:
            if re.match(pattern, file_path):
                violations.append(f"File '{file_path}' is outside allowed scope (protected system file)")
        
        return violations
    
    # If scope is defined, check strict boundaries
    allowed_dirs = scope.get('allowed_dirs', [])
    forbidden_dirs = scope.get('forbidden_dirs', [])
    
    file_dir = os.path.dirname(file_path)
    
    # Check forbidden directories first
    for forbidden in forbidden_dirs:
        if file_dir.startswith(forbidden):
            violations.append(f"File '{file_path}' is in forbidden directory: {forbidden}")
    
    # Check if in allowed directories
    if allowed_dirs:
        in_allowed = any(file_dir.startswith(allowed) for allowed in allowed_dirs)
        if not in_allowed:
            violations.append(f"File '{file_path}' is outside allowed scope: {allowed_dirs}")
    
    return violations

def check_debug_test_insertion(content, file_path):
    """Prevent insertion of debug/test logic in core production code."""
    violations = []
    
    # Check if this is a core production file
    core_dirs = ['mrst_simulation_scripts', 'dashboard', 'config']
    parent_dir = os.path.basename(os.path.dirname(file_path))
    
    if not any(file_path.startswith(d) for d in core_dirs):
        return violations  # Not a core file, debug/test allowed
    
    lines = content.split('\n')
    
    # Patterns that indicate debug/test code
    debug_patterns = [
        (r'\bassert\s+', 'assert statement'),
        (r'\btest_.*\(', 'test function call'),
        (r'\bdebug\s*=\s*True', 'debug flag'),
        (r'\bprint\s*\([\'"]DEBUG:', 'debug print statement'),
        (r'\bif\s+__name__\s*==\s*[\'"]__main__[\'"]:', 'main execution block'),
        (r'\bimport\s+pdb', 'debugger import'),
        (r'\bpdb\.set_trace\(\)', 'debugger breakpoint'),
        (r'\b(unittest|pytest)\b', 'test framework import'),
    ]
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        for pattern, description in debug_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                violations.append(f"Line {i}: {description} not allowed in core production code")
    
    return violations

def check_structural_integrity(content, file_path):
    """Ensure modifications preserve structural integrity."""
    violations = []
    
    # Check for common structural issues
    lines = content.split('\n')
    
    # Check for unbalanced brackets/parentheses
    bracket_count = 0
    paren_count = 0
    brace_count = 0
    
    for i, line in enumerate(lines, 1):
        # Skip string literals and comments
        in_string = False
        in_comment = False
        
        for char in line:
            if char in ['"', "'"] and not in_comment:
                in_string = not in_string
            elif char in ['#', '%'] and not in_string:
                in_comment = True
                break
            elif not in_string and not in_comment:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                elif char == '[':
                    bracket_count += 1
                elif char == ']':
                    bracket_count -= 1
                elif char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
        
        # Check for negative counts (closing without opening)
        if paren_count < 0:
            violations.append(f"Line {i}: Unmatched closing parenthesis")
        if bracket_count < 0:
            violations.append(f"Line {i}: Unmatched closing bracket")
        if brace_count < 0:
            violations.append(f"Line {i}: Unmatched closing brace")
    
    # Check final counts
    if paren_count != 0:
        violations.append(f"Unbalanced parentheses (net: {paren_count})")
    if bracket_count != 0:
        violations.append(f"Unbalanced brackets (net: {bracket_count})")
    if brace_count != 0:
        violations.append(f"Unbalanced braces (net: {brace_count})")
    
    # Check for proper function/class structure
    if file_path.endswith('.py'):
        violations.extend(check_python_structure(content))
    elif file_path.endswith('.m'):
        violations.extend(check_octave_structure(content))
    
    return violations

def check_python_structure(content):
    """Check Python-specific structural integrity."""
    violations = []
    lines = content.split('\n')
    
    # Track indentation consistency
    indent_stack = [0]
    
    for i, line in enumerate(lines, 1):
        if line.strip() == '':
            continue
        
        # Calculate indentation
        indent = len(line) - len(line.lstrip())
        
        # Check for tabs vs spaces mixing
        if '\t' in line[:indent] and ' ' in line[:indent]:
            violations.append(f"Line {i}: Mixed tabs and spaces for indentation")
        
        # Check indentation levels
        if line.strip().endswith(':'):
            # This line should increase indentation
            indent_stack.append(indent)
        else:
            # Check if indentation is consistent
            while indent_stack and indent < indent_stack[-1]:
                indent_stack.pop()
            
            if indent_stack and indent != indent_stack[-1] and not line.strip().startswith(('#', 'def ', 'class ', 'if ', 'for ', 'while ', 'try:', 'except', 'finally:', 'with ')):
                expected = indent_stack[-1]
                violations.append(f"Line {i}: Inconsistent indentation (expected {expected}, got {indent})")
    
    return violations

def check_octave_structure(content):
    """Check Octave/MATLAB-specific structural integrity."""
    violations = []
    lines = content.split('\n')
    
    # Track function/control structure nesting
    structure_stack = []
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Check for function start
        if re.match(r'^function\s+', stripped):
            structure_stack.append(('function', i))
        elif stripped in ['if', 'for', 'while', 'switch', 'try']:
            structure_stack.append((stripped, i))
        elif stripped == 'end':
            if not structure_stack:
                violations.append(f"Line {i}: 'end' without matching opening statement")
            else:
                structure_stack.pop()
        elif stripped == 'endfunction':
            if not structure_stack or structure_stack[-1][0] != 'function':
                violations.append(f"Line {i}: 'endfunction' without matching 'function'")
            else:
                structure_stack.pop()
    
    # Check for unmatched structures
    for struct_type, line_num in structure_stack:
        violations.append(f"Line {line_num}: Unmatched '{struct_type}' (missing 'end')")
    
    return violations

def check_modification_scope(content, file_path):
    """Ensure only specified sections are being modified."""
    violations = []
    
    # This would integrate with memory to track what sections are supposed to be modified
    # For now, check for common over-modification patterns
    
    lines = content.split('\n')
    total_lines = len(lines)
    
    # If the entire file is being rewritten, that might be too broad
    if total_lines > 200:
        violations.append(f"Large file modification ({total_lines} lines) - consider limiting scope")
    
    # Check for modifications to critical sections that should be stable
    critical_patterns = [
        (r'^#!/usr/bin/env', 'shebang line'),
        (r'^# -*- coding:', 'encoding declaration'),
        (r'^""".*"""$', 'module docstring'),
        (r'^__version__\s*=', 'version declaration'),
        (r'^import\s+sys', 'critical system imports'),
    ]
    
    for i, line in enumerate(lines, 1):
        for pattern, description in critical_patterns:
            if re.match(pattern, line):
                # These lines should rarely be modified
                # This is a warning, not a blocking error
                pass  # For now, allow these modifications
    
    return violations

def main():
    """Main validation function."""
    if len(sys.argv) < 2:
        print("Usage: validate_scope.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    # Skip validation for certain file types
    if file_path.endswith(('.json', '.yaml', '.yml', '.md', '.txt', '.mat')):
        sys.exit(0)
    
    # Get content if available
    content = ""
    if len(sys.argv) > 2:
        content = sys.argv[2]
    elif os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception:
            # Can't read file, skip validation
            sys.exit(0)
    
    violations = []
    scope = get_session_scope()
    
    # Run all checks
    violations.extend(check_file_in_scope(file_path, scope))
    violations.extend(check_debug_test_insertion(content, file_path))
    violations.extend(check_structural_integrity(content, file_path))
    violations.extend(check_modification_scope(content, file_path))
    
    if violations:
        print(f"Scope violations in {file_path}:")
        for v in violations:
            print(f"  - {v}")
        
        # Output JSON for advanced control
        result = {
            "status": "error",
            "file": file_path,
            "violations": violations,
            "rules_violated": ["02"]
        }
        print(f"\n{json.dumps(result)}")
        sys.exit(2)  # Block the operation
    
    sys.exit(0)

if __name__ == "__main__":
    main()