---
description: Enforce strict editing boundaries for modifying existing code.
---

EDIT_SCOPE:
  - When the user pinpoints the target: modify only the specified function, class, or block.
  - When the user does not pinpoint the target:
    - Inspect the code to locate the smallest block required to fix the issue (e.g., a single function or a specific configuration section).
    - Apply changes only within that minimal block.
    - Do not create new utilities, abstractions, or extra logic unless explicitly requested.

  - Do not add code outside the defined scope (logging, debug helpers, etc.).

STRUCTURAL_INTEGRITY:
  - Preserve the existing order of imports and function declarations unless the user requests reordering.
  - Maintain original indentation, formatting, and comments unless they are directly related to the edit.

MULTI_FILE_CHANGES:
  - Allowed only when the task clearly involves cross-file coordination, such as:
    • Web tasks requiring updates to HTML, CSS, and JS.
    • Pipeline/workflow updates across orchestration and task modules.
    • Component creation requiring registration/import elsewhere.
  - Constraints:
    • Edit only files directly related to the request.
    • Each change must have a clear reason and impact aligned with the goal.
    • Avoid broad refactors or speculative edits unless explicitly requested.
    • Do not infer relationships between files unless user confirms or implies them.
  - Organize outputs with clear file labels or headers.
  - Show only modified sections; never full files unless requested.

DEBUG_AND_TEST_CODE:
  - Read 03-test-script.md and 04-debug-script.md for detailed testing and debugging rules.
  - Do not insert print(), logging, assertions, or test/debug logic in core code.
  - Always create test/debug scripts and place test/debug logic in test/debug folder following 03-test-script.md, 04-debug-script.md and 05-file-naming.md rules.

COMMENTS:
  - Only modify or add comments tied to the changed logic.
  - Do not rephrase unrelated documentation or annotations.

OUTPUT_FORMAT:
  - Return only modified function/class.
  - Do not show or regenerate unchanged code.
  - Show full file only if explicitly asked by the user.

