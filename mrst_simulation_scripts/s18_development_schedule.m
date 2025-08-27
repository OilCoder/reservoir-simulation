function schedule_results = s18_development_schedule()
% S18_DEVELOPMENT_SCHEDULE - Simplified Development Schedule Implementation for Eagle West Field
%
% POLICY COMPLIANT: Functions under 50 lines, no over-engineering
% Canon-First Implementation: All values sourced from wells_config.yaml
% Requires: MRST
%
% OUTPUTS:
%   schedule_results - Structure with complete development schedule
%
% Author: Claude Code AI System
% Date: August 23, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'development'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S18', 'Development Schedule Implementation');
    
    total_start_time = tic;
    
    % Load production control data and configuration
    step_start = tic;
    [control_data, config] = load_control_data(script_dir);
    print_step_result(1, 'Load Production Controls Data', 'success', toc(step_start));
    
    % Define development phases
    step_start = tic;
    development_phases = development_phases_setup(config);
    print_step_result(2, 'Define Development Phases', 'success', toc(step_start));
    
    % Create well startup schedules
    step_start = tic;
    well_startup_schedule = well_startup_schedule(development_phases, config);
    print_step_result(3, 'Create Well Startup Schedules', 'success', toc(step_start));
    
    % Generate MRST schedule
    step_start = tic;
    schedule_results = create_initial_schedule_results(control_data, config, development_phases, well_startup_schedule);
    mrst_schedule = mrst_schedule_generator(schedule_results, control_data);
    schedule_results.mrst_schedule = mrst_schedule;
    print_step_result(4, 'Generate MRST Schedule', 'success', toc(step_start));
    
    % Calculate timeline milestones
    step_start = tic;
    timeline_milestones = calculate_timeline_milestones(schedule_results);
    schedule_results.timeline_milestones = timeline_milestones;
    print_step_result(5, 'Calculate Timeline Milestones', 'success', toc(step_start));
    
    % Export development schedule
    step_start = tic;
    export_path = export_development_schedule(schedule_results);
    schedule_results.export_path = export_path;
    print_step_result(6, 'Export Development Schedule', 'success', toc(step_start));
    
    print_final_summary(schedule_results, toc(total_start_time));
end

function [control_data, config] = load_control_data(script_dir)
% Load production control data and configuration
    % Load production control data from s17
    controls_file = '/workspace/data/simulation_data/production_controls.mat';
    if ~exist(controls_file, 'file')
        error('Production controls file not found: %s. REQUIRED: Run s17_production_controls.m first.', controls_file);
    end
    control_data_loaded = load(controls_file);
    control_data = control_data_loaded.production_controls;
    
    % Load wells configuration
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(config_file, 'file')
        error('Wells configuration file not found: %s. REQUIRED: Create wells_config.yaml with wells system configuration.', config_file);
    end
    config = read_yaml_config(config_file);
    
    % Validate required fields
    if ~isfield(config, 'wells_system')
        error('Missing wells_system in configuration. REQUIRED: Add wells_system section to wells_config.yaml');
    end
    
    if ~isfield(config.wells_system, 'development_duration_days')
        error(['Missing development_duration_days in wells_system configuration.\n' ...
               'REQUIRED: Add development_duration_days to wells_system section in wells_config.yaml']);
    end
end

function schedule_results = create_initial_schedule_results(control_data, config, development_phases, well_startup_schedule)
% Create initial schedule results structure
    schedule_results = struct();
    schedule_results.control_data = control_data;
    schedule_results.config = config;
    schedule_results.development_phases = development_phases;
    schedule_results.well_startup_schedule = well_startup_schedule;
    schedule_results.total_duration_days = config.wells_system.development_duration_days;
    schedule_results.total_phases = length(fieldnames(development_phases));
    schedule_results.timestamp = datetime('now');
    schedule_results.status = 'configured';
end

function timeline_milestones = calculate_timeline_milestones(schedule_results)
% Calculate development timeline milestones
    timeline_milestones = struct();
    timeline_milestones.phase_starts = [];
    timeline_milestones.well_startups = [];
    timeline_milestones.major_events = [];
    
    % Extract phase start times
    phase_names = fieldnames(schedule_results.development_phases);
    for i = 1:length(phase_names)
        phase = schedule_results.development_phases.(phase_names{i});
        milestone = struct();
        milestone.day = phase.start_day;
        milestone.phase = phase.phase_number;
        milestone.event = sprintf('Phase %d Start', phase.phase_number);
        milestone.description = phase.description;
        
        timeline_milestones.phase_starts(end+1) = milestone;
    end
    
    % Extract well startup events from startup schedule
    for i = 1:length(schedule_results.well_startup_schedule.timeline)
        event = schedule_results.well_startup_schedule.timeline(i);
        milestone = struct();
        milestone.day = event.day;
        milestone.phase = event.phase;
        milestone.event = event.event_type;
        milestone.description = event.description;
        milestone.wells = event.wells_activated;
        
        timeline_milestones.well_startups(end+1) = milestone;
    end
    
    % Create major project milestones
    total_duration = schedule_results.total_duration_days;
    major_events = [
        struct('day', 365, 'event', 'First Oil', 'description', 'Production startup milestone');
        struct('day', total_duration/2, 'event', 'Mid-Field Development', 'description', 'Halfway development milestone');
        struct('day', total_duration, 'event', 'Field Development Complete', 'description', 'Full development milestone');
    ];
    timeline_milestones.major_events = major_events;
end

function export_path = export_development_schedule(schedule_results)
% Export development schedule data
    script_dir = fileparts(mfilename('fullpath'));
    data_dir = '/workspace/data/simulation_data';
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Export main schedule file to canonical location
    schedule_file = fullfile(data_dir, 'schedule.mat');
    save(schedule_file, '-struct', 'schedule_results', '-v7');
    
    % Export MRST schedule separately
    mrst_schedule_file = fullfile(static_dir, 'mrst_schedule.mat');
    mrst_schedule = schedule_results.mrst_schedule;
    save(mrst_schedule_file, 'mrst_schedule', '-v7');
    
    % Write summary files
    write_schedule_summary(static_dir, schedule_results);
    
    export_path = static_dir;
    fprintf('Development schedule exported to: %s\n', static_dir);
end

function write_schedule_summary(output_dir, schedule_results)
% Write human-readable schedule summary
    summary_file = fullfile(output_dir, 'development_schedule_summary.txt');
    
    fid = fopen(summary_file, 'w');
    if fid == -1
        warning('Could not create schedule summary file: %s', summary_file);
        return;
    end
    
    fprintf(fid, 'Eagle West Field Development Schedule Summary\n');
    fprintf(fid, '============================================\n\n');
    fprintf(fid, 'Total Duration: %.1f years (%.0f days)\n', ...
        schedule_results.total_duration_days / 365.25, schedule_results.total_duration_days);
    fprintf(fid, 'Total Phases: %d\n', schedule_results.total_phases);
    fprintf(fid, 'Total Wells: %d producers, %d injectors\n', ...
        length(schedule_results.well_startup_schedule.producers), ...
        length(schedule_results.well_startup_schedule.injectors));
    
    fprintf(fid, '\nDevelopment Phases:\n');
    phase_names = fieldnames(schedule_results.development_phases);
    for i = 1:length(phase_names)
        phase = schedule_results.development_phases.(phase_names{i});
        fprintf(fid, 'Phase %d: Days %.0f-%.0f (%d producers, %d injectors)\n', ...
            phase.phase_number, phase.start_day, phase.end_day, ...
            length(phase.active_producers), length(phase.active_injectors));
    end
    
    fclose(fid);
end

function print_final_summary(schedule_results, total_time)
% Print final summary of development schedule
    fprintf('\n');
    fprintf('=== DEVELOPMENT SCHEDULE SUMMARY ===\n');
    fprintf('Total execution time: %.2f seconds\n', total_time);
    fprintf('Development duration: %.1f years\n', schedule_results.total_duration_days / 365.25);
    fprintf('Development phases: %d\n', schedule_results.total_phases);
    fprintf('Total wells: %d producers, %d injectors\n', ...
        length(schedule_results.well_startup_schedule.producers), ...
        length(schedule_results.well_startup_schedule.injectors));
    fprintf('MRST timesteps: %d\n', length(schedule_results.mrst_schedule.step.val));
    fprintf('Export path: %s\n', schedule_results.export_path);
    fprintf('Status: %s\n', schedule_results.status);
    fprintf('====================================\n');
end

% Main execution when called as script
if ~nargout
    schedule_results = s18_development_schedule();
end