% LOCAL STARTUP.M - Runs before MRST startup.m when in this directory
% This fixes the mrstPath undefined error

% Pre-load MRST core paths to make mrstPath available
if exist('/opt/mrst/core/utils', 'dir')
    addpath('/opt/mrst/core/utils');
    addpath('/opt/mrst/core');
    
    % Now safe to run MRST startup if it exists
    mrst_startup = '/opt/mrst/startup.m';
    if exist(mrst_startup, 'file')
        % Temporarily change directory to avoid recursion
        old_dir = pwd;
        cd('/opt/mrst');
        
        % Suppress the error output
        try
            startup();
        catch
            % Ignore startup errors
        end
        
        cd(old_dir);
    end
end

% Suppress common warnings
warning('off', 'Octave:shadowed-function');
warning('off', 'Octave:deprecated-function');
warning('off', 'Octave:legacy-function');