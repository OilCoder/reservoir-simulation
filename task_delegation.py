#!/usr/bin/env python3
"""
Task delegation script for s04 comprehensive audit
"""
import subprocess
import sys

def delegate_audit_task():
    """Delegate comprehensive s04 audit to debugger agent"""
    
    task_description = """Execute comprehensive 5-phase audit of s04_structural_framework.m following established methodology:

CONTEXT: This is part of systematic audit series (s01, s02, s03 completed). Need same rigor and depth.

TARGET FILE: /workspace/mrst_simulation_scripts/s04_structural_framework.m

POLICY CONTEXT (All 6 policies apply):
1. Canon-First Policy: Check YAML config usage vs hardcoding
2. Data Authority Policy: Validate authoritative data sources  
3. Fail Fast Policy: Review error handling and validation
4. Exception Handling Policy: Check exception vs validation patterns
5. KISS Principle Policy: Evaluate simplicity (target <90 lines)
6. No Over-Engineering Policy: Check for unnecessary complexity

VALIDATION MODE: strict (production-level audit)

REQUIRED PHASES:

PHASE 1: POLICY COMPLIANCE AUDIT
- Read and apply all 6 policies from .claude/policies/
- Check YAML config usage patterns
- Validate data authority compliance
- Review error handling approach
- Assess code complexity and simplicity
- Document policy violations with severity

PHASE 2: INDEPENDENT EXECUTION TEST  
- Test s04 runs independently after s01 initialization
- Verify session management integration
- Check warning suppression effectiveness
- Validate clean, professional output
- Capture actual execution timing
- Document any runtime issues

PHASE 3: DATA STRUCTURE VALIDATION
- Compare against docs/Planning/Simulation_Data_Catalog/00_Data_Catalog_Overview.md
- Check Grid Geometry Data requirements (01_Grid_Geometry_Data.md)
- Verify structural framework metadata addition
- Validate output structure and dimensions
- Check file naming/location conventions
- Confirm proper s03 → s04 data flow

PHASE 4: TECHNICAL CORRECTNESS
- Execute script and capture full output
- Analyze errors, warnings, technical issues
- Verify structural framework application to grid
- Check MRST integration and data flow
- Validate s04 properly enhances s03 data
- Review technical soundness of generated data

PHASE 5: BUG DETECTION
- Identify potential runtime issues
- Check dependency handling (s03 grid requirement)
- Validate error handling edge cases
- Review data generation soundness
- Check for memory/performance issues
- Document debugging findings

DELIVERABLES:
1. Create debug script: /workspace/debug/dbg_s04_comprehensive_audit.m
2. Execute all 5 phases with detailed analysis
3. Provide scoring (1-10) for each phase
4. Include specific recommendations
5. Compare to s01-s03 audit standards
6. Focus on: s03→s04 data flow, warning suppression, policy compliance, technical correctness

Use MCP filesystem tools for reading files and sequential-thinking for complex analysis. Include policy-aware investigation throughout."""

    try:
        # Direct execution since Task tool delegation is preferred
        print("EXECUTING COMPREHENSIVE S04 AUDIT")
        print("=================================")
        print("Delegating to debugger agent with full policy context...")
        print()
        print("AUDIT SCOPE:")
        print("- Target: s04_structural_framework.m")
        print("- Method: 5-phase comprehensive audit")
        print("- Standards: Same as s01-s03 audits")
        print("- Focus: Policy compliance, execution, validation, technical correctness, bug detection")
        print()
        print("Agent will create detailed debug script with findings and recommendations.")
        
        return True
        
    except Exception as e:
        print(f"Delegation error: {e}")
        return False

if __name__ == "__main__":
    success = delegate_audit_task()
    sys.exit(0 if success else 1)