function util_ensure_directories()
% util_ensure_directories - Ensure all required directories exist
%
% Creates all necessary directories for MRST simulation workflow including
% data storage, plots, and temporary files. Provides detailed logging of
% directory creation status.
%
% Args:
%   None
%
% Returns:
%   None (creates directories as needed)
%
% Requires: None (pure Octave/MATLAB)

%% ----
%% Step 1 – Define required directories
%% ----

% Substep 1.1 – List all required directories __________________
% Updated for optimized data structure
required_dirs = {
    '../data'                           % Base data directory
    '../data/initial'                   % Initial reservoir conditions
    '../data/static'                    % Static data (grid, wells, rock regions)
    '../data/dynamic/fields'            % 3D time-dependent field arrays
    '../data/dynamic/wells'             % Well operational data
    '../data/temporal'                  % Time vectors and schedules
    '../data/metadata'                  % Dataset documentation
};

fprintf('[INFO] Creating optimized data structure directories...\n');

%% ----
%% Step 2 – Create directories if they don't exist
%% ----

% Substep 2.1 – Loop through required directories ______________
n_created = 0;
n_existing = 0;

for i = 1:length(required_dirs)
    dir_path = required_dirs{i};
    
    % 📁 Check if directory exists
    if ~exist(dir_path, 'dir')
        % ✅ Create directory
        try
            mkdir(dir_path);
            fprintf('[INFO] Created directory: %s\n', dir_path);
            n_created = n_created + 1;
        catch ME
            fprintf('[ERROR] Failed to create directory %s: %s\n', dir_path, ME.message);
        end
    else
        % 🔄 Directory already exists
        n_existing = n_existing + 1;
    end
end

%% ----
%% Step 3 – Verify directory permissions
%% ----

% Substep 3.1 – Test write permissions _________________________
fprintf('[INFO] Testing write permissions...\n');

critical_dirs = {'../data'};
all_writable = true;

for i = 1:length(critical_dirs)
    dir_path = critical_dirs{i};
    test_file = fullfile(dir_path, 'test_write.tmp');
    
    try
        % 📝 Test write access
        fid = fopen(test_file, 'w');
        if fid > 0
            fprintf(fid, 'test');
            fclose(fid);
            delete(test_file);
            fprintf('[INFO] Write permission OK: %s\n', dir_path);
        else
            fprintf('[ERROR] Cannot write to directory: %s\n', dir_path);
            all_writable = false;
        end
    catch ME
        fprintf('[ERROR] Write test failed for %s: %s\n', dir_path, ME.message);
        all_writable = false;
    end
end

%% ----
%% Step 4 – Final summary
%% ----

% Substep 6.1 – Report directory creation status _______________
fprintf('\n--- Directory Setup Summary ---\n');
fprintf('Directories created: %d\n', n_created);
fprintf('Directories existing: %d\n', n_existing);
fprintf('Total directories: %d\n', length(required_dirs));

if all_writable
    fprintf('✅ All critical directories writable\n');
else
    fprintf('❌ Some directories not writable - check permissions\n');
end

% Substep 6.2 – List final directory structure _________________
fprintf('\nFinal directory structure:\n');
for i = 1:length(required_dirs)
    dir_path = required_dirs{i};
    if exist(dir_path, 'dir')
        fprintf('  ✅ %s\n', dir_path);
    else
        fprintf('  ❌ %s (missing)\n', dir_path);
    end
end

fprintf('[INFO] Directory setup completed\n');
end 