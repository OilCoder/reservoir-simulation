#!/usr/bin/env python3
"""
Validate documentation according to rule 06.

Rule enforced:
- Rule 06: Documentation enforcement - Google Style docstrings (Python), 
  structured comment blocks (Octave), ALL in English, <100 words per docstring
"""

import sys
import re
import os
import json
import ast
from pathlib import Path

def extract_python_docstrings(content):
    """Extract all docstrings from Python code."""
    docstrings = []
    
    try:
        tree = ast.parse(content)
    except SyntaxError:
        # If code doesn't parse, skip docstring validation
        return docstrings
    
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef, ast.Module)):
            docstring = ast.get_docstring(node)
            if docstring:
                line_num = node.lineno if hasattr(node, 'lineno') else 1
                docstrings.append({
                    'content': docstring,
                    'line': line_num,
                    'type': type(node).__name__,
                    'name': getattr(node, 'name', 'module')
                })
    
    return docstrings

def extract_octave_docstrings(content):
    """Extract comment blocks that serve as docstrings in Octave/MATLAB."""
    docstrings = []
    lines = content.split('\n')
    
    in_function = False
    function_name = None
    comment_block = []
    comment_start_line = 0
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Function start
        func_match = re.match(r'^function\s+.*?(\w+)\s*\(', stripped)
        if func_match:
            # Save previous comment block if exists
            if comment_block and function_name:
                docstrings.append({
                    'content': '\n'.join(comment_block),
                    'line': comment_start_line,
                    'type': 'function',
                    'name': function_name
                })
            
            in_function = True
            function_name = func_match.group(1)
            comment_block = []
            continue
        
        # Comment line
        if stripped.startswith('%') and not stripped.startswith('%%'):
            if not comment_block:
                comment_start_line = i
            comment_block.append(stripped[1:].strip())  # Remove % and strip
        elif stripped == '':
            # Empty line, continue collecting if in comment block
            if comment_block:
                comment_block.append('')
        else:
            # Non-comment, non-empty line
            if comment_block and in_function:
                # This comment block belongs to the current function
                docstrings.append({
                    'content': '\n'.join(comment_block),
                    'line': comment_start_line,
                    'type': 'function',
                    'name': function_name
                })
                comment_block = []
            elif comment_block:
                # File-level comment
                docstrings.append({
                    'content': '\n'.join(comment_block),
                    'line': comment_start_line,
                    'type': 'module',
                    'name': 'file_header'
                })
                comment_block = []
            
            # Reset function tracking if we hit 'end'
            if stripped in ['end', 'endfunction']:
                in_function = False
                function_name = None
    
    # Handle final comment block
    if comment_block:
        target_name = function_name if function_name else 'file_footer'
        target_type = 'function' if function_name else 'module'
        docstrings.append({
            'content': '\n'.join(comment_block),
            'line': comment_start_line,
            'type': target_type,
            'name': target_name
        })
    
    return docstrings

def validate_google_style_docstring(docstring_info):
    """Validate Google Style docstring format."""
    violations = []
    content = docstring_info['content']
    line = docstring_info['line']
    name = docstring_info['name']
    doc_type = docstring_info['type']
    
    # Check length (< 100 words)
    word_count = len(content.split())
    if word_count > 100:
        violations.append(f"Line {line}: {doc_type} '{name}' docstring too long: {word_count} words (max 100)")
    
    # Check for English content
    spanish_patterns = [
        r'\b(función|parámetro|retorna|devuelve|variable)\b',
        r'\b(el|la|los|las|un|una|para|por|con|es|son)\b'
    ]
    
    for pattern in spanish_patterns:
        if re.search(pattern, content, re.IGNORECASE):
            violations.append(f"Line {line}: {doc_type} '{name}' docstring appears to contain Spanish (must be English)")
            break
    
    # Check required sections for functions
    if doc_type in ['FunctionDef', 'AsyncFunctionDef']:
        required_sections = ['Args:', 'Returns:', 'Raises:']
        optional_sections = ['Note:', 'Example:', 'Examples:']
        
        # Check for summary (first line should be summary)
        lines = content.split('\n')
        if not lines[0].strip():
            violations.append(f"Line {line}: Function '{name}' docstring should start with summary")
        
        # Check for Args section if function has parameters
        if 'Args:' not in content and '(' in name:  # Rough heuristic
            violations.append(f"Line {line}: Function '{name}' docstring missing 'Args:' section")
        
        # Check for Returns section
        if 'Returns:' not in content and 'return' in content.lower():
            violations.append(f"Line {line}: Function '{name}' docstring missing 'Returns:' section")
    
    # Check basic formatting
    if not content.strip():
        violations.append(f"Line {line}: {doc_type} '{name}' has empty docstring")
    
    return violations

def validate_octave_comment_block(docstring_info):
    """Validate Octave/MATLAB comment block format."""
    violations = []
    content = docstring_info['content']
    line = docstring_info['line']
    name = docstring_info['name']
    doc_type = docstring_info['type']
    
    # Check length (< 100 words)
    word_count = len(content.split())
    if word_count > 100:
        violations.append(f"Line {line}: {doc_type} '{name}' comment block too long: {word_count} words (max 100)")
    
    # Check for English content
    spanish_patterns = [
        r'\b(función|parámetro|retorna|devuelve|variable)\b',
        r'\b(el|la|los|las|un|una|para|por|con|es|son)\b'
    ]
    
    for pattern in spanish_patterns:
        if re.search(pattern, content, re.IGNORECASE):
            violations.append(f"Line {line}: {doc_type} '{name}' comment appears to contain Spanish (must be English)")
            break
    
    # Check basic structure for functions
    if doc_type == 'function' and name != 'file_header':
        lines = [l.strip() for l in content.split('\n') if l.strip()]
        
        if not lines:
            violations.append(f"Line {line}: Function '{name}' has empty comment block")
        else:
            # First line should be summary
            if len(lines[0]) < 10:  # Very short summary
                violations.append(f"Line {line}: Function '{name}' comment should start with descriptive summary")
            
            # Look for input/output documentation
            has_input_doc = any(keyword in content.lower() for keyword in ['input', 'argument', 'parameter', 'param'])
            has_output_doc = any(keyword in content.lower() for keyword in ['output', 'return', 'result'])
            
            # This is advisory, not blocking
            if not has_input_doc and len(lines) > 1:
                violations.append(f"Line {line}: Function '{name}' comment should document input parameters")
    
    return violations

def check_missing_documentation(content, file_path):
    """Check for functions/classes that are missing documentation."""
    violations = []
    
    if file_path.endswith('.py'):
        violations.extend(check_python_missing_docs(content))
    elif file_path.endswith('.m'):
        violations.extend(check_octave_missing_docs(content))
    
    return violations

def check_python_missing_docs(content):
    """Check for Python functions/classes missing docstrings."""
    violations = []
    
    try:
        tree = ast.parse(content)
    except SyntaxError:
        return violations
    
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            # Skip private/internal functions (start with _)
            if node.name.startswith('_'):
                continue
            
            docstring = ast.get_docstring(node)
            if not docstring:
                violations.append(f"Line {node.lineno}: Public function '{node.name}' missing docstring")
        
        elif isinstance(node, ast.ClassDef):
            docstring = ast.get_docstring(node)
            if not docstring:
                violations.append(f"Line {node.lineno}: Class '{node.name}' missing docstring")
    
    return violations

def check_octave_missing_docs(content):
    """Check for Octave functions missing comment blocks."""
    violations = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        func_match = re.match(r'^function\s+.*?(\w+)\s*\(', line.strip())
        if func_match:
            func_name = func_match.group(1)
            
            # Check if next few lines have comments
            has_comment = False
            for j in range(i, min(i + 5, len(lines))):
                if lines[j].strip().startswith('%') and not lines[j].strip().startswith('%%'):
                    has_comment = True
                    break
                elif lines[j].strip() and not lines[j].strip().startswith('%'):
                    break  # Hit non-comment code
            
            if not has_comment:
                violations.append(f"Line {i}: Function '{func_name}' missing comment block documentation")
    
    return violations

def validate_header_documentation(content, file_path):
    """Validate file header documentation."""
    violations = []
    lines = content.split('\n')
    
    # Check for file header within first 10 lines
    has_header = False
    header_content = ""
    
    for i, line in enumerate(lines[:10]):
        if line.strip().startswith(('#', '%', '"""', "'''")):
            has_header = True
            header_content += line + "\n"
    
    if not has_header:
        violations.append("File missing header documentation")
    else:
        # Check header quality
        word_count = len(header_content.split())
        if word_count < 5:
            violations.append("File header documentation too brief (should describe purpose)")
        
        # Check for Spanish in header
        spanish_patterns = [
            r'\b(función|parámetro|retorna|devuelve|variable)\b',
            r'\b(el|la|los|las|un|una|para|por|con|es|son)\b'
        ]
        
        for pattern in spanish_patterns:
            if re.search(pattern, header_content, re.IGNORECASE):
                violations.append("File header contains Spanish text (must be English)")
                break
    
    return violations

def main():
    """Main documentation validation function."""
    if len(sys.argv) < 2:
        print("Usage: validate_documentation.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    # Skip validation for certain file types
    if file_path.endswith(('.json', '.yaml', '.yml', '.md', '.txt', '.mat')):
        sys.exit(0)
    
    # Skip validation for .claude tools (they're meta)
    if '.claude' in file_path:
        sys.exit(0)
    
    # Get content
    content = ""
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception:
            sys.exit(0)
    
    violations = []
    
    # Extract and validate docstrings/comments
    if file_path.endswith('.py'):
        docstrings = extract_python_docstrings(content)
        for doc_info in docstrings:
            violations.extend(validate_google_style_docstring(doc_info))
    elif file_path.endswith('.m'):
        docstrings = extract_octave_docstrings(content)
        for doc_info in docstrings:
            violations.extend(validate_octave_comment_block(doc_info))
    
    # Check for missing documentation
    violations.extend(check_missing_documentation(content, file_path))
    
    # Check file header
    violations.extend(validate_header_documentation(content, file_path))
    
    if violations:
        print(f"Documentation violations in {file_path}:")
        for v in violations:
            print(f"  - {v}")
        
        # Output JSON for advanced control
        result = {
            "status": "error",
            "file": file_path,
            "violations": violations,
            "rules_violated": ["06"]
        }
        print(f"\n{json.dumps(result)}")
        sys.exit(2)  # Block the operation
    
    sys.exit(0)

if __name__ == "__main__":
    main()