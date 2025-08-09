function debug_result = dbg_s12_exact_error()
% DEBUG SCRIPT: S12 Exact Error Reproduction
% Purpose: Reproduce the exact api_gravity error by running actual s12 code path
% 
% Author: DEBUGGER Agent
% Date: 2025-08-08

    run('print_utils.m');
    fprintf('=== S12 EXACT ERROR REPRODUCTION DEBUG ===\n');
    
    debug_result = struct();
    debug_result.findings = {};
    debug_result.actual_error = '';
    debug_result.root_cause = '';
    
    try
        % ========================================================================
        % TEST 1: Run the exact s12 step that fails
        % ========================================================================
        fprintf('\n[DEBUG] TEST 1: Running exact s12 failure path...\n');
        
        % Try to run s12_pvt_tables and catch the exact error
        try
            fprintf('[DEBUG] Attempting to call s12_pvt_tables()...\n');
            fluid_complete = s12_pvt_tables();
            fprintf('[DEBUG] ✓ s12_pvt_tables() completed successfully!\n');
            debug_result.findings{end+1} = 'UNEXPECTED: s12_pvt_tables ran without api_gravity error';
            
        catch ME
            fprintf('[DEBUG] ✗ s12_pvt_tables() failed with error:\n');
            fprintf('[DEBUG] Error message: %s\n', ME.message);
            fprintf('[DEBUG] Error identifier: %s\n', ME.identifier);
            
            % Parse the error message for specific issues
            if contains(ME.message, 'api_gravity')
                fprintf('[DEBUG] ✓ Confirmed: api_gravity error detected\n');
                debug_result.actual_error = ME.message;
                debug_result.root_cause = 'api_gravity field access failure';
            elseif contains(ME.message, 'structure has no member')
                fprintf('[DEBUG] ✓ Confirmed: structure member access error\n');
                debug_result.actual_error = ME.message;
                debug_result.root_cause = 'structure field missing';
            else
                fprintf('[DEBUG] Different error than expected: %s\n', ME.message);
                debug_result.actual_error = ME.message;
                debug_result.root_cause = 'other_error';
            end
            
            % Show the stack trace to pinpoint exact location
            fprintf('[DEBUG] Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('[DEBUG]   %s at line %d\n', ME.stack(i).name, ME.stack(i).line);
            end
        end
        
        % ========================================================================
        % TEST 2: Manually test the problematic function calls
        % ========================================================================
        fprintf('\n[DEBUG] TEST 2: Manual test of s12 individual steps...\n');
        
        try
            % Step 1: Load PVT config (this should work)
            fprintf('[DEBUG] Testing step_1_load_pvt_config equivalent...\n');
            pvt_config = read_yaml_config('config/fluid_properties_config.yaml');
            
            if ~isfield(pvt_config, 'fluid_properties')
                error('Missing fluid_properties field in configuration');
            end
            
            pvt_config = pvt_config.fluid_properties;
            fprintf('[DEBUG] ✓ PVT config loaded successfully\n');
            
            % Show all available fields
            fprintf('[DEBUG] Available pvt_config fields:\n');
            field_names = fieldnames(pvt_config);
            for i = 1:length(field_names)
                fprintf('[DEBUG]   - %s\n', field_names{i});
            end
            
            % Test the specific api_gravity access
            fprintf('[DEBUG] Testing api_gravity access...\n');
            if isfield(pvt_config, 'api_gravity')
                api_val = pvt_config.api_gravity;
                fprintf('[DEBUG] ✓ api_gravity = %g\n', api_val);
            else
                fprintf('[DEBUG] ✗ api_gravity field NOT FOUND\n');
                error('api_gravity field missing from pvt_config');
            end
            
        catch ME
            fprintf('[DEBUG] ✗ Manual step test failed: %s\n', ME.message);
            debug_result.findings{end+1} = ['Manual test error: ' ME.message];
        end
        
        % ========================================================================
        % TEST 3: Test fluid loading prerequisite
        % ========================================================================
        fprintf('\n[DEBUG] TEST 3: Testing s11 prerequisite (fluid_with_pc)...\n');
        
        script_path = fileparts(mfilename('fullpath'));
        data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
        fluid_file = fullfile(data_dir, 'fluid_with_capillary_pressure.mat');
        
        fprintf('[DEBUG] Looking for fluid file: %s\n', fluid_file);
        
        if exist(fluid_file, 'file')
            fprintf('[DEBUG] ✓ Fluid file exists\n');
            try
                load(fluid_file, 'fluid_with_pc', 'G');
                fprintf('[DEBUG] ✓ Fluid file loaded successfully\n');
                
                % Check fluid structure
                if exist('fluid_with_pc', 'var')
                    fprintf('[DEBUG] ✓ fluid_with_pc variable loaded\n');
                else
                    fprintf('[DEBUG] ✗ fluid_with_pc variable missing from file\n');
                end
                
                if exist('G', 'var') 
                    fprintf('[DEBUG] ✓ G (grid) variable loaded\n');
                else
                    fprintf('[DEBUG] ✗ G (grid) variable missing from file\n');
                end
                
            catch ME
                fprintf('[DEBUG] ✗ Failed to load fluid file: %s\n', ME.message);
                debug_result.findings{end+1} = ['Fluid file load error: ' ME.message];
            end
        else
            fprintf('[DEBUG] ✗ Fluid file does not exist - s11 not run yet\n');
            debug_result.findings{end+1} = 'Prerequisite s11_capillary_pressure.m not executed';
        end
        
        % ========================================================================
        % ROOT CAUSE SUMMARY
        % ========================================================================
        fprintf('\n=== ROOT CAUSE SUMMARY ===\n');
        
        if isempty(debug_result.actual_error)
            fprintf('[RESULT] No api_gravity error reproduced - may be intermittent or fixed\n');
        else
            fprintf('[RESULT] Confirmed error: %s\n', debug_result.actual_error);
            fprintf('[RESULT] Root cause: %s\n', debug_result.root_cause);
        end
        
        % Show specific recommendations
        fprintf('\n=== RECOMMENDATIONS ===\n');
        fprintf('1. Check if s11_capillary_pressure.m was executed successfully\n');
        fprintf('2. Verify YAML configuration structure is properly loaded\n');
        fprintf('3. Fix variable name mismatch in save operation (line 719)\n'); 
        fprintf('4. Add field validation before accessing api_gravity\n');
        
    catch ME
        fprintf('[DEBUG] Debug script failed: %s\n', ME.message);
        debug_result.findings{end+1} = ['Debug script error: ' ME.message];
    end
    
    fprintf('\n=== DEBUG INVESTIGATION COMPLETE ===\n');
    
end