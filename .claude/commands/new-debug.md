---
allowed-tools: [Write, Read]
description: Create a debug script for investigating issues
---

# Create Debug Script

Generate a new debug script for investigating a specific issue.

Arguments: `$ARGUMENTS`
Expected format: `<target_module> <issue_description>`
Example: `src/s01_load_data.py memory_leak` or `mrst_simulation_scripts/s02_setup_field.m convergence_issue`

## Instructions:

1. Parse arguments to extract:
   - Target module path
   - Issue slug (short description)
   - Language (from module extension)

2. Create filename: `dbg_<issue_slug>.<ext>`

3. Use the appropriate template:
   - Python: Use `.claude/templates/debug_script.py`
   - Octave: Use `.claude/templates/debug_script.m`

4. Place in `/workspace/debug/` directory

5. Customize the template:
   - Set target module information
   - Update issue description
   - Add relevant imports
   - Include specific debug checks

Remember:
- Debug directory is gitignored
- Liberal use of print/log allowed
- Document findings clearly
- Save outputs for analysis
- English-only output