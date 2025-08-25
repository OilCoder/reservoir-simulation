function stats = calculate_completion_statistics(wells)
% CALCULATE_COMPLETION_STATISTICS - Calculate completion design statistics
%
% INPUTS:
%   wells - Array of wellbore design structures
%
% OUTPUTS:
%   stats - Statistical summary of completion designs
%
% Author: Claude Code AI System
% Date: August 22, 2025

    stats = struct();
    
    % Count by well type
    stats.vertical_count = sum(strcmp({wells.well_type}, 'vertical'));
    stats.horizontal_count = sum(strcmp({wells.well_type}, 'horizontal'));
    stats.multilateral_count = sum(strcmp({wells.well_type}, 'multi_lateral'));
    
    % Skin factor statistics
    skin_factors = [wells.skin_factor];
    stats.skin_factor_min = min(skin_factors);
    stats.skin_factor_max = max(skin_factors);
    stats.skin_factor_mean = mean(skin_factors);
    
    % Completion length statistics
    completion_lengths = [wells.completion_length_ft];
    stats.total_completion_length_ft = sum(completion_lengths);
    stats.average_completion_length_ft = mean(completion_lengths);
    stats.max_completion_length_ft = max(completion_lengths);

end