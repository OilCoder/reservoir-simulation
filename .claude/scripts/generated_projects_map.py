"""
Auto-generates project_map.md by scanning the entire Geomechanical ML project.

Part of Claude Code management tools for tracking and documenting project structure.
Located in .claude/scripts/ as it's a development utility, not project documentation.

Features:
- Completely dynamic generation following DATA_GENERATION_POLICY
- No hardcoded directory lists or descriptions
- Everything extracted from actual code content
- Comprehensive function and class documentation
- Ignores .claude/ directory to avoid self-referencing
- Supports both Python (.py) and MATLAB/Octave (.m) files
"""

import re
import ast
from typing import Dict, List
from pathlib import Path
from datetime import datetime

# Configure project root and output
PROJECT_ROOT = Path(__file__).parent.parent.parent  # Go up from .claude/scripts/ to workspace/
OUTPUT_FILE = PROJECT_ROOT / "docs" / "project_map.md"

# Code file extensions
CODE_EXTENSIONS = {".py", ".m"}

# Directories to ignore
IGNORE_DIRS = {
    "__pycache__", ".git", ".vscode", "node_modules", 
    ".pytest_cache", ".mypy_cache", "dist", "build",
    ".claude"  # Ignore Claude Code configuration directory
}

def parse_docstring(docstring: str) -> Dict[str, str]:
    """Parse docstring into sections (description, args, returns, etc.)."""
    if not docstring:
        return {'description': '', 'args': '', 'returns': ''}
    
    sections = {'description': '', 'args': '', 'returns': ''}
    lines = docstring.strip().split('\n')
    current_section = 'description'
    section_content = []
    
    for line in lines:
        line = line.strip()
        lower_line = line.lower()
        
        # Check for section headers
        if lower_line.startswith('args:') or lower_line.startswith('arguments:') or lower_line.startswith('parameters:'):
            if section_content:
                sections[current_section] = '\n'.join(section_content).strip()
            current_section = 'args'
            section_content = []
        elif lower_line.startswith('returns:') or lower_line.startswith('return:'):
            if section_content:
                sections[current_section] = '\n'.join(section_content).strip()
            current_section = 'returns'
            section_content = []
        else:
            section_content.append(line)
    
    # Add final section
    if section_content:
        sections[current_section] = '\n'.join(section_content).strip()
    
    return sections

def extract_python_info(filepath: Path) -> Dict:
    """Extract complete information from Python file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Parse AST
        tree = ast.parse(content)
        
        # Module docstring
        module_docstring = ast.get_docstring(tree) or ""
        
        # Extract functions with their docstrings
        functions = []
        classes = []
        
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                func_docstring = ast.get_docstring(node) or ""
                # Parse docstring sections
                parsed_docstring = parse_docstring(func_docstring)
                functions.append({
                    'name': node.name,
                    'docstring': func_docstring,
                    'parsed_docstring': parsed_docstring,
                    'line': node.lineno,
                    'args': [arg.arg for arg in node.args.args]
                })
            elif isinstance(node, ast.ClassDef):
                class_docstring = ast.get_docstring(node) or ""
                parsed_docstring = parse_docstring(class_docstring)
                classes.append({
                    'name': node.name,
                    'docstring': class_docstring,
                    'parsed_docstring': parsed_docstring,
                    'line': node.lineno
                })
        
        return {
            'type': 'Python',
            'module_docstring': module_docstring,
            'functions': functions,
            'classes': classes
        }
        
    except Exception as e:
        return {
            'type': 'Python',
            'error': str(e),
            'module_docstring': "",
            'functions': [],
            'classes': []
        }

def extract_matlab_info(filepath: Path) -> Dict:
    """Extract complete information from MATLAB/Octave file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Find main function and docstring
        main_function = None
        module_docstring_lines = []
        functions = []
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            # Skip empty lines
            if not line:
                i += 1
                continue
                
            # Function definition
            if line.startswith('function '):
                func_match = re.search(r'function\s+(?:.*?=\s*)?(\w+)\s*\(([^)]*)\)', line)
                if func_match:
                    func_name = func_match.group(1)
                    func_args = [arg.strip() for arg in func_match.group(2).split(',') if arg.strip()]
                    
                    # Extract function docstring (comments after function)
                    func_docstring_lines = []
                    j = i + 1
                    while j < len(lines):
                        comment_line = lines[j].strip()
                        if comment_line.startswith('%'):
                            clean_comment = comment_line[1:].strip()
                            if clean_comment and not clean_comment.startswith('====') and not clean_comment.startswith('----'):
                                func_docstring_lines.append(clean_comment)
                        elif comment_line and not comment_line.startswith('%'):
                            break
                        j += 1
                    
                    # If this is the first function, it's the main function
                    if main_function is None:
                        main_function = func_name
                        module_docstring_lines = func_docstring_lines.copy()
                    
                    functions.append({
                        'name': func_name,
                        'docstring': ' '.join(func_docstring_lines),
                        'line': i + 1,
                        'args': func_args,
                        'is_main': main_function == func_name
                    })
            i += 1
        
        return {
            'type': 'MATLAB/Octave',
            'module_docstring': ' '.join(module_docstring_lines),
            'main_function': main_function,
            'functions': functions
        }
        
    except Exception as e:
        return {
            'type': 'MATLAB/Octave',
            'error': str(e),
            'module_docstring': "",
            'functions': []
        }

def scan_project_tree() -> Dict:
    """Scan entire project tree and extract information."""
    project_tree = {}
    processed_files = 0
    
    # Walk through entire project
    for path in PROJECT_ROOT.rglob('*'):
        # Skip ignored directories
        if any(ignore_dir in path.parts for ignore_dir in IGNORE_DIRS):
            continue
            
        # Only process code files
        if path.is_file() and path.suffix in CODE_EXTENSIONS:
            processed_files += 1
            if processed_files <= 5:  # Debug first 5 files
                print(f"Processing file {processed_files}: {path.relative_to(PROJECT_ROOT)}")
            # Get relative path from project root
            rel_path = path.relative_to(PROJECT_ROOT)
            
            # Create directory structure
            current_level = project_tree
            
            # Debug path structure for first few files
            if processed_files <= 3:
                print(f"  Path parts: {rel_path.parts}")
            
            for part in rel_path.parts[:-1]:  # All parts except filename
                if '_dirs' not in current_level:
                    current_level['_dirs'] = {}
                if '_files' not in current_level:
                    current_level['_files'] = {}
                if part not in current_level['_dirs']:
                    current_level['_dirs'][part] = {'_dirs': {}, '_files': {}}
                current_level = current_level['_dirs'][part]
            
            # Add file information
            if '_files' not in current_level:
                current_level['_files'] = {}
                
            filename = rel_path.parts[-1]
            
            # Extract file information based on type
            if path.suffix == '.py':
                file_info = extract_python_info(path)
            elif path.suffix == '.m':
                file_info = extract_matlab_info(path)
            else:
                continue
                
            file_info['path'] = str(rel_path)
            file_info['size'] = path.stat().st_size
            current_level['_files'][filename] = file_info
    
    print(f"Total files processed: {processed_files}")
    return project_tree

def generate_tree_structure(tree: Dict, prefix: str = "") -> str:
    """Generate ASCII tree structure."""
    result = ""
    
    # Get all directories and files
    dirs = tree.get('_dirs', {})
    files = tree.get('_files', {})
    
    # Combine and sort
    all_items = []
    for name in sorted(dirs.keys()):
        all_items.append((name, 'dir', dirs[name]))
    for name in sorted(files.keys()):
        all_items.append((name, 'file', files[name]))
    
    for i, (name, item_type, item_data) in enumerate(all_items):
        is_last_item = (i == len(all_items) - 1)
        
        # Tree symbols
        if is_last_item:
            current_prefix = prefix + "└── "
            next_prefix = prefix + "    "
        else:
            current_prefix = prefix + "├── "
            next_prefix = prefix + "│   "
        
        if item_type == 'dir':
            result += f"{current_prefix}{name}/\n"
            result += generate_tree_structure(item_data, next_prefix)
        else:
            # File - show type info in comment
            result += f"{current_prefix}{name}\n"
    
    return result

def generate_directory_documentation(tree: Dict, path_parts: List[str] = []) -> str:
    """Generate detailed documentation for each directory."""
    result = ""
    
    # Current directory path
    current_path = '/'.join(path_parts) if path_parts else 'PROJECT_ROOT'
    
    # Get files in current directory
    files = tree.get('_files', {})
    if files:
        result += f"\n## {current_path}/\n\n"
        
        # Group files by type
        by_type = {}
        for filename, file_info in files.items():
            file_type = file_info.get('type', 'Unknown')
            if file_type not in by_type:
                by_type[file_type] = []
            by_type[file_type].append((filename, file_info))
        
        # Document each type
        for file_type in sorted(by_type.keys()):
            type_files = by_type[file_type]
            result += f"### {file_type} Files ({len(type_files)} files)\n\n"
            
            for filename, file_info in sorted(type_files):
                result += f"#### `{filename}`\n\n"
                
                # Module description
                module_doc = file_info.get('module_docstring', '')
                if module_doc:
                    result += f"**Description:** {module_doc}\n\n"
                
                # Functions
                functions = file_info.get('functions', [])
                if functions:
                    result += "**Functions:**\n\n"
                    for func in functions:
                        result += f"**`{func['name']}({', '.join(func['args'])})`** *(line {func['line']})*\n\n"
                        
                        # Check if we have parsed docstring sections
                        parsed_doc = func.get('parsed_docstring', {})
                        if parsed_doc and any(parsed_doc.values()):
                            # Description
                            if parsed_doc.get('description'):
                                result += f"{parsed_doc['description']}\n\n"
                            
                            # Args
                            if parsed_doc.get('args'):
                                result += f"**Args:**\n{parsed_doc['args']}\n\n"
                            
                            # Returns
                            if parsed_doc.get('returns'):
                                result += f"**Returns:**\n{parsed_doc['returns']}\n\n"
                        elif func.get('docstring'):
                            # Fallback to raw docstring
                            result += f"{func['docstring']}\n\n"
                        
                        result += "---\n\n"
                
                # Classes (for Python)
                classes = file_info.get('classes', [])
                if classes:
                    result += "**Classes:**\n\n"
                    for cls in classes:
                        result += f"**`{cls['name']}`** *(line {cls['line']})*\n\n"
                        
                        # Check if we have parsed docstring sections
                        parsed_doc = cls.get('parsed_docstring', {})
                        if parsed_doc and any(parsed_doc.values()):
                            # Description
                            if parsed_doc.get('description'):
                                result += f"{parsed_doc['description']}\n\n"
                            
                            # Args
                            if parsed_doc.get('args'):
                                result += f"**Args:**\n{parsed_doc['args']}\n\n"
                            
                            # Returns
                            if parsed_doc.get('returns'):
                                result += f"**Returns:**\n{parsed_doc['returns']}\n\n"
                        elif cls.get('docstring'):
                            # Fallback to raw docstring
                            result += f"{cls['docstring']}\n\n"
                        
                        result += "---\n\n"
                
                # Error info if any
                if 'error' in file_info:
                    result += f"**Parse Error:** {file_info['error']}\n\n"
                
                result += "\n"
    
    # Recurse into subdirectories
    dirs = tree.get('_dirs', {})
    for dirname in sorted(dirs.keys()):
        result += generate_directory_documentation(dirs[dirname], path_parts + [dirname])
    
    return result

def generate_project_map():
    """Generate complete project map."""
    print(f"Project root: {PROJECT_ROOT}")
    print("Scanning project tree...")
    
    # Debug: List some files to make sure we can see them
    all_files = list(PROJECT_ROOT.rglob('*.py')) + list(PROJECT_ROOT.rglob('*.m'))
    print(f"Found {len(all_files)} code files total")
    for f in all_files[:10]:  # Show first 10
        print(f"  - {f.relative_to(PROJECT_ROOT)}")
    if len(all_files) > 10:
        print(f"  ... and {len(all_files) - 10} more")
    
    project_tree = scan_project_tree()
    
    print("Generating documentation...")
    
    # Count total files
    total_files = 0
    def count_files(tree):
        nonlocal total_files
        total_files += len(tree.get('_files', {}))
        for subdir in tree.get('_dirs', {}).values():
            count_files(subdir)
    
    count_files(project_tree)
    
    # Generate content
    content = f"""# Reservoir Simulation Project Map

*Auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*

## Overview

This document provides a completely dynamic map of the project structure. 
Everything is extracted automatically from actual code content, following DATA_GENERATION_POLICY.

**Project Statistics:**
- Total code files analyzed: {total_files}
- Generated from: Live codebase scan
- No hardcoded values: All content extracted dynamically

## Project Tree Structure

```
reservoir-simulation/
{generate_tree_structure(project_tree)}```

## Complete File Documentation

The following sections provide detailed documentation for each file, 
including all functions, classes, and their docstrings.

{generate_directory_documentation(project_tree)}

---

*This documentation is auto-generated and reflects the current state of the codebase.*
"""

    # Write to file
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Project map generated: {OUTPUT_FILE}")
    print(f"Total files documented: {total_files}")

if __name__ == "__main__":
    generate_project_map()