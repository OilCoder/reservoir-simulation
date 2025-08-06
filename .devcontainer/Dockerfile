# NVIDIA PyTorch Container + TensorFlow (Safe)
FROM nvcr.io/nvidia/pytorch:24.11-py3

# Test PyTorch first (ensure it's working)
RUN python -c "import torch; print(f'✅ PyTorch {torch.__version__} OK')"

# Install TensorFlow with conservative strategy
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed tensorflow[and-cuda]

# Install core scientific computing stack
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    numpy>=1.24.0 \
    scipy>=1.10.0 \
    matplotlib>=3.4.0 \
    pandas>=2.0.0 \
    scikit-learn>=1.0.0 \
    jupyter>=1.0.0 \
    pyyaml>=6.0

# Install data handling and file I/O libraries
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    h5py \
    netcdf4 \
    xarray \
    openpyxl \
    pyarrow

# Install optimization and ML libraries  
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    optuna \
    statsmodels \
    seaborn \
    numba

# Install dashboard and visualization libraries
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    streamlit>=1.28.0 \
    plotly>=5.15.0 \
    pyvista \
    vtk

# Install PVT and thermodynamics libraries for reservoir simulation
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    CoolProp \
    thermo \
    sympy \
    sparse \
    discretize

# Install petroleum engineering and well libraries
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    welly \
    lasio \
    welleng

# Install high-performance computing libraries
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    dask \
    joblib

# Install MATLAB/Octave integration
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
    oct2py

# Install Node.js (LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install uv (Python package manager for MCP servers)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Clone and setup MRST (without system Octave to avoid conflicts)
RUN git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst && \
    chmod -R 755 /opt/mrst



