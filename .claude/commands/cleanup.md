---
allowed-tools: [Read, Edit, Bash]
description: Clean up code before commit
---

# Cleanup Code for Commit

Remove debug prints, fix minor style issues, and prepare code for commit.

Arguments: `$ARGUMENTS`
Expected format: `<file_path>` or `<directory>`
Example: `src/s01_load_data.py` or `src/`

## Instructions:

1. For the specified file(s):
   - Remove print() statements (Python)
   - Remove disp() statements (Octave, except MRST progress)
   - Remove debug logging statements
   - Fix obvious style issues

2. Cleaning tasks:
   - Remove commented-out code blocks
   - Remove TODO comments that are completed
   - Ensure consistent spacing
   - Remove trailing whitespace
   - Ensure files end with newline

3. Do NOT change:
   - Function logic
   - Variable names
   - File structure
   - Docstrings

4. After cleaning:
   - Run validation to ensure compliance
   - Report what was cleaned
   - Show diff of changes

5. Create summary:
   - Files cleaned
   - Print statements removed
   - Other cleanups performed

Remember: This is for final cleanup only, not for refactoring.