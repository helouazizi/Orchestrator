#!/usr/bin/env bash

set -euo pipefail

echo "🔑 Extracting K3s configuration profile from master-node..."
# Pull the internal K3s config out to your host project folder
vagrant ssh master-node -c "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-local.yaml

echo "🛠️ Configuring profile network routing for Host laptop..."
# Replace 127.0.0.1 with the private IP address of your master node
# Works cross-platform on both Linux and macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/127.0.0.1/192.168.56.10/g' k3s-local.yaml
else
  sed -i 's/127.0.0.1/192.168.56.10/g' k3s-local.yaml
fi

# Secure file permissions for Kubeconfig files
chmod 600 k3s-local.yaml

# export KUBECONFIG=\$(pwd)/k3s-local.yaml

echo "✅ Connection profile saved to k3s-local.yaml"