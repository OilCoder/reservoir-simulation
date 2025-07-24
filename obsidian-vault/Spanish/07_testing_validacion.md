# Guía de Testing y Validación

## Descripción General

El sistema de testing de GeomechML garantiza la calidad y confiabilidad del código mediante pruebas automatizadas, validación de configuraciones y verificación de resultados de simulación.

## Arquitectura de Testing

### Estructura de Tests

```
tests/
├── test_01_sim_scripts_util_read_config.m    # Tests de configuración
├── test_02_sim_scripts_setup_field.m         # Tests de setup de campo
└── README.md                                 # Documentación de tests
```

### Tipos de Tests

1. **Tests Unitarios** - Validación de funciones individuales
2. **Tests de Integración** - Verificación de workflow completo
3. **Tests de Configuración** - Validación de archivos YAML
4. **Tests de Datos** - Verificación de integridad de datasets

## Tests de Configuración

### `test_01_sim_scripts_util_read_config.m`

Valida el sistema de configuración YAML:

```octave
function test_01_sim_scripts_util_read_config()
    % Tests del sistema de configuración YAML
    fprintf('=== Testing YAML Configuration System ===\n');
    
    % Ejecutar todos los tests
    test_config_loading_basic();
    test_setup_field_with_config();
    test_config_modification();
    
    fprintf('\n✅ All configuration tests PASSED!\n');
end
```

### Tests Incluidos

#### 1. `test_config_loading_basic()`
**Propósito**: Verificar carga básica de configuración
**Validaciones**:
- Archivo YAML existe y es legible
- Estructura de configuración correcta
- Tipos de datos apropiados
- Valores dentro de rangos válidos

```octave
function test_config_loading_basic()
    % Test básico de carga de configuración
    config_file = '../config/reservoir_config.yaml';
    
    % Verificar que el archivo existe
    assert(exist(config_file, 'file') == 2, 'Config file not found');
    
    % Cargar configuración
    config = util_read_config(config_file);
    
    % Verificar estructura básica
    assert(isfield(config, 'grid'), 'Missing grid section');
    assert(isfield(config, 'porosity'), 'Missing porosity section');
    assert(isfield(config, 'wells'), 'Missing wells section');
    
    % Verificar valores críticos
    assert(config.grid.nx > 0, 'Invalid grid nx');
    assert(config.grid.ny > 0, 'Invalid grid ny');
    assert(config.porosity.base_value > 0, 'Invalid porosity base');
    
    fprintf('✅ Basic config loading: PASSED\n');
end
```

#### 2. `test_setup_field_with_config()`
**Propósito**: Verificar integración con setup_field
**Validaciones**:
- Grid se crea correctamente
- Propiedades de roca son válidas
- Dimensiones coinciden con configuración

```octave
function test_setup_field_with_config()
    % Test de integración con setup_field
    config_file = '../config/reservoir_config.yaml';
    
    % Ejecutar setup_field
    [G, rock, fluid] = setup_field(config_file);
    
    % Verificar grid
    assert(G.cells.num == 400, 'Wrong number of cells');
    assert(size(rock.poro, 1) == 400, 'Wrong porosity size');
    assert(size(rock.perm, 1) == 400, 'Wrong permeability size');
    
    % Verificar rangos físicos
    assert(all(rock.poro >= 0.01), 'Porosity too low');
    assert(all(rock.poro <= 0.5), 'Porosity too high');
    assert(all(rock.perm >= 1e-15), 'Permeability too low');
    
    fprintf('✅ Setup field integration: PASSED\n');
end
```

#### 3. `test_config_modification()`
**Propósito**: Verificar modificación de configuraciones
**Validaciones**:
- Configuración temporal funciona
- Modificaciones se aplican correctamente
- Validación de parámetros modificados

```octave
function test_config_modification()
    % Test de modificación de configuración
    
    % Crear configuración temporal
    temp_config = write_temp_config();
    
    try
        % Cargar configuración modificada
        config = util_read_config(temp_config);
        
        % Verificar modificaciones
        assert(config.grid.nx == 10, 'Grid modification failed');
        assert(config.simulation.total_time == 180, 'Time modification failed');
        
        fprintf('✅ Config modification: PASSED\n');
        
    catch ME
        % Limpiar archivo temporal
        if exist(temp_config, 'file')
            delete(temp_config);
        end
        rethrow(ME);
    end
    
    % Limpiar archivo temporal
    if exist(temp_config, 'file')
        delete(temp_config);
    end
end
```

## Tests de Setup de Campo

### `test_02_sim_scripts_setup_field.m`

Valida la configuración de campo y unidades:

```octave
function test_02_sim_scripts_setup_field()
    % Tests de configuración de campo con unidades
    fprintf('=== Testing Field Units Configuration ===\n');
    
    % Ejecutar todos los tests
    test_field_units_config();
    test_setup_field_units();
    test_fluid_definition_units();
    test_schedule_creation_units();
    
    fprintf('\n✅ All field units tests PASSED!\n');
end
```

### Tests Incluidos

#### 1. `test_field_units_config()`
**Propósito**: Verificar configuración de unidades de campo
**Validaciones**:
- Unidades correctas (psi, ft, bbl/day)
- Conversiones apropiadas
- Rangos físicos realistas

#### 2. `test_setup_field_units()`
**Propósito**: Verificar setup de campo con unidades
**Validaciones**:
- Grid en unidades correctas
- Propiedades de roca en unidades apropiadas
- Consistencia dimensional

#### 3. `test_fluid_definition_units()`
**Propósito**: Verificar definición de fluidos
**Validaciones**:
- Propiedades de fluidos correctas
- Unidades consistentes
- Valores físicamente realistas

#### 4. `test_schedule_creation_units()`
**Propósito**: Verificar creación de schedule
**Validaciones**:
- Controles de pozos correctos
- Unidades de tasas apropiadas
- Timesteps válidos

## Ejecución de Tests

### Ejecutar Tests Individuales

```octave
% Test específico de configuración
cd tests
test_01_sim_scripts_util_read_config

% Test específico de setup de campo
test_02_sim_scripts_setup_field
```

### Ejecutar Todos los Tests

```octave
% Script para ejecutar todos los tests
function run_all_tests()
    fprintf('=== GeomechML Test Suite ===\n');
    
    test_files = {
        'test_01_sim_scripts_util_read_config',
        'test_02_sim_scripts_setup_field'
    };
    
    passed = 0;
    failed = 0;
    
    for i = 1:length(test_files)
        try
            fprintf('\n--- Running %s ---\n', test_files{i});
            eval(test_files{i});
            passed = passed + 1;
        catch ME
            fprintf('❌ FAILED: %s\n', ME.message);
            failed = failed + 1;
        end
    end
    
    fprintf('\n=== Test Summary ===\n');
    fprintf('Passed: %d\n', passed);
    fprintf('Failed: %d\n', failed);
    
    if failed == 0
        fprintf('🎉 All tests PASSED!\n');
    else
        fprintf('⚠️  Some tests FAILED!\n');
    end
end
```

## Validación de Simulación

### Tests de Workflow Completo

```octave
function test_complete_workflow()
    % Test del workflow completo de simulación
    fprintf('=== Testing Complete Simulation Workflow ===\n');
    
    try
        % Ejecutar workflow completo
        main_phase1;
        
        % Verificar salidas
        assert(exist('data/raw/snap_001.mat', 'file') == 2, 'Missing snapshot files');
        assert(exist('data/raw/metadata.yaml', 'file') == 2, 'Missing metadata');
        
        % Verificar integridad de datos
        validate_dataset('data/raw/');
        
        fprintf('✅ Complete workflow: PASSED\n');
        
    catch ME
        fprintf('❌ Complete workflow: FAILED\n');
        fprintf('Error: %s\n', ME.message);
        rethrow(ME);
    end
end
```

### Validación de Datos

```octave
function validate_dataset(data_dir)
    % Validar integridad del dataset generado
    
    % Verificar archivos de snapshots
    files = dir(fullfile(data_dir, 'snap_*.mat'));
    assert(length(files) == 50, 'Wrong number of snapshot files');
    
    % Verificar contenido de snapshots
    for i = 1:length(files)
        data = load(fullfile(data_dir, files(i).name));
        snapshot = data.snapshot;
        
        % Verificar estructura
        required_fields = {'sigma_eff', 'phi', 'k', 'rock_id'};
        for j = 1:length(required_fields)
            assert(isfield(snapshot, required_fields{j}), ...
                   sprintf('Missing field: %s', required_fields{j}));
        end
        
        % Verificar dimensiones
        assert(all(size(snapshot.sigma_eff) == [20, 20]), 'Wrong dimensions');
        
        % Verificar rangos físicos
        assert(all(snapshot.phi(:) >= 0.01), 'Invalid porosity range');
        assert(all(snapshot.k(:) >= 0.1), 'Invalid permeability range');
        assert(all(snapshot.sigma_eff(:) >= 1000), 'Invalid stress range');
    end
    
    % Verificar metadata
    assert(exist(fullfile(data_dir, 'metadata.yaml'), 'file') == 2, ...
           'Missing metadata file');
    assert(exist(fullfile(data_dir, 'metadata.mat'), 'file') == 2, ...
           'Missing metadata MAT file');
    
    fprintf('✅ Dataset validation: PASSED\n');
end
```

## Tests de Rendimiento

### Benchmarks de Simulación

```octave
function benchmark_simulation()
    % Benchmark de rendimiento de simulación
    fprintf('=== Simulation Performance Benchmark ===\n');
    
    % Configuración de benchmark
    configs = {
        struct('nx', 10, 'ny', 10, 'timesteps', 10),  % Pequeño
        struct('nx', 20, 'ny', 20, 'timesteps', 50),  % Estándar
        struct('nx', 50, 'ny', 50, 'timesteps', 100)  % Grande
    };
    
    for i = 1:length(configs)
        config = configs{i};
        
        fprintf('Testing grid %dx%d, %d timesteps...\n', ...
                config.nx, config.ny, config.timesteps);
        
        % Medir tiempo de ejecución
        tic;
        run_simulation_with_config(config);
        elapsed = toc;
        
        fprintf('Time: %.2f seconds\n', elapsed);
        
        % Verificar memoria
        memory_info = memory;
        fprintf('Memory used: %.1f MB\n', memory_info.MemUsedMATLAB / 1e6);
    end
end
```

## Debugging y Troubleshooting

### Tests de Debug

```octave
function test_debug_capabilities()
    % Test de capacidades de debug
    fprintf('=== Testing Debug Capabilities ===\n');
    
    % Activar modo verbose
    mrstVerbose on;
    
    % Ejecutar simulación con logging
    try
        main_phase1;
        fprintf('✅ Debug mode: PASSED\n');
    catch ME
        fprintf('❌ Debug mode: FAILED\n');
        fprintf('Error: %s\n', ME.message);
    end
    
    % Desactivar modo verbose
    mrstVerbose off;
end
```

### Validación de Configuraciones

```octave
function test_invalid_configurations()
    % Test de manejo de configuraciones inválidas
    fprintf('=== Testing Invalid Configuration Handling ===\n');
    
    invalid_configs = {
        struct('grid', struct('nx', 0)),           % Grid inválido
        struct('porosity', struct('base_value', -0.1)), % Porosidad negativa
        struct('wells', struct('producer_bhp', 0))  % BHP inválido
    };
    
    for i = 1:length(invalid_configs)
        try
            % Intentar usar configuración inválida
            setup_field_with_config(invalid_configs{i});
            fprintf('❌ Should have failed for invalid config %d\n', i);
        catch ME
            fprintf('✅ Correctly rejected invalid config %d\n', i);
        end
    end
end
```

## Integración Continua

### Script de CI/CD

```octave
function ci_test_suite()
    % Suite de tests para integración continua
    fprintf('=== CI/CD Test Suite ===\n');
    
    test_results = struct();
    
    % Tests básicos
    test_results.config = run_safe_test(@test_01_sim_scripts_util_read_config);
    test_results.setup = run_safe_test(@test_02_sim_scripts_setup_field);
    
    % Tests de integración
    test_results.workflow = run_safe_test(@test_complete_workflow);
    test_results.performance = run_safe_test(@benchmark_simulation);
    
    % Generar reporte
    generate_test_report(test_results);
    
    % Código de salida
    failed_tests = sum(~struct2array(test_results));
    if failed_tests > 0
        error('CI/CD: %d tests failed', failed_tests);
    else
        fprintf('🎉 CI/CD: All tests PASSED!\n');
    end
end

function success = run_safe_test(test_function)
    % Ejecutar test de forma segura
    try
        test_function();
        success = true;
    catch ME
        fprintf('Test failed: %s\n', ME.message);
        success = false;
    end
end
```

## Mejores Prácticas

### Escritura de Tests

1. **Nombres Descriptivos**: Usar nombres que expliquen qué se está probando
2. **Tests Independientes**: Cada test debe ser autocontenido
3. **Cleanup**: Limpiar archivos temporales después de cada test
4. **Assertions Claras**: Usar mensajes de error descriptivos

### Organización de Tests

1. **Agrupación Lógica**: Agrupar tests relacionados
2. **Orden de Ejecución**: Tests básicos primero, complejos después
3. **Documentación**: Documentar propósito y validaciones de cada test
4. **Mantenimiento**: Actualizar tests cuando cambie el código

### Validación de Datos

1. **Rangos Físicos**: Verificar que los valores estén en rangos realistas
2. **Consistencia**: Verificar relaciones entre variables
3. **Evolución Temporal**: Verificar que los cambios sean físicamente correctos
4. **Balance de Masa**: Verificar conservación de propiedades

---

*Fuente: `tests/` - Sistema de pruebas automatizadas* 