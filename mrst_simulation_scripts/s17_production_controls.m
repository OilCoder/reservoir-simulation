function control_results = s17_production_controls()
% S17_PRODUCTION_CONTROLS - Eagle West Field Production Controls (REFACTORED)
%
% SINGLE RESPONSIBILITY: Create production and injection controls only
% 
% PURPOSE:
%   Creates production controls, injection controls, and control switching logic
%   NO schedule creation - that's s18's responsibility
%   
% CANONICAL OUTPUT:
%   controls.mat → production_controls, injection_controls, control_switching
%
% DEPENDENCIES:
%   - wells.mat (from s15→s16)
%   - production_config.yaml
%   - wells_config.yaml
%
% NO SCHEDULE CREATION: Only controls, s18 creates schedule
%
% Author: Claude Code AI System  
% Date: August 28, 2025 (REFACTORED)

    % Add paths and utilities
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'production_controls'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    
    warning('off', 'all');
    print_step_header('S17', 'Production Controls (REFACTORED)');
    
    total_start_time = tic;
    
    try
        % Step 1: Load dependencies
        step_start = tic;
        [W, well_config, prod_config] = load_controls_dependencies(script_dir);
        print_step_result(1, 'Load Dependencies', 'success', toc(step_start));
        
        % Step 2: Create production controls
        step_start = tic;
        production_controls = create_production_controls(W, well_config, prod_config);
        print_step_result(2, 'Create Production Controls', 'success', toc(step_start));
        
        % Step 3: Create injection controls  
        step_start = tic;
        injection_controls = create_injection_controls(W, well_config, prod_config);
        print_step_result(3, 'Create Injection Controls', 'success', toc(step_start));
        
        % Step 4: Create control switching logic
        step_start = tic;
        control_switching = create_control_switching(production_controls, injection_controls, prod_config);
        print_step_result(4, 'Create Control Switching', 'success', toc(step_start));
        
        % Step 5: Save controls data
        step_start = tic;
        controls_file = '/workspace/data/mrst/controls.mat';
        save(controls_file, 'production_controls', 'injection_controls', 'control_switching', '-v7');
        print_step_result(5, 'Save controls.mat', 'success', toc(step_start));
        
        % Create results structure
        control_results = struct();
        control_results.production_controls = production_controls;
        control_results.injection_controls = injection_controls;
        control_results.control_switching = control_switching;
        control_results.file_path = controls_file;
        control_results.status = 'completed';
        
        fprintf('\n✅ S17: Production Controls Completed\n');
        fprintf('   - Producer controls: %d\n', length(production_controls));
        fprintf('   - Injector controls: %d\n', length(injection_controls));
        fprintf('   - Saved to: %s\n', controls_file);
        fprintf('   - Execution time: %.2f seconds\n', toc(total_start_time));
        
    catch ME
        fprintf('\n❌ S17 Error: %s\n', ME.message);
        control_results = struct('status', 'failed', 'error', ME.message);
        rethrow(ME);
    end
end

function [W, well_config, prod_config] = load_controls_dependencies(script_dir)
% Load wells and configuration files
    
    % Load wells array from s16
    wells_file = '/workspace/data/mrst/wells.mat';
    if ~exist(wells_file, 'file')
        error('Wells file not found: %s. Run s15→s16 first.', wells_file);
    end
    wells_data = load(wells_file, 'W');
    W = wells_data.W;
    
    % Load wells configuration
    well_config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(well_config_file, 'file')
        error('Wells config not found: %s', well_config_file);
    end
    well_config = read_yaml_config(well_config_file);
    
    % Load production configuration
    prod_config_file = fullfile(script_dir, 'config', 'production_config.yaml');
    if ~exist(prod_config_file, 'file')
        error('Production config not found: %s', prod_config_file);
    end
    prod_config = read_yaml_config(prod_config_file);
    
    fprintf('Loaded %d wells for controls creation\n', length(W));
end

function production_controls = create_production_controls(W, well_config, prod_config)
% Create production controls for all producer wells
    
    production_controls = [];
    producer_wells = well_config.wells_system.producer_wells;
    producer_names = fieldnames(producer_wells);
    
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_data = producer_wells.(well_name);
        
        % Find corresponding MRST well
        well_idx = find(strcmp({W.name}, well_name));
        if isempty(well_idx)
            warning('MRST well not found for: %s', well_name);
            continue;
        end
        
        % Create control structure
        control = struct();
        control.name = well_name;
        control.type = 'producer';
        control.well_type = well_data.well_type;
        control.target_oil_rate_stb_day = well_data.target_oil_rate_stb_day;
        control.target_oil_rate_m3_day = well_data.target_oil_rate_stb_day * 0.159;
        control.min_bhp_psi = well_data.min_bhp_psi;
        control.min_bhp_pa = well_data.min_bhp_psi * 6895;
        control.max_water_cut = well_data.max_water_cut;
        control.max_gor_scf_stb = well_data.max_gor_scf_stb;
        
        % Add ESP data if available
        if isfield(well_data, 'esp_type')
            control.esp_type = well_data.esp_type;
            control.esp_stages = well_data.esp_stages;
            control.esp_hp = well_data.esp_hp;
        end
        
        % Add control switching thresholds
        control.rate_to_bhp_threshold = well_data.min_bhp_psi + prod_config.production_controls.control_switching.producer_bhp_margin_psi;
        control.bhp_to_rate_threshold = well_data.min_bhp_psi + prod_config.production_controls.control_switching.producer_bhp_recovery_psi;
        
        production_controls = [production_controls; control];
    end
end

function injection_controls = create_injection_controls(W, well_config, prod_config)
% Create injection controls for all injector wells
    
    injection_controls = [];
    injector_wells = well_config.wells_system.injector_wells;
    injector_names = fieldnames(injector_wells);
    
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_data = injector_wells.(well_name);
        
        % Find corresponding MRST well
        well_idx = find(strcmp({W.name}, well_name));
        if isempty(well_idx)
            warning('MRST well not found for: %s', well_name);
            continue;
        end
        
        % Create control structure
        control = struct();
        control.name = well_name;
        control.type = 'injector';
        control.well_type = well_data.well_type;
        control.target_injection_rate_bbl_day = well_data.target_injection_rate_bbl_day;
        control.target_injection_rate_m3_day = well_data.target_injection_rate_bbl_day * 0.159;
        control.max_bhp_psi = well_data.max_bhp_psi;
        control.max_bhp_pa = well_data.max_bhp_psi * 6895;
        control.injection_fluid = well_data.injection_fluid;
        
        % Add control switching thresholds
        control.rate_to_bhp_threshold = well_data.max_bhp_psi - prod_config.production_controls.control_switching.injector_bhp_margin_psi;
        control.bhp_to_rate_threshold = well_data.max_bhp_psi - prod_config.production_controls.control_switching.injector_bhp_recovery_psi;
        
        injection_controls = [injection_controls; control];
    end
end

function control_switching = create_control_switching(production_controls, injection_controls, prod_config)
% Create control switching logic configuration
    
    control_switching = struct();
    
    % General switching parameters
    control_switching.enabled = true;
    control_switching.check_frequency_days = prod_config.production_controls.development_parameters.check_frequency_days;
    
    % Producer switching rules
    control_switching.producer_rules = struct();
    control_switching.producer_rules.bhp_margin_psi = prod_config.production_controls.control_switching.producer_bhp_margin_psi;
    control_switching.producer_rules.bhp_recovery_psi = prod_config.production_controls.control_switching.producer_bhp_recovery_psi;
    control_switching.producer_rules.water_cut_limit = prod_config.production_controls.control_switching.safety_water_cut_limit;
    control_switching.producer_rules.gor_reduction_factor = prod_config.production_controls.control_switching.gor_reduction_factor;
    
    % Injector switching rules
    control_switching.injector_rules = struct();
    control_switching.injector_rules.bhp_margin_psi = prod_config.production_controls.control_switching.injector_bhp_margin_psi;
    control_switching.injector_rules.bhp_recovery_psi = prod_config.production_controls.control_switching.injector_bhp_recovery_psi;
    
    % Field level constraints
    control_switching.field_constraints = prod_config.production_controls.field_constraints;
    
    % Summary statistics
    control_switching.total_producers = length(production_controls);
    control_switching.total_injectors = length(injection_controls);
    control_switching.timestamp = datestr(now);
end