#!/usr/bin/env python3
# Task delegation to debugger agent
task_data = {
    "agent": "debugger",
    "task": "investigate_script_sequence", 
    "description": "\nTASK: Investigate script execution sequence failure (s04-s10 failing due to missing grid.mat)\n\nPROBLEM CONTEXT:\n- Scripts s04-s10 are failing because /workspace/data/mrst/grid.mat doesn't exist\n- After implementing canonical structure, need to execute s03→s04→s05 sequence to generate files\n- Expected sequence: s03 (create PEBI grid) → s04 (structural framework) → s05 (add faults)\n- Files should be generated in /workspace/data/mrst/ (canonical location)\n\nPOLICY CONTEXT:\n- Validation mode: warn (development)  \n- Canon-First Policy: Scripts must follow documented data flow\n- Data Authority Policy: All data from authoritative YAML configs, no hardcoding\n- Fail Fast Policy: Scripts should fail immediately on missing prerequisites\n\nINVESTIGATION REQUEST:\n1. Check if s03_create_pebi_grid.m is correctly configured to save grid.mat in canonical location\n2. Execute s03 and verify grid.mat generation\n3. Test s04 loading of grid.mat and proper updates\n4. Identify root cause if execution chain fails\n5. Create debug script with findings and recommendations\n\nDELIVERABLE: Debug script dbg_grid_sequence.m with step-by-step analysis and policy-compliant recommendations\n",
    "context": "Grid generation sequence failure investigation",
    "priority": "high",
    "policies": ["canon-first", "data-authority", "fail-fast"]
}

print(f"DELEGATING TO DEBUGGER AGENT: {task_data['description'][:100]}...")
print("Task details prepared for agent execution.")
