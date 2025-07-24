#!/bin/bash
# Startup script to fix environment issues

# Fix fzf configuration
if [ -f ~/.zshrc ]; then
    # Remove problematic fzf lines
    sed -i '/source.*fzf.*key-bindings\.zsh/d' ~/.zshrc
    sed -i '/source.*fzf.*completion\.zsh/d' ~/.zshrc
    
    # Add correct fzf configuration if files exist
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
        echo '[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh' >> ~/.zshrc
    fi
    
    if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
        echo '[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh' >> ~/.zshrc
    fi
fi

# Initialize conda if not already done
if ! grep -q "conda initialize" ~/.zshrc; then
    /opt/conda/bin/conda init zsh
fi

if ! grep -q "conda initialize" ~/.bashrc; then
    /opt/conda/bin/conda init bash
fi

# Add conda activation if not present
if ! grep -q "conda activate simulation" ~/.zshrc; then
    echo "conda activate simulation" >> ~/.zshrc
fi

if ! grep -q "conda activate simulation" ~/.bashrc; then
    echo "conda activate simulation" >> ~/.bashrc
fi

echo "Environment setup completed. Please restart your shell or run:"
echo "  source ~/.zshrc"
echo "or"
echo "  source ~/.bashrc"