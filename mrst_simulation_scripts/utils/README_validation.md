# MRST Session Validation - Standardized Implementation

## Overview

The `validate_mrst_session.m` function provides a standardized approach for ensuring MRST is properly initialized before any simulation script runs. This implements **Pattern B** identified in the MRST workflow audit - the successful fallback initialization pattern.

## Purpose

Based on the audit findings, 18 MRST scripts need standardized MRST validation. This function serves as the building block to replace inconsistent initialization patterns with a unified approach.

## Usage

### Basic Usage in MRST Scripts

```matlab
% At the beginning of any sNN script:
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'utils'));

% Validate MRST session with automatic fallback
[success, message] = validate_mrst_session(script_dir);
if ~success
    error('MRST initialization failed: %s', message);
end

% Continue with MRST-dependent code...
```

### Alternative Pattern (Path Auto-Detection)

```matlab
% Let function auto-detect script directory
[success, message] = validate_mrst_session();
```

## Implementation Pattern

The function implements the **successful Pattern B** from s02_create_grid.m:

1. **Check Critical Functions**: Verify `mrstModule`, `cartGrid`, `computeGeometry` exist
2. **Fallback Initialization**: If functions missing, execute `s01_initialize_mrst.m`
3. **Verification**: Confirm MRST is ready after initialization
4. **Clear Status**: Return boolean success indicator and descriptive message

## Function Signature

```matlab
function [success, message] = validate_mrst_session(script_dir)
```

**Parameters:**
- `script_dir` (optional): Directory containing `s01_initialize_mrst.m`
  - If not provided, auto-detects from calling function's location

**Returns:**
- `success`: Boolean indicating if MRST is ready for use
- `message`: String describing initialization status and module information

## Standardization Benefits

### Before (Inconsistent Patterns)
- Some scripts check `cartGrid`, others check `mrstModule`
- Different error handling approaches
- Inconsistent fallback strategies
- No unified logging format

### After (Standardized Pattern)
- Single validation function with consistent logic
- Unified error handling and logging
- Reliable fallback to s01_initialize_mrst.m
- Clear success/failure indicators

## Testing

Run the test script to verify functionality:

```bash
octave mrst_simulation_scripts/test_validate_mrst_session.m
```

The test validates:
1. Function can be called successfully
2. Path-agnostic behavior works
3. Critical MRST functions are available after validation

## Integration into Existing Scripts

The 18 scripts identified in the audit should be updated to use this pattern:

```matlab
% Replace existing MRST checks with:
[success, message] = validate_mrst_session(script_dir);
if ~success
    error('MRST validation failed: %s', message);
end
```

This ensures consistent behavior across all MRST workflow scripts.

## Dependencies

- `s01_initialize_mrst.m` - Must exist in script directory for fallback initialization
- MRST installation - Function will attempt to locate and initialize MRST

## Author

Claude Code AI System  
Date: January 30, 2025