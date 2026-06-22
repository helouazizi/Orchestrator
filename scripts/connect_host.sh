#!/usr/bin/env bash
set -euo pipefail

# Text formatting modifiers for clean output readability
CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}NETWORK: Extracting K3s configuration profile from master-node...${CLR_RESET}"
export APPIMAGE_EXTRACT_AND_RUN=1

# Pull the internal K3s config out to your host project folder
vagrant ssh master-node -c "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-local.yaml

echo "STATUS: Configuring profile network routing for Host machine..."
# Replace 127.0.0.1 with the private IP address of your master node
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/127.0.0.1/192.168.56.10/g' k3s-local.yaml
else
  sed -i 's/127.0.0.1/192.168.56.10/g' k3s-local.yaml
fi

# Secure file permissions for Kubeconfig files
chmod 600 k3s-local.yaml

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}Connection profile saved to k3s-local.yaml${CLR_RESET}"