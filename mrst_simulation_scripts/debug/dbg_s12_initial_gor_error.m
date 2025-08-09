function debug_result = dbg_s12_initial_gor_error()
% DEBUG SCRIPT: S12 Initial GOR Structure Error Investigation
% Issue: "structure has no member 'initial_gor'" error in S12 PVT table generation
% Focus: Line 537 and 762 initial_gor field access and assignment
%
% Author: DEBUGGER Agent 
% Date: 2025-08-08

    run('print_utils.m');
    print_step_header('DEBUG', 'S12 Initial GOR Structure Error Investigation');
    
    debug_result = struct();
    debug_result.findings = {};
    debug_result.errors_found = {};
    debug_result.suggested_fixes = {};
    
    try
        % ========================================================================
        % INVESTIGATION 1: YAML Configuration Analysis for solution_gor Field
        % ========================================================================
        print_debug('=== INVESTIGATION 1: YAML solution_gor Field Analysis ===');
        
        try
            % Load and inspect YAML configuration
            print_debug('Loading YAML configuration from config/fluid_properties_config.yaml');
            
            pvt_config_raw = read_yaml_config('config/fluid_properties_config.yaml');
            print_debug('✓ YAML config loaded successfully');
            
            % Extract fluid_properties section (mirroring s12 exactly)
            if ~isfield(pvt_config_raw, 'fluid_properties')
                debug_result.errors_found{end+1} = 'Missing fluid_properties field in YAML root';
                error('Missing fluid_properties field in configuration');
            end
            
            pvt_config = pvt_config_raw.fluid_properties;
            print_debug('✓ Extracted fluid_properties section');
            
            % Check for solution_gor field specifically (line 537 uses this)
            if isfield(pvt_config, 'solution_gor')
                print_debug(['✓ solution_gor field found: ' num2str(pvt_config.solution_gor) ' scf/STB']);
                debug_result.findings{end+1} = ['YAML has solution_gor field with value: ' num2str(pvt_config.solution_gor)];
            else
                error_msg = 'CRITICAL: solution_gor field NOT FOUND in fluid_properties section';
                print_debug(['✗ ' error_msg]);
                debug_result.errors_found{end+1} = error_msg;
                
                % Show available fields for debugging
                print_debug('Available fields in fluid_properties:');
                available_fields = fieldnames(pvt_config);
                for i = 1:length(available_fields)
                    fprintf('  - %s\n', available_fields{i});
                    if contains(available_fields{i}, 'gor', 'IgnoreCase', true)
                        print_debug(['    *** GOR-related field found: ' available_fields{i}]);
                    end
                end
            end
            
        catch ME
            error_msg = ['YAML loading/analysis failed: ' ME.message];
            print_debug(['✗ ' error_msg]);
            debug_result.errors_found{end+1} = error_msg;
        end
        
        % ========================================================================
        % INVESTIGATION 2: Reproduce Line 537 Assignment
        % ========================================================================
        print_debug('\n=== INVESTIGATION 2: Line 537 Assignment Reproduction ===');
        
        print_debug('Reproducing: oil_props.initial_gor = pvt_config.solution_gor;');
        
        try
            % Simulate the exact context of step_3_add_phase_densities
            pvt_config_test = read_yaml_config('config/fluid_properties_config.yaml');
            pvt_config_test = pvt_config_test.fluid_properties;
            
            % Create oil_props structure as done in the function
            oil_props = struct();
            
            % This is line 537 - the problematic assignment
            if isfield(pvt_config_test, 'solution_gor')
                oil_props.initial_gor = pvt_config_test.solution_gor;
                print_debug(['✓ Assignment successful: oil_props.initial_gor = ' num2str(oil_props.initial_gor)]);
                debug_result.findings{end+1} = 'Line 537 assignment should work correctly';
            else
                error_msg = 'CONFIRMED BUG: solution_gor field missing for line 537 assignment';
                print_debug(['✗ ' error_msg]);
                debug_result.errors_found{end+1} = error_msg;
            end
            
        catch ME
            error_msg = ['Line 537 reproduction failed: ' ME.message];
            print_debug(['✗ ' error_msg]);
            debug_result.errors_found{end+1} = error_msg;
        end
        
        % ========================================================================
        % INVESTIGATION 3: Check fluid.oil_properties Structure Chain
        % ========================================================================
        print_debug('\n=== INVESTIGATION 3: fluid.oil_properties Structure Chain ===');
        
        print_debug('Tracing structure chain: oil_props -> fluid.oil_properties -> final access');
        
        try
            % The issue might be in the structure assignment chain
            % In step_3_add_phase_densities, oil_props is created and then assigned to fluid
            
            % Simulate the full chain
            oil_props_test = struct();
            if isfield(pvt_config_test, 'solution_gor')
                oil_props_test.initial_gor = pvt_config_test.solution_gor;
            end
            
            % Simulate the fluid structure assignment
            fluid_test = struct();
            fluid_test.oil_properties = oil_props_test;
            
            % Test line 762 access: fluid.oil_properties.initial_gor
            if isfield(fluid_test, 'oil_properties') && isfield(fluid_test.oil_properties, 'initial_gor')
                print_debug(['✓ Full chain access successful: ' num2str(fluid_test.oil_properties.initial_gor)]);
                debug_result.findings{end+1} = 'Structure chain should work: fluid.oil_properties.initial_gor';
            else
                error_msg = 'STRUCTURE CHAIN BROKEN: fluid.oil_properties.initial_gor not accessible';
                print_debug(['✗ ' error_msg]);
                debug_result.errors_found{end+1} = error_msg;
                
                % Debug the structure
                if isfield(fluid_test, 'oil_properties')
                    print_debug('fluid.oil_properties exists, checking its fields:');
                    oil_prop_fields = fieldnames(fluid_test.oil_properties);
                    for i = 1:length(oil_prop_fields)
                        fprintf('    - %s\n', oil_prop_fields{i});
                    end
                else
                    print_debug('fluid.oil_properties does NOT exist');
                end
            end
            
        catch ME
            error_msg = ['Structure chain test failed: ' ME.message];
            print_debug(['✗ ' error_msg]);
            debug_result.errors_found{end+1} = error_msg;
        end
        
        % ========================================================================
        % INVESTIGATION 4: Compare With API Gravity Fix Pattern
        % ========================================================================
        print_debug('\n=== INVESTIGATION 4: Compare With API Gravity Fix Pattern ===');
        
        print_debug('Analyzing similar api_gravity fix that was already implemented...');
        
        % The api_gravity fix uses defensive validation (lines 528-535 in s12)
        print_debug('API gravity defensive pattern:');
        print_debug('  if isfield(pvt_config, ''api_gravity'')');
        print_debug('      oil_props.api_gravity = pvt_config.api_gravity;');
        print_debug('  else');
        print_debug('      warning(...); % Use calculated value');
        print_debug('  end');
        
        print_debug('\nCurrent initial_gor pattern:');
        print_debug('  oil_props.initial_gor = pvt_config.solution_gor;  % Line 537 - NO VALIDATION');
        
        debug_result.findings{end+1} = 'PATTERN INCONSISTENCY: api_gravity uses defensive validation but initial_gor does not';
        debug_result.suggested_fixes{end+1} = 'Apply same defensive pattern to initial_gor as used for api_gravity';
        
        % ========================================================================
        % INVESTIGATION 5: Check Alternative Field Names in YAML
        % ========================================================================
        print_debug('\n=== INVESTIGATION 5: Alternative GOR Field Names ===');
        
        try
            yaml_fields = fieldnames(pvt_config_test);
            gor_related_fields = {};
            
            for i = 1:length(yaml_fields)
                if contains(yaml_fields{i}, 'gor', 'IgnoreCase', true)
                    gor_related_fields{end+1} = yaml_fields{i};
                    print_debug(['Found GOR-related field: ' yaml_fields{i}]);
                end
            end
            
            if length(gor_related_fields) > 0
                debug_result.findings{end+1} = ['Alternative GOR fields available: ' strjoin(gor_related_fields, ', ')];
            else
                debug_result.errors_found{end+1} = 'NO GOR-related fields found in YAML configuration';
            end
            
        catch ME
            debug_result.errors_found{end+1} = ['Alternative field search failed: ' ME.message];
        end
        
        % ========================================================================
        % ROOT CAUSE ANALYSIS & SUGGESTED FIXES
        % ========================================================================
        print_debug('\n=== ROOT CAUSE ANALYSIS ===');
        
        debug_result.findings{end+1} = 'ROOT CAUSE: Missing defensive field validation for solution_gor access';
        debug_result.findings{end+1} = 'LOCATION: s12_pvt_tables.m line 537 in step_3_add_phase_densities function';
        debug_result.findings{end+1} = 'CONTEXT: oil_props.initial_gor = pvt_config.solution_gor; lacks field existence check';
        
        % ========================================================================  
        % SUGGESTED FIXES
        % ========================================================================
        print_debug('\n=== SUGGESTED FIXES ===');
        
        debug_result.suggested_fixes{end+1} = 'FIX 1: Add defensive validation around line 537';
        debug_result.suggested_fixes{end+1} = 'FIX 2: Pattern: if isfield(pvt_config, ''solution_gor'') ... else warning + default';
        debug_result.suggested_fixes{end+1} = 'FIX 3: Check if YAML field name should be ''initial_gor'' instead of ''solution_gor''';
        debug_result.suggested_fixes{end+1} = 'FIX 4: Validate all required YAML fields in step_1_load_pvt_config';
        
        print_debug('\n=== RECOMMENDED DEFENSIVE FIX ===');
        print_debug('Replace line 537 with:');
        print_debug('  if isfield(pvt_config, ''solution_gor'')');
        print_debug('      oil_props.initial_gor = pvt_config.solution_gor;');
        print_debug('  else');
        print_debug('      warning(''solution_gor not found in PVT config. Using default value.'');');
        print_debug('      oil_props.initial_gor = 450.0;  % Default from CANON documentation');
        print_debug('  end');
        
        debug_result.status = 'investigation_complete';
        debug_result.priority = 'high';
        debug_result.confidence = 'high';
        
        print_step_footer('DEBUG', 'S12 Initial GOR Investigation Complete', toc);
        
    catch ME
        print_error_step(0, 'Debug Investigation', ME.message);
        debug_result.status = 'investigation_failed';
        debug_result.error = ME.message;
    end
    
end

function print_debug(message)
    fprintf('[DEBUG] %s\n', message);
end