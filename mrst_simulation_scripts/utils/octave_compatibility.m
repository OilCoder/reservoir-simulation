function octave_compatibility()
% Octave compatibility fixes for MRST
% Replaces missing/problematic functions

%% Fix 1: contains function
if ~exist('contains', 'builtin')
    % Create contains function using strfind
    assignin('base', 'contains', @octave_contains);
end

%% Fix 2: isprop function (already exists but may have issues)
if ~exist('isprop', 'builtin') || exist('isprop', 'file')
    assignin('base', 'isprop', @octave_isprop);
end

%% Fix 3: Add to global scope for scripts
evalin('base', 'contains = @octave_contains;');
evalin('base', 'isprop = @octave_isprop;');

fprintf('✅ Octave compatibility functions loaded\n');

end

function result = octave_contains(str, pattern)
% Octave replacement for contains function
if ischar(str) && ischar(pattern)
    result = ~isempty(strfind(str, pattern));
elseif iscell(str)
    result = false(size(str));
    for i = 1:numel(str)
        if ischar(str{i})
            result(i) = ~isempty(strfind(str{i}, pattern));
        end
    end
else
    result = false;
end
end

function result = octave_isprop(obj, prop)
% Octave replacement for isprop function
try
    if isstruct(obj)
        result = isfield(obj, prop);
    elseif isobject(obj)
        % Try to access the property
        try
            get(obj, prop);
            result = true;
        catch
            result = false;
        end
    else
        result = false;
    end
catch
    result = false;
end
end