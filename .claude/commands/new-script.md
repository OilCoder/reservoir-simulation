---
allowed-tools: [Write, Read]
description: Create a new workflow script following naming conventions
---

# Create New Workflow Script

Generate a new workflow script with the correct naming pattern and structure.

Arguments: `$ARGUMENTS`
Expected format: `<step_number> <verb> <noun> [python|octave]`
Example: `01 load data python` or `02a setup field octave`

## Instructions:

1. Parse the arguments to extract:
   - Step number (with optional letter)
   - Verb (action word)
   - Noun (target/object)
   - Language (default: python)

2. Create filename following pattern: `sNN[x]_<verb>_<noun>.<ext>`

3. Use the appropriate template:
   - Python: Use `.claude/templates/python_module.py`
   - Octave: Use `.claude/templates/octave_script.m`

4. Place in correct directory:
   - Python: `/workspace/src/`
   - Octave: `/workspace/mrst_simulation_scripts/`

5. Customize the template with:
   - Appropriate module/script purpose
   - Relevant imports
   - Function names matching the verb_noun pattern

Remember to follow all project rules:
- KISS principle (keep it simple)
- English-only comments
- Proper step/substep structure
- Google Style docstrings (Python)
- MRST requirements (Octave)