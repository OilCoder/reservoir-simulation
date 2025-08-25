# MRST Container - MATLAB Reservoir Simulation Toolbox with Octave
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Octave and required packages
RUN apt-get update && apt-get install -y \
    octave \
    octave-dev \
    octave-control \
    octave-signal \
    octave-statistics \
    octave-io \
    octave-image \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for Claude Code
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Clone and setup MRST
RUN git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst && \
    chmod -R 755 /opt/mrst

# Setup MRST startup
RUN echo "% MRST startup configuration" > /opt/mrst_startup.m && \
    echo "addpath('/opt/mrst');" >> /opt/mrst_startup.m && \
    echo "startup;" >> /opt/mrst_startup.m && \
    echo "% Pre-load core modules" >> /opt/mrst_startup.m && \
    echo "try" >> /opt/mrst_startup.m && \
    echo "    mrstModule('add', 'ad-core', 'ad-blackoil', 'ad-props');" >> /opt/mrst_startup.m && \
    echo "    mrstModule('add', 'agglom', 'coarsegrid', 'diagnostics');" >> /opt/mrst_startup.m && \
    echo "    fprintf('✅ MRST modules loaded\\n');" >> /opt/mrst_startup.m && \
    echo "catch ME" >> /opt/mrst_startup.m && \
    echo "    warning('Failed to load some MRST modules: %s', ME.message);" >> /opt/mrst_startup.m && \
    echo "end" >> /opt/mrst_startup.m

# Create ubuntu user (if not exists)
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set MRST environment variables
ENV MRST_ROOT=/opt/mrst
ENV MATLABPATH=/opt/mrst
ENV OCTAVE_PATH=/opt/mrst

# Configure Claude Code permissions (yolo mode)
ENV CLAUDE_SKIP_PERMISSIONS_CHECK=true
ENV ANTHROPIC_SKIP_PERMS=true
ENV CLAUDE_CLI_YOLO=true

# Configure git for ubuntu user
RUN su - ubuntu -c "git config --global user.name 'Claude Code'" && \
    su - ubuntu -c "git config --global user.email 'claude@anthropic.com'" && \
    su - ubuntu -c "git config --global init.defaultBranch main"

# Create Octave startup file
RUN mkdir -p /home/ubuntu && \
    echo "% Octave startup file" > /home/ubuntu/.octaverc && \
    echo "addpath('/opt/mrst');" >> /home/ubuntu/.octaverc && \
    echo "if exist('/opt/mrst/startup.m', 'file')" >> /home/ubuntu/.octaverc && \
    echo "    run('/opt/mrst/startup.m');" >> /home/ubuntu/.octaverc && \
    echo "end" >> /home/ubuntu/.octaverc && \
    chown ubuntu:ubuntu /home/ubuntu/.octaverc

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
    echo 'echo "🎯 MRST Container Ready"' >> ~/.welcome.sh && \
    echo 'echo "   Octave + MRST + Claude Code"' >> ~/.welcome.sh && \
    echo 'echo "   Working directory: /workspace"' >> ~/.welcome.sh && \
    echo 'echo "   Run: octave to start MRST"' >> ~/.welcome.sh && \
    echo 'echo "   Run: claude --help for Claude Code"' >> ~/.welcome.sh && \
    chmod +x ~/.welcome.sh && \
    echo "~/.welcome.sh" >> ~/.bashrc