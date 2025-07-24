---
description: Define the role and scope of each rule in the codebase
---

RULE_INDEX:
  0. 00-project-guidelines.md – Defines the role and scope of each rule in the codebase.
  1. 01-code-style.md – Enforces layout, naming, spacing, and step/substep structure in source files.
  2. 02-code-change.md – Limits edits to the exact requested scope; allows multi-file changes only when explicitly requested.
  3. 03-test-script.md – Defines naming conventions, isolation standards, and structure for Pytest-based tests.
  4. 04-debug-script.md – Isolates debug logic in debug/ folder, enforces cleanup and naming standards.
  5. 05-file-naming.md – Standardizes naming for all files: source, test, debug, docs, notebooks, simulation outputs.
  6. doc-enforcement.md – Requires Google Style docstrings for all public and non-trivial private functions/classes.
  7. docs-style.md – Defines required format and structure for Markdown documentation.
  8. logging-policy.md – Allows temporary print/logging but enforces cleanup before commit.

ENFORCEMENT_STRATEGY:
  - All source changes must comply with style (1) and scope (2) rules.
  - All committed code must use valid naming (5).
  - Code must comply with doc_enforcement (6) and logging_policy (8).
  - Debugging code (4) and testing code (5) must be isolated in folders that correspond debug/ test/ or removed before delivery.

PROJECT_MAP_REFERENCE:
  - Canonical project structure is defined in: docs/project_map.mdc
  - Includes folder tree, file purposes, and role classifications (core, utility, test, debug, doc).
  - project_map.md is auto-generated and must not be edited manually.

SIMPLE CODE POLICY (“Keep It Simple, Stupid”)
  ### KISS Core
  - Write the most direct, readable solution that fulfils the requirement—no speculative abstractions.
  - Break problems into small, single-purpose functions (see Rule 1 *FUNCTION_STRUCTURE*).

  ### try/except Restrictions
  1. **Allowed only for true I/O boundaries**  
    File access, network calls, external APIs.  
  2. **Never silence errors**  
    Re-raise or log with context; do not pass/return default values.  
  3. **Validate first, don’t patch later**  
    Use explicit `if` checks or assertions instead of catching predictable errors.

  ### Enforcement
  - Pre-hook linter flags any new `try:` block.  
    - **Warning** if the block handles I/O (allowed).  
    - **Error (blocks commit)** if the `except` is broad or re-raises nothing.  
  - Repeated violations trigger a mandatory code review.

DATA_GENERATION_POLICY
  - **Prohibition of Hard‑Coding**
    - Do not embed fixed numeric answers, lookup tables, or formula constants directly in source files unless the value is a true physical constant (e.g., π, gravity).
    - Expected outputs for tests must be computed at runtime via simulator calls or helper utilities, never pasted literals.

  - **Simulator Authority**
    - Reservoir properties, stress calculations, synthetic logs, and any other domain‑specific values must originate from MRST, Octave scripts, or the designated ML pipelines.
    - If a new tool is introduced, its adoption must be documented in docs/ADR and reflected in project_map.mdc.

  - **Traceability Requirements**
    -Each dataset or artefact must include provenance metadata (timestamp, script name, parameters) either in filename or an accompanying .meta.json file.
    - Formulas or numerical methods belong in simulator scripts, not scattered across utilities.