#!/usr/bin/env python3
"""
Route files to correct directories according to rules 03 and 04.

Rules enforced:
- Rule 03: All tests go in tests/ directory (gitignored), proper naming test_NN_*
- Rule 04: All debug code goes in debug/ directory (gitignored), proper naming dbg_*
"""

import sys
import os
import json
import re
from pathlib import Path

def determine_file_type(content, file_path):
    """Determine if file is test, debug, or production code."""
    basename = os.path.basename(file_path)
    content_lower = content.lower()
    
    # Check filename patterns first
    if re.match(r'^test_\d{2}_.*\.(py|m)$', basename):
        return 'test'
    elif re.match(r'^dbg_.*\.(py|m)$', basename):
        return 'debug'
    
    # Check content patterns
    test_indicators = [
        'import unittest',
        'import pytest',
        'from unittest',
        'def test_',
        'class test',
        'assert ',
        'unittest.main',
        'pytest.main',
        # Octave/MATLAB test patterns
        'function test_',
        'assert(',
        'test_result',
    ]
    
    debug_indicators = [
        'print("debug',
        'disp("debug',  
        'debug_flag',
        'debug_mode',
        'pdb.set_trace',
        'import pdb',
        'breakpoint(',
        # Octave debug patterns
        'keyboard',  # Octave debugger
        'dbstop',
        'debug_info',
    ]
    
    # Count indicators
    test_score = sum(1 for indicator in test_indicators if indicator in content_lower)
    debug_score = sum(1 for indicator in debug_indicators if indicator in content_lower)
    
    if test_score > debug_score and test_score > 0:
        return 'test'
    elif debug_score > 0:
        return 'debug'
    else:
        return 'production'

def check_test_file_requirements(content, file_path):
    """Check test file specific requirements."""
    violations = []
    basename = os.path.basename(file_path)
    
    # Check test file naming convention
    if not re.match(r'^test_\d{2}_.*\.(py|m)$', basename):
        violations.append(f"Test file '{basename}' must follow naming: test_NN_module_purpose.ext")
    
    # Check if test file is in correct directory
    parent_dir = os.path.basename(os.path.dirname(file_path))
    if parent_dir != 'test' and parent_dir != 'tests':
        violations.append(f"Test file must be in 'test/' or 'tests/' directory, found in: {parent_dir}")
    
    lines = content.split('\n')
    
    # Check for self-contained requirement
    external_dependencies = []
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        # Check for external file dependencies
        if re.search(r'(load|import|require|include).*\.\.(\/|\\)', line):
            external_dependencies.append(f"Line {i}: External dependency outside test directory")
        
        # Check for hardcoded paths
        if re.search(r'["\']\/.*?["\']', line) or re.search(r'["\'][A-Z]:\\.*?["\']', line):
            violations.append(f"Line {i}: Hardcoded absolute path found - tests should be portable")
    
    violations.extend(external_dependencies)
    
    # Check for order independence
    if re.search(r'global\s+\w+', content) or re.search(r'persistent\s+\w+', content):
        violations.append("Test uses global/persistent variables - may not be order-independent")
    
    return violations

def check_debug_file_requirements(content, file_path):
    """Check debug file specific requirements."""
    violations = []
    basename = os.path.basename(file_path)
    
    # Check debug file naming convention
    if not re.match(r'^dbg_.*\.(py|m)$', basename):
        violations.append(f"Debug file '{basename}' must follow naming: dbg_purpose.ext")
    
    # Check if debug file is in correct directory
    parent_dir = os.path.basename(os.path.dirname(file_path))
    if parent_dir != 'debug':
        violations.append(f"Debug file must be in 'debug/' directory, found in: {parent_dir}")
    
    # Check for imports from production code
    lines = content.split('\n')
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        # Check for production code imports
        if re.search(r'(import|from|addpath).*\.\.(\/|\\)(mrst_simulation_scripts|dashboard|config)', line):
            violations.append(f"Line {i}: Debug file should not import from production directories")
    
    return violations

def check_production_file_isolation(content, file_path):
    """Check that production files don't import debug/test code."""
    violations = []
    
    # Skip if this is already a test or debug file
    file_type = determine_file_type(content, file_path)
    if file_type in ['test', 'debug']:
        return violations
    
    lines = content.split('\n')
    for i, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith(('#', '%', '//')):
            continue
        
        # Check for test/debug imports
        if re.search(r'(import|from|addpath).*(test|debug)', line, re.IGNORECASE):
            violations.append(f"Line {i}: Production code should not import test/debug modules")
        
        # Check for test function calls
        if re.search(r'\btest_\w+\s*\(', line):
            violations.append(f"Line {i}: Production code should not call test functions")
        
        # Check for debug function calls
        if re.search(r'\bdbg_\w+\s*\(', line):
            violations.append(f"Line {i}: Production code should not call debug functions")
    
    return violations

def suggest_correct_location(file_path, file_type):
    """Suggest correct location for misplaced files."""
    basename = os.path.basename(file_path)
    project_root = "/workspaces/simulation"
    
    if file_type == 'test':
        if not basename.startswith('test_'):
            # Suggest proper test naming
            number = "01"  # Default number
            module_name = basename.replace('.py', '').replace('.m', '')
            ext = os.path.splitext(basename)[1]
            suggested_name = f"test_{number}_{module_name}{ext}"
        else:
            suggested_name = basename
        
        return f"{project_root}/test/{suggested_name}"
    
    elif file_type == 'debug':
        if not basename.startswith('dbg_'):
            # Suggest proper debug naming
            module_name = basename.replace('.py', '').replace('.m', '')
            ext = os.path.splitext(basename)[1]
            suggested_name = f"dbg_{module_name}{ext}"
        else:
            suggested_name = basename
        
        return f"{project_root}/debug/{suggested_name}"
    
    return None

def ensure_directory_exists(directory):
    """Ensure target directory exists."""
    try:
        os.makedirs(directory, exist_ok=True)
        return True
    except Exception as e:
        return False

def main():
    """Main routing function."""
    if len(sys.argv) < 2:
        print("Usage: route_files.py <file_path>")
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
    file_type = determine_file_type(content, file_path)
    
    # Run type-specific checks
    if file_type == 'test':
        violations.extend(check_test_file_requirements(content, file_path))
    elif file_type == 'debug':
        violations.extend(check_debug_file_requirements(content, file_path))
    else:
        violations.extend(check_production_file_isolation(content, file_path))
    
    # Check if file is in wrong location
    current_dir = os.path.basename(os.path.dirname(file_path))
    
    if file_type == 'test' and current_dir not in ['test', 'tests']:
        suggested_location = suggest_correct_location(file_path, file_type)
        violations.append(f"Test file should be moved to: {suggested_location}")
    elif file_type == 'debug' and current_dir != 'debug':
        suggested_location = suggest_correct_location(file_path, file_type)
        violations.append(f"Debug file should be moved to: {suggested_location}")
    
    if violations:
        print(f"File routing violations in {file_path}:")
        for v in violations:
            print(f"  - {v}")
        
        # Output JSON for advanced control
        result = {
            "status": "error",
            "file": file_path,
            "violations": violations,
            "rules_violated": ["03", "04"],
            "detected_type": file_type,
            "suggested_location": suggest_correct_location(file_path, file_type)
        }
        print(f"\n{json.dumps(result)}")
        sys.exit(2)  # Block the operation
    
    sys.exit(0)

if __name__ == "__main__":
    main()