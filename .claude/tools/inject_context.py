#!/usr/bin/env python3
"""
Inject contextual prompts based on user request type.

This tool analyzes the user's prompt and injects relevant MCP prompts to enforce
coding rules and provide context before code generation.
"""

import sys
import re
import os
import json
from pathlib import Path

def analyze_prompt_intent(prompt):
    """Analyze user prompt to determine intent and required context."""
    prompt_lower = prompt.lower()
    
    intents = {
        'coding': 0,
        'testing': 0,
        'debugging': 0,
        'documentation': 0,
        'architecture': 0,
        'data_generation': 0,
        'configuration': 0,
        'refactoring': 0
    }
    
    # Coding patterns
    coding_patterns = [
        r'\b(write|create|implement|code|function|class|method)\b',
        r'\b(add|build|generate|develop)\b.*\b(feature|functionality)\b',
        r'\b(python|octave|matlab|script)\b',
        r'\bdef\s+\w+\b',
        r'\bfunction\s+\w+\b'
    ]
    
    # Testing patterns
    testing_patterns = [
        r'\b(test|testing|unittest|pytest|assert)\b',
        r'\b(validate|verify|check)\b.*\b(function|code|implementation)\b',
        r'\b(test case|test suite|unit test)\b',
        r'\btest_\w+\b'
    ]
    
    # Debugging patterns
    debugging_patterns = [
        r'\b(debug|fix|error|bug|issue|problem)\b',
        r'\b(troubleshoot|diagnose|investigate)\b',
        r'\b(not working|failing|broken)\b',
        r'\b(exception|traceback|stack trace)\b'
    ]
    
    # Documentation patterns
    documentation_patterns = [
        r'\b(document|docstring|comment|explain|describe)\b',
        r'\b(documentation|docs|readme)\b',
        r'\b(how does|what does|explain how)\b'
    ]
    
    # Architecture patterns
    architecture_patterns = [
        r'\b(architecture|design|structure|organize)\b',
        r'\b(refactor|restructure|redesign)\b',
        r'\b(pattern|approach|strategy|plan)\b',
        r'\b(system|framework|infrastructure)\b'
    ]
    
    # Data generation patterns
    data_generation_patterns = [
        r'\b(data|dataset|generate|export|simulate)\b',
        r'\b(reservoir|simulation|mrst)\b',
        r'\b(matlab|octave).*\b(data|export)\b',
        r'\b(metadata|traceability)\b'
    ]
    
    # Configuration patterns
    configuration_patterns = [
        r'\b(config|configuration|settings|parameters)\b',
        r'\b(yaml|json|configure|setup)\b',
        r'\byaml.*\bfile\b',
        r'\bparameter.*\bconfig\b'
    ]
    
    # Refactoring patterns
    refactoring_patterns = [
        r'\b(refactor|improve|optimize|clean up)\b',
        r'\b(simplify|modernize|update)\b',
        r'\b(KISS|simple|complexity)\b'
    ]
    
    # Score each intent
    pattern_groups = {
        'coding': coding_patterns,
        'testing': testing_patterns,
        'debugging': debugging_patterns,
        'documentation': documentation_patterns,
        'architecture': architecture_patterns,
        'data_generation': data_generation_patterns,
        'configuration': configuration_patterns,
        'refactoring': refactoring_patterns
    }
    
    for intent, patterns in pattern_groups.items():
        for pattern in patterns:
            matches = len(re.findall(pattern, prompt_lower))
            intents[intent] += matches
    
    # Determine primary intent
    primary_intent = max(intents, key=intents.get)
    intent_score = intents[primary_intent]
    
    # If no clear intent, default to coding
    if intent_score == 0:
        primary_intent = 'coding'
    
    return primary_intent, intents

def get_relevant_mcp_prompts(intent, intents, original_prompt=""):
    """Get relevant MCP prompts based on intent analysis."""
    prompts = []
    
    # Always include basic style reminder
    prompts.append('style_reminder.mcp')
    
    # Intent-specific prompts
    if intent == 'coding' or intents['coding'] > 0:
        prompts.extend(['simple_code.mcp', 'data_policy.mcp'])
    
    if intent == 'testing' or intents['testing'] > 0:
        prompts.append('test_isolation.mcp')
    
    if intent == 'debugging' or intents['debugging'] > 0:
        prompts.append('debug_isolation.mcp')
    
    if intent == 'documentation' or intents['documentation'] > 0:
        prompts.append('documentation_standards.mcp')
    
    if intent == 'architecture' or intents['architecture'] > 0:
        prompts.append('sequential_thinking.mcp')
    
    if intent == 'data_generation' or intents['data_generation'] > 0:
        prompts.extend(['data_policy.mcp', 'metadata_tracking.mcp'])
    
    if intent == 'configuration' or intents['configuration'] > 0:
        prompts.append('config_discipline.mcp')
    
    if intent == 'refactoring' or intents['refactoring'] > 0:
        prompts.extend(['simple_code.mcp', 'scope_control.mcp'])
    
    # Add MCP server integration prompts based on available servers
    prompt_lower = original_prompt.lower()
    
    if any(keyword in prompt_lower for keyword in ['git', 'commit', 'version', 'repository', 'branch']):
        prompts.append('git_integration.mcp')
    
    if intent == 'documentation' or intents['documentation'] > 0:
        prompts.append('obsidian_integration.mcp')
    
    if any(keyword in prompt_lower for keyword in ['web', 'scrape', 'capture', 'browser', 'screenshot', 'puppeteer']):
        prompts.append('puppeteer_integration.mcp')
    
    return list(set(prompts))  # Remove duplicates

def load_mcp_prompt(prompt_name):
    """Load MCP prompt content from prompts/core/ directory."""
    prompt_path = f"/workspaces/simulation/.claude/prompts/core/{prompt_name}"
    
    if os.path.exists(prompt_path):
        try:
            with open(prompt_path, 'r', encoding='utf-8') as f:
                return f.read().strip()
        except Exception as e:
            return f"# {prompt_name} (loading error: {e})"
    else:
        # Return placeholder if prompt doesn't exist yet
        return get_placeholder_prompt(prompt_name)

def get_placeholder_prompt(prompt_name):
    """Get placeholder content for MCP prompts that don't exist yet."""
    placeholders = {
        'style_reminder.mcp': '''# Code Style Enforcement
ALL code must follow:
- Functions < 40 lines with single responsibility
- snake_case naming (Python/Octave)
- English-only comments and documentation
- Step/Substep visual structure for multi-step functions
- No unauthorized print/log statements''',
        
        'simple_code.mcp': '''# KISS Principle
Keep It Simple, Stupid:
- NO try/except blocks (prohibited)
- NO hardcoded values except physical constants
- Functions should have single responsibility
- Avoid over-engineering and excessive abstraction
- Complexity metrics: cyclomatic complexity < 10''',
        
        'data_policy.mcp': '''# Data Generation Policy
CRITICAL REQUIREMENTS:
- NO hardcoded values except physical constants (pi, g, etc.)
- ALL data must come from simulators with complete metadata
- Every dataset requires traceability information
- Include timestamp, source, version, and origin in metadata''',
        
        'test_isolation.mcp': '''# Test Standards
Tests must be:
- Located in tests/ directory (gitignored)
- Named: test_NN_module_purpose.ext
- Self-contained with no external dependencies
- Order-independent (no global state)
- English-only code and comments''',
        
        'debug_isolation.mcp': '''# Debug Code Isolation
Debug code must be:
- Located in debug/ directory (gitignored)
- Named: dbg_purpose.ext
- Never imported by production code
- Temporary and disposable
- English-only output and comments''',
        
        'documentation_standards.mcp': '''# Documentation Requirements
ALL documentation must be:
- In English only (no Spanish)
- Google Style docstrings (Python)
- Structured comment blocks (Octave)
- < 100 words per docstring
- Include Args, Returns, Raises sections''',
        
        'sequential_thinking.mcp': '''# Sequential Problem Solving
For complex tasks:
- Break down into clear Steps (Step 1, Step 2, etc.)
- Use Substeps for detailed implementation
- Each step should be < 40 lines when implemented
- Document the reasoning for each step''',
        
        'metadata_tracking.mcp': '''# Metadata and Traceability
For data generation:
- Record simulator version and parameters
- Include timestamp and execution environment
- Document data source and processing steps
- Ensure complete reproducibility''',
        
        'config_discipline.mcp': '''# Configuration Management
Configuration changes:
- Modify config/reservoir_config.yaml (not hardcoded values)
- Document parameter purpose and valid ranges
- Use meaningful parameter names
- Include units and default values''',
        
        'scope_control.mcp': '''# Scope Control
Modifications must:
- Stay within requested scope
- Preserve existing functionality
- Not break structural integrity
- Show only modified sections (not entire files)''',
        
        'git_integration.mcp': '''# Git MCP Server Integration
Use @git server for:
- Analyze repository history and patterns
- Check file modifications and status
- Generate conventional commit messages
- Track changes with complete metadata
- Maintain clean git workflow''',
        
        'obsidian_integration.mcp': '''# Obsidian MCP Server Integration
Use @obsidian server for:
- Access knowledge base and documentation
- Create and update structured notes
- Link related concepts and files
- Maintain documentation consistency
- Store project insights and decisions''',
        
        'puppeteer_integration.mcp': '''# Puppeteer MCP Server Integration
Use @puppeteer server for:
- Capture web documentation and examples
- Test web interfaces and interactions
- Generate screenshots for documentation
- Scrape technical references
- Automate browser-based workflows'''
    }
    
    return placeholders.get(prompt_name, f"# {prompt_name}\nPlaceholder prompt content")

def inject_context_prompts(original_prompt, intent, prompts):
    """Inject context prompts into the original prompt."""
    context_header = f"# Context Injection (Intent: {intent})\n"
    
    context_content = []
    for prompt_name in prompts:
        prompt_content = load_mcp_prompt(prompt_name)
        context_content.append(f"## {prompt_name.replace('.mcp', '').replace('_', ' ').title()}")
        context_content.append(prompt_content)
        context_content.append("")  # Empty line separator
    
    # Combine everything
    injected_prompt = context_header + "\n".join(context_content) + "\n---\n\n" + original_prompt
    
    return injected_prompt

def log_context_injection(intent, prompts, original_prompt_length):
    """Log context injection for debugging and monitoring."""
    log_data = {
        "timestamp": "2025-07-23T19:45:00Z",  # Would use actual timestamp
        "intent": intent,
        "prompts_injected": prompts,
        "original_prompt_length": original_prompt_length,
        "context_added": True
    }
    
    # In a real implementation, this might write to a log file or send to monitoring
    # For now, just write to a simple log
    log_path = "/workspaces/simulation/.claude/logs/context_injection.json"
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    
    try:
        with open(log_path, 'a') as f:
            f.write(json.dumps(log_data) + "\n")
    except Exception:
        pass  # Don't fail if logging fails

def main():
    """Main context injection function."""
    if len(sys.argv) < 2:
        # No prompt provided, exit gracefully
        sys.exit(0)
    
    original_prompt = sys.argv[1] if len(sys.argv) > 1 else ""
    
    # Skip injection for empty or very short prompts
    if len(original_prompt.strip()) < 10:
        sys.exit(0)
    
    # Analyze prompt intent
    intent, intents = analyze_prompt_intent(original_prompt)
    
    # Get relevant MCP prompts
    relevant_prompts = get_relevant_mcp_prompts(intent, intents, original_prompt)
    
    # Inject context
    injected_prompt = inject_context_prompts(original_prompt, intent, relevant_prompts)
    
    # Log the injection
    log_context_injection(intent, relevant_prompts, len(original_prompt))
    
    # Output the modified prompt
    print(injected_prompt)
    
    sys.exit(0)

if __name__ == "__main__":
    main()