#!/usr/bin/env bash
set -euo pipefail

CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}PROVISION: Installing K3s Master Plane...${CLR_RESET}"
echo "--------------------------------------------------------"

IFACE=$(ip -o -4 addr show | grep "192.168.56.10" | awk '{print $2}')
export K3S_KUBECONFIG_MODE="644"

curl -sfL https://get.k3s.io | sh -s - \
  --flannel-iface="$IFACE" \
  --node-ip="192.168.56.10" \
  --write-kubeconfig-mode="644" \
  --node-taint "node-role.kubernetes.io/control-plane:NoSchedule"

echo "STATUS: Saving Cluster Token for Agent access..."

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}K3s Master Plane installation completed successfully!${CLR_RESET}"