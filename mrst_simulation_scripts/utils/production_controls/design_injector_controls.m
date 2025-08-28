function injector_controls = design_injector_controls(completion_data, config)
% DESIGN_INJECTOR_CONTROLS - Design control systems for injector wells
%
% INPUTS:
%   completion_data - Wells completion data structure
%   config          - Combined configuration structure
%
% OUTPUTS:
%   injector_controls - Array of injector control structures
%
% DATA AUTHORITY: All parameters from config files, no hardcoded values
% KISS PRINCIPLE: Single responsibility - only injector control design

    % WARNING SUPPRESSION: Clean output for utility functions
    warning('off', 'all');

    fprintf('\n Injector Control Systems:\n');
    fprintf(' ──────────────────────────────────────────────────────────────────\n');
    
    injector_controls = [];
    
    % Get configuration parameters (Data Authority Policy)
    conv = config.production_controls.conversion_constants;
    equip = config.production_controls.equipment_defaults;
    switching = config.production_controls.control_switching;
    water_qual = config.production_controls.water_quality_specs;
    rate_const = config.production_controls.rate_constraints;
    pump_sys = config.production_controls.pump_systems;
    
    % Get injector wells from completion data
    all_wells = completion_data.wells_data.injector_wells;
    injectors_config = config.wells_system.injector_wells;
    
    % Design controls for each injector
    for i = 1:length(all_wells)
        well = all_wells{i};
        well_config = get_well_config_by_name(injectors_config, well.name);
        
        ic = create_injector_control_structure(well, well_config, conv, equip, ...
                                             switching, water_qual, rate_const, pump_sys);
        injector_controls = [injector_controls; ic];
        
        fprintf('   %-8s │ %5d BWD │ %4d psi │ %-13s │ Pump: %s\n', ...
            ic.name, ic.target_injection_rate_bbl_day, ic.max_bhp_psi, ...
            ic.injection_fluid, ic.pump_system.type);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────────\n');

end

function ic = create_injector_control_structure(well, well_config, conv, equip, ...
                                              switching, water_qual, rate_const, pump_sys)
% CREATE_INJECTOR_CONTROL_STRUCTURE - Create individual injector control structure
% KISS PRINCIPLE: Single responsibility helper function

    ic = struct();
    ic.name = well.name;
    ic.type = 'injector';
    ic.well_type = well.well_type;
    ic.phase = well.phase;
    
    % Primary control: Water injection rate (Data Authority)
    ic.primary_control = 'water_rate';
    ic.target_injection_rate_bbl_day = well_config.target_injection_rate_bbl_day;
    ic.target_injection_rate_m3_day = ic.target_injection_rate_bbl_day * conv.bbl_to_m3;
    
    % BHP constraint (Data Authority)
    ic.max_bhp_psi = well_config.max_bhp_psi;
    ic.max_bhp_pa = ic.max_bhp_psi * conv.psi_to_pa;
    
    % Injection fluid properties (Data Authority)
    ic.injection_fluid = well_config.injection_fluid;
    ic.injection_temperature_f = equip.injection_temperature_f;
    ic.injection_temperature_k = (ic.injection_temperature_f - conv.f_to_c_offset) * ...
                                conv.f_to_c_multiplier + conv.f_to_k_offset;
    
    % Rate limits and constraints (Data Authority)
    ic.min_injection_rate_bbl_day = ic.target_injection_rate_bbl_day * rate_const.min_injection_rate_factor;
    ic.max_injection_rate_bbl_day = ic.target_injection_rate_bbl_day * rate_const.max_injection_rate_factor;
    ic.min_injection_rate_m3_day = ic.min_injection_rate_bbl_day * conv.bbl_to_m3;
    ic.max_injection_rate_m3_day = ic.max_injection_rate_bbl_day * conv.bbl_to_m3;
    
    % Control switching thresholds (Data Authority)
    ic.control_switching = struct();
    ic.control_switching.rate_to_bhp_threshold = ic.max_bhp_psi - switching.injector_bhp_margin_psi;
    ic.control_switching.bhp_to_rate_threshold = ic.max_bhp_psi - switching.injector_bhp_recovery_psi;
    
    % Water quality specifications (Data Authority)
    ic.water_quality = struct();
    ic.water_quality.max_tss_ppm = water_qual.max_tss_ppm;
    ic.water_quality.max_oil_content_ppm = water_qual.max_oil_content_ppm;
    ic.water_quality.max_particle_size_microns = water_qual.max_particle_size_microns;
    ic.water_quality.min_ph = water_qual.min_ph;
    ic.water_quality.max_ph = water_qual.max_ph;
    
    % Injection pump specifications (Data Authority)
    ic.pump_system = struct();
    ic.pump_system.type = pump_sys.injection_pump.type;
    ic.pump_system.max_pressure_psi = ic.max_bhp_psi + pump_sys.injection_pump.pressure_margin_psi;
    ic.pump_system.efficiency = equip.pump_efficiency;
    ic.pump_system.vfd_control = pump_sys.injection_pump.vfd_control;

end

function well_config = get_well_config_by_name(wells_config, well_name)
% GET_WELL_CONFIG_BY_NAME - Get well configuration by name (handles hyphens)
% KISS PRINCIPLE: Simple helper to handle invalid field names
    
    % Convert well name to valid field name (replace hyphens with underscores)
    field_name = strrep(well_name, '-', '_');
    
    % Try to access with converted field name first
    if isfield(wells_config, field_name)
        well_config = wells_config.(field_name);
    elseif isfield(wells_config, well_name)
        % Fallback to original name if it exists
        well_config = wells_config.(well_name);
    else
        % If neither works, search through all fields
        field_names = fieldnames(wells_config);
        found = false;
        for i = 1:length(field_names)
            fn = field_names{i};
            % Check if this field has the same name after converting back
            if strcmp(strrep(fn, '_', '-'), well_name) || strcmp(fn, well_name)
                well_config = wells_config.(fn);
                found = true;
                break;
            end
        end
        if ~found
            error('Well configuration not found for: %s', well_name);
        end
    end
end