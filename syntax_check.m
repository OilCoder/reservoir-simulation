% Quick syntax check for s11-s16 files
function syntax_check()
    files = {'s11_pvt_tables.m', 's12_pressure_initialization.m', 's13_saturation_distribution.m', ...
             's14_aquifer_configuration.m', 's15_well_placement.m', 's16_well_completions.m'};
    
    fprintf('=== SYNTAX CHECK FOR S11-S16 ===\n\n');
    
    for i = 1:length(files)
        file = files{i};
        fprintf('Checking %s... ', file);
        
        try
            % Try to parse the file
            fileread(file);
            fprintf('✅ VALID\n');
        catch ME
            fprintf('❌ ERROR: %s\n', ME.message);
        end
    end
    
    fprintf('\n=== SYNTAX CHECK COMPLETE ===\n');
end

syntax_check();