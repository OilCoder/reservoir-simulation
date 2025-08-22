function fluid = s02_define_fluids()
% S02_DEFINE_FLUIDS - Define 3-phase fluid system for Eagle West Field using native MRST
%
% PURPOSE:
%   Creates comprehensive 3-phase black oil fluid system (oil-gas-water) for Eagle West Field
%   reservoir simulation. Implements Eagle West fluid properties using native MRST deck format
%   with PVT tables, relative permeability functions, and phase behavior specifications.
%   100% native MRST implementation with zero external dependencies.
%
% SCOPE:
%   - 3-phase black oil fluid creation (WOG phase system)
%   - PVT table generation from YAML configuration (PVTO, PVTW, PVTG)
%   - Relative permeability tables (SWOF, SGOF) with field-averaged properties
%   - Surface density specification and reference conditions
%   - Does NOT: Create rock properties, grid dependencies, or well constraints
%
% WORKFLOW POSITION:
%   Second step in Eagle West Field MRST workflow sequence:
%   s01 (Initialize) → s02 (Fluids) → s03 (Structure) → s04 (Faults) → s05 (PEBI Grid)
%   Dependencies: s01 (MRST session) | Used by: s07 (rock), s17 (wells), s22 (simulation)
%
% INPUTS:
%   - config/fluid_properties_config.yaml - Eagle West fluid PVT data
%   - MRST session from s01_initialize_mrst.m
%   - Required MRST modules: ad-blackoil, ad-props, ad-core
%
% OUTPUTS:
%   fluid - Native MRST fluid structure containing:
%     .phases - 'WOG' (water-oil-gas)
%     .pvto - Oil PVT table [P, Rs, Bo, muo]
%     .pvtw - Water PVT table [Pref, Bwref, Cw, muwref, Cvw]
%     .pvtg - Gas PVT table [P, Rv, Bg, mug]
%     .swof - Water-oil rel perm [Sw, krw, kro, Pcow]
%     .sgof - Gas-oil rel perm [Sg, krg, krog, Pcgo]
%     .rhoOS/.rhoWS/.rhoGS - Surface densities
%
% CONFIGURATION:
%   - fluid_properties_config.yaml - Complete Eagle West PVT specification
%   - Key parameters: API 32°, bubble point 2100 psi, GOR 450 scf/STB
%   - Temperature: 176°F, pressure: 2900 psi initial conditions
%
% CANONICAL REFERENCE:
%   - Specification: obsidian-vault/Planning/Reservoir_Definition/03_Fluid_Properties.md
%   - Implementation: 100% native MRST deck format (initSimpleADIFluid or manual)
%   - Canon-first: FAIL_FAST when fluid properties missing from YAML
%
% EXAMPLES:
%   % Create Eagle West fluid system
%   fluid = s02_define_fluids();
%   
%   % Verify 3-phase system
%   fprintf('Fluid phases: %s\n', fluid.phases);
%   fprintf('PVT tables: PVTO(%dx%d), PVTW(%dx%d)\n', size(fluid.pvto), size(fluid.pvtw));
%
% Author: Claude Code AI System  
% Date: 2025-08-14 (Updated with comprehensive headers)
% Implementation: Eagle West Field MRST Workflow Phase 2

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end

    print_step_header('S02', 'Define Fluid Properties (MRST Native)');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Fluid Configuration
        % ----------------------------------------
        step_start = tic;
        verify_mrst_modules();
        fluid_params = create_default_fluid_params();
        print_step_result(1, 'Load Fluid Configuration', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Create Native MRST Fluid
        % ----------------------------------------
        step_start = tic;
        deck = create_deck_from_yaml(fluid_params);
        fluid = create_native_mrst_fluid(deck, fluid_params);
        print_step_result(2, 'Create Native MRST Fluid', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Validate & Export Fluid Data
        % ----------------------------------------
        step_start = tic;
        validate_native_fluid(fluid, fluid_params);
        export_native_fluid_data(fluid, fluid_params, deck);
        print_step_result(3, 'Validate & Export Fluid', 'success', toc(step_start));
        
        print_step_footer('S02', 'Native MRST Fluid Ready (3-phase)', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Fluid Definition', ME.message);
        error('Native MRST fluid definition failed: %s', ME.message);
    end

end

function verify_mrst_modules()
% VERIFY_MRST_MODULES - Verify MRST modules from s01 session (Canon-First)
%
% Canon-first implementation: s01 session must have loaded all required modules.
% No fallbacks, no defensive programming - FAIL_FAST if s01 session incomplete.

    % Verify essential functions are available from s01 session
    required_functions = {'initSimpleADIFluid', 'mrstModule'};
    
    for i = 1:length(required_functions)
        func_name = required_functions{i};
        if ~exist(func_name, 'file')
            error(['MRST function missing: %s\n' ...
                   'REQUIRED: s01 session must be established first.\n' ...
                   'CANON-FIRST: No fallbacks allowed - run s01_initialize_mrst() first.'], func_name);
        end
    end
    
    fprintf('   ✅ All required MRST functions available from s01 session\n');

end


function deck = create_deck_from_yaml(fluid_params)
% CREATE_DECK_FROM_YAML - Convert YAML fluid tables to MRST deck format
%
% INPUT:
%   fluid_params - Fluid parameters structure from YAML
%
% OUTPUT:
%   deck - MRST deck structure with PVT and relative permeability tables

    % Initialize deck structure
    deck = struct();
    deck.PROPS = struct();
    
    % Convert oil PVT data to PVTO table format
    deck.PROPS.PVTO = create_pvto_table(fluid_params);
    
    % Convert water PVT data to PVTW table format  
    deck.PROPS.PVTW = create_pvtw_table(fluid_params);
    
    % Convert gas PVT data to PVTG table format
    deck.PROPS.PVTG = create_pvtg_table(fluid_params);
    
    % Create relative permeability tables
    deck.PROPS.SWOF = create_swof_table(fluid_params);
    deck.PROPS.SGOF = create_sgof_table(fluid_params);
    
    % Add surface densities
    deck.PROPS.DENSITY = [fluid_params.oil_density, fluid_params.water_density, fluid_params.gas_density];
    
    % Add reference conditions
    deck.PROPS.PVTNUM = 1;  % Single PVT region
    deck.PROPS.SATNUM = 1;  % Single saturation region

end

function pvto_table = create_pvto_table(fluid_params)
% CREATE_PVTO_TABLE - Create PVTO table from YAML data
%
% PVTO format: [Rs Bo muo Pb] for each pressure point
% Using complete PVT tables from YAML configuration

    % Get PVT data from YAML tables
    pressures = fluid_params.oil_bo_pressure_table.pressures;
    bo_values = fluid_params.oil_bo_pressure_table.bo_values;
    rs_values = fluid_params.solution_gor_table.rs_values;
    visc_values = fluid_params.oil_viscosity_table.viscosity_values;
    
    % Ensure all arrays are same length
    n_points = length(pressures);
    if length(bo_values) ~= n_points || length(rs_values) ~= n_points || length(visc_values) ~= n_points
        error('PVT table lengths must match. Pressures: %d, Bo: %d, Rs: %d, Viscosity: %d', ...
              n_points, length(bo_values), length(rs_values), length(visc_values));
    end
    
    % Create PVTO table: [Pb Rs Bo muo] (bubble point format)
    pvto_table = zeros(n_points, 4);
    
    for i = 1:n_points
        pvto_table(i, 1) = pressures(i);      % Pressure (psi)
        pvto_table(i, 2) = rs_values(i);      % Rs (scf/STB)
        pvto_table(i, 3) = bo_values(i);      % Bo (rb/STB)
        pvto_table(i, 4) = visc_values(i);    % muo (cP)
    end

end

function pvtw_table = create_pvtw_table(fluid_params)
% CREATE_PVTW_TABLE - Create PVTW table from YAML data
%
% PVTW format: [Pref Bwref Cw muwref Cvw]

    % Get water PVT data from YAML
    pressures = fluid_params.water_bw_pressure_table.pressures;
    bw_values = fluid_params.water_bw_pressure_table.bw_values;
    cw_values = fluid_params.water_compressibility_table.cw_values;
    
    % Use reference conditions (first point)
    pref = pressures(1);
    bwref = bw_values(1);
    cw = cw_values(1);
    muwref = fluid_params.water_viscosity;
    cvw = fluid_params.water_properties.water_viscosibility;  % Water viscosibility from YAML (usually negligible)
    
    % PVTW table: [Pref Bwref Cw muwref Cvw]
    pvtw_table = [pref, bwref, cw, muwref, cvw];

end

function pvtg_table = create_pvtg_table(fluid_params)
% CREATE_PVTG_TABLE - Create PVTG table from YAML data  
%
% PVTG format: [P Rv Bg mug] (dry gas format)

    % Get gas PVT data from YAML
    pressures = fluid_params.gas_bg_pressure_table.pressures;
    bg_values = fluid_params.gas_bg_pressure_table.bg_values;  
    visc_values = fluid_params.gas_viscosity_table.viscosity_values;
    
    n_points = length(pressures);
    
    % Create PVTG table: [P Rv Bg mug]
    pvtg_table = zeros(n_points, 4);
    
    for i = 1:n_points
        pvtg_table(i, 1) = pressures(i);      % Pressure (psi)
        pvtg_table(i, 2) = fluid_params.gas_properties.rv_dry_gas;  % Rv (STB/Mscf) - dry gas from YAML
        pvtg_table(i, 3) = bg_values(i);      % Bg (rb/Mscf)
        pvtg_table(i, 4) = visc_values(i);    % mug (cP)
    end

end

function swof_table = create_swof_table(fluid_params)
% CREATE_SWOF_TABLE - Create SWOF table using native MRST approach
%
% SWOF format: [Sw krw kro Pcow]
% Uses field-weighted average properties for initialization

    % Use field-weighted average properties
    avg_props = fluid_params.field_average_properties;
    
    % Saturation range
    n_points = 50;
    sw_min = avg_props.connate_water_saturation;
    sw_max = 1.0 - avg_props.residual_oil_saturation;
    sw = linspace(sw_min, sw_max, n_points)';
    
    % Calculate relative permeabilities using MRST-style approach
    % Normalized saturations
    sw_norm = (sw - sw_min) / (sw_max - sw_min);
    so_norm = 1.0 - sw_norm;
    
    % Endpoint values (field averages from RT1 - dominant rock type)
    krw_max = fluid_params.rt1_properties.krw_max;
    kro_max = fluid_params.rt1_properties.kro_max;
    nw = fluid_params.rt1_properties.corey_water_exponent;
    no = fluid_params.rt1_properties.corey_oil_exponent;
    
    % Calculate using power law (Corey-type)
    krw = krw_max * sw_norm.^nw;
    kro = kro_max * so_norm.^no;
    
    % Simple capillary pressure model (placeholder - replaced in s11)
    pc_entry = avg_props.capillary_pressure_entry;  % Entry pressure from YAML
    pc_max = avg_props.capillary_pressure_max;      % Maximum Pc from YAML
    pcow = pc_entry ./ sw;  % Simplified model
    pcow = min(pcow, pc_max);  % Cap at max Pc
    
    % Create SWOF table
    swof_table = [sw, krw, kro, pcow];

end

function sgof_table = create_sgof_table(fluid_params)
% CREATE_SGOF_TABLE - Create SGOF table for gas-oil relative permeability
%
% SGOF format: [Sg krg krog Pcgo]

    % Use field-weighted average properties  
    avg_props = fluid_params.field_average_properties;
    
    % Gas saturation range
    n_points = 50;
    sg_min = avg_props.residual_gas_saturation;
    sg_max = 1.0 - avg_props.connate_water_saturation - avg_props.residual_oil_to_gas;
    sg = linspace(sg_min, sg_max, n_points)';
    
    % Normalized saturations
    sg_norm = (sg - sg_min) / (sg_max - sg_min);
    so_norm = 1.0 - sg_norm;
    
    % Endpoint values from RT1 (dominant rock type)
    krg_max = fluid_params.rt1_properties.krg_max;
    krog_max = fluid_params.rt1_properties.krog_max;
    ng = fluid_params.rt1_properties.corey_gas_exponent;
    nog = fluid_params.rt1_properties.corey_oil_gas_exponent;
    
    % Calculate using power law
    krg = krg_max * sg_norm.^ng;
    krog = krog_max * so_norm.^nog;
    
    % Gas-oil capillary pressure (typically small)
    pcgo = zeros(size(sg));
    
    % Create SGOF table
    sgof_table = [sg, krg, krog, pcgo];

end

function fluid = create_native_mrst_fluid(deck, fluid_params)
% CREATE_NATIVE_MRST_FLUID - Create fluid using native MRST functions
%
% INPUT:
%   deck - MRST deck structure with PVT tables
%   fluid_params - Original fluid parameters
%
% OUTPUT:
%   fluid - Native MRST fluid structure

    % Try different MRST fluid initialization approaches
    try
        % For YAML-based deck, use simplified approach (no GRID section)
        % Using initSimpleADIFluid or manual creation
        fprintf('   Using simplified fluid initialization (YAML-based deck)\n');
        fluid = create_simple_adi_fluid(deck, fluid_params);
        
        % Ensure proper phase identification
        if ~isfield(fluid, 'phases') || isempty(fluid.phases)
            fluid.phases = 'WOG';  % Water-Oil-Gas
        end
        
        % Store reference surface densities
        fluid.rhoOS = fluid_params.oil_density;
        fluid.rhoWS = fluid_params.water_density; 
        fluid.rhoGS = fluid_params.gas_density;
        
    catch ME
        error('Failed to create native MRST fluid: %s', ME.message);
    end

end

function fluid = create_simple_adi_fluid(deck, fluid_params)
% CREATE_SIMPLE_ADI_FLUID - Create fluid using simple ADI approach
%
% Fallback when initDeckADIFluid is not available

    if exist('initSimpleADIFluid', 'file')
        % Use simple ADI fluid with basic properties
        rho = [fluid_params.water_density, fluid_params.oil_density, fluid_params.gas_density];
        mu = [fluid_params.water_viscosity, fluid_params.oil_viscosity, fluid_params.gas_viscosity];
        
        fluid = initSimpleADIFluid('phases', 'WOG', 'rho', rho, 'mu', mu);
        
        % Add PVT tables manually
        fluid.pvto = deck.PROPS.PVTO;
        fluid.pvtw = deck.PROPS.PVTW;
        fluid.pvtg = deck.PROPS.PVTG;
        fluid.swof = deck.PROPS.SWOF;
        fluid.sgof = deck.PROPS.SGOF;
        
    else
        % Manual fluid structure creation (minimal approach)
        fluid = struct();
        fluid.phases = 'WOG';
        
        % Store all PVT data
        fluid.pvto = deck.PROPS.PVTO;
        fluid.pvtw = deck.PROPS.PVTW;
        fluid.pvtg = deck.PROPS.PVTG;
        fluid.swof = deck.PROPS.SWOF;
        fluid.sgof = deck.PROPS.SGOF;
        
        % Basic properties
        fluid.rhoOS = fluid_params.oil_density;
        fluid.rhoWS = fluid_params.water_density;
        fluid.rhoGS = fluid_params.gas_density;
        
        % Reference viscosities
        fluid.muO = fluid_params.oil_viscosity;
        fluid.muW = fluid_params.water_viscosity;
        fluid.muG = fluid_params.gas_viscosity;
        
        fprintf('   Created manual fluid structure (fallback mode)\n');
    end

end

function validate_native_fluid(fluid, fluid_params)
% VALIDATE_NATIVE_FLUID - Validate native MRST fluid structure
%
% INPUT:
%   fluid - Native MRST fluid structure
%   fluid_params - Original parameters for validation

    % Check required fields
    required_fields = {'phases'};
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(fluid, field)
            error('Missing required field in native fluid structure: %s', field);
        end
    end
    
    % Validate phases
    if ~strcmp(fluid.phases, 'WOG') && ~strcmp(fluid.phases, 'OWG')
        error(['Invalid phase configuration: %s\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fluid_Properties.md\n' ...
               'Must use exactly ''WOG'' or ''OWG'' phase ordering.'], fluid.phases);
    end
    
    % Check that PVT tables exist
    pvt_tables = {'pvto', 'pvtw', 'pvtg'};
    for i = 1:length(pvt_tables)
        table = pvt_tables{i};
        if isfield(fluid, table) && ~isempty(fluid.(table))
            fprintf('     %s table: %dx%d\n', upper(table), size(fluid.(table)));
        else
            error(['Missing PVT table: %s\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Fluid_Properties.md\n' ...
                   'Must define complete PVT tables for 3-phase black oil.'], table);
        end
    end
    
    % Check relative permeability tables
    relperm_tables = {'swof', 'sgof'};
    for i = 1:length(relperm_tables)
        table = relperm_tables{i};
        if isfield(fluid, table) && ~isempty(fluid.(table))
            fprintf('     %s table: %dx%d\n', upper(table), size(fluid.(table)));
        end
    end
    
    fprintf('     Native fluid validation successful\n');

end

function export_native_fluid_data(fluid, fluid_params, deck)
% EXPORT_NATIVE_FLUID_DATA - Export native fluid data using new canonical MRST structure
%
% INPUT:
%   fluid - Native MRST fluid structure
%   fluid_params - Original fluid parameters
%   deck - MRST deck structure

    % NEW CANONICAL STRUCTURE: Create fluid.mat in /workspace/data/mrst/
    canonical_file = '/workspace/data/mrst/fluid.mat';
    
    % Check if canonical file already exists (load existing data)
    if exist(canonical_file, 'file')
        load(canonical_file);
        if ~exist('data_struct', 'var')
            data_struct = struct();
            data_struct.created_by = {};
        end
    else
        data_struct = struct();
        data_struct.created_by = {};
    end
    
    % Add new fluid data to canonical structure
    data_struct.properties = fluid_params;
    data_struct.model = fluid;
    data_struct.deck = deck;
    data_struct.created_by{end+1} = 's02';
    data_struct.timestamp = datetime('now');
    
    % Save canonical structure
    save(canonical_file, 'data_struct');
    fprintf('     NEW CANONICAL: Fluid data saved to %s\n', canonical_file);
    
    % Maintain legacy compatibility during transition
    try
        legacy_data_dir = get_data_path('static');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        legacy_fluid_file = fullfile(legacy_data_dir, 'native_fluid_properties.mat');
        save(legacy_fluid_file, 'fluid', 'fluid_params', 'deck');
        
        % Create summary report
        create_fluid_summary_report(fluid_params, deck, legacy_data_dir);
        fprintf('     Legacy compatibility maintained: %s\n', legacy_fluid_file);
    catch ME
        fprintf('Warning: Legacy export failed: %s\n', ME.message);
    end
end

function create_fluid_summary_report(fluid_params, deck, output_dir)
% CREATE_FLUID_SUMMARY_REPORT - Create human-readable fluid summary
    
    summary_file = fullfile(output_dir, 'fluid_deck_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Native MRST Fluid Summary\n');
    fprintf(fid, '=============================================\n\n');
    fprintf(fid, 'Implementation: 100%% Native MRST (Canonical Organization)\n');
    fprintf(fid, 'Fluid System: 3-phase black oil\n');
    fprintf(fid, 'MRST Modules: ad-blackoil, ad-props, ad-core\n\n');
    
    fprintf(fid, 'Surface Properties:\n');
    fprintf(fid, '  Oil Density: %.0f kg/m³ (API %.1f°)\n', fluid_params.oil_density, fluid_params.api_gravity);
    fprintf(fid, '  Water Density: %.0f kg/m³\n', fluid_params.water_density);
    fprintf(fid, '  Gas Density: %.1f kg/m³\n', fluid_params.gas_density);
    
    fprintf(fid, '\nReservoir Conditions:\n');
    fprintf(fid, '  Temperature: %.0f °F\n', fluid_params.reservoir_temperature);
    fprintf(fid, '  Bubble Point: %.0f psi\n', fluid_params.bubble_point);
    fprintf(fid, '  Solution GOR: %.0f scf/STB\n', fluid_params.solution_gor);
    
    fprintf(fid, '\nPVT Tables (Native MRST Deck Format):\n');
    if isfield(deck.PROPS, 'PVTO')
        fprintf(fid, '  PVTO: %dx%d points\n', size(deck.PROPS.PVTO));
    end
    if isfield(deck.PROPS, 'PVTW')
        fprintf(fid, '  PVTW: %dx%d points\n', size(deck.PROPS.PVTW));
    end
    if isfield(deck.PROPS, 'PVTG')
        fprintf(fid, '  PVTG: %dx%d points\n', size(deck.PROPS.PVTG));
    end
    
    fprintf(fid, '\nRelative Permeability Tables:\n');
    if isfield(deck.PROPS, 'SWOF')
        fprintf(fid, '  SWOF: %dx%d points\n', size(deck.PROPS.SWOF));
    end
    if isfield(deck.PROPS, 'SGOF')
        fprintf(fid, '  SGOF: %dx%d points\n', size(deck.PROPS.SGOF));
    end
    
    fprintf(fid, '\nData Organization: Canonical (by_type/by_usage/by_phase)\n');
    fprintf(fid, 'Format: Native .mat (oct2py compatible)\n');
    fprintf(fid, 'Creation Date: %s\n', datestr(now));
    fprintf(fid, 'Policy: 100%% MRST Native Implementation\n');
    
    fclose(fid);
end

function fallback_export_fluid_data(fluid, fluid_params, deck)
% FALLBACK_EXPORT_FLUID_DATA - Legacy export if canonical fails
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save native fluid structure
    fluid_file = fullfile(data_dir, 'native_fluid_properties.mat');
    save(fluid_file, 'fluid', 'fluid_params', 'deck');
    
    fprintf('     Fallback: Native fluid data saved to: %s\n', fluid_file);
end

function fluid_params = create_default_fluid_params()
% Load fluid parameters from YAML - NO HARDCODING POLICY
    try
        % Policy Compliance: Load from YAML only
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, 'utils'));
        config = read_yaml_config('config/fluid_properties_config.yaml');
        fluid_params = config.fluid_properties;
        
        % Validate all required properties exist in YAML
        required_props = {'oil_density', 'water_density', 'gas_density', 'bubble_point', ...
                         'reservoir_temperature', 'initial_reservoir_pressure', 'solution_gor'};
        
        for i = 1:length(required_props)
            field_name = required_props{i};
            if strcmp(field_name, 'initial_reservoir_pressure')
                check_field = 'reservoir_pressure'; 
                fluid_params.reservoir_pressure = fluid_params.initial_reservoir_pressure;
            elseif strcmp(field_name, 'solution_gor')
                check_field = 'initial_gor';
                fluid_params.initial_gor = fluid_params.solution_gor;
            else
                check_field = field_name;
            end
            
            if ~isfield(fluid_params, check_field)
                error('Missing required fluid property in YAML: %s', field_name);
            end
        end
        
        % Load default values from YAML - Policy 1 compliance
        if ~isfield(fluid_params, 'swc') && isfield(fluid_params, 'default_saturations')
            fluid_params.swc = fluid_params.default_saturations.swc;
        end
        if ~isfield(fluid_params, 'sorw') && isfield(fluid_params, 'default_saturations')
            fluid_params.sorw = fluid_params.default_saturations.sorw;
        end
        if ~isfield(fluid_params, 'sorg') && isfield(fluid_params, 'default_saturations')
            fluid_params.sorg = fluid_params.default_saturations.sorg;
        end
        if ~isfield(fluid_params, 'sgc') && isfield(fluid_params, 'default_saturations')
            fluid_params.sgc = fluid_params.default_saturations.sgc;
        end
        if ~isfield(fluid_params, 'sw_max') && isfield(fluid_params, 'default_saturations')
            fluid_params.sw_max = fluid_params.default_saturations.sw_max;
        end
        if ~isfield(fluid_params, 'sg_max') && isfield(fluid_params, 'default_saturations')
            fluid_params.sg_max = fluid_params.default_saturations.sg_max;
        end
        
        % Load relperm endpoints from YAML
        if ~isfield(fluid_params, 'krw_max') && isfield(fluid_params, 'default_relperm_endpoints')
            fluid_params.krw_max = fluid_params.default_relperm_endpoints.krw_max;
        end
        if ~isfield(fluid_params, 'kro_max') && isfield(fluid_params, 'default_relperm_endpoints')
            fluid_params.kro_max = fluid_params.default_relperm_endpoints.kro_max;
        end
        if ~isfield(fluid_params, 'krg_max') && isfield(fluid_params, 'default_relperm_endpoints')
            fluid_params.krg_max = fluid_params.default_relperm_endpoints.krg_max;
        end
        
        % Load Corey exponents from YAML
        if ~isfield(fluid_params, 'corey_nw') && isfield(fluid_params, 'default_corey_exponents')
            fluid_params.corey_nw = fluid_params.default_corey_exponents.nw;
        end
        if ~isfield(fluid_params, 'corey_now') && isfield(fluid_params, 'default_corey_exponents')
            fluid_params.corey_now = fluid_params.default_corey_exponents.now;
        end
        if ~isfield(fluid_params, 'corey_ng') && isfield(fluid_params, 'default_corey_exponents')
            fluid_params.corey_ng = fluid_params.default_corey_exponents.ng;
        end
        if ~isfield(fluid_params, 'corey_nog') && isfield(fluid_params, 'default_corey_exponents')
            fluid_params.corey_nog = fluid_params.default_corey_exponents.nog;
        end
        
        % Load viscosity and FVF defaults from YAML
        if ~isfield(fluid_params, 'oil_viscosity_dead') && isfield(fluid_params, 'default_viscosity')
            fluid_params.oil_viscosity_dead = fluid_params.default_viscosity.oil_viscosity_dead;
        end
        if ~isfield(fluid_params, 'oil_viscosity_saturated')
            fluid_params.oil_viscosity_saturated = fluid_params.oil_viscosity;
        end
        if ~isfield(fluid_params, 'gas_viscosity_ref') && isfield(fluid_params, 'default_viscosity')
            fluid_params.gas_viscosity_ref = fluid_params.default_viscosity.gas_viscosity_ref;
        end
        
        if ~isfield(fluid_params, 'bo_bubble') && isfield(fluid_params, 'default_fvf')
            fluid_params.bo_bubble = fluid_params.default_fvf.bo_bubble;
        end
        if ~isfield(fluid_params, 'bw_ref') && isfield(fluid_params, 'default_fvf')
            fluid_params.bw_ref = fluid_params.default_fvf.bw_ref;
        end
        
        fprintf('Using Eagle West Field 3-phase fluid system (canon documentation)\n');
        
    catch ME
        error('Failed to load fluid parameters from YAML: %s\nPolicy violation: No hardcoding allowed', ME.message);
    end
end

% create_simple_mrst_fluid - REMOVED for Policy 2 compliance
% All external calculation functions replaced with native MRST deck approach

% External calculation functions REMOVED for Policy 2 compliance:
% - calculate_oil_viscosity
% - calculate_water_fvf
% - calculate_oil_fvf
% - calculate_gas_fvf
% All PVT calculations now handled by native MRST deck functions

% External Stone's Model functions REMOVED for Policy 2 compliance:
% - add_threephase_relperm
% - stone_water_relperm
% - stone_oil_water_relperm
% - stone_gas_relperm
% - stone_oil_gas_relperm
% - stone_threephase_oil
% All relative permeability handled by native MRST SWOF/SGOF tables

% External PVT table generation function REMOVED for Policy 2 compliance:
% - add_pvt_tables (used external calculate_* functions)
% All PVT tables now created from YAML data via create_deck_from_yaml

% Simple fluid functions REMOVED - replaced with native MRST functions:
% - validate_simple_fluid -> validate_native_fluid
% - export_simple_fluid_data -> export_native_fluid_data

% Main execution when called as script
if ~nargout
    % If called as script (not function), create and display fluid properties
    fluid = s02_define_fluids();
    
    fprintf('Native MRST fluid ready for simulation!\n');
    fprintf('Implementation: 100%% Native MRST\n');
    fprintf('Fluid phases: %s\n', fluid.phases);
    fprintf('Use fluid structure in reservoir simulation.\n\n');
end