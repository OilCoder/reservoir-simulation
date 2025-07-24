% Debug script for investigating [specific issue/behavior]
%
% Target module: mrst_simulation_scripts/[module_name].m
% Function: [function_name]
% Date: [YYYY-MM-DD]
% Author: [Name]
%
% Issue Description:
%   - What behavior are we investigating?
%   - What error or unexpected result occurs?
%   - Under what conditions?
%
% Hypothesis:
%   - What might be causing the issue?

% ----------------------------------------
% Step 1 – Setup Debug Environment
% ----------------------------------------

% Clear workspace but keep breakpoints
clear variables; close all; clc;

% Add paths
addpath('..');
addpath('../mrst_simulation_scripts');

% Start diary for logging
diary_file = sprintf('debug/debug_log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
diary(diary_file);

fprintf('=====================================\n');
fprintf('DEBUG INVESTIGATION STARTED\n');
fprintf('Time: %s\n', datestr(now));
fprintf('=====================================\n\n');

% ----------------------------------------
% Step 2 – Load Test Data
% ----------------------------------------

fprintf('--- Loading Test Data ---\n');

try
    % Option 1: Load saved problematic data
    load('debug/problem_data.mat');
    fprintf('✅ Loaded saved test data\n');
    whos  % Display loaded variables
catch
    % Option 2: Generate synthetic test case
    fprintf('⚠️  No saved data found, generating synthetic test case\n');
    
    % Example: Create test grid
    nx = 20; ny = 20; nz = 5;
    test_data.grid = cartGrid([nx, ny, nz], [100, 100, 20]);
    test_data.rock = makeRock(test_data.grid, 100*milli*darcy, 0.2);
end

% Examine data characteristics
fprintf('\nData characteristics:\n');
if exist('test_data', 'var') && isstruct(test_data)
    fields = fieldnames(test_data);
    for i = 1:length(fields)
        field = fields{i};
        value = test_data.(field);
        fprintf('  %s: ', field);
        if isnumeric(value)
            fprintf('size=%s, class=%s, range=[%.4g, %.4g]\n', ...
                    mat2str(size(value)), class(value), ...
                    min(value(:)), max(value(:)));
        else
            fprintf('class=%s\n', class(value));
        end
    end
end

% ----------------------------------------
% Step 3 – Reproduce Issue
% ----------------------------------------

fprintf('\n--- Reproducing Issue ---\n');

% Test Case 1: Normal operation
fprintf('\nTest 1: Normal operation\n');
try
    % Run function with normal inputs
    normal_input = test_data;
    tic;
    result1 = suspicious_function(normal_input);
    elapsed1 = toc;
    
    fprintf('✅ Normal case passed (elapsed: %.3f s)\n', elapsed1);
    fprintf('   Result size: %s\n', mat2str(size(result1)));
catch ME
    fprintf('❌ Normal case failed: %s\n', ME.message);
    fprintf('   Error ID: %s\n', ME.identifier);
    fprintf('   Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('     %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

% Test Case 2: Edge case that triggers issue
fprintf('\nTest 2: Edge case\n');
try
    % Modify data to trigger issue
    edge_case_data = test_data;
    % Example: Set extreme values
    if isfield(edge_case_data, 'rock') && isfield(edge_case_data.rock, 'perm')
        edge_case_data.rock.perm(1) = inf;  % Infinite permeability
    end
    
    tic;
    result2 = suspicious_function(edge_case_data);
    elapsed2 = toc;
    
    fprintf('✅ Edge case passed (elapsed: %.3f s)\n', elapsed2);
catch ME
    fprintf('❌ Edge case failed (EXPECTED): %s\n', ME.message);
    fprintf('   Error location: %s, line %d\n', ...
            ME.stack(1).name, ME.stack(1).line);
end

% ----------------------------------------
% Step 4 – Deep Dive Analysis
% ----------------------------------------

fprintf('\n--- Deep Dive Analysis ---\n');

% Enable verbose mode if available
if exist('suspicious_function', 'file')
    % Check function internals
    fprintf('\nAnalyzing function behavior:\n');
    
    % Test with minimal input
    minimal_input = test_data;
    if isfield(minimal_input, 'grid')
        minimal_input.grid = cartGrid([2, 2, 1], [10, 10, 1]);
    end
    
    % Run with debugging output
    dbg_mode = true;
    try
        fprintf('Running with minimal input and debug mode...\n');
        result_debug = suspicious_function(minimal_input, 'debug', dbg_mode);
    catch ME
        fprintf('Debug run failed at: %s\n', ME.message);
    end
end

% Check for common issues
fprintf('\nChecking for common issues:\n');

% Check 1: NaN or Inf values
if exist('test_data', 'var') && isstruct(test_data)
    fields = fieldnames(test_data);
    for i = 1:length(fields)
        if isnumeric(test_data.(fields{i}))
            data = test_data.(fields{i});
            nan_count = sum(isnan(data(:)));
            inf_count = sum(isinf(data(:)));
            
            if nan_count > 0 || inf_count > 0
                fprintf('  ⚠️  Field "%s": %d NaN, %d Inf values\n', ...
                        fields{i}, nan_count, inf_count);
            end
        end
    end
end

% ----------------------------------------
% Step 5 – Visualization
% ----------------------------------------

fprintf('\n--- Creating Debug Visualizations ---\n');

% Create figure for debug plots
figure('Name', 'Debug Analysis', 'Position', [100, 100, 1200, 800]);

% Plot 1: Data visualization
subplot(2, 2, 1);
if exist('test_data', 'var') && isfield(test_data, 'grid')
    plotGrid(test_data.grid, 'FaceAlpha', 0.3);
    title('Grid Structure');
    view(3); axis tight;
else
    % Generic data plot
    plot(1:10, rand(1,10));
    title('Test Data Sample');
end

% Plot 2: Error analysis
subplot(2, 2, 2);
% Add problem-specific visualization
title('Error Analysis');

% Plot 3: Performance metrics
subplot(2, 2, 3);
if exist('elapsed1', 'var') && exist('elapsed2', 'var')
    bar([elapsed1, elapsed2]);
    set(gca, 'XTickLabel', {'Normal', 'Edge Case'});
    ylabel('Time (s)');
    title('Performance Comparison');
end

% Plot 4: Custom analysis
subplot(2, 2, 4);
% Add custom visualization
title('Custom Analysis');

% Save figure
saveas(gcf, 'debug/debug_analysis.png');
fprintf('✅ Saved visualization to debug/debug_analysis.png\n');

% ----------------------------------------
% Step 6 – Memory and Performance Analysis
% ----------------------------------------

fprintf('\n--- Memory and Performance ---\n');

% Check memory usage
mem_info = memory;
fprintf('Memory usage:\n');
fprintf('  Available: %.2f GB\n', mem_info.MemAvailableAllArrays/1e9);
fprintf('  Used by MATLAB: %.2f GB\n', mem_info.MemUsedMATLAB/1e9);

% Profile if needed
if false  % Set to true to enable profiling
    profile on;
    suspicious_function(test_data);
    profile off;
    profile_data = profile('info');
    % Analyze profile data
end

% ----------------------------------------
% Step 7 – Findings and Conclusions
% ----------------------------------------

fprintf('\n=====================================\n');
fprintf('FINDINGS AND CONCLUSIONS\n');
fprintf('=====================================\n');

findings = struct();
findings.timestamp = datestr(now);
findings.issue = 'Description of the issue';
findings.root_cause = 'Identified root cause';
findings.conditions = {
    'Condition 1 that triggers issue';
    'Condition 2 that triggers issue'
};
findings.proposed_fix = 'Suggested solution';

fprintf('\n📋 Summary:\n');
fprintf('1. Issue occurs when:\n');
for i = 1:length(findings.conditions)
    fprintf('   - %s\n', findings.conditions{i});
end
fprintf('2. Root cause: %s\n', findings.root_cause);
fprintf('3. Proposed fix: %s\n', findings.proposed_fix);

% Save findings
save('debug/findings.mat', 'findings');
fprintf('\n✅ Findings saved to debug/findings.mat\n');

% ----------------------------------------
% Step 8 – Cleanup
% ----------------------------------------

fprintf('\n--- Debug Session Completed ---\n');
fprintf('Outputs saved:\n');
fprintf('  - Log: %s\n', diary_file);
fprintf('  - Plots: debug/debug_analysis.png\n');
fprintf('  - Findings: debug/findings.mat\n');

% Close diary
diary off;