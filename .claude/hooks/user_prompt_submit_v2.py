#!/usr/bin/env python3
"""
SSOW (Single Shot One Way) Router Hook - Version 2
- Structured Task Packets with acceptance criteria
- AST-based signature extraction
- Template support for common patterns
- Batch change accumulation
"""

import json
import sys
import re
import os
import subprocess
import ast
import yaml
from typing import Dict, List, Optional, Any
from pathlib import Path

# Cache for expensive operations
_cheatsheet_cache = None
_template_cache = {}

def extract_function_signatures(file_path: str, max_signatures: int = 15) -> List[str]:
    """Extract public function/class signatures using AST parsing"""
    signatures = []
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Handle Python files
        if file_path.endswith('.py'):
            tree = ast.parse(content)
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if not node.name.startswith('_'):
                        args = []
                        for arg in node.args.args:
                            args.append(arg.arg)
                        sig = f"def {node.name}({', '.join(args)})"
                        if node.returns:
                            sig += f" -> {ast.unparse(node.returns)}"
                        signatures.append(sig)
                        
                elif isinstance(node, ast.ClassDef):
                    if not node.name.startswith('_'):
                        bases = [ast.unparse(b) for b in node.bases]
                        sig = f"class {node.name}"
                        if bases:
                            sig += f"({', '.join(bases)})"
                        signatures.append(sig)
                        
                if len(signatures) >= max_signatures:
                    break
                    
        # Handle Octave/MATLAB files
        elif file_path.endswith(('.m', '.mat')):
            # Simple regex for function signatures
            func_pattern = r'^function\s+(?:\[?[\w,\s]+\]?\s*=\s*)?(\w+)\s*\([^)]*\)'
            for line in content.split('\n'):
                match = re.match(func_pattern, line.strip())
                if match:
                    signatures.append(f"function {match.group(0)}")
                    if len(signatures) >= max_signatures:
                        break
                        
    except Exception as e:
        pass  # Silently fail for unparseable files
    
    return signatures

def infer_acceptance_criteria(prompt: str, template: Optional[Dict] = None) -> List[str]:
    """Infer acceptance criteria from prompt and optional template"""
    criteria = []
    prompt_lower = prompt.lower()
    
    # Template-based criteria
    if template and 'acceptance_criteria' in template:
        criteria.extend(template['acceptance_criteria'])
    
    # Keyword-based inference
    if 'fix' in prompt_lower or 'bug' in prompt_lower:
        criteria.append("Bug/issue is resolved")
        criteria.append("No new failures introduced")
        
    if 'test' in prompt_lower:
        criteria.append("All tests pass")
        criteria.append("Coverage maintained or improved")
        
    if 'refactor' in prompt_lower:
        criteria.append("Functionality unchanged")
        criteria.append("Code cleaner/more maintainable")
        
    if 'performance' in prompt_lower or 'optimize' in prompt_lower:
        criteria.append("Performance improved or maintained")
        criteria.append("No functionality regression")
        
    if 'add' in prompt_lower or 'implement' in prompt_lower or 'create' in prompt_lower:
        criteria.append("New functionality works as specified")
        criteria.append("Integrates with existing code")
        
    # Default criteria if none found
    if not criteria:
        criteria = [
            "Code changes achieve stated objective",
            "No regressions in existing functionality",
            "Code follows project conventions"
        ]
    
    return criteria[:5]  # Limit to 5 most relevant

def compress_hunks(hunks: Dict[str, str], max_chars: int = 80000) -> Dict[str, str]:
    """Compress hunks to fit within token budget"""
    compressed = {}
    total_chars = 0
    
    # Priority: files with most changes first
    sorted_files = sorted(hunks.items(), key=lambda x: len(x[1]), reverse=True)
    
    for file_path, hunk in sorted_files:
        if total_chars >= max_chars:
            break
            
        # Truncate large hunks
        if len(hunk) > 10000:
            # Keep first and last parts
            hunk = hunk[:5000] + "\n... [truncated] ...\n" + hunk[-5000:]
        
        remaining = max_chars - total_chars
        if len(hunk) <= remaining:
            compressed[file_path] = hunk
            total_chars += len(hunk)
        else:
            compressed[file_path] = hunk[:remaining] + "\n... [truncated]"
            break
    
    return compressed

def load_cheatsheet() -> str:
    """Load and cache the coding cheatsheet"""
    global _cheatsheet_cache
    
    if _cheatsheet_cache is not None:
        return _cheatsheet_cache
    
    cheatsheet_path = Path("/workspaces/claudeclean/.claude/rules/10-code-cheatsheet.md")
    if cheatsheet_path.exists():
        with open(cheatsheet_path, 'r') as f:
            _cheatsheet_cache = f.read()[:2000]  # Limit size
    else:
        _cheatsheet_cache = "Follow project conventions"
    
    return _cheatsheet_cache

def load_template(template_name: str) -> Optional[Dict]:
    """Load template from templates directory"""
    global _template_cache
    
    if template_name in _template_cache:
        return _template_cache[template_name]
    
    template_path = Path(f"/workspaces/claudeclean/.claude/templates/{template_name}.yml")
    if template_path.exists():
        with open(template_path, 'r') as f:
            _template_cache[template_name] = yaml.safe_load(f)
            return _template_cache[template_name]
    
    return None

def detect_template(prompt: str) -> Optional[str]:
    """Detect which template to use based on prompt"""
    prompt_lower = prompt.lower()
    
    if 'fix' in prompt_lower or 'bug' in prompt_lower or 'error' in prompt_lower:
        return 'fix'
    elif 'refactor' in prompt_lower:
        return 'refactor'
    elif 'add' in prompt_lower or 'implement' in prompt_lower or 'feature' in prompt_lower:
        return 'feature'
    
    return None

def build_task_packet(prompt: str, route: Dict, hunks: Dict, budget: int) -> str:
    """Build structured YAML task packet for SSOW approach"""
    
    # Detect and load template
    template_name = detect_template(prompt)
    template = load_template(template_name) if template_name else None
    
    # Extract signatures from modified files
    all_signatures = []
    for file_path in list(hunks.keys())[:10]:  # Limit to 10 files
        if os.path.exists(file_path):
            sigs = extract_function_signatures(file_path, max_signatures=5)
            if sigs:
                all_signatures.append({file_path: sigs})
    
    # Build structured packet
    packet = {
        "task_packet": {
            "version": "2.0-SSOW",
            "objective": prompt[:500],  # Full prompt up to 500 chars
            "agent": route["agent"],
            "routing_reason": route["reason"],
            "budget_remaining": budget,
            
            "constraints": {
                "scope_files": list(hunks.keys())[:10],
                "change_budget": {
                    "lines_max": 400,
                    "files_max": 10
                },
                "time_limit": "single_shot"  # Emphasize 1-shot completion
            },
            
            "acceptance_criteria": infer_acceptance_criteria(prompt, template),
            
            "context": {
                "modified_files_count": len(hunks),
                "signatures": all_signatures if all_signatures else "No signatures extracted",
                "template_used": template_name or "none"
            },
            
            "inputs": {
                "diffs_or_hunks": compress_hunks(hunks, max_chars=60000),
                "todo_markers": extract_todo_markers(hunks),
            },
            
            "output_spec": {
                "format": "unified_diff_only",
                "include": ["code_changes", "test_updates", "minimal_docs"],
                "exclude": ["explanations", "reasoning", "summaries"],
                "max_response_tokens": 4000
            },
            
            "rules_summary": load_cheatsheet()[:1000]  # Compact rules
        }
    }
    
    # Convert to YAML for structured readability
    yaml_packet = yaml.dump(packet, default_flow_style=False, width=120)
    
    # Add directive header
    header = f"""[SSOW TASK PACKET v2.0]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL: Complete in ONE response. No explanations.
Output: Unified diff ONLY. Include tests if needed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"""
    
    return header + yaml_packet

def extract_todo_markers(hunks: Dict[str, str]) -> List[str]:
    """Extract TODO/CLAUDE markers from hunks"""
    markers = []
    todo_pattern = r'#\s*(TODO|CLAUDE|FIXME):\s*(.+)'
    
    for file_path, hunk in hunks.items():
        for match in re.finditer(todo_pattern, hunk):
            markers.append(f"{file_path}: {match.group(2)}")
    
    return markers[:10]  # Limit to 10 markers

def should_batch_changes(prompt: str, existing_todos: List[str]) -> bool:
    """Determine if we should wait to batch more changes"""
    # Don't batch if explicit urgency
    if any(word in prompt.lower() for word in ['now', 'urgent', 'immediately', 'asap']):
        return False
    
    # Batch if we have pending TODOs and this adds more
    if existing_todos and 'todo' in prompt.lower():
        return True
    
    # Batch if small change
    if len(prompt) < 100:
        return True
    
    return False

def get_budget_estimate() -> int:
    """Enhanced budget estimation"""
    # Check environment variable
    budget = os.environ.get("CLAUDE_REMAINING_PROMPTS")
    if budget and budget.isdigit():
        return int(budget)
    
    # Check for budget file (could be updated by other tools)
    budget_file = Path("/tmp/claude_budget.txt")
    if budget_file.exists():
        try:
            with open(budget_file, 'r') as f:
                return int(f.read().strip())
        except:
            pass
    
    # Conservative default
    return 100

def route_prompt(prompt: str, budget_remaining: int = 999) -> Dict:
    """Enhanced routing with SSOW awareness"""
    prompt_lower = prompt.lower().strip()
    
    # Ultra-conservative mode for very low budget
    if budget_remaining < 10:
        return {
            "agent": "coder",
            "reason": "critical_budget_conservation", 
            "specialized": False,
            "ssow_mode": True  # Force single-shot mode
        }
    
    # Conservative mode
    if budget_remaining < 25:
        return {
            "agent": "coder",
            "reason": "budget_conservation",
            "specialized": False,
            "ssow_mode": True
        }
    
    # Explicit agent requests
    if re.search(r'\b(only|just)\s+(test|testing)\b', prompt_lower):
        return {"agent": "tester", "reason": "explicit_test", "specialized": True, "ssow_mode": False}
    
    if re.search(r'\b(only|just)\s+(debug|debugging)\b', prompt_lower):
        return {"agent": "debugger", "reason": "explicit_debug", "specialized": True, "ssow_mode": False}
    
    # Specialized tasks (only if budget allows)
    if budget_remaining > 50:
        if re.search(r'\b(test|pytest|unittest|coverage|assert)\b', prompt_lower):
            return {"agent": "tester", "reason": "test_keywords", "specialized": True, "ssow_mode": False}
        
        if re.search(r'\b(debug|trace|investigate|diagnose|broken|fix.*bug)\b', prompt_lower):
            return {"agent": "debugger", "reason": "debug_keywords", "specialized": True, "ssow_mode": False}
    
    # Default: coder in SSOW mode
    return {
        "agent": "coder", 
        "reason": "default",
        "specialized": False,
        "ssow_mode": True
    }

def collect_enhanced_diff_hunks(max_chars: int = 60000, context_lines: int = 40) -> Dict[str, str]:
    """Enhanced diff collection with better context"""
    hunks = {}
    total_chars = 0
    
    try:
        # Get both staged and unstaged changes
        for diff_type in ['--cached', '']:  # staged first, then unstaged
            result = subprocess.run(
                ["git", "diff", diff_type, "--name-only"],
                capture_output=True, text=True
            )
            
            if result.returncode != 0:
                continue
            
            modified_files = [f.strip() for f in result.stdout.split('\n') if f.strip()]
            
            for file_path in modified_files:
                if total_chars >= max_chars or file_path in hunks:
                    continue
                    
                if not os.path.exists(file_path):
                    continue
                
                # Get unified diff with more context
                diff_result = subprocess.run(
                    ["git", "diff", diff_type, f"-U{context_lines}", "--", file_path],
                    capture_output=True, text=True
                )
                
                if diff_result.returncode == 0 and diff_result.stdout:
                    remaining_chars = max_chars - total_chars
                    hunk = diff_result.stdout[:remaining_chars]
                    hunks[file_path] = hunk
                    total_chars += len(hunk)
        
        # If no git changes, check for recently modified files
        if not hunks:
            result = subprocess.run(
                ["find", ".", "-type", "f", "-name", "*.py", "-o", "-name", "*.m", 
                 "-mmin", "-10"],  # Files modified in last 10 minutes
                capture_output=True, text=True
            )
            recent_files = [f.strip() for f in result.stdout.split('\n') if f.strip()][:5]
            
            for file_path in recent_files:
                with open(file_path, 'r') as f:
                    content = f.read()[:5000]  # First 5000 chars
                    hunks[file_path] = f"RECENT FILE (no git diff):\n{content}"
                    
    except Exception as e:
        hunks["error"] = f"Failed to collect diffs: {str(e)}"
    
    return hunks

def main():
    """Main SSOW router execution"""
    try:
        # Get prompt from stdin or command line
        prompt = ""
        if not sys.stdin.isatty():
            try:
                data = json.load(sys.stdin)
                prompt = data.get("prompt", "")
            except json.JSONDecodeError:
                # Try reading as plain text
                sys.stdin.seek(0)
                prompt = sys.stdin.read()
        
        if not prompt and len(sys.argv) > 1:
            prompt = ' '.join(sys.argv[1:])
        
        if not prompt.strip():
            print(json.dumps({"continue": True}))
            return
        
        # Get enhanced budget estimate
        budget = get_budget_estimate()
        
        # Route with SSOW awareness
        route = route_prompt(prompt, budget)
        
        # Collect enhanced context
        hunks = collect_enhanced_diff_hunks(max_chars=60000, context_lines=40)
        
        # Check if we should batch (optional)
        existing_todos = extract_todo_markers(hunks)
        if should_batch_changes(prompt, existing_todos) and budget > 50:
            response = {
                "continue": True,
                "additionalContext": f"[BATCHING] Accumulating changes. Current TODOs: {len(existing_todos)}",
                "agent": "none",
                "batch_mode": True
            }
            print(json.dumps(response))
            return
        
        # Build SSOW task packet
        if route.get("ssow_mode", False):
            context = build_task_packet(prompt, route, hunks, budget)
        else:
            # Fall back to original compact context for specialized agents
            context = create_compact_context(route, prompt, hunks)
        
        # Return enhanced response
        response = {
            "continue": True,
            "agent": route["agent"],
            "additionalContext": context,
            "routingReason": route["reason"],
            "budgetRemaining": budget,
            "ssowMode": route.get("ssow_mode", False),
            "templateUsed": detect_template(prompt) or "none"
        }
        
        print(json.dumps(response, indent=2))
        
    except Exception as e:
        # Enhanced error handling
        import traceback
        error_response = {
            "continue": True,
            "additionalContext": f"[ROUTER ERROR - Falling back to default]\nError: {str(e)}\n",
            "agent": "coder",
            "error": str(e),
            "traceback": traceback.format_exc()[-500:]  # Last 500 chars of traceback
        }
        print(json.dumps(error_response))

# Helper function from original (kept for compatibility)
def create_compact_context(route: Dict, prompt: str, hunks: Dict[str, str]) -> str:
    """Original compact context creator for backward compatibility"""
    agent = route["agent"]
    specialized = route.get("specialized", False)
    
    directive = f"""[ROUTER] Agent={agent} | Mode={'specialized' if specialized else 'general'}

DIRECTIVE: Return ONLY a unified diff + 1-line title. No explanations.

TASK: {prompt}"""
    
    if hunks and len(hunks) > 0:
        directive += f"\n\nFILES CHANGED: {len(hunks)} files"
        file_list = list(hunks.keys())[:5]
        if file_list:
            directive += f"\n- " + "\n- ".join(file_list)
            if len(hunks) > 5:
                directive += f"\n- ... and {len(hunks) - 5} more files"
    else:
        directive += "\n\nFILES CHANGED: No git changes detected"
    
    return directive

if __name__ == "__main__":
    main()