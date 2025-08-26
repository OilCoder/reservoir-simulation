function producer_controls = design_producer_controls(completion_data, config)
% DESIGN_PRODUCER_CONTROLS - Design control systems for producer wells
%
% INPUTS:
%   completion_data - Wells completion data structure
%   config          - Combined configuration structure
%
% OUTPUTS:
%   producer_controls - Array of producer control structures
%
% DATA AUTHORITY: All parameters from config files, no hardcoded values
% KISS PRINCIPLE: Single responsibility - only producer control design

    fprintf('\n Producer Control Systems:\n');
    fprintf(' ──────────────────────────────────────────────────────────────────\n');
    
    producer_controls = [];
    
    % Get configuration parameters (Data Authority Policy)
    conv = config.production_controls.conversion_constants;
    equip = config.production_controls.equipment_defaults;
    switching = config.production_controls.control_switching;
    
    % Get producer wells from completion data
    all_wells = completion_data.wells_data.placement.producers;
    producers_config = config.wells_system.producer_wells;
    
    % Design controls for each producer
    for i = 1:length(all_wells)
        well = all_wells(i);
        well_config = producers_config.(well.name);
        
        pc = create_producer_control_structure(well, well_config, conv, equip, switching);
        producer_controls = [producer_controls; pc];
        
        fprintf('   %-8s │ %4d STB/d │ %4d psi │ %2d%% WC │ ESP: %-8s\n', ...
            pc.name, pc.target_oil_rate_stb_day, pc.min_bhp_psi, ...
            round(pc.max_water_cut*100), pc.esp_system.type);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────────\n');

end

function pc = create_producer_control_structure(well, well_config, conv, equip, switching)
% CREATE_PRODUCER_CONTROL_STRUCTURE - Create individual producer control structure
% KISS PRINCIPLE: Single responsibility helper function

    pc = struct();
    pc.name = well.name;
    pc.type = 'producer';
    pc.well_type = well.well_type;
    pc.phase = well.phase;
    
    % Primary control: Oil rate (Data Authority)
    pc.primary_control = 'oil_rate';
    pc.target_oil_rate_stb_day = well_config.target_oil_rate_stb_day;
    pc.target_oil_rate_m3_day = pc.target_oil_rate_stb_day * conv.stb_to_m3;
    
    % BHP constraint (Data Authority)
    pc.min_bhp_psi = well_config.min_bhp_psi;
    pc.min_bhp_pa = pc.min_bhp_psi * conv.psi_to_pa;
    
    % Additional constraints (Data Authority)
    pc.max_water_cut = well_config.max_water_cut;
    pc.max_gor_scf_stb = well_config.max_gor_scf_stb;
    
    % Calculate maximum liquid rate based on water cut limit
    if pc.max_water_cut < 1.0
        pc.max_liquid_rate_stb_day = pc.target_oil_rate_stb_day / (1 - pc.max_water_cut);
    else
        rate_const = config.production_controls.rate_constraints;
        pc.max_liquid_rate_stb_day = pc.target_oil_rate_stb_day * rate_const.max_liquid_rate_safety_factor;
    end
    pc.max_liquid_rate_m3_day = pc.max_liquid_rate_stb_day * conv.stb_to_m3;
    
    % Control switching thresholds (Data Authority)
    pc.control_switching = struct();
    pc.control_switching.rate_to_bhp_threshold = pc.min_bhp_psi + switching.producer_bhp_margin_psi;
    pc.control_switching.bhp_to_rate_threshold = pc.min_bhp_psi + switching.producer_bhp_recovery_psi;
    pc.control_switching.water_cut_limit = pc.max_water_cut;
    pc.control_switching.gor_limit = pc.max_gor_scf_stb;
    
    % ESP operating parameters (Data Authority)
    pc.esp_system = struct();
    pc.esp_system.type = well_config.esp_type;
    pc.esp_system.stages = well_config.esp_stages;
    pc.esp_system.hp = well_config.esp_hp;
    pc.esp_system.frequency_hz = equip.standard_frequency_hz;
    pc.esp_system.efficiency = equip.esp_efficiency;

end