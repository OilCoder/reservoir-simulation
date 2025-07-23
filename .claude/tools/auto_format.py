#!/usr/bin/env python3
"""
Auto-format and clean up code according to project standards.

This tool performs post-processing cleanup to ensure code follows
the established formatting and style guidelines.
"""

import sys
import re
import os
import json
from pathlib import Path

def format_python_code(content):
    """Format Python code according to project standards."""
    lines = content.split('\n')
    formatted_lines = []
    
    for i, line in enumerate(lines):
        # Clean up temporary print statements
        if re.match(r'^\s*print\s*\([\'"]DEBUG:', line):
            # Remove debug print statements
            continue
        elif re.match(r'^\s*print\s*\([\'"]TODO:', line):
            # Remove TODO print statements
            continue
        
        # Ensure proper spacing around operators
        line = re.sub(r'([=!<>])([=!<>])', r'\1 \2', line)  # == != <= >= 
        line = re.sub(r'(\w)([=+\-*/%])(\w)', r'\1 \2 \3', line)  # Operators with spaces
        
        # Fix common spacing issues
        line = re.sub(r',(\w)', r', \1', line)  # Comma spacing
        line = re.sub(r'(\w):(\w)', r'\1: \2', line)  # Colon spacing in dicts
        
        # Ensure Step/Substep formatting
        if re.match(r'^\s*#\s*(Step|Substep)\s+\d+', line):
            # Standardize Step formatting
            step_match = re.match(r'^(\s*)#\s*(Step|Substep)\s+(\d+)(.*)$', line)
            if step_match:
                indent, step_type, number, rest = step_match.groups()
                line = f"{indent}# {step_type} {number}:{rest}"
        
        formatted_lines.append(line)
    
    return '\n'.join(formatted_lines)

def format_octave_code(content):
    """Format Octave/MATLAB code according to project standards."""
    lines = content.split('\n')
    formatted_lines = []
    
    for i, line in enumerate(lines):
        # Clean up temporary disp statements
        if re.match(r'^\s*disp\s*\([\'"]DEBUG:', line):
            # Remove debug disp statements
            continue
        elif re.match(r'^\s*disp\s*\([\'"]TODO:', line):
            # Remove TODO disp statements
            continue
        
        # Ensure proper spacing around operators
        line = re.sub(r'([=!<>])([=!<>])', r'\1\2', line)  # Keep == != <= >= tight
        line = re.sub(r'(\w)\s*([=+\-*/%])\s*(\w)', r'\1 \2 \3', line)  # Operators with spaces
        
        # Fix semicolon usage (Octave style)
        if not line.strip().endswith(';') and re.match(r'^\s*\w+\s*=', line):
            # Add semicolon to assignment statements
            line = line.rstrip() + ';'
        
        # Ensure Step/Substep formatting (same as Python)
        if re.match(r'^\s*%\s*(Step|Substep)\s+\d+', line):
            step_match = re.match(r'^(\s*)%\s*(Step|Substep)\s+(\d+)(.*)$', line)
            if step_match:
                indent, step_type, number, rest = step_match.groups()
                line = f"{indent}% {step_type} {number}:{rest}"
        
        formatted_lines.append(line)
    
    return '\n'.join(formatted_lines)

def add_missing_blank_lines(content, file_path):
    """Add blank lines between logical sections."""
    lines = content.split('\n')
    formatted_lines = []
    
    prev_line_type = None
    
    for i, line in enumerate(lines):
        current_line_type = classify_line_type(line, file_path)
        
        # Add blank line before function definitions
        if current_line_type == 'function' and prev_line_type not in [None, 'blank', 'comment']:
            formatted_lines.append('')
        
        # Add blank line before Step comments
        if current_line_type == 'step' and prev_line_type not in [None, 'blank']:
            formatted_lines.append('')
        
        # Add blank line before class definitions
        if current_line_type == 'class' and prev_line_type not in [None, 'blank', 'comment']:
            formatted_lines.append('')
        
        formatted_lines.append(line)
        prev_line_type = current_line_type
    
    return '\n'.join(formatted_lines)

def classify_line_type(line, file_path):
    """Classify the type of a line for formatting purposes."""
    stripped = line.strip()
    
    if not stripped:
        return 'blank'
    
    if file_path.endswith('.py'):
        if stripped.startswith('#'):
            if re.match(r'#\s*(Step|Substep)\s+\d+', stripped):
                return 'step'
            return 'comment'
        elif stripped.startswith('def ') or stripped.startswith('async def '):
            return 'function'
        elif stripped.startswith('class '):
            return 'class'
        elif stripped.startswith(('import ', 'from ')):
            return 'import'
    
    elif file_path.endswith('.m'):
        if stripped.startswith('%'):
            if re.match(r'%\s*(Step|Substep)\s+\d+', stripped):
                return 'step'
            return 'comment'
        elif stripped.startswith('function '):
            return 'function'
        elif '=' in stripped and not stripped.startswith('%'):
            return 'assignment'
    
    return 'code'

def clean_trailing_whitespace(content):
    """Remove trailing whitespace from all lines."""
    lines = content.split('\n')
    cleaned_lines = [line.rstrip() for line in lines]
    return '\n'.join(cleaned_lines)

def ensure_final_newline(content):
    """Ensure file ends with exactly one newline."""
    content = content.rstrip()
    return content + '\n'

def fix_indentation_consistency(content, file_path):
    """Fix indentation consistency issues."""
    lines = content.split('\n')
    fixed_lines = []
    
    if file_path.endswith('.py'):
        # Python: enforce 4-space indentation
        for line in lines:
            if line.strip():
                # Count leading whitespace
                leading_space = len(line) - len(line.lstrip())
                if leading_space > 0:
                    # Convert tabs to spaces
                    line_no_tabs = line.expandtabs(4)
                    # Ensure multiple of 4 spaces
                    new_leading = len(line_no_tabs) - len(line_no_tabs.lstrip())
                    if new_leading % 4 != 0:
                        # Round to nearest multiple of 4
                        target_indent = (new_leading // 4) * 4
                        if new_leading % 4 >= 2:
                            target_indent += 4
                        line = ' ' * target_indent + line_no_tabs.lstrip()
                    else:
                        line = line_no_tabs
            fixed_lines.append(line)
    
    elif file_path.endswith('.m'):
        # Octave: enforce 2-space indentation
        for line in lines:
            if line.strip():
                # Convert tabs to spaces
                line_no_tabs = line.expandtabs(2)
                # Ensure multiple of 2 spaces
                leading_space = len(line_no_tabs) - len(line_no_tabs.lstrip())
                if leading_space > 0 and leading_space % 2 != 0:
                    # Round to nearest multiple of 2
                    target_indent = (leading_space // 2) * 2
                    if leading_space % 2 == 1:
                        target_indent += 2
                    line = ' ' * target_indent + line_no_tabs.lstrip()
                else:
                    line = line_no_tabs
            fixed_lines.append(line)
    else:
        return content
    
    return '\n'.join(fixed_lines)

def validate_formatting_rules(content, file_path):
    """Validate that formatting follows rules - return warnings, not errors."""
    warnings = []
    lines = content.split('\n')
    
    # Check for overly long lines
    for i, line in enumerate(lines, 1):
        if len(line) > 100:
            warnings.append(f"Line {i}: Line longer than 100 characters ({len(line)})")
    
    # Check for excessive blank lines
    blank_count = 0
    for i, line in enumerate(lines, 1):
        if not line.strip():
            blank_count += 1
            if blank_count > 2:
                warnings.append(f"Line {i}: More than 2 consecutive blank lines")
        else:
            blank_count = 0
    
    # Check for missing documentation after function definitions
    in_function = False
    function_line = 0
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        if file_path.endswith('.py'):
            if stripped.startswith('def ') and not stripped.startswith('def _'):
                in_function = True
                function_line = i
            elif in_function and stripped and not stripped.startswith(('"""', "'''", '#')):
                warnings.append(f"Line {function_line}: Public function missing docstring")
                in_function = False
            elif in_function and stripped.startswith(('"""', "'''")):
                in_function = False
        
        elif file_path.endswith('.m'):
            if stripped.startswith('function '):
                in_function = True
                function_line = i
            elif in_function and stripped and not stripped.startswith('%'):
                warnings.append(f"Line {function_line}: Function missing comment block")
                in_function = False
            elif in_function and stripped.startswith('%'):
                in_function = False
    
    return warnings

def main():
    """Main auto-formatting function."""
    if len(sys.argv) < 2:
        print("Usage: auto_format.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    # Skip formatting for certain file types
    if file_path.endswith(('.json', '.yaml', '.yml', '.md', '.txt', '.mat')):
        sys.exit(0)
    
    # Skip formatting for .claude tools (they're meta)
    if '.claude' in file_path:
        sys.exit(0)
    
    # Get content
    if not os.path.exists(file_path):
        sys.exit(0)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
    except Exception:
        sys.exit(0)
    
    content = original_content
    
    # Apply formatting based on file type
    if file_path.endswith('.py'):
        content = format_python_code(content)
    elif file_path.endswith('.m'):
        content = format_octave_code(content)
    
    # Apply universal formatting
    content = fix_indentation_consistency(content, file_path)
    content = add_missing_blank_lines(content, file_path)
    content = clean_trailing_whitespace(content)
    content = ensure_final_newline(content)
    
    # Check for formatting warnings
    warnings = validate_formatting_rules(content, file_path)
    
    # Write back formatted content if changed
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        except Exception as e:
            print(f"Warning: Could not write formatted content to {file_path}: {e}")
    
    # Report warnings but don't block
    if warnings:
        print(f"Formatting warnings for {file_path}:")
        for warning in warnings[:5]:  # Limit to first 5 warnings
            print(f"  - {warning}")
        if len(warnings) > 5:
            print(f"  - ... and {len(warnings) - 5} more warnings")
    
    sys.exit(0)

if __name__ == "__main__":
    main()