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

# 3. DOCKER ROOTLESS INSTALLATION
if ! command -v docker &> /dev/null && [ ! -f "$HOME/bin/docker" ] && [ ! -f "$HOME/.local/bin/docker" ]; then
    echo "STATUS: Installing Docker (rootless)..."
    curl -fsSL https://get.docker.com/rootless | sh
    echo "STATUS: Running dockerd-rootless-setuptool.sh with --skip-iptables..."
    
    # Run rootless tool. Fallback to local path if installer links it to ~/bin
    if [ -f "$HOME/bin/dockerd-rootless-setuptool.sh" ]; then
        "$HOME/bin/dockerd-rootless-setuptool.sh" install --skip-iptables || echo "⚠️ Skipping setup tool errors."
    elif [ -f "$HOME/.local/bin/dockerd-rootless-setuptool.sh" ]; then
        "$HOME/.local/bin/dockerd-rootless-setuptool.sh" install --skip-iptables || echo "⚠️ Skipping setup tool errors."
    fi

    # Set up environment variables temporarily for the rest of this installer execution
    export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"

    # Inject Docker configurations smoothly into the detected user shell profile file
    if [ -n "$SHELL_PROFILE" ]; then
        if ! grep -q "DOCKER_HOST" "$SHELL_PROFILE" 2>/dev/null; then
            echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
            echo 'export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"' >> "$SHELL_PROFILE"
        fi
    fi

    # Start the rootless Docker daemon in background safely
    echo "STATUS: Starting Docker daemon (rootless) in background..."
    if command -v dockerd-rootless.sh &> /dev/null; then
        nohup dockerd-rootless.sh > "$HOME/docker-rootless.log" 2>&1 &
        echo -e "✅ ${CLR_GREEN}Docker daemon started in background (log: ~/docker-rootless.log)${CLR_RESET}"
    fi
else
    echo "STATUS: Docker engine binary is already set up."
fi

echo ""

# 4. DOWNLOAD DOCKER COMPOSE V2
if ! docker compose version &> /dev/null && [ ! -f "$HOME/.docker/cli-plugins/docker-compose" ]; then
    echo "STATUS: Installing Docker Compose v2..."
    curl -SL "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64" \
        -o "$HOME/.docker/cli-plugins/docker-compose"
    chmod +x "$HOME/.docker/cli-plugins/docker-compose"

    export PATH="$HOME/.docker/cli-plugins:$PATH"
    if [ -n "$SHELL_PROFILE" ]; then
        if ! grep -q "cli-plugins" "$SHELL_PROFILE" 2>/dev/null; then
            echo 'export PATH="$HOME/.docker/cli-plugins:$PATH"' >> "$SHELL_PROFILE"
        fi
    fi
    echo -e "✅ ${CLR_GREEN}Docker Compose plugin setup completed.${CLR_RESET}"
else
    echo "STATUS: Docker Compose plugin is already set up."
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