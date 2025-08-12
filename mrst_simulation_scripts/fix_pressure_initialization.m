function fix_pressure_initialization()
% FIX_PRESSURE_INITIALIZATION - Fix pressure file format for S22 compatibility

    data_dir = '/workspaces/claudeclean/data/simulation_data/static';
    pressure_file = fullfile(data_dir, 'pressure_initialization.mat');
    
    % Load existing pressure data
    pressure_data = load(pressure_file);
    
    % Rename field to what S22 expects  
    pressure = pressure_data.initial_pressure; % Assume in Pascal already
    
    % Save in format expected by S22 (pressure in Pa)
    save(pressure_file, 'pressure');
    
    fprintf('Fixed pressure initialization file format for S22 compatibility\n');
    
end