function mwell = set_well_controls(mwell, well, init_config, wells_config)
% SET_WELL_CONTROLS - Set MRST well control parameters
%
% INPUTS:
%   mwell - MRST well structure to populate
%   well - Well structure from wells placement
%   init_config - Initialization configuration from YAML
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   mwell - MRST well structure with controls set
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Initialize control fields
    mwell.target_rate = 0;
    
    % Get BHP limits from wells_config.yaml (CANON-FIRST)
    if strcmp(well.type, 'producer')
        well_config = wells_config.wells_system.producer_wells.(well.name);
        min_bhp_psi = well_config.min_bhp_psi;
        if strcmp(well.type, 'producer')
            max_bhp_psi = 4000;  % Default max BHP for producers
        end
    else
        well_config = wells_config.wells_system.injector_wells.(well.name);
        max_bhp_psi = well_config.max_bhp_psi;
        min_bhp_psi = 1000;  % Default min BHP for injectors
    end
    
    % Convert pressure using CANON conversion factor
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.pressure, 'psi_to_pa')
        error(['CANON-FIRST ERROR: Missing psi_to_pa conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    psi_to_pa = init_config.initialization.unit_conversions.pressure.psi_to_pa;
    mwell.min_bhp = min_bhp_psi * psi_to_pa;  % CANON conversion
    mwell.max_bhp = max_bhp_psi * psi_to_pa;  % CANON conversion
    
    % Extract volume conversion factor (CANON-FIRST)
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.volume, 'bbl_to_m3')
        error(['CANON-FIRST ERROR: Missing bbl_to_m3 conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    bbl_to_m3 = init_config.initialization.unit_conversions.volume.bbl_to_m3;
    
    if strcmp(well.type, 'producer')
        mwell.target_rate = well_config.target_oil_rate_stb_day * bbl_to_m3;  % CANON STB/day to m³/day conversion
    else
        mwell.target_rate = well_config.target_injection_rate_bbl_day * bbl_to_m3;  % CANON BBL/day to m³/day conversion
    end

end