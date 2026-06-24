# !/bin/bash

set -e 

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
    curl -sfL https://get.k3s.io | sh -
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

    # search for all yaml files to extract variables from

    files=$(find /vagrant/Manifests -name "*.yml" -o -name "*.yaml")

    for file in $files; do
        # search for all variables in the yaml file and check if they are defined in the .env file
        while read -r var; do
            envs=$(grep "^${var}=" /vagrant/.env)
            export $envs | xargs && envsubst < $file | sudo kubectl apply -f -
            break
        done < <(grep -oP '(?<=\$)\w+' "$file")
    done



    sudo kubectl apply -f /vagrant/Manifests/rabbitmq_pod.yml
fi


