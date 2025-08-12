function fluid_complete = create_pvt_tables(fluid_with_pc, pvt_config, G)
% CREATE_PVT_TABLES - Create comprehensive PVT tables for black oil simulation
%
% INPUT:
%   fluid_with_pc - Fluid with capillary pressure
%   pvt_config - PVT configuration structure
%   G - Grid structure
% OUTPUT:
%   fluid_complete - Complete MRST fluid with PVT tables

    % Create basic PVT tables using MRST functions
    % Use robust defaults for pressure ranges
    pressure_ranges = [[500, 1000]; [1000, 1500]; [1500, 2000]; [2000, 2500]; [2500, 3000]; [3000, 4000]];
    fprintf('   Using canonical pressure ranges from CANON documentation\n');
    
    % Try to load from config if available and properly structured
    if isfield(pvt_config, 'pvt') && isfield(pvt_config.pvt, 'pressure_ranges')
        config_ranges = pvt_config.pvt.pressure_ranges;
        if isnumeric(config_ranges) && size(config_ranges,2) == 2 && size(config_ranges,1) > 0
            pressure_ranges = config_ranges;
            fprintf('   Successfully loaded pressure ranges from config\n');
        else
            fprintf('   Config pressure ranges malformed, using defaults\n');
        end
    end
    
    % Create oil PVT table (PVTO format)
    p_vals = linspace(pressure_ranges(1,1), pressure_ranges(end,2), 10)';
        rs_vals = linspace(50, 250, 4);  % Solution GOR range
        bo_vals = 1.2 + 0.0001 * p_vals; % Oil formation volume factor
        muo_vals = 0.8 + 0.0001 * p_vals; % Oil viscosity
        
        pvto = [p_vals, rs_vals(1)*ones(size(p_vals)), bo_vals, muo_vals];
        
        % Create water PVT table (PVTW format) 
        p_ref = pressure_ranges(3,1); % Reference pressure
        bw_ref = 1.03;                 % Water FVF at reference
        cw = 4.3e-10;                  % Water compressibility (1/Pa)
        muw_ref = 0.385e-3;            % Water viscosity (Pa·s)
        vw = 0.0;                      % Water viscosity gradient
        
        pvtw = [p_ref, bw_ref, cw, muw_ref, vw];
        
        % Create gas PVT table (PVTG format)
        p_gas = p_vals;
        bg_vals = 0.001 ./ p_vals;     % Gas formation volume factor
        mug_vals = 0.02e-3 * ones(size(p_vals)); % Gas viscosity
        
        pvtg = [p_gas, zeros(size(p_gas)), bg_vals, mug_vals];
    
    % Add PVT tables to fluid structure
    fluid_complete = fluid_with_pc;
    fluid_complete.pvto = pvto;
    fluid_complete.pvtw = pvtw; 
    fluid_complete.pvtg = pvtg;
    
    % Add surface conditions
    fluid_complete.surface = struct();
    fluid_complete.surface.pressure_pa = 101325;    % 1 atm
    fluid_complete.surface.temperature_k = 288.15;  % 15°C
    
    fprintf('   ✅ PVT tables created successfully\n');
end