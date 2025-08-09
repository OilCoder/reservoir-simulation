function control_results = s18_production_controls()
% S18_PRODUCTION_CONTROLS - Production Controls for Eagle West Field
% Requires: MRST
%
% Implements production controls with:
% - Rate controls with BHP constraints
% - Min BHP: 1350-1650 psi (producers)
% - Max BHP: 3100-3600 psi (injectors)  
% - Production targets per well from documentation
% - Control switching logic
%
% OUTPUTS:
%   control_results - Structure with production control setup
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S18', 'Production Controls Setup');
    
    total_start_time = tic;
    control_results = initialize_control_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Well Completions Data
        % ----------------------------------------
        step_start = tic;
        [completion_data, config] = step_1_load_completion_data();
        control_results.completion_data = completion_data;
        control_results.config = config;
        print_step_result(1, 'Load Well Completions Data', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Design Producer Controls
        % ----------------------------------------
        step_start = tic;
        producer_controls = step_2_design_producer_controls(completion_data, config);
        control_results.producer_controls = producer_controls;
        print_step_result(2, 'Design Producer Controls', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Design Injector Controls
        % ----------------------------------------
        step_start = tic;
        injector_controls = step_3_design_injector_controls(completion_data, config);
        control_results.injector_controls = injector_controls;
        print_step_result(3, 'Design Injector Controls', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Setup Control Switching Logic
        % ----------------------------------------
        step_start = tic;
        switching_logic = step_4_setup_switching_logic(control_results);
        control_results.switching_logic = switching_logic;
        print_step_result(4, 'Setup Control Switching Logic', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Create Phase-Based Schedules
        % ----------------------------------------
        step_start = tic;
        phase_schedules = step_5_create_phase_schedules(control_results, config);
        control_results.phase_schedules = phase_schedules;
        print_step_result(5, 'Create Phase-Based Schedules', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Control Data
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_control_data(control_results);
        control_results.export_path = export_path;
        print_step_result(6, 'Export Control Data', 'success', toc(step_start));
        
        control_results.status = 'success';
        control_results.total_producers = length(control_results.producer_controls);
        control_results.total_injectors = length(control_results.injector_controls);
        control_results.creation_time = datestr(now);
        
        print_step_footer('S18', sprintf('Production Controls Setup (%d producers + %d injectors)', ...
            control_results.total_producers, control_results.total_injectors), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Production Controls', ME.message);
        control_results.status = 'failed';
        control_results.error_message = ME.message;
        error('Production controls setup failed: %s', ME.message);
    end

end

function control_results = initialize_control_structure()
% Initialize production controls results structure
    control_results = struct();
    control_results.status = 'initializing';
    control_results.producer_controls = [];
    control_results.injector_controls = [];
    control_results.switching_logic = [];
    control_results.phase_schedules = [];
end

function [completion_data, config] = step_1_load_completion_data()
% Step 1 - Load well completion data and configuration

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Load completion data ___________________________
    completion_file = fullfile(data_dir, 'well_completions.mat');
    if exist(completion_file, 'file')
        load(completion_file, 'completion_results');
        completion_data = completion_results;
        fprintf('Loaded completion data: %d wells\n', completion_data.total_wells);
    else
        error('Well completion file not found. Run s17_well_completions.m first.');
    end
    
    % Substep 1.2 - Load wells configuration _______________________
    config_path = fullfile(fileparts(data_dir), 'mrst_simulation_scripts', 'config', 'wells_config.yaml');
    if exist(config_path, 'file')
        config = parse_yaml_file(config_path);
        fprintf('Loaded wells configuration\n');
    else
        error('Wells configuration not found: %s', config_path);
    end

end

function producer_controls = step_2_design_producer_controls(completion_data, config)
% Step 2 - Design control systems for producer wells

    fprintf('\n Producer Control Systems:\n');
    fprintf(' ──────────────────────────────────────────────────────────────────\n');
    
    producer_controls = [];
    
    % Get producer wells from completion data
    all_wells = completion_data.wells_data.producer_wells;
    producers_config = config.wells_system.producer_wells;
    
    % Substep 2.1 - Design controls for each producer ______________
    for i = 1:length(all_wells)
        well = all_wells(i);
        well_config = producers_config.(well.name);
        
        pc = struct();
        pc.name = well.name;
        pc.type = 'producer';
        pc.well_type = well.well_type;
        pc.phase = well.phase;
        
        % Substep 2.2 - Primary control: Oil rate ___________________
        pc.primary_control = 'oil_rate';
        pc.target_oil_rate_stb_day = well_config.target_oil_rate_stb_day;
        pc.target_oil_rate_m3_day = pc.target_oil_rate_stb_day * 0.159;  % Convert STB to m³
        
        % Substep 2.3 - BHP constraint _______________________________
        pc.min_bhp_psi = well_config.min_bhp_psi;
        pc.min_bhp_pa = pc.min_bhp_psi * 6895;  % Convert psi to Pa
        
        % Substep 2.4 - Additional constraints _______________________
        pc.max_water_cut = well_config.max_water_cut;
        pc.max_gor_scf_stb = well_config.max_gor_scf_stb;
        
        % Calculate maximum liquid rate based on water cut limit
        if pc.max_water_cut < 1.0
            pc.max_liquid_rate_stb_day = pc.target_oil_rate_stb_day / (1 - pc.max_water_cut);
        else
            pc.max_liquid_rate_stb_day = pc.target_oil_rate_stb_day * 20;  % Safety factor
        end
        pc.max_liquid_rate_m3_day = pc.max_liquid_rate_stb_day * 0.159;
        
        % Substep 2.5 - Control switching thresholds ________________
        pc.control_switching = struct();
        pc.control_switching.rate_to_bhp_threshold = pc.min_bhp_psi + 50;  % Switch 50 psi above min
        pc.control_switching.bhp_to_rate_threshold = pc.min_bhp_psi + 100;  % Switch back 100 psi above min
        pc.control_switching.water_cut_limit = pc.max_water_cut;
        pc.control_switching.gor_limit = pc.max_gor_scf_stb;
        
        % Substep 2.6 - ESP operating parameters ____________________
        pc.esp_system = struct();
        pc.esp_system.type = well_config.esp_type;
        pc.esp_system.stages = well_config.esp_stages;
        pc.esp_system.hp = well_config.esp_hp;
        pc.esp_system.frequency_hz = 60;  % Standard frequency
        pc.esp_system.efficiency = 0.72;  % Typical ESP efficiency
        
        producer_controls = [producer_controls; pc];
        
        fprintf('   %-8s │ %4d STB/d │ %4d psi │ %2d%% WC │ ESP: %-8s\n', ...
            pc.name, pc.target_oil_rate_stb_day, pc.min_bhp_psi, ...
            round(pc.max_water_cut*100), pc.esp_system.type);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────────\n');

end

function injector_controls = step_3_design_injector_controls(completion_data, config)
% Step 3 - Design control systems for injector wells

    fprintf('\n Injector Control Systems:\n');
    fprintf(' ──────────────────────────────────────────────────────────────────\n');
    
    injector_controls = [];
    
    % Get injector wells from completion data
    all_wells = completion_data.wells_data.injector_wells;
    injectors_config = config.wells_system.injector_wells;
    
    % Substep 3.1 - Design controls for each injector ______________
    for i = 1:length(all_wells)
        well = all_wells(i);
        well_config = injectors_config.(well.name);
        
        ic = struct();
        ic.name = well.name;
        ic.type = 'injector';
        ic.well_type = well.well_type;
        ic.phase = well.phase;
        
        % Substep 3.2 - Primary control: Water injection rate _______
        ic.primary_control = 'water_rate';
        ic.target_injection_rate_bbl_day = well_config.target_injection_rate_bbl_day;
        ic.target_injection_rate_m3_day = ic.target_injection_rate_bbl_day * 0.159;  % Convert BBL to m³
        
        % Substep 3.3 - BHP constraint _______________________________
        ic.max_bhp_psi = well_config.max_bhp_psi;
        ic.max_bhp_pa = ic.max_bhp_psi * 6895;  % Convert psi to Pa
        
        % Substep 3.4 - Injection fluid properties __________________
        ic.injection_fluid = well_config.injection_fluid;
        ic.injection_temperature_f = 90;  % Surface injection temperature
        ic.injection_temperature_k = (ic.injection_temperature_f - 32) * 5/9 + 273.15;  % Convert to Kelvin
        
        % Substep 3.5 - Rate limits and constraints __________________
        ic.min_injection_rate_bbl_day = ic.target_injection_rate_bbl_day * 0.1;  % 10% minimum
        ic.max_injection_rate_bbl_day = ic.target_injection_rate_bbl_day * 1.5;  % 150% maximum
        ic.min_injection_rate_m3_day = ic.min_injection_rate_bbl_day * 0.159;
        ic.max_injection_rate_m3_day = ic.max_injection_rate_bbl_day * 0.159;
        
        % Substep 3.6 - Control switching thresholds ________________
        ic.control_switching = struct();
        ic.control_switching.rate_to_bhp_threshold = ic.max_bhp_psi - 100;  % Switch 100 psi below max
        ic.control_switching.bhp_to_rate_threshold = ic.max_bhp_psi - 200;  % Switch back 200 psi below max
        
        % Substep 3.7 - Water quality specifications _________________
        ic.water_quality = struct();
        ic.water_quality.max_tss_ppm = 5;  % Total suspended solids
        ic.water_quality.max_oil_content_ppm = 30;
        ic.water_quality.max_particle_size_microns = 2;
        ic.water_quality.min_ph = 6.5;
        ic.water_quality.max_ph = 8.5;
        
        % Substep 3.8 - Injection pump specifications _______________
        ic.pump_system = struct();
        ic.pump_system.type = 'centrifugal';
        ic.pump_system.max_pressure_psi = ic.max_bhp_psi + 500;  % Surface pressure + wellhead pressure
        ic.pump_system.efficiency = 0.78;  % Typical injection pump efficiency
        ic.pump_system.vfd_control = true;  % Variable frequency drive
        
        injector_controls = [injector_controls; ic];
        
        fprintf('   %-8s │ %5d BWD │ %4d psi │ %-13s │ Pump: Centrifugal\n', ...
            ic.name, ic.target_injection_rate_bbl_day, ic.max_bhp_psi, ic.injection_fluid);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────────\n');

end

function switching_logic = step_4_setup_switching_logic(control_results)
% Step 4 - Setup control switching logic for all wells

    fprintf('\n Control Switching Logic:\n');
    fprintf(' ─────────────────────────────────────────────────────────────\n');
    
    switching_logic = struct();
    switching_logic.enabled = true;
    switching_logic.check_frequency_days = 1;  % Check daily
    
    % Substep 4.1 - Producer switching logic _______________________
    switching_logic.producers = struct();
    for i = 1:length(control_results.producer_controls)
        pc = control_results.producer_controls(i);
        
        psl = struct();
        psl.name = pc.name;
        psl.current_control = 'rate';  % Start with rate control
        
        % Rate to BHP switching conditions
        psl.rate_to_bhp_conditions = {
            sprintf('BHP < %.1f psi', pc.control_switching.rate_to_bhp_threshold),
            sprintf('Water_Cut > %.1f%%', pc.control_switching.water_cut_limit * 100),
            sprintf('GOR > %.0f SCF/STB', pc.control_switching.gor_limit)
        };
        
        % BHP to rate switching conditions
        psl.bhp_to_rate_conditions = {
            sprintf('BHP > %.1f psi', pc.control_switching.bhp_to_rate_threshold),
            'Water_Cut < 90%',
            sprintf('GOR < %.0f SCF/STB', pc.control_switching.gor_limit * 0.9)
        };
        
        switching_logic.producers.(pc.name) = psl;
    end
    
    % Substep 4.2 - Injector switching logic _______________________
    switching_logic.injectors = struct();
    for i = 1:length(control_results.injector_controls)
        ic = control_results.injector_controls(i);
        
        isl = struct();
        isl.name = ic.name;
        isl.current_control = 'rate';  % Start with rate control
        
        % Rate to BHP switching conditions
        isl.rate_to_bhp_conditions = {
            sprintf('BHP > %.1f psi', ic.control_switching.rate_to_bhp_threshold),
            'Injection rate declining trend'
        };
        
        % BHP to rate switching conditions  
        isl.bhp_to_rate_conditions = {
            sprintf('BHP < %.1f psi', ic.control_switching.bhp_to_rate_threshold),
            'Stable injection performance'
        };
        
        switching_logic.injectors.(ic.name) = isl;
    end
    
    % Substep 4.3 - Field-level switching logic ____________________
    switching_logic.field_level = struct();
    switching_logic.field_level.voidage_replacement_target = [1.1, 1.2];  % Range by phase
    switching_logic.field_level.total_liquid_rate_limit = 55000;  % BBL/day field limit
    switching_logic.field_level.pressure_maintenance_priority = true;
    
    fprintf('   Producer Controls: %d wells with switching logic\n', ...
        length(fieldnames(switching_logic.producers)));
    fprintf('   Injector Controls: %d wells with switching logic\n', ...
        length(fieldnames(switching_logic.injectors)));
    fprintf('   Switching Check Frequency: %d day(s)\n', switching_logic.check_frequency_days);
    fprintf(' ─────────────────────────────────────────────────────────────\n');

end

function phase_schedules = step_5_create_phase_schedules(control_results, config)
% Step 5 - Create phased development schedules

    fprintf('\n Phase-Based Development Schedules:\n');
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    
    phase_schedules = struct();
    development_phases = config.wells_system.development_phases;
    phase_names = fieldnames(development_phases);
    
    % Substep 5.1 - Create schedule for each phase __________________
    for i = 1:length(phase_names)
        phase_name = phase_names{i};
        phase_config = development_phases.(phase_name);
        
        ps = struct();
        ps.phase_name = phase_name;
        ps.phase_number = i;
        ps.timeline_days = phase_config.timeline_days;
        ps.duration_years = phase_config.duration_years;
        ps.wells_added = phase_config.wells_added;
        
        % Substep 5.2 - Determine active wells for this phase ________
        ps.active_producers = {};
        ps.active_injectors = {};
        
        % Add wells from all previous phases plus current phase
        for j = 1:i
            prev_phase = development_phases.(phase_names{j});
            if isfield(prev_phase, 'wells_added')
                for k = 1:length(prev_phase.wells_added)
                    well_name = prev_phase.wells_added{k};
                    if ~isempty(strfind(well_name, 'EW-'))
                        ps.active_producers{end+1} = well_name;
                    elseif ~isempty(strfind(well_name, 'IW-'))
                        ps.active_injectors{end+1} = well_name;
                    end
                end
            end
        end
        
        % Substep 5.3 - Set production targets for phase _____________
        ps.target_oil_rate_stb_day = phase_config.target_oil_rate_stb_day;
        ps.expected_oil_rate_stb_day = phase_config.expected_oil_rate_stb_day;
        ps.water_cut_percent = phase_config.water_cut_percent;
        ps.gor_scf_stb = phase_config.gor_scf_stb;
        
        if isfield(phase_config, 'injection_rate_bwpd')
            ps.injection_rate_bwpd = phase_config.injection_rate_bwpd;
            ps.vrr_target = phase_config.vrr_target;
        else
            ps.injection_rate_bwpd = 0;
            ps.vrr_target = 0;
        end
        
        % Substep 5.4 - Calculate well-level targets _________________
        ps.producer_targets = calculate_producer_targets(ps, control_results.producer_controls);
        ps.injector_targets = calculate_injector_targets(ps, control_results.injector_controls);
        
        phase_schedules.(phase_name) = ps;
        
        fprintf('   %-10s │ Days %4d-%4d │ %2d wells │ %5d STB/d │ %5d BWD\n', ...
            phase_name, ps.timeline_days(1), ps.timeline_days(2), ...
            length(ps.active_producers) + length(ps.active_injectors), ...
            ps.target_oil_rate_stb_day, ps.injection_rate_bwpd);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────\n');

end

function producer_targets = calculate_producer_targets(phase_schedule, producer_controls)
% Calculate individual producer targets for phase
    producer_targets = struct();
    
    total_target = phase_schedule.target_oil_rate_stb_day;
    active_producers = phase_schedule.active_producers;
    
    % Distribute target based on well capacity
    total_capacity = 0;
    for i = 1:length(active_producers)
        well_name = active_producers{i};
        for j = 1:length(producer_controls)
            if strcmp(producer_controls(j).name, well_name)
                total_capacity = total_capacity + producer_controls(j).target_oil_rate_stb_day;
                break;
            end
        end
    end
    
    % Calculate individual targets
    for i = 1:length(active_producers)
        well_name = active_producers{i};
        for j = 1:length(producer_controls)
            if strcmp(producer_controls(j).name, well_name)
                well_capacity = producer_controls(j).target_oil_rate_stb_day;
                if total_capacity > 0
                    target_rate = (well_capacity / total_capacity) * total_target;
                else
                    target_rate = well_capacity;
                end
                producer_targets.(well_name) = round(target_rate);
                break;
            end
        end
    end

end

function injector_targets = calculate_injector_targets(phase_schedule, injector_controls)
% Calculate individual injector targets for phase
    injector_targets = struct();
    
    if phase_schedule.injection_rate_bwpd > 0
        total_target = phase_schedule.injection_rate_bwpd;
        active_injectors = phase_schedule.active_injectors;
        
        % Distribute injection target evenly among active injectors
        if ~isempty(active_injectors)
            target_per_injector = total_target / length(active_injectors);
            for i = 1:length(active_injectors)
                well_name = active_injectors{i};
                injector_targets.(well_name) = round(target_per_injector);
            end
        end
    end

end

function export_path = step_6_export_control_data(control_results)
% Step 6 - Export production controls data

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save MATLAB structure __________________________
    export_path = fullfile(data_dir, 'production_controls.mat');
    save(export_path, 'control_results');
    
    % Substep 6.2 - Create controls summary ________________________
    summary_file = fullfile(data_dir, 'production_controls_summary.txt');
    write_controls_summary_file(summary_file, control_results);
    
    % Substep 6.3 - Create phase schedule table ____________________
    schedule_file = fullfile(data_dir, 'phase_schedules.txt');
    write_phase_schedules_file(schedule_file, control_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Schedules: %s\n', schedule_file);

end

function write_controls_summary_file(filename, control_results)
% Write production controls summary to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Production Controls Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '==============================================\n\n');
        
        % Producer controls summary
        fprintf(fid, 'PRODUCER CONTROLS:\n');
        fprintf(fid, '%-8s %-10s %-8s %-8s %-8s %-10s\n', ...
            'Well', 'Type', 'Oil_STB', 'Min_BHP', 'Max_WC', 'ESP');
        fprintf(fid, '%s\n', repmat('-', 1, 65));
        
        for i = 1:length(control_results.producer_controls)
            pc = control_results.producer_controls(i);
            fprintf(fid, '%-8s %-10s %-8d %-8d %-7.0f%% %-10s\n', ...
                pc.name, pc.well_type, pc.target_oil_rate_stb_day, pc.min_bhp_psi, ...
                pc.max_water_cut*100, pc.esp_system.type);
        end
        
        fprintf(fid, '\n');
        
        % Injector controls summary
        fprintf(fid, 'INJECTOR CONTROLS:\n');
        fprintf(fid, '%-8s %-10s %-8s %-8s %-15s\n', ...
            'Well', 'Type', 'Inj_BWD', 'Max_BHP', 'Fluid');
        fprintf(fid, '%s\n', repmat('-', 1, 55));
        
        for i = 1:length(control_results.injector_controls)
            ic = control_results.injector_controls(i);
            fprintf(fid, '%-8s %-10s %-8d %-8d %-15s\n', ...
                ic.name, ic.well_type, ic.target_injection_rate_bbl_day, ...
                ic.max_bhp_psi, ic.injection_fluid);
        end
        
        fprintf(fid, '\n');
        
        % Control switching summary
        fprintf(fid, 'CONTROL SWITCHING:\n');
        if control_results.switching_logic.enabled
            fprintf(fid, '  Switching Enabled: Yes\n');
        else
            fprintf(fid, '  Switching Enabled: No\n');
        end
        fprintf(fid, '  Check Frequency: %d day(s)\n', ...
            control_results.switching_logic.check_frequency_days);
        fprintf(fid, '  Producer Wells: %d with switching logic\n', ...
            length(fieldnames(control_results.switching_logic.producers)));
        fprintf(fid, '  Injector Wells: %d with switching logic\n', ...
            length(fieldnames(control_results.switching_logic.injectors)));
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing controls summary: %s', ME.message);
    end

end

function write_phase_schedules_file(filename, control_results)
% Write phase development schedules to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Phase Development Schedules\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '==============================================\n\n');
        
        phase_names = fieldnames(control_results.phase_schedules);
        
        for i = 1:length(phase_names)
            phase_name = phase_names{i};
            ps = control_results.phase_schedules.(phase_name);
            
            fprintf(fid, 'PHASE %d - %s:\n', ps.phase_number, upper(phase_name));
            fprintf(fid, '  Timeline: Day %d to %d (%d days)\n', ...
                ps.timeline_days(1), ps.timeline_days(2), ...
                ps.timeline_days(2) - ps.timeline_days(1) + 1);
            fprintf(fid, '  Duration: %.1f year(s)\n', ps.duration_years);
            fprintf(fid, '  Wells Added: %s\n', strjoin(ps.wells_added, ', '));
            fprintf(fid, '  Active Producers: %s\n', strjoin(ps.active_producers, ', '));
            fprintf(fid, '  Active Injectors: %s\n', strjoin(ps.active_injectors, ', '));
            fprintf(fid, '  Target Oil Rate: %d STB/day\n', ps.target_oil_rate_stb_day);
            fprintf(fid, '  Expected Oil Rate: %d STB/day\n', ps.expected_oil_rate_stb_day);
            fprintf(fid, '  Water Cut: %d%%\n', ps.water_cut_percent);
            fprintf(fid, '  GOR: %d SCF/STB\n', ps.gor_scf_stb);
            if ps.injection_rate_bwpd > 0
                fprintf(fid, '  Injection Rate: %d BWD\n', ps.injection_rate_bwpd);
                fprintf(fid, '  VRR Target: %.2f\n', ps.vrr_target);
            end
            fprintf(fid, '\n');
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing phase schedules: %s', ME.message);
    end

end

function data = parse_yaml_file(filename)
% Simple YAML parser for configuration (Octave compatible)

    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open YAML file: %s', filename);
    end
    
    data = struct();
    current_section = '';
    current_well = '';
    current_phase = '';
    
    try
        while ~feof(fid)
            line = strtrim(fgetl(fid));
            
            % Skip empty lines and comments
            if isempty(line) || line(1) == '#'
                continue;
            end
            
            % Parse main sections
            if ~isempty(strfind(line, 'wells_system:'))
                current_section = 'wells_system';
                data.wells_system = struct();
            elseif ~isempty(strfind(line, 'development_phases:'))
                current_section = 'development_phases';
                data.wells_system.development_phases = struct();
            elseif ~isempty(strfind(line, 'producer_wells:'))
                current_section = 'producer_wells';
                data.wells_system.producer_wells = struct();
            elseif ~isempty(strfind(line, 'injector_wells:'))
                current_section = 'injector_wells';
                data.wells_system.injector_wells = struct();
            elseif line(1) ~= ' ' && ~isempty(strfind(line, ':'))
                % Top-level key
                continue;
            elseif strncmp(line, '    ', 4) && ~isempty(strfind(line, ':')) && isempty(strfind(line, '- '))
                % Section items
                colon_pos = strfind(line, ':');
                key = strtrim(line(1:colon_pos-1));
                value = strtrim(line(colon_pos+1:end));
                
                if strcmp(current_section, 'development_phases')
                    current_phase = key;
                    data.wells_system.development_phases.(current_phase) = struct();
                elseif strcmp(current_section, 'producer_wells') || strcmp(current_section, 'injector_wells')
                    if ~isempty(strfind(key, '-')) && length(key) > 6  % Well name
                        current_well = key;
                        if strcmp(current_section, 'producer_wells')
                            data.wells_system.producer_wells.(current_well) = struct();
                        else
                            data.wells_system.injector_wells.(current_well) = struct();
                        end
                    elseif ~isempty(current_well)
                        parsed_value = parse_yaml_value(value);
                        if strcmp(current_section, 'producer_wells')
                            data.wells_system.producer_wells.(current_well).(key) = parsed_value;
                        else
                            data.wells_system.injector_wells.(current_well).(key) = parsed_value;
                        end
                    end
                end
            elseif strncmp(line, '      ', 6) && ~isempty(strfind(line, ':')) && ~isempty(current_phase)
                % Phase properties
                colon_pos = strfind(line, ':');
                key = strtrim(line(1:colon_pos-1));
                value = strtrim(line(colon_pos+1:end));
                parsed_value = parse_yaml_value(value);
                data.wells_system.development_phases.(current_phase).(key) = parsed_value;
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error parsing YAML file: %s', ME.message);
    end

end

function value = parse_yaml_value(str)
% Parse YAML value to appropriate MATLAB type

    str = strtrim(str);
    
    % Remove quotes
    if (str(1) == '"' && str(end) == '"') || (str(1) == '''' && str(end) == '''')
        value = str(2:end-1);
        return;
    end
    
    % Array notation [1, 2, 3] or ["item1", "item2"]
    if str(1) == '[' && str(end) == ']'
        inner = str(2:end-1);
        if ~isempty(strfind(inner, '"'))
            % String array
            parts = strsplit(inner, ',');
            value = {};
            for i = 1:length(parts)
                item = strtrim(parts{i});
                if (item(1) == '"' && item(end) == '"') || (item(1) == '''' && item(end) == '''')
                    value{i} = item(2:end-1);
                else
                    value{i} = item;
                end
            end
        else
            % Numeric array
            parts = strsplit(inner, ',');
            value = [];
            for i = 1:length(parts)
                num = str2double(strtrim(parts{i}));
                if ~isnan(num)
                    value(i) = num;
                end
            end
        end
        return;
    end
    
    % Try to parse as number
    num_value = str2double(str);
    if ~isnan(num_value)
        value = num_value;
        return;
    end
    
    % String value
    value = str;

end

% Main execution when called as script
if ~nargout
    control_results = s18_production_controls();
end