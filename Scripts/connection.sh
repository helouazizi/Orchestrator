#!/bin/bash

set -e

GREEN="\033[32m"
RED="\033[31m"
ORANGE="\033[38;5;208m"
BLUE="\033[34m"
NC="\033[0m"

KUBECONFIG_SOURCE="../kubeconfig.yaml"
KUBECONFIG_DEST="${HOME}/.kube/config"

# Vérifier que le kubeconfig existe
if [ ! -f "$KUBECONFIG_SOURCE" ]; then
    echo -e "${RED}Error: $KUBECONFIG_SOURCE not found.${NC}"
    exit 1
fi

# Installer kubectl si nécessaire
if [ ! -f "$HOME/.local/bin/kubectl" ]; then
    echo -e "${ORANGE}Installing kubectl...${NC}"

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    mkdir -p "$HOME/.local/bin"
    mv kubectl "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/kubectl"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo -e "${GREEN}kubectl installed successfully.${NC}"
else
    echo -e "${BLUE}kubectl is already installed.${NC}"
fi

# Copier le kubeconfig si nécessaire
if [ ! -f "$KUBECONFIG_SOURCE" ]; then
    echo -e "${RED}No kubeconfig on parent folder${NC}"
    exit 1
fi
    echo -e "${ORANGE}Copying kubeconfig...${NC}"
    mkdir -p "${HOME}/.kube"
    cp "$KUBECONFIG_SOURCE" "$KUBECONFIG_DEST"
    chmod 600 "$KUBECONFIG_DEST"

    echo -e "${GREEN}kubeconfig copied to ${KUBECONFIG_DEST}.${NC}"
echo -e "${GREEN}Setup completed successfully.${NC}"