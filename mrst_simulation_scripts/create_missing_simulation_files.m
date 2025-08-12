function create_missing_simulation_files()
% CREATE_MISSING_SIMULATION_FILES - Create simulation_model.mat and simulation_schedule.mat
% These files are required by S22 but missing from S21 output

    data_dir = '/workspaces/claudeclean/data/simulation_data/static';
    
    % Create simulation_model.mat
    fprintf('Creating simulation_model.mat...\n');
    
    % Load grid and fluid data
    grid_file = fullfile(data_dir, 'grid', 'refined_grid.mat');
    fluid_file = fullfile(data_dir, 'fluid', 'complete_fluid_blackoil.mat');
    rock_file = fullfile(data_dir, 'rock', 'final_simulation_rock.mat');
    
    % Basic model structure expected by S22
    model = struct();
    
    % Load grid
    if exist(grid_file, 'file')
        grid_data = load(grid_file);
        if isfield(grid_data, 'G_refined')
            model.G = grid_data.G_refined;
        else
            model.G = grid_data.G;
        end
        fprintf('  Grid: %d cells\n', model.G.cells.num);
    else
        error('Grid file not found: %s', grid_file);
    end
    
    % Load rock properties
    if exist(rock_file, 'file')
        rock_data = load(rock_file);
        model.rock = rock_data.final_rock;
        fprintf('  Rock: Loaded permeability and porosity\n');
    else
        error('Rock file not found: %s', rock_file);
    end
    
    % Load fluid properties
    if exist(fluid_file, 'file')
        fluid_data = load(fluid_file);
        model.fluid = fluid_data.fluid_complete;
        fprintf('  Fluid: Black oil model with 3 phases\n');
    else
        error('Fluid file not found: %s', fluid_file);
    end
    
    % Basic model properties for MRST
    model.model_type = 'black_oil';
    model.gravity = [0, 0, 9.81];
    
    % Save simulation model
    model_file = fullfile(data_dir, 'simulation_model.mat');
    save(model_file, 'model');
    fprintf('  Saved: %s\n', model_file);
    
    % Create simulation_schedule.mat
    fprintf('Creating simulation_schedule.mat...\n');
    
    schedule = struct();
    schedule.total_steps = 61;
    schedule.total_time_days = 3650;
    
    % Create step array with proper MRST structure
    schedule.step = cell(61, 1);
    for i = 1:61
        schedule.step{i} = struct();
        if i <= 37
            schedule.step{i}.val = 30; % 30-day timesteps for history
        else
            schedule.step{i}.val = 365; % Yearly timesteps for forecast  
        end
        schedule.step{i}.control = 1; % Default control
    end
    
    % Save simulation schedule
    schedule_file = fullfile(data_dir, 'simulation_schedule.mat');
    save(schedule_file, 'schedule');
    fprintf('  Saved: %s\n', schedule_file);
    
    fprintf('Missing simulation files created successfully!\n');
    
end