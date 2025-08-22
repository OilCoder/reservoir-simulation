# Eagle West OPM Workflow

## Quick Start
```bash
python scripts/run_opm_workflow.py     # Complete workflow
python scripts/s22_omp_simulation.py   # Just simulation  
python scripts/s24_omp_analytics.py    # Just analytics
```

## Structure
- `scripts/` - All workflow scripts (simulation, analytics, automation)
- `resinsight_data/` - ResInsight input files

## Data
- Results → `/workspace/mrst_simulation_scripts/data/opm/`
- MRST data → `/workspace/mrst_simulation_scripts/data/`