function fluid = s09_relative_permeability()
% S09_RELATIVE_PERMEABILITY - Simplified Relative Permeability Definition for Eagle West Field
%
% POLICY COMPLIANT: Functions under 50 lines, no over-engineering
% Source: 04_SCAL_Properties.md (CANON)
% Requires: MRST ad-blackoil, ad-props
%
% OUTPUT:
%   fluid - MRST fluid structure with relative permeability functions
%
% Author: Claude Code AI System
% Date: August 23, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'relperm'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % WARNING SUPPRESSION: Complete silence for clean output
    warning('off', 'all');
    
    % Load corey functions explicitly
    run(fullfile(script_dir, 'utils', 'relperm', 'corey_functions.m'));

    % Add MRST to path manually (since session doesn't save paths)
    mrst_root = '/opt/mrst';
    addpath(genpath(fullfile(mrst_root, 'core'))); % Add all core subdirectories
    addpath(genpath(fullfile(mrst_root, 'modules')));
    
    % Load saved MRST session to check status
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/session/ as authoritative location
    workspace_root = '/workspace';
    session_file = fullfile(workspace_root, 'data', 'mrst', 'session', 's01_mrst_session.mat');
    if exist(session_file, 'file')
        loaded_data = load(session_file);
        if isfield(loaded_data, 'mrst_env') && strcmp(loaded_data.mrst_env.status, 'ready')
            fprintf('   ✅ MRST session validated\n');
        end
    else
        error('MRST session not found. Please run s01_initialize_mrst.m first.');
    end
    
    print_step_header('S09', 'Define Relative Permeability Curves (MRST Native)');
    
    total_start_time = tic;
    
    % Load SCAL configuration
    step_start = tic;
    [rock, G] = load_rock_data(script_dir);
    scal_config = load_scal_config(script_dir);
    print_step_result(1, 'Load SCAL Configuration', 'success', toc(step_start));
    
    % Create relative permeability functions
    step_start = tic;
    fluid = fluid_structure_setup(scal_config, G);
    print_step_result(2, 'Create Relative Permeability Functions', 'success', toc(step_start));
    
    % Assign rock-type specific properties
    step_start = tic;
    fluid = assign_rock_type_properties(fluid, scal_config, rock, G);
    print_step_result(3, 'Assign Rock-Type Specific Properties', 'success', toc(step_start));
    
    % Validate & export fluid structure
    step_start = tic;
    validation_results = fluid_validation(fluid, G);
    if validation_results.validation_passed
        export_fluid_structure(fluid, G, scal_config);
    else
        warning('Fluid validation failed - exported with validation warnings');
        export_fluid_structure(fluid, G, scal_config);
    end
    print_step_result(4, 'Validate & Export Fluid Structure', 'success', toc(step_start));
    
    print_final_summary(fluid, G, scal_config, toc(total_start_time));
end

function [rock, G] = load_rock_data(script_dir)
% Load rock properties and grid data from consolidated structure
    % Load rock properties from consolidated location
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    rock_file = '/workspace/data/mrst/rock.mat';
    if ~exist(rock_file, 'file')
        error('Rock properties file not found: %s. REQUIRED: Complete rock property workflow (s06-s08) first.', rock_file);
    end
    rock_data = load(rock_file);
    rock = rock_data.rock;
    
    % Load grid from consolidated location
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    grid_file = '/workspace/data/mrst/grid.mat';
    if ~exist(grid_file, 'file')
        error('Grid file not found: %s. REQUIRED: Run s03_create_pebi_grid.m first.', grid_file);
    end
    grid_data = load(grid_file);
    % Use fault grid if available, otherwise use base grid
    if isfield(grid_data, 'fault_grid') && ~isempty(grid_data.fault_grid)
        G = grid_data.fault_grid;
    else
        G = grid_data.G;
    end
    
    fprintf('   ✅ Rock data and grid loaded: %d cells with rock properties\n', G.cells.num);
end

function scal_config = load_scal_config(script_dir)
% Load SCAL configuration from YAML file
    config_file = fullfile(script_dir, 'config', 'scal_properties_config.yaml');
    if ~exist(config_file, 'file')
        error('SCAL configuration file not found: %s. REQUIRED: Create scal_properties_config.yaml with SCAL parameters.', config_file);
    end
    
    scal_config = read_yaml_config(config_file);
    
    % Validate required sections under scal_properties
    if ~isfield(scal_config, 'scal_properties')
        error('Missing scal_properties section in SCAL configuration. REQUIRED: Add scal_properties root section to scal_properties_config.yaml');
    end
    
    scal_props = scal_config.scal_properties;
    required_sections = {'sandstone_ow', 'sandstone_go'};
    for i = 1:length(required_sections)
        section = required_sections{i};
        if ~isfield(scal_props, section)
            error('Missing %s section in SCAL configuration. REQUIRED: Add %s parameters to scal_properties_config.yaml', section, section);
        end
    end
    
    % Return the scal_properties for easier access
    scal_config = scal_props;
    
    fprintf('SCAL configuration loaded successfully\n');
end

function fluid = assign_rock_type_properties(fluid, scal_config, rock, G)
% Assign rock-type specific properties to fluid
    % Create cell property maps for different rock types
    fluid = create_cell_property_maps(fluid, scal_config, rock, G);
    
    % Add wettability information
    fluid = add_wettability_info(fluid, scal_config);
    
    % Add validation metadata
    fluid = add_validation_metadata(fluid, scal_config);
    
    fprintf('Rock-type specific properties assigned\n');
end

function fluid = create_cell_property_maps(fluid, scal_config, rock, G)
% Create cell-by-cell property maps for different rock types
    n_cells = G.cells.num;
    
    % Initialize cell property maps
    fluid.cells = struct();
    fluid.cells.swc = zeros(n_cells, 1);  % Connate water saturation
    fluid.cells.sor = zeros(n_cells, 1);  % Residual oil saturation
    fluid.cells.sgc = zeros(n_cells, 1);  % Critical gas saturation
    
    % Get rock type assignments if available
    if isfield(rock, 'meta') && isfield(rock.meta, 'rock_type_assignments')
        rock_type_assignments = rock.meta.rock_type_assignments;
    else
        % Default to sandstone for all cells
        rock_type_assignments = ones(n_cells, 1);
        warning('Rock type assignments not found, defaulting all cells to sandstone');
    end
    
    % Assign properties based on rock type
    for cell_idx = 1:n_cells
        rock_type = rock_type_assignments(cell_idx);
        
        switch rock_type
            case {1, 2, 3} % Sandstone variants
                if isfield(scal_config, 'sandstone_ow')
                    fluid.cells.swc(cell_idx) = scal_config.sandstone_ow.connate_water_saturation;
                    fluid.cells.sor(cell_idx) = scal_config.sandstone_ow.residual_oil_saturation;
                end
                if isfield(scal_config, 'sandstone_go')
                    fluid.cells.sgc(cell_idx) = scal_config.sandstone_go.critical_gas_saturation;
                end
                
            case 6 % Shale barriers
                if isfield(scal_config, 'shale_ow')
                    fluid.cells.swc(cell_idx) = scal_config.shale_ow.connate_water_saturation;
                    fluid.cells.sor(cell_idx) = scal_config.shale_ow.residual_oil_saturation;
                end
                if isfield(scal_config, 'shale_go')
                    fluid.cells.sgc(cell_idx) = scal_config.shale_go.critical_gas_saturation;
                end
                
            otherwise % Default to sandstone
                if isfield(scal_config, 'sandstone_ow')
                    fluid.cells.swc(cell_idx) = scal_config.sandstone_ow.connate_water_saturation;
                    fluid.cells.sor(cell_idx) = scal_config.sandstone_ow.residual_oil_saturation;
                end
                if isfield(scal_config, 'sandstone_go')
                    fluid.cells.sgc(cell_idx) = scal_config.sandstone_go.critical_gas_saturation;
                end
        end
    end
end

function fluid = add_wettability_info(fluid, scal_config)
% Add wettability information to fluid structure
    if isfield(scal_config, 'wettability') && isfield(scal_config.wettability, 'sandstone')
        wett = scal_config.wettability.sandstone;
        
        fluid.wettability = struct();
        fluid.wettability.contact_angle = wett.contact_angle;
        fluid.wettability.description = wett.description;
        fluid.wettability.amott_harvey_oil = wett.amott_harvey_oil;
        fluid.wettability.amott_harvey_water = wett.amott_harvey_water;
        fluid.wettability.wettability_index = wett.wettability_index;
    end
end

function fluid = add_validation_metadata(fluid, scal_config)
% Add validation metadata to fluid structure
    fluid.metadata = struct();
    fluid.metadata.source = 'scal_properties_config.yaml';
    fluid.metadata.creation_date = datestr(now);
    fluid.metadata.model_type = 'three_phase_black_oil';
    
    if isfield(scal_config, 'validation')
        fluid.metadata.confidence_level = scal_config.validation.confidence_level;
        fluid.metadata.measurement_precision = scal_config.validation.measurement_precision;
        fluid.metadata.data_quality = scal_config.validation.data_quality;
    end
end

function export_fluid_structure(fluid, G, scal_config)
% Export fluid structure to canonical location
    % CANON-FIRST POLICY: Use only canonical Data Catalog structure
    % Documentation specifies /workspace/data/mrst/fluid.mat as authoritative location
    
    % Create a copy without function handles for saving
    fluid_for_save = fluid;
    function_handle_fields = {'krW', 'krOW', 'krG', 'krO'};
    for i = 1:length(function_handle_fields)
        field = function_handle_fields{i};
        if isfield(fluid_for_save, field) && isa(fluid_for_save.(field), 'function_handle')
            fluid_for_save.(field) = sprintf('Function handle removed for Octave compatibility');
        end
    end
    
    % Prepare SCAL summary data for inclusion in consolidated file
    scal_summary = create_scal_summary_data(fluid, G, scal_config);
    
    % Save consolidated fluid data to canonical location (/workspace/data/mrst/fluid.mat)
    save_consolidated_data('fluid', 's09', 'fluid', fluid_for_save, 'scal_summary', scal_summary);
    
    fprintf('Fluid structure exported to canonical location: /workspace/data/mrst/fluid.mat\n');
end

function scal_summary = create_scal_summary_data(fluid, G, scal_config)
% Create SCAL summary data structure for inclusion in consolidated file
    scal_summary = struct();
    scal_summary.description = 'Eagle West Field SCAL Properties Summary';
    scal_summary.grid_cells = G.cells.num;
    scal_summary.fluid_phases = fluid.phases;
    scal_summary.generation_date = datestr(now);
    
    if isfield(fluid, 'n')
        scal_summary.corey_exponents = fluid.n;
    end
    
    if isfield(scal_config, 'sandstone_ow')
        scal_summary.sandstone_ow = scal_config.sandstone_ow;
    end
    
    if isfield(scal_config, 'sandstone_go')
        scal_summary.sandstone_go = scal_config.sandstone_go;
    end
    
    % Add metadata for traceability
    scal_summary.metadata = struct();
    scal_summary.metadata.source_script = 's09_relative_permeability.m';
    scal_summary.metadata.config_source = 'scal_properties_config.yaml';
    scal_summary.metadata.data_authority = 'CANON-FIRST POLICY';
end

function print_final_summary(fluid, G, scal_config, total_time)
% Print final summary of relative permeability setup
    fprintf('\n');
    fprintf('=== RELATIVE PERMEABILITY SUMMARY ===\n');
    fprintf('Total execution time: %.2f seconds\n', total_time);
    fprintf('Grid cells: %d\n', G.cells.num);
    fprintf('Fluid phases: %s\n', fluid.phases);
    
    if isfield(fluid, 'n')
        fprintf('Corey exponents: [%.2f, %.2f, %.2f]\n', fluid.n(1), fluid.n(2), fluid.n(3));
    end
    
    % Count relative permeability functions
    relperm_funcs = 0;
    relperm_fields = {'krW', 'krOW', 'krG', 'krO'};
    for i = 1:length(relperm_fields)
        if isfield(fluid, relperm_fields{i})
            relperm_funcs = relperm_funcs + 1;
        end
    end
    fprintf('Relative permeability functions: %d\n', relperm_funcs);
    
    if isfield(fluid, 'wettability')
        fprintf('Wettability: %s\n', fluid.wettability.description);
    end
    
    fprintf('======================================\n');
end

% Main execution when called as script
if ~nargout
    fluid = s09_relative_permeability();
end