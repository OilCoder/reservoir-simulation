function rock_types = s07_define_rock_types()
% S07_DEFINE_ROCK_TYPES - Define rock types for Eagle West Field
%
% SYNTAX:
%   rock_types = s07_define_rock_types()
%
% OUTPUT:
%   rock_types - Structure containing rock type definitions (RT1-RT6)
%
% DESCRIPTION:
%   Define the 6 rock types for Eagle West Field following
%   specifications in 02_Rock_Properties.md.
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Rock Types Definition (Step 7)\n');
    fprintf('======================================================\n\n');
    
    try
        % Load rock properties configuration
        rock_config = load_rock_config();
        
        % Define 6 rock types (RT1-RT6) based on documentation
        rock_types = struct();
        
        % RT1 - High Permeability Sandstone (Upper Zone)
        rock_types(1).id = 'RT1';
        rock_types(1).name = 'High Perm Sandstone';
        rock_types(1).porosity = 0.22;
        rock_types(1).permeability = 150; % mD
        rock_types(1).kv_kh = 0.5;
        
        % RT2 - Medium Permeability Sandstone (Middle Zone)
        rock_types(2).id = 'RT2';
        rock_types(2).name = 'Medium Perm Sandstone';
        rock_types(2).porosity = 0.19;
        rock_types(2).permeability = 85; % mD
        rock_types(2).kv_kh = 0.5;
        
        % RT3 - Low Permeability Sandstone (Lower Zone)
        rock_types(3).id = 'RT3';
        rock_types(3).name = 'Low Perm Sandstone';
        rock_types(3).porosity = 0.15;
        rock_types(3).permeability = 25; % mD
        rock_types(3).kv_kh = 0.5;
        
        % RT4 - Shale Barriers
        rock_types(4).id = 'RT4';
        rock_types(4).name = 'Shale Barrier';
        rock_types(4).porosity = 0.05;
        rock_types(4).permeability = 0.01; % mD
        rock_types(4).kv_kh = 0.1;
        
        % RT5 - Tight Sandstone
        rock_types(5).id = 'RT5';
        rock_types(5).name = 'Tight Sandstone';
        rock_types(5).porosity = 0.08;
        rock_types(5).permeability = 1.0; % mD
        rock_types(5).kv_kh = 0.3;
        
        % RT6 - Cemented Sandstone
        rock_types(6).id = 'RT6';
        rock_types(6).name = 'Cemented Sandstone';
        rock_types(6).porosity = 0.12;
        rock_types(6).permeability = 5.0; % mD
        rock_types(6).kv_kh = 0.4;
        
        % Export rock types
        export_rock_types_data(rock_types);
        
        fprintf('✓ 6 rock types (RT1-RT6) defined successfully\n\n');
        
    catch ME
        fprintf('❌ Rock types definition failed: %s\n', ME.message);
        error('Rock types definition failed: %s', ME.message);
    end

end

function rock_config = load_rock_config()
    run('read_yaml_config.m');
    rock_config = read_yaml_config('config/rock_properties_config.yaml');
end

function export_rock_types_data(rock_types)
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    rock_types_file = fullfile(data_dir, 'rock_types.mat');
    save(rock_types_file, 'rock_types', '');
end

if ~nargout
    rock_types = s07_define_rock_types();
end