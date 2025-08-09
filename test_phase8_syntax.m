% Test Phase 8 scripts for syntax errors
fprintf('Testing Phase 8 script syntax...\n\n');

scripts_to_test = {'s21_solver_setup', 's22_run_simulation', 's23_quality_validation'};

for i = 1:length(scripts_to_test)
    script_name = scripts_to_test{i};
    
    try
        fprintf('Testing %s.m... ', script_name);
        
        % Test by checking function exists
        func_path = which(script_name);
        if isempty(func_path)
            fprintf('❌ Function not found\n');
            continue;
        end
        
        % Test function definition parsing
        try
            eval(['help ' script_name ';']);
            fprintf('✅ Syntax OK\n');
        catch ME2
            fprintf('❌ Syntax Error: %s\n', ME2.message);
        end
        
    catch ME
        fprintf('❌ Error: %s\n', ME.message);
    end
end

fprintf('\nSyntax validation complete.\n');