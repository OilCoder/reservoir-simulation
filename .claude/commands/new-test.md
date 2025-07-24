---
allowed-tools: [Write, Read]
description: Create a new test file for a module
---

# Create New Test File

Generate a new test file following the test naming convention.

Arguments: `$ARGUMENTS`
Expected format: `<module_path> [test_name]`
Example: `src/s01_load_data.py` or `mrst_simulation_scripts/s02_setup_field.m edge_cases`

## Instructions:

1. Parse the module path to extract:
   - Source folder (src, mrst_simulation_scripts)
   - Module name (without extension)
   - Language (from extension)

2. Determine test number (next available NN)

3. Create filename: `test_NN_<folder>_<module>[_<purpose>].<ext>`

4. Use the appropriate template:
   - Python: Use `.claude/templates/python_test.py`
   - Octave: Use `.claude/templates/octave_test.m`

5. Place in `/workspace/tests/` directory

6. Customize the template:
   - Import the target module
   - Create relevant test cases
   - Add appropriate fixtures
   - Include edge cases

Remember:
- Tests directory is gitignored
- Each test must be independent
- Include both normal and edge cases
- Use descriptive test names
- English-only comments