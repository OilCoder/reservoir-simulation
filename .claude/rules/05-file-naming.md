---
description: Enforce consistent file naming across the geomechanical ML project
---

All files must follow consistent and descriptive naming conventions to ensure discoverability, clarity, and traceability across the codebase.

GENERAL_CONVENTIONS
  - Use snake_case for all files: lowercase letters with underscores
  - Filenames must reflect the purpose or main component of the file
  - Avoid generic names like `script.m`, `data.mat`, `utils.py` unless scoped in clearly named folders
  - No spaces, accented characters, or mixed camelCase/snake_case in filenames
  - **ALL NAMES MUST BE IN ENGLISH** - No Spanish names allowed (read DOCUMENTATION for exceptions)
  -  scripts must carry the sNN prefix so anyone can deduce execution order by simply listing the directory contents.

  Octave + MRST Scripts / 
    - Location: /mrst_simulation_scripts/.
    - Must include % Requires: MRST at the top.

  Python Scripts
    - Location: /src/ with logical subfolders.

  Pattern:
    - sNN[x]_<verb>_<noun>.<ext>
      - s	Fixed prefix = step (starts with a letter → safe for Octave).
      - NN	Two‑digit primary step index (00–99).
      - x	Optional sub‑step letter (a–z) for finer ordering.
      - <verb>_<noun>	Snake‑case action descriptor.
      - <ext>	.m (Octave + MRST) or .py (Python).
    Examples:
      `s00a_setup_field.m`
      `s01_create_schedule.m`
      `s03b_generate_report.m`
      `s00_prepare_dataset.py`
      `s01_split_data.py`
      `s04_export_artifacts.py`

  Main launcher
    - If a single file orchestrates the entire workflow, name it with the prefix s99_ followed by a descriptive snake‑case phrase.
    - The 99 prefix ensures it appears last in directory listings.
    - Place the launcher in the same folder as the other workflow scripts and keep its contents lightweight—just high‑level orchestration, not heavy business logic.
    Examples: 
      `s99_run_workflow.m`
      `s99_execute_pipeline.py`
      `s99_full_simulation.m.`

TEST_FILES
- Pattern: test_<NN>_<folder>_<module>[_<purpose>].m
  - NN = two-digit index (01–99) for natural ordering
  - folder = source folder being tested (mrst_simulation_scripts, src, etc.)
  - module = specific file being tested (without .m/.py extension)
  - purpose = optional tag for test variant or specific case
  Examples:
    `test_01_mrst_simulation_scripts_setup_field.m`
    `test_02_src_surrogate_training_validation.m`
    `test_03_mrst_simulation_scripts_export_dataset_io.m`
  - All test files live under tests/ folder

DEBUG_FILES
- Pattern: dbg_<slug>[_<experiment>].m
  - slug = short descriptive name of what's being debugged
  - experiment = optional tag for specific debug purpose
  Examples:
    `dbg_pressure_map.m`
    `dbg_grid_refinement.m`
    `dbg_export_validation.m`
  - All debug files live under `/debug/` folder

DOCUMENTATION
  - Location: 
    obsidian-vault/Spanish/ para documentación en español, leer 07-docs-style.md
    obsidian-vault/English/ for English documentation, read 07-docs-style.md
  - Pattern: <NN>_<slug>.md
    - NN = two‑digit index (01–99) for natural ordering
    - slug = concise English/Español descriptor.
    Examples:
      `obsidian-vault/English/00_setup_guide.md`
      `obsidian-vault/English/01_introduction.md`
      `obsidian-vault/Spanish/02_configuracion_inicial.md`
      `obsidian-vault/Spanish/03_configuracion_parametros.md`
