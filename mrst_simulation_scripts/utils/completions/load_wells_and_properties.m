function [wells_data, rock_props, G, wells_config, init_config] = load_wells_and_properties()
% LOAD_WELLS_AND_PROPERTIES - Load well placement and rock properties data
%
% OUTPUTS:
%   wells_data - Wells placement structure from s15
%   rock_props - Rock properties structure 
%   G - Grid structure from MRST
%   wells_config - Wells configuration from YAML
%   init_config - Initialization configuration from YAML
%
% Author: Claude Code AI System
% Date: August 22, 2025

    script_path = fileparts(fileparts(mfilename('fullpath')));
    
    % Load YAML configurations for unit conversions and well parameters
    addpath(fullfile(script_path, 'utils'));
    wells_config = read_yaml_config('config/wells_config.yaml', true);
    init_config = read_yaml_config('config/initialization_config.yaml', true);
    
    % Load wells from canonical MRST data structure
    canonical_mrst_dir = '/workspace/data/mrst';
    
    % Load wells data from canonical MRST structure
    wells_file = fullfile(canonical_mrst_dir, 'wells.mat');
    if exist(wells_file, 'file')
        wells_mat = load(wells_file, 'wells_results');
        % Extract wells data from wells_results structure
        wells_data = struct();
        wells_data.producer_wells = wells_mat.wells_results.producer_wells;
        wells_data.injector_wells = wells_mat.wells_results.injector_wells;
        wells_data.total_wells = wells_mat.wells_results.total_wells;
        fprintf('   ✅ Wells loaded from canonical MRST structure\n');
    else
        error(['CANON-FIRST ERROR: Wells data not found at canonical location.\n' ...
               'REQUIRED: Run s15_well_placement.m first.\n' ...
               'Expected file: %s'], wells_file);
    end
    
    % Load rock properties from canonical MRST structure
    rock_file = fullfile(canonical_mrst_dir, 'rock.mat');
    if exist(rock_file, 'file')
        rock_data = load(rock_file, 'rock');
        rock_props = struct('perm', rock_data.rock.perm, 'poro', rock_data.rock.poro);
        if isfield(rock_data.rock, 'rock_type_assignments')
            rock_types = rock_data.rock.rock_type_assignments;
        end
        fprintf('   ✅ Rock properties loaded from canonical MRST structure\n');
    else
        error(['CANON-FIRST ERROR: Rock properties not found at canonical location.\n' ...
               'REQUIRED: Run rock property initialization first.\n' ...
               'Expected file: %s'], rock_file);
    end
    
    % Load grid from canonical MRST structure
    grid_file = fullfile(canonical_mrst_dir, 'grid.mat');
    if exist(grid_file, 'file')
        grid_data = load(grid_file, 'G');
        G = grid_data.G;
        fprintf('   ✅ Grid loaded from canonical MRST structure\n');
    else
        error(['CANON-FIRST ERROR: Grid not found at canonical location.\n' ...
               'REQUIRED: Run grid initialization first.\n' ...
               'Expected file: %s'], grid_file);
    end

end