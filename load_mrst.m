function load_mrst()
    %% Load MRST - MATLAB Reservoir Simulation Toolbox
    % This function properly initializes MRST for use in simulation scripts
    
    fprintf('Loading MRST...\n');
    
    % Add MRST to path
    if exist('/opt/mrst', 'dir')
        addpath('/opt/mrst');
        
        % Change to MRST directory temporarily
        current_dir = pwd;
        cd('/opt/mrst');
        
        try
            % Run MRST startup
            startup;
            
            % Load core modules
            mrstModule add core
            
            fprintf('MRST loaded successfully!\n');
            
        catch ME
            fprintf('Warning: MRST loading had issues: %s\n', ME.message);
        end
        
        % Return to original directory
        cd(current_dir);
    else
        error('MRST not found in /opt/mrst');
    end
end 