# !/bin/bash

set -e 

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    curl -sfL https://get.k3s.io | sh -
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
    sudo kubectl create secret generic app-secret --from-env-file=/vagrant/.env
fi


