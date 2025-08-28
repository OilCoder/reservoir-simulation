# COMPREHENSIVE AUDIT TASK: s13_saturation_distribution.m

## TASK SPECIFICATION
Execute comprehensive audit of `s13_saturation_distribution.m` using proven 5-phase methodology for Eagle West Field MRST script.

## CONTEXT
- **Script Role**: Critical Initial Conditions Chain component (s12→s13→s14 = state.mat)
- **Current Status**: s12 successfully executed, s13 needs audit before s14
- **Data Dependencies**: grid.mat (7.7MB), rock.mat (869K), fluid.mat (875K), state.mat (357K)
- **Expected Output**: Enhanced state.mat (~10MB per Data Catalog Overview)

## 5-PHASE AUDIT METHODOLOGY

### Phase 1: Policy Compliance Analysis
Analyze against all 6 code generation policies:
- **Canon-First Policy**: Check canonical data loading from /workspace/data/mrst/
- **Data Authority Policy**: Verify no hardcoded domain values
- **Fail Fast Policy**: Check explicit validation patterns
- **Exception Handling Policy**: Validate exception usage vs explicit validation
- **KISS Principle Policy**: Assess simplicity and directness
- **No Over-Engineering Policy**: Check for appropriate scope

### Phase 2: Independent Execution Analysis
- **Session Management**: Verify check_and_load_mrst_session() usage
- **Dependency Loading**: Check proper file loading from canonical structure
- **Warning Suppression**: Verify suppress_compatibility_warnings() call
- **Path Management**: Validate /workspace/data/mrst/ canonical paths only

### Phase 3: Data Structure Validation
- **Data Catalog Compliance**: Check s13 continues Initial Conditions Chain
- **Expected Output**: state.mat contribution (s12→s13→s14)
- **File Structure**: Validate canonical data structure usage
- **Size Estimation**: Verify realistic data size expectations (~10MB per catalog)

### Phase 4: Technical Correctness
- **MRST Integration**: Check proper MRST saturation initialization functions
- **Grid Dependency**: Verify grid.mat loading and usage
- **Rock Dependency**: Check rock.mat loading for saturation calculations
- **Fluid Dependency**: Validate fluid.mat usage for phase distribution
- **State Dependency**: Check state.mat (from s12) loading for pressure foundation

### Phase 5: Bug Detection
- **Script Execution**: Test actual execution with current canonical structure
- **Error Handling**: Check error messages and fail-fast behavior
- **Output Validation**: Verify state.mat update and content
- **Integration**: Check compatibility with s12 (upstream) and s14 (downstream)

## DELIVERABLE REQUIREMENTS
Comprehensive audit report with:
1. Phase-by-phase analysis results
2. Policy compliance assessment (strict/warn/suggest mode analysis)
3. Bug detection findings
4. Data Catalog compliance verification
5. Overall grade (A+/A/B/C/D/F) with numerical score
6. Critical issues requiring immediate attention
7. Execution test results with actual output

## VALIDATION MODE
- **Context**: Development script requiring thorough validation
- **Mode**: warn (development phase with helpful feedback)
- **Policy Awareness**: Full 6-policy compliance checking required

## CRITICAL SUCCESS FACTORS
- Must verify Initial Conditions Chain continuity (s12→s13→s14)
- Must validate canonical data structure compliance
- Must test actual execution with current data
- Must provide policy-aware recommendations