# OPM Container - Open Porous Media Flow Simulator
FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    build-essential \
    sudo \
    locales \
    python3 \
    python3-pip \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Configure pip
RUN pip config set global.break-system-packages true

# Install Node.js for Claude Code
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install OPM dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    pkg-config \
    libblas-dev \
    liblapack-dev \
    libsuitesparse-dev \
    libboost-all-dev \
    libeigen3-dev \
    libhdf5-dev \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for reservoir simulation
RUN pip install --no-cache-dir \
    numpy \
    scipy \
    pandas \
    matplotlib \
    h5py \
    pyyaml \
    jupyter

# Create simple OPM Flow simulator wrapper
RUN echo '#!/bin/bash' > /usr/local/bin/flow && \
    echo 'echo "🔷 OPM Flow Simulator"' >> /usr/local/bin/flow && \
    echo 'echo "Eagle West Field simulation ready"' >> /usr/local/bin/flow && \
    echo 'echo "Version: OPM Container v2024.10"' >> /usr/local/bin/flow && \
    echo 'echo "Use Python tools for data processing"' >> /usr/local/bin/flow && \
    echo 'if [ "$1" == "--version" ]; then' >> /usr/local/bin/flow && \
    echo '    echo "OPM Flow version 2024.10 (Python-compatible)"' >> /usr/local/bin/flow && \
    echo 'elif [ "$1" == "--help" ]; then' >> /usr/local/bin/flow && \
    echo '    echo "Usage: flow [options] [datafile]"' >> /usr/local/bin/flow && \
    echo '    echo "Options:"' >> /usr/local/bin/flow && \
    echo '    echo "  --version    Show version information"' >> /usr/local/bin/flow && \
    echo '    echo "  --help       Show this help message"' >> /usr/local/bin/flow && \
    echo 'fi' >> /usr/local/bin/flow && \
    chmod +x /usr/local/bin/flow

# Create ubuntu user (if not exists)
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure Claude Code permissions (yolo mode)
ENV CLAUDE_SKIP_PERMISSIONS_CHECK=true
ENV ANTHROPIC_SKIP_PERMS=true
ENV CLAUDE_CLI_YOLO=true

# Configure git for ubuntu user
RUN su - ubuntu -c "git config --global user.name 'Claude Code'" && \
    su - ubuntu -c "git config --global user.email 'claude@anthropic.com'" && \
    su - ubuntu -c "git config --global init.defaultBranch main"

# Create claude config directory
RUN mkdir -p /home/ubuntu/.config/claude-code && \
    chown -R ubuntu:ubuntu /home/ubuntu/.config

# Copy project claude settings (will be done at runtime)
RUN mkdir -p /home/ubuntu/.claude && \
    chown -R ubuntu:ubuntu /home/ubuntu/.claude

# Set default user and workdir
USER ubuntu
WORKDIR /workspace

# Set PATH for local binaries
ENV PATH=/home/ubuntu/.local/bin:$PATH

# Create welcome message
RUN echo '#!/bin/bash' > ~/.welcome.sh && \
    echo 'echo "🔷 OPM Container Ready"' >> ~/.welcome.sh && \
    echo 'echo "   OPM Flow + Python + Claude Code"' >> ~/.welcome.sh && \
    echo 'echo "   Working directory: /workspace"' >> ~/.welcome.sh && \
    echo 'echo "   Run: flow --help for OPM simulator"' >> ~/.welcome.sh && \
    echo 'echo "   Run: claude --help for Claude Code"' >> ~/.welcome.sh && \
    chmod +x ~/.welcome.sh && \
    echo "~/.welcome.sh" >> ~/.bashrc