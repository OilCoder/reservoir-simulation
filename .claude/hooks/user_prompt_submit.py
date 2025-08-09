#!/usr/bin/env python3
"""
Optimized Router Hook for Maximum Prompt Efficiency
- Single agent selection by regex classification (no LLM reasoning)
- Minimal context injection (git diff hunks only)  
- Budget-aware agent selection
- Forces compact output format
"""

import json
import sys
import re
import os
import subprocess
from typing import Dict, List, Optional

def route_prompt(prompt: str, budget_remaining: int = 999) -> Dict:
    """
    Fast regex-based routing to single agent.
    
    Args:
        prompt: User input
        budget_remaining: Estimated prompts left in session
        
    Returns:
        Agent selection and configuration
    """
    prompt_lower = prompt.lower().strip()
    
    # Conservative mode: only coder when budget is low
    if budget_remaining < 25:
        return {
            "agent": "coder",
            "reason": "budget_conservation",
            "specialized": False
        }
    
    # Explicit agent requests (highest priority)
    if re.search(r'\b(only|just)\s+(test|testing)\b', prompt_lower):
        return {"agent": "tester", "reason": "explicit_test", "specialized": True}
    
    if re.search(r'\b(only|just)\s+(debug|debugging)\b', prompt_lower):
        return {"agent": "debugger", "reason": "explicit_debug", "specialized": True}
    
    # Specialized task detection
    if re.search(r'\b(test|pytest|unittest|coverage|assert)\b', prompt_lower):
        return {"agent": "tester", "reason": "test_keywords", "specialized": True}
    
    if re.search(r'\b(debug|trace|investigate|diagnose|broken|fix.*bug)\b', prompt_lower):
        return {"agent": "debugger", "reason": "debug_keywords", "specialized": True}
    
    # Default: coder handles everything else
    return {"agent": "coder", "reason": "default", "specialized": False}

def collect_diff_hunks(max_chars: int = 20000, context_lines: int = 30) -> Dict[str, str]:
    """
    Collect git diff hunks for modified files.
    
    Args:
        max_chars: Maximum total characters to include
        context_lines: Lines of context around changes
        
    Returns:
        Dictionary mapping file paths to diff hunks
    """
    hunks = {}
    total_chars = 0
    
    try:
        # Get list of modified files
        result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            return {"git_status": "No git repository or no changes"}
        
        modified_files = [f.strip() for f in result.stdout.split('\n') if f.strip()]
        
        # Collect hunks for each file
        for file_path in modified_files:
            if total_chars >= max_chars:
                break
                
            if not os.path.exists(file_path):
                continue
                
            # Get diff with context
            diff_result = subprocess.run(
                ["git", "diff", f"-U{context_lines}", "HEAD", "--", file_path],
                capture_output=True, text=True
            )
            
            if diff_result.returncode == 0 and diff_result.stdout:
                remaining_chars = max_chars - total_chars
                hunk = diff_result.stdout[:remaining_chars]
                hunks[file_path] = hunk
                total_chars += len(hunk)
                
    except Exception as e:
        hunks["error"] = f"Failed to collect diffs: {str(e)}"
    
    return hunks

def get_budget_estimate() -> int:
    """
    Estimate remaining prompts in session.
    Simple heuristic based on environment or defaults to conservative.
    """
    # Check if budget tracking is available
    budget = os.environ.get("CLAUDE_REMAINING_PROMPTS")
    if budget and budget.isdigit():
        return int(budget)
    
    # Default conservative estimate
    return 100

def create_compact_context(route: Dict, prompt: str, hunks: Dict[str, str]) -> str:
    """
    Create minimal context for selected agent.
    
    Args:
        route: Agent routing decision
        prompt: Original user prompt  
        hunks: Git diff hunks
        
    Returns:
        Compact context string
    """
    agent = route["agent"]
    specialized = route.get("specialized", False)
    
    # Core directive (CRITICAL for token efficiency)
    directive = f"""[ROUTER] Agent={agent} | Mode={'specialized' if specialized else 'general'}

DIRECTIVE: Return ONLY a unified diff + 1-line title. No explanations, no reasoning, no summaries.

TASK: {prompt}"""
    
    # Add relevant context
    if hunks and len(hunks) > 0:
        directive += f"\n\nFILES CHANGED: {len(hunks)} files"
        
        # Show first few file names (not full content to save tokens)
        file_list = list(hunks.keys())[:5]
        if file_list:
            directive += f"\n- " + "\n- ".join(file_list)
            if len(hunks) > 5:
                directive += f"\n- ... and {len(hunks) - 5} more files"
    else:
        directive += "\n\nFILES CHANGED: No git changes detected"
    
    return directive

def main():
    """Main router execution"""
    try:
        # Get prompt from stdin (Claude Code standard) or command line
        prompt = ""
        if not sys.stdin.isatty():
            try:
                data = json.load(sys.stdin)
                prompt = data.get("prompt", "")
            except json.JSONDecodeError:
                pass
        
        # Fall back to command line argument
        if not prompt and len(sys.argv) > 1:
            prompt = sys.argv[1]
        
        if not prompt.strip():
            # No routing needed
            print(json.dumps({"continue": True}))
            return
        
        # Route prompt to single agent
        budget = get_budget_estimate()
        route = route_prompt(prompt, budget)
        
        # Collect minimal context
        hunks = collect_diff_hunks(max_chars=20000, context_lines=30)
        context = create_compact_context(route, prompt, hunks)
        
        # Return optimized response
        response = {
            "continue": True,
            "agent": route["agent"],
            "additionalContext": context,
            "routingReason": route["reason"],
            "budgetRemaining": budget
        }
        
        print(json.dumps(response))
        
    except Exception as e:
        # Fail gracefully - continue with default behavior
        error_response = {
            "continue": True,
            "additionalContext": f"[ROUTER ERROR: {str(e)}]"
        }
        print(json.dumps(error_response))

if __name__ == "__main__":
    main()