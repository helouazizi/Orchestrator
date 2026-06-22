#!/usr/bin/env bash
set -euo pipefail

# Text formatting modifiers for clean output readability
CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}PROVISION: Installing K3s Master Plane...${CLR_RESET}"
echo "--------------------------------------------------------"

IFACE=$(ip -o -4 addr show | grep "192.168.56.10" | awk '{print $2}')
export K3S_KUBECONFIG_MODE="644"

# We pass --node-ip to bind the master to the private network
curl -sfL https://get.k3s.io | sh -s - \
  --flannel-iface="$IFACE" \
  --node-ip="192.168.56.10" \
  --write-kubeconfig-mode="644"

echo "STATUS: Saving Cluster Token for Agent access..."
# /vagrant/ is the shared folder mapped directly to your host machine's directory
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}K3s Master Plane installation completed successfully!${CLR_RESET}"