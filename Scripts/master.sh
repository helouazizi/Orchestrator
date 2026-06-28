#!/bin/bash
sed -i 's/\r$//' /vagrant/.env
set -ae 
. /vagrant/.env
set +a

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    curl -sfL https://get.k3s.io |  sh -s - \
    --node-taint CriticalAddonsOnly=true:NoSchedule \
    --flannel-iface=eth1
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
    sudo sed "s/127.0.0.1/${VmMaster_IP}/g" /etc/rancher/k3s/k3s.yaml > /vagrant/kubeconfig.yaml
    
fi
    # search for all yaml files to extract variables from
    files=$(find /vagrant/Manifests -name "*.yml" -o -name "*.yaml")

    for file in $files; do
        # search for all variables in the yaml file and check if they are defined in the .env file
        echo -e "\033[38;5;208mChecking variables in $file\033[0m"
        while read -r var; do
            if [ -z "${!var+x}" ]; then
                echo "Variable $var not defined in .env"
                exit 1
            fi
        done < <(grep -oP '(?<=\$)\w+' "$file" | sort -u)
        echo -e "\033[32mApplying $file\033[0m"
        envsubst < "$file" |  kubectl apply -f -
    done

    sudo chmod 644 /etc/rancher/k3s/k3s.yaml

