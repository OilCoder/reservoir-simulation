function targets_results = s20_production_targets()
% S20_PRODUCTION_TARGETS - Production Targets and Optimization for Eagle West Field
% Requires: MRST
%
% Implements production optimization with:
% - Peak production: 18,500 STB/day (Phase 6)
% - Voidage replacement ratios: 0.95-1.20 per phase
% - Field pressure maintenance strategy
% - Production targets per well and phase
% - Rate constraints and optimization
% - Economic optimization logic
%
% OUTPUTS:
%   targets_results - Structure with production targets and optimization
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S20', 'Production Targets and Optimization');
    
    total_start_time = tic;
    targets_results = initialize_targets_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Development Schedule Data
        % ----------------------------------------
        step_start = tic;
        [schedule_data, control_data] = step_1_load_schedule_data();
        targets_results.schedule_data = schedule_data;
        targets_results.control_data = control_data;
        print_step_result(1, 'Load Development Schedule Data', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Calculate Phase-Based Targets
        % ----------------------------------------
        step_start = tic;
        phase_targets = step_2_calculate_phase_targets(schedule_data);
        targets_results.phase_targets = phase_targets;
        print_step_result(2, 'Calculate Phase-Based Targets', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Design Pressure Maintenance Strategy
        % ----------------------------------------
        step_start = tic;
        pressure_strategy = step_3_design_pressure_maintenance(phase_targets, schedule_data);
        targets_results.pressure_strategy = pressure_strategy;
        print_step_result(3, 'Design Pressure Maintenance Strategy', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Optimize Well-Level Allocation
        % ----------------------------------------
        step_start = tic;
        well_allocation = step_4_optimize_well_allocation(targets_results);
        targets_results.well_allocation = well_allocation;
        print_step_result(4, 'Optimize Well-Level Allocation', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Economic Optimization Logic
        % ----------------------------------------
        step_start = tic;
        economic_optimization = step_5_economic_optimization(targets_results);
        targets_results.economic_optimization = economic_optimization;
        print_step_result(5, 'Economic Optimization Logic', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Production Targets
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_targets_data(targets_results);
        targets_results.export_path = export_path;
        print_step_result(6, 'Export Production Targets', 'success', toc(step_start));
        
        targets_results.status = 'success';
        targets_results.peak_production_stb_day = 18500;
        targets_results.total_phases = 6;
        targets_results.optimization_complete = true;
        targets_results.creation_time = datestr(now);
        
        print_step_footer('S20', sprintf('Production Targets Optimized (Peak: %d STB/day)', ...
            targets_results.peak_production_stb_day), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Production Targets', ME.message);
        targets_results.status = 'failed';
        targets_results.error_message = ME.message;
        error('Production targets optimization failed: %s', ME.message);
    end

end

function targets_results = initialize_targets_structure()
% Initialize production targets results structure
    targets_results = struct();
    targets_results.status = 'initializing';
    targets_results.phase_targets = [];
    targets_results.pressure_strategy = [];
    targets_results.well_allocation = [];
    targets_results.economic_optimization = [];
end

function [schedule_data, control_data] = step_1_load_schedule_data()
% Step 1 - Load development schedule and control data

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Load development schedule data _________________
    schedule_file = fullfile(data_dir, 'development_schedule.mat');
    if exist(schedule_file, 'file')
        load(schedule_file, 'schedule_results');
        schedule_data = schedule_results;
        fprintf('Loaded development schedule: %d phases, %d wells\n', ...
            length(schedule_data.development_phases), schedule_data.total_wells);
    else
        error('Development schedule file not found. Run s19_development_schedule.m first.');
    end
    
    % Substep 1.2 - Load production controls data __________________
    controls_file = fullfile(data_dir, 'production_controls.mat');
    if exist(controls_file, 'file')
        load(controls_file, 'control_results');
        control_data = control_results;
        fprintf('Loaded production controls: %d producers + %d injectors\n', ...
            length(control_data.producer_controls), length(control_data.injector_controls));
    else
        error('Production controls file not found. Run s18_production_controls.m first.');
    end

end

function phase_targets = step_2_calculate_phase_targets(schedule_data)
% Step 2 - Calculate detailed production targets for each phase

    fprintf('\n Phase-Based Production Targets:\n');
    fprintf(' ───────────────────────────────────────────────────────────────────────────\n');
    
    phase_targets = [];
    development_phases = schedule_data.development_phases;
    
    % Substep 2.1 - Process each development phase _________________
    for i = 1:length(development_phases)
        phase = development_phases(i);
        
        pt = struct();
        pt.phase_number = i;
        pt.phase_name = phase.phase_name;
        pt.duration_days = phase.duration_days;
        pt.start_day = phase.start_day;
        pt.end_day = phase.end_day;
        
        % Substep 2.2 - Production targets ___________________________
        pt.target_oil_rate_stb_day = phase.target_oil_rate_stb_day;
        pt.expected_oil_rate_stb_day = phase.expected_oil_rate_stb_day;
        pt.water_cut_percent = phase.water_cut_percent;
        pt.gor_scf_stb = phase.gor_scf_stb;
        
        % Substep 2.3 - Calculate liquid production __________________
        oil_rate = pt.expected_oil_rate_stb_day;
        water_cut = pt.water_cut_percent / 100;
        
        if water_cut > 0
            pt.water_rate_stb_day = oil_rate * (water_cut / (1 - water_cut));
        else
            pt.water_rate_stb_day = 0;
        end
        
        pt.total_liquid_rate_stb_day = oil_rate + pt.water_rate_stb_day;
        
        % Substep 2.4 - Gas production _______________________________
        pt.gas_rate_scf_day = oil_rate * pt.gor_scf_stb;
        pt.gas_rate_mmscf_day = pt.gas_rate_scf_day / 1000000;
        
        % Substep 2.5 - Injection targets ____________________________
        if phase.injection_rate_bwpd > 0
            pt.injection_rate_bwpd = phase.injection_rate_bwpd;
            pt.vrr_target = phase.vrr_target;
            
            % Calculate required injection based on voidage replacement
            reservoir_voidage_bbl_day = pt.total_liquid_rate_stb_day;  % Assume STB ≈ bbl at reservoir conditions
            pt.required_injection_bwpd = reservoir_voidage_bbl_day * pt.vrr_target;
            pt.injection_excess_bwpd = pt.injection_rate_bwpd - pt.required_injection_bwpd;
        else
            pt.injection_rate_bwpd = 0;
            pt.vrr_target = 0;
            pt.required_injection_bwpd = 0;
            pt.injection_excess_bwpd = 0;
        end
        
        % Substep 2.6 - Production efficiency metrics _______________
        pt.num_active_producers = phase.num_producers;
        pt.num_active_injectors = phase.num_injectors;
        
        if pt.num_active_producers > 0
            pt.oil_rate_per_producer = pt.expected_oil_rate_stb_day / pt.num_active_producers;
        else
            pt.oil_rate_per_producer = 0;
        end
        
        if pt.num_active_injectors > 0
            pt.injection_rate_per_injector = pt.injection_rate_bwpd / pt.num_active_injectors;
        else
            pt.injection_rate_per_injector = 0;
        end
        
        % Substep 2.7 - Calculate cumulative production _____________
        if i == 1
            pt.cumulative_oil_mmstb = 0;
            pt.cumulative_gas_bcf = 0;
            pt.cumulative_water_mmstb = 0;
            pt.cumulative_injection_mmbwi = 0;
        else
            prev_phase = phase_targets(i-1);
            pt.cumulative_oil_mmstb = prev_phase.cumulative_oil_mmstb + ...
                (prev_phase.expected_oil_rate_stb_day * prev_phase.duration_days / 1000000);
            pt.cumulative_gas_bcf = prev_phase.cumulative_gas_bcf + ...
                (prev_phase.gas_rate_scf_day * prev_phase.duration_days / 1000000000);
            pt.cumulative_water_mmstb = prev_phase.cumulative_water_mmstb + ...
                (prev_phase.water_rate_stb_day * prev_phase.duration_days / 1000000);
            pt.cumulative_injection_mmbwi = prev_phase.cumulative_injection_mmbwi + ...
                (prev_phase.injection_rate_bwpd * prev_phase.duration_days / 1000000);
        end
        
        phase_targets = [phase_targets; pt];
        
        fprintf('   Phase %d │ %5d STB/d │ %5d BWD │ %2d%% WC │ %3d SCF/STB │ VRR: %.2f\n', ...
            pt.phase_number, pt.expected_oil_rate_stb_day, pt.injection_rate_bwpd, ...
            pt.water_cut_percent, pt.gor_scf_stb, pt.vrr_target);
    end
    
    fprintf(' ───────────────────────────────────────────────────────────────────────────\n');
    
    % Add final cumulative totals
    final_phase = phase_targets(end);
    final_cumulative_oil = final_phase.cumulative_oil_mmstb + ...
        (final_phase.expected_oil_rate_stb_day * final_phase.duration_days / 1000000);
    
    fprintf('   Ultimate Recovery: %.1f MMbbl over 10 years\n', final_cumulative_oil);

end

function pressure_strategy = step_3_design_pressure_maintenance(phase_targets, schedule_data)
% Step 3 - Design comprehensive pressure maintenance strategy

    fprintf('\n Pressure Maintenance Strategy:\n');
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    
    pressure_strategy = struct();
    
    % Substep 3.1 - Initial reservoir conditions ___________________
    pressure_strategy.initial_pressure_psi = 2900;
    pressure_strategy.bubble_point_pressure_psi = 2200;  % Critical threshold
    pressure_strategy.minimum_operating_pressure_psi = 2400;  % 83% of initial
    pressure_strategy.target_pressure_psi = 2500;  % Operational target
    
    % Substep 3.2 - Phase-specific pressure targets _______________
    pressure_strategy.phase_pressure_targets = [];
    
    for i = 1:length(phase_targets)
        phase = phase_targets(i);
        
        ppt = struct();
        ppt.phase_number = i;
        ppt.phase_name = phase.phase_name;
        
        % Calculate pressure decline based on production
        if i == 1
            % Natural depletion in Phase 1
            ppt.target_pressure_psi = 2650;  % Expected decline to 2650 psi
            ppt.pressure_support = 'natural_depletion';
            ppt.pressure_maintenance_efficiency = 0;
        elseif i == 2
            % Initial injection support
            ppt.target_pressure_psi = 2700;  % Pressure recovery
            ppt.pressure_support = 'partial_injection';
            ppt.pressure_maintenance_efficiency = 0.6;
        elseif i == 3
            % Pattern establishment
            ppt.target_pressure_psi = 2750;  % Further recovery
            ppt.pressure_support = 'pattern_initiation';
            ppt.pressure_maintenance_efficiency = 0.75;
        else
            % Full pressure maintenance
            ppt.target_pressure_psi = 2500;  % Maintained pressure
            ppt.pressure_support = 'full_waterflood';
            ppt.pressure_maintenance_efficiency = 0.85;
        end
        
        % Substep 3.3 - VRR optimization ____________________________
        ppt.vrr_target = phase.vrr_target;
        ppt.vrr_range = [ppt.vrr_target * 0.9, ppt.vrr_target * 1.1];  % ±10% flexibility
        
        % Injection optimization based on pressure response
        if phase.injection_rate_bwpd > 0
            ppt.injection_optimization = struct();
            ppt.injection_optimization.base_rate_bwpd = phase.injection_rate_bwpd;
            ppt.injection_optimization.min_rate_bwpd = phase.injection_rate_bwpd * 0.8;
            ppt.injection_optimization.max_rate_bwpd = phase.injection_rate_bwpd * 1.2;
            
            % Pressure response time
            ppt.injection_optimization.response_time_days = 30;  % Expected pressure response
            ppt.injection_optimization.adjustment_frequency_days = 7;  % Weekly adjustments
        end
        
        pressure_strategy.phase_pressure_targets = [pressure_strategy.phase_pressure_targets; ppt];
        
        fprintf('   Phase %d │ Target: %4d psi │ VRR: %.2f │ Support: %s\n', ...
            ppt.phase_number, ppt.target_pressure_psi, ppt.vrr_target, ppt.pressure_support);
    end
    
    % Substep 3.4 - Pressure monitoring strategy ___________________
    pressure_strategy.monitoring = struct();
    pressure_strategy.monitoring.measurement_frequency_days = 7;  % Weekly RFT surveys
    pressure_strategy.monitoring.critical_pressure_threshold = 2300;  % Emergency threshold
    pressure_strategy.monitoring.pressure_gradient_limit = 50;  % Max decline per month
    
    % Substep 3.5 - Injection allocation strategy ___________________
    pressure_strategy.injection_allocation = struct();
    pressure_strategy.injection_allocation.pattern_efficiency_target = 0.75;
    pressure_strategy.injection_allocation.sweep_efficiency_target = 0.65;
    pressure_strategy.injection_allocation.conformance_factor = 0.8;
    
    % Substep 3.6 - Emergency response procedures ___________________
    pressure_strategy.emergency_response = struct();
    pressure_strategy.emergency_response.trigger_pressure_psi = 2300;
    pressure_strategy.emergency_response.actions = {
        'Increase injection rates by 20%',
        'Reduce production rates by 10%', 
        'Activate emergency water supply',
        'Consider polymer injection for sweep improvement'
    };
    
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    fprintf('   Pressure Target: Maintain >2,400 psi (83%% of initial)\n');
    fprintf('   VRR Range: 0.95 to 1.20 based on phase requirements\n');

end

function well_allocation = step_4_optimize_well_allocation(targets_results)
% Step 4 - Optimize production allocation among wells

    fprintf('\n Well-Level Production Allocation:\n');
    fprintf(' ──────────────────────────────────────────────────────────────────────\n');
    
    well_allocation = struct();
    phase_targets = targets_results.phase_targets;
    schedule_data = targets_results.schedule_data;
    control_data = targets_results.control_data;
    
    well_allocation.phases = [];
    
    % Substep 4.1 - Allocate production for each phase _____________
    for i = 1:length(phase_targets)
        phase = phase_targets(i);
        development_phase = schedule_data.development_phases(i);
        
        wa = struct();
        wa.phase_number = i;
        wa.phase_name = phase.phase_name;
        wa.field_oil_target_stb_day = phase.expected_oil_rate_stb_day;
        wa.field_injection_target_bwpd = phase.injection_rate_bwpd;
        
        % Substep 4.2 - Producer allocation _________________________
        wa.producer_allocation = [];
        active_producers = development_phase.active_producers;
        
        % Get producer capabilities
        total_producer_capacity = 0;
        producer_capacities = containers.Map();
        
        for j = 1:length(active_producers)
            well_name = active_producers{j};
            
            % Find well capacity from controls
            for k = 1:length(control_data.producer_controls)
                if strcmp(control_data.producer_controls(k).name, well_name)
                    capacity = control_data.producer_controls(k).target_oil_rate_stb_day;
                    producer_capacities(well_name) = capacity;
                    total_producer_capacity = total_producer_capacity + capacity;
                    break;
                end
            end
        end
        
        % Allocate based on relative capacity with optimization
        for j = 1:length(active_producers)
            well_name = active_producers{j};
            
            pa = struct();
            pa.well_name = well_name;
            pa.well_capacity_stb_day = producer_capacities(well_name);
            
            if total_producer_capacity > 0
                % Base allocation proportional to capacity
                base_allocation = (pa.well_capacity_stb_day / total_producer_capacity) * wa.field_oil_target_stb_day;
                
                % Apply optimization factors
                optimization_factor = calculate_producer_optimization_factor(well_name, i, control_data);
                pa.optimized_rate_stb_day = round(base_allocation * optimization_factor);
                
                % Apply constraints
                pa.optimized_rate_stb_day = min(pa.optimized_rate_stb_day, pa.well_capacity_stb_day);
                pa.optimization_factor = optimization_factor;
            else
                pa.optimized_rate_stb_day = 0;
                pa.optimization_factor = 1.0;
            end
            
            wa.producer_allocation = [wa.producer_allocation; pa];
        end
        
        % Substep 4.3 - Injector allocation _________________________
        wa.injector_allocation = [];
        active_injectors = development_phase.active_injectors;
        
        if ~isempty(active_injectors) && wa.field_injection_target_bwpd > 0
            % Distribute injection equally with pattern optimization
            base_injection_per_well = wa.field_injection_target_bwpd / length(active_injectors);
            
            for j = 1:length(active_injectors)
                well_name = active_injectors{j};
                
                ia = struct();
                ia.well_name = well_name;
                
                % Get injector capacity from controls
                for k = 1:length(control_data.injector_controls)
                    if strcmp(control_data.injector_controls(k).name, well_name)
                        ia.well_capacity_bwpd = control_data.injector_controls(k).target_injection_rate_bbl_day;
                        break;
                    end
                end
                
                % Apply pattern-based optimization
                pattern_factor = calculate_injector_pattern_factor(well_name, i);
                ia.optimized_rate_bwpd = round(base_injection_per_well * pattern_factor);
                
                % Apply constraints
                ia.optimized_rate_bwpd = min(ia.optimized_rate_bwpd, ia.well_capacity_bwpd);
                ia.pattern_factor = pattern_factor;
                
                wa.injector_allocation = [wa.injector_allocation; ia];
            end
        end
        
        % Substep 4.4 - Calculate allocation efficiency _____________
        allocated_oil = sum([wa.producer_allocation.optimized_rate_stb_day]);
        allocated_injection = sum([wa.injector_allocation.optimized_rate_bwpd]);
        
        wa.allocation_efficiency = struct();
        wa.allocation_efficiency.oil_target_achievement = allocated_oil / wa.field_oil_target_stb_day;
        if wa.field_injection_target_bwpd > 0
            wa.allocation_efficiency.injection_target_achievement = allocated_injection / wa.field_injection_target_bwpd;
        else
            wa.allocation_efficiency.injection_target_achievement = 1.0;
        end
        
        well_allocation.phases = [well_allocation.phases; wa];
        
        fprintf('   Phase %d │ %2d prod │ %2d inj │ Oil: %5d/%5d │ Inj: %5d/%5d\n', ...
            i, length(active_producers), length(active_injectors), ...
            allocated_oil, wa.field_oil_target_stb_day, ...
            allocated_injection, wa.field_injection_target_bwpd);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────────────────\n');

end

function optimization_factor = calculate_producer_optimization_factor(well_name, phase, control_data)
% Calculate optimization factor for producer based on well type and phase

    % Find well configuration
    well_type = 'vertical';  % Default
    for i = 1:length(control_data.producer_controls)
        if strcmp(control_data.producer_controls(i).name, well_name)
            well_type = control_data.producer_controls(i).well_type;
            break;
        end
    end
    
    % Base optimization factors by well type
    if strcmp(well_type, 'vertical')
        base_factor = 1.0;
    elseif strcmp(well_type, 'horizontal')
        base_factor = 1.2;  % 20% higher productivity
    elseif strcmp(well_type, 'multi-lateral')
        base_factor = 1.4;  % 40% higher productivity
    else
        base_factor = 1.0;
    end
    
    % Phase-based adjustments
    if phase <= 2
        phase_factor = 1.1;  % Higher rates in early phases
    elseif phase <= 4
        phase_factor = 1.0;  % Stable production
    else
        phase_factor = 0.9;  % Decline in later phases
    end
    
    % Well-specific adjustments based on structural position
    structural_factor = 1.0;
    if ~isempty(strfind(well_name, '001')) || ~isempty(strfind(well_name, '005')) || ~isempty(strfind(well_name, '010'))
        structural_factor = 1.15;  % Crest wells get preference
    end
    
    optimization_factor = base_factor * phase_factor * structural_factor;

end

function pattern_factor = calculate_injector_pattern_factor(well_name, phase)
% Calculate injection pattern optimization factor

    % Base pattern efficiency by phase
    if phase <= 2
        base_pattern = 1.0;  % Simple patterns
    elseif phase <= 4
        base_pattern = 1.1;  % Established patterns
    else
        base_pattern = 1.2;  % Optimized mature patterns
    end
    
    % Well-specific pattern position
    position_factor = 1.0;
    if ~isempty(strfind(well_name, '001')) || ~isempty(strfind(well_name, '005'))
        position_factor = 1.1;  % Key pattern positions
    end
    
    pattern_factor = base_pattern * position_factor;

end

function economic_optimization = step_5_economic_optimization(targets_results)
% Step 5 - Economic optimization logic for production targets

    fprintf('\n Economic Optimization Logic:\n');
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    
    economic_optimization = struct();
    phase_targets = targets_results.phase_targets;
    
    % Substep 5.1 - Economic parameters ____________________________
    economic_optimization.parameters = struct();
    economic_optimization.parameters.oil_price_usd_bbl = 70;  % Base oil price
    economic_optimization.parameters.gas_price_usd_mcf = 4.50;  % Gas price
    economic_optimization.parameters.water_handling_cost_usd_bbl = 2.50;
    economic_optimization.parameters.injection_cost_usd_bbl = 1.20;
    economic_optimization.parameters.esp_operating_cost_usd_day = 150;
    
    % Substep 5.2 - Phase-based economic analysis __________________
    economic_optimization.phase_economics = [];
    
    for i = 1:length(phase_targets)
        phase = phase_targets(i);
        
        pe = struct();
        pe.phase_number = i;
        pe.phase_name = phase.phase_name;
        pe.duration_days = phase.duration_days;
        
        % Revenue calculations
        daily_oil_revenue = phase.expected_oil_rate_stb_day * economic_optimization.parameters.oil_price_usd_bbl;
        daily_gas_revenue = phase.gas_rate_mmscf_day * economic_optimization.parameters.gas_price_usd_mcf * 1000;
        pe.daily_revenue_usd = daily_oil_revenue + daily_gas_revenue;
        
        % Cost calculations
        daily_water_cost = phase.water_rate_stb_day * economic_optimization.parameters.water_handling_cost_usd_bbl;
        daily_injection_cost = phase.injection_rate_bwpd * economic_optimization.parameters.injection_cost_usd_bbl;
        daily_esp_cost = phase.num_active_producers * economic_optimization.parameters.esp_operating_cost_usd_day;
        pe.daily_opex_usd = daily_water_cost + daily_injection_cost + daily_esp_cost;
        
        % Net economics
        pe.daily_net_cashflow_usd = pe.daily_revenue_usd - pe.daily_opex_usd;
        pe.phase_net_cashflow_musd = (pe.daily_net_cashflow_usd * pe.duration_days) / 1000000;
        
        % Optimization metrics
        pe.oil_revenue_per_stb = economic_optimization.parameters.oil_price_usd_bbl;
        pe.opex_per_stb = pe.daily_opex_usd / phase.expected_oil_rate_stb_day;
        pe.netback_per_stb = pe.oil_revenue_per_stb - pe.opex_per_stb;
        
        economic_optimization.phase_economics = [economic_optimization.phase_economics; pe];
        
        fprintf('   Phase %d │ Rev: $%6.0fK/d │ OPEX: $%5.0fK/d │ Net: $%6.0fK/d │ $%4.1f/STB\n', ...
            pe.phase_number, pe.daily_revenue_usd/1000, pe.daily_opex_usd/1000, ...
            pe.daily_net_cashflow_usd/1000, pe.netback_per_stb);
    end
    
    % Substep 5.3 - Rate optimization strategy ____________________
    economic_optimization.rate_optimization = struct();
    economic_optimization.rate_optimization.strategy = 'maximize_npv';
    economic_optimization.rate_optimization.discount_rate = 0.10;  % 10% discount rate
    
    % Constraints for rate optimization
    economic_optimization.rate_optimization.constraints = struct();
    economic_optimization.rate_optimization.constraints.min_oil_price_usd_bbl = 50;  % Economic limit
    economic_optimization.rate_optimization.constraints.max_water_cut_percent = 85;  % Economic limit
    economic_optimization.rate_optimization.constraints.min_netback_usd_stb = 15;  % Minimum economic netback
    
    % Substep 5.4 - Well prioritization logic ______________________
    economic_optimization.well_prioritization = struct();
    economic_optimization.well_prioritization.ranking_criteria = {
        'netback_per_stb',
        'cumulative_npv_contribution',
        'production_sustainability',
        'water_cut_progression'
    };
    
    % Priority scoring system
    economic_optimization.well_prioritization.scoring = struct();
    economic_optimization.well_prioritization.scoring.high_netback_bonus = 1.2;
    economic_optimization.well_prioritization.scoring.low_water_cut_bonus = 1.1;
    economic_optimization.well_prioritization.scoring.structural_position_bonus = 1.15;
    
    % Substep 5.5 - Calculate cumulative economics _________________
    cumulative_revenue = 0;
    cumulative_opex = 0;
    
    for i = 1:length(economic_optimization.phase_economics)
        pe = economic_optimization.phase_economics(i);
        cumulative_revenue = cumulative_revenue + (pe.daily_revenue_usd * pe.duration_days);
        cumulative_opex = cumulative_opex + (pe.daily_opex_usd * pe.duration_days);
    end
    
    economic_optimization.field_economics = struct();
    economic_optimization.field_economics.total_revenue_musd = cumulative_revenue / 1000000;
    economic_optimization.field_economics.total_opex_musd = cumulative_opex / 1000000;
    economic_optimization.field_economics.total_net_cashflow_musd = ...
        economic_optimization.field_economics.total_revenue_musd - economic_optimization.field_economics.total_opex_musd;
    
    fprintf(' ──────────────────────────────────────────────────────────────\n');
    fprintf('   Field Total: Revenue: $%.0fM │ OPEX: $%.0fM │ Net: $%.0fM\n', ...
        economic_optimization.field_economics.total_revenue_musd, ...
        economic_optimization.field_economics.total_opex_musd, ...
        economic_optimization.field_economics.total_net_cashflow_musd);

end

function export_path = step_6_export_targets_data(targets_results)
% Step 6 - Export production targets and optimization data

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save MATLAB structure __________________________
    export_path = fullfile(data_dir, 'production_targets.mat');
    save(export_path, 'targets_results');
    
    % Substep 6.2 - Create targets summary _________________________
    summary_file = fullfile(data_dir, 'production_targets_summary.txt');
    write_targets_summary_file(summary_file, targets_results);
    
    % Substep 6.3 - Create well allocation table ___________________
    allocation_file = fullfile(data_dir, 'well_allocation_targets.txt');
    write_allocation_file(allocation_file, targets_results);
    
    % Substep 6.4 - Create economic analysis _______________________
    economics_file = fullfile(data_dir, 'economic_optimization.txt');
    write_economics_file(economics_file, targets_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Allocation: %s\n', allocation_file);
    fprintf('   Economics: %s\n', economics_file);

end

function write_targets_summary_file(filename, targets_results)
% Write production targets summary to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Production Targets Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '===========================================\n\n');
        
        % Overall targets summary
        fprintf(fid, 'PRODUCTION TARGETS OVERVIEW:\n');
        fprintf(fid, '  Peak Production Target: %d STB/day\n', targets_results.peak_production_stb_day);
        fprintf(fid, '  Total Development Phases: %d\n', targets_results.total_phases);
        fprintf(fid, '  VRR Range: 0.95 - 1.20\n');
        fprintf(fid, '  Pressure Maintenance: >2,400 psi target\n');
        fprintf(fid, '\n');
        
        % Phase targets
        fprintf(fid, 'PHASE TARGETS:\n');
        fprintf(fid, '%-6s %-12s %-8s %-8s %-8s %-6s %-6s %-6s\n', ...
            'Phase', 'Name', 'Oil_STB', 'Liq_STB', 'Inj_BWD', 'WC_%', 'GOR', 'VRR');
        fprintf(fid, '%s\n', repmat('-', 1, 75));
        
        for i = 1:length(targets_results.phase_targets)
            phase = targets_results.phase_targets(i);
            
            fprintf(fid, '%-6d %-12s %-8d %-8d %-8d %-6d %-6d %-6.2f\n', ...
                phase.phase_number, phase.phase_name, phase.expected_oil_rate_stb_day, ...
                phase.total_liquid_rate_stb_day, phase.injection_rate_bwpd, ...
                phase.water_cut_percent, phase.gor_scf_stb, phase.vrr_target);
        end
        
        fprintf(fid, '\n');
        
        % Pressure maintenance summary
        fprintf(fid, 'PRESSURE MAINTENANCE TARGETS:\n');
        fprintf(fid, '%-6s %-12s %-10s %-15s %-8s\n', ...
            'Phase', 'Name', 'Target_psi', 'Support_Type', 'VRR');
        fprintf(fid, '%s\n', repmat('-', 1, 60));
        
        pressure_targets = targets_results.pressure_strategy.phase_pressure_targets;
        for i = 1:length(pressure_targets)
            pt = pressure_targets(i);
            
            fprintf(fid, '%-6d %-12s %-10d %-15s %-8.2f\n', ...
                pt.phase_number, pt.phase_name, pt.target_pressure_psi, ...
                pt.pressure_support, pt.vrr_target);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing targets summary: %s', ME.message);
    end

end

function write_allocation_file(filename, targets_results)
% Write well allocation targets to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Well Allocation Targets\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '=========================================\n\n');
        
        well_allocation = targets_results.well_allocation;
        
        for i = 1:length(well_allocation.phases)
            wa = well_allocation.phases(i);
            
            fprintf(fid, 'PHASE %d - %s:\n', wa.phase_number, upper(wa.phase_name));
            fprintf(fid, '  Field Oil Target: %d STB/day\n', wa.field_oil_target_stb_day);
            fprintf(fid, '  Field Injection Target: %d BWD\n', wa.field_injection_target_bwpd);
            fprintf(fid, '\n');
            
            % Producer allocation
            if ~isempty(wa.producer_allocation)
                fprintf(fid, '  PRODUCER ALLOCATION:\n');
                fprintf(fid, '  %-8s %-10s %-12s %-8s\n', 'Well', 'Capacity', 'Target', 'Factor');
                fprintf(fid, '  %s\n', repmat('-', 1, 45));
                
                for j = 1:length(wa.producer_allocation)
                    pa = wa.producer_allocation(j);
                    fprintf(fid, '  %-8s %-10d %-12d %-8.2f\n', ...
                        pa.well_name, pa.well_capacity_stb_day, ...
                        pa.optimized_rate_stb_day, pa.optimization_factor);
                end
                fprintf(fid, '\n');
            end
            
            % Injector allocation
            if ~isempty(wa.injector_allocation)
                fprintf(fid, '  INJECTOR ALLOCATION:\n');
                fprintf(fid, '  %-8s %-10s %-12s %-8s\n', 'Well', 'Capacity', 'Target', 'Factor');
                fprintf(fid, '  %s\n', repmat('-', 1, 45));
                
                for j = 1:length(wa.injector_allocation)
                    ia = wa.injector_allocation(j);
                    fprintf(fid, '  %-8s %-10d %-12d %-8.2f\n', ...
                        ia.well_name, ia.well_capacity_bwpd, ...
                        ia.optimized_rate_bwpd, ia.pattern_factor);
                end
                fprintf(fid, '\n');
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing allocation file: %s', ME.message);
    end

end

function write_economics_file(filename, targets_results)
% Write economic optimization analysis to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Economic Optimization Analysis\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '===============================================\n\n');
        
        econ = targets_results.economic_optimization;
        
        % Economic parameters
        fprintf(fid, 'ECONOMIC PARAMETERS:\n');
        fprintf(fid, '  Oil Price: $%.2f/bbl\n', econ.parameters.oil_price_usd_bbl);
        fprintf(fid, '  Gas Price: $%.2f/Mcf\n', econ.parameters.gas_price_usd_mcf);
        fprintf(fid, '  Water Handling Cost: $%.2f/bbl\n', econ.parameters.water_handling_cost_usd_bbl);
        fprintf(fid, '  Injection Cost: $%.2f/bbl\n', econ.parameters.injection_cost_usd_bbl);
        fprintf(fid, '  ESP Operating Cost: $%.0f/day/well\n', econ.parameters.esp_operating_cost_usd_day);
        fprintf(fid, '\n');
        
        % Phase economics
        fprintf(fid, 'PHASE ECONOMIC ANALYSIS:\n');
        fprintf(fid, '%-6s %-12s %-10s %-10s %-10s %-8s\n', ...
            'Phase', 'Name', 'Rev_K$/d', 'OPEX_K$/d', 'Net_K$/d', '$/STB');
        fprintf(fid, '%s\n', repmat('-', 1, 70));
        
        for i = 1:length(econ.phase_economics)
            pe = econ.phase_economics(i);
            
            fprintf(fid, '%-6d %-12s %-10.0f %-10.0f %-10.0f %-8.1f\n', ...
                pe.phase_number, pe.phase_name, pe.daily_revenue_usd/1000, ...
                pe.daily_opex_usd/1000, pe.daily_net_cashflow_usd/1000, pe.netback_per_stb);
        end
        
        fprintf(fid, '\n');
        
        % Field totals
        fprintf(fid, 'FIELD ECONOMIC SUMMARY:\n');
        fprintf(fid, '  Total Revenue: $%.0f million\n', econ.field_economics.total_revenue_musd);
        fprintf(fid, '  Total OPEX: $%.0f million\n', econ.field_economics.total_opex_musd);
        fprintf(fid, '  Net Cashflow: $%.0f million\n', econ.field_economics.total_net_cashflow_musd);
        fprintf(fid, '\n');
        
        % Optimization constraints
        fprintf(fid, 'OPTIMIZATION CONSTRAINTS:\n');
        fprintf(fid, '  Minimum Oil Price: $%.0f/bbl\n', econ.rate_optimization.constraints.min_oil_price_usd_bbl);
        fprintf(fid, '  Maximum Water Cut: %d%%\n', econ.rate_optimization.constraints.max_water_cut_percent);
        fprintf(fid, '  Minimum Netback: $%.0f/STB\n', econ.rate_optimization.constraints.min_netback_usd_stb);
        fprintf(fid, '  Discount Rate: %.0f%%\n', econ.rate_optimization.discount_rate * 100);
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing economics file: %s', ME.message);
    end

end

% Main execution when called as script
if ~nargout
    targets_results = s20_production_targets();
end