vagrant ssh master-node -c "cat /etc/rancher/k3s/k3s.yaml" > k3s-local.yaml


export KUBECONFIG=$(pwd)/k3s-local.yaml