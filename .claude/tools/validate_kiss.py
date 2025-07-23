#!/usr/bin/env python3
"""
Validate KISS principle and data generation policy according to rules 00 and 09.

Rules enforced:
- Rule 00: KISS principle, no hardcoded values except physical constants, complete traceability
- Rule 09: Simple code structure, prohibit excessive complexity and try/except blocks
"""

import sys
import re
import os
import json
import ast
from pathlib import Path

def detect_hardcoded_values(content, file_path):
    """Detect hardcoded values that should come from simulators."""
    violations = []
    lines = content.split('\n')
    
    # Physical constants that are allowed to be hardcoded
    allowed_constants = {
        # Physical constants
        'pi', 'PI', 'e', 'E', 'gravity', 'g',
        # Common mathematical constants
        '3.14159', '2.71828', '9.81', '9.8',
        # Unit conversions
        '1000', '100', '60', '24', '365',
        # Common array sizes
        '0', '1', '2', '3', '4', '5', '-1',
        # Configuration/UI defaults
        'True', 'False', 'None', '[]', '{}', '""', "''",
    }
    
    # Patterns for potentially hardcoded values
    hardcoded_patterns = [
        # Reservoir properties that should come from config
        (r'\b(porosity|permeability|pressure|saturation)\s*=\s*[\d.]+', 'reservoir property'),
        (r'\b(depth|thickness|width|length)\s*=\s*[\d.]+', 'geometric parameter'),
        (r'\b(rate|flow|volume)\s*=\s*[\d.]+', 'flow parameter'),
        (r'\b(time|timestep|dt)\s*=\s*[\d.]+', 'temporal parameter'),
        # Large numeric literals (likely should be configurable)
        (r'\b\d{4,}\b', 'large numeric literal'),
        # Specific unit values
        (r'\b\d+\.\d*\s*(psi|bar|mD|ft|m|bbl|stb)\b', 'unit value'),
    ]
    
    for i, line in enumerate(lines, 1):
        # Skip comments and strings
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        # Skip lines with allowed constants
        if any(const in line for const in allowed_constants):
            continue
        
        for pattern, description in hardcoded_patterns:
            matches = re.findall(pattern, line, re.IGNORECASE)
            for match in matches:
                # Check if it's in a comment or string literal
                if '#' in line and line.index('#') < line.index(str(match)):
                    continue
                violations.append(f"Line {i}: Potential hardcoded {description}: '{match}'")
    
    return violations

def detect_try_except_blocks(content):
    """Detect prohibited try/except blocks (Rule 00)."""
    violations = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Python try/except
        if stripped.startswith('try:') or stripped == 'try':
            violations.append(f"Line {i}: try/except blocks are prohibited (KISS principle)")
        
        # Octave/MATLAB try/catch
        if stripped.startswith('try') and not stripped.startswith('try:'):
            # Check if it's Octave try
            if re.match(r'^try\s*$', stripped):
                violations.append(f"Line {i}: try/catch blocks are prohibited (KISS principle)")
    
    return violations

def calculate_complexity_metrics(content, file_path):
    """Calculate complexity metrics and detect violations."""
    violations = []
    
    if file_path.endswith('.py'):
        violations.extend(calculate_python_complexity(content))
    elif file_path.endswith('.m'):
        violations.extend(calculate_octave_complexity(content))
    
    return violations

def calculate_python_complexity(content):
    """Calculate cyclomatic complexity for Python code."""
    violations = []
    
    try:
        tree = ast.parse(content)
    except SyntaxError:
        # If we can't parse, let other validators handle syntax errors
        return violations
    
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            complexity = calculate_cyclomatic_complexity(node)
            if complexity > 10:  # McCabe complexity threshold
                violations.append(f"Function '{node.name}' has high complexity: {complexity} (max 10)")
        elif isinstance(node, ast.ClassDef):
            # Check class size
            methods = [n for n in node.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))]
            if len(methods) > 15:
                violations.append(f"Class '{node.name}' has too many methods: {len(methods)} (max 15)")
    
    return violations

def calculate_cyclomatic_complexity(node):
    """Calculate cyclomatic complexity for an AST node."""
    complexity = 1  # Base complexity
    
    for child in ast.walk(node):
        # Count decision points
        if isinstance(child, (ast.If, ast.While, ast.For, ast.AsyncFor)):
            complexity += 1
        elif isinstance(child, ast.Try):
            complexity += len(child.handlers)  # Each except handler
        elif isinstance(child, ast.BoolOp):
            complexity += len(child.values) - 1  # And/Or operations
        elif isinstance(child, ast.ListComp):
            complexity += 1  # List comprehensions add complexity
        elif isinstance(child, (ast.DictComp, ast.SetComp, ast.GeneratorExp)):
            complexity += 1
    
    return complexity

def calculate_octave_complexity(content):
    """Calculate complexity metrics for Octave/MATLAB code."""
    violations = []
    lines = content.split('\n')
    
    # Track control structures
    control_structures = ['if', 'for', 'while', 'switch', 'try']
    current_function = None
    function_complexity = 0
    function_start_line = 0
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Function start
        func_match = re.match(r'^function\s+.*?(\w+)\s*\(', stripped)
        if func_match:
            # End previous function
            if current_function and function_complexity > 10:
                violations.append(f"Function '{current_function}' has high complexity: {function_complexity} (max 10)")
            
            # Start new function
            current_function = func_match.group(1)
            function_complexity = 1
            function_start_line = i
        
        # Count control structures
        elif any(stripped.startswith(cs) for cs in control_structures):
            function_complexity += 1
        
        # Function end
        elif stripped in ['end', 'endfunction']:
            if current_function and function_complexity > 10:
                violations.append(f"Function '{current_function}' has high complexity: {function_complexity} (max 10)")
            current_function = None
            function_complexity = 0
    
    # Handle last function
    if current_function and function_complexity > 10:
        violations.append(f"Function '{current_function}' has high complexity: {function_complexity} (max 10)")
    
    return violations

def detect_over_engineering(content, file_path):
    """Detect patterns of over-engineering that violate KISS."""
    violations = []
    lines = content.split('\n')
    
    # Patterns that suggest over-engineering
    overengineering_patterns = [
        # Excessive abstraction
        (r'class\s+.*Factory', 'Factory pattern may be over-engineering'),
        (r'class\s+.*Singleton', 'Singleton pattern may be over-engineering'),
        (r'class\s+.*Observer', 'Observer pattern may be over-engineering'),
        (r'class\s+.*Strategy', 'Strategy pattern may be over-engineering'),
        
        # Excessive indirection
        (r'def\s+get_.*_manager\(', 'Manager functions may indicate over-abstraction'),
        (r'def\s+create_.*_factory\(', 'Factory functions may be unnecessary'),
        
        # Complex decorators
        (r'@.*wrapper.*', 'Complex decorators may violate KISS'),
        (r'def\s+.*_decorator\(', 'Custom decorators should be used sparingly'),
        
        # Excessive configuration
        (r'config\[.*\]\[.*\]\[.*\]', 'Deep configuration nesting'),
        (r'settings\[.*\]\[.*\]\[.*\]', 'Deep settings nesting'),
    ]
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        for pattern, description in overengineering_patterns:
            if re.search(pattern, line):
                violations.append(f"Line {i}: {description}")
    
    return violations

def check_function_responsibility(content):
    """Check for single responsibility principle violations."""
    violations = []
    lines = content.split('\n')
    
    # Look for functions that do too many things
    current_function = None
    action_count = 0
    function_start_line = 0
    
    # Action verbs that indicate different responsibilities
    action_verbs = [
        'load', 'save', 'read', 'write', 'parse', 'format', 'convert',
        'calculate', 'compute', 'process', 'transform', 'filter',
        'validate', 'check', 'verify', 'test', 'assert',
        'create', 'build', 'generate', 'construct', 'initialize',
        'update', 'modify', 'change', 'set', 'get', 'fetch',
        'send', 'receive', 'connect', 'disconnect', 'open', 'close'
    ]
    
    for i, line in enumerate(lines, 1):
        # Function start
        func_match = re.match(r'^(def|function)\s+.*?(\w+)\s*\(', line)
        if func_match:
            # Check previous function
            if current_function and action_count > 3:
                violations.append(f"Function '{current_function}' appears to have multiple responsibilities ({action_count} different actions)")
            
            # Start new function
            current_function = func_match.group(2)
            action_count = 0
            function_start_line = i
        
        # Count different types of actions
        elif current_function:
            line_lower = line.lower()
            for verb in action_verbs:
                if verb in line_lower and not line.strip().startswith(('#', '%', '//')):
                    action_count += 1
                    break  # Only count one action per line
        
        # Function end
        elif line.strip() in ['end', 'endfunction'] or (current_function and not line.startswith(' ') and line.strip()):
            if current_function and action_count > 3:
                violations.append(f"Function '{current_function}' appears to have multiple responsibilities ({action_count} different actions)")
            current_function = None
            action_count = 0
    
    # Handle last function
    if current_function and action_count > 3:
        violations.append(f"Function '{current_function}' appears to have multiple responsibilities ({action_count} different actions)")
    
    return violations

def check_data_traceability(content, file_path):
    """Check for data traceability requirements."""
    violations = []
    
    # Skip non-data files
    if not any(keyword in file_path.lower() for keyword in ['data', 'export', 'generate', 'simulate']):
        return violations
    
    lines = content.split('\n')
    
    # Look for data generation without metadata
    data_patterns = [
        r'\.mat\s*=',  # MATLAB data assignment
        r'save\s*\(',  # Data saving
        r'export.*data',  # Data export
        r'generate.*data',  # Data generation
    ]
    
    has_metadata = False
    metadata_patterns = [
        r'metadata',
        r'timestamp',
        r'source',
        r'origin',
        r'version',
        r'traceability'
    ]
    
    # Check if metadata is present
    content_lower = content.lower()
    has_metadata = any(re.search(pattern, content_lower) for pattern in metadata_patterns)
    
    # If file generates data but has no metadata tracking
    generates_data = any(re.search(pattern, content, re.IGNORECASE) for pattern in data_patterns)
    
    if generates_data and not has_metadata:
        violations.append("Data generation detected but no metadata/traceability information found")
    
    return violations

def main():
    """Main validation function."""
    if len(sys.argv) < 2:
        print("Usage: validate_kiss.py <content>")
        sys.exit(1)
    
    content = sys.argv[1] if len(sys.argv) > 1 else ""
    file_path = sys.argv[2] if len(sys.argv) > 2 else "unknown"
    
    # Skip validation for certain file types
    if file_path.endswith(('.json', '.yaml', '.yml', '.md', '.txt', '.mat')):
        sys.exit(0)
    
    violations = []
    
    # Run all checks
    violations.extend(detect_hardcoded_values(content, file_path))
    violations.extend(detect_try_except_blocks(content))
    violations.extend(calculate_complexity_metrics(content, file_path))
    violations.extend(detect_over_engineering(content, file_path))
    violations.extend(check_function_responsibility(content))
    violations.extend(check_data_traceability(content, file_path))
    
    if violations:
        print(f"KISS principle violations in {file_path}:")
        for v in violations:
            print(f"  - {v}")
        
        # Output JSON for advanced control
        result = {
            "status": "error",
            "file": file_path,
            "violations": violations,
            "rules_violated": ["00", "09"]
        }
        print(f"\n{json.dumps(result)}")
        sys.exit(2)  # Block the operation
    
    sys.exit(0)

if __name__ == "__main__":
    main()