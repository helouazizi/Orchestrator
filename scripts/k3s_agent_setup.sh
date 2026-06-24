#!/usr/bin/env bash
set -euo pipefail

CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}PROVISION: Installing K3s Agent Node...${CLR_RESET}"
echo "--------------------------------------------------------"

IFACE=$(ip -o -4 addr show | grep "192.168.56.11" | awk '{print $2}')

while [ ! -f /vagrant/node-token ]; do
  echo "STATUS: Waiting for master node-token file to appear..."
  sleep 3
done

TOKEN=$(cat /vagrant/node-token)

# Run the installer as an agent pointing to the master server
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN="$TOKEN" sh -s - \
  --flannel-iface="$IFACE" \
  --node-ip="192.168.56.11"

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}K3s Agent Node installation completed successfully!${CLR_RESET}"