function seconds = day()
    % DAY - Convert days to seconds for MRST time unit standardization
    %
    % SYNOPSIS:
    %   seconds = day()
    %
    % DESCRIPTION:
    %   Returns the canonical MRST conversion factor from days to seconds.
    %   This function provides the standard time unit conversion used throughout
    %   MRST for schedule and simulation time calculations.
    %
    % RETURNS:
    %   seconds - Number of seconds in one day (86400)
    %
    % NOTE:
    %   This is a canonical MRST utility function. The value 86400 is the
    %   standard seconds per day conversion factor used in all MRST time
    %   calculations and schedule definitions.
    %
    % SEE ALSO:
    %   year, month, hour, minute
    
    % Canon-First Policy: Use documented MRST standard
    % Data Authority: Canonical time conversion (86400 seconds/day)
    seconds = 86400;
end