function phase_schedules = create_phase_schedules(control_results, config)
% CREATE_PHASE_SCHEDULES - Create phased development schedules
%
% INPUTS:
%   control_results - Structure with producer and injector controls
%   config          - Configuration structure
%
% OUTPUTS:
%   phase_schedules - Structure with phase-based development schedules
%
% DATA AUTHORITY: All parameters from config files, no hardcoded values
% KISS PRINCIPLE: Single responsibility - only phase schedule creation

    fprintf('\n Phase-Based Development Schedules:\n');
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    
    phase_schedules = struct();
    
    % Get development parameters (Data Authority Policy)
    dev_params = config.production_controls.development_parameters;
    
    % Generate development phases based on well configuration
    max_phase = determine_max_phase(config.wells_system);
    
    % Create schedule for each phase
    for i = 1:max_phase
        phase_name = sprintf('phase_%d', i);
        ps = create_single_phase_schedule(i, config, dev_params);
        phase_schedules.(phase_name) = ps;
        
        fprintf('   %-10s │ Days %4d-%4d │ %2d wells │ %5d STB/d │ %5d BWD\n', ...
            phase_name, ps.timeline_days(1), ps.timeline_days(2), ...
            length(ps.active_producers) + length(ps.active_injectors), ...
            ps.target_oil_rate_stb_day, ps.injection_rate_bwpd);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────\n');

end

function max_phase = determine_max_phase(wells_system)
% DETERMINE_MAX_PHASE - Find maximum development phase
% KISS PRINCIPLE: Single responsibility helper function

    max_phase = 1;
    
    % Check producer wells
    producer_names = fieldnames(wells_system.producer_wells);
    for i = 1:length(producer_names)
        well_config = wells_system.producer_wells.(producer_names{i});
        max_phase = max(max_phase, well_config.phase);
    end
    
    % Check injector wells
    injector_names = fieldnames(wells_system.injector_wells);
    for i = 1:length(injector_names)
        well_config = wells_system.injector_wells.(injector_names{i});
        max_phase = max(max_phase, well_config.phase);
    end

end

function ps = create_single_phase_schedule(phase_number, config, dev_params)
% CREATE_SINGLE_PHASE_SCHEDULE - Create schedule for single development phase
% KISS PRINCIPLE: Single responsibility helper function

    ps = struct();
    ps.phase_name = sprintf('phase_%d', phase_number);
    ps.phase_number = phase_number;
    
    % Timeline calculation (Data Authority)
    days_per_year = 365;
    ps.timeline_days = [days_per_year * (phase_number - 1), days_per_year * phase_number];
    ps.duration_years = dev_params.phase_duration_years;
    
    % Determine active wells for this phase
    [ps.active_producers, ps.active_injectors, ps.wells_added] = ...
        determine_phase_wells(phase_number, config.wells_system);
    
    % Calculate production targets for phase (Data Authority)
    [ps.target_oil_rate_stb_day, ps.injection_rate_bwpd] = ...
        calculate_phase_targets(ps, config.wells_system);
    
    % Calculate derived parameters (Data Authority)
    ps.expected_oil_rate_stb_day = ps.target_oil_rate_stb_day * dev_params.production_efficiency;
    ps.water_cut_percent = dev_params.initial_water_cut_percent + phase_number * dev_params.water_cut_increase_per_phase;
    ps.gor_scf_stb = dev_params.initial_gor_scf_stb + phase_number * dev_params.gor_increase_per_phase;
    ps.vrr_target = dev_params.vrr_target;

end

function [active_producers, active_injectors, wells_added] = determine_phase_wells(phase_number, wells_system)
% DETERMINE_PHASE_WELLS - Determine wells active and added in phase
% KISS PRINCIPLE: Single responsibility helper function

    active_producers = {};
    active_injectors = {};
    wells_added = {};
    
    % Get producer wells for this phase
    producer_names = fieldnames(wells_system.producer_wells);
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_config = wells_system.producer_wells.(well_name);
        if well_config.phase <= phase_number
            active_producers{end+1} = well_name;
        end
        if well_config.phase == phase_number
            wells_added{end+1} = well_name;
        end
    end
    
    % Get injector wells for this phase
    injector_names = fieldnames(wells_system.injector_wells);
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_config = wells_system.injector_wells.(well_name);
        if well_config.phase <= phase_number
            active_injectors{end+1} = well_name;
        end
        if well_config.phase == phase_number
            wells_added{end+1} = well_name;
        end
    end

end

function [total_oil_rate, total_injection_rate] = calculate_phase_targets(phase_schedule, wells_system)
% CALCULATE_PHASE_TARGETS - Calculate production targets for phase
% KISS PRINCIPLE: Single responsibility helper function

    total_oil_rate = 0;
    total_injection_rate = 0;
    
    % Calculate total oil rate from active producers
    for i = 1:length(phase_schedule.active_producers)
        well_name = phase_schedule.active_producers{i};
        well_config = wells_system.producer_wells.(well_name);
        total_oil_rate = total_oil_rate + well_config.target_oil_rate_stb_day;
    end
    
    % Calculate total injection rate from active injectors
    for i = 1:length(phase_schedule.active_injectors)
        well_name = phase_schedule.active_injectors{i};
        well_config = wells_system.injector_wells.(well_name);
        total_injection_rate = total_injection_rate + well_config.target_injection_rate_bbl_day;
    end

end