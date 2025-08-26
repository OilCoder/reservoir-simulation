---
description: Enforce layout, naming, spacing, and step/substep structure in source files
---

All code generated must prioritize clarity, simplicity, and directness. The goal is to produce maintainable and focused code with no unnecessary complexity.

FUNCTION_STRUCTURE:
    - Every function must have a single, well-defined responsibility.
    - Avoid mixing unrelated logic inside the same function.
    - Function bodies should be as short as reasonably possible (ideally under 40 lines).
    - Use helper functions if a task has multiple logical steps.

MINIMALISM:
    - Only generate what is strictly necessary to fulfill the request.
    - Avoid boilerplate, placeholder code, or speculative structures unless explicitly requested.
    - Do not write future-proof abstractions unless the user explicitly asks for scalability.

NAMING:
    - **Python** and **Octave**: Variable and function names must be self-explanatory and follow snake_case.
    - Use short, meaningful names. Avoid generic or placeholder names (e.g., temp, foo, bar, data1, result).

COMMENTS_AND_STYLE:
    - **ALL COMMENTS MUST BE IN ENGLISH** - No Spanish comments allowed in any code files.
    - Use comments only where logic is not self-evident.

    - For functions involving multiple stages, always organize them using the following visual structure:

        **Python** /  **Octave**:
        # ----------------------------------------
        # Step 1 – <High-level action>
        # ----------------------------------------

    - Inside each step, substeps should be marked with a flat header:

        **Python** /  **Octave**:
        # Substep 1.1 – <Specific sub-action> ______________________

    - For additional inline actions or clarifications inside a substep, use emojis or bullet markers:

        **Python**:
        # ✅ Validate inputs
        # 🔄 Loop through each curve
        # 📊 Plot histogram (if enabled)

    - This structure improves readability and helps locate logic blocks during debugging or refactoring.
    - Avoid inline comments for trivial code lines; instead, describe the logic block at a higher level.
    - Do not generate excessive documentation blocks unless explicitly requested.
    - Prioritize structure and clarity over verbosity or repetition.

IMPORTS_AND_DEPENDENCIES:
    - **Python**: Only import what is actually used in the generated code.
    - **Python**: Group imports logically: standard → external → internal.
    - **Octave**: Use addpath() statements at the beginning of scripts if needed.
    - **Octave**: Clearly document any required toolboxes (e.g., % Requires: MRST, Optimization Toolbox).
    - **MRST Integration**: All reservoir simulation code should leverage MRST functions and conventions.
    - Avoid unnecessary third-party dependencies unless they are already used in the project.

OUTPUT_FORMAT:
    - Code must be presented in clean, executable blocks.
    - Do not include explanatory text in code output unless requested.
    - When writing multiple functions, separate them with clear spacing.

SCOPE_DISCIPLINE:
    - Never write more than what the request scope defines.
    - Avoid solving problems that were not asked or predicted unless clarification is provided.

LOGGING_AND_OUTPUT_CONTROL:
    - See logging-policy.mdc for all print/log guidance
