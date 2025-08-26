---
description: Define behavior and rules for debug code and files
---

DEBUG_ROOT_FOLDER:
  - All scratch / exploratory code goes in the top‑level directory debug/.
  - The entire debug/ folder is listed in .gitignore. No debug scripts are committed.

FILENAME_CONVENTION:
  - See 05-file-naming.md for naming files guidance.

DEBUG_WRITING_RULES:
  - Each script targets a specific module or function in src/ or mrst_simulation_scripts/; keep that link explicit in the name.
  - Use clear section headers and variable names to describe your intent.
  - Add inline comments to document key findings or dead ends.
  - Temporary logging and print/disp statements are allowed.
  - No print()/disp() or logging should remain in the final version unless it's part of the functional output or proper logging infrastructure.
  - Keep code readable, even if not production-grade — think of it as an experiment log.
  - **ALL COMMENTS AND OUTPUT MUST BE IN ENGLISH** - No Spanish allowed in debug files.
  - Final code must be clean, minimal, and free of any debugging noise.

ISOLATION_AND_ARTIFACTS:
  - Debug scripts must never be imported by production or test code.
  - Any large files or outputs created during debugging go to debug/.

PROMOTION_PATH:
  - If a debug script exposes a bug or behavior worth validating:
  - Convert the scenario into a proper test inside tests/ using the test rules.
s