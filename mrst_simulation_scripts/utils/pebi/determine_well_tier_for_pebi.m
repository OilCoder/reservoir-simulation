function tier = determine_well_tier_for_pebi(well_name, wells_config)
% Get PEBI sizing parameters for well tier from wells_config.yaml

    if ~isfield(wells_config, 'grid_refinement')
        error('Missing grid_refinement section in wells_config.yaml');
    end
    
    gr = wells_config.grid_refinement;
    
    % Check critical wells tier
    if isfield(gr, 'critical_wells') && ismember(well_name, gr.critical_wells)
        tier.size = gr.critical_pebi_cell_size;
        tier.radius = gr.critical_pebi_influence_radius;
        tier.name = 'critical';
        return;
    end
    
    % Check standard wells tier
    if isfield(gr, 'standard_wells') && ismember(well_name, gr.standard_wells)
        tier.size = gr.standard_pebi_cell_size;
        tier.radius = gr.standard_pebi_influence_radius;
        tier.name = 'standard';
        return;
    end
    
    % Check marginal wells tier
    if isfield(gr, 'marginal_wells') && ismember(well_name, gr.marginal_wells)
        tier.size = gr.marginal_pebi_cell_size;
        tier.radius = gr.marginal_pebi_influence_radius;
        tier.name = 'marginal';
        return;
    end
    
    error('Well %s not found in canonical tier classification', well_name);
end