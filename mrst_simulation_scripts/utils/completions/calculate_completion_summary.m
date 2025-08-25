function summary = calculate_completion_summary(wells)
% CALCULATE_COMPLETION_SUMMARY - Calculate completion summary statistics
%
% INPUTS:
%   wells - Array of well completion intervals
%
% OUTPUTS:
%   summary - Summary statistics by sand interval
%
% Author: Claude Code AI System
% Date: August 22, 2025

    summary = struct();
    
    % Count completions by sand interval
    upper_wells = 0; middle_wells = 0; lower_wells = 0;
    total_upper_pay = 0; total_middle_pay = 0; total_lower_pay = 0;
    
    for i = 1:length(wells)
        well = wells(i);
        for j = 1:length(well.intervals)
            interval = well.intervals(j);
            if interval.layer <= 3
                upper_wells = upper_wells + 1;
                total_upper_pay = total_upper_pay + interval.net_pay_ft;
            elseif interval.layer <= 7
                middle_wells = middle_wells + 1;
                total_middle_pay = total_middle_pay + interval.net_pay_ft;
            else
                lower_wells = lower_wells + 1;
                total_lower_pay = total_lower_pay + interval.net_pay_ft;
            end
        end
    end
    
    summary.upper_sand_completions = upper_wells;
    summary.middle_sand_completions = middle_wells;
    summary.lower_sand_completions = lower_wells;
    summary.total_upper_pay_ft = total_upper_pay;
    summary.total_middle_pay_ft = total_middle_pay;
    summary.total_lower_pay_ft = total_lower_pay;
    summary.total_completion_length_ft = total_upper_pay + total_middle_pay + total_lower_pay;

end