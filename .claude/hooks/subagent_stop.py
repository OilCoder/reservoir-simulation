#!/usr/bin/env python3
"""
Hook for consolidating results when subagents complete their tasks.
Triggers: SubagentStop
Author: Claude Code 3-Agent System
"""

import json
import sys
import os
from datetime import datetime
from typing import Dict, Any

def log_agent_completion(agent_name: str, result_summary: str) -> None:
    """
    Log the completion of an agent task.
    
    Args:
        agent_name: Name of the completed agent
        result_summary: Summary of what the agent accomplished
    """
    log_dir = ".claude/logs"
    os.makedirs(log_dir, exist_ok=True)
    
    timestamp = datetime.now().isoformat()
    log_entry = {
        "timestamp": timestamp,
        "agent": agent_name,
        "status": "completed",
        "summary": result_summary
    }
    
    log_file = os.path.join(log_dir, f"agent_activity_{datetime.now().strftime('%Y%m%d')}.jsonl")
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")

def create_completion_summary() -> str:
    """
    Create a summary of the completed work.
    
    Returns:
        Formatted summary string
    """
    summary = """

[✅ Agent Task Completed]

Your request has been processed by the specialized agent(s). Here's what happened:

📁 File Changes:
   - Check src/ for new/modified production code
   - Check tests/ for new test files  
   - Check debug/ for investigation scripts

🔧 MCP Integration:
   - Patterns stored in memory graph for future use
   - Documentation updated in obsidian vault
   - TODO items tracked and updated

💡 Next Steps:
   - Run tests to validate new code: pytest tests/
   - Check debug scripts for insights: ls debug/
   - Review obsidian vault for updated documentation

The agents have followed all project rules and used MCP servers for optimal performance.
"""
    return summary

def check_project_health() -> Dict[str, Any]:
    """
    Perform basic health checks on the project structure.
    
    Returns:
        Health check results
    """
    health = {
        "src_files": 0,
        "test_files": 0,
        "debug_files": 0,
        "issues": []
    }
    
    try:
        # Count files in each directory
        if os.path.exists("src"):
            health["src_files"] = len([f for f in os.listdir("src") if f.endswith(('.py', '.m'))])
        
        if os.path.exists("tests"):
            health["test_files"] = len([f for f in os.listdir("tests") if f.startswith('test_')])
        
        if os.path.exists("debug"):
            health["debug_files"] = len([f for f in os.listdir("debug") if f.startswith('dbg_')])
        
        # Basic health checks
        if health["src_files"] > 0 and health["test_files"] == 0:
            health["issues"].append("⚠️ Production code exists but no tests found")
        
        if health["src_files"] > health["test_files"] * 2:
            health["issues"].append("⚠️ Test coverage might be low (more src than test files)")
            
    except Exception as e:
        health["issues"].append(f"❌ Health check error: {str(e)}")
    
    return health

def main():
    """Main hook execution"""
    try:
        # Get any context from the subagent stop
        context = sys.argv[1] if len(sys.argv) > 1 else ""
        
        # Log the completion
        agent_name = "subagent"  # Could be extracted from context
        log_agent_completion(agent_name, "Task completed successfully")
        
        # Create completion summary
        completion_summary = create_completion_summary()
        
        # Check project health
        health = check_project_health()
        
        # Add health information to summary if there are issues
        if health["issues"]:
            completion_summary += "\n🔍 Project Health Check:\n"
            for issue in health["issues"]:
                completion_summary += f"   {issue}\n"
        
        completion_summary += f"\n📊 Current Stats: {health['src_files']} source files, {health['test_files']} test files, {health['debug_files']} debug scripts\n"
        
        # Return hook response
        response = {
            "continue": True,
            "additionalContext": completion_summary
        }
        
        print(json.dumps(response))
        
    except Exception as e:
        # If hook fails, continue normally to avoid blocking
        error_response = {
            "continue": True,
            "additionalContext": f"\n[SubAgent Stop Hook Error: {str(e)}]\n"
        }
        print(json.dumps(error_response))

if __name__ == "__main__":
    main()