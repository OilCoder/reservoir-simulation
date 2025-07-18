# Base image with CUDA and cuDNN for GPU support
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Non-interactive APT
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies, Node.js, and npm for Claude CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git curl ca-certificates bzip2 build-essential \
      octave gfortran libhdf5-serial-dev libpng-dev libfreetype6-dev \
      sudo nodejs npm python3-venv python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Clone MRST repository and configure Octave path
RUN git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst && \
    mkdir -p /etc/octave && \
    echo 'addpath /opt/mrst' >> /etc/octave/octaverc

# Install Claude Code CLI globally via npm
# RUN npm install -g @anthropic-ai/claude-code

# Install Miniconda
ENV CONDA_DIR=/opt/conda
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
      -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda init bash && \
    $CONDA_DIR/bin/conda config --system --remove channels defaults && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge
ENV PATH="$CONDA_DIR/bin:$PATH"

# Stay as root user for devcontainer
WORKDIR /workspaces/simulation

# Copy environment spec
COPY .devcontainer/environment.yml /tmp/environment.yml

# Install mamba directly and create environment with explicit channel specification
RUN $CONDA_DIR/bin/conda install -n base -c conda-forge mamba --yes --override-channels && \
    $CONDA_DIR/bin/mamba env create -f /tmp/environment.yml && \
    $CONDA_DIR/bin/conda clean -afy

# Activate conda env by default and update PATH for root
RUN echo "conda activate simulation" >> /root/.bashrc && \
    echo "export PATH=\"$CONDA_DIR/envs/simulation/bin:$PATH\"" >> /root/.bashrc
ENV CONDA_DEFAULT_ENV=simulation
ENV PATH="$CONDA_DIR/envs/simulation/bin:$PATH"

# Default shell
CMD ["/bin/bash"]