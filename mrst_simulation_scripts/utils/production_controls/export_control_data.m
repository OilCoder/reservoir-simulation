function export_path = export_control_data(control_results)
% EXPORT_CONTROL_DATA - Export production controls data
%
% INPUTS:
%   control_results - Complete control results structure
%
% OUTPUTS:
%   export_path - Path to exported canonical data file
%
% DATA AUTHORITY: Uses canonical MRST data directory structure
% KISS PRINCIPLE: Single responsibility - only data export

    % WARNING SUPPRESSION: Clean output for utility functions
    warning('off', 'all');
    
    % Canon-First: Use canonical MRST data directory
    data_dir = '/workspace/data/mrst';
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save to canonical MRST structure
    canonical_file = fullfile(data_dir, 'schedule.mat');
    data_struct = create_canonical_data_structure(control_results);
    save(canonical_file, 'data_struct');
    export_path = canonical_file;
    
    % Create additional export files
    create_summary_files(data_dir, control_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', fullfile(data_dir, 'production_controls_summary.txt'));
    fprintf('   Schedules: %s\n', fullfile(data_dir, 'phase_schedules.txt'));

end

function data_struct = create_canonical_data_structure(control_results)
% CREATE_CANONICAL_DATA_STRUCTURE - Create canonical data structure
% KISS PRINCIPLE: Single responsibility helper function

    data_struct = struct();
    data_struct.controls.producers = control_results.producer_controls;
    data_struct.controls.injectors = control_results.injector_controls;
    
    % Extract BHP limits and rate targets for quick access
    [bhp_limits, rate_targets] = extract_control_parameters(control_results);
    data_struct.controls.bhp_limits = bhp_limits;
    data_struct.controls.rate_targets = rate_targets;
    
    % Metadata
    data_struct.created_by = {'s17'};
    data_struct.timestamp = datestr(now);

end

function [bhp_limits, rate_targets] = extract_control_parameters(control_results)
% EXTRACT_CONTROL_PARAMETERS - Extract key control parameters
% KISS PRINCIPLE: Single responsibility helper function

    bhp_limits = struct();
    rate_targets = struct();
    
    % Extract producer parameters
    for i = 1:length(control_results.producer_controls)
        pc = control_results.producer_controls(i);
        bhp_limits.(pc.name) = pc.min_bhp_psi;
        rate_targets.(pc.name) = pc.target_oil_rate_stb_day;
    end
    
    % Extract injector parameters
    for i = 1:length(control_results.injector_controls)
        ic = control_results.injector_controls(i);
        bhp_limits.(ic.name) = ic.max_bhp_psi;
        rate_targets.(ic.name) = ic.target_injection_rate_bbl_day;
    end

end

function create_summary_files(data_dir, control_results)
% CREATE_SUMMARY_FILES - Create summary and schedule files
% KISS PRINCIPLE: Single responsibility helper function

    % Create controls summary
    summary_file = fullfile(data_dir, 'production_controls_summary.txt');
    write_controls_summary_file(summary_file, control_results);
    
    % Create phase schedule table
    schedule_file = fullfile(data_dir, 'phase_schedules.txt');
    write_phase_schedules_file(schedule_file, control_results);

end

function write_controls_summary_file(filename, control_results)
% WRITE_CONTROLS_SUMMARY_FILE - Write production controls summary
% KISS PRINCIPLE: Single responsibility helper function under 40 lines

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        write_summary_header(fid);
        write_producer_summary(fid, control_results.producer_controls);
        write_injector_summary(fid, control_results.injector_controls);
        write_switching_summary(fid, control_results.switching_logic);
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing controls summary: %s', ME.message);
    end

end

function write_summary_header(fid)
% WRITE_SUMMARY_HEADER - Write file header
    fprintf(fid, 'Eagle West Field - Production Controls Summary\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, '==============================================\n\n');
end

function write_producer_summary(fid, producer_controls)
% WRITE_PRODUCER_SUMMARY - Write producer controls section
    fprintf(fid, 'PRODUCER CONTROLS:\n');
    fprintf(fid, '%-8s %-10s %-8s %-8s %-8s %-10s\n', ...
        'Well', 'Type', 'Oil_STB', 'Min_BHP', 'Max_WC', 'ESP');
    fprintf(fid, '%s\n', repmat('-', 1, 65));
    
    for i = 1:length(producer_controls)
        pc = producer_controls(i);
        fprintf(fid, '%-8s %-10s %-8d %-8d %-7.0f%% %-10s\n', ...
            pc.name, pc.well_type, pc.target_oil_rate_stb_day, pc.min_bhp_psi, ...
            pc.max_water_cut*100, pc.esp_system.type);
    end
    fprintf(fid, '\n');
end

function write_injector_summary(fid, injector_controls)
% WRITE_INJECTOR_SUMMARY - Write injector controls section
    fprintf(fid, 'INJECTOR CONTROLS:\n');
    fprintf(fid, '%-8s %-10s %-8s %-8s %-15s\n', ...
        'Well', 'Type', 'Inj_BWD', 'Max_BHP', 'Fluid');
    fprintf(fid, '%s\n', repmat('-', 1, 55));
    
    for i = 1:length(injector_controls)
        ic = injector_controls(i);
        fprintf(fid, '%-8s %-10s %-8d %-8d %-15s\n', ...
            ic.name, ic.well_type, ic.target_injection_rate_bbl_day, ...
            ic.max_bhp_psi, ic.injection_fluid);
    end
    fprintf(fid, '\n');
end

function write_switching_summary(fid, switching_logic)
% WRITE_SWITCHING_SUMMARY - Write control switching section
    fprintf(fid, 'CONTROL SWITCHING:\n');
    if switching_logic.enabled
        enabled_text = 'Yes';
    else
        enabled_text = 'No';
    end
    fprintf(fid, '  Switching Enabled: %s\n', enabled_text);
    fprintf(fid, '  Check Frequency: %d day(s)\n', switching_logic.check_frequency_days);
    fprintf(fid, '  Producer Wells: %d with switching logic\n', ...
        length(fieldnames(switching_logic.producers)));
    fprintf(fid, '  Injector Wells: %d with switching logic\n', ...
        length(fieldnames(switching_logic.injectors)));
end

function write_phase_schedules_file(filename, control_results)
% WRITE_PHASE_SCHEDULES_FILE - Write phase development schedules
% KISS PRINCIPLE: Single responsibility helper function under 40 lines

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        write_schedules_header(fid);
        write_phase_details(fid, control_results.phase_schedules);
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing phase schedules: %s', ME.message);
    end

end

function write_schedules_header(fid)
% WRITE_SCHEDULES_HEADER - Write schedules file header
    fprintf(fid, 'Eagle West Field - Phase Development Schedules\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, '==============================================\n\n');
end

function write_phase_details(fid, phase_schedules)
% WRITE_PHASE_DETAILS - Write individual phase details
    phase_names = fieldnames(phase_schedules);
    
    for i = 1:length(phase_names)
        phase_name = phase_names{i};
        ps = phase_schedules.(phase_name);
        
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
end