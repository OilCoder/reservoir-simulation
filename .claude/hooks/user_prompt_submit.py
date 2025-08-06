#!/usr/bin/env python3
"""
Hook for analyzing user prompts and distributing tasks to appropriate agents.
Triggers: UserPromptSubmit
Author: Claude Code 3-Agent System
"""

import json
import sys
import re
from typing import Dict, List, Tuple

def analyze_prompt_with_mcp(prompt: str) -> Tuple[Dict, List[str]]:
    """
    Analyze user prompt and determine which agents to activate.
    
    Args:
        prompt: User's input prompt
        
    Returns:
        Tuple of (agent_config, active_agents)
    """
    
    # Agent configuration with MCP server assignments
    agents_config = {
        'coder': {
            'active': False,
            'description': 'Production code writer (src/, mrst_simulation_scripts/)',
            'mcp_servers': ['filesystem', 'memory', 'obsidian', 'sequential-thinking', 'todo'],
            'rules': [0, 1, 2, 5, 6, 8]
        },
        'tester': {
            'active': False,
            'description': 'Test creator (tests/)',
            'mcp_servers': ['filesystem', 'memory', 'ref', 'todo'],
            'rules': [0, 3, 5]
        },
        'debugger': {
            'active': False,
            'description': 'Debug script creator (debug/)',
            'mcp_servers': ['filesystem', 'memory', 'sequential-thinking', 'obsidian'],
            'rules': [0, 4, 5]
        }
    }
    
    prompt_lower = prompt.lower()
    
    # Keywords that trigger specific agents
    coder_keywords = [
        'create', 'implement', 'write', 'edit', 'add', 'build', 'develop',
        'function', 'class', 'module', 'script', 'code', 'algorithm'
    ]
    
    tester_keywords = [
        'test', 'testing', 'pytest', 'unittest', 'validation', 'verify',
        'check', 'assert', 'coverage', 'edge case'
    ]
    
    debugger_keywords = [
        'debug', 'fix', 'error', 'bug', 'issue', 'problem', 'investigate',
        'analyze', 'trace', 'diagnose', 'troubleshoot', 'broken'
    ]
    
    # Check for explicit agent requests
    if re.search(r'\b(only|just)\s+(test|testing)\b', prompt_lower):
        agents_config['tester']['active'] = True
    elif re.search(r'\b(only|just)\s+(debug|debugging)\b', prompt_lower):
        agents_config['debugger']['active'] = True
    elif re.search(r'\b(only|just)\s+(code|coding)\b', prompt_lower):
        agents_config['coder']['active'] = True
    else:
        # Automatic detection based on keywords
        if any(keyword in prompt_lower for keyword in coder_keywords):
            agents_config['coder']['active'] = True
            # Auto-activate tester when creating new code
            if any(word in prompt_lower for word in ['create', 'implement', 'new', 'add']):
                agents_config['tester']['active'] = True
        
        if any(keyword in prompt_lower for keyword in tester_keywords):
            agents_config['tester']['active'] = True
        
        if any(keyword in prompt_lower for keyword in debugger_keywords):
            agents_config['debugger']['active'] = True
            # Auto-activate coder for fixing issues
            if any(word in prompt_lower for word in ['fix', 'repair', 'solve']):
                agents_config['coder']['active'] = True
    
    # Default: activate coder + tester for general requests
    active_agents = [k for k, v in agents_config.items() if v['active']]
    if not active_agents:
        agents_config['coder']['active'] = True
        agents_config['tester']['active'] = True
        active_agents = ['coder', 'tester']
    
    return agents_config, active_agents

def create_agent_context(config: Dict, active_agents: List[str], prompt: str) -> str:
    """
    Create context information for the agents.
    
    Args:
        config: Agent configuration
        active_agents: List of active agent names
        prompt: Original user prompt
        
    Returns:
        Formatted context string
    """
    context = f"""
[🚀 3-Agent System Activated]
Original prompt: "{prompt}"

Active Agents: {', '.join(active_agents)}

Agent Assignments:
"""
    
    for agent in active_agents:
        agent_info = config[agent]
        context += f"""
🤖 {agent.upper()} Agent:
   - Responsibility: {agent_info['description']}
   - MCP Servers: {', '.join(agent_info['mcp_servers'])}
   - Rules: {agent_info['rules']}
"""
    
    context += f"""
System Instructions:
- Each agent will work in parallel using the Task tool
- Agents have access to their assigned MCP servers
- Follow your specific rules and stay in your designated folders
- Use MCP tools for better performance (mcp__filesystem__ instead of native tools)
- CODER: No print() in final code, use MCP memory for patterns
- TESTER: One test file per module, comprehensive coverage
- DEBUGGER: Liberal print() allowed, document findings

Parallel Execution Strategy:
"""
    
    if len(active_agents) == 1:
        context += f"- Single agent execution: {active_agents[0]} will handle this task\n"
    elif len(active_agents) == 2:
        context += f"- Dual agent execution: {' and '.join(active_agents)} will work in parallel\n"
    else:
        context += f"- Triple agent execution: All agents will collaborate in parallel\n"
    
    return context

def main():
    """Main hook execution"""
    try:
        # Get the prompt from command line arguments
        prompt = sys.argv[1] if len(sys.argv) > 1 else ""
        
        if not prompt.strip():
            # No prompt provided, continue normally
            print(json.dumps({"continue": True}))
            return
        
        # Analyze the prompt
        config, active_agents = analyze_prompt_with_mcp(prompt)
        
        # Create context for agents
        agent_context = create_agent_context(config, active_agents, prompt)
        
        # Return hook response
        response = {
            "continue": True,
            "additionalContext": agent_context
        }
        
        print(json.dumps(response))
        
    except Exception as e:
        # If hook fails, continue normally to avoid blocking
        error_response = {
            "continue": True,
            "additionalContext": f"\n[Hook Error: {str(e)}]\n"
        }
        print(json.dumps(error_response))

if __name__ == "__main__":
    main()