# Task Delegation: Fix s21_run_simulation.m Output Display Issues

## AGENT: coder
## VALIDATION_MODE: strict (production accuracy)
## POLICY_CONTEXT: All 6 policies enforced - Canon-First, Data Authority, Fail Fast, Exception Handling, KISS, No Over-Engineering

## IDENTIFIED CRITICAL OUTPUT ISSUES:

### 1. CRITICAL: Incorrect Simulation Duration Display
**Problem**: Line 759 shows "15 years" but configuration shows 40 years (14610 days)
**Root Cause**: Line 734 hardcodes `simulation_results.years = 15;`
**Config Authority**: wells_config.yaml line 10: `development_duration_days: 14610` (40 years exactly)

### 2. Gas Production Display Formatting Issues  
**Problem**: Numbers like "8848991 Mcf" are hard to read
**Improvement**: Format as "8,849 MMcf" or better units

### 3. Missing Key Technical Information
**Gaps**:
- No gas liberation timeline indication (Years 28-40)
- No bubble point reference (2100 psi from fluid_properties_config.yaml)
- No recovery factor percentage  
- No development phase progression (Primary → Waterflood → Gas Liberation)

### 4. Timeline Display Inconsistency
**Problem**: Annual progress shows incorrect years total in loop (line 384)

## REQUIRED FIXES:

### Fix A: Correct Simulation Duration (CRITICAL)
```matlab
% Replace line 734 hardcoded value with actual calculation
simulation_results.years = round(development_days / 365.25);  % Should be 40
```

### Fix B: Enhanced Production Display Format
```matlab
% Better gas formatting (line 762)
fprintf('   - Cumulative gas production: %.1f Bcf (%.0f MMcf)\n', 
        simulation_results.total_gas_bcf, simulation_results.total_gas_mcf/1000);
```

### Fix C: Add Missing Technical Context
```matlab
% Add bubble point and gas liberation context
fprintf('   - Gas liberation: %s (P < %.0f psi bubble point)\n', 
        gas_status, bubble_point_psi);

% Add recovery factor calculation
recovery_factor = (cum_oil_bbl / ooip_estimate) * 100;
fprintf('   - Oil recovery factor: %.1f%% OOIP\n', recovery_factor);

% Add development phases summary
fprintf('   - Development phases: Primary (Yrs 1-5) → Waterflood (Yrs 6-27) → Gas Liberation (Yrs 28-40)\n');
```

### Fix D: Timeline Display Consistency  
```matlab
% Fix line 384 to use correct total years
fprintf('     Year %d of %.0f: %d wells active\n', step/12, 40.0, length(W_active));
```

## DATA AUTHORITY SOURCES:
- wells_config.yaml: `development_duration_days: 14610` (40 years)
- fluid_properties_config.yaml: `bubble_point: 2100.0` (psi)
- Configuration-driven timeline calculation (Canon-First Policy)

## SUCCESS CRITERIA:
✅ Output shows correct 40 years duration
✅ All displayed numbers match YAML configuration  
✅ Gas production formatted clearly and readable
✅ Technical context includes bubble point and phases
✅ Timeline progression consistent throughout
✅ Recovery factors and GOR properly displayed

## FILES TO MODIFY:
- `/workspace/mrst_simulation_scripts/s21_run_simulation.m`
  - Lines: 734 (years calculation), 759-769 (summary output), 384 (timeline display)
  - Functions: `create_results_summary()`, `print_simulation_summary()`, simulation loop

## CONSTRAINTS:
- Use only Canon-First Policy data sources (YAML configs)
- No hardcoded values - derive from authoritative sources
- Maintain existing output structure, just fix accuracy
- Clear, professional engineering output format