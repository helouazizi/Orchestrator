Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # ==========================================
  # 1. THE MASTER NODE
  # ==========================================
  config.vm.define "master-node" do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end

    master.vm.provision "shell" do |sh|
      sh.path = "scripts/k3s_master_setup.sh"
    end
  end

  # ==========================================
  # 2. THE AGENT NODE
  # ==========================================
  config.vm.define "agent1-node" do |agent|
    agent.vm.hostname = "agent1-node"
    agent.vm.network "private_network", ip: "192.168.56.11" # Distinct IP!
    
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = "1024" # Agents can be lighter
      vb.cpus = 1
    end

    agent.vm.provision "shell" do |sh|
      sh.path = "scripts/k3s_agent_setup.sh"
    end
  end
end