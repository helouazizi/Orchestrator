#!/usr/bin/env bash
set -euo pipefail

echo "===================================================="
echo "🚀 Starting K3s Clean Installation on Master Node..."
echo "===================================================="

# 1. Dynamically find the interface name that has our static IP (192.168.56.10)
# This prevents hardcoding 'eth1' or 'enp0s8'
IFACE=$(ip -o -4 addr show | grep "192.168.56.10" | awk '{print $2}')

if [ -z "$IFACE" ]; then
    echo "❌ Error: Could not find network interface with IP 192.168.56.10"
    exit 1
fi

echo "🎯 Found target network interface: $IFACE"

# 2. Configure permissions for the vagrant user
export K3S_KUBECONFIG_MODE="644"

# 3. Install K3s with the correct dynamic interface
curl -sfL https://get.k3s.io | sh -s - \
  --flannel-iface="$IFACE" \
  --node-ip="192.168.56.10" \
  --write-kubeconfig-mode="644"

echo "===================================================="
echo "✅ K3s Installation Completed Successfully!"
echo "===================================================="