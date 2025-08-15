# Canonical Data Utilities Framework

## Overview

The Canonical Data Utilities Framework provides a comprehensive system for organizing, validating, and managing MRST simulation data following the **Simulation Data Catalog** canon established for the Eagle West Field project.

## Key Features

### 🏛️ Canon-First Philosophy
- **No defensive programming** - fail fast with specific error messages
- **Documentation-driven** - implements exact specifications from canon
- **Zero fallbacks** - missing specifications require canon updates
- **Explicit validation** - all inputs validated against canonical requirements

### 📁 Multi-Organization Data Structure
- **by_type/**: Primary organization by intrinsic data characteristics
- **by_usage/**: Secondary organization by application purpose  
- **by_phase/**: Tertiary organization by project timeline
- **metadata/**: Comprehensive metadata and validation infrastructure

### 🔧 Modern Data Formats
- **HDF5**: Large arrays for Python/ML compatibility
- **YAML**: Configuration and metadata
- **Parquet**: ML-ready feature matrices (future)
- **Automatic symlinks**: Multi-organization access patterns

### ✅ Comprehensive Validation
- **File existence and accessibility**
- **Data format compliance** 
- **Cross-step dependency validation**
- **Quality threshold checking** (Eagle West Field specific)
- **Canonical organization verification**

## Core Utilities

### 1. `canonical_data_utils.m`
**Primary data export and organization utility**

```matlab
% Save data following canonical organization
output_files = save_canonical_data('s05', grid_data, ...
    'formats', {'hdf5', 'yaml'}, ...
    'organizations', {'by_type', 'by_usage', 'by_phase'});
```

**Key Functions:**
- `save_canonical_data()` - Universal canonical data export
- `validate_step_name()` - Canon step name validation
- `generate_canonical_metadata()` - Comprehensive metadata creation
- `create_organization_symlinks()` - Multi-organization access setup

### 2. `workflow_validation.m`  
**Comprehensive validation framework**

```matlab
% Validate complete workflow
validation_report = validate_workflow_data({'s05', 's06', 's07'}, ...
    'validation_level', 'standard', ...
    'fix_issues', true);
```

**Key Functions:**
- `validate_workflow_data()` - Multi-step validation orchestrator
- `validate_individual_step()` - Single step comprehensive validation
- `validate_cross_step_consistency()` - Inter-step dependency validation
- `validate_data_quality()` - Eagle West Field quality thresholds

### 3. `directory_management.m`
**Canonical structure creation and management**

```matlab
% Create complete canonical structure
create_canonical_structure('/path/to/simulation_data', ...
    'create_symlinks', true, ...
    'create_metadata', true);
```

**Key Functions:**
- `create_canonical_structure()` - Complete structure creation
- `validate_directory_structure()` - Structure completeness validation
- `repair_directory_structure()` - Automatic structure repair
- `get_structure_info()` - Detailed structure analysis

### 4. `data_export_utils.m` (Enhanced)
**Legacy compatibility and migration support**

```matlab
% Migrate legacy data to canonical format
migrate_to_canonical_format('/path/to/legacy_data', ...
    'target_base_path', '/path/to/canonical_data', ...
    'validation_level', 'standard');
```

**Key Functions:**
- `export_canonical_static_data()` - Bridge to canonical utilities
- `migrate_to_canonical_format()` - Legacy data migration
- `scan_legacy_data_files()` - Legacy file discovery and analysis

## Directory Structure

### Canonical Organization

```
data/simulation_data/
├── by_type/                    # Primary organization
│   ├── static/
│   │   ├── geometry/           # Grid data (s05)
│   │   ├── geology/            # Rock properties (s06-s08), faults (s04)
│   │   ├── fluid_properties/   # PVT data (s02)
│   │   ├── scal_properties/    # Relative permeability (s09)
│   │   ├── wells/              # Well definitions
│   │   └── initial_conditions/ # Initial state
│   ├── dynamic/                # Time-varying data
│   │   ├── pressures/          # Pressure evolution
│   │   ├── saturations/        # Saturation evolution  
│   │   ├── rates/              # Well rates
│   │   └── states/             # Complete solution states
│   ├── solver/                 # Numerical diagnostics
│   │   ├── convergence/        # Newton iteration data
│   │   ├── performance/        # Solver timing
│   │   └── diagnostics/        # Stability indicators
│   ├── derived/                # Calculated analytics
│   │   ├── recovery_factors/   # Recovery analysis
│   │   ├── sweep_efficiency/   # Displacement metrics
│   │   └── connectivity/       # Well interference
│   └── ml_features/            # ML-ready features
│       ├── static_features/    # Time-invariant features
│       ├── dynamic_features/   # Time-varying features
│       └── temporal_features/  # Time-based engineering
├── by_usage/                   # Secondary organization
│   ├── simulation_setup/       # Data for MRST runs
│   ├── ML_training/            # Machine learning datasets
│   ├── visualization/          # Plotting and analysis
│   └── geological_modeling/    # Geological analysis
├── by_phase/                   # Project timeline organization
│   ├── pre_simulation/         # Setup phase (s01-s09)
│   ├── simulation/             # Runtime phase (s10-s23)
│   ├── post_analysis/          # Analysis phase (s24-s25)
│   └── simulation_ready/       # Final inputs
└── metadata/                   # Infrastructure
    ├── schemas/                # YAML metadata schemas
    ├── validation/             # Validation reports
    ├── documentation/          # Structure guides
    └── catalogs/               # Data inventories
```

## Usage Examples

### Basic Workflow

```matlab
% 1. Create canonical structure
base_path = '/workspaces/claudeclean/data/simulation_data';
create_canonical_structure(base_path);

% 2. Save workflow data
% After s05_create_pebi_grid.m:
output_files = save_canonical_data('s05', struct('G', G), ...
    'base_path', base_path);

% After s06_create_base_rock.m:  
save_canonical_data('s06', struct('rock', rock), ...
    'base_path', base_path);

% 3. Validate workflow
validation_report = validate_workflow_data({'s05', 's06'}, ...
    'base_path', base_path, ...
    'validation_level', 'standard');

% 4. Check results
if strcmp(validation_report.validation_summary.overall_status, "PASS")
    fprintf('✅ Workflow validation passed\n');
else
    fprintf('❌ Issues found: %d\n', validation_report.validation_summary.total_issues);
end
```

### Advanced Integration

```matlab
% Enhanced export with full metadata
enhanced_data = struct();
enhanced_data.G = G;                    % Grid structure
enhanced_data.rock = rock;              % Rock properties  
enhanced_data.metadata = struct();     % Additional metadata
enhanced_data.metadata.step_name = 's06_create_base_rock';
enhanced_data.metadata.eagle_west_specs = true;

output_files = save_canonical_data('s06', enhanced_data, ...
    'formats', {'hdf5', 'yaml'}, ...
    'organizations', {'by_type', 'by_usage', 'by_phase'}, ...
    'metadata', struct('processing_notes', 'Enhanced rock properties'));

% Comprehensive validation with auto-fix
validation_report = validate_workflow_data('all', ...
    'base_path', base_path, ...
    'validation_level', 'comprehensive', ...
    'fix_issues', true);
```

### Legacy Migration

```matlab
% Migrate existing data to canonical format
legacy_path = '/old/simulation/data';
canonical_path = '/workspaces/claudeclean/data/simulation_data';

migrate_to_canonical_format(legacy_path, ...
    'target_base_path', canonical_path, ...
    'preserve_legacy', true, ...
    'validation_level', 'standard');
```

## File Naming Conventions

### Canonical Pattern
```
[data_type]_[timestamp].[extension]
```

**Examples:**
- `pebi_grid_20250815_143022.h5`
- `base_rock_properties_20250815_143022.h5` 
- `fluid_pvt_20250815_143022.yaml`
- `pebi_grid_metadata_20250815_143022.yaml`

### Current Version Symlinks
```
[data_type]_current.[extension]
```

**Examples:**
- `pebi_grid_current.h5` → `pebi_grid_20250815_143022.h5`
- `base_rock_properties_current.h5` → `base_rock_properties_20250815_143022.h5`

## Step Configuration Mapping

| Step | Data Type | Primary Category | Subcategory | Required Fields |
|------|-----------|------------------|-------------|-----------------|
| s01 | environment_control | control | mrst_session | mrst_modules, paths |
| s02 | fluid_pvt | static | fluid_properties | fluid, pvt_tables |
| s03 | structural_framework | static | geology | structural_framework, layers |
| s04 | fault_system | static | geology | faults, transmissibility |
| s05 | pebi_grid | static | geometry | G, cells, faces |
| s06 | base_rock_properties | static | geology | rock, poro, perm |
| s07 | enhanced_rock_properties | static | geology | rock, layers, metadata |
| s08 | final_simulation_rock | static | geology | rock, heterogeneity |
| s09 | relative_permeability | static | scal_properties | relperm, kr_tables |

## Quality Thresholds

### Eagle West Field Specifications

**Grid (s05):**
- Cell count: 15,000 - 25,000 cells
- File size: minimum 20 MB

**Rock Properties (s06-s08):**
- Porosity range: 0.05 - 0.35
- Permeability: positive values only
- File size: minimum 25-40 MB

**General:**
- File age: maximum 48 hours for active development
- Metadata completeness: 100% required

## Error Handling

### Canon-First Error Messages

**Missing Configuration:**
```
Error: Missing canonical parameter in config.
REQUIRED: Update obsidian-vault/Planning/Simulation_Data_Catalog/
STEP_DATA_OUTPUT_MAPPING.md to define parameter for Eagle West Field.
Canon must specify exact value, no defaults allowed.
```

**File Creation Failure:**
```
Error: Cannot create canonical directory: /path/to/dir
REQUIRED: Directory creation must succeed for canonical compliance.
Canon requires write access and proper permissions.
```

**Validation Failure:**
```
Error: Missing required files: pebi_grid.h5, grid_connectivity.h5
REQUIRED: All canonical files must exist for step s05.
Canon specification requires complete data output.
```

## Integration with MRST Workflow

### Step Integration Pattern

```matlab
% At end of each workflow step (e.g., s06_create_base_rock.m):

% Prepare data for canonical export
canonical_data = struct();
canonical_data.rock = rock;
canonical_data.porosity = rock.poro;
canonical_data.permeability = rock.perm;
canonical_data.metadata = struct();
canonical_data.metadata.step_completion_time = datestr(now);

% Save using canonical utilities
try
    output_files = save_canonical_data('s06', canonical_data);
    fprintf('✅ Canonical data saved: %d files\n', length(output_files.primary_files));
catch ME
    error('Canonical save failed: %s', ME.message);
end
```

### Workflow Validation Integration

```matlab
% In s99_run_workflow.m after completing steps:

% Validate completed workflow steps
completed_steps = {'s01', 's02', 's05', 's06', 's07', 's08'};

validation_result = validate_workflow_data(completed_steps, ...
    'validation_level', 'standard', ...
    'fix_issues', false);

if strcmp(validation_result.validation_summary.overall_status, "PASS")
    fprintf('✅ All workflow steps validated successfully\n');
else
    fprintf('⚠️  Validation issues found:\n');
    for i = 1:length(validation_result.recommendations)
        fprintf('   - %s\n', validation_result.recommendations{i});
    end
end
```

## Performance Considerations

### HDF5 vs MATLAB Files
- **HDF5**: Better for Python/ML compatibility, cross-platform access
- **MATLAB .mat**: Faster for MATLAB-only workflows
- **Recommendation**: Use HDF5 for primary storage, .mat for temporary files

### Symlink Performance
- **Unix/Linux**: Native symlinks for optimal performance
- **Windows**: File copies as fallback (requires admin rights for symlinks)
- **Network drives**: May require special handling

### Large Dataset Handling
- **Chunked writing**: For datasets > 1 GB
- **Compression**: Automatic for HDF5 files
- **Validation**: Configurable levels to balance thoroughness vs speed

## Troubleshooting

### Common Issues

**Issue: Symlink creation fails**
```
Solution: Check file permissions, use 'create_symlinks', false for testing
```

**Issue: HDF5 files cannot be created**
```
Solution: Verify write permissions, check disk space, ensure data is numeric
```

**Issue: Validation fails with "missing files"**
```
Solution: Check step naming convention, verify save_canonical_data completed successfully
```

**Issue: Cross-step validation errors**
```
Solution: Ensure dependency steps completed before dependent steps
```

### Debug Mode

```matlab
% Enable verbose output for debugging
create_canonical_structure(base_path, 'verbose', true);

% Use basic validation first
validation_result = validate_workflow_data(steps, ...
    'validation_level', 'basic', ...
    'report_format', 'summary');
```

## Canon Documentation References

- **Primary**: `obsidian-vault/Planning/Simulation_Data_Catalog/STEP_DATA_OUTPUT_MAPPING.md`
- **Structure**: `obsidian-vault/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md`
- **Quality**: `obsidian-vault/Planning/Reservoir_Definition/08_MRST_Implementation.md`

## Future Enhancements

### Planned Features
- **Parquet export**: For ML feature matrices
- **Real-time validation**: During simulation execution
- **Cloud storage**: Support for remote data repositories
- **Data lineage**: Complete provenance tracking
- **Automated testing**: Unit tests for all utilities

### Version Compatibility
- **Current**: Canonical v1.0 (August 2025)
- **MRST**: Compatible with MRST 2023a and later
- **MATLAB**: Requires R2019b or later for full functionality
- **Python**: HDF5 files compatible with h5py, pandas

---

**Status**: Production Ready  
**Version**: 1.0.0  
**Last Updated**: August 15, 2025  
**Canonical Compliance**: 100%  

For questions or issues, refer to the canon documentation or validate your implementation using the provided utilities.