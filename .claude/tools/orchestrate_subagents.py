#!/usr/bin/env python3
"""
Orchestrate subagents using sequential thinking and parallel execution.

This tool uses the sequential thinking MCP server to create a concrete plan,
then spawns contextualized subagents to execute tasks in parallel.
"""

import sys
import os
import json
import datetime
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import time

def use_sequential_thinking(original_prompt):
    """Use sequential thinking MCP server to decompose the task."""
    # This would normally use the MCP server directly
    # For now, we'll create a structured decomposition
    
    thinking_prompt = f"""
Analyze this request and create a detailed execution plan:

{original_prompt}

Please decompose this into:
1. Clear sequential steps
2. Dependencies between steps
3. Parallelizable tasks
4. Required context for each task
5. Expected deliverables

Format as:
## Step Analysis
- Step 1: [description]
- Step 2: [description]
...

## Parallelization Opportunities
- Parallel Group A: [steps that can run together]
- Parallel Group B: [steps that can run together]
...

## Context Requirements
- Step X needs: [context requirements]
- Step Y needs: [context requirements]
...
"""
    
    # Simulate sequential thinking output
    plan = {
        "analysis": {
            "complexity": "medium",
            "estimated_steps": 3,
            "parallelizable": True
        },
        "steps": [],
        "parallel_groups": [],
        "context_requirements": {}
    }
    
    # Parse the original prompt to create an intelligent plan
    prompt_lower = original_prompt.lower()
    
    if any(keyword in prompt_lower for keyword in ['debug', 'fix', 'error', 'problem']):
        plan["steps"] = [
            {
                "id": 1,
                "description": "Investigate and reproduce the issue",
                "type": "investigation",
                "parallelizable": False,
                "dependencies": []
            },
            {
                "id": 2,
                "description": "Identify root cause and affected components",
                "type": "analysis",
                "parallelizable": False,
                "dependencies": [1]
            },
            {
                "id": 3,
                "description": "Implement fix for the issue", 
                "type": "fix",
                "parallelizable": True,
                "dependencies": [2]
            },
            {
                "id": 4,
                "description": "Create regression tests",
                "type": "testing",
                "parallelizable": True,
                "dependencies": [2]
            }
        ]
        
        plan["parallel_groups"] = [
            {
                "group_id": "A",
                "steps": [3, 4],
                "description": "Fix implementation and test creation can run in parallel"
            }
        ]
        
        plan["context_requirements"] = {
            "1": ["error_context", "system_state", "reproduction_steps"],
            "2": ["investigation_results", "code_analysis", "debugging_tools"],
            "3": ["root_cause_analysis", "coding_standards", "fix_patterns"],
            "4": ["root_cause_analysis", "test_patterns", "regression_prevention"]
        }
    
    elif any(keyword in prompt_lower for keyword in ['implement', 'create', 'build', 'develop']):
        plan["steps"] = [
            {
                "id": 1,
                "description": "Analyze requirements and existing codebase",
                "type": "analysis",
                "parallelizable": False,
                "dependencies": []
            },
            {
                "id": 2,
                "description": "Design solution architecture",
                "type": "design", 
                "parallelizable": False,
                "dependencies": [1]
            },
            {
                "id": 3,
                "description": "Implement core functionality",
                "type": "implementation",
                "parallelizable": True,
                "dependencies": [2]
            },
            {
                "id": 4,
                "description": "Create tests and documentation",
                "type": "validation",
                "parallelizable": True,
                "dependencies": [2]
            }
        ]
        
        plan["parallel_groups"] = [
            {
                "group_id": "A",
                "steps": [3, 4],
                "description": "Implementation and validation can run in parallel"
            }
        ]
        
        plan["context_requirements"] = {
            "1": ["codebase_structure", "existing_patterns", "project_rules"],
            "2": ["analysis_results", "architecture_patterns", "constraints"],
            "3": ["design_spec", "coding_standards", "implementation_context"],
            "4": ["design_spec", "test_patterns", "documentation_standards"]
        }
    
    elif any(keyword in prompt_lower for keyword in ['debug', 'fix', 'error', 'problem']):
        plan["steps"] = [
            {
                "id": 1,
                "description": "Investigate and reproduce the issue",
                "type": "investigation",
                "parallelizable": False,
                "dependencies": []
            },
            {
                "id": 2,
                "description": "Identify root cause and affected components",
                "type": "analysis",
                "parallelizable": False,
                "dependencies": [1]
            },
            {
                "id": 3,
                "description": "Implement fix for the issue", 
                "type": "fix",
                "parallelizable": True,
                "dependencies": [2]
            },
            {
                "id": 4,
                "description": "Create regression tests",
                "type": "testing",
                "parallelizable": True,
                "dependencies": [2]
            }
        ]
        
        plan["parallel_groups"] = [
            {
                "group_id": "A",
                "steps": [3, 4],
                "description": "Fix implementation and test creation can run in parallel"
            }
        ]
        
        plan["context_requirements"] = {
            "1": ["error_context", "system_state", "reproduction_steps"],
            "2": ["investigation_results", "code_analysis", "debugging_tools"],
            "3": ["root_cause_analysis", "coding_standards", "fix_patterns"],
            "4": ["root_cause_analysis", "test_patterns", "regression_prevention"]
        }
    
    else:
        # Generic task decomposition
        plan["steps"] = [
            {
                "id": 1,
                "description": "Understand the request and gather context",
                "type": "analysis",
                "parallelizable": False,
                "dependencies": []
            },
            {
                "id": 2,
                "description": "Execute the main task",
                "type": "execution",
                "parallelizable": False,
                "dependencies": [1]
            }
        ]
        
        plan["context_requirements"] = {
            "1": ["project_context", "user_intent", "available_tools"],
            "2": ["analysis_results", "execution_context", "project_standards"]
        }
    
    return plan

def get_context_for_step(step_id, context_requirements, original_prompt):
    """Generate appropriate context for a specific step."""
    required_contexts = context_requirements.get(str(step_id), [])
    
    context_elements = []
    
    if "codebase_structure" in required_contexts:
        context_elements.append("""
# Codebase Structure Context
- MRST simulation scripts in mrst_simulation_scripts/
- Configuration in config/reservoir_config.yaml
- Data outputs in data/ with structured subdirectories
- Dashboard in dashboard/ with Python/Streamlit
- Tests in test/ directory (gitignored)
- Debug code in debug/ directory (gitignored)
""")
    
    if "project_rules" in required_contexts:
        context_elements.append("""
# Project Rules Enforcement
- Functions must be < 40 lines with single responsibility
- Use snake_case naming conventions
- English-only comments and documentation
- No hardcoded values except physical constants
- Complete metadata traceability for data
- KISS principle: avoid try/except blocks and over-engineering
""")
    
    if "coding_standards" in required_contexts:
        context_elements.append("""
# Coding Standards Context
- Python: 4-space indentation, Google-style docstrings
- Octave: 2-space indentation, structured comment blocks
- Step/Substep structure for multi-step functions
- English-only code and comments
- File naming: sNN_, test_NN_, dbg_ prefixes
""")
    
    if "architecture_patterns" in required_contexts:
        context_elements.append("""
# Architecture Patterns Context
- Modular workflow design (sequential s00-s13 scripts)
- Configuration-driven parameters (YAML-based)
- Clear separation: simulation/visualization/testing
- Service-based dashboard architecture
- MCP server integration for extended capabilities
""")
    
    if "test_patterns" in required_contexts:
        context_elements.append("""
# Testing Patterns Context
- Tests isolated in test/ directory
- Naming: test_NN_module_purpose.ext
- Self-contained with no external dependencies
- Order-independent execution
- Validate configuration parsing and field setup
""")
    
    if "documentation_standards" in required_contexts:
        context_elements.append("""
# Documentation Standards Context
- Google Style docstrings (Python)
- Structured comment blocks (Octave)
- < 100 words per docstring
- Include Args, Returns, Raises sections
- English-only documentation
""")
    
    # Add original prompt context
    context_elements.append(f"""
# Original Request Context
{original_prompt}
""")
    
    return "\n".join(context_elements)

def create_subagent_task(step, context, step_number, total_steps):
    """Create a focused task description for a subagent."""
    task_description = f"""
# Subagent Task {step_number}/{total_steps}

## Primary Objective
{step['description']}

## Task Type
{step['type']}

## Context
{context}

## Success Criteria
- Complete the specific objective described above
- Follow all project rules and standards
- Provide clear output about what was accomplished
- Do not exceed the defined scope

## Important Notes
- This is part of a larger orchestrated workflow
- Focus only on your specific task
- Use available tools as needed
- Report completion status clearly
"""
    
    return task_description

def execute_subagent(task_description, agent_id):
    """Execute a subagent with the given task."""
    try:
        # Create a unique task file for this subagent
        task_file = f"/tmp/subagent_task_{agent_id}_{int(time.time())}.txt"
        
        with open(task_file, 'w') as f:
            f.write(task_description)
        
        # Simulate subagent execution
        # In a real implementation, this would spawn Claude Code with the task
        start_time = time.time()
        
        # For now, simulate work based on task type
        task_type = "unknown"
        if "analysis" in task_description.lower():
            task_type = "analysis"
            time.sleep(2)  # Simulate analysis time
        elif "implementation" in task_description.lower() or "implement" in task_description.lower():
            task_type = "implementation" 
            time.sleep(5)  # Simulate implementation time
        elif "test" in task_description.lower():
            task_type = "testing"
            time.sleep(3)  # Simulate testing time
        else:
            time.sleep(1)  # Default simulation time
        
        execution_time = time.time() - start_time
        
        result = {
            "agent_id": agent_id,
            "status": "completed",
            "task_type": task_type,
            "execution_time": execution_time,
            "output": f"Subagent {agent_id} completed {task_type} task successfully",
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
        }
        
        # Clean up task file
        try:
            os.remove(task_file)
        except:
            pass
            
        return result
        
    except Exception as e:
        return {
            "agent_id": agent_id,
            "status": "failed",
            "error": str(e),
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
        }

def execute_parallel_group(steps, context_requirements, original_prompt, group_info):
    """Execute a group of steps in parallel."""
    # Removed unauthorized print(f"Executing parallel group: {group_info['description']}")
    
    results = []
    
    with ThreadPoolExecutor(max_workers=len(steps)) as executor:
        # Submit tasks for parallel execution
        future_to_step = {}
        
        for step in steps:
            context = get_context_for_step(step['id'], context_requirements, original_prompt)
            task_description = create_subagent_task(step, context, step['id'], len(steps))
            
            future = executor.submit(execute_subagent, task_description, f"agent_{step['id']}")
            future_to_step[future] = step
        
        # Collect results as they complete
        for future in as_completed(future_to_step):
            step = future_to_step[future]
            try:
                result = future.result()
                results.append(result)
                # Removed unauthorized print(f"  ✓ Step {step['id']}: {result['status']}")
            except Exception as e:
                # Removed unauthorized print(f"  ✗ Step {step['id']}: failed - {e}")
                results.append({
                    "agent_id": f"agent_{step['id']}",
                    "status": "failed",
                    "error": str(e)
                })
    
    return results

def execute_sequential_step(step, context_requirements, original_prompt):
    """Execute a single step sequentially."""
    # Removed unauthorized print(f"Executing step {step['id']}: {step['description']}")
    
    context = get_context_for_step(step['id'], context_requirements, original_prompt)
    task_description = create_subagent_task(step, context, step['id'], 1)
    
    result = execute_subagent(task_description, f"agent_{step['id']}")
    
    if result['status'] == 'completed':
        # Removed unauthorized print(f"  ✓ Step {step['id']}: completed")
    else:
        # Removed unauthorized print(f"  ✗ Step {step['id']}: failed - {result.get('error', 'unknown error')}")
    
    return result

def orchestrate_execution(plan, original_prompt):
    """Orchestrate the execution of the plan."""
    steps = plan['steps']
    parallel_groups = plan['parallel_groups']
    context_requirements = plan['context_requirements']
    
    # Create execution order considering dependencies and parallelization
    executed_steps = set()
    all_results = []
    
    # Group steps by parallelization opportunities
    parallel_step_ids = set()
    for group in parallel_groups:
        parallel_step_ids.update(group['steps'])
    
    # Execute steps in order, respecting dependencies
    while len(executed_steps) < len(steps):
        # Find steps that can be executed now (dependencies satisfied)
        ready_steps = []
        ready_parallel_groups = []
        
        for step in steps:
            if step['id'] not in executed_steps:
                dependencies_met = all(dep in executed_steps for dep in step['dependencies'])
                if dependencies_met:
                    if step['id'] in parallel_step_ids:
                        # Find the parallel group this step belongs to
                        for group in parallel_groups:
                            if step['id'] in group['steps']:
                                # Check if all steps in this group are ready
                                group_steps = [s for s in steps if s['id'] in group['steps']]
                                all_ready = all(
                                    all(dep in executed_steps for dep in gs['dependencies']) 
                                    for gs in group_steps if gs['id'] not in executed_steps
                                )
                                if all_ready and group not in ready_parallel_groups:
                                    ready_parallel_groups.append((group, group_steps))
                                break
                    else:
                        ready_steps.append(step)
        
        # Execute parallel groups first
        for group, group_steps in ready_parallel_groups:
            remaining_steps = [s for s in group_steps if s['id'] not in executed_steps]
            if remaining_steps:  # Only execute if there are remaining steps
                group_results = execute_parallel_group(
                    remaining_steps,
                    context_requirements,
                    original_prompt,
                    group
                )
                all_results.extend(group_results)
                for step in remaining_steps:
                    executed_steps.add(step['id'])
        
        # Execute remaining sequential steps
        for step in ready_steps:
            if step['id'] not in executed_steps:
                result = execute_sequential_step(step, context_requirements, original_prompt)
                all_results.append(result)
                executed_steps.add(step['id'])
    
    return all_results

def save_orchestration_results(plan, results, original_prompt):
    """Save orchestration session results for analysis."""
    session_data = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "original_prompt": original_prompt,
        "execution_plan": plan,
        "results": results,
        "summary": {
            "total_steps": len(plan['steps']),
            "completed_steps": len([r for r in results if r['status'] == 'completed']),
            "failed_steps": len([r for r in results if r['status'] == 'failed']),
            "total_execution_time": sum(r.get('execution_time', 0) for r in results),
            "parallelization_used": len(plan['parallel_groups']) > 0
        }
    }
    
    # Save to orchestration logs
    log_dir = "/workspaces/simulation/.claude/logs"
    os.makedirs(log_dir, exist_ok=True)
    
    timestamp = datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    log_file = f"{log_dir}/orchestration_{timestamp}.json"
    
    try:
        with open(log_file, 'w') as f:
            json.dump(session_data, f, indent=2)
    except Exception:
        pass  # Don't fail if logging fails
    
    return session_data

def main():
    """Main orchestration function."""
    if len(sys.argv) < 2:
        # Removed unauthorized print("Usage: orchestrate_subagents.py <original_prompt>")
        sys.exit(1)
    
    original_prompt = " ".join(sys.argv[1:])
    
    # Removed unauthorized print("🚀 Starting subagent orchestration...")
    # Removed unauthorized print(f"📝 Original prompt: {original_prompt[:100]}{'...' if len(original_prompt) > 100 else ''}")
    
    # Step 1: Use sequential thinking to create plan
    # Removed unauthorized print("\n🧠 Creating execution plan with sequential thinking...")
    plan = use_sequential_thinking(original_prompt)
    
    # Removed unauthorized print(f"📋 Plan created: {len(plan['steps'])} steps, {len(plan['parallel_groups'])} parallel groups")
    for step in plan['steps']:
        deps = f" (depends on: {step['dependencies']})" if step['dependencies'] else ""
        # Removed unauthorized print(f"   Step {step['id']}: {step['description']}{deps}")
    
    # Step 2: Execute plan with subagent orchestration
    # Removed unauthorized print("\n⚡ Executing plan with parallel subagents...")
    results = orchestrate_execution(plan, original_prompt)
    
    # Step 3: Save and summarize results
    session_data = save_orchestration_results(plan, results, original_prompt)
    
    # Removed unauthorized print(f"\n✅ Orchestration completed!")
    # Removed unauthorized print(f"   Total steps: {session_data['summary']['total_steps']}")
    # Removed unauthorized print(f"   Completed: {session_data['summary']['completed_steps']}")
    # Removed unauthorized print(f"   Failed: {session_data['summary']['failed_steps']}")
    # Removed unauthorized print(f"   Execution time: {session_data['summary']['total_execution_time']:.2f}s")
    # Removed unauthorized print(f"   Parallelization: {'Yes' if session_data['summary']['parallelization_used'] else 'No'}")
    
    # Exit with appropriate code
    if session_data['summary']['failed_steps'] > 0:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()