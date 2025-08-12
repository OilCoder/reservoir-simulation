function export_pvt_results(fluid_complete)
% EXPORT_PVT_RESULTS - Export PVT tables and comprehensive summary
%
% INPUT:
%   fluid_complete - Complete MRST fluid structure with PVT tables

    % Export complete fluid with PVT tables
    static_dir = '/workspaces/claudeclean/data/simulation_data/static/fluid';
    if ~exist(static_dir, 'dir')
        mkdir(static_dir);
    end
    
    % Save complete fluid structure
    fluid_file = fullfile(static_dir, 'complete_fluid_blackoil.mat');
    save(fluid_file, 'fluid_complete');
    fprintf('   ✅ Complete fluid saved: %s\n', fluid_file);
    
    % Save PVT tables separately for easy access
    pvt_file = fullfile(static_dir, 'pvt_tables.mat');
    pvt_results = struct();
    pvt_results.pvto = fluid_complete.pvto;
    pvt_results.pvtw = fluid_complete.pvtw;
    pvt_results.pvtg = fluid_complete.pvtg;
    pvt_results.surface = fluid_complete.surface;
    save(pvt_file, 'pvt_results');
    fprintf('   ✅ PVT tables saved: %s\n', pvt_file);
    
    % Create comprehensive PVT summary
    summary_file = fullfile(static_dir, 'pvt_comprehensive_summary.txt');
    write_pvt_summary(fluid_complete, summary_file);
    fprintf('   ✅ PVT summary saved: %s\n', summary_file);
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