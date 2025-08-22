# TensorFlow Container - Deep Learning with GPU Support
FROM tensorflow/tensorflow:latest-gpu

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install additional dependencies
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

# Install Node.js for Claude Code
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install additional Python packages for scientific computing
RUN pip install --no-cache-dir \
    pandas \
    scikit-learn \
    seaborn \
    plotly \
    jupyterlab \
    ipywidgets \
    tensorboard

# Create ubuntu user (if not exists)
RUN if ! id -u ubuntu >/dev/null 2>&1; then useradd -m -s /bin/bash ubuntu; fi
RUN usermod -aG sudo ubuntu
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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

# Configure Jupyter
RUN mkdir -p ~/.jupyter && \
    echo "c.ServerApp.ip = '0.0.0.0'" > ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.token = ''" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> ~/.jupyter/jupyter_lab_config.py

# Set default user and workdir
USER ubuntu
WORKDIR /workspace

# Set PATH for local binaries
ENV PATH=/home/ubuntu/.local/bin:$PATH

# Create Jupyter config for ubuntu user
RUN mkdir -p ~/.jupyter && \
    echo "c.ServerApp.ip = '0.0.0.0'" > ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.token = ''" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> ~/.jupyter/jupyter_lab_config.py

# Create test script
RUN echo '#!/usr/bin/env python' > ~/test_tensorflow.py && \
    echo 'import tensorflow as tf' >> ~/test_tensorflow.py && \
    echo 'print(f"TensorFlow version: {tf.__version__}")' >> ~/test_tensorflow.py && \
    echo 'print(f"GPU available: {tf.config.list_physical_devices('GPU')}")' >> ~/test_tensorflow.py && \
    echo 'print(f"CUDA support: {tf.test.is_built_with_cuda()}")' >> ~/test_tensorflow.py && \
    chmod +x ~/test_tensorflow.py

# Create welcome message
RUN echo '#!/bin/bash' > ~/.welcome.sh && \
    echo 'echo "🤖 TensorFlow Container Ready"' >> ~/.welcome.sh && \
    echo 'echo "   TensorFlow GPU + Claude Code"' >> ~/.welcome.sh && \
    echo 'echo "   Working directory: /workspace"' >> ~/.welcome.sh && \
    echo 'echo "   Run: python ~/test_tensorflow.py to test GPU"' >> ~/.welcome.sh && \
    echo 'echo "   Run: jupyter lab to start JupyterLab"' >> ~/.welcome.sh && \
    echo 'echo "   Run: claude --help for Claude Code"' >> ~/.welcome.sh && \
    chmod +x ~/.welcome.sh && \
    echo "~/.welcome.sh" >> ~/.bashrc

# Default command
CMD ["bash"]