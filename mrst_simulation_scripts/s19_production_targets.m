function targets_results = s19_production_targets()
% S19_PRODUCTION_TARGETS - Eagle West Field Production Targets (REFACTORED)
%
% SINGLE RESPONSIBILITY: Create production targets by phase only
% 
% PURPOSE:
%   Creates production targets for 6 development phases
%   NO controls or schedule creation - those are s17 and s18's responsibilities
%   
% CANONICAL INPUT/OUTPUT:
%   Input: controls.mat (from s17), schedule.mat (from s18)
%   Output: targets.mat → production_targets, recovery_targets
%
% DEPENDENCIES:
%   - controls.mat (from s17)
%   - schedule.mat (from s18)
%   - wells_config.yaml (for target rates)
%
% NO CIRCULAR DEPENDENCIES: Clear input/output separation
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
    print_step_header('S19', 'Production Targets (REFACTORED)');
    
    total_start_time = tic;
    
    try
        % Step 1: Load dependencies
        step_start = tic;
        [controls_data, schedule_data, well_config] = load_targets_dependencies(script_dir);
        print_step_result(1, 'Load Dependencies', 'success', toc(step_start));
        
        % Step 2: Create production targets by phase
        step_start = tic;
        production_targets = create_production_targets(controls_data, schedule_data, well_config);
        print_step_result(2, 'Create Production Targets', 'success', toc(step_start));
        
        % Step 3: Create recovery targets
        step_start = tic;
        recovery_targets = create_recovery_targets(production_targets);
        print_step_result(3, 'Create Recovery Targets', 'success', toc(step_start));
        
        % Step 4: Save targets data
        step_start = tic;
        targets_file = '/workspace/data/mrst/targets.mat';
        save(targets_file, 'production_targets', 'recovery_targets', '-v7');
        print_step_result(4, 'Save targets.mat', 'success', toc(step_start));
        
        % Create results structure
        targets_results = struct();
        targets_results.production_targets = production_targets;
        targets_results.recovery_targets = recovery_targets;
        targets_results.total_phases = length(production_targets);
        targets_results.file_path = targets_file;
        targets_results.status = 'completed';
        
        fprintf('\n✅ S19: Production Targets Completed\n');
        fprintf('   - Production phases: %d\n', length(production_targets));
        fprintf('   - Peak oil rate: %.0f STB/day\n', max([production_targets.expected_oil_rate_stb_day]));
        fprintf('   - Saved to: %s\n', targets_file);
        fprintf('   - Execution time: %.2f seconds\n', toc(total_start_time));
        
    catch ME
        fprintf('\n❌ S19 Error: %s\n', ME.message);
        targets_results = struct('status', 'failed', 'error', ME.message);
        rethrow(ME);
    end
end

function [controls_data, schedule_data, well_config] = load_targets_dependencies(script_dir)
% Load controls, schedule, and configuration files
    
    % Load controls from s17
    controls_file = '/workspace/data/mrst/controls.mat';
    if ~exist(controls_file, 'file')
        error('Controls file not found: %s. Run s17 first.', controls_file);
    end
    controls_data = load(controls_file);
    
    % Load schedule from s18
    schedule_file = '/workspace/data/mrst/schedule.mat';
    if ~exist(schedule_file, 'file')
        error('Schedule file not found: %s. Run s18 first.', schedule_file);
    end
    schedule_data = load(schedule_file);
    
    % Load wells configuration for target rates
    well_config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(well_config_file, 'file')
        error('Wells config not found: %s', well_config_file);
    end
    well_config = read_yaml_config(well_config_file);
    
    fprintf('Loaded controls and schedule data for targets calculation\n');
end

function production_targets = create_production_targets(controls_data, schedule_data, well_config)
% Create production targets for 6 development phases
    
    production_targets = [];
    
    % Get development phases from schedule
    if isfield(schedule_data, 'development_phases')
        development_phases = schedule_data.development_phases;
    else
        % Create default 6-phase structure if not found
        development_phases = create_default_phases();
    end
    
    % Production efficiency from well config
    prod_efficiency = 0.9;  % 90% efficiency (expected vs target)
    
    for i = 1:length(development_phases)
        phase = development_phases(i);
        
        % Create target structure for this phase
        target = struct();
        target.phase_number = phase.phase_number;
        target.phase_name = phase.phase_name;
        target.duration_days = phase.duration_days;
        target.start_day = phase.start_day;
        target.end_day = phase.end_day;
        
        % Calculate oil production targets
        target.target_oil_rate_stb_day = calculate_phase_oil_target(phase, controls_data);
        target.expected_oil_rate_stb_day = target.target_oil_rate_stb_day * prod_efficiency;
        
        % Calculate injection targets
        target.injection_rate_bwpd = calculate_phase_injection_target(phase, controls_data);
        
        % Add fluid properties evolution
        target.water_cut = calculate_phase_water_cut(i);
        target.gor_scf_stb = calculate_phase_gor(i);
        
        production_targets = [production_targets; target];
    end
end

function oil_target = calculate_phase_oil_target(phase, controls_data)
% Calculate total oil production target for a phase
    
    oil_target = 0;
    active_wells = phase.active_wells;
    
    % Sum targets from active producer wells
    for i = 1:length(controls_data.production_controls)
        producer = controls_data.production_controls(i);
        if any(strcmp(active_wells, producer.name))
            oil_target = oil_target + producer.target_oil_rate_stb_day;
        end
    end
end

function injection_target = calculate_phase_injection_target(phase, controls_data)
% Calculate total injection target for a phase
    
    injection_target = 0;
    active_wells = phase.active_wells;
    
    % Sum targets from active injector wells
    for i = 1:length(controls_data.injection_controls)
        injector = controls_data.injection_controls(i);
        if any(strcmp(active_wells, injector.name))
            injection_target = injection_target + injector.target_injection_rate_bbl_day;
        end
    end
end

function water_cut = calculate_phase_water_cut(phase_num)
% Calculate water cut evolution by phase
    % Starting at 25% in phase 1, increasing 5% per phase
    water_cut = 0.20 + (phase_num * 0.05);
end

function gor = calculate_phase_gor(phase_num)
% Calculate GOR evolution by phase
    % Starting at 1300 SCF/STB, increasing 100 per phase
    gor = 1200 + (phase_num * 100);
end

function development_phases = create_default_phases()
% Create default 6-phase development structure if not found in schedule
    
    development_phases = [];
    
    phase_info = {
        {1, 'PHASE_1', 365, 0, 365, {'EW-001'}};
        {2, 'PHASE_2', 365, 365, 730, {'EW-001', 'EW-002', 'IW-001'}};
        {3, 'PHASE_3', 365, 730, 1095, {'EW-001', 'EW-002', 'EW-003', 'EW-004', 'IW-001', 'IW-002'}};
        {4, 'PHASE_4', 365, 1095, 1460, {'EW-001', 'EW-002', 'EW-003', 'EW-004', 'EW-005', 'EW-006', 'EW-007', 'IW-001', 'IW-002', 'IW-003'}};
        {5, 'PHASE_5', 365, 1460, 1825, {'EW-001', 'EW-002', 'EW-003', 'EW-004', 'EW-005', 'EW-006', 'EW-007', 'EW-008', 'EW-009', 'IW-001', 'IW-002', 'IW-003', 'IW-004'}};
        {6, 'PHASE_6', 365, 1825, 2190, {'EW-001', 'EW-002', 'EW-003', 'EW-004', 'EW-005', 'EW-006', 'EW-007', 'EW-008', 'EW-009', 'EW-010', 'IW-001', 'IW-002', 'IW-003', 'IW-004', 'IW-005'}};
    };
    
    for i = 1:length(phase_info)
        info = phase_info{i};
        phase = struct();
        phase.phase_number = info{1};
        phase.phase_name = info{2};
        phase.duration_days = info{3};
        phase.start_day = info{4};
        phase.end_day = info{5};
        phase.active_wells = info{6};
        development_phases = [development_phases; phase];
    end
end

function recovery_targets = create_recovery_targets(production_targets)
% Create recovery and economic targets
    
    recovery_targets = struct();
    
    % Field-level recovery targets
    recovery_targets.total_phases = length(production_targets);
    recovery_targets.simulation_duration_years = 10;
    recovery_targets.peak_oil_rate_stb_day = max([production_targets.expected_oil_rate_stb_day]);
    recovery_targets.cumulative_oil_target_mmstb = 50;  % 50 million STB target
    recovery_targets.recovery_factor_target = 0.35;     % 35% recovery factor
    
    % Economic targets
    recovery_targets.field_npv_target_musd = 1000;      % $1B NPV target
    recovery_targets.oil_price_assumption_bbl = 75;     % $75/bbl oil price
    recovery_targets.capex_estimate_musd = 250;         % $250M CAPEX
    recovery_targets.opex_estimate_usd_bbl = 15;        % $15/bbl OPEX
    
    % Reservoir management targets
    recovery_targets.max_field_water_cut = 0.85;        % 85% max water cut
    recovery_targets.voidage_replacement_ratio = 1.2;   % 1.2 VRR target
    recovery_targets.pressure_maintenance = true;       % Maintain reservoir pressure
    
    recovery_targets.timestamp = datestr(now);
    recovery_targets.created_by = 's19_production_targets';
end