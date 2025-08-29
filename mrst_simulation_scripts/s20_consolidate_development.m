function consolidation_results = s20_consolidate_development()
% S20_CONSOLIDATE_DEVELOPMENT - Eagle West Field Development Consolidation
%
% PURPOSE: Consolidate all development data into single development.mat file
% 
% SINGLE RESPONSIBILITY: 
%   Combines wells.mat, controls.mat, schedule.mat, targets.mat into development.mat
%   Ready for s21+ simulation and analysis scripts
%   
% CANONICAL INPUT/OUTPUT:
%   Input: wells.mat, controls.mat, schedule.mat, targets.mat
%   Output: development.mat → consolidated development plan
%
% DEPENDENCIES:
%   - wells.mat (from s15→s16)
%   - controls.mat (from s17)
%   - schedule.mat (from s18)
%   - targets.mat (from s19)
%
% NO CIRCULAR DEPENDENCIES: Final consolidation step
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
    print_step_header('S20', 'Consolidate Development (NEW)');
    
    total_start_time = tic;
    
    try
        % Step 1: Load all development components
        step_start = tic;
        [wells_data, controls_data, schedule_data, targets_data] = load_development_components();
        print_step_result(1, 'Load Development Components', 'success', toc(step_start));
        
        % Step 2: Create consolidated development structure
        step_start = tic;
        development = create_consolidated_development(wells_data, controls_data, schedule_data, targets_data);
        print_step_result(2, 'Create Consolidated Structure', 'success', toc(step_start));
        
        % Step 3: Validate consolidated data
        step_start = tic;
        validation_results = validate_consolidated_data(development);
        print_step_result(3, 'Validate Consolidated Data', 'success', toc(step_start));
        
        % Step 4: Save consolidated development
        step_start = tic;
        development_file = '/workspace/data/mrst/development.mat';
        save(development_file, 'development', 'validation_results', '-v7');
        print_step_result(4, 'Save development.mat', 'success', toc(step_start));
        
        % Create results structure
        consolidation_results = struct();
        consolidation_results.development = development;
        consolidation_results.validation_results = validation_results;
        consolidation_results.file_path = development_file;
        consolidation_results.status = 'completed';
        
        fprintf('\n✅ S20: Development Consolidation Completed\n');
        fprintf('   - Wells: %d total (%d producers, %d injectors)\n', ...
            development.summary.total_wells, development.summary.total_producers, development.summary.total_injectors);
        fprintf('   - Phases: %d development phases\n', development.summary.total_phases);
        fprintf('   - Peak production: %.0f STB/day\n', development.summary.peak_oil_rate_stb_day);
        fprintf('   - Saved to: %s\n', development_file);
        fprintf('   - Execution time: %.2f seconds\n', toc(total_start_time));
        
        % Display consolidated data summary
        display_consolidation_summary(development);
        
    catch ME
        fprintf('\n❌ S20 Error: %s\n', ME.message);
        consolidation_results = struct('status', 'failed', 'error', ME.message);
        rethrow(ME);
    end
end

function [wells_data, controls_data, schedule_data, targets_data] = load_development_components()
% Load all development components with validation
    
    data_dir = '/workspace/data/mrst';
    
    % Load wells data
    wells_file = fullfile(data_dir, 'wells.mat');
    if ~exist(wells_file, 'file')
        error('Wells file not found: %s. Run s15→s16 first.', wells_file);
    end
    wells_data = load(wells_file);
    
    % Load controls data
    controls_file = fullfile(data_dir, 'controls.mat');
    if ~exist(controls_file, 'file')
        error('Controls file not found: %s. Run s17 first.', controls_file);
    end
    controls_data = load(controls_file);
    
    % Load schedule data
    schedule_file = fullfile(data_dir, 'schedule.mat');
    if ~exist(schedule_file, 'file')
        error('Schedule file not found: %s. Run s18 first.', schedule_file);
    end
    schedule_data = load(schedule_file);
    
    % Load targets data
    targets_file = fullfile(data_dir, 'targets.mat');
    if ~exist(targets_file, 'file')
        error('Targets file not found: %s. Run s19 first.', targets_file);
    end
    targets_data = load(targets_file);
    
    fprintf('Loaded all development components successfully\n');
end

function development = create_consolidated_development(wells_data, controls_data, schedule_data, targets_data)
% Create consolidated development structure
    
    development = struct();
    
    % Core development components
    development.wells = wells_data.W;
    development.production_controls = controls_data.production_controls;
    development.injection_controls = controls_data.injection_controls;
    development.control_switching = controls_data.control_switching;
    development.schedule = schedule_data.schedule;
    development.development_phases = schedule_data.development_phases;
    development.production_targets = targets_data.production_targets;
    development.recovery_targets = targets_data.recovery_targets;
    
    % Summary statistics
    development.summary = create_development_summary(wells_data, controls_data, targets_data);
    
    % Metadata
    development.metadata = struct();
    development.metadata.created_by = 's20_consolidate_development';
    development.metadata.timestamp = datestr(now);
    development.metadata.data_sources = {'wells.mat', 'controls.mat', 'schedule.mat', 'targets.mat'};
    development.metadata.consolidation_version = '1.0';
    
    % Field specifications (Eagle West Field canonical)
    development.field_specs = struct();
    development.field_specs.field_name = 'Eagle West Field';
    development.field_specs.grid_dimensions = '41x41x12';
    development.field_specs.simulation_duration_years = 10;
    development.field_specs.major_faults = 5;
    development.field_specs.reservoir_type = 'black_oil';
end

function summary = create_development_summary(wells_data, controls_data, targets_data)
% Create development summary statistics
    
    summary = struct();
    
    % Wells summary
    summary.total_wells = length(wells_data.W);
    summary.total_producers = length(controls_data.production_controls);
    summary.total_injectors = length(controls_data.injection_controls);
    
    % Production summary
    if ~isempty(targets_data.production_targets)
        summary.total_phases = length(targets_data.production_targets);
        summary.peak_oil_rate_stb_day = max([targets_data.production_targets.expected_oil_rate_stb_day]);
        summary.total_injection_rate_bwpd = max([targets_data.production_targets.injection_rate_bwpd]);
    else
        summary.total_phases = 0;
        summary.peak_oil_rate_stb_day = 0;
        summary.total_injection_rate_bwpd = 0;
    end
    
    % Recovery summary
    if isfield(targets_data, 'recovery_targets')
        summary.recovery_factor_target = targets_data.recovery_targets.recovery_factor_target;
        summary.field_npv_target_musd = targets_data.recovery_targets.field_npv_target_musd;
    else
        summary.recovery_factor_target = 0.35;  % Default
        summary.field_npv_target_musd = 1000;   % Default
    end
end

function validation_results = validate_consolidated_data(development)
% Validate consolidated development data
    
    validation_results = struct();
    validation_results.status = 'validating';
    validation_results.errors = {};
    validation_results.warnings = {};
    validation_results.summary = struct();
    
    % Validate wells consistency
    wells_validation = validate_wells_consistency(development);
    validation_results.wells_validation = wells_validation;
    
    % Validate controls consistency
    controls_validation = validate_controls_consistency(development);
    validation_results.controls_validation = controls_validation;
    
    % Validate schedule consistency
    schedule_validation = validate_schedule_consistency(development);
    validation_results.schedule_validation = schedule_validation;
    
    % Validate targets consistency
    targets_validation = validate_targets_consistency(development);
    validation_results.targets_validation = targets_validation;
    
    % Overall validation status
    total_errors = length(wells_validation.errors) + length(controls_validation.errors) + ...
                   length(schedule_validation.errors) + length(targets_validation.errors);
    
    if total_errors == 0
        validation_results.status = 'passed';
    else
        validation_results.status = 'failed';
        validation_results.total_errors = total_errors;
    end
    
    validation_results.timestamp = datestr(now);
end

function wells_validation = validate_wells_consistency(development)
% Validate wells data consistency
    
    wells_validation = struct();
    wells_validation.errors = {};
    wells_validation.status = 'validating';
    
    % Check basic wells structure
    if ~isfield(development, 'wells') || isempty(development.wells)
        wells_validation.errors{end+1} = 'No wells data found';
    else
        wells_validation.total_wells = length(development.wells);
        
        % Check well names consistency
        well_names = {development.wells.name};
        if length(unique(well_names)) ~= length(well_names)
            wells_validation.errors{end+1} = 'Duplicate well names found';
        end
    end
    
    if isempty(wells_validation.errors)
        wells_validation.status = 'passed';
    else
        wells_validation.status = 'failed';
    end
end

function controls_validation = validate_controls_consistency(development)
% Validate controls data consistency
    
    controls_validation = struct();
    controls_validation.errors = {};
    controls_validation.status = 'validating';
    
    % Check controls data exists
    if ~isfield(development, 'production_controls') || isempty(development.production_controls)
        controls_validation.errors{end+1} = 'No production controls found';
    end
    
    if ~isfield(development, 'injection_controls') || isempty(development.injection_controls)
        controls_validation.errors{end+1} = 'No injection controls found';
    end
    
    if isempty(controls_validation.errors)
        controls_validation.status = 'passed';
        controls_validation.total_producer_controls = length(development.production_controls);
        controls_validation.total_injector_controls = length(development.injection_controls);
    else
        controls_validation.status = 'failed';
    end
end

function schedule_validation = validate_schedule_consistency(development)
% Validate schedule data consistency
    
    schedule_validation = struct();
    schedule_validation.errors = {};
    schedule_validation.status = 'validating';
    
    % Check schedule exists
    if ~isfield(development, 'schedule') || isempty(development.schedule)
        schedule_validation.errors{end+1} = 'No schedule data found';
    end
    
    % Check development phases
    if ~isfield(development, 'development_phases') || isempty(development.development_phases)
        schedule_validation.errors{end+1} = 'No development phases found';
    else
        schedule_validation.total_phases = length(development.development_phases);
        
        % Validate 6-phase Eagle West standard
        if schedule_validation.total_phases ~= 6
            schedule_validation.errors{end+1} = sprintf('Expected 6 phases, found %d', schedule_validation.total_phases);
        end
    end
    
    if isempty(schedule_validation.errors)
        schedule_validation.status = 'passed';
    else
        schedule_validation.status = 'failed';
    end
end

function targets_validation = validate_targets_consistency(development)
% Validate targets data consistency
    
    targets_validation = struct();
    targets_validation.errors = {};
    targets_validation.status = 'validating';
    
    % Check production targets
    if ~isfield(development, 'production_targets') || isempty(development.production_targets)
        targets_validation.errors{end+1} = 'No production targets found';
    else
        targets_validation.total_target_phases = length(development.production_targets);
        
        % Check peak production meets Eagle West specs
        peak_rate = max([development.production_targets.expected_oil_rate_stb_day]);
        if peak_rate < 15000  % Minimum expected for Eagle West
            targets_validation.errors{end+1} = sprintf('Peak production too low: %.0f STB/day', peak_rate);
        end
    end
    
    if isempty(targets_validation.errors)
        targets_validation.status = 'passed';
    else
        targets_validation.status = 'failed';
    end
end

function display_consolidation_summary(development)
% Display comprehensive consolidation summary
    
    fprintf('\n=== DEVELOPMENT CONSOLIDATION SUMMARY ===\n');
    fprintf('Field: %s\n', development.field_specs.field_name);
    fprintf('Grid: %s cells\n', development.field_specs.grid_dimensions);
    fprintf('Simulation: %d years\n', development.field_specs.simulation_duration_years);
    fprintf('\nWells System:\n');
    fprintf('  - Total: %d wells\n', development.summary.total_wells);
    fprintf('  - Producers: %d wells\n', development.summary.total_producers);
    fprintf('  - Injectors: %d wells\n', development.summary.total_injectors);
    fprintf('\nDevelopment Plan:\n');
    fprintf('  - Phases: %d phases\n', development.summary.total_phases);
    fprintf('  - Peak Oil: %.0f STB/day\n', development.summary.peak_oil_rate_stb_day);
    fprintf('  - Recovery Target: %.1f%%\n', development.summary.recovery_factor_target * 100);
    fprintf('  - NPV Target: $%.0fM\n', development.summary.field_npv_target_musd);
    fprintf('===========================================\n');
end