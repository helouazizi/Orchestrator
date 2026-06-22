#!/bin/bash
set -euo pipefail

echo "📥 Checking and installing localized requirements (No Sudo Required)..."

# Ensure the local bin folder exists
mkdir -p "$HOME/.local/bin"

# 1. DOWNLOAD VAGRANT (Portable Binary Approach upgraded to 2.4.9)
if ! command -v vagrant &> /dev/null && [ ! -f "$HOME/.local/bin/vagrant" ]; then
    echo "📦 Vagrant mismatch resolved. Fetching modern portable linux binary archive (2.4.9)..."
    
    # We force delete the old 2.4.1 binary if it exists in local space to allow replacement
    rm -f "$HOME/.local/bin/vagrant"

    # Download version 2.4.9
    curl -LO "https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_linux_amd64.zip"
    
    # Extract the executable
    unzip -p vagrant_2.4.9_linux_amd64.zip vagrant > "$HOME/.local/bin/vagrant"
    chmod +x "$HOME/.local/bin/vagrant"
    
    rm vagrant_2.4.9_linux_amd64.zip
    echo "✅ Portable Vagrant 2.4.9 setup completed in user space."
else
    echo "ℹ️ Vagrant is already present."
fi

# 2. DOWNLOAD KUBECTL
if ! command -v kubectl &> /dev/null && [ ! -f "$HOME/.local/bin/kubectl" ]; then
    echo "📥 Downloading latest stable kubectl binary..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    chmod +x ./kubectl
    mv ./kubectl "$HOME/.local/bin/kubectl"
    echo "✅ Portable kubectl setup completed in user space."
else
    echo "ℹ️ kubectl binary is already set up."
fi

# 3. AUTOMATIC SHELL PATH CONFIGURATION
SHELL_PROFILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q '.local/bin' "$SHELL_PROFILE" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
        echo "✅ Added ~/.local/bin to your $SHELL_PROFILE configuration profile."
    fi
fi

echo "🚀 Local space installations completed successfully!"

