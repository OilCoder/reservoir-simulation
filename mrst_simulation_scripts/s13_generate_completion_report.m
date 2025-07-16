function generate_completion_report(G, rock, states, schedule, timing, all_vars_exist)
% generate_completion_report - Generate final workflow completion report
%
% Creates a comprehensive report of the simulation workflow execution
% including timing, results summary, and validation status.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure with regions
%   states: Cell array of simulation states
%   schedule: MRST schedule structure
%   timing: Structure with timing information
%   all_vars_exist: Boolean indicating if all variables exist
%
% Returns:
%   None (prints completion report)
%
% Requires: MRST

%% ----
%% Step 1 – Calculate total workflow time
%% ----

total_time = timing.setup_time + timing.fluid_time + timing.regions_time + ...
            timing.schedule_time + timing.simulation_time + timing.export_time;

%% ----
%% Step 2 – Generate completion report
%% ----

fprintf('\n=== PHASE 1 COMPLETION REPORT ===\n');
fprintf('Workflow finished at: %s\n', datestr(now));
fprintf('Total execution time: %.1f seconds (%.1f minutes)\n', total_time, total_time/60);
fprintf('\nTiming breakdown:\n');
fprintf('  Grid/Rock setup: %.1f s (%.1f%%)\n', timing.setup_time, 100*timing.setup_time/total_time);
fprintf('  Fluid properties: %.1f s (%.1f%%)\n', timing.fluid_time, 100*timing.fluid_time/total_time);
fprintf('  Rock regions: %.1f s (%.1f%%)\n', timing.regions_time, 100*timing.regions_time/total_time);
fprintf('  Schedule creation: %.1f s (%.1f%%)\n', timing.schedule_time, 100*timing.schedule_time/total_time);
fprintf('  Simulation: %.1f s (%.1f%%)\n', timing.simulation_time, 100*timing.simulation_time/total_time);
fprintf('  Data export: %.1f s (%.1f%%)\n', timing.export_time, 100*timing.export_time/total_time);

%% ----
%% Step 3 – Results summary
%% ----

fprintf('\nResults summary:\n');
fprintf('  Grid cells: %d (20x20)\n', G.cells.num);
fprintf('  Timesteps: %d\n', length(states));
fprintf('  Simulation time: %.1f days\n', sum(schedule.step.val)/86400);
fprintf('  Wells: %d\n', length(schedule.control(1).W));
fprintf('  Rock regions: %d\n', length(unique(rock.regions)));

% Calculate total data size from optimized structure
data_dir = '../data';
total_size = 0;
if exist(data_dir, 'dir')
    data_files = dir(fullfile(data_dir, '**/*.mat'));
    for i = 1:length(data_files)
        total_size = total_size + data_files(i).bytes;
    end
end
fprintf('  Total data size: %.1f MB\n', total_size/(1024^2));

%% ----
%% Step 4 – Success/failure status
%% ----

if all_vars_exist
    fprintf('\n✅ PHASE 1 COMPLETED SUCCESSFULLY!\n');
    fprintf('All required outputs generated and validated.\n');
    fprintf('Dataset ready for ML training pipeline.\n');
else
    fprintf('\n❌ PHASE 1 COMPLETED WITH ERRORS!\n');
    fprintf('Some required outputs missing. Check error messages above.\n');
end

%% ----
%% Step 5 – Next steps instructions
%% ----

fprintf('\nNext steps:\n');
fprintf('  1. Examine snapshot data in ../data/\n');
fprintf('  2. Review metadata.yaml for dataset details\n');
fprintf('  3. Use monitoring/plot_scripts/ for visualization\n');
fprintf('  4. Proceed to Phase 2 (ML model development)\n');

fprintf('\nWorkspace variables available:\n');
fprintf('  G, rock, fluid, schedule, states, wellSols\n');
fprintf('  Use "clear all" to clean workspace if needed\n');

fprintf('\n=== END OF PHASE 1 ===\n');

end
