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
echo -e "${CLR_CYAN}PROVISION: Installing Helm CLI...${CLR_RESET}"
echo "--------------------------------------------------------"

# Download and execute the official Helm installer script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
rm get_helm.sh # Clean up installation script file after usage

# Set up cluster network configuration path profiles for the vagrant user profile context
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}K3s Master Plane & Helm installation completed successfully!${CLR_RESET}"