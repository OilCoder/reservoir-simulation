function switching_logic = setup_switching_logic(control_results, config)
% SETUP_SWITCHING_LOGIC - Setup control switching logic for all wells
%
% INPUTS:
%   control_results - Structure with producer and injector controls
%   config          - Configuration structure
%
% OUTPUTS:
%   switching_logic - Structure with switching logic for all wells
%
% DATA AUTHORITY: All parameters from config files, no hardcoded values
% KISS PRINCIPLE: Single responsibility - only switching logic setup

    % WARNING SUPPRESSION: Clean output for utility functions
    warning('off', 'all');

    fprintf('\n Control Switching Logic:\n');
    fprintf(' ─────────────────────────────────────────────────────────────\n');
    
    % Get configuration parameters (Data Authority Policy)
    dev_params = config.production_controls.development_parameters;
    field_const = config.production_controls.field_constraints;
    switching_params = config.production_controls.control_switching;
    
    switching_logic = struct();
    switching_logic.enabled = true;
    switching_logic.check_frequency_days = dev_params.check_frequency_days;
    
    % Producer switching logic
    switching_logic.producers = create_producer_switching_logic(control_results.producer_controls, switching_params);
    
    % Injector switching logic
    switching_logic.injectors = create_injector_switching_logic(control_results.injector_controls);
    
    % Field-level switching logic (Data Authority)
    switching_logic.field_level = struct();
    switching_logic.field_level.voidage_replacement_target = field_const.voidage_replacement_range;
    switching_logic.field_level.total_liquid_rate_limit = field_const.total_liquid_rate_limit_bbl_day;
    switching_logic.field_level.pressure_maintenance_priority = field_const.pressure_maintenance_priority;
    
    fprintf('   Producer Controls: %d wells with switching logic\n', ...
        length(fieldnames(switching_logic.producers)));
    fprintf('   Injector Controls: %d wells with switching logic\n', ...
        length(fieldnames(switching_logic.injectors)));
    fprintf('   Switching Check Frequency: %d day(s)\n', switching_logic.check_frequency_days);
    fprintf(' ─────────────────────────────────────────────────────────────\n');

end

function producers_logic = create_producer_switching_logic(producer_controls, switching_params)
% CREATE_PRODUCER_SWITCHING_LOGIC - Create switching logic for producers
% KISS PRINCIPLE: Single responsibility helper function

    producers_logic = struct();
    
    for i = 1:length(producer_controls)
        pc = producer_controls(i);
        
        psl = struct();
        psl.name = pc.name;
        psl.current_control = 'rate';  % Start with rate control
        
        % Rate to BHP switching conditions (Data Authority)
        psl.rate_to_bhp_conditions = {
            sprintf('BHP < %.1f psi', pc.control_switching.rate_to_bhp_threshold),
            sprintf('Water_Cut > %.1f%%', pc.control_switching.water_cut_limit * 100),
            sprintf('GOR > %.0f SCF/STB', pc.control_switching.gor_limit)
        };
        
        % BHP to rate switching conditions (Data Authority)
        psl.bhp_to_rate_conditions = {
            sprintf('BHP > %.1f psi', pc.control_switching.bhp_to_rate_threshold),
            sprintf('Water_Cut < %.1f%%', switching_params.safety_water_cut_limit * 100),
            sprintf('GOR < %.0f SCF/STB', pc.control_switching.gor_limit * switching_params.gor_reduction_factor)
        };
        
        % Use valid field name for structure assignment
        valid_field_name = make_valid_field_name(pc.name);
        producers_logic.(valid_field_name) = psl;
    end

end

function injectors_logic = create_injector_switching_logic(injector_controls)
% CREATE_INJECTOR_SWITCHING_LOGIC - Create switching logic for injectors
% KISS PRINCIPLE: Single responsibility helper function

    injectors_logic = struct();
    
    for i = 1:length(injector_controls)
        ic = injector_controls(i);
        
        isl = struct();
        isl.name = ic.name;
        isl.current_control = 'rate';  % Start with rate control
        
        % Rate to BHP switching conditions (Data Authority)
        isl.rate_to_bhp_conditions = {
            sprintf('BHP > %.1f psi', ic.control_switching.rate_to_bhp_threshold),
            'Injection rate declining trend'
        };
        
        % BHP to rate switching conditions (Data Authority)
        isl.bhp_to_rate_conditions = {
            sprintf('BHP < %.1f psi', ic.control_switching.bhp_to_rate_threshold),
            'Stable injection performance'
        };
        
        % Use valid field name for structure assignment
        valid_field_name = make_valid_field_name(ic.name);
        injectors_logic.(valid_field_name) = isl;
    end

end

function valid_name = make_valid_field_name(field_name)
% MAKE_VALID_FIELD_NAME - Convert field name to valid Octave field name
% KISS PRINCIPLE: Simple helper to handle invalid field names
    
    % Replace hyphens with underscores for valid field names
    valid_name = strrep(field_name, '-', '_');
end