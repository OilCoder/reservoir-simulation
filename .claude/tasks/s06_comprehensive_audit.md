# Task: Comprehensive 5-Phase Audit of s06_create_base_rock_structure.m

## Agent Assignment: debugger
**Specialized Role**: Policy-aware investigation with mode context analysis and technical correctness validation

## Task Context
Execute comprehensive audit following established s01-s05 methodology on s06_create_base_rock_structure.m. This is part of the MRST workflow sequence where s06 creates base rock structure building on the complete s01→s02→s03→s04→s05 chain.

## 5-Phase Audit Requirements

### PHASE 1: POLICY COMPLIANCE AUDIT
**Check against all 6 policies in .claude/policies/:**

1. **Canon-First Policy**: 
   - Verify script uses config/rock_properties_config.yaml vs hardcoded values
   - Check documentation compliance with docs/Planning/Reservoir_Definition/ specs
   - Validate parameter sourcing follows canonical hierarchy

2. **Data Authority Policy**:
   - Validate all rock data comes from authoritative sources (YAML configs)
   - Check for provenance metadata (timestamp, script, parameters)
   - Ensure no magic numbers or manual estimates in rock properties

3. **Fail Fast Policy**:
   - Check prerequisite validation (s01-s05 dependencies)
   - Validate error handling with clear error messages
   - Context-aware validation (development vs production modes)

4. **Exception Handling Policy**:
   - Review exception vs explicit validation approaches
   - Ensure exceptions only for unpredictable external failures
   - No exception-based flow control

5. **KISS Principle Policy**:
   - Evaluate code simplicity and readability (target <90 lines)
   - Single responsibility function analysis
   - Check for unnecessary complexity

6. **No Over-Engineering Policy**:
   - Functions under 50 lines analysis
   - No speculative code evaluation
   - Verify simplest solution approach

### PHASE 2: INDEPENDENT EXECUTION TEST
**Critical Integration Testing:**

- Test s06 runs independently after s01 initialization
- **Session Management**: Check for same bug found in s04/s05 (session reset issues)
- **Warning Suppression**: Validate clean output without warning spam
- **Professional Output**: Check output formatting and user experience
- **Execution Timing**: Capture and analyze performance
- **Dependency Chain**: Verify s01→s02→s03→s04→s05→s06 flow works

### PHASE 3: DATA STRUCTURE VALIDATION
**Compare against canonical specifications:**

- Check docs/Planning/Simulation_Data_Catalog/00_Data_Catalog_Overview.md
- Validate Grid Geometry Data integration with rock properties
- Verify rock structure metadata addition to grid from s03/s04/s05
- Check output structure, dimensions, metadata completeness
- Validate file naming: should output to data/simulation_data/rock.mat
- Verify VARIABLE_INVENTORY.md compliance for rock variables

### PHASE 4: TECHNICAL CORRECTNESS
**Full execution analysis:**

- Run script and capture complete output
- Analyze errors, warnings, technical issues
- Verify base rock structure application to grid
- Check MRST integration and data flow from previous scripts
- Validate s06 properly loads and enhances existing grid/fault data
- Verify rock properties are technically sound (porosity, permeability ranges)

### PHASE 5: BUG DETECTION
**Comprehensive issue identification:**

- Runtime issues and logic error detection
- Dependency handling validation (s01-s05 chain requirement)
- Error handling and edge case coverage
- Generated data technical soundness verification
- Memory leak and performance issue detection
- Sequential workflow integration validation

## Expected Deliverables

1. **Debug Script**: Create `/workspace/debug/dbg_s06_comprehensive_audit.m` following Rule 5 naming
2. **Detailed Findings**: Policy compliance analysis with mode context
3. **Technical Assessment**: Execution results and technical correctness
4. **Bug Report**: Any issues found with root cause analysis
5. **Scoring**: Grade A/B/C classification matching s01-s05 standards
6. **Recommendations**: Policy-compliant improvement suggestions

## Policy Context for Investigation
- **Validation Mode**: warn (development context)
- **File Context**: Production script in mrst_simulation_scripts/
- **Authority**: YAML configs in config/ directory are canonical
- **Documentation**: docs/Planning/ specifications are authoritative

## Success Criteria
- All 5 phases executed thoroughly
- Policy compliance validated against all 6 policies
- Technical execution verified with clean output
- Same quality level as s01-s05 audits
- Session management bug checked specifically
- Professional audit report with actionable recommendations

Execute with policy-aware investigation approach and document all findings in debug script with comprehensive analysis.