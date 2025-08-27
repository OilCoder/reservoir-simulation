function export_pvt_results(fluid_complete)
% EXPORT_PVT_RESULTS - Export PVT tables to simulation data catalog structure
%
% INPUT:
%   fluid_complete - Complete MRST fluid structure with PVT tables

    % CATALOG STRUCTURE: Save to /workspace/data/simulation_data/
    data_dir = '/workspace/data/simulation_data';
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Create fluid.mat according to canonical specification
    fluid_file = fullfile(data_dir, 'fluid.mat');
    
    % PVT Data Structure (Section 4 of catalog)
    if isfield(fluid_complete, 'pvto') && ~isempty(fluid_complete.pvto)
        pressure_table = fluid_complete.pvto(:,1);
        oil_fvf = fluid_complete.pvto(:,3);
        oil_viscosity = fluid_complete.pvto(:,4);
    else
        % Default pressure points if not available
        pressure_table = linspace(1e5, 400e5, 50)';  % 1-400 bar
        oil_fvf = ones(50, 1) * 1.2;  % Default FVF
        oil_viscosity = ones(50, 1) * 2.0;  % Default viscosity
    end
    
    if isfield(fluid_complete, 'pvtw') && ~isempty(fluid_complete.pvtw)
        water_fvf = ones(size(pressure_table)) * fluid_complete.pvtw(2);
        water_viscosity = ones(size(pressure_table)) * 0.5e-3;  % Default water viscosity
    else
        water_fvf = ones(size(pressure_table));
        water_viscosity = ones(size(pressure_table)) * 0.5e-3;
    end
    
    % Relative Permeability Tables (Section 4 of catalog)
    saturation_table = linspace(0, 1, 100)';
    krw_table = max(0, ((saturation_table - 0.15) / 0.85).^2);  % Corey model
    kro_table = max(0, ((0.8 - saturation_table) / 0.65).^2);
    pcow_table = zeros(size(saturation_table));  % Zero capillary pressure for now
    
    % Fluid Constants (from catalog)
    oil_density = 850.0;    % kg/m³
    water_density = 1000.0; % kg/m³
    oil_viscosity_ref = 2.0;    % cP
    water_viscosity_ref = 0.5;  % cP
    connate_water_sat = 0.15;   % fraction
    residual_oil_sat = 0.20;    % fraction
    
    % Create fluid_complete copy without function handles for saving
    fluid_for_save = struct();
    field_names = fieldnames(fluid_complete);
    for i = 1:length(field_names)
        field_name = field_names{i};
        field_value = fluid_complete.(field_name);
        if isa(field_value, 'function_handle')
            fluid_for_save.(field_name) = sprintf('Function handle removed for Octave compatibility');
        else
            fluid_for_save.(field_name) = field_value;
        end
    end
    
    % Save catalog-compliant fluid properties
    save(fluid_file, 'pressure_table', 'oil_fvf', 'oil_viscosity', ...
         'water_fvf', 'water_viscosity', 'saturation_table', 'krw_table', ...
         'kro_table', 'pcow_table', 'oil_density', 'water_density', ...
         'oil_viscosity_ref', 'water_viscosity_ref', 'connate_water_sat', ...
         'residual_oil_sat', 'fluid_for_save', '-v7');
    
    fprintf('     Fluid data saved to canonical location: %s\n', fluid_file);
    
    % Save using consolidated data structure (final fluid contributor)  
    script_path = fileparts(mfilename('fullpath'));
    script_path = fileparts(fileparts(script_path));  % Go up two levels to get to mrst_simulation_scripts
    addpath(fullfile(script_path, 'utils'));
    save_consolidated_data('fluid', 's11', 'fluid', fluid_for_save);
    fprintf('     ✅ Saved to fluid.mat: fluid\n');
    
    % Maintain legacy compatibility during transition
    try
        base_data_path = fullfile('/workspace', 'data');
        legacy_static_dir = fullfile(base_data_path, 'by_type', 'static', 'fluid');
        if ~exist(legacy_static_dir, 'dir')
            mkdir(legacy_static_dir);
        end
        
        % Save complete fluid structure
        fluid_file = fullfile(legacy_static_dir, 'complete_fluid_blackoil.mat');
        save(fluid_file, 'fluid_complete');
        fprintf('     Legacy compatibility maintained: %s\n', fluid_file);
        
        % Create comprehensive PVT summary
        summary_file = fullfile(legacy_static_dir, 'pvt_comprehensive_summary.txt');
        write_pvt_summary(fluid_complete, summary_file);
        fprintf('     PVT summary saved: %s\n', summary_file);
    catch ME
        fprintf('Warning: Legacy export failed: %s\n', ME.message);
    end
end

function write_pvt_summary(fluid_complete, filename)
% Write comprehensive PVT summary file
    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot create PVT summary file: %s', filename);
    end
    
    try
        fprintf(fid, 'EAGLE WEST FIELD - PVT TABLES SUMMARY\n');
        fprintf(fid, '====================================\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        % Oil PVT summary
        if isfield(fluid_complete, 'pvto')
            fprintf(fid, 'OIL PVT (PVTO) SUMMARY:\n');
            fprintf(fid, '  Table entries: %d\n', size(fluid_complete.pvto, 1));
            fprintf(fid, '  Pressure range: %.1f - %.1f bar\n', ...
                min(fluid_complete.pvto(:,1))/1e5, max(fluid_complete.pvto(:,1))/1e5);
            fprintf(fid, '  Solution GOR range: %.1f - %.1f sm3/sm3\n', ...
                min(fluid_complete.pvto(:,2)), max(fluid_complete.pvto(:,2)));
            fprintf(fid, '\n');
        end
        
        % Water PVT summary
        if isfield(fluid_complete, 'pvtw')
            fprintf(fid, 'WATER PVT (PVTW) SUMMARY:\n');
            fprintf(fid, '  Reference pressure: %.1f bar\n', fluid_complete.pvtw(1)/1e5);
            fprintf(fid, '  Water FVF: %.4f rm3/sm3\n', fluid_complete.pvtw(2));
            fprintf(fid, '  Compressibility: %.2e 1/Pa\n', fluid_complete.pvtw(3));
            fprintf(fid, '\n');
        end
        
        % Gas PVT summary  
        if isfield(fluid_complete, 'pvtg')
            fprintf(fid, 'GAS PVT (PVTG) SUMMARY:\n');
            fprintf(fid, '  Table entries: %d\n', size(fluid_complete.pvtg, 1));
            fprintf(fid, '  Pressure range: %.1f - %.1f bar\n', ...
                min(fluid_complete.pvtg(:,1))/1e5, max(fluid_complete.pvtg(:,1))/1e5);
            fprintf(fid, '\n');
        end
        
        % Surface conditions
        if isfield(fluid_complete, 'surface')
            fprintf(fid, 'SURFACE CONDITIONS:\n');
            fprintf(fid, '  Pressure: %.0f Pa (%.2f bar)\n', ...
                fluid_complete.surface.pressure_pa, fluid_complete.surface.pressure_pa/1e5);
            fprintf(fid, '  Temperature: %.1f K (%.1f°C)\n', ...
                fluid_complete.surface.temperature_k, fluid_complete.surface.temperature_k - 273.15);
        end
        
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing PVT summary: %s', ME.message);
    end
end