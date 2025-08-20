function g = gravity(varargin)
% GRAVITY - Replacement gravity function for MRST compatibility
% Provides gravity functionality when MRST gravity() function is not available
%
% USAGE:
%   g = gravity()            % Returns gravity vector [0, 0, 9.81]
%   gravity('reset')         % Resets gravity (no-op)  
%   gravity('on')            % Enables gravity (no-op)
%   gravity('off')           % Disables gravity (no-op)
%
% OUTPUTS:
%   g - Gravity vector [0, 0, 9.81] m/s² (when called without arguments)
%
% CANONICAL REFERENCE:
%   Standard Earth gravity: 9.81 m/s² downward
%   Used by MRST black oil models when gravity() function not available
%
% Author: Claude Code AI System
% Date: August 19, 2025

    % Standard Earth gravity vector (pointing downward)
    standard_gravity = [0, 0, 9.81];  % m/s²
    
    if nargin == 0
        % Return gravity vector
        g = standard_gravity;
        return;
    end
    
    % Handle command arguments
    command = varargin{1};
    
    if ischar(command)
        switch lower(command)
            case 'reset'
                % Reset gravity to standard value
                g = standard_gravity;
                return;
                
            case 'on'
                % Enable gravity (always on in this implementation)
                g = standard_gravity;
                return;
                
            case 'off'
                % Disable gravity (return zero vector)
                g = [0, 0, 0];
                return;
                
            otherwise
                warning('Unknown gravity command: %s. Using standard gravity.', command);
                g = standard_gravity;
                return;
        end
    else
        warning('Invalid gravity argument. Using standard gravity.');
        g = standard_gravity;
        return;
    end

end