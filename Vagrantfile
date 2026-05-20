Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  # Master Node
  config.vm.define "master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    master.vm.provision "shell", inline: <<-SHELL
      curl -sfL https://get.k3s.io | sh -s - --node-ip 192.168.56.10 --write-kubeconfig-mode 644
      sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
      sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/k3s.yaml
    SHELL
  end

  # Agent Node
  config.vm.define "agent" do |agent|
    agent.vm.hostname = "k3s-agent"
    agent.vm.network "private_network", ip: "192.168.56.11"
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    agent.vm.provision "shell", inline: <<-SHELL
      while [ ! -f /vagrant/k3s.yaml ]; do sleep 2; done
      K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token 2>/dev/null || ssh -o StrictHostKeyChecking=no 192.168.56.10 sudo cat /var/lib/rancher/k3s/server/node-token)
      curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$K3S_TOKEN sh -s - --node-ip 192.168.56.11
    SHELL
  end
end