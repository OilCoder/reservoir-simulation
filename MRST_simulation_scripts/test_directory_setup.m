% test_directory_setup.m
% Test script to verify directory setup functionality
% Requires: util_ensure_directories.m

%% ----
%% Step 1 – Clean test environment
%% ----

fprintf('=== Testing Directory Setup System ===\n');

% Remove test directories if they exist (only plots for testing)
test_dirs = {'plots'};
for i = 1:length(test_dirs)
    if exist(test_dirs{i}, 'dir')
        rmdir(test_dirs{i}, 's');
        fprintf('[INFO] Removed existing test directory: %s\n', test_dirs{i});
    end
end

%% ----
%% Step 2 – Test directory creation
%% ----

fprintf('\n--- Testing util_ensure_directories ---\n');
util_ensure_directories();

%% ----
%% Step 3 – Verify all directories exist
%% ----

fprintf('\n--- Verifying directory creation ---\n');
required_dirs = {
    'data'
};

all_exist = true;
for i = 1:length(required_dirs)
    if exist(required_dirs{i}, 'dir')
        fprintf('✅ %s exists\n', required_dirs{i});
    else
        fprintf('❌ %s missing\n', required_dirs{i});
        all_exist = false;
    end
end

%% ----
%% Step 4 – Test write permissions
%% ----

fprintf('\n--- Testing write permissions ---\n');
test_files = {
    'data/test_write.tmp'
};

all_writable = true;
for i = 1:length(test_files)
    try
        fid = fopen(test_files{i}, 'w');
        if fid > 0
            fprintf(fid, 'test');
            fclose(fid);
            delete(test_files{i});
            fprintf('✅ Write permission OK: %s\n', fileparts(test_files{i}));
        else
            fprintf('❌ Cannot write to: %s\n', fileparts(test_files{i}));
            all_writable = false;
        end
    catch ME
        fprintf('❌ Write test failed for %s: %s\n', fileparts(test_files{i}), ME.message);
        all_writable = false;
    end
end

%% ----
%% Step 5 – Test results
%% ----

fprintf('\n=== Test Results ===\n');
if all_exist && all_writable
    fprintf('✅ ALL TESTS PASSED!\n');
    fprintf('Directory setup system is working correctly.\n');
    fprintf('Ready to run main_phase1.m\n');
else
    fprintf('❌ SOME TESTS FAILED!\n');
    if ~all_exist
        fprintf('- Some directories were not created\n');
    end
    if ~all_writable
        fprintf('- Some directories are not writable\n');
    end
    fprintf('Check permissions and file system\n');
end

fprintf('\nTest completed at: %s\n', datestr(now)); 