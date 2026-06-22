# !/bin/bash
set -e 

TOKEN=$(cat /vagrant/node-token)

curl -sfL https://get.k3s.io | K3S_URL="https://${VmMaster_IP}:6443" K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="--node-ip=${VmWorker_IP} --flannel-iface=eth1" sh -


