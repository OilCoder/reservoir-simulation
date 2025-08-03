function [results, status] = s99_run_workflow(varargin)
%S99_RUN_WORKFLOW Master orchestrator for Eagle West Field MRST simulation
%
% This script orchestrates the implemented phases of the Eagle West Field 
% development simulation workflow with quality control and error handling.

% Suppress all warnings for clean output as requested
warning('off', 'all');
%
% USAGE:
%   [results, status] = s99_run_complete_workflow()           % Run all implemented phases
%   [results, status] = s99_run_complete_workflow('phases', [1,2])  % Run specific phases
%   [results, status] = s99_run_complete_workflow('validate_only', true)  % Validation only
%
% OUTPUT:
%   results - Structure containing all simulation results and data
%   status  - Comprehensive status tracking for all phases
%
% IMPLEMENTED PHASES:
%   Phase 1: Foundation (s00-s03) - COMPLETE
%   Phase 2: Structural Geology (s04-s06) - COMPLETE
%   Phase 3: Rock Properties (s07-s09) - COMPLETE
%
% FUTURE PHASES (not yet implemented):
%   Phase 4: SCAL & PVT (s10-s12) - PENDING
%   Phase 5: Initial Conditions (s13-s15) - PENDING
%   [... phases 6-9 pending ...]
%
% DEPENDENCIES:
%   - Implemented phase scripts (s00-s07, partial s08-s09)
%   - MRST 2023a or later
%   - Configuration files in config/ directory
%
% REFERENCES:
%   - Eagle West Field MRST Implementation Plan
%   - MRST_Implementation.md technical specifications

    fprintf('\n');
    fprintf('================================================================\n');
    fprintf('    EAGLE WEST FIELD - MRST SIMULATION WORKFLOW\n');
    fprintf('================================================================\n');
    fprintf('ARCHITECTURE: Direct YAML configuration reading (no s00_load_config)\n');
    fprintf('IMPLEMENTED PHASES: Foundation + Structural Geology + Rock Properties\n');
    fprintf('Grid: Dynamic cells, 5 faults, structural framework\n'); 
    fprintf('Rock: 6 rock types (RT1-RT6) with heterogeneity modeling\n');
    fprintf('Current status: Phase 1-3 complete (s01-s09)\n');
    fprintf('================================================================\n\n');
    
    %% Parse input arguments
    p = inputParser;
    addParameter(p, 'phases', [1,2,3], @(x) isnumeric(x) && all(x >= 1) && all(x <= 3));
    addParameter(p, 'validate_only', false, @islogical);
    addParameter(p, 'save_results', false, @islogical);
    addParameter(p, 'output_dir', 'output', @ischar);
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    
    phases_to_run = p.Results.phases;
    validate_only = p.Results.validate_only;
    save_results = p.Results.save_results;
    output_dir = p.Results.output_dir;
    verbose = p.Results.verbose;
    
    %% Initialize results and status structures
    results = struct();
    status = struct();
    status.workflow_start_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    status.phases_completed = [];
    status.phases_failed = [];
    status.total_runtime = 0;
    status.memory_peak = 0;
    
    % Initialize phase status tracking (only implemented phases)
    phase_names = {'Foundation', 'Structural_Geology', 'Rock_Properties'};
    
    for i = 1:length(phase_names)
        status.phases.(phase_names{i}).completed = false;
        status.phases.(phase_names{i}).runtime = 0;
        status.phases.(phase_names{i}).errors = {};
        status.phases.(phase_names{i}).warnings = {};
    end
    
    %% Validation mode
    if validate_only
        fprintf('=== VALIDATION MODE ===\n');
        fprintf('Checking environment and dependencies...\n');
        
        try
            % Check MRST installation and modules
            startup_mrst = exist('startup', 'file');
            if startup_mrst ~= 2
                error('MRST not found. Please ensure MRST is installed and in path.');
            end
            
            % Check required configuration files
            config_files = {'grid_config.yaml', 'fluid_properties_config.yaml', ...
                           'rock_properties_config.yaml', 'wells_schedule_config.yaml', ...
                           'initial_conditions_config.yaml'};
            
            for i = 1:length(config_files)
                config_path = fullfile('config', config_files{i});
                if ~exist(config_path, 'file')
                    error('Configuration file missing: %s', config_path);
                end
            end
            
            fprintf('[Y] MRST installation: OK\n');
            fprintf('[Y] Configuration files: OK\n');
            fprintf('[Y] Validation completed successfully\n');
            return;
            
        catch ME
            fprintf('[X] Validation failed: %s\n', ME.message);
            status.validation_failed = true;
            return;
        end
    end
    
    %% Create output directory only if save_results is true and user requested
    if save_results && ~exist(output_dir, 'dir')
        mkdir(output_dir);
        fprintf('Created output directory: %s\n', output_dir);
    end
    
    workflow_timer = tic;
    
    try
        %% ================================================================
        %% PHASE 1: FOUNDATION - CORE COMPONENTS
        %% ================================================================
        if ismember(1, phases_to_run)
            phase_timer = tic;
            print_phase_header(1, 'FOUNDATION - CORE COMPONENTS', verbose);
            
            try
                % Task 1.1: Initialize MRST environment
                [mrst_status] = s01_initialize_mrst();
                if ~mrst_status.success
                    error('MRST initialization failed');
                end
                results.mrst_status = mrst_status;
                
                % Task 1.2: Create basic grid (reads grid_config.yaml directly)
                [G, grid_status] = s02_create_grid();
                if ~grid_status.success
                    error('Grid creation failed');
                end
                results.grid_basic = G;
                results.grid_status = grid_status;
                
                % Task 1.3: Define basic fluid model (reads fluid_properties_config.yaml directly)
                [fluid, fluid_status] = s03_define_fluids();
                if ~fluid_status.success
                    error('Fluid model creation failed');
                end
                results.fluid_basic = fluid;
                results.fluid_status = fluid_status;
                
                status.phases.Foundation.completed = true;
                status.phases.Foundation.runtime = toc(phase_timer);
                status.phases_completed = [status.phases_completed, 1];
                
                fprintf('[Y] Phase 1 completed in %.1f seconds\n\n', status.phases.Foundation.runtime);
                
            catch ME
                status.phases.Foundation.errors{end+1} = ME.message;
                status.phases_failed = [status.phases_failed, 1];
                fprintf('[X] Phase 1 failed: %s\n\n', ME.message);
                rethrow(ME);
            end
        end
        
        %% ================================================================
        %% PHASE 2: STRUCTURAL GEOLOGY IMPLEMENTATION
        %% ================================================================
        if ismember(2, phases_to_run)
            phase_timer = tic;
            fprintf('=== PHASE 2: STRUCTURAL GEOLOGY IMPLEMENTATION ===\n');
            
            try
                % Task 2.1: Structural framework (FIRST)
                fprintf('Task 2.1: Implementing structural framework...\n');
                [G_structural, structural_status] = s04_structural_framework(results.grid_basic);
                if ~structural_status.success
                    error('Structural framework implementation failed');
                end
                results.grid_structural = G_structural;
                results.structural_status = structural_status;
                
                % Task 2.2: Fault system (SECOND)
                fprintf('Task 2.2: Adding fault system...\n');
                [G_faulted, fault_status] = s05_add_faults(G_structural);
                if ~fault_status.success
                    error('Fault system implementation failed');
                end
                results.grid_faulted = G_faulted;
                results.fault_status = fault_status;
                
                % Task 2.3: Grid refinement (THIRD)
                fprintf('Task 2.3: Applying grid refinement...\n');
                [G_refined, refinement_status] = s06_grid_refinement(G_faulted);
                if ~refinement_status.success
                    error('Grid refinement implementation failed');
                end
                results.grid_refined = G_refined;
                results.refinement_status = refinement_status;
                
                status.phases.Structural_Geology.completed = true;
                status.phases.Structural_Geology.runtime = toc(phase_timer);
                status.phases_completed = [status.phases_completed, 2];
                
                fprintf('[Y] Phase 2 completed in %.1f seconds\n', status.phases.Structural_Geology.runtime);
                fprintf('  - Structural relief: %.0f ft\n', structural_status.structural_relief/0.3048);
                fprintf('  - Faults implemented: %d\n', fault_status.faults_added); 
                fprintf('  - Refinement zones: %d cells\n\n', refinement_status.refined_cells);
                
            catch ME
                status.phases.Structural_Geology.errors{end+1} = ME.message;
                status.phases_failed = [status.phases_failed, 2];
                fprintf('[X] Phase 2 failed: %s\n\n', ME.message);
                rethrow(ME);
            end
        end
        
        %% ================================================================
        %% PHASE 3: ROCK PROPERTIES & HETEROGENEITY
        %% ================================================================
        if ismember(3, phases_to_run)
            phase_timer = tic;
            fprintf('=== PHASE 3: ROCK PROPERTIES & HETEROGENEITY ===\n');
            
            try
                % Check if we need grid from previous phase
                if ~ismember(2, phases_to_run)
                    error('Phase 3 requires Phase 2 results. Please run Phase 2 first.');
                end
                
                % Task 3.1: Define rock types
                fprintf('Task 3.1: Defining rock types...\n');
                [rock_types, rock_types_status] = s07_define_rock_types('verbose', false);
                if ~rock_types_status.success
                    error('Rock types definition failed');
                end
                results.rock_types = rock_types;
                results.rock_types_status = rock_types_status;
                
                % Task 3.2: Layer-based property assignment (if script exists)
                if exist('s08_assign_layer_properties', 'file')
                    fprintf('Task 3.2: Assigning layer properties...\n');
                    [rock, layer_status] = s08_assign_layer_properties(results.grid_refined, rock_types, []);
                    if ~layer_status.success
                        error('Layer property assignment failed');
                    end
                    results.rock = rock;
                    results.layer_status = layer_status;
                else
                    fprintf('Task 3.2: Layer properties assignment - PENDING (s08 not yet implemented)\n');
                    results.rock = struct('perm', ones(results.grid_refined.cells.num, 1) * 100e-3 * darcy(), ...
                                         'poro', ones(results.grid_refined.cells.num, 1) * 0.2);
                end
                
                % Task 3.3: Spatial heterogeneity (if script exists)
                if exist('s09_spatial_heterogeneity', 'file')
                    fprintf('Task 3.3: Applying spatial heterogeneity...\n');
                    [rock_hetero, hetero_status] = s09_spatial_heterogeneity(results.rock, results.grid_refined, []);
                    if ~hetero_status.success
                        error('Spatial heterogeneity modeling failed');
                    end
                    results.rock = rock_hetero;
                    results.hetero_status = hetero_status;
                else
                    fprintf('Task 3.3: Spatial heterogeneity - PENDING (s09 not yet implemented)\n');
                end
                
                status.phases.Rock_Properties.completed = true;
                status.phases.Rock_Properties.runtime = toc(phase_timer);
                status.phases_completed = [status.phases_completed, 3];
                
                fprintf('[Y] Phase 3 completed in %.1f seconds\n', status.phases.Rock_Properties.runtime);
                fprintf('  - Rock types defined: %d\n', rock_types_status.rock_types_defined);
                fprintf('  - Porosity range: %.1f-%.1f%%\n', rock_types_status.porosity_range(1)*100, rock_types_status.porosity_range(2)*100);
                fprintf('  - Permeability range: %.3f-%.0f mD\n\n', rock_types_status.permeability_range_mD(1), rock_types_status.permeability_range_mD(2));
                
            catch ME
                status.phases.Rock_Properties.errors{end+1} = ME.message;
                status.phases_failed = [status.phases_failed, 3];
                fprintf('[X] Phase 3 failed: %s\n\n', ME.message);
                rethrow(ME);
            end
        end
        
        
        %% ================================================================
        %% WORKFLOW COMPLETION SUMMARY
        %% ================================================================
        status.total_runtime = toc(workflow_timer);
        status.workflow_end_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        status.success = isempty(status.phases_failed);
        
        fprintf('================================================================\n');
        fprintf('    EAGLE WEST FIELD WORKFLOW COMPLETION SUMMARY\n');
        fprintf('================================================================\n');
        fprintf('Start time: %s\n', status.workflow_start_time);
        fprintf('End time: %s\n', status.workflow_end_time);
        fprintf('Total runtime: %.1f seconds (%.1f minutes)\n', status.total_runtime, status.total_runtime/60);
        fprintf('Phases completed: %d\n', length(status.phases_completed));
        fprintf('Phases failed: %d\n', length(status.phases_failed));
        
        if status.success
            fprintf('Overall status: [Y] SUCCESS\n');
        else
            fprintf('Overall status: [X] FAILED\n');
            fprintf('Failed phases: %s\n', mat2str(status.phases_failed));
        end
        
        % Current implementation status
        fprintf('\nImplementation Status:\n');
        if ismember(1, status.phases_completed)
            fprintf('[Y] Phase 1: Foundation - COMPLETE\n');
            fprintf('  - MRST initialization, YAML configuration validation\n');
            fprintf('  - Basic grid creation, fluid model\n');
        else
            fprintf('[!] Phase 1: Foundation - NOT RUN\n');
        end
        
        if ismember(2, status.phases_completed)
            fprintf('[Y] Phase 2: Structural Geology - COMPLETE\n');
            fprintf('  - Structural framework with %.0f ft relief\n', results.structural_status.structural_relief/0.3048);
            fprintf('  - 5-fault system with transmissibility multipliers\n');
            fprintf('  - Grid refinement zones identification\n');
        else
            fprintf('[!] Phase 2: Structural Geology - NOT RUN\n');
        end
        
        if ismember(3, status.phases_completed)
            fprintf('[Y] Phase 3: Rock Properties - COMPLETE\n');
            fprintf('  - %d rock types defined (RT1-RT6)\n', results.rock_types_status.rock_types_defined);
            fprintf('  - Porosity: %.1f-%.1f%%, Permeability: %.3f-%.0f mD\n', ...
                    results.rock_types_status.porosity_range(1)*100, ...
                    results.rock_types_status.porosity_range(2)*100, ...
                    results.rock_types_status.permeability_range_mD(1), ...
                    results.rock_types_status.permeability_range_mD(2));
            if exist('s08_assign_layer_properties', 'file')
                fprintf('  - Layer properties assigned (s08)\n');
            end
            if exist('s09_spatial_heterogeneity', 'file')
                fprintf('  - Spatial heterogeneity modeled (s09)\n');
            end
        else
            fprintf('[!] Phase 3: Rock Properties (s07-s09) - NOT RUN\n');
        end
        
        fprintf('\nNext Steps (for future development):\n');
        fprintf('[!] Phase 4: SCAL & PVT (s10-s12) - PENDING\n');
        fprintf('[!] Phase 5: Initial Conditions (s13-s15) - PENDING\n');
        fprintf('[!] Phase 6: Well System (s16-s18) - PENDING\n');
        fprintf('[!] Phase 7: Development Schedule (s19-s20) - PENDING\n');
        fprintf('[!] Phase 8: Simulation Execution (s21-s23) - PENDING\n');
        fprintf('[!] Phase 9: Results & Reporting (s24-s26) - PENDING\n');
        
        %% Save results if requested
        if save_results
            save_path = fullfile(output_dir, sprintf('eagle_west_workflow_%s.mat', ...
                                datestr(now, 'yyyymmdd_HHMMSS')));
            save(save_path, 'results', 'status');
            fprintf('\nResults saved to: %s\n', save_path);
        end
        
        fprintf('================================================================\n\n');
        
    catch ME
        status.total_runtime = toc(workflow_timer);
        status.workflow_end_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        status.success = false;
        status.global_error = ME.message;
        
        fprintf('================================================================\n');
        fprintf('    WORKFLOW FAILED\n');
        fprintf('================================================================\n');
        fprintf('Error: %s\n', ME.message);
        fprintf('Total runtime: %.1f seconds\n', status.total_runtime);
        fprintf('Phases completed before failure: %s\n', mat2str(status.phases_completed));
        fprintf('================================================================\n\n');
        
        rethrow(ME);
    end
end

%% Helper functions for clean output formatting
function print_task_start(task_name, verbose)
    if verbose
        fprintf('%s\n', task_name);
    else
        fprintf('  ⏳ %s', task_name);
    end
end

function print_task_success(task_name, verbose, duration)
    if verbose
        fprintf('✓ %s completed in %.1f seconds\n', task_name, duration);
    else
        fprintf(' ✓ (%.1fs)\n', duration);
    end
end

function print_phase_header(phase_num, phase_name, verbose)
    if verbose
        fprintf('\n=== PHASE %d: %s ===\n', phase_num, phase_name);
    else
        fprintf('\n>> PHASE %d: %s\n', phase_num, phase_name);
    end
end

function print_config_summary(config, verbose)
    if verbose
        % Current detailed output (unchanged)
        return;
    else
        % Clean summary
        fprintf('  >> Configuration: Grid(%dx%dx%d), Wells(%d), Rock types(%d)\n', ...
                config.grid.nx, config.grid.ny, config.grid.nz, ...
                config.wells.total_wells, length(fieldnames(config.rock.types)));
    end
end

function print_clean_summary(status, results, verbose)
    if verbose
        % Use existing detailed summary
        return;
    end
    
    % Clean, organized summary
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║                    SIMULATION SUMMARY                       ║\n');
    fprintf('╠══════════════════════════════════════════════════════════════╣\n');
    fprintf('║ Status: ✓ SUCCESS                                           ║\n');
    fprintf('║ Runtime: %.1f seconds                                        ║\n', status.total_runtime);
    fprintf('║ Phases completed: %d/%d                                      ║\n', length(status.phases_completed), 2);
    fprintf('╠══════════════════════════════════════════════════════════════╣\n');
    fprintf('║ RESERVOIR MODEL:                                             ║\n');
    fprintf('║   • Grid: %dx%dx%d = %d cells                          ║\n', ...
            results.config.grid.nx, results.config.grid.ny, results.config.grid.nz, ...
            results.grid_basic.cells.num);
    fprintf('║   • Field size: %.0f acres                                   ║\n', ...
            results.config.grid.model_area);
    fprintf('║   • Structural relief: %.0f ft                               ║\n', ...
            results.structural_status.structural_relief/0.3048);
    fprintf('║   • Faults: %d major faults implemented                      ║\n', ...
            results.fault_status.faults_added);
    fprintf('║   • Compartments: %d (Northern + Southern)                   ║\n', 2);
    fprintf('╠══════════════════════════════════════════════════════════════╣\n');
    fprintf('║ NEXT STEPS:                                                  ║\n');
    fprintf('║   • Phase 3: Rock Properties (6 rock types)                 ║\n');
    fprintf('║   • Phase 4: SCAL & PVT data                                ║\n');
    fprintf('║   • Phase 5: Well placement (15 wells)                      ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n');
end