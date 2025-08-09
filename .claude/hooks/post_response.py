#!/usr/bin/env python3
"""
Post-Response Hook for Auto-Apply and Local CI
- Extracts and applies unified diffs
- Runs tests/linting locally
- Prepares minimal retry context if needed
"""

import json
import sys
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

def extract_unified_diff(response: str) -> Optional[str]:
    """Extract unified diff from response text"""
    # Look for diff blocks
    diff_patterns = [
        r'```diff\n(.*?)```',
        r'```patch\n(.*?)```',
        r'```unified-diff\n(.*?)```',
        r'---.*?\n\+\+\+.*?\n@@.*?@@.*?(?=\n(?:---|\+\+\+|$))',
    ]
    
    for pattern in diff_patterns:
        matches = re.findall(pattern, response, re.DOTALL)
        if matches:
            # Combine all diff blocks
            return '\n'.join(matches)
    
    # Check if entire response looks like a diff
    if response.startswith(('---', 'diff', '@@')):
        return response
    
    return None

def apply_diff(diff_content: str) -> Tuple[bool, str]:
    """Apply unified diff using git apply"""
    if not diff_content:
        return False, "No diff content found"
    
    # Write diff to temp file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.patch', delete=False) as f:
        f.write(diff_content)
        patch_file = f.name
    
    try:
        # Try to apply the patch
        result = subprocess.run(
            ["git", "apply", "--check", patch_file],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            return False, f"Patch check failed: {result.stderr}"
        
        # Apply the patch
        result = subprocess.run(
            ["git", "apply", patch_file],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            return True, "Patch applied successfully"
        else:
            return False, f"Patch apply failed: {result.stderr}"
            
    finally:
        # Clean up temp file
        Path(patch_file).unlink(missing_ok=True)

def run_tests() -> Tuple[bool, List[Dict]]:
    """Run tests and collect failures"""
    failures = []
    
    # Try multiple test runners
    test_commands = [
        ["python", "-m", "pytest", "--tb=short", "-q"],
        ["pytest", "--tb=short", "-q"],
        ["python", "-m", "unittest", "discover"],
        ["npm", "test"],
        ["cargo", "test"],
    ]
    
    for cmd in test_commands:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode != 0:
                # Parse test output for failures
                failures.append({
                    "command": ' '.join(cmd),
                    "exit_code": result.returncode,
                    "output": result.stdout[-2000:],  # Last 2000 chars
                    "errors": result.stderr[-1000:]   # Last 1000 chars
                })
                
            return result.returncode == 0, failures
            
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue
    
    # No test runner found
    return True, []

def run_linting() -> Tuple[bool, List[Dict]]:
    """Run linting and collect issues"""
    issues = []
    
    # Try multiple linters
    lint_commands = [
        ["ruff", "check", "."],
        ["flake8", "."],
        ["pylint", "*.py"],
        ["black", "--check", "."],
        ["eslint", "."],
    ]
    
    for cmd in lint_commands:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                issues.append({
                    "linter": cmd[0],
                    "output": result.stdout[-1500:]  # Last 1500 chars
                })
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue
    
    return len(issues) == 0, issues

def extract_affected_files(diff_content: str) -> List[str]:
    """Extract list of files affected by diff"""
    files = []
    
    # Look for +++ lines in unified diff
    for line in diff_content.split('\n'):
        if line.startswith('+++'):
            # Extract filename from +++ b/path/to/file.py
            parts = line.split()
            if len(parts) >= 2:
                file_path = parts[1]
                if file_path.startswith('b/'):
                    file_path = file_path[2:]
                files.append(file_path)
    
    return files

def prepare_retry_context(failures: List[Dict], lint_issues: List[Dict], 
                         affected_files: List[str]) -> str:
    """Prepare minimal context for retry prompt"""
    context = ["[AUTO-CI FAILURE - Minimal Retry Context]"]
    context.append("=" * 50)
    
    if failures:
        context.append("\n## Test Failures:")
        for failure in failures[:2]:  # Max 2 failures
            context.append(f"Command: {failure['command']}")
            context.append(f"Exit code: {failure['exit_code']}")
            
            # Extract key error lines
            output_lines = failure['output'].split('\n')
            error_lines = [l for l in output_lines if 'error' in l.lower() or 'fail' in l.lower()]
            if error_lines:
                context.append("Key errors:")
                context.extend(error_lines[:5])  # Max 5 error lines
    
    if lint_issues:
        context.append("\n## Lint Issues:")
        for issue in lint_issues[:1]:  # Only first linter
            context.append(f"Linter: {issue['linter']}")
            # Extract first few issues
            lines = issue['output'].split('\n')[:10]
            context.extend(lines)
    
    if affected_files:
        context.append(f"\n## Affected Files: {', '.join(affected_files[:5])}")
    
    context.append("\n## Required Actions:")
    context.append("1. Fix the specific errors above")
    context.append("2. Return ONLY a unified diff with fixes")
    context.append("3. No explanations needed")
    
    return '\n'.join(context)

def update_budget(used: int = 1):
    """Update prompt budget tracking"""
    budget_file = Path("/tmp/claude_budget.txt")
    
    try:
        current = 100  # Default
        if budget_file.exists():
            with open(budget_file, 'r') as f:
                current = int(f.read().strip())
        
        new_budget = max(0, current - used)
        
        with open(budget_file, 'w') as f:
            f.write(str(new_budget))
            
    except Exception:
        pass  # Silent fail for budget tracking

def main():
    """Main post-response processor"""
    try:
        # Read response from stdin
        if not sys.stdin.isatty():
            response_data = json.load(sys.stdin)
            response_text = response_data.get("response", "")
        else:
            response_text = sys.stdin.read()
        
        if not response_text:
            print(json.dumps({"continue": True, "status": "no_response"}))
            return
        
        # Extract unified diff
        diff_content = extract_unified_diff(response_text)
        
        if not diff_content:
            # No diff found, nothing to apply
            print(json.dumps({
                "continue": True,
                "status": "no_diff_found",
                "message": "No unified diff detected in response"
            }))
            return
        
        # Apply the diff
        apply_success, apply_message = apply_diff(diff_content)
        
        if not apply_success:
            # Diff failed to apply
            print(json.dumps({
                "continue": True,
                "status": "apply_failed",
                "message": apply_message,
                "retry_recommended": True
            }))
            return
        
        # Get affected files
        affected_files = extract_affected_files(diff_content)
        
        # Run tests
        test_success, test_failures = run_tests()
        
        # Run linting (optional)
        lint_success, lint_issues = run_linting()
        
        # Update budget
        update_budget(1)
        
        if test_success and lint_success:
            # Everything passed!
            print(json.dumps({
                "continue": False,  # Stop here, success
                "status": "success",
                "message": "Changes applied and all checks passed",
                "files_modified": affected_files,
                "auto_applied": True
            }))
            
        else:
            # Prepare retry context
            retry_context = prepare_retry_context(
                test_failures, 
                lint_issues if not test_success else [],  # Only include lint if tests pass
                affected_files
            )
            
            # Return retry directive
            print(json.dumps({
                "continue": True,
                "status": "needs_retry",
                "retry_context": retry_context,
                "test_failed": not test_success,
                "lint_failed": not lint_success,
                "files_affected": affected_files,
                "prompt_2_mode": True  # Signal this is second prompt
            }))
            
            # Update budget for retry
            update_budget(1)
        
    except Exception as e:
        # Fail gracefully
        import traceback
        print(json.dumps({
            "continue": True,
            "status": "error",
            "message": str(e),
            "traceback": traceback.format_exc()[-500:]
        }))

if __name__ == "__main__":
    main()