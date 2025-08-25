function mwell = set_well_controls(mwell, well, init_config)
% SET_WELL_CONTROLS - Set MRST well control parameters
%
% INPUTS:
%   mwell - MRST well structure to populate
%   well - Well structure from wells placement
%   init_config - Initialization configuration from YAML
%
% OUTPUTS:
%   mwell - MRST well structure with controls set
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Initialize control fields
    mwell.target_rate = 0;
    
    % Set pressure limits (CANON-FIRST - must come from YAML configuration)
    if ~isfield(well, 'min_bhp_psi') || ~isfield(well, 'max_bhp_psi')
        error(['CANON-FIRST ERROR: Missing BHP limits for well %s\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact min_bhp_psi/max_bhp_psi in wells_config.yaml for Eagle West Field.\n' ...
               'No default pressure limits allowed - all values must be domain-specific.'], well.name);
    end
    
    % Convert pressure using CANON conversion factor
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.pressure, 'psi_to_pa')
        error(['CANON-FIRST ERROR: Missing psi_to_pa conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    psi_to_pa = init_config.initialization.unit_conversions.pressure.psi_to_pa;
    mwell.min_bhp = well.min_bhp_psi * psi_to_pa;  % CANON conversion
    mwell.max_bhp = well.max_bhp_psi * psi_to_pa;  % CANON conversion
    
    % Extract volume conversion factor (CANON-FIRST)
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.volume, 'bbl_to_m3')
        error(['CANON-FIRST ERROR: Missing bbl_to_m3 conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    bbl_to_m3 = init_config.initialization.unit_conversions.volume.bbl_to_m3;
    
    if strcmp(well.type, 'producer')
        mwell.target_rate = well.target_oil_rate * bbl_to_m3;  % CANON STB/day to m³/day conversion
    else
        mwell.target_rate = well.target_injection_rate * bbl_to_m3;  % CANON BBL/day to m³/day conversion
    end

end