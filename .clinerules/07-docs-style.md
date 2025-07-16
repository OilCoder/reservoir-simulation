---
description: Define standards for documentation files
---

DOCS_ROOT_FOLDER:
  - All documentation files must live in the top-level directory docs/.
  - Inside it, use subfolders by language to keep documents well organized:
      docs/English/ for documentation in English
      docs/Spanish/ for documentation in Spanish
  - Auto-generated content must not be placed here.

FILENAME_CONVENTION:
    - See 05-file-naming.md for naming files guidance. 

DOC_WRITING_RULES:
    - Each document must reflect the actual behavior of the code — not future plans or assumptions.
    - Every file must include the following sections:

REQUIRED_SECTIONS:
    1. Title and Purpose
        - Start with a single sentence summarizing the module's role.
    2. Workflow Description
        - Describe the sequence of operations performed.
        - Use numbered steps or descriptive text.
        - Include a Mermaid diagram using `flowchart TD` or `graph LR` if applicable.
    3. Inputs and Outputs
        - List each parameter with name, type, and purpose.
        - Describe expected output(s) and their structure.
    4. Mathematical Explanation (if applicable)
        - Use LaTeX inside code blocks to describe formulas or logical steps.
    5. Code Reference
        - Always include the source module path (e.g., `Source: code/src/module.py`)

STYLE:
    - Write clearly and concisely. Use short paragraphs, bullet points, and examples when helpful.
    - Document only what exists in the current version of the code. Avoid TODOs and speculative notes.

