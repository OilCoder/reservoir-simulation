function plot_quicklook(G, rock, states, timestep_idx)
% plot_quicklook - Quick visualization of simulation results
%
% Creates rapid visualization plots of effective stress, porosity, and
% permeability to validate heterogeneity and numerical stability after
% simulation runs.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   states: Cell array of simulation states
%   timestep_idx: Index of timestep to plot (optional, default: last)
%
% Returns:
%   None (creates figure)
%
% Requires: MRST

%% ----
%% Step 1 – Input validation and setup
%% ----

% Substep 1.1 – Check inputs ___________________________________
if nargin < 4 || isempty(timestep_idx)
    timestep_idx = length(states);  % Default to last timestep
end

assert(timestep_idx >= 1 && timestep_idx <= length(states), ...
    'Invalid timestep index');

% Substep 1.2 – Extract snapshot data __________________________
% ✅ Use extract_snapshot function for consistency
[sigma_eff, porosity, permeability, rock_id] = extract_snapshot(G, rock, states{timestep_idx}, timestep_idx);

% Substep 1.3 – Setup figure ___________________________________
figure('Name', sprintf('Quicklook - Timestep %d', timestep_idx), ...
       'Position', [100, 100, 1200, 800]);

%% ----
%% Step 2 – Plot effective stress
%% ----

% Substep 2.1 – Effective stress subplot ______________________
subplot(2, 3, 1);
imagesc(sigma_eff / 1e6);  % Convert to MPa
colorbar;
title(sprintf('Effective Stress (MPa) - t=%d', timestep_idx));
xlabel('X Direction');
ylabel('Y Direction');
axis equal tight;
colormap(gca, 'viridis');

% Add contour lines for better visualization
hold on;
contour(sigma_eff / 1e6, 5, 'k--', 'LineWidth', 0.5);
hold off;

%% ----
%% Step 3 – Plot porosity
%% ----

% Substep 3.1 – Porosity subplot ______________________________
subplot(2, 3, 2);
imagesc(porosity);
colorbar;
title(sprintf('Porosity (-) - t=%d', timestep_idx));
xlabel('X Direction');
ylabel('Y Direction');
axis equal tight;
colormap(gca, 'plasma');
caxis([0.05, 0.35]);  % Typical porosity range

% Add contour lines
hold on;
contour(porosity, 5, 'k--', 'LineWidth', 0.5);
hold off;

%% ----
%% Step 4 – Plot permeability
%% ----

% Substep 4.1 – Permeability subplot __________________________
subplot(2, 3, 3);
imagesc(permeability / (milli*darcy));  % Convert to mD
colorbar;
title(sprintf('Permeability (mD) - t=%d', timestep_idx));
xlabel('X Direction');
ylabel('Y Direction');
axis equal tight;
colormap(gca, 'hot');

% Add contour lines
hold on;
contour(permeability / (milli*darcy), 5, 'k--', 'LineWidth', 0.5);
hold off;

%% ----
%% Step 5 – Plot rock regions
%% ----

% Substep 5.1 – Rock regions subplot ___________________________
subplot(2, 3, 4);
imagesc(rock_id);
colorbar;
title('Rock Regions');
xlabel('X Direction');
ylabel('Y Direction');
axis equal tight;
colormap(gca, 'jet');
caxis([0.5, 3.5]);

% Add region labels
hold on;
for i = 1:3
    [r, c] = find(rock_id == i);
    if ~isempty(r)
        text(mean(c), mean(r), sprintf('R%d', i), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', 'white');
    end
end
hold off;

%% ----
%% Step 6 – Time series plots
%% ----

% Substep 6.1 – Pressure evolution plot _______________________
subplot(2, 3, 5);
if length(states) > 1
    time_days = zeros(length(states), 1);
    mean_pressure = zeros(length(states), 1);
    
    for i = 1:length(states)
        time_days(i) = sum(schedule.step.val(1:i)) / day;
        mean_pressure(i) = mean(states{i}.pressure) / psia;
    end
    
    plot(time_days, mean_pressure, 'b-', 'LineWidth', 2);
    xlabel('Time (days)');
    ylabel('Mean Pressure (psia)');
    title('Pressure Evolution');
    grid on;
    
    % Highlight current timestep
    hold on;
    plot(time_days(timestep_idx), mean_pressure(timestep_idx), 'ro', ...
        'MarkerSize', 8, 'MarkerFaceColor', 'red');
    hold off;
else
    text(0.5, 0.5, 'Single timestep\nNo time series', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    axis off;
end

%% ----
%% Step 7 – Statistical summary
%% ----

% Substep 7.1 – Statistics subplot ____________________________
subplot(2, 3, 6);
axis off;

% Calculate statistics
stats_text = {
    sprintf('Timestep: %d', timestep_idx);
    sprintf('Time: %.1f days', sum(schedule.step.val(1:timestep_idx)) / day);
    '';
    '--- Statistics ---';
    sprintf('σ'': %.1f ± %.1f MPa', mean(sigma_eff(:))/1e6, std(sigma_eff(:))/1e6);
    sprintf('φ: %.3f ± %.3f', mean(porosity(:)), std(porosity(:)));
    sprintf('k: %.1f ± %.1f mD', mean(permeability(:))/(milli*darcy), std(permeability(:))/(milli*darcy));
    '';
    '--- Ranges ---';
    sprintf('σ'': %.1f - %.1f MPa', min(sigma_eff(:))/1e6, max(sigma_eff(:))/1e6);
    sprintf('φ: %.3f - %.3f', min(porosity(:)), max(porosity(:)));
    sprintf('k: %.1f - %.1f mD', min(permeability(:))/(milli*darcy), max(permeability(:))/(milli*darcy));
    '';
    '--- Regions ---';
    sprintf('Region 1: %d cells', sum(rock_id(:) == 1));
    sprintf('Region 2: %d cells', sum(rock_id(:) == 2));
    sprintf('Region 3: %d cells', sum(rock_id(:) == 3));
};

% Display statistics
text(0.05, 0.95, stats_text, 'VerticalAlignment', 'top', ...
    'FontSize', 9, 'FontFamily', 'monospace');

%% ----
%% Step 8 – Final formatting
%% ----

% Substep 8.1 – Add main title _________________________________
sgtitle(sprintf('MRST Geomechanical Simulation - Timestep %d', timestep_idx), ...
    'FontSize', 14, 'FontWeight', 'bold');

% Substep 8.2 – Adjust layout __________________________________
set(gcf, 'Color', 'white');
drawnow;

%% ----
%% Step 9 – Save figure (optional)
%% ----

% Substep 9.1 – Save to plots directory ________________________
if ~exist('plots', 'dir')
    mkdir('plots');
end

plot_filename = sprintf('plots/quicklook_t%03d.png', timestep_idx);
print(gcf, plot_filename, '-dpng', '-r300');

fprintf('[INFO] Quicklook plot saved to: %s\n', plot_filename);
fprintf('[INFO] Figure ready for inspection\n');

end 