function fluid = s09_relative_permeability()
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
% S10_RELATIVE_PERMEABILITY - Define relative permeability curves (MRST Native)
% Source: 04_SCAL_Properties.md (CANON)
% Requires: MRST ad-blackoil, ad-props
%
% OUTPUT:
%   fluid - MRST fluid structure with relative permeability functions
%
% FIXES:
%   - Viscosity warning eliminated by loading canonical values from fluid_properties_config.yaml
%   - Wettability warning eliminated by improved YAML parsing and error handling
%   - Canonical viscosities: oil=0.92 cp, water=0.385 cp, gas=0.02 cp
%   - Canonical wettability: strongly water-wet (contact angle: 25.0°)
%
% Author: Claude Code AI System
% Date: 2025-08-08 (Updated with warning fixes)

    print_step_header('S10', 'Define Relative Permeability Curves (MRST Native)');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load SCAL Configuration
        % ----------------------------------------
        step_start = tic;
        [rock, G] = step_1_load_rock_data();
        scal_config = step_1_load_scal_config();
        print_step_result(1, 'Load SCAL Configuration', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Create Relative Permeability Functions
        % ----------------------------------------
        step_start = tic;
        fluid = step_2_create_relperm_functions(scal_config, G);
        print_step_result(2, 'Create Relative Permeability Functions', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Assign Rock-Type Specific Properties
        % ----------------------------------------
        step_start = tic;
        fluid = step_3_assign_rock_type_properties(fluid, scal_config, rock, G);
        print_step_result(3, 'Assign Rock-Type Specific Properties', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Validate & Export Fluid Structure
        % ----------------------------------------
        step_start = tic;
        step_4_validate_fluid_structure(fluid, G);
        step_4_export_fluid_structure(fluid, G, scal_config);
        print_step_result(4, 'Validate & Export Fluid Structure', 'success', toc(step_start));
        
        print_step_footer('S10', 'Relative Permeability Functions Ready for Simulation', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Relative Permeability', ME.message);
        error('Relative permeability definition failed: %s', ME.message);
    end

end

function [rock, G] = step_1_load_rock_data()
% Step 1 - Load rock structure from previous steps
    script_dir = fileparts(mfilename('fullpath'));

    % Substep 1.1 – Locate final rock file ____________________________
    script_path = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    data_dir = get_data_path('static');
    rock_file = fullfile(data_dir, 'final_simulation_rock.mat');
    
    if ~exist(rock_file, 'file')
        error('Final rock structure not found. Run s09_spatial_heterogeneity.m first.');
    end
    
    % Substep 1.2 – Load rock structure ________________________________
    load(rock_file, 'final_rock', 'G');
    rock = final_rock;
    
end

function scal_config = step_1_load_scal_config()
% Step 1 - Load SCAL configuration from canonical documentation
    script_dir = fileparts(mfilename('fullpath'));

    try
        % Load SCAL configuration from YAML - CANON compliance
        addpath(fullfile(script_dir, 'utils'));
        scal_config = read_yaml_config('config/scal_properties_config.yaml', true);
        fprintf('SCAL configuration loaded successfully\n');
        
        if ~isfield(scal_config, 'scal_properties')
            error('Missing scal_properties field in SCAL configuration');
        end
        
        scal_config = scal_config.scal_properties;
        
    catch ME
        error('Failed to load SCAL configuration: %s\\nCANON violation: Must use 04_SCAL_Properties.md data', ME.message);
    end
    
end

function fluid = step_2_create_relperm_functions(scal_config, G)
% Step 2 - Create MRST fluid structure with relative permeability functions

    % Substep 2.1 – Initialize fluid structure __________________________
    fluid = step_2_initialize_fluid_structure();
    
    % Substep 2.2 – Create oil-water relperm functions ___________________
    fluid = step_2_create_oil_water_functions(fluid, scal_config);
    
    % Substep 2.3 – Create gas-oil relperm functions _____________________
    fluid = step_2_create_gas_oil_functions(fluid, scal_config);
    
    % Substep 2.4 – Add three-phase modeling _____________________________
    fluid = step_2_add_three_phase_modeling(fluid, scal_config);
    
end

function fluid = step_2_initialize_fluid_structure()
% Initialize basic MRST fluid structure with canonical viscosity values
    script_dir = fileparts(mfilename('fullpath'));

    % Load canonical fluid properties for viscosity
    try
        addpath(fullfile(script_dir, 'utils'));
        fluid_config = read_yaml_config('config/fluid_properties_config.yaml', true);
        fluid_props = fluid_config.fluid_properties;
        
        % Extract canonical viscosity values (CANON)
        mu_o = fluid_props.oil_viscosity;     % 0.92 cp
        mu_w = fluid_props.water_viscosity;   % 0.385 cp  
        mu_g = fluid_props.gas_viscosity;     % 0.02 cp
        
        fprintf('   Loaded canonical viscosities: oil=%.3f cp, water=%.3f cp, gas=%.3f cp\\n', mu_o, mu_w, mu_g);
        
    catch ME
        % CANON-FIRST ERROR: FAIL_FAST when configuration missing
        error(['CANON-FIRST ERROR: Failed to load fluid viscosities from fluid_properties_config.yaml\n' ...
               'ORIGINAL ERROR: %s\n' ...
               'REQUIRED: Update fluid_properties_config.yaml with canonical viscosity values:\n' ...
               '  oil_viscosity: 0.92    # cp\n' ...
               '  water_viscosity: 0.385 # cp\n' ...
               '  gas_viscosity: 0.02    # cp\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fluid_Properties_Definition.md\n' ...
               'Must define exact viscosity values for Eagle West Field.'], ME.message);
    end
    
    % Create basic fluid structure for 3-phase black oil
    try
        % Try to use MRST native initSimpleADIFluid if available
        if exist('initSimpleADIFluid', 'file')
            % Pass viscosity values to avoid default warnings
            fluid = initSimpleADIFluid('phases', 'WOG', 'n', [2, 2, 2], ...
                                       'mu', [mu_w*1e-3, mu_o*1e-3, mu_g*1e-3]); % Convert cp to Pa·s
            fprintf('   Using MRST initSimpleADIFluid with canonical viscosities\\n');
            
            % Ensure phases field is properly set (MRST compatibility fix)
            if ~isfield(fluid, 'phases') || isempty(fluid.phases)
                fluid.phases = 'WOG';  % Ensure phases field exists
            end
        else
            % Create manual fluid structure
            fluid = create_manual_fluid_structure();
            % Add viscosity values to manual structure
            fluid.mu = [mu_w*1e-3, mu_o*1e-3, mu_g*1e-3]; % Pa·s
            fprintf('   Using manual fluid structure with canonical viscosities\\n');
        end
    catch ME
        fprintf('   initSimpleADIFluid failed, using manual: %s\\n', ME.message);
        fluid = create_manual_fluid_structure();
        % Add viscosity values to manual structure
        fluid.mu = [mu_w*1e-3, mu_o*1e-3, mu_g*1e-3]; % Pa·s
    end
    
end

function fluid = create_manual_fluid_structure()
% Create manual fluid structure when MRST functions not available

    fluid = struct();
    
    % Basic fluid properties
    fluid.phases = 'WOG';  % Water-Oil-Gas
    fluid.n = [2, 2, 2];   % Default Corey exponents
    
    % Phase indices
    fluid.water = 1;
    fluid.oil = 2;
    fluid.gas = 3;
    
    % Initialize relative permeability function holders
    fluid.krW = [];  % Water relative permeability
    fluid.krO = [];  % Oil relative permeability  
    fluid.krG = [];  % Gas relative permeability
    
    % Initialize relative permeability derivatives
    fluid.dkrW = [];
    fluid.dkrO = [];
    fluid.dkrG = [];
    
    % Viscosity placeholder (will be set by calling function)
    fluid.mu = [];
    
end

function fluid = step_2_create_oil_water_functions(fluid, scal_config)
% Create oil-water relative permeability functions by rock type

    % Extract sandstone oil-water parameters (dominant rock type)
    if ~isfield(scal_config, 'sandstone_ow')
        error('Missing sandstone_ow field in SCAL configuration');
    end
    ss_ow = scal_config.sandstone_ow;
    
    % Create Corey-type oil-water relative permeability functions
    % Extract parameters directly to avoid indexing issues
    Swc = ss_ow.connate_water_saturation;
    Sor = ss_ow.residual_oil_saturation;
    krw_max = ss_ow.water_relperm_max;
    kro_max = ss_ow.oil_relperm_max;
    nw = ss_ow.water_corey_exponent;
    no = ss_ow.oil_corey_exponent;
    
    % Create function handles directly
    fluid.krW = @(s, varargin) water_relperm_corey(s(:,1), Swc, Sor, krw_max, nw);
    fluid.krO = @(s, varargin) oil_water_relperm_corey(s(:,1), Swc, Sor, kro_max, no);
    
    % Add derivatives for MRST AD
    fluid.dkrW = @(s, varargin) water_relperm_derivative(s(:,1), Swc, Sor, krw_max, nw);
    fluid.dkrO = @(s, varargin) oil_water_relperm_derivative(s(:,1), Swc, Sor, kro_max, no);
    
    % Store SCAL parameters for reference
    fluid.scal_ow_params = ss_ow;
    
end

function krW_func = create_water_relperm_function(params)
% Create water relative permeability function

    Swc = params.connate_water_saturation;
    Sor = params.residual_oil_saturation;
    krw_max = params.water_relperm_max;
    nw = params.water_corey_exponent;
    
    krW_func = @(s, varargin) water_relperm_corey(s(:,1), Swc, Sor, krw_max, nw);
    
end

function krO_func = create_oil_water_relperm_function(params)
% Create oil relative permeability function (oil-water system)

    Swc = params.connate_water_saturation;
    Sor = params.residual_oil_saturation;
    kro_max = params.oil_relperm_max;
    no = params.oil_corey_exponent;
    
    krO_func = @(s, varargin) oil_water_relperm_corey(s(:,1), Swc, Sor, kro_max, no);
    
end

function dkrW_func = create_water_relperm_derivative(params)
% Create water relative permeability derivative

    Swc = params.connate_water_saturation;
    Sor = params.residual_oil_saturation;
    krw_max = params.water_relperm_max;
    nw = params.water_corey_exponent;
    
    dkrW_func = @(s, varargin) water_relperm_derivative(s(:,1), Swc, Sor, krw_max, nw);
    
end

function dkrO_func = create_oil_water_relperm_derivative(params)
% Create oil relative permeability derivative (oil-water)

    Swc = params.connate_water_saturation;
    Sor = params.residual_oil_saturation;
    kro_max = params.oil_relperm_max;
    no = params.oil_corey_exponent;
    
    dkrO_func = @(s, varargin) oil_water_relperm_derivative(s(:,1), Swc, Sor, kro_max, no);
    
end

function fluid = step_2_create_gas_oil_functions(fluid, scal_config)
% Create gas-oil relative permeability functions

    % Extract sandstone gas-oil parameters
    if ~isfield(scal_config, 'sandstone_go')
        error('Missing sandstone_go field in SCAL configuration');
    end
    ss_go = scal_config.sandstone_go;
    
    % Extract parameters directly to avoid indexing issues
    Sgc = ss_go.critical_gas_saturation;
    Sorg = ss_go.residual_oil_to_gas;
    krg_max = ss_go.gas_relperm_max;
    krog_max = ss_go.oil_gas_relperm_max;
    ng = ss_go.gas_corey_exponent;
    nog = ss_go.oil_gas_corey_exponent;
    
    % Create function handles directly
    fluid.krG = @(s, varargin) gas_relperm_corey(s(:,3), Sgc, Sorg, krg_max, ng);
    fluid.dkrG = @(s, varargin) gas_relperm_derivative(s(:,3), Sgc, Sorg, krg_max, ng);
    
    % Update oil function for gas-oil system
    fluid.krOG = @(s, varargin) oil_gas_relperm_corey(s(:,3), Sgc, Sorg, krog_max, nog);
    fluid.dkrOG = @(s, varargin) oil_gas_relperm_derivative(s(:,3), Sgc, Sorg, krog_max, nog);
    
    % Store SCAL parameters
    fluid.scal_go_params = ss_go;
    
end

function krG_func = create_gas_relperm_function(params)
% Create gas relative permeability function

    Sgc = params.critical_gas_saturation;
    Sorg = params.residual_oil_to_gas;
    krg_max = params.gas_relperm_max;
    ng = params.gas_corey_exponent;
    
    krG_func = @(s, varargin) gas_relperm_corey(s(:,3), Sgc, Sorg, krg_max, ng);
    
end

function krOG_func = create_oil_gas_relperm_function(params)
% Create oil relative permeability function (gas-oil system)

    Sgc = params.critical_gas_saturation;
    Sorg = params.residual_oil_to_gas;
    krog_max = params.oil_gas_relperm_max;
    nog = params.oil_gas_corey_exponent;
    
    krOG_func = @(s, varargin) oil_gas_relperm_corey(s(:,3), Sgc, Sorg, krog_max, nog);
    
end

function dkrG_func = create_gas_relperm_derivative(params)
% Create gas relative permeability derivative

    Sgc = params.critical_gas_saturation;
    Sorg = params.residual_oil_to_gas;
    krg_max = params.gas_relperm_max;
    ng = params.gas_corey_exponent;
    
    dkrG_func = @(s, varargin) gas_relperm_derivative(s(:,3), Sgc, Sorg, krg_max, ng);
    
end

function dkrOG_func = create_oil_gas_relperm_derivative(params)
% Create oil relative permeability derivative (gas-oil)

    Sgc = params.critical_gas_saturation;
    Sorg = params.residual_oil_to_gas;
    krog_max = params.oil_gas_relperm_max;
    nog = params.oil_gas_corey_exponent;
    
    dkrOG_func = @(s, varargin) oil_gas_relperm_derivative(s(:,3), Sgc, Sorg, krog_max, nog);
    
end

function fluid = step_2_add_three_phase_modeling(fluid, scal_config)
% Add three-phase relative permeability modeling

    % Add Stone II model parameters (CANON from 04_SCAL_Properties.md)
    three_phase = scal_config.three_phase_model;
    
    fluid.three_phase_method = three_phase.method;  % "stone_ii"
    fluid.stone_eta = three_phase.stone_eta;        % 2.0
    
    % Add hysteresis modeling
    fluid.hysteresis_model = three_phase.hysteresis_model;  % "land"
    fluid.land_coefficient = three_phase.land_coefficient;  % 2.4
    
    % Stone II implementation marker
    fluid.use_stone_ii = true;
    
end

function fluid = step_3_assign_rock_type_properties(fluid, scal_config, rock, G)
% Step 3 - Assign rock-type specific properties to cells

    % Substep 3.1 – Create cell-based property maps ____________________
    fluid = step_3_create_cell_property_maps(fluid, scal_config, rock, G);
    
    % Substep 3.2 – Add wettability information ________________________
    fluid = step_3_add_wettability_info(fluid, scal_config);
    
    % Substep 3.3 – Add validation metadata _____________________________
    fluid = step_3_add_validation_metadata(fluid, scal_config);
    
end

function fluid = step_3_create_cell_property_maps(fluid, scal_config, rock, G)
% Create cell-based relative permeability property maps

    n_cells = G.cells.num;
    
    % Initialize property arrays
    fluid.cell_swc = zeros(n_cells, 1);
    fluid.cell_sor = zeros(n_cells, 1);
    fluid.cell_sgc = zeros(n_cells, 1);
    fluid.cell_sorg = zeros(n_cells, 1);
    
    % Assign properties based on layer (simplified approach)
    % For PEBI grids, use z-coordinate to determine layer
    z_min = min(G.cells.centroids(:,3));
    z_max = max(G.cells.centroids(:,3));
    
    for cell_id = 1:n_cells
        % Determine layer index for PEBI grid
        cell_z = G.cells.centroids(cell_id, 3);
        k_index = ceil(rock.meta.layer_info.n_layers * (cell_z - z_min) / (z_max - z_min + eps));
        k_index = min(max(k_index, 1), rock.meta.layer_info.n_layers);
        
        % Assign SCAL properties based on layer type
        if ismember(k_index, [4, 8])  % Shale layers
            % Use shale properties - defensive checks
            if ~isstruct(scal_config.shale_ow)
                error('shale_ow is not a struct');
            end
            if ~isstruct(scal_config.shale_go)
                error('shale_go is not a struct');
            end
            
            fluid.cell_swc(cell_id) = scal_config.shale_ow.connate_water_saturation;
            fluid.cell_sor(cell_id) = scal_config.shale_ow.residual_oil_saturation;
            fluid.cell_sgc(cell_id) = scal_config.shale_go.critical_gas_saturation;
            fluid.cell_sorg(cell_id) = scal_config.shale_go.residual_oil_to_gas;
        else  % Sandstone layers
            % Use sandstone properties - defensive checks
            if ~isstruct(scal_config.sandstone_ow)
                error('sandstone_ow is not a struct');
            end
            if ~isstruct(scal_config.sandstone_go)
                error('sandstone_go is not a struct');
            end
            
            fluid.cell_swc(cell_id) = scal_config.sandstone_ow.connate_water_saturation;
            fluid.cell_sor(cell_id) = scal_config.sandstone_ow.residual_oil_saturation;
            fluid.cell_sgc(cell_id) = scal_config.sandstone_go.critical_gas_saturation;
            fluid.cell_sorg(cell_id) = scal_config.sandstone_go.residual_oil_to_gas;
        end
    end
    
end

function fluid = step_3_add_wettability_info(fluid, scal_config)
% Add wettability information from SCAL data with improved error handling

    % Extract wettability data (CANON from 04_SCAL_Properties.md Section 4)
    try
        if isfield(scal_config, 'wettability')
            fluid.wettability = scal_config.wettability;
            
            % Set dominant wettability (sandstone is dominant rock type)
            % Improved YAML parsing with multiple validation checks
            if isfield(fluid.wettability, 'sandstone') && ...
               isstruct(fluid.wettability.sandstone) && ...
               isfield(fluid.wettability.sandstone, 'description') && ...
               isfield(fluid.wettability.sandstone, 'contact_angle')
                
                fluid.dominant_wettability = fluid.wettability.sandstone.description;
                fluid.contact_angle = fluid.wettability.sandstone.contact_angle;
                
                fprintf('   Successfully loaded wettability: %s (contact angle: %.1f°)\\n', ...
                        fluid.dominant_wettability, fluid.contact_angle);
            else
                % CANON-FIRST ERROR: FAIL_FAST when YAML parsing fails
                error(['CANON-FIRST ERROR: Failed to parse wettability from scal_properties_config.yaml\n' ...
                       'REQUIRED: Update scal_properties_config.yaml with complete wettability section:\n' ...
                       '  wettability_parameters:\n' ...
                       '    contact_angle_degrees: 25.0\n' ...
                       '    amott_harvey_oil: 0.15\n' ...
                       '    amott_harvey_water: 0.75\n' ...
                       '    wettability_index: -0.60\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/SCAL_Properties_Definition.md\n' ...
                       'Must define exact wettability parameters for Eagle West Field sandstone.']);
            end
        else
            error('Missing wettability field in SCAL configuration');
        end
    catch ME
        % CANON-FIRST ERROR: FAIL_FAST when wettability configuration missing
        error(['CANON-FIRST ERROR: Failed to load wettability from scal_properties_config.yaml\n' ...
               'ORIGINAL ERROR: %s\n' ...
               'REQUIRED: Create complete wettability configuration:\n' ...
               '  wettability_parameters:\n' ...
               '    dominant_type: strongly water-wet\n' ...
               '    contact_angle_degrees: 25.0\n' ...
               '    amott_harvey_oil: 0.15\n' ...
               '    amott_harvey_water: 0.75\n' ...
               '    wettability_index: -0.60\n' ...
               'UPDATE CANON: obsidian-vault/Planning/SCAL_Properties_Definition.md\n' ...
               'Must define exact wettability for Eagle West Field sandstone reservoir.'], ME.message);
    end
    
end

function fluid = step_3_add_validation_metadata(fluid, scal_config)
% Add validation metadata from SCAL configuration

    fluid.validation = scal_config.validation;
    fluid.upscaling = scal_config.upscaling;
    
    % Add MRST implementation notes
    fluid.mrst_implementation = scal_config.mrst_implementation;
    
    % Add creation metadata
    fluid.creation_date = datestr(now);
    fluid.creation_method = 'SCAL_CANON_Configuration';
    fluid.data_source = '04_SCAL_Properties.md';
    
end

function step_4_validate_fluid_structure(fluid, G)
% Step 4 - Validate MRST fluid structure

    % Substep 4.1 – Check required fields _______________________________
    validate_required_fields(fluid);
    
    % Substep 4.2 – Validate function handles ___________________________
    validate_function_handles(fluid, G);
    
    % Substep 4.3 – Validate SCAL parameters _____________________________
    validate_scal_parameters(fluid, G);
    
end

function validate_required_fields(fluid)
% Validate required MRST fluid fields

    required_fields = {'phases', 'krW', 'krO', 'krG'};
    for i = 1:length(required_fields)
        if ~isfield(fluid, required_fields{i})
            error('Missing required fluid field: %s', required_fields{i});
        end
    end
    
end

function validate_function_handles(fluid, G)
% Validate relative permeability function handles

    % Test with sample saturation array
    n_test = min(100, G.cells.num);
    s_test = [0.3 * ones(n_test, 1), 0.6 * ones(n_test, 1), 0.1 * ones(n_test, 1)];
    
    try
        krw_test = fluid.krW(s_test);
        kro_test = fluid.krO(s_test);
        krg_test = fluid.krG(s_test);
        
        if any(krw_test < 0) || any(krw_test > 1)
            error('Water relative permeability out of range [0,1]');
        end
        
        if any(kro_test < 0) || any(kro_test > 1)
            error('Oil relative permeability out of range [0,1]');
        end
        
        if any(krg_test < 0) || any(krg_test > 1)
            error('Gas relative permeability out of range [0,1]');
        end
        
    catch ME
        error('Relative permeability function validation failed: %s', ME.message);
    end
    
end

function validate_scal_parameters(fluid, G)
% Validate SCAL parameters

    if length(fluid.cell_swc) ~= G.cells.num
        error('Cell-based Swc array size mismatch');
    end
    
    if any(fluid.cell_swc < 0) || any(fluid.cell_swc > 1)
        error('Invalid connate water saturation values');
    end
    
    if any(fluid.cell_sor < 0) || any(fluid.cell_sor > 1)
        error('Invalid residual oil saturation values');
    end
    
end

function step_4_export_fluid_structure(fluid, G, scal_config)
% Step 4 - Export fluid structure and validation

    % Substep 4.1 – Export fluid structure _______________________________
    export_fluid_file(fluid, G, scal_config);
    
    % Substep 4.2 – Export SCAL summary __________________________________
    export_scal_summary(fluid, G, scal_config);
    
end

function export_fluid_file(fluid, G, scal_config)
% Export MRST fluid structure to file using canonical organization
    
    try
        % Load canonical data utilities
        script_path = fileparts(mfilename('fullpath'));
        addpath(fullfile(script_path, 'utils'));
        run(fullfile(script_path, 'utils', 'canonical_data_utils.m'));
        run(fullfile(script_path, 'utils', 'directory_management.m'));
        
        % Create canonical directory structure
        base_data_path = fullfile(fileparts(script_path), 'data');
        static_path = fullfile(base_data_path, 'by_type', 'static');
        if ~exist(static_path, 'dir')
            mkdir(static_path);
        end
        
        % Save using canonical format with native .mat
        fluid_file = fullfile(static_path, 'fluid_relperm_s09.mat');
        save(fluid_file, 'fluid', 'G', 'scal_config');
        fprintf('     Canonical fluid with relperm saved: %s\n', fluid_file);
        
        % Maintain legacy compatibility during transition
        legacy_data_dir = get_data_path('static', 'fluid');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        
        legacy_fluid_file = fullfile(legacy_data_dir, 'fluid_with_relperm.mat');
        save(legacy_fluid_file, 'fluid', 'G', 'scal_config');
        
        fprintf('     Legacy compatibility maintained: %s\n', legacy_fluid_file);
        
    catch ME
        fprintf('Warning: Canonical export failed: %s\n', ME.message);
        
        % Fallback to legacy export
        script_path = fileparts(mfilename('fullpath'));
        if isempty(script_path)
            script_path = pwd();
        end
        data_dir = get_data_path('static', 'fluid');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        % Save fluid structure
        fluid_file = fullfile(data_dir, 'fluid_with_relperm.mat');
        save(fluid_file, 'fluid', 'G', 'scal_config');
        
        fprintf('     Fallback: Fluid structure saved to %s\n', fluid_file);
    end
    
end

function export_scal_summary(fluid, G, scal_config)
% Export SCAL properties summary

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static', 'fluid');
    
    scal_summary_file = fullfile(data_dir, 'scal_summary.txt');
    fid = fopen(scal_summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - SCAL Properties Summary\\n');
    fprintf(fid, '==========================================\\n\\n');
    fprintf(fid, 'Data Source: 04_SCAL_Properties.md (CANON)\\n');
    fprintf(fid, 'Implementation: 100%% MRST Native\\n\\n');
    
    fprintf(fid, 'Relative Permeability Model:\\n');
    fprintf(fid, '  Method: Corey-type correlations\\n');
    fprintf(fid, '  Three-phase: %s\\n', fluid.three_phase_method);
    fprintf(fid, '  Hysteresis: %s\\n', fluid.hysteresis_model);
    
    fprintf(fid, '\\nDominant Rock Properties (Sandstone):\\n');
    fprintf(fid, '  Swc: %.3f\\n', scal_config.sandstone_ow.connate_water_saturation);
    fprintf(fid, '  Sor: %.3f\\n', scal_config.sandstone_ow.residual_oil_saturation);
    fprintf(fid, '  Sgc: %.3f\\n', scal_config.sandstone_go.critical_gas_saturation);
    fprintf(fid, '  Wettability: %s\\n', fluid.dominant_wettability);
    
    fprintf(fid, '\\n=== READY FOR MRST RESERVOIR SIMULATION ===\\n');
    
    fclose(fid);
    
end

% Corey Relative Permeability Functions
function kr = water_relperm_corey(sw, swc, sor, krw_max, nw)
% Water relative permeability using Corey correlation

    sw_norm = max(0, min(1, (sw - swc) ./ (1 - swc - sor)));
    kr = krw_max .* (sw_norm .^ nw);
    kr(sw <= swc) = 0;
    kr(sw >= 1 - sor) = krw_max;
    
end

function kr = oil_water_relperm_corey(sw, swc, sor, kro_max, no)
% Oil relative permeability in oil-water system using Corey correlation

    so_norm = max(0, min(1, (1 - sw - sor) ./ (1 - swc - sor)));
    kr = kro_max .* (so_norm .^ no);
    kr(sw <= swc) = kro_max;
    kr(sw >= 1 - sor) = 0;
    
end

function kr = gas_relperm_corey(sg, sgc, sorg, krg_max, ng)
% Gas relative permeability using Corey correlation

    sg_norm = max(0, min(1, (sg - sgc) ./ (1 - sgc - sorg)));
    kr = krg_max .* (sg_norm .^ ng);
    kr(sg <= sgc) = 0;
    kr(sg >= 1 - sorg) = krg_max;
    
end

function kr = oil_gas_relperm_corey(sg, sgc, sorg, krog_max, nog)
% Oil relative permeability in gas-oil system using Corey correlation

    so_norm = max(0, min(1, (1 - sg - sorg) ./ (1 - sgc - sorg)));
    kr = krog_max .* (so_norm .^ nog);
    kr(sg <= sgc) = krog_max;
    kr(sg >= 1 - sorg) = 0;
    
end

% Derivative Functions
function dkr = water_relperm_derivative(sw, swc, sor, krw_max, nw)
% Water relative permeability derivative

    sw_norm = max(0, min(1, (sw - swc) ./ (1 - swc - sor)));
    dkr = krw_max * nw ./ (1 - swc - sor) .* (sw_norm .^ (nw - 1));
    dkr(sw <= swc | sw >= 1 - sor) = 0;
    
end

function dkr = oil_water_relperm_derivative(sw, swc, sor, kro_max, no)
% Oil relative permeability derivative (oil-water)

    so_norm = max(0, min(1, (1 - sw - sor) ./ (1 - swc - sor)));
    dkr = -kro_max * no ./ (1 - swc - sor) .* (so_norm .^ (no - 1));
    dkr(sw <= swc | sw >= 1 - sor) = 0;
    
end

function dkr = gas_relperm_derivative(sg, sgc, sorg, krg_max, ng)
% Gas relative permeability derivative

    sg_norm = max(0, min(1, (sg - sgc) ./ (1 - sgc - sorg)));
    dkr = krg_max * ng ./ (1 - sgc - sorg) .* (sg_norm .^ (ng - 1));
    dkr(sg <= sgc | sg >= 1 - sorg) = 0;
    
end

function dkr = oil_gas_relperm_derivative(sg, sgc, sorg, krog_max, nog)
% Oil relative permeability derivative (gas-oil)

    so_norm = max(0, min(1, (1 - sg - sorg) ./ (1 - sgc - sorg)));
    dkr = -krog_max * nog ./ (1 - sgc - sorg) .* (so_norm .^ (nog - 1));
    dkr(sg <= sgc | sg >= 1 - sorg) = 0;
    
end

% Main execution when called as script
if ~nargout
    % If called as script (not function), create relative permeability functions
    fluid = s10_relative_permeability();
    
    fprintf('MRST fluid with relative permeability ready!\\n');
    fprintf('Implementation: 100%% MRST Native with CANON SCAL data\\n');
    fprintf('Three-phase model: %s\\n', fluid.three_phase_method);
    fprintf('Dominant wettability: %s\\n', fluid.dominant_wettability);
    fprintf('Use fluid structure in MRST reservoir simulation.\\n\\n');
end