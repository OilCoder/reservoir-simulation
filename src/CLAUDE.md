# Python Source Code Guidelines

This directory contains Python implementation for the geomechanical ML project.

## File Naming
All files must follow: `sNN[x]_<verb>_<noun>.py`
- Examples: `s01_load_data.py`, `s02_train_model.py`, `s03a_validate_results.py`

## Module Structure Template
```python
"""
Brief module purpose (1-3 lines).

Key components:
- Component description
"""

# ----------------------------------------
# Step 1 – Import and Setup
# ----------------------------------------

# Substep 1.1 – Standard library imports ______________________
import os
import sys
from typing import Dict, List, Optional

# Substep 1.2 – External imports ______________________
import numpy as np
import pandas as pd

# Substep 1.3 – Internal imports ______________________
from src.utils import helper_function

# ----------------------------------------
# Step 2 – Core Implementation
# ----------------------------------------

def main_function(param: type) -> return_type:
    """One-line summary.
    
    Args:
        param: Parameter description.
        
    Returns:
        Description of return value.
        
    Raises:
        IOError: Only for actual I/O operations.
    """
    # ✅ Validate inputs
    if not param:
        raise ValueError("Parameter cannot be None")
    
    # 🔄 Process data
    result = process_data(param)
    
    # 📊 Return results
    return result
```

## Key Rules
1. Functions must be <40 lines
2. Use descriptive snake_case names
3. Google Style docstrings required
4. English-only comments
5. No broad try/except blocks
6. Clean up all print() before commit