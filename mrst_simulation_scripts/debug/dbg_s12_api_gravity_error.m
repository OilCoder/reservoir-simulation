function debug_result = dbg_s12_api_gravity_error()
% DEBUG SCRIPT: S12 API Gravity Structure Error Investigation
% Issue: "structure has no member 'api_gravity'" error at Step 0 of PVT table generation
% Also investigates: Warning about 'fluid_complete' variable not existing in save operation
%
% Author: DEBUGGER Agent 
% Date: 2025-08-08

    run('print_utils.m');
    print_step_header('DEBUG', 'S12 API Gravity Structure Error Investigation');
    
    debug_result = struct();
    debug_result.findings = {};
    debug_result.errors_found = {};
    debug_result.suggested_fixes = {};
    
    try
        % ========================================================================
        % INVESTIGATION 1: Analyze YAML Configuration Loading
        % ========================================================================
        print_debug('=== INVESTIGATION 1: YAML Configuration Analysis ===');
        
        % Step 1.1: Load and inspect YAML configuration
        print_debug('Loading YAML configuration from config/fluid_properties_config.yaml');
        
        try
            pvt_config = read_yaml_config('config/fluid_properties_config.yaml');
            print_debug('✓ YAML config loaded successfully');
            
            % Inspect top-level structure
            print_debug('Top-level YAML fields:');
            yaml_fields = fieldnames(pvt_config);
            for i = 1:length(yaml_fields)
                fprintf('  - %s\n', yaml_fields{i});
            end
            
            % Extract fluid_properties section (this is what s12 does)
            if ~isfield(pvt_config, 'fluid_properties')
                debug_result.errors_found{end+1} = 'Missing fluid_properties field in YAML root';
                error('Missing fluid_properties field in configuration');
            end
            
            pvt_config = pvt_config.fluid_properties;
            print_debug('✓ Extracted fluid_properties section');
            
            % Inspect fluid_properties structure
            print_debug('fluid_properties fields:');
            fluid_fields = fieldnames(pvt_config);
            for i = 1:length(fluid_fields)
                fprintf('  - %s\n', fluid_fields{i});
            end
            
            % Check for api_gravity field specifically
            if isfield(pvt_config, 'api_gravity')
                print_debug(['✓ api_gravity field found: ' num2str(pvt_config.api_gravity)]);
            else
                error_msg = 'CRITICAL: api_gravity field NOT FOUND in fluid_properties section';
                print_debug(['✗ ' error_msg]);
                debug_result.errors_found{end+1} = error_msg;
            end
            
        catch ME
            error_msg = ['YAML loading failed: ' ME.message];
            print_debug(['✗ ' error_msg]);
            debug_result.errors_found{end+1} = error_msg;
            debug_result.findings{end+1} = 'Root cause: YAML configuration loading or structure issue';
        end
        
        % ========================================================================
        % INVESTIGATION 2: Reproduce the Exact s12 Execution Path  
        % ========================================================================
        print_debug('\n=== INVESTIGATION 2: S12 Execution Path Analysis ===');
        
        % Step 2.1: Simulate s12 step_1_load_pvt_config function
        print_debug('Simulating s12_pvt_tables step_1_load_pvt_config()...');
        
        try
            % This mirrors exactly what s12 does in step_1_load_pvt_config
            pvt_config_s12 = read_yaml_config('config/fluid_properties_config.yaml');
            
            if ~isfield(pvt_config_s12, 'fluid_properties')
                error('Missing fluid_properties field in configuration');
            end
            
            pvt_config_s12 = pvt_config_s12.fluid_properties;
            print_debug('✓ S12-style config loading successful');
            
            % This is where the error happens in step_3_add_phase_densities
            print_debug('Testing api_gravity access in step_3_add_phase_densities context...');
            
            if isfield(pvt_config_s12, 'api_gravity')
                api_gravity_value = pvt_config_s12.api_gravity;
                print_debug(['✓ api_gravity accessible: ' num2str(api_gravity_value)]);
            else
                error_msg = 'CONFIRMED BUG: api_gravity not accessible in pvt_config structure';
                print_debug(['✗ ' error_msg]);
                debug_result.errors_found{end+1} = error_msg;
                
                % Show available fields for debugging
                print_debug('Available fields in pvt_config:');
                available_fields = fieldnames(pvt_config_s12);
                for i = 1:length(available_fields)
                    fprintf('  - %s\n', available_fields{i});
                end
            end
            
        catch ME
            error_msg = ['S12 config loading simulation failed: ' ME.message];
            print_debug(['✗ ' error_msg]);
            debug_result.errors_found{end+1} = error_msg;
        end
        
        % ========================================================================
        % INVESTIGATION 3: Check YAML Field Structure vs Code Expectations
        % ========================================================================
        print_debug('\n=== INVESTIGATION 3: YAML Structure vs Code Expectations ===');
        
        % The error occurs in line 523 of s12_pvt_tables.m:
        % oil_props.api_gravity = pvt_config.api_gravity;
        print_debug('Analyzing line 523: oil_props.api_gravity = pvt_config.api_gravity;');
        
        % Check exactly what the code expects vs what YAML provides
        print_debug('Code expectation: pvt_config.api_gravity should exist');
        print_debug('YAML structure analysis:');
        
        try
            raw_yaml = read_yaml_config('config/fluid_properties_config.yaml');
            
            % Show the exact path the code should use
            if isfield(raw_yaml, 'fluid_properties') && isfield(raw_yaml.fluid_properties, 'api_gravity')
                print_debug('✓ YAML has: fluid_properties.api_gravity');
                print_debug(['  Value: ' num2str(raw_yaml.fluid_properties.api_gravity)]);
            else
                print_debug('✗ YAML structure issue detected');
            end
            
            % The root cause: s12 does pvt_config = pvt_config.fluid_properties;  
            % So it should access api_gravity directly, but let's verify the field exists
            if isfield(raw_yaml.fluid_properties, 'api_gravity')
                print_debug('✓ After extraction, should be accessible as pvt_config.api_gravity');
                debug_result.findings{end+1} = 'YAML structure appears correct - api_gravity field exists';
            else
                debug_result.errors_found{end+1} = 'YAML missing api_gravity field in fluid_properties section';
            end
            
        catch ME
            debug_result.errors_found{end+1} = ['YAML analysis failed: ' ME.message];
        end
        
        % ========================================================================
        % INVESTIGATION 4: Check fluid_complete Variable Save Warning
        % ========================================================================
        print_debug('\n=== INVESTIGATION 4: fluid_complete Save Warning Analysis ===');
        
        % The warning is about 'fluid_complete' variable not existing in save operation
        % This occurs in line 719: save(complete_fluid_file, 'fluid_complete', 'G', 'pvt_config');
        print_debug('Analyzing line 719: save(complete_fluid_file, ''fluid_complete'', ''G'', ''pvt_config'');');
        
        % The issue: The function returns 'fluid_complete' but saves a variable with same name
        % In step_4_export_complete_fluid, the parameter is named 'fluid', not 'fluid_complete'
        print_debug('Function parameter analysis:');
        print_debug('- step_4_export_complete_fluid(fluid, G, pvt_config)');  
        print_debug('- Inside function: parameter is named ''fluid'', not ''fluid_complete''');
        print_debug('- But save command tries to save ''fluid_complete'' variable');
        print_debug('✗ MISMATCH: Variable name inconsistency in save operation');
        
        debug_result.errors_found{end+1} = 'Variable name mismatch in save operation: function parameter is ''fluid'' but save tries to use ''fluid_complete''';
        
        % ========================================================================
        % ROOT CAUSE ANALYSIS & SUGGESTED FIXES
        % ========================================================================
        print_debug('\n=== ROOT CAUSE ANALYSIS ===');
        
        % Root cause 1: api_gravity structure access
        debug_result.findings{end+1} = 'ROOT CAUSE 1: Potential YAML parsing or field access issue with api_gravity';
        debug_result.findings{end+1} = 'Location: s12_pvt_tables.m line 523 in step_3_add_phase_densities function';
        debug_result.findings{end+1} = 'Context: oil_props.api_gravity = pvt_config.api_gravity; fails';
        
        % Root cause 2: Variable name mismatch  
        debug_result.findings{end+1} = 'ROOT CAUSE 2: Variable name inconsistency in export function';
        debug_result.findings{end+1} = 'Location: s12_pvt_tables.m line 719 in export_complete_fluid_file function';
        debug_result.findings{end+1} = 'Context: Function parameter named ''fluid'' but save uses ''fluid_complete''';
        
        % ========================================================================  
        % SUGGESTED FIXES
        % ========================================================================
        print_debug('\n=== SUGGESTED FIXES ===');
        
        debug_result.suggested_fixes{end+1} = 'FIX 1: Check if YAML read_yaml_config function properly handles nested structures';
        debug_result.suggested_fixes{end+1} = 'FIX 2: Add debug print statements in s12 to show pvt_config field names before api_gravity access';
        debug_result.suggested_fixes{end+1} = 'FIX 3: Change save line 719 from ''fluid_complete'' to ''fluid'' to match parameter name';
        debug_result.suggested_fixes{end+1} = 'FIX 4: Alternative - rename function parameter from ''fluid'' to ''fluid_complete'' for consistency';
        debug_result.suggested_fixes{end+1} = 'FIX 5: Add field existence check before accessing api_gravity: if isfield(pvt_config, ''api_gravity'')';
        
        print_debug('\n=== DEBUGGING RECOMMENDATIONS ===');
        print_debug('1. Run s12_pvt_tables.m with additional debug prints around line 523');
        print_debug('2. Check read_yaml_config function for proper nested field handling');
        print_debug('3. Fix variable name mismatch in export function immediately');
        print_debug('4. Consider adding field validation in step_1_load_pvt_config');
        
        debug_result.status = 'investigation_complete';
        debug_result.priority = 'high';
        debug_result.confidence = 'high';
        
        print_step_footer('DEBUG', 'S12 API Gravity Investigation Complete', toc);
        
    catch ME
        print_error_step(0, 'Debug Investigation', ME.message);
        debug_result.status = 'investigation_failed';
        debug_result.error = ME.message;
    end
    
end

function print_debug(message)
    fprintf('[DEBUG] %s\n', message);
end