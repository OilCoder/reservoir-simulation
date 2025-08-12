# Simulation Data Organization

## Directory Structure

### `/static/` - Time-invariant Data
- **`grid/`** - Grid geometry, refinement, structural framework
- **`rock/`** - Rock properties, heterogeneity, layer assignments  
- **`fluid/`** - PVT tables, SCAL properties, fluid initialization
- **`wells/`** - Well placement, completions, indices

### `/dynamic/` - Time-varying Data  
- **`pressures/`** - Pressure fields over time
- **`saturations/`** - Saturation distributions over time
- **`rates/`** - Production/injection rates over time

### `/results/` - Analysis Outputs
- Final simulation states
- Production summaries
- Quality validation reports
- Workflow execution logs

## File Naming Convention
- Static data: `{component}_{timestamp}.mat`
- Dynamic data: `{variable}_timeseries_{timestamp}.mat`
- Results: `{analysis_type}_{timestamp}.{ext}`

## Scripts Generating Data
- **S01-S15**: Generate `/static/` data
- **S22**: Generates `/dynamic/` and initial `/results/` 
- **S23-S25**: Generate analysis `/results/`