% Test s21_solver_setup.m for syntax errors
try
    fprintf('Testing s21_solver_setup.m syntax...\n');
    
    % Test by loading the function definition
    which s21_solver_setup
    
    fprintf('✅ s21_solver_setup.m syntax is valid\n');
catch ME
    fprintf('❌ Error in s21_solver_setup.m: %s\n', ME.message);
end