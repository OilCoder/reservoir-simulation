# Ubuntu base with CUDA support
FROM ubuntu:24.04

# Install base dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    curl \
    git \
    wget \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Configure pip to allow system-wide installations
RUN pip config set global.break-system-packages true

# Install CUDA toolkit (12.6 to match NVIDIA container)
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* cuda-keyring_1.1-1_all.deb

# Set CUDA environment variables
ENV PATH=/usr/local/cuda-12.6/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64

# Install PyTorch with CUDA support
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

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

# Install oct2py (Python-Octave bridge)
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

# Clone and setup MRST
RUN git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst && \
    chmod -R 755 /opt/mrst

# Install Octave AFTER everything else is configured (minimal install without MPI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    octave \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Test that PyTorch still works after Octave installation
RUN python -c "import torch; print(f'✅ PyTorch {torch.__version__} - GPU: {torch.cuda.is_available()}')"



