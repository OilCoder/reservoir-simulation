function phase_specs = get_phase_specifications()
% GET_PHASE_SPECIFICATIONS - Canonical phase definitions for Eagle West Field
%
% Returns authoritative phase specifications for MRST workflow
% These definitions are the canonical source for all phase metadata
%
% SYNTAX:
%   phase_specs = get_phase_specifications()
%
% OUTPUT:
%   phase_specs - Cell array with phase_id, script_name, description
%
% Author: Claude Code AI System  
% Date: 2025-08-22

    phase_specs = {
        struct('phase_id', 's01', 'script_name', 's01_initialize_mrst', 'description', 'Initialize MRST Environment');
        struct('phase_id', 's02', 'script_name', 's02_define_fluids', 'description', 'Define Fluids (3-phase)');
        struct('phase_id', 's03', 'script_name', 's03_create_pebi_grid', 'description', 'PEBI Grid Construction (Canonical)');
        struct('phase_id', 's04', 'script_name', 's04_structural_framework', 'description', 'Structural Framework');
        struct('phase_id', 's05', 'script_name', 's05_add_faults', 'description', 'Add Fault System');
        struct('phase_id', 's06', 'script_name', 's06_create_base_rock_structure', 'description', 'Create Base Rock Structure');
        struct('phase_id', 's07', 'script_name', 's07_add_layer_metadata', 'description', 'Add Layer Metadata');
        struct('phase_id', 's08', 'script_name', 's08_apply_spatial_heterogeneity', 'description', 'Apply Spatial Heterogeneity');
        struct('phase_id', 's09', 'script_name', 's09_relative_permeability', 'description', 'Relative Permeability');
        struct('phase_id', 's10', 'script_name', 's10_capillary_pressure', 'description', 'Capillary Pressure');
        struct('phase_id', 's11', 'script_name', 's11_pvt_tables', 'description', 'PVT Tables');
        struct('phase_id', 's12', 'script_name', 's12_pressure_initialization', 'description', 'Pressure Initialization');
        struct('phase_id', 's13', 'script_name', 's13_saturation_distribution', 'description', 'Saturation Distribution');
        struct('phase_id', 's14', 'script_name', 's14_aquifer_configuration', 'description', 'Aquifer Configuration');
        struct('phase_id', 's15', 'script_name', 's15_well_placement', 'description', 'Well Placement (15 wells)');
        struct('phase_id', 's16', 'script_name', 's16_well_completions', 'description', 'Well Completions');
        struct('phase_id', 's17', 'script_name', 's17_production_controls', 'description', 'Production Controls');
        struct('phase_id', 's18', 'script_name', 's18_development_schedule', 'description', 'Development Schedule (6 phases)');
        struct('phase_id', 's19', 'script_name', 's19_production_targets', 'description', 'Production Targets');
        struct('phase_id', 's20', 'script_name', 's20_solver_setup', 'description', 'Solver Configuration (ad-fi)');
    };
end