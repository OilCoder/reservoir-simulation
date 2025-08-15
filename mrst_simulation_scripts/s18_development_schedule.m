function schedule_results = s19_development_schedule()
% S19_DEVELOPMENT_SCHEDULE - Development Schedule Implementation for Eagle West Field
% Requires: MRST
%
% Implements 6-Phase Development Program over 10 years (3,650 days):
% - Phase 1 (Day 1-365): 1 producer (EW-001)
% - Phase 2 (Day 366-730): 2 producers + 1 injector  
% - Phase 3 (Day 731-1095): 4 producers + 2 injectors
% - Phase 4 (Day 1096-1825): 7 producers + 3 injectors
% - Phase 5 (Day 1826-2920): 9 producers + 4 injectors
% - Phase 6 (Day 2921-3650): 10 producers + 5 injectors
% Well startup schedules with drilling dates
% MRST schedule structure for simulation
%
% OUTPUTS:
%   schedule_results - Structure with complete development schedule
%
% Author: Claude Code AI System
% Date: August 8, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S19', 'Development Schedule Implementation');
    
    total_start_time = tic;
    schedule_results = initialize_schedule_structure();
    
    % Initialize key fields early for export functions
    schedule_results.total_duration_days = 3650;
    schedule_results.total_phases = 6;
    schedule_results.total_wells = 15;
    
    try
        % ----------------------------------------
        % Step 1 - Load Production Controls Data
        % ----------------------------------------
        step_start = tic;
        [control_data, config] = step_1_load_control_data();
        schedule_results.control_data = control_data;
        schedule_results.config = config;
        print_step_result(1, 'Load Production Controls Data', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Define Development Phases
        % ----------------------------------------
        step_start = tic;
        development_phases = step_2_define_development_phases(config);
        schedule_results.development_phases = development_phases;
        print_step_result(2, 'Define Development Phases', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Create Well Startup Schedules
        % ----------------------------------------
        step_start = tic;
        well_startup_schedule = step_3_create_well_startup_schedules(development_phases, config);
        schedule_results.well_startup_schedule = well_startup_schedule;
        print_step_result(3, 'Create Well Startup Schedules', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Generate MRST Schedule Structure
        % ----------------------------------------
        step_start = tic;
        mrst_schedule = step_4_generate_mrst_schedule(schedule_results, control_data);
        schedule_results.mrst_schedule = mrst_schedule;
        print_step_result(4, 'Generate MRST Schedule Structure', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Calculate Timeline Milestones
        % ----------------------------------------
        step_start = tic;
        timeline_milestones = step_5_calculate_timeline_milestones(schedule_results);
        schedule_results.timeline_milestones = timeline_milestones;
        print_step_result(5, 'Calculate Timeline Milestones', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Development Schedule
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_development_schedule(schedule_results);
        schedule_results.export_path = export_path;
        print_step_result(6, 'Export Development Schedule', 'success', toc(step_start));
        
        schedule_results.status = 'success';
        schedule_results.total_phases = length(development_phases);
        schedule_results.total_duration_days = 3650;
        schedule_results.total_wells = 15;
        schedule_results.creation_time = datestr(now);
        
        print_step_footer('S19', sprintf('Development Schedule Created (6 phases, %d wells)', ...
            schedule_results.total_wells), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Development Schedule', ME.message);
        schedule_results.status = 'failed';
        schedule_results.error_message = ME.message;
        error('Development schedule creation failed: %s', ME.message);
    end

end

function schedule_results = initialize_schedule_structure()
% Initialize development schedule results structure
    schedule_results = struct();
    schedule_results.status = 'initializing';
    schedule_results.development_phases = [];
    schedule_results.well_startup_schedule = [];
    schedule_results.mrst_schedule = [];
    schedule_results.timeline_milestones = [];
end

function [control_data, config] = step_1_load_control_data()
% Step 1 - Load production controls and configuration data
    script_dir = fileparts(mfilename('fullpath'));

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 1.1 - Load production controls data __________________
    controls_file = fullfile(data_dir, 'production_controls.mat');
    if exist(controls_file, 'file')
        load(controls_file, 'control_results');
        control_data = control_results;
        fprintf('Loaded production controls: %d producers + %d injectors\n', ...
            length(control_data.producer_controls), length(control_data.injector_controls));
    else
        error('Production controls file not found. Run s18_production_controls.m first.');
    end
    
    % Substep 1.2 - Load wells configuration _______________________
    config_path = fullfile(script_path, 'config', 'wells_config.yaml');
    if exist(config_path, 'file')
        addpath(fullfile(script_dir, 'utils'));
        config = read_yaml_config(config_path);
        fprintf('Loaded wells configuration\n');
    else
        error('Wells configuration not found: %s', config_path);
    end

end

function development_phases = step_2_define_development_phases(config)
% Step 2 - Define the 6 development phases with canonical data

    fprintf('\n Development Phase Definition:\n');
    fprintf(' ───────────────────────────────────────────────────────────────────\n');
    
    development_phases = [];
    phases_config = config.wells_system.development_phases;
    phase_names = fieldnames(phases_config);
    
    % Substep 2.1 - Process each development phase _________________
    for i = 1:length(phase_names)
        phase_name = phase_names{i};
        phase_config = phases_config.(phase_name);
        
        dp = struct();
        dp.phase_number = i;
        dp.phase_name = phase_name;
        dp.start_day = phase_config.timeline_days(1);
        dp.end_day = phase_config.timeline_days(2);
        dp.duration_days = dp.end_day - dp.start_day + 1;
        dp.duration_years = phase_config.duration_years;
        
        % Substep 2.2 - Well additions for this phase _______________
        dp.wells_added = phase_config.wells_added;
        dp.total_active_wells = phase_config.total_active_wells;
        dp.wells_p_i = phase_config.wells_p_i;
        
        % Substep 2.3 - Production targets ___________________________
        dp.target_oil_rate_stb_day = phase_config.target_oil_rate_stb_day;
        dp.expected_oil_rate_stb_day = phase_config.expected_oil_rate_stb_day;
        dp.water_cut_percent = phase_config.water_cut_percent;
        dp.gor_scf_stb = phase_config.gor_scf_stb;
        
        % Substep 2.4 - Injection targets ____________________________
        if isfield(phase_config, 'injection_rate_bwpd')
            dp.injection_rate_bwpd = phase_config.injection_rate_bwpd;
            dp.vrr_target = phase_config.vrr_target;
        else
            dp.injection_rate_bwpd = 0;
            dp.vrr_target = 0;
        end
        
        % Substep 2.5 - Calculate active wells by type _______________
        dp.active_producers = {};
        dp.active_injectors = {};
        
        % Add wells from all phases up to current phase
        for j = 1:i
            prev_phase = phases_config.(phase_names{j});
            if isfield(prev_phase, 'wells_added')
                for k = 1:length(prev_phase.wells_added)
                    well_name = prev_phase.wells_added{k};
                    if ~isempty(strfind(well_name, 'EW-'))
                        dp.active_producers{end+1} = well_name;
                    elseif ~isempty(strfind(well_name, 'IW-'))
                        dp.active_injectors{end+1} = well_name;
                    end
                end
            end
        end
        
        dp.num_producers = length(dp.active_producers);
        dp.num_injectors = length(dp.active_injectors);
        
        development_phases = [development_phases; dp];
        
        fprintf('   Phase %d │ Days %4d-%4d │ %2d wells │ %5d STB/d │ %5d BWD │ VRR: %.2f\n', ...
            dp.phase_number, dp.start_day, dp.end_day, dp.total_active_wells, ...
            dp.target_oil_rate_stb_day, dp.injection_rate_bwpd, dp.vrr_target);
    end
    
    fprintf(' ───────────────────────────────────────────────────────────────────\n');

end

function well_startup_schedule = step_3_create_well_startup_schedules(development_phases, config)
% Step 3 - Create detailed well startup schedules with drilling dates

    fprintf('\n Well Startup Schedule:\n');
    fprintf(' ───────────────────────────────────────────────────────────────────\n');
    
    well_startup_schedule = [];
    producers_config = config.wells_system.producer_wells;
    injectors_config = config.wells_system.injector_wells;
    
    % Substep 3.1 - Process producer wells _________________________
    producer_names = fieldnames(producers_config);
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_config = producers_config.(well_name);
        
        ws = struct();
        ws.well_name = well_name;
        ws.well_type = 'producer';
        ws.well_configuration = well_config.well_type;
        ws.phase = well_config.phase;
        ws.drill_date_day = well_config.drill_date_day;
        
        % Substep 3.2 - Determine startup day ________________________
        % Find the phase this well belongs to
        phase_info = development_phases(ws.phase);
        ws.startup_day = phase_info.start_day;
        ws.phase_start_day = phase_info.start_day;
        ws.phase_end_day = phase_info.end_day;
        
        % Substep 3.3 - Calculate drilling timeline __________________
        ws.drilling_duration_days = 45;  % Standard drilling duration
        if strcmp(well_config.well_type, 'horizontal')
            ws.drilling_duration_days = 65;  % Extended for horizontal
        elseif strcmp(well_config.well_type, 'multi-lateral')
            ws.drilling_duration_days = 85;  % Extended for multi-lateral
        end
        
        ws.completion_duration_days = 15;  % Standard completion
        ws.total_well_time_days = ws.drilling_duration_days + ws.completion_duration_days;
        
        % Substep 3.4 - Set production parameters ____________________
        ws.target_oil_rate_stb_day = well_config.target_oil_rate_stb_day;
        ws.min_bhp_psi = well_config.min_bhp_psi;
        ws.max_water_cut = well_config.max_water_cut;
        
        % Initialize injector fields with defaults for consistency
        ws.target_injection_rate_bbl_day = 0;
        ws.max_bhp_psi = 0;
        
        well_startup_schedule = [well_startup_schedule; ws];
        
        fprintf('   %-8s │ %8s │ Drill: Day %3d │ Start: Day %4d │ %4d STB/d\n', ...
            ws.well_name, ws.well_configuration, ws.drill_date_day, ws.startup_day, ws.target_oil_rate_stb_day);
    end
    
    % Substep 3.5 - Process injector wells _________________________
    injector_names = fieldnames(injectors_config);
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_config = injectors_config.(well_name);
        
        ws = struct();
        ws.well_name = well_name;
        ws.well_type = 'injector';
        ws.well_configuration = well_config.well_type;
        ws.phase = well_config.phase;
        ws.drill_date_day = well_config.drill_date_day;
        
        % Find the phase this well belongs to
        phase_info = development_phases(ws.phase);
        ws.startup_day = phase_info.start_day;
        ws.phase_start_day = phase_info.start_day;
        ws.phase_end_day = phase_info.end_day;
        
        % Calculate drilling timeline
        ws.drilling_duration_days = 40;  % Standard drilling duration
        if strcmp(well_config.well_type, 'horizontal')
            ws.drilling_duration_days = 60;
        elseif strcmp(well_config.well_type, 'multi-lateral')
            ws.drilling_duration_days = 80;
        end
        
        ws.completion_duration_days = 12;  % Injector completion
        ws.total_well_time_days = ws.drilling_duration_days + ws.completion_duration_days;
        
        % Set injection parameters
        ws.target_injection_rate_bbl_day = well_config.target_injection_rate_bbl_day;
        ws.max_bhp_psi = well_config.max_bhp_psi;
        
        % Initialize producer fields with defaults for consistency
        ws.target_oil_rate_stb_day = 0;
        ws.min_bhp_psi = 0;
        ws.max_water_cut = 0;
        
        well_startup_schedule = [well_startup_schedule; ws];
        
        fprintf('   %-8s │ %8s │ Drill: Day %3d │ Start: Day %4d │ %4d BWD\n', ...
            ws.well_name, ws.well_configuration, ws.drill_date_day, ws.startup_day, ws.target_injection_rate_bbl_day);
    end
    
    fprintf(' ───────────────────────────────────────────────────────────────────\n');

end

function mrst_schedule = step_4_generate_mrst_schedule(schedule_results, control_data)
% Step 4 - Generate MRST simulation schedule structure

    fprintf('\n MRST Schedule Structure Generation:\n');
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    
    development_phases = schedule_results.development_phases;
    
    % Substep 4.1 - Initialize MRST schedule structure _____________
    mrst_schedule = struct();
    mrst_schedule.step = [];
    mrst_schedule.control = [];
    
    total_steps = 0;
    current_day = 1;
    
    % Substep 4.2 - Create schedule steps for each phase ___________
    for i = 1:length(development_phases)
        phase = development_phases(i);
        
        % Calculate timesteps for this phase
        phase_duration = phase.duration_days;
        
        % Substep 4.3 - Generate timesteps for phase _________________
        if phase_duration <= 365
            % Short phases: monthly timesteps
            timestep_days = 30;
            num_steps = ceil(phase_duration / timestep_days);
        elseif phase_duration <= 1095
            % Medium phases: bi-monthly timesteps
            timestep_days = 60;
            num_steps = ceil(phase_duration / timestep_days);
        else
            % Long phases: quarterly timesteps
            timestep_days = 90;
            num_steps = ceil(phase_duration / timestep_days);
        end
        
        % Substep 4.4 - Create timestep structure ___________________
        for j = 1:num_steps
            step = struct();
            
            if j < num_steps
                step.val = timestep_days * 24 * 3600;  % Convert days to seconds
                step.days = timestep_days;
            else
                % Last step in phase - adjust for exact phase end
                remaining_days = phase.end_day - current_day + 1;
                step.val = remaining_days * 24 * 3600;
                step.days = remaining_days;
            end
            
            step.phase_number = i;
            step.phase_name = phase.phase_name;
            step.step_number = total_steps + j;
            step.current_day = current_day;
            
            mrst_schedule.step = [mrst_schedule.step; step];
            current_day = current_day + step.days;
        end
        
        % Substep 4.5 - Create control structure for phase ___________
        control = struct();
        control.phase_number = i;
        control.phase_name = phase.phase_name;
        control.active_producers = phase.active_producers;
        control.active_injectors = phase.active_injectors;
        
        % Set production targets
        control.field_oil_target_stb_day = phase.target_oil_rate_stb_day;
        control.field_water_injection_bwpd = phase.injection_rate_bwpd;
        control.voidage_replacement_ratio = phase.vrr_target;
        
        % Well-level controls
        control.producer_controls = extract_producer_controls(phase, control_data);
        control.injector_controls = extract_injector_controls(phase, control_data);
        
        mrst_schedule.control = [mrst_schedule.control; control];
        
        total_steps = total_steps + num_steps;
        
        fprintf('   Phase %d │ %-10s │ %3d steps │ %2d days/step │ %2d wells\n', ...
            i, phase.phase_name, num_steps, timestep_days, phase.total_active_wells);
    end
    
    % Substep 4.6 - Set schedule metadata __________________________
    mrst_schedule.total_steps = total_steps;
    mrst_schedule.total_duration_days = 3650;
    mrst_schedule.total_duration_seconds = 3650 * 24 * 3600;
    mrst_schedule.num_phases = length(development_phases);
    
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    fprintf('   Total Schedule: %d timesteps over %d days\n', total_steps, 3650);

end

function producer_controls = extract_producer_controls(phase, control_data)
% Extract producer controls for active wells in this phase
    producer_controls = [];
    
    for i = 1:length(phase.active_producers)
        well_name = phase.active_producers{i};
        
        % Find well in control data
        for j = 1:length(control_data.producer_controls)
            if strcmp(control_data.producer_controls(j).name, well_name)
                pc = control_data.producer_controls(j);
                
                well_control = struct();
                well_control.name = pc.name;
                well_control.type = 'producer';
                well_control.target_oil_rate_m3_s = pc.target_oil_rate_m3_day / (24 * 3600);
                well_control.min_bhp_pa = pc.min_bhp_pa;
                well_control.control_mode = 'rate';  % Start with rate control
                
                producer_controls = [producer_controls; well_control];
                break;
            end
        end
    end
end

function injector_controls = extract_injector_controls(phase, control_data)
% Extract injector controls for active wells in this phase
    injector_controls = [];
    
    for i = 1:length(phase.active_injectors)
        well_name = phase.active_injectors{i};
        
        % Find well in control data
        for j = 1:length(control_data.injector_controls)
            if strcmp(control_data.injector_controls(j).name, well_name)
                ic = control_data.injector_controls(j);
                
                well_control = struct();
                well_control.name = ic.name;
                well_control.type = 'injector';
                well_control.target_rate_m3_s = ic.target_injection_rate_m3_day / (24 * 3600);
                well_control.max_bhp_pa = ic.max_bhp_pa;
                well_control.control_mode = 'rate';  % Start with rate control
                
                injector_controls = [injector_controls; well_control];
                break;
            end
        end
    end
end

function timeline_milestones = step_5_calculate_timeline_milestones(schedule_results)
% Step 5 - Calculate key timeline milestones and decision points

    fprintf('\n Timeline Milestones:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    timeline_milestones = [];
    development_phases = schedule_results.development_phases;
    well_startup = schedule_results.well_startup_schedule;
    
    % Substep 5.1 - Phase transition milestones ____________________
    for i = 1:length(development_phases)
        phase = development_phases(i);
        
        tm = struct();
        tm.milestone_type = 'phase_start';
        tm.day = phase.start_day;
        tm.phase = i;
        tm.description = sprintf('Phase %d Start: %s', i, phase.phase_name);
        tm.target_oil_rate = phase.target_oil_rate_stb_day;
        tm.active_wells = phase.total_active_wells;
        % Initialize other fields for consistency
        tm.well_name = '';
        tm.drilling_duration = 0;
        tm.target_rate = 0;
        tm.year = tm.day / 365;
        
        timeline_milestones = [timeline_milestones; tm];
        
        % Phase end milestone
        tm_end = struct();
        tm_end.milestone_type = 'phase_end';
        tm_end.day = phase.end_day;
        tm_end.phase = i;
        tm_end.description = sprintf('Phase %d End: %s', i, phase.phase_name);
        tm_end.target_oil_rate = phase.target_oil_rate_stb_day;
        tm_end.active_wells = phase.total_active_wells;
        % Initialize other fields for consistency
        tm_end.well_name = '';
        tm_end.drilling_duration = 0;
        tm_end.target_rate = 0;
        tm_end.year = tm_end.day / 365;
        
        timeline_milestones = [timeline_milestones; tm_end];
    end
    
    % Substep 5.2 - Well drilling milestones _______________________
    for i = 1:length(well_startup)
        well = well_startup(i);
        
        tm_drill = struct();
        tm_drill.milestone_type = 'well_drilling';
        tm_drill.day = well.drill_date_day;
        tm_drill.well_name = well.well_name;
        tm_drill.description = sprintf('Start drilling %s (%s)', well.well_name, well.well_configuration);
        tm_drill.drilling_duration = well.drilling_duration_days;
        % Initialize other fields for consistency
        tm_drill.phase = 0;
        tm_drill.target_oil_rate = 0;
        tm_drill.active_wells = 0;
        tm_drill.target_rate = 0;
        tm_drill.year = tm_drill.day / 365;
        
        timeline_milestones = [timeline_milestones; tm_drill];
        
        % Well startup milestone
        tm_startup = struct();
        tm_startup.milestone_type = 'well_startup';
        tm_startup.day = well.startup_day;
        tm_startup.well_name = well.well_name;
        tm_startup.description = sprintf('Startup %s', well.well_name);
        if strcmp(well.well_type, 'producer')
            tm_startup.target_rate = well.target_oil_rate_stb_day;
        else
            tm_startup.target_rate = well.target_injection_rate_bbl_day;
        end
        % Initialize other fields for consistency
        tm_startup.phase = 0;
        tm_startup.target_oil_rate = 0;
        tm_startup.active_wells = 0;
        tm_startup.drilling_duration = 0;
        tm_startup.year = tm_startup.day / 365;
        
        timeline_milestones = [timeline_milestones; tm_startup];
    end
    
    % Substep 5.3 - Sort milestones by day _________________________
    [~, sort_idx] = sort([timeline_milestones.day]);
    timeline_milestones = timeline_milestones(sort_idx);
    
    % Substep 5.4 - Add production milestones ______________________
    key_milestones = [
        struct('day', 365, 'type', 'production', 'desc', 'First year production target'),
        struct('day', 1095, 'type', 'production', 'desc', 'Multi-well pattern established'),
        struct('day', 2190, 'type', 'production', 'desc', 'Waterflood optimization'),
        struct('day', 2920, 'type', 'production', 'desc', 'Field expansion complete'),
        struct('day', 3650, 'type', 'production', 'desc', 'Peak production plateau')
    ];
    
    for i = 1:length(key_milestones)
        km = key_milestones(i);
        
        tm_key = struct();
        tm_key.milestone_type = km.type;
        tm_key.day = km.day;
        tm_key.description = km.desc;
        tm_key.year = km.day / 365;
        % Initialize other fields for consistency
        tm_key.phase = 0;
        tm_key.target_oil_rate = 0;
        tm_key.active_wells = 0;
        tm_key.well_name = '';
        tm_key.drilling_duration = 0;
        tm_key.target_rate = 0;
        
        timeline_milestones = [timeline_milestones; tm_key];
    end
    
    % Re-sort all milestones
    [~, sort_idx] = sort([timeline_milestones.day]);
    timeline_milestones = timeline_milestones(sort_idx);
    
    fprintf('   Total Milestones: %d over 10-year development\n', length(timeline_milestones));
    fprintf('   Phase Transitions: %d\n', sum(strcmp({timeline_milestones.milestone_type}, 'phase_start')));
    fprintf('   Well Startups: %d\n', sum(strcmp({timeline_milestones.milestone_type}, 'well_startup')));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_path = step_6_export_development_schedule(schedule_results)
% Step 6 - Export development schedule data

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save MATLAB structure __________________________
    export_path = fullfile(data_dir, 'development_schedule.mat');
    save(export_path, 'schedule_results');
    
    % Substep 6.2 - Create schedule summary ________________________
    summary_file = fullfile(data_dir, 'development_schedule_summary.txt');
    write_schedule_summary_file(summary_file, schedule_results);
    
    % Substep 6.3 - Create milestones table ________________________
    milestones_file = fullfile(data_dir, 'development_milestones.txt');
    write_milestones_file(milestones_file, schedule_results);
    
    % Substep 6.4 - Create MRST schedule file ______________________
    mrst_file = fullfile(data_dir, 'mrst_simulation_schedule.mat');
    mrst_schedule = schedule_results.mrst_schedule;
    save(mrst_file, 'mrst_schedule');
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Milestones: %s\n', milestones_file);
    fprintf('   MRST Schedule: %s\n', mrst_file);

end

function write_schedule_summary_file(filename, schedule_results)
% Write development schedule summary to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Development Schedule Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '=============================================\n\n');
        
        % Overall development summary
        fprintf(fid, 'DEVELOPMENT OVERVIEW:\n');
        fprintf(fid, '  Total Duration: %d days (10 years)\n', schedule_results.total_duration_days);
        fprintf(fid, '  Development Phases: %d\n', schedule_results.total_phases);
        fprintf(fid, '  Total Wells: %d\n', schedule_results.total_wells);
        fprintf(fid, '  Peak Production Target: 18,500 STB/day\n');
        fprintf(fid, '  MRST Timesteps: %d\n', schedule_results.mrst_schedule.total_steps);
        fprintf(fid, '\n');
        
        % Phase-by-phase summary
        fprintf(fid, 'DEVELOPMENT PHASES:\n');
        fprintf(fid, '%-8s %-12s %-12s %-8s %-8s %-8s %-6s\n', ...
            'Phase', 'Name', 'Timeline', 'Wells', 'Oil_STB', 'Inj_BWD', 'VRR');
        fprintf(fid, '%s\n', repmat('-', 1, 75));
        
        for i = 1:length(schedule_results.development_phases)
            phase = schedule_results.development_phases(i);
            timeline_str = sprintf('D%d-%d', phase.start_day, phase.end_day);
            
            fprintf(fid, '%-8d %-12s %-12s %-8d %-8d %-8d %-6.2f\n', ...
                phase.phase_number, phase.phase_name, timeline_str, ...
                phase.total_active_wells, phase.target_oil_rate_stb_day, ...
                phase.injection_rate_bwpd, phase.vrr_target);
        end
        
        fprintf(fid, '\n');
        
        % Well startup schedule
        fprintf(fid, 'WELL STARTUP SCHEDULE:\n');
        fprintf(fid, '%-8s %-10s %-6s %-10s %-10s %-8s\n', ...
            'Well', 'Type', 'Phase', 'Drill_Day', 'Start_Day', 'Target');
        fprintf(fid, '%s\n', repmat('-', 1, 65));
        
        for i = 1:length(schedule_results.well_startup_schedule)
            well = schedule_results.well_startup_schedule(i);
            
            if strcmp(well.well_type, 'producer')
                target_str = sprintf('%d STB', well.target_oil_rate_stb_day);
            else
                target_str = sprintf('%d BWD', well.target_injection_rate_bbl_day);
            end
            
            fprintf(fid, '%-8s %-10s %-6d %-10d %-10d %-8s\n', ...
                well.well_name, well.well_configuration, well.phase, ...
                well.drill_date_day, well.startup_day, target_str);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing schedule summary: %s', ME.message);
    end

end

function write_milestones_file(filename, schedule_results)
% Write timeline milestones to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Development Timeline Milestones\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '================================================\n\n');
        
        milestones = schedule_results.timeline_milestones;
        
        fprintf(fid, '%-6s %-8s %-15s %-50s\n', 'Day', 'Year', 'Type', 'Description');
        fprintf(fid, '%s\n', repmat('-', 1, 85));
        
        for i = 1:length(milestones)
            milestone = milestones(i);
            year_str = sprintf('%.1f', milestone.day / 365.25);
            
            fprintf(fid, '%-6d %-8s %-15s %-50s\n', ...
                milestone.day, year_str, milestone.milestone_type, milestone.description);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing milestones file: %s', ME.message);
    end

end


% Main execution when called as script
if ~nargout
    schedule_results = s19_development_schedule();
end