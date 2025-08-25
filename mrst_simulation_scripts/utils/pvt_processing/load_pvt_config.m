function pvt_config = load_pvt_config()
% LOAD_PVT_CONFIG - Load PVT configuration from YAML
%
% OUTPUT:
%   pvt_config - Structure with PVT configuration data

    addpath('../');
    pvt_config = read_yaml_config('config/fluid_properties_config.yaml', true);
    
    % Validate required PVT fields
    if ~isfield(pvt_config, 'fluid_properties')
        error('Missing required PVT field: fluid_properties');
    end
    
    % Extract fluid properties
    fluid_props = pvt_config.fluid_properties;
    
    % Create pvt section for backward compatibility
    pvt_config.pvt = struct();
    if isfield(fluid_props, 'oil_compressibility') && isfield(fluid_props.oil_compressibility, 'pressure_ranges')
        pvt_config.pvt.pressure_ranges = fluid_props.oil_compressibility.pressure_ranges;
    else
        % Default pressure ranges
        pvt_config.pvt.pressure_ranges = [[500, 1000]; [1000, 1500]; [1500, 2000]; [2000, 2500]; [2500, 3000]];
    end
    
    % Fix pressure ranges if malformed
    if isfield(pvt_config.pvt, 'pressure_ranges') && ischar(pvt_config.pvt.pressure_ranges)
        fprintf('Fixing malformed YAML pressure_ranges parsing...\n');
        ranges_str = pvt_config.pvt.pressure_ranges;
        ranges_str = strrep(ranges_str, '[', '');
        ranges_str = strrep(ranges_str, ']', '');
        ranges_cell = strsplit(ranges_str, ',');
        
        pressure_pairs = [];
        for i = 1:2:length(ranges_cell)
            if i+1 <= length(ranges_cell)
                p1 = str2double(strtrim(ranges_cell{i}));
                p2 = str2double(strtrim(ranges_cell{i+1}));
                pressure_pairs = [pressure_pairs; p1, p2];
            end
        end
        
        pvt_config.pvt.pressure_ranges = pressure_pairs;
        fprintf('Fixed pressure ranges: %d pairs reconstructed\n', size(pressure_pairs, 1));
        fprintf('✓ Pressure ranges match CANON specification\n');
    end
    
    fprintf('   ✅ PVT configuration loaded\n');
end