---
allowed-tools: [Read, Bash]
description: Validate files against project rules
---

# Validate Code Compliance

Check files for compliance with all project rules.

Arguments: `$ARGUMENTS`
Expected format: `<file_path>` or `all`
Example: `src/s01_load_data.py` or `all`

## Instructions:

1. If argument is a specific file:
   - Run all validation hooks on that file
   - Report any violations

2. If argument is "all":
   - Find all Python and Octave files in src/ and mrst_simulation_scripts/
   - Run validation on each file
   - Provide summary report

3. Validation checks to run:
   - File naming convention
   - Code style (KISS, function length, comments)
   - Docstring compliance
   - Try/except usage
   - Print statement warnings

4. For each violation found:
   - Show the specific rule violated
   - Provide the exact location (file:line if possible)
   - Suggest how to fix it

5. Generate summary:
   - Total files checked
   - Files with errors
   - Files with warnings
   - Overall compliance percentage

Use the validation hooks in `.claude/hooks/` directory.