#!/bin/bash
set -euo pipefail

CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}DEPENDENCY: Checking and installing localized requirements...${CLR_RESET}"
echo "--------------------------------------------------------"

# Ensure the local bin folders exist
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.docker/cli-plugins"

# Identify active user profile shell configuration
SHELL_PROFILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

# 1. DOWNLOAD VAGRANT 
if ! command -v vagrant &> /dev/null && [ ! -f "$HOME/.local/bin/vagrant" ]; then
    echo "STATUS: Vagrant mismatch resolved. Fetching modern portable linux binary archive (2.4.9)..."
    rm -f "$HOME/.local/bin/vagrant"
    curl -LO "https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_linux_amd64.zip"
    unzip -p vagrant_2.4.9_linux_amd64.zip vagrant > "$HOME/.local/bin/vagrant"
    chmod +x "$HOME/.local/bin/vagrant"
    rm -f vagrant_2.4.9_linux_amd64.zip
    echo -e "✅ ${CLR_GREEN}Portable Vagrant 2.4.9 setup completed in user space.${CLR_RESET}"
else
    echo "STATUS: Vagrant is already present."
fi

echo "" 

# 2. DOWNLOAD KUBECTL
if ! command -v kubectl &> /dev/null && [ ! -f "$HOME/.local/bin/kubectl" ]; then
    echo "STATUS: Downloading latest stable kubectl binary..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    mv ./kubectl "$HOME/.local/bin/kubectl"
    echo -e "✅ ${CLR_GREEN}Portable kubectl setup completed in user space.${CLR_RESET}"
else
    echo "STATUS: kubectl binary is already set up."
fi

echo ""

# 5. AUTOMATIC SHELL USER-SPACE BIN PATH CONFIGURATION
if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q '.local/bin' "$SHELL_PROFILE" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
        echo -e "✅ ${CLR_GREEN}Added ~/.local/bin to your dynamic environment layout profile.${CLR_RESET}"
    fi
fi

echo "--------------------------------------------------------"
echo -e "${CLR_GREEN}✅ Local space installations completed successfully!${CLR_RESET}"