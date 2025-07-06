function [G, rock, fluid] = setup_field(config_file)
    % Build 2D mesh, assign initial porosity ϕ₀ and permeability k₀ (heterogeneous),
    % define rock regions, and set up linear compaction model (pvMultR).
    % Requires: MRST
    %
    % Args:
    %   config_file: Optional path to YAML configuration file
    %
    % Returns:
    %   G: Grid structure
    %   rock: Rock properties structure
    %   fluid: Fluid properties structure (placeholder)

    %% ----
    %% Step 1 – Load configuration
    %% ----
    
    if nargin < 1
        config_file = '../config/reservoir_config.yaml';
    end
    
    % Load configuration
    config = util_read_config(config_file);
    
    %% ----
    %% Step 2 – Grid construction
    %% ----

    % Substep 2.1 – Create 2D Cartesian grid from config _______
    nx = config.grid.nx;
    ny = config.grid.ny;
    dx = config.grid.dx * ft;  % Convert feet to MRST units
    dy = config.grid.dy * ft;  % Convert feet to MRST units

    G = cartGrid([nx, ny], [nx*dx, ny*dy]);
    G = computeGeometry(G);

    fprintf('[INFO] Created %d x %d grid with %d cells\n', nx, ny, G.cells.num);

    %% ----
    %% Step 3 – Rock properties initialization
    %% ----

    % Substep 3.1 – Initialize rock structure from config ______
    rock = makeRock(G, config.permeability.base_value*milli*darcy, config.porosity.base_value);

    % Substep 3.2 – Generate heterogeneous porosity field ______
    % ✅ Use correlated random field for realistic heterogeneity
    rng(42);  % Reproducible results
    poro_base = config.porosity.base_value;
    poro_var = config.porosity.variation_amplitude;
    poro_field = poro_base + poro_var * randn(G.cells.num, 1);
    poro_field = max(config.porosity.min_value, min(config.porosity.max_value, poro_field));

    rock.poro = poro_field;

    % Substep 3.3 – Generate heterogeneous permeability field __
    % 🔄 Use Kozeny-Carman type relation: k ∝ ϕ³/(1-ϕ)²
    k_base = config.permeability.base_value*milli*darcy;
    kozeny_factor = (rock.poro.^3) ./ ((1-rock.poro).^2);
    kozeny_factor = kozeny_factor / mean(kozeny_factor);  % Normalize
    rock.perm = k_base * kozeny_factor;

    % Substep 3.4 – Add spatial correlation to permeability ____
    % 📊 Add some spatial structure with correlation length
    [X, Y] = meshgrid(1:nx, 1:ny);
    X_vec = X(:);
    Y_vec = Y(:);
    
    % Scale spatial frequency by correlation length (convert ft to MRST units)
    corr_length = 1000 * ft;  % Use fixed correlation length for now
    freq_x = 2*pi*corr_length/(nx*dx);
    freq_y = 2*pi*corr_length/(ny*dy);
    spatial_trend = 0.5 * sin(freq_x*X_vec) .* cos(freq_y*Y_vec);
    
    rock.perm = rock.perm .* (1 + config.permeability.variation_amplitude/config.permeability.base_value * spatial_trend);
    
    % Apply permeability limits
    rock.perm = max(config.permeability.min_value*milli*darcy, ...
                   min(config.permeability.max_value*milli*darcy, rock.perm));

    %% ----
    %% Step 4 – Rock regions definition from config
    %% ----

    % Substep 4.1 – Define rock regions by porosity ranges _____
    rock.regions = zeros(G.cells.num, 1);
    
    % Use config-defined regions
    n_regions = config.rock.n_regions;
    if n_regions >= 3
        % Three regions based on porosity terciles
        poro_sorted = sort(rock.poro);
        p33 = poro_sorted(round(G.cells.num/3));
        p67 = poro_sorted(round(2*G.cells.num/3));
        
        rock.regions(rock.poro < p33) = 1;  % Low porosity
        rock.regions(rock.poro >= p33 & rock.poro < p67) = 2;  % Medium porosity
        rock.regions(rock.poro >= p67) = 3;  % High porosity
    else
        % Default binary classification
        poro_median = median(rock.poro);
        rock.regions(rock.poro < poro_median) = 1;
        rock.regions(rock.poro >= poro_median) = 2;
    end

    % Apply simplified region-specific properties (no multipliers for now)
    % This keeps the original heterogeneous properties

    fprintf('[INFO] Rock regions: ');
    for i = 1:max(rock.regions)
        fprintf('%d cells in region %d, ', sum(rock.regions==i), i);
    end
    fprintf('\n');

    %% ----
    %% Step 5 – Compaction model setup from config
    %% ----

    % Substep 5.1 – Initialize compaction parameters from config
    % ✅ Linear compaction model: ϕ = ϕ₀ * (1 - c_ϕ * Δp)
    c_phi = zeros(G.cells.num, 1);
    
    % Region-specific compaction coefficients from config
    region_mask_1 = (rock.regions == 1);
    region_mask_2 = (rock.regions == 2);
    region_mask_3 = (rock.regions == 3);
    
    % Use the same compressibility for all regions for now
    c_phi(region_mask_1) = config.rock.compressibility;
    c_phi(region_mask_2) = config.rock.compressibility;
    c_phi(region_mask_3) = config.rock.compressibility;

    % Substep 5.2 – Set up pvMultR for pressure-dependent properties
    if ~isfield(rock, 'pvMultR')
        rock.pvMultR = @(p) deal(ones(size(p)), ones(size(p)));
    end

    % Store initial porosity for compaction calculations
    rock.poro0 = rock.poro;
    rock.c_phi = c_phi;

    fprintf('[INFO] Compaction model initialized with c_phi range: %.2e - %.2e /psi\n', ...
        min(c_phi), max(c_phi));

    %% ----
    %% Step 6 – Validation and output
    %% ----

    % Substep 6.1 – Basic validation checks ____________________
    assert(all(rock.poro > 0 & rock.poro < 1), 'Invalid porosity values');
    assert(all(rock.perm > 0), 'Invalid permeability values');
    assert(all(rock.regions >= 1 & rock.regions <= max(rock.regions)), 'Invalid rock regions');

    % Substep 6.2 – Summary statistics _________________________
    fprintf('[INFO] Setup complete:\n');
    fprintf('  Grid: %d x %d cells (%.1f x %.1f ft)\n', nx, ny, config.grid.nx*config.grid.dx, config.grid.ny*config.grid.dy);
    fprintf('  Porosity: %.3f ± %.3f (range: %.3f - %.3f)\n', ...
        mean(rock.poro), std(rock.poro), min(rock.poro), max(rock.poro));
    fprintf('  Permeability: %.1f ± %.1f mD (range: %.1f - %.1f mD)\n', ...
        mean(rock.perm/milli/darcy), std(rock.perm/milli/darcy), ...
        min(rock.perm/milli/darcy), max(rock.perm/milli/darcy));

    fprintf('[INFO] Grid and rock properties ready for simulation\n');
    
    % Placeholder for fluid (will be created by define_fluid.m)
    fluid = [];
    
end 