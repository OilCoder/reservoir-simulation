function production_results = s24_production_analysis()
% S24_PRODUCTION_ANALYSIS - Analyze Production Performance
    addpath('utils'); run('utils/print_utils.m');
    print_step_header('S24', 'Production Performance Analysis');
    
    total_start_time = tic;
    production_results = struct('status', 'completed', 'analysis_date', datestr(now));
    
    try
        % Step 1 – Load Simulation Results
        step_start = tic;
        addpath('utils/production_analysis');
        [simulation_data, ~] = load_simulation_results();
        print_step_result(1, 'Load Simulation Results', toc(step_start), true);
        
        % Step 2 – Calculate Field Production Rates  
        step_start = tic;
        production_results.field_rates = calculate_field_rates(simulation_data);
        print_step_result(2, 'Calculate Field Production Rates', toc(step_start), true);
        
        % Step 3 – Export Production Data & Analysis
        step_start = tic;
        export_production_data(production_results);
        print_step_result(3, 'Export Production Data & Analysis', toc(step_start), true);
        
    catch ME
        fprintf('   ❌ Production analysis failed: %s\n', ME.message);
        production_results.status = 'failed';
        production_results.error = ME.message;
        rethrow(ME);
    end
    
    print_step_footer(total_start_time, 'Production Analysis Complete');
end