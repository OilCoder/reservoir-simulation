#!/usr/bin/env python3
"""
Validate code style according to rules 01, 05, and 08.

Rules enforced:
- Rule 01: Functions < 40 lines, snake_case, English comments, Step/Substep structure
- Rule 05: File naming conventions (sNN_, test_, dbg_)  
- Rule 08: No unauthorized print/log statements
"""

import sys
import re
import os
import json
from pathlib import Path

def count_function_lines(content):
    """Count lines in each function and return violations."""
    violations = []
    lines = content.split('\n')
    
    # Python function pattern
    py_func_pattern = r'^def\s+(\w+)\s*\('
    # Octave/MATLAB function pattern
    oct_func_pattern = r'^function\s+.*?(\w+)\s*\('
    
    current_func = None
    func_start = 0
    indent_level = 0
    
    for i, line in enumerate(lines, 1):
        # Check for Python function
        py_match = re.match(py_func_pattern, line)
        oct_match = re.match(oct_func_pattern, line)
        
        if py_match or oct_match:
            # Close previous function
            if current_func:
                func_lines = i - func_start - 1
                if func_lines > 40:
                    violations.append(f"Function '{current_func}' has {func_lines} lines (max 40)")
            
            # Start new function
            current_func = py_match.group(1) if py_match else oct_match.group(1)
            func_start = i
            indent_level = len(line) - len(line.lstrip())
        
        # Check for function end (Python - dedent, Octave - end/endfunction)
        elif current_func:
            if line.strip() in ['end', 'endfunction']:
                func_lines = i - func_start
                if func_lines > 40:
                    violations.append(f"Function '{current_func}' has {func_lines} lines (max 40)")
                current_func = None
            elif line.strip() and (len(line) - len(line.lstrip())) <= indent_level:
                # Python function ended by dedent
                func_lines = i - func_start - 1
                if func_lines > 40:
                    violations.append(f"Function '{current_func}' has {func_lines} lines (max 40)")
                current_func = None
    
    # Handle last function
    if current_func:
        func_lines = len(lines) - func_start + 1
        if func_lines > 40:
            violations.append(f"Function '{current_func}' has {func_lines} lines (max 40)")
    
    return violations

def check_naming_conventions(content, file_path):
    """Check snake_case naming and file naming conventions."""
    violations = []
    basename = os.path.basename(file_path)
    
    # Rule 05: File naming conventions
    valid_prefixes = [
        r'^s\d{2}[a-z]?_.*\.(m|py)$',  # Workflow scripts
        r'^test_\d{2}_.*\.(m|py)$',     # Test files
        r'^dbg_.*\.(m|py)$',            # Debug files
        r'^util_.*\.(m|py)$',           # Utility files
    ]
    
    # Check if file is in special directories that don't need prefixes
    special_dirs = ['dashboard', 'validators', 'tools', 'prompts', 'templates', 'docs', '.claude']
    parent_dir = os.path.basename(os.path.dirname(file_path))
    
    if not any(parent_dir.startswith(d) for d in special_dirs):
        if not any(re.match(pattern, basename) for pattern in valid_prefixes):
            if not basename.startswith('__'):  # Allow Python special files
                violations.append(f"File '{basename}' doesn't follow naming convention (sNN_, test_, dbg_, util_)")
    
    # Check variable/function names for snake_case
    # Python patterns
    py_var_pattern = r'^([a-zA-Z_]\w*)\s*='
    py_func_pattern = r'^def\s+([a-zA-Z_]\w*)\s*\('
    py_class_pattern = r'^class\s+([a-zA-Z_]\w*)'
    
    # Octave patterns
    oct_var_pattern = r'^([a-zA-Z_]\w*)\s*='
    oct_func_pattern = r'^function\s+.*?([a-zA-Z_]\w*)\s*\('
    
    lines = content.split('\n')
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        # Check Python variables and functions
        for pattern in [py_var_pattern, py_func_pattern]:
            match = re.match(pattern, line.strip())
            if match:
                name = match.group(1)
                if not re.match(r'^[a-z_][a-z0-9_]*$', name) and name not in ['__init__', '__main__']:
                    violations.append(f"Line {i}: '{name}' should be snake_case")
        
        # Allow PascalCase for classes
        match = re.match(py_class_pattern, line.strip())
        if match:
            name = match.group(1)
            if not re.match(r'^[A-Z][a-zA-Z0-9]*$', name):
                violations.append(f"Line {i}: Class '{name}' should be PascalCase")
    
    return violations

def check_english_comments(content):
    """Check that all comments are in English."""
    violations = []
    lines = content.split('\n')
    
    # Common Spanish words to detect
    spanish_patterns = [
        r'\b(el|la|los|las|un|una|unos|unas)\b',
        r'\b(para|por|con|sin|sobre|bajo|desde|hasta)\b',
        r'\b(es|son|está|están|hay|hace|sido|siendo)\b',
        r'\b(pero|y|o|ni|que|como|cuando|donde)\b',
        r'\b(función|parámetro|retorna|devuelve|variable)\b',
    ]
    spanish_regex = '|'.join(spanish_patterns)
    
    for i, line in enumerate(lines, 1):
        # Extract comments
        comment = None
        if '#' in line:
            comment = line[line.index('#'):]
        elif '%' in line and not line.strip().startswith('%%'):
            comment = line[line.index('%'):]
        
        if comment and re.search(spanish_regex, comment, re.IGNORECASE):
            violations.append(f"Line {i}: Comment appears to be in Spanish (must be English)")
    
    return violations

def check_step_structure(content):
    """Check for Step/Substep structure in multi-step functions."""
    violations = []
    lines = content.split('\n')
    
    # Find functions that might need Step/Substep structure
    in_function = False
    func_name = None
    func_start = 0
    step_count = 0
    
    for i, line in enumerate(lines, 1):
        # Detect function start
        func_match = re.match(r'^(def|function)\s+.*?(\w+)\s*\(', line)
        if func_match:
            in_function = True
            func_name = func_match.group(2)
            func_start = i
            step_count = 0
        
        # Count potential steps (comments with action verbs)
        if in_function and re.match(r'^\s*[#%]\s*(Step|Initialize|Setup|Process|Calculate|Export|Validate)', line):
            step_count += 1
        
        # Function end
        if in_function and (line.strip() in ['end', 'endfunction'] or 
                           (line.strip() and not line.startswith(' ') and i > func_start)):
            # If function has multiple steps but no Step markers
            if step_count >= 3 and not any('Step' in lines[j] for j in range(func_start-1, i)):
                violations.append(f"Function '{func_name}' appears to have multiple steps but lacks Step/Substep structure")
            in_function = False
    
    return violations

def check_unauthorized_output(content, file_path):
    """Check for unauthorized print/log statements (Rule 08)."""
    violations = []
    lines = content.split('\n')
    
    # Allowed locations for output
    allowed_dirs = ['debug', 'test', 'dashboard', '.claude']
    parent_dir = os.path.basename(os.path.dirname(file_path))
    
    if any(parent_dir.startswith(d) for d in allowed_dirs):
        return violations  # Output allowed in these directories
    
    # Patterns for output statements
    output_patterns = [
        (r'\bprint\s*\(', 'print'),
        (r'\bdisp\s*\(', 'disp'),
        (r'\bfprintf\s*\(', 'fprintf'),
        (r'\blogging\.(debug|info|warning|error)\s*\(', 'logging'),
        (r'\bconsole\.(log|error|warn)\s*\(', 'console'),
    ]
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        for pattern, stmt_type in output_patterns:
            if re.search(pattern, line):
                # Check if it's a critical function (allowed)
                if 'progress' in line.lower() or 'error' in stmt_type:
                    continue
                violations.append(f"Line {i}: Unauthorized {stmt_type} statement (Rule 08)")
    
    return violations

def main():
    """Main validation function."""
    if len(sys.argv) < 3:
        print("Usage: validate_code_style.py <file_path> <content>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    content = sys.argv[2] if len(sys.argv) > 2 else ""
    
    # Skip validation for certain file types
    if file_path.endswith(('.json', '.yaml', '.yml', '.md', '.txt', '.mat')):
        sys.exit(0)
    
    violations = []
    
    # Run all checks
    violations.extend(count_function_lines(content))
    violations.extend(check_naming_conventions(content, file_path))
    violations.extend(check_english_comments(content))
    violations.extend(check_step_structure(content))
    violations.extend(check_unauthorized_output(content, file_path))
    
    if violations:
        print(f"Code style violations in {file_path}:")
        for v in violations:
            print(f"  - {v}")
        
        # Output JSON for advanced control
        result = {
            "status": "error",
            "file": file_path,
            "violations": violations,
            "rules_violated": ["01", "05", "08"]
        }
        print(f"\n{json.dumps(result)}")
        sys.exit(2)  # Block the operation
    
    sys.exit(0)

if __name__ == "__main__":
    main()