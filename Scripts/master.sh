# !/bin/bash

set -e 

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    curl -sfL https://get.k3s.io |  sh -s - \
    --node-taint CriticalAddonsOnly=true:NoSchedule \
    --flannel-iface=eth1
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

    # search for all yaml files to extract variables from

    files=$(find /vagrant/Manifests -name "*.yml" -o -name "*.yaml")

    for file in $files; do
        # search for all variables in the yaml file and check if they are defined in the .env file
        vars=""
        while read -r var; do
            envs=$(grep "^${var}=" /vagrant/.env)
            vars+="$envs "        
        done < <(grep -oP '(?<=\$)\w+' "$file")
        export $vars 
        envsubst < $file |  kubectl apply -f -
    done
fi

sudo chmod 644 /etc/rancher/k3s/k3s.yaml
