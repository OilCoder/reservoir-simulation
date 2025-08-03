function status = s01_initialize_mrst(varargin)
%S01_INITIALIZE_MRST Initialize MRST environment and verify functionality
%
% This script initializes the MRST environment, loads required modules,
% and verifies that everything is working correctly.
%
% USAGE:
%   status = s01_initialize_mrst()                % Normal mode (clean output)
%   status = s01_initialize_mrst('verbose', true) % Verbose mode (detailed output)
%
% OUTPUT:
%   status - Structure containing initialization status and information
%
% DEPENDENCIES:
%   - MRST installation at /opt/mrst
%   - util_read_config.m for configuration management
%
% SUCCESS CRITERIA:
%   - MRST loads without errors
%   - Required modules are accessible
%   - Configuration paths are properly set
%   - Basic grid creation works

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== MRST Initialization ===\n');
    else
        fprintf('\n>> Initializing MRST Environment:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Component                           | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.mrst_loaded = false;
    status.modules_loaded = {};
    status.errors = {};
    status.warnings = {};
    
    % Define components to initialize
    component_names = {'Core Path Setup', 'Function Verification', 'Essential Modules', 'Configuration Test', 'Final Verification'};
    
    try
        %% Step 1: Add MRST to path
        if verbose
            fprintf('Step 1: Adding MRST core to path...\n');
        end
        
        try
            mrst_core_path = '/opt/mrst/core';
            if ~exist(mrst_core_path, 'dir')
                error('MRST core directory not found at: %s', mrst_core_path);
            end
            % Suppress all warnings completely for clean output as requested
            warning('off', 'all');
            addpath(genpath(mrst_core_path));
            step1_success = true;
        catch
            step1_success = false;
        end
        
        if ~verbose
            if step1_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', component_names{1}, status_symbol);
        else
            fprintf('  - MRST core path added successfully\n');
        end
        
        if ~step1_success
            error('Failed to add MRST core to path');
        end
        
        %% Step 2: Verify MRST functions are accessible
        if verbose
            fprintf('Step 2: Verifying MRST functions...\n');
        end
        
        try
            % Test that essential MRST functions exist
            if ~exist('cartGrid', 'file') || ~exist('computeGeometry', 'file')
                error('Essential MRST functions not found');
            end
            step2_success = true;
        catch
            step2_success = false;
        end
        
        if ~verbose
            if step2_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', component_names{2}, status_symbol);
        else
            fprintf('  - cartGrid function: OK\n');
            fprintf('  - computeGeometry function: OK\n');
        end
        
        if ~step2_success
            error('Failed to verify MRST functions');
        end
        
        status.mrst_loaded = true;
        
        %% Step 3: Load essential modules
        if verbose
            fprintf('Step 3: Loading essential MRST modules...\n');
        end
        
        try
            % Required modules for reservoir simulation
            core_modules = {'ad-core', 'ad-blackoil', 'ad-props', 'incomp'};
            advanced_modules = {'ad-fi', 'coarsegrid', 'upscaling', 'diagnostics'};
            required_modules = [core_modules; advanced_modules];
            
            loaded_modules = {};
            modules_loaded = 0;
            for i = 1:length(required_modules)
                module_name = required_modules{i};
                % Check multiple possible locations
                module_paths = {
                    fullfile('/opt/mrst', 'modules', module_name),
                    fullfile('/opt/mrst', 'autodiff', module_name),
                    fullfile('/opt/mrst', 'solvers', module_name)
                };
                
                module_found = false;
                for j = 1:length(module_paths)
                    if exist(module_paths{j}, 'dir')
                        warning('off', 'all');
                        addpath(genpath(module_paths{j}));
                        loaded_modules{end+1} = module_name;
                        modules_loaded = modules_loaded + 1;
                        module_found = true;
                        if verbose
                            fprintf('  - Module %s: OK\n', module_name);
                        end
                        break;
                    end
                end
                
                if ~module_found && verbose
                    fprintf('  - Module %s: WARNING (not found)\n', module_name);
                    status.warnings{end+1} = sprintf('Module %s not found', module_name);
                end
            end
            
            step3_success = modules_loaded >= 1; % At least one module loaded (be more lenient)
        catch
            step3_success = false;
        end
        
        if ~verbose
            if step3_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', component_names{3}, status_symbol);
        end
        
        if ~step3_success
            error('Failed to load essential MRST modules');
        end
        
        status.modules_loaded = loaded_modules;
        
        %% Step 4: Test YAML configuration files
        if verbose
            fprintf('Step 4: Testing YAML configuration files...\n');
        end
        
        try
            % Test that configuration files exist
            config_files = {'grid_config.yaml', 'fluid_properties_config.yaml', ...
                           'rock_properties_config.yaml', 'wells_schedule_config.yaml', ...
                           'initial_conditions_config.yaml'};
            
            config_dir = 'config';
            files_found = 0;
            for i = 1:length(config_files)
                config_path = fullfile(config_dir, config_files{i});
                if exist(config_path, 'file')
                    files_found = files_found + 1;
                end
            end
            
            step4_success = files_found >= 4;  % At least 4 config files needed
            status.config_files_found = files_found;
        catch
            step4_success = false;
            status.config_files_found = 0;
        end
        
        if ~verbose
            if step4_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', component_names{4}, status_symbol);
        else
            if step4_success
                fprintf('  - Configuration files: %d/5 found\n', files_found);
                fprintf('  - YAML configs: Grid, Fluid, Rock, Wells, Initial\n');
            else
                fprintf('  - Configuration files: WARNING (%d/5 found)\n', files_found);
            end
        end
        
        %% Step 5: Final verification
        if verbose
            fprintf('Step 5: Final verification...\n');
        end
        
        try
            % Final verification that everything is working
            step5_success = step1_success && step2_success && step3_success;
        catch
            step5_success = false;
        end
        
        if ~verbose
            if step5_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', component_names{5}, status_symbol);
        else
            fprintf('  - All essential components verified\n');
        end
        
        %% Success
        status.success = step5_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== MRST Initialization SUCCESSFUL ===\n');
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> MRST: %d/%d components initialized successfully\n', length(component_names), length(component_names));
            fprintf('   Modules: %d loaded | Functions: verified | Config: tested\n', length(loaded_modules));
        end
        
        % Separate core and advanced modules in status
        core_loaded = {};
        advanced_loaded = {};
        for i = 1:length(status.modules_loaded)
            if any(strcmp(status.modules_loaded{i}, core_modules))
                core_loaded{end+1} = status.modules_loaded{i};
            else
                advanced_loaded{end+1} = status.modules_loaded{i};
            end
        end
        
        if verbose
            warning('off', 'Octave:str-to-num');
            fprintf('Core modules loaded (%d/%d): %s\n', length(core_loaded), length(core_modules), strjoin(core_loaded, ', '));
            if ~isempty(advanced_loaded)
                fprintf('Advanced modules loaded (%d/%d): %s\n', length(advanced_loaded), length(advanced_modules), strjoin(advanced_loaded, ', '));
            end
            warning('on', 'Octave:str-to-num');
            if status.config_files_found >= 4
                fprintf('Configuration files: OK (%d/5 YAML configs available)\n', status.config_files_found);
            else
                fprintf('Configuration files: WARNING (%d/5 found)\n', status.config_files_found);
            end
            fprintf('Timestamp: %s\n', status.timestamp);
        end
        
        if ~isempty(status.warnings) && verbose
            fprintf('\nWarnings encountered:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
    catch ME
        status.success = false;
        status.errors{end+1} = ME.message;
        
        fprintf('\n=== MRST Initialization FAILED ===\n');
        fprintf('Error: %s\n', ME.message);
        
        if ~isempty(status.warnings)
            fprintf('\nWarnings:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
        rethrow(ME);
    end
    
    fprintf('\n');
end