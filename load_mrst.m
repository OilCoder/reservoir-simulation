function load_mrst()
    % LOAD_MRST Initialize MRST environment for reservoir simulation
    %
    % This function sets up the MRST (MATLAB Reservoir Simulation Toolbox)
    % environment with required modules for geomechanical reservoir simulation.
    %
    % REQUIREMENTS:
    %   - MRST installed and accessible in MATLAB path
    %   - Required MRST modules: ad-core, ad-blackoil, ad-props, geomechanics
    %
    % USAGE:
    %   load_mrst()
    %
    % MODULES LOADED:
    %   - ad-core: Automatic differentiation core
    %   - ad-blackoil: Black oil reservoir simulation
    %   - ad-props: Advanced property calculations
    %   - geomechanics: Coupled geomechanics
    %   - mrst-gui: Plotting and visualization
    %
    % AUTHOR: Geomechanical ML Project Team
    % DATE: 2025-01-24
    
    % ----------------------------------------
    % Step 1 – Validate MRST installation
    % ----------------------------------------
    
    % Substep 1.1 – Check if MRST is available ______________________
    if ~exist('mrstModule', 'file')
        error('MRST not found. Please install MRST and add to MATLAB path.');
    end
    
    fprintf('Initializing MRST environment...\n');
    
    % ----------------------------------------
    % Step 2 – Load required MRST modules
    % ----------------------------------------
    
    % Substep 2.1 – Load core modules ______________________
    try
        mrstModule add ad-core ad-blackoil ad-props
        fprintf('✅ Core modules loaded: ad-core, ad-blackoil, ad-props\n');
    catch ME
        error('Failed to load core MRST modules: %s', ME.message);
    end
    
    % Substep 2.2 – Load geomechanics module ______________________
    try
        mrstModule add geomechanics
        fprintf('✅ Geomechanics module loaded\n');
    catch ME
        warning('Geomechanics module not available: %s', ME.message);
    end
    
    % Substep 2.3 – Load visualization modules ______________________
    try
        mrstModule add mrst-gui
        fprintf('✅ Visualization module loaded: mrst-gui\n');
    catch ME
        warning('GUI module not available: %s', ME.message);
    end
    
    % ----------------------------------------
    % Step 3 – Verify MRST configuration
    % ----------------------------------------
    
    % Substep 3.1 – Display loaded modules ______________________
    fprintf('\nLoaded MRST modules:\n');
    mrstModule list
    
    % Substep 3.2 – Set default plotting options ______________________
    set(0, 'DefaultFigureRenderer', 'opengl');
    
    fprintf('\n🎯 MRST environment ready for simulation!\n');
    fprintf('Use mrstModule list to see all loaded modules.\n\n');
    
end