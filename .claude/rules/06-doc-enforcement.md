---
description: Enforce standardized documentation using Google Style docstrings and Octave comments.
---

DOCSTRING_REQUIRED:
  - **Python**: All public functions, methods, and classes must include a Google Style docstring.
  - **Python**: Private functions (starting with '_') require a docstring if they contain nontrivial logic.
  - **Octave**: All public functions must include a structured comment block with purpose, inputs, outputs, and usage examples.
  - **Octave**: Use the standard Octave help format with % comments immediately following the function declaration.
  - **ALL DOCUMENTATION MUST BE IN ENGLISH** - No Spanish documentation or comments allowed.
  - Keep it under 100 words. Avoid excessive detail or inline implementation logic.

MODULE HEADER DOCSTRING
  - **Python**: Every new Python file under src/ must begin with a top-level docstring.
  - **Octave**: Every new .m file under mrst_simulation_scripts/ or src/ must begin with a structured comment block.
  - This docstring/comment must serve as a concise summary of the module's purpose.
  - It may contain:
      • A short description of the file's overall goal (1–3 lines)
      • An optional bullet list of major functions, classes, or features
      • Optional usage context or file dependencies (if relevant)
      • **Octave**: Required toolboxes or dependencies (e.g., % Requires: MRST)

DOCSTRING_STRUCTURE:
  - Must include (if applicable):
    • One-line summary describing behavior.
    • "Args:" section with parameter names, types, and descriptions.
    • "Returns:" section with return type and explanation.
    • "Raises:" section for explicitly raised exceptions.

STYLE_RULES:
  - Must match Google Style formatting (headers, indentation, alignment).
  - Do not mix with NumPy or reStructuredText formats.
  - Avoid vague terms like "does something" or "helper function".
  - If a function has no parameters or return value, still explain what it does.

CONSISTENCY_RULES:
  - Docstring must reflect actual behavior, not intentions or placeholders.
  - Do not duplicate content across sections.
  - Keep docstrings concise, specific, and informative.

ENFORCEMENT_SCOPE:
  - Functions without docstrings may be excluded from generated documentation.
  - project_map.md relies on these docstrings to infer module functionality.
