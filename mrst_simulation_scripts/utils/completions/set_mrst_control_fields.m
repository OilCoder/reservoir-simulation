function mrst_wells = set_mrst_control_fields(mrst_wells)
% SET_MRST_CONTROL_FIELDS - Set required MRST control fields for all wells
%
% INPUTS:
%   mrst_wells - Array of MRST well structures
%
% OUTPUTS:
%   mrst_wells - Array with control fields set
%
% Author: Claude Code AI System
% Date: August 22, 2025

    for i = 1:length(mrst_wells)
        % Set rate control value from target_rate
        mrst_wells(i).val = mrst_wells(i).target_rate;
        
        % Set well control sign and type based on well type
        if strcmp(mrst_wells(i).type, 'producer')
            mrst_wells(i).sign = 1;     % Positive for producers (fluid out)
            mrst_wells(i).type = 'rate'; % Rate-controlled well
        elseif strcmp(mrst_wells(i).type, 'injector')
            mrst_wells(i).sign = -1;    % Negative for injectors (fluid in)
            mrst_wells(i).type = 'rate'; % Rate-controlled well
        end
        
        % MRST well control validation
        fprintf('   ■ %s: MRST controls (val: %.2f m³/day, sign: %d, type: %s)\n', ...
                mrst_wells(i).name, mrst_wells(i).val, mrst_wells(i).sign, mrst_wells(i).type);
    end

end