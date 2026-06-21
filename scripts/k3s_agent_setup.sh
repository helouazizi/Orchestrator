#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing K3s Agent Node..."

IFACE=$(ip -o -4 addr show | grep "192.168.56.11" | awk '{print $2}')

# Loop and wait until the master script successfully drops the token file
while [ ! -f /vagrant/node-token ]; do
  echo "Waiting for master node-token file to appear..."
  sleep 3
done

TOKEN=$(cat /vagrant/node-token)

# Notice we use K3S_URL (pointing to master) and K3S_TOKEN. 
# This tells the installer to run as an AGENT, not a master server.
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN="$TOKEN" sh -s - \
  --flannel-iface="$IFACE" \
  --node-ip="192.168.56.11"