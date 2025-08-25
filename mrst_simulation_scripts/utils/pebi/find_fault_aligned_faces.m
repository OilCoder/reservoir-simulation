function fault_faces = find_fault_aligned_faces(G, x1, y1, x2, y2)
% Find grid faces aligned with fault line using configuration tolerance

    fault_faces = [];
    
    % Load tolerance from configuration
    script_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
    addpath(fullfile(script_dir, 'utils'));
    config = read_yaml_config(config_file, true);
    tolerance = config.pebi_grid.geometry_parameters.fault_alignment_tolerance;
    
    % Check each face for alignment with fault
    for i = 1:G.faces.num
        % Get face center
        if isfield(G.faces, 'centroids')
            face_center = G.faces.centroids(i, 1:2);
        else
            nodes = G.faces.nodes(G.faces.nodePos(i):G.faces.nodePos(i+1)-1);
            face_coords = G.nodes.coords(nodes, 1:2);
            face_center = mean(face_coords, 1);
        end
        
        % Calculate distance from face center to fault line
        dist = calculate_point_to_line_distance_single(face_center(1), face_center(2), x1, y1, x2, y2);
        
        % Include face if within tolerance
        if dist <= tolerance
            fault_faces(end+1) = i;
        end
    end
end