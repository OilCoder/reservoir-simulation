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
  6. 06-doc-enforcement.md – Requires Google Style docstrings for all public and non-trivial private functions/classes.
  7. 07-docs-style.md – Defines required format and structure for Markdown documentation.
  8. 08-logging-policy.md – Allows temporary print/logging but enforces cleanup before commit.
  9. 09-canon-first-philosophy.md – Enforces documentation-as-specification approach with zero defensive programming.

ENFORCEMENT_STRATEGY:
  - All source changes must comply with style (1) and scope (2) rules.
  - All committed code must use valid naming (5).
  - Code must comply with doc_enforcement (6) and logging_policy (8).
  - All code must follow Canon-First Philosophy (9) - documentation-as-specification with zero defensive programming.
  - All error handling must follow Exception Handling Policy and FAIL_FAST_POLICY.
  - No defensive programming that hides missing requirements or generates incorrect defaults.
  - Debugging code (4) must be isolated in debug/ folder for development and removed before final delivery.
  - Testing code (3) must be isolated in tests/ folder and committed to ensure project quality.

PROJECT_STRUCTURE_REFERENCE:
  - Project structure is documented in: obsidian-vault/Planning/
  - Includes folder organization, file purposes, and development workflows.
  - Structure follows established patterns in mrst_simulation_scripts/, src/, tests/, debug/ folders.

SIMPLE CODE POLICY (“Keep It Simple, Stupid”)
  ### KISS Core
  - Write the most direct, readable solution that fulfils the requirement—no speculative abstractions.
  - Break problems into small, single-purpose functions (see Rule 1 *FUNCTION_STRUCTURE*).

  ### Exception Handling Policy

  #### ALLOWED: Unpredictable External Failures Only
  - File system operations where files may not exist or permissions may change
  - Network operations where external services may be unavailable  
  - Optional dependency imports where libraries may not be installed
  - OS-level operations that depend on system state

  #### PROHIBITED: Predictable Application Logic
  - Flow control using exceptions instead of explicit validation
  - Input validation where you can check validity before processing
  - Data structure access where you can verify existence first
  - Type conversion where you can validate format before converting
  - Mathematical operations where you can validate inputs beforehand

  #### REQUIRED APPROACH:
  - Validate prerequisites explicitly before attempting operations
  - Fail immediately with specific, actionable error messages
  - Never use exception handling to bypass proper input validation
  - Never return default values when required data is missing

  ### Enforcement
  - Manual code review should check for proper try/except usage.
  - Broad exception handling or silent failures should be flagged during development.
  - Follow explicit validation patterns instead of exception-based flow control.

DATA_GENERATION_POLICY
  - **Prohibition of Hard‑Coding**
    - Do not embed fixed numeric answers, lookup tables, or formula constants directly in source files unless the value is a true physical constant (e.g., π, gravity).
    - Expected outputs for tests must be computed at runtime via simulator calls or helper utilities, never pasted literals.

  - **Simulator Authority**
    - Reservoir properties, stress calculations, synthetic logs, and any other domain‑specific values must originate from MRST, Octave scripts, or the designated ML pipelines.
    - If a new tool is introduced, its adoption must be documented in obsidian-vault/Planning/ with clear justification.

  - **Traceability Requirements**
    -Each dataset or artefact must include provenance metadata (timestamp, script name, parameters) either in filename or an accompanying .meta.json file.
    - Formulas or numerical methods belong in simulator scripts, not scattered across utilities.

FAIL_FAST_POLICY ("No Defensive Programming")
  ### Core Principle
  If required configuration, data, or dependencies are missing, FAIL immediately with clear error message explaining exactly what is needed and where to provide it.

  ### Prohibited Defensive Patterns
  - Default values for domain-specific parameters (pressures, temperatures, densities, coordinates)
  - Empty data structures when real data is expected
  - "Safe" fallbacks that produce scientifically incorrect results
  - Warnings followed by continued execution with missing critical data
  - Exception handling that hides configuration or setup errors

  ### Required Validation Approach
  - Check all prerequisites explicitly at function entry
  - Terminate immediately when requirements are not met
  - Error messages must specify exactly what is missing
  - Error messages must explain where to provide missing information
  - Never generate workarounds for missing essential inputs