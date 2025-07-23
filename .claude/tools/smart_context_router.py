#!/usr/bin/env python3
"""
Smart context router for subagent orchestration.

This tool intelligently determines when to use orchestration vs direct execution
and prepares appropriate context for subagents.
"""

import sys
import os
import re
import json
import subprocess
from pathlib import Path

def analyze_complexity(prompt):
    """Analyze prompt complexity to determine if orchestration is needed."""
    complexity_indicators = {
        'high': [
            r'\b(implement|create|build|develop)\b.*\b(system|feature|application|framework)\b',
            r'\b(multiple|several|various)\b.*\b(components|parts|modules|files)\b',
            r'\b(architecture|design|structure)\b.*\b(from scratch|new)\b',
            r'\b(integrate|combine|coordinate)\b.*\b(different|multiple)\b',
            r'\b(workflow|pipeline|process)\b.*\b(complete|end-to-end)\b',
            r'\b(dashboard|interface|system)\b.*\b(with|including)\b.*\b(features|functionality)\b'
        ],
        'medium': [
            r'\b(add|implement|create)\b.*\b(feature|functionality|component)\b',
            r'\b(refactor|improve|optimize)\b.*\b(code|system|implementation)\b',
            r'\b(fix|debug|resolve)\b.*\b(multiple|several)\b.*\b(issues|problems|bugs)\b',
            r'\b(test|validate|verify)\b.*\b(comprehensive|complete|thorough)\b',
            r'\b(documentation|docs)\b.*\b(complete|comprehensive|update)\b'
        ],
        'low': [
            r'\b(explain|describe|show|tell)\b',
            r'\b(what is|how does|where is)\b',
            r'\b(read|view|display|list)\b',
            r'\b(simple|quick|small)\b.*\b(change|fix|update)\b',
            r'\brun\b.*\b(command|test|script)\b'
        ]
    }
    
    prompt_lower = prompt.lower()
    scores = {'high': 0, 'medium': 0, 'low': 0}
    
    for level, patterns in complexity_indicators.items():
        for pattern in patterns:
            matches = len(re.findall(pattern, prompt_lower))
            scores[level] += matches
    
    # Determine complexity level
    if scores['high'] > 0 or (scores['medium'] > 2):
        return 'high'
    elif scores['medium'] > 0 or (scores['low'] > 0 and len(prompt.split()) > 20):
        return 'medium' 
    else:
        return 'low'

def should_use_orchestration(prompt, complexity):
    """Determine if orchestration should be used."""
    if complexity == 'high':
        return True
    
    if complexity == 'medium':
        # Check for specific indicators that suggest orchestration would help
        orchestration_indicators = [
            r'\b(step by step|stages|phases|sequential)\b',
            r'\b(first.*then|start.*then|begin.*after)\b',
            r'\b(multiple.*files|different.*components|various.*parts)\b',
            r'\b(implement.*test|create.*document|build.*validate)\b'
        ]
        
        prompt_lower = prompt.lower()
        for indicator in orchestration_indicators:
            if re.search(indicator, prompt_lower):
                return True
    
    return False

def detect_subagent_requirements(prompt):
    """Detect what types of subagents and context will be needed."""
    requirements = {
        'analysis_agent': False,
        'implementation_agent': False,
        'testing_agent': False,
        'documentation_agent': False,
        'context_types': []
    }
    
    prompt_lower = prompt.lower()
    
    # Agent type detection
    if any(pattern in prompt_lower for pattern in ['analyze', 'understand', 'investigate', 'examine', 'research']):
        requirements['analysis_agent'] = True
        requirements['context_types'].extend(['codebase_structure', 'project_rules'])
    
    if any(pattern in prompt_lower for pattern in ['implement', 'create', 'build', 'develop', 'code', 'write']):
        requirements['implementation_agent'] = True
        requirements['context_types'].extend(['coding_standards', 'architecture_patterns'])
    
    if any(pattern in prompt_lower for pattern in ['test', 'validate', 'verify', 'check', 'ensure']):
        requirements['testing_agent'] = True
        requirements['context_types'].extend(['test_patterns', 'validation_context'])
    
    if any(pattern in prompt_lower for pattern in ['document', 'explain', 'describe', 'comment', 'docstring']):
        requirements['documentation_agent'] = True
        requirements['context_types'].extend(['documentation_standards'])
    
    # Remove duplicates
    requirements['context_types'] = list(set(requirements['context_types']))
    
    return requirements

def get_orchestration_context(prompt, requirements):
    """Generate context specifically for orchestration."""
    context_parts = []
    
    # Add orchestration-specific instructions
    context_parts.append("""
# Orchestration Context

You are being executed as part of a coordinated subagent system. This task is part of a larger workflow that has been intelligently decomposed.

## Orchestration Guidelines
- Focus on your specific assigned task only
- Use available context to understand the broader project
- Report completion status clearly
- Follow all project rules and standards
- Coordinate with other subagents through shared context
""")
    
    # Add specific context based on requirements
    if 'codebase_structure' in requirements['context_types']:
        context_parts.append("""
## Codebase Structure Context
- Core MRST simulation workflow in mrst_simulation_scripts/ (s00-s13)
- Configuration management in config/reservoir_config.yaml
- Structured data outputs in data/ subdirectories
- Python dashboard in dashboard/ with Streamlit interface
- Testing isolation in test/ directory
- Debug code isolation in debug/ directory
""")
    
    if 'project_rules' in requirements['context_types']:
        context_parts.append("""
## Project Rules Context
- Functions must be < 40 lines with single responsibility
- Use snake_case naming for Python/Octave
- English-only comments and documentation
- No hardcoded values except physical constants
- Complete metadata traceability for all data
- KISS principle: avoid try/catch and over-engineering
""")
    
    if 'coding_standards' in requirements['context_types']:
        context_parts.append("""
## Coding Standards Context
- Python: 4-space indentation, Google-style docstrings
- Octave: 2-space indentation, structured comment blocks
- Step/Substep visual structure for multi-step functions
- File naming conventions: sNN_, test_NN_, dbg_ prefixes
- English-only code and error messages
""")
    
    if 'architecture_patterns' in requirements['context_types']:
        context_parts.append("""
## Architecture Patterns Context
- Sequential modular workflow design
- Configuration-driven parameters (no hardcoded values)
- Clear separation: simulation/visualization/testing
- Service-based dashboard architecture
- MCP server integration for extended capabilities
""")
    
    if 'test_patterns' in requirements['context_types']:
        context_parts.append("""
## Testing Patterns Context
- All tests isolated in test/ directory (gitignored)
- Naming convention: test_NN_module_purpose.ext
- Self-contained tests with no external dependencies
- Order-independent execution capability
- Focus on configuration parsing and field setup validation
""")
    
    if 'documentation_standards' in requirements['context_types']:
        context_parts.append("""
## Documentation Standards Context
- Google Style docstrings for Python functions
- Structured comment blocks for Octave functions
- Maximum 100 words per docstring
- Include Args, Returns, Raises sections
- English-only documentation throughout
""")
    
    # Add original prompt context
    context_parts.append(f"""
## Original Request
{prompt}
""")
    
    return "\n".join(context_parts)

def prepare_orchestration_command(prompt):
    """Prepare the orchestration command with proper context."""
    # Create a temporary file with the enhanced prompt
    enhanced_prompt_file = f"/tmp/orchestration_prompt_{os.getpid()}.txt"
    
    complexity = analyze_complexity(prompt)
    requirements = detect_subagent_requirements(prompt)
    orchestration_context = get_orchestration_context(prompt, requirements)
    
    enhanced_prompt = f"{orchestration_context}\n\n---\n\n{prompt}"
    
    try:
        with open(enhanced_prompt_file, 'w') as f:
            f.write(enhanced_prompt)
        
        # Return the command to execute orchestration
        return f"python /workspaces/simulation/.claude/tools/orchestrate_subagents.py \"$(cat {enhanced_prompt_file})\""
    
    except Exception:
        # Fallback to direct prompt
        return f"python /workspaces/simulation/.claude/tools/orchestrate_subagents.py \"{prompt}\""

def log_routing_decision(prompt, use_orchestration, complexity, requirements):
    """Log the routing decision for analysis."""
    log_data = {
        "timestamp": "2025-07-23T20:00:00Z",  # Would use actual timestamp
        "prompt_length": len(prompt),
        "complexity": complexity,
        "use_orchestration": use_orchestration,
        "requirements": requirements,
        "routing_decision": "orchestration" if use_orchestration else "direct"
    }
    
    log_path = "/workspaces/simulation/.claude/logs/routing_decisions.jsonl"
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    
    try:
        with open(log_path, 'a') as f:
            f.write(json.dumps(log_data) + "\n")
    except Exception:
        pass  # Don't fail if logging fails

def main():
    """Main context routing function."""
    if len(sys.argv) < 2:
        sys.exit(0)
    
    original_prompt = " ".join(sys.argv[1:])
    
    # Skip routing for very short prompts
    if len(original_prompt.strip()) < 15:
        sys.exit(0)
    
    # Analyze prompt to determine routing
    complexity = analyze_complexity(original_prompt)
    requirements = detect_subagent_requirements(original_prompt)
    use_orchestration = should_use_orchestration(original_prompt, complexity)
    
    # Log the routing decision
    log_routing_decision(original_prompt, use_orchestration, complexity, requirements)
    
    if use_orchestration:
        # Prepare and execute orchestration
        orchestration_command = prepare_orchestration_command(original_prompt)
        
        print(f"🎯 Detected complex task ({complexity} complexity)")
        print(f"🚀 Routing to subagent orchestration...")
        print(f"📋 Required agents: {', '.join([k.replace('_agent', '') for k, v in requirements.items() if v and k.endswith('_agent')])}")
        
        # Execute orchestration (in a real system)
        # For now, just show the command that would be executed
        print(f"Command: {orchestration_command}")
    else:
        print(f"📝 Simple task ({complexity} complexity) - using direct execution")
    
    sys.exit(0)

if __name__ == "__main__":
    main()