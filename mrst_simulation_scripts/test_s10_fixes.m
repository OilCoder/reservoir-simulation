function test_s10_fixes()
% TEST_S10_FIXES - Verify viscosity and wettability warning fixes
% Test script to verify fixes for s10_relative_permeability.m warnings
%
% Expected Results:
% - No "Defaulted viscosity to unit value (1000 centipoise)" warning
% - No "Using default wettability values due to YAML parsing issue" warning
% - Canonical viscosity values loaded: oil=0.92 cp, water=0.385 cp, gas=0.02 cp
% - Wettability successfully loaded from SCAL configuration

    run('print_utils.m');
    
    fprintf('\n=== Testing S10 Viscosity and Wettability Fixes ===\n');
    
    try
        % Test viscosity loading function
        fprintf('\n1. Testing viscosity loading...\n');
        test_viscosity_loading();
        
        % Test wettability loading function
        fprintf('\n2. Testing wettability loading...\n');
        test_wettability_loading();
        
        % Test full fluid initialization
        fprintf('\n3. Testing full fluid initialization...\n');
        fluid = s10_relative_permeability();
        
        % Verify results
        fprintf('\n=== Verification Results ===\n');
        if isfield(fluid, 'mu') && ~isempty(fluid.mu)
            fprintf('✓ Viscosity values properly set\n');
            fprintf('  mu = [%.6f, %.6f, %.6f] Pa·s\n', fluid.mu(1), fluid.mu(2), fluid.mu(3));
        else
            fprintf('✗ Viscosity values missing\n');
        end
        
        if isfield(fluid, 'dominant_wettability')
            fprintf('✓ Wettability properly set: %s\n', fluid.dominant_wettability);
            fprintf('  Contact angle: %.1f degrees\n', fluid.contact_angle);
        else
            fprintf('✗ Wettability information missing\n');
        end
        
        fprintf('\n=== Test Complete ===\n');
        
    catch ME
        fprintf('✗ Test failed with error: %s\n', ME.message);
        fprintf('  Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
    end

end

function test_viscosity_loading()
% Test viscosity configuration loading

    try
        fluid_config = read_yaml_config('config/fluid_properties_config.yaml');
        fluid_props = fluid_config.fluid_properties;
        
        mu_o = fluid_props.oil_viscosity;
        mu_w = fluid_props.water_viscosity;
        mu_g = fluid_props.gas_viscosity;
        
        fprintf('  Loaded viscosities: oil=%.3f cp, water=%.3f cp, gas=%.3f cp\n', mu_o, mu_w, mu_g);
        
        % Verify canonical values
        if abs(mu_o - 0.92) < 0.001 && abs(mu_w - 0.385) < 0.001 && abs(mu_g - 0.02) < 0.001
            fprintf('  ✓ Canonical viscosity values confirmed\n');
        else
            fprintf('  ✗ Viscosity values do not match canonical data\n');
        end
        
    catch ME
        fprintf('  ✗ Failed to load viscosity configuration: %s\n', ME.message);
    end

end

function test_wettability_loading()
% Test wettability configuration loading

    try
        scal_config = read_yaml_config('config/scal_properties_config.yaml');
        scal_props = scal_config.scal_properties;
        
        if isfield(scal_props, 'wettability') && ...
           isfield(scal_props.wettability, 'sandstone') && ...
           isfield(scal_props.wettability.sandstone, 'description')
            
            desc = scal_props.wettability.sandstone.description;
            angle = scal_props.wettability.sandstone.contact_angle;
            
            fprintf('  Loaded wettability: %s (contact angle: %.1f°)\n', desc, angle);
            
            % Verify canonical values
            if strcmp(desc, 'strongly water-wet') && abs(angle - 25.0) < 0.1
                fprintf('  ✓ Canonical wettability values confirmed\n');
            else
                fprintf('  ✗ Wettability values do not match canonical data\n');
            end
        else
            fprintf('  ✗ Wettability structure incomplete or missing\n');
        end
        
    catch ME
        fprintf('  ✗ Failed to load wettability configuration: %s\n', ME.message);
    end

end

% Run test if called as script
if ~nargout
    test_s10_fixes();
end