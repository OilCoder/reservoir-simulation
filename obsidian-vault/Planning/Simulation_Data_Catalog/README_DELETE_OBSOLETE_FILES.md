# OBSOLETE FILES TO BE DELETED

This file tracks the deletion of obsolete documentation files during the Canon-First restructuring.

## Files Deleted During Restructuring (2025-08-21)

The following files were removed as part of the Canon-First simplification:

1. `01_Static_Data_Inventory.md` - Replaced by new canonical structure
2. `02_Dynamic_Data_Inventory.md` - Replaced by new canonical structure  
3. `03_Solver_Internal_Data.md` - Replaced by new canonical structure
4. `04_Derived_Calculated_Data.md` - Replaced by new canonical structure
5. `05_Visualization_Outputs.md` - Replaced by new canonical structure
6. `06_ML_Ready_Features.md` - Replaced by new canonical structure
7. `07_Metadata_Specifications.md` - Replaced by new canonical structure
8. `08_Data_Access_Guide.md` - Replaced by new canonical structure
9. `09_Storage_Organization.md` - Replaced by new canonical structure
10. `00_Data_Catalog_Overview.md` - Replaced by new canonical structure
11. `COMPREHENSIVE_DATA_CAPTURE_ANALYSIS.md` - Obsolete complex analysis
12. `STEP_DATA_OUTPUT_MAPPING.md` - Replaced by script-to-file mapping
13. `README_Data_Catalog.md` - Replaced by new master README

## Reason for Restructuring

The previous documentation reflected a complex by_type/by_usage/by_phase organization with 30+ files.
The new Canon-First approach simplifies to 7 canonical .mat files with clear script-to-file mapping.

This deletion is part of implementing the canonical MRST structure:
- `/workspace/data/mrst/grid.mat`
- `/workspace/data/mrst/rock.mat`  
- `/workspace/data/mrst/fluid.mat`
- `/workspace/data/mrst/wells.mat`
- `/workspace/data/mrst/initial_state.mat`
- `/workspace/data/mrst/schedule.mat`
- `/workspace/data/mrst/solver.mat`
- `/workspace/data/mrst/session/mrst_session.mat`

New documentation reflects this simplified, maintainable structure.