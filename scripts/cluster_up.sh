#!/usr/bin/env bash
set -euo pipefail

echo "🔌 Booting up Vagrant multi-node cluster VMs (FUSE Bypassed)..."
# Force the portable AppImage to run without needing root FUSE modules
export APPIMAGE_EXTRACT_AND_RUN=1

vagrant up

echo "✅ Vagrant cluster is up and running!"