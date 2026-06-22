#!/usr/bin/env bash
set -euo pipefail

# Text formatting modifiers for clean output readability
CLR_CYAN="\033[36m"
CLR_GREEN="\033[32m"
CLR_RESET="\033[0m"

echo -e "${CLR_CYAN}INFRASTRUCTURE: Booting up Vagrant multi-node cluster VMs (FUSE Bypassed)...${CLR_RESET}"
echo "--------------------------------------------------------"

# Force the portable AppImage to run without needing root FUSE modules
export APPIMAGE_EXTRACT_AND_RUN=1

vagrant up

echo "--------------------------------------------------------"
echo -e "✅ ${CLR_GREEN}Vagrant cluster is up and running!${CLR_RESET}"