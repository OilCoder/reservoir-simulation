# CUDA base image for GPU support while maintaining Ubuntu 22.04 compatibility
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Preserve original timezone argument
ARG TZ
ENV TZ="$TZ"

# Non-interactive APT to prevent hanging
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js 20 FIRST to match original setup, plus all original tools
RUN apt update && apt install -y \
  # Original Claude Code dependencies
  less git procps sudo fzf zsh man-db unzip gnupg2 gh \
  iptables ipset iproute2 dnsutils aggregate jq \
  # Additional dependencies for scientific computing
  curl ca-certificates bzip2 build-essential wget \
  octave gfortran libhdf5-serial-dev libpng-dev libfreetype6-dev \
  python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 exactly as in original
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
  && apt-get install -y nodejs

# Ensure default node user has access to /usr/local/share (preserve original)
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R 1000:1000 /usr/local/share

# Create node user with same UID/GID as original
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ARG USERNAME=node

# Persist bash history (preserve original functionality)
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable (preserve original)
ENV DEVCONTAINER=true

# Create workspace and config directories (preserve original)
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Install git-delta exactly as in original
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
  rm "git-delta_0.18.2_${ARCH}.deb"

# Install Miniconda for scientific computing (isolated installation)
ENV CONDA_DIR=/opt/conda
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
      -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda init bash && \
    $CONDA_DIR/bin/conda config --system --remove channels defaults && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge

# Clone MRST repository for reservoir simulation
RUN git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst && \
    mkdir -p /etc/octave && \
    echo 'addpath("/opt/mrst")' >> /etc/octave/octaverc

# Set up non-root user (preserve original)
USER node

# Install global packages (preserve original npm setup)
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh (preserve original)
ENV SHELL=/bin/zsh

# Install zsh with powerline10k theme (preserve original setup)
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude Code CLI (preserve original functionality)
RUN npm install -g @anthropic-ai/claude-code

# Install mamba for faster conda operations and create simulation environment
USER root

# Copy environment file and create conda environment during build
COPY environment.yml /tmp/environment.yml

# Configure conda for better reliability and create environment
RUN $CONDA_DIR/bin/conda install -n base -c conda-forge mamba --yes --override-channels && \
    $CONDA_DIR/bin/conda config --system --set remote_connect_timeout_secs 30.0 && \
    $CONDA_DIR/bin/conda config --system --set remote_read_timeout_secs 120.0 && \
    $CONDA_DIR/bin/mamba env create -f /tmp/environment.yml && \
    # Install UV package manager for MCP servers in the simulation environment
    $CONDA_DIR/bin/mamba install -n simulation -c conda-forge uv --yes && \
    $CONDA_DIR/bin/conda clean -afy && \
    rm /tmp/environment.yml

# Set up conda environment activation for node user with simulation environment as default
RUN echo "export PATH=\"$CONDA_DIR/bin:\$PATH\"" >> /home/node/.bashrc && \
    echo "export PATH=\"$CONDA_DIR/bin:\$PATH\"" >> /home/node/.zshrc && \
    # Initialize conda for bash and zsh for node user
    su - node -c "$CONDA_DIR/bin/conda init bash" && \
    su - node -c "$CONDA_DIR/bin/conda init zsh" && \
    # Add conda activation to shell configs
    echo "conda activate simulation" >> /home/node/.bashrc && \
    echo "conda activate simulation" >> /home/node/.zshrc && \
    # PERMANENT FIX for fzf errors: Remove fzf plugin from oh-my-zsh plugins list
    sed -i 's/plugins=(git fzf )/plugins=(git )/' /home/node/.zshrc && \
    # Add environment variables to disable fzf features that cause errors
    echo "export DISABLE_FZF_KEY_BINDINGS=true" >> /home/node/.zshrc && \
    echo "export DISABLE_FZF_AUTO_COMPLETION=true" >> /home/node/.zshrc && \
    # Patch oh-my-zsh fzf plugin to handle missing files gracefully (in case it gets re-enabled)
    sed -i '/source.*key-bindings\.zsh/s/source/[ -f "&" ] \&\& source/' /home/node/.oh-my-zsh/plugins/fzf/fzf.plugin.zsh 2>/dev/null || true && \
    sed -i '/source.*completion\.zsh/s/source/[ -f "&" ] \&\& source/' /home/node/.oh-my-zsh/plugins/fzf/fzf.plugin.zsh 2>/dev/null || true && \
    chown node:node /home/node/.bashrc /home/node/.zshrc

# Copy and set up firewall script (preserve original security)
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

# Switch back to node user
USER node

# Set conda path for scientific computing
ENV PATH="$CONDA_DIR/bin:$PATH"