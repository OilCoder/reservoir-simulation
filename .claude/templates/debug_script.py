"""
Debug script for investigating [specific issue/behavior].

Target module: src/[module_name].py
Function: [function_name]
Date: [YYYY-MM-DD]
Author: [Name]

Issue Description:
- What behavior are we investigating?
- What error or unexpected result occurs?
- Under what conditions?

Hypothesis:
- What might be causing the issue?
"""

# ----------------------------------------
# Step 1 – Setup Debug Environment
# ----------------------------------------

# Substep 1.1 – Configure paths and imports ______________________
import sys
import os
sys.path.insert(0, os.path.abspath('..'))

# Debug utilities
import logging
import traceback
from datetime import datetime
import json

# Visualization
import matplotlib.pyplot as plt
import numpy as np

# Target module imports
try:
    from src.module_name import suspicious_function, helper_function
    print("✅ Successfully imported target functions")
except ImportError as e:
    print(f"❌ Import failed: {e}")
    traceback.print_exc()

# ----------------------------------------
# Step 2 – Configure Debug Logging
# ----------------------------------------

# Create debug logger
debug_logger = logging.getLogger('debug')
debug_logger.setLevel(logging.DEBUG)

# File handler for debug log
fh = logging.FileHandler(f'debug/debug_log_{datetime.now():%Y%m%d_%H%M%S}.log')
fh.setLevel(logging.DEBUG)

# Console handler
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)

# Formatter
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
ch.setFormatter(formatter)

debug_logger.addHandler(fh)
debug_logger.addHandler(ch)

# ----------------------------------------
# Step 3 – Load Test Data
# ----------------------------------------

print("\n" + "="*50)
print("STARTING DEBUG INVESTIGATION")
print("="*50)

# Load problematic data
try:
    # Option 1: Load from file
    test_data = np.load('debug/problem_data.npy')
    print(f"✅ Loaded test data: shape={test_data.shape}, dtype={test_data.dtype}")
except:
    # Option 2: Generate synthetic test case
    print("⚠️  No saved data found, generating synthetic test case")
    test_data = np.random.randn(100, 50)

# Examine data characteristics
print(f"\nData statistics:")
print(f"  Min: {np.min(test_data):.4f}")
print(f"  Max: {np.max(test_data):.4f}")
print(f"  Mean: {np.mean(test_data):.4f}")
print(f"  Std: {np.std(test_data):.4f}")
print(f"  NaN count: {np.sum(np.isnan(test_data))}")

# ----------------------------------------
# Step 4 – Reproduce Issue
# ----------------------------------------

print("\n" + "-"*50)
print("REPRODUCING ISSUE")
print("-"*50)

# Test Case 1: Normal operation
print("\nTest 1: Normal operation")
try:
    result1 = suspicious_function(test_data[:10])
    print(f"✅ Normal case passed: result shape = {result1.shape}")
    debug_logger.info(f"Normal case result: {result1}")
except Exception as e:
    print(f"❌ Normal case failed: {e}")
    debug_logger.error(f"Normal case error: {e}", exc_info=True)

# Test Case 2: Edge case that triggers issue
print("\nTest 2: Edge case")
try:
    # Modify data to trigger issue
    edge_case_data = test_data.copy()
    edge_case_data[0, 0] = np.inf  # Example modification
    
    result2 = suspicious_function(edge_case_data)
    print(f"✅ Edge case passed: result = {result2}")
except Exception as e:
    print(f"❌ Edge case failed (EXPECTED): {e}")
    debug_logger.error(f"Edge case error: {e}", exc_info=True)
    
    # Detailed traceback
    print("\nDetailed traceback:")
    traceback.print_exc()

# ----------------------------------------
# Step 5 – Deep Dive Analysis
# ----------------------------------------

print("\n" + "-"*50)
print("DEEP DIVE ANALYSIS")
print("-"*50)

# Instrument the function with debugging
def debug_wrapper(func):
    """Wrapper to add debugging to function calls."""
    def wrapper(*args, **kwargs):
        print(f"\n🔍 Calling {func.__name__}")
        print(f"   Args shapes: {[getattr(a, 'shape', type(a)) for a in args]}")
        print(f"   Kwargs: {kwargs}")
        
        try:
            result = func(*args, **kwargs)
            print(f"   ✅ Success! Result shape: {getattr(result, 'shape', type(result))}")
            return result
        except Exception as e:
            print(f"   ❌ Failed with: {e}")
            raise
    return wrapper

# Apply debugging wrapper
suspicious_function_debug = debug_wrapper(suspicious_function)

# Run with debugging
print("\nRunning with debug wrapper:")
try:
    debug_result = suspicious_function_debug(test_data[:5])
except Exception as e:
    print(f"Debug run failed: {e}")

# ----------------------------------------
# Step 6 – Visualization
# ----------------------------------------

print("\n" + "-"*50)
print("VISUALIZATION")
print("-"*50)

# Create debug plots
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Debug Analysis Visualization')

# Plot 1: Input data distribution
ax1 = axes[0, 0]
ax1.hist(test_data.flatten(), bins=50, alpha=0.7)
ax1.set_title('Input Data Distribution')
ax1.set_xlabel('Value')
ax1.set_ylabel('Frequency')

# Plot 2: Data heatmap
ax2 = axes[0, 1]
im = ax2.imshow(test_data[:20, :20], cmap='viridis', aspect='auto')
ax2.set_title('Data Sample Heatmap')
plt.colorbar(im, ax=ax2)

# Plot 3: Error locations (if applicable)
ax3 = axes[1, 0]
# Identify problematic values
problems = np.where(np.isnan(test_data) | np.isinf(test_data))
if len(problems[0]) > 0:
    ax3.scatter(problems[1], problems[0], c='red', s=50)
    ax3.set_title(f'Problem Locations ({len(problems[0])} found)')
else:
    ax3.text(0.5, 0.5, 'No NaN/Inf values found', 
             ha='center', va='center', transform=ax3.transAxes)
    ax3.set_title('Problem Locations')

# Plot 4: Custom analysis
ax4 = axes[1, 1]
# Add custom visualization here
ax4.set_title('Custom Analysis')

plt.tight_layout()
plt.savefig('debug/analysis_visualization.png', dpi=150)
print("✅ Saved visualization to debug/analysis_visualization.png")

# ----------------------------------------
# Step 7 – Findings and Conclusions
# ----------------------------------------

print("\n" + "="*50)
print("FINDINGS AND CONCLUSIONS")
print("="*50)

findings = {
    "timestamp": datetime.now().isoformat(),
    "issue": "Description of the issue",
    "root_cause": "Identified root cause",
    "conditions": [
        "Condition 1 that triggers issue",
        "Condition 2 that triggers issue"
    ],
    "proposed_fix": "Suggested solution",
    "test_results": {
        "normal_case": "passed/failed",
        "edge_case": "passed/failed"
    }
}

print("\n📋 Summary:")
print(f"1. Issue occurs when: {findings['conditions']}")
print(f"2. Root cause: {findings['root_cause']}")
print(f"3. Proposed fix: {findings['proposed_fix']}")

# Save findings
with open('debug/findings.json', 'w') as f:
    json.dump(findings, f, indent=2)
print("\n✅ Findings saved to debug/findings.json")

# ----------------------------------------
# Step 8 – Cleanup
# ----------------------------------------

print("\n" + "-"*50)
print("Debug session completed")
print(f"Log file: debug/debug_log_*.log")
print(f"Plots: debug/analysis_visualization.png")
print(f"Findings: debug/findings.json")
print("-"*50)