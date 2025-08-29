function completion_results = s16_well_completions()
% S16_WELL_COMPLETIONS - Eagle West Field Well Completions (REFACTORED)
%
% SINGLE RESPONSIBILITY: Add completion data to existing MRST wells array W
% 
% PURPOSE:
%   Updates MRST wells array W with completion intervals, well indices, and productivity
%   
% CANONICAL INPUT/OUTPUT:
%   Input: wells.mat → W (from s15)
%   Output: wells.mat → W (updated with completions)
%
% DEPENDENCIES:
%   - wells.mat (from s15)
%   - wells_config.yaml (completion specs)
%
% NO CHAIN DEPENDENCIES: Runs independently after s15
%
% Author: Claude Code AI System  
% Date: August 28, 2025 (REFACTORED)

    % Add paths and utilities
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    
    warning('off', 'all');
    print_step_header('S16', 'Well Completions (REFACTORED)');
    
    total_start_time = tic;
    
    try
        % Step 1: Load existing wells and configuration
        step_start = tic;
        [W, config] = load_wells_and_config(script_dir);
        print_step_result(1, 'Load Wells and Config', 'success', toc(step_start));
        
        % Step 2: Add completion data to wells
        step_start = tic;
        W = add_completion_data(W, config);
        print_step_result(2, 'Add Completion Data', 'success', toc(step_start));
        
        % Step 3: Save updated wells
        step_start = tic;
        wells_file = '/workspace/data/mrst/wells.mat';
        save(wells_file, 'W', '-v7');
        print_step_result(3, 'Save Updated wells.mat', 'success', toc(step_start));
        
        % Create results structure
        completion_results = struct();
        completion_results.W = W;
        completion_results.total_wells = length(W);
        completion_results.file_path = wells_file;
        completion_results.status = 'completed';
        
        fprintf('\n✅ S16: Well Completions Completed\n');
        fprintf('   - Wells updated: %d\n', length(W));
        fprintf('   - Saved to: %s\n', wells_file);
        fprintf('   - Execution time: %.2f seconds\n', toc(total_start_time));
        
    catch ME
        fprintf('\n❌ S16 Error: %s\n', ME.message);
        completion_results = struct('status', 'failed', 'error', ME.message);
        rethrow(ME);
    end
end

function [W, config] = load_wells_and_config(script_dir)
% Load existing wells array and completion configuration
    
    % Load wells array from s15
    wells_file = '/workspace/data/mrst/wells.mat';
    if ~exist(wells_file, 'file')
        error('Wells file not found: %s. Run s15 first.', wells_file);
    end
    wells_data = load(wells_file, 'W');
    W = wells_data.W;
    
    % Load wells configuration
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(config_file, 'file')
        error('Wells config not found: %s', config_file);
    end
    config = read_yaml_config(config_file);
    
    fprintf('Loaded %d wells for completion update\n', length(W));
end

function W = add_completion_data(W, config)
% Add completion data to existing MRST wells array
    
    % Get well configurations
    producer_wells = config.wells_system.producer_wells;
    injector_wells = config.wells_system.injector_wells;
    
    % Update each well with completion data
    for i = 1:length(W)
        well_name = W(i).name;
        
        % Find well configuration
        if isfield(producer_wells, well_name)
            well_config = producer_wells.(well_name);
            % Update producer completion data
            update_producer_completion(W, i, well_config);
        elseif isfield(injector_wells, well_name)
            well_config = injector_wells.(well_name);
            % Update injector completion data
            update_injector_completion(W, i, well_config);
        else
            warning('Well configuration not found for: %s', well_name);
        end
    end
end

function update_producer_completion(W, well_idx, well_config)
% Update producer well with completion data
    
    % Create completion data structure (to avoid field conflicts)
    completion_data = struct();
    
    % Add completion layers info
    if isfield(well_config, 'completion_layers')
        completion_data.completion_layers = well_config.completion_layers;
    end
    
    % Add well type info
    if isfield(well_config, 'well_type')
        completion_data.well_type = well_config.well_type;
    end
    
    % Add BHP constraints
    if isfield(well_config, 'min_bhp_psi')
        completion_data.bhp_limit = well_config.min_bhp_psi * 6895;  % Convert psi to Pa
    end
    
    % Add ESP info for producers
    if isfield(well_config, 'esp_type')
        completion_data.esp_type = well_config.esp_type;
        if isfield(well_config, 'esp_stages')
            completion_data.esp_stages = well_config.esp_stages;
        end
        if isfield(well_config, 'esp_hp')
            completion_data.esp_hp = well_config.esp_hp;
        end
    end
    
    % Add constraints
    if isfield(well_config, 'max_water_cut')
        completion_data.max_water_cut = well_config.max_water_cut;
    end
    
    if isfield(well_config, 'max_gor_scf_stb')
        completion_data.max_gor = well_config.max_gor_scf_stb;
    end
    
    % Store completion data in well structure
    W(well_idx).completion_data = completion_data;
end

function update_injector_completion(W, well_idx, well_config)
% Update injector well with completion data
    
    % Create completion data structure (to avoid field conflicts)
    completion_data = struct();
    
    % Add completion layers info
    if isfield(well_config, 'completion_layers')
        completion_data.completion_layers = well_config.completion_layers;
    end
    
    % Add well type info
    if isfield(well_config, 'well_type')
        completion_data.well_type = well_config.well_type;
    end
    
    % Add BHP constraints
    if isfield(well_config, 'max_bhp_psi')
        completion_data.bhp_limit = well_config.max_bhp_psi * 6895;  % Convert psi to Pa
    end
    
    % Add injection fluid info
    if isfield(well_config, 'injection_fluid')
        completion_data.injection_fluid = well_config.injection_fluid;
    end
    
    % Add horizontal length for horizontal wells
    if isfield(well_config, 'horizontal_length_ft')
        completion_data.horizontal_length = well_config.horizontal_length_ft;
    end
    
    % Add lateral lengths for multilateral wells
    if isfield(well_config, 'lateral_1_length_ft')
        completion_data.lateral_1_length = well_config.lateral_1_length_ft;
    end
    if isfield(well_config, 'lateral_2_length_ft')
        completion_data.lateral_2_length = well_config.lateral_2_length_ft;
    end
    
    % Store completion data in well structure
    W(well_idx).completion_data = completion_data;
end