# Reservoir Simulation Environment Setup

This devcontainer provides a complete environment for reservoir simulation using Octave/MRST and deep learning with TensorFlow/PyTorch, while preserving Claude Code functionality.

## Features

### Core Environment
- **CUDA 12.4.1** with cuDNN for GPU acceleration
- **Node.js 20** with Claude Code CLI
- **Ubuntu 22.04** base with all original Claude Code tools
- **Miniconda** with isolated scientific Python environment

### Scientific Computing Stack
- **Octave** with MRST repository for reservoir simulation
- **TensorFlow** and **PyTorch** for deep learning (GPU-enabled)
- **Scientific Python** stack (NumPy, SciPy, Pandas, Matplotlib)
- **Optimization tools** (Optuna, Hyperopt)
- **Jupyter Lab** for interactive development

### Development Tools
- **VS Code** with extensions for Python, Jupyter, Octave
- **Git** with delta for enhanced diffs
- **Zsh** with powerline10k theme
- **Firewall** configuration for security

## Quick Start

1. **Rebuild container**: VS Code will prompt to rebuild when opening
2. **Environment auto-activated**: The `simulation` conda environment is activated by default
3. **Verify installation**: Check the postCreateCommand output for "✅ Environment ready" message
4. **Test setup** (optional): `python /workspace/.devcontainer/test-integration.py`
5. **Start Jupyter**: `jupyter lab --ip=0.0.0.0 --port=8888 --no-browser`

## Installation Process

The environment is fully installed during container build time:
- **Dockerfile handles**: All conda packages, MRST setup, and dependencies
- **PostCreateCommand**: Only firewall setup and environment verification
- **No manual steps required**: Everything is ready when container starts

## Usage Examples

### Reservoir Simulation with MRST
```bash
# Start Octave
octave

# In Octave:
startup  # Initialize MRST
G = cartGrid([10, 10, 5])  # Create simple grid
```

### Deep Learning
```python
# Environment is already activated by default

# Test GPU
import torch
print(torch.cuda.is_available())

# Simple TensorFlow test
import tensorflow as tf
print(tf.config.list_physical_devices('GPU'))
```

### Python-Octave Integration
```python
from oct2py import octave

# Run Octave commands from Python
result = octave.eval('magic(3)')
print(result)
```

## Path Configuration

- **MRST**: `/opt/mrst` (automatically added to Octave path)
- **Conda**: `/opt/conda` 
- **Scientific environment**: `/opt/conda/envs/simulation`
- **Claude Config**: `/home/node/.claude` (preserved)

## Troubleshooting

### GPU not detected
- Ensure Docker has GPU support: `docker run --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`
- Check NVIDIA drivers on host system

### Conda environment issues
- Recreate environment: `mamba env create -f /workspace/.devcontainer/environment.yml --force`
- Check environment: `conda info --envs`

### MRST not working
- Verify path: `octave -q --eval "path"`
- Reinstall: `git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst`

## Security

All original Claude Code security features are preserved:
- Firewall rules limiting outbound connections
- Sudoers configuration for firewall script
- Volume mounts for persistent configuration

## Integration Test

Run the integration test to verify all components:
```bash
python /workspace/.devcontainer/test-integration.py
```

This will test:
- Package imports (scientific stack)
- GPU availability (PyTorch/TensorFlow)
- Octave integration with oct2py