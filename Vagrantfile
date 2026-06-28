def load_env(path)
  File.readlines(path).each do |line|
    next if line.strip.empty?
    next if line.strip.start_with?("#")

    key, value = line.strip.split("=", 2)
    ENV[key] = value if key && value
  end
end

load_env(".env")

Vagrant.configure("2") do |config|
  
  config.vm.box = "bento/ubuntu-22.04"


  config.vm.define "master" do |master|
    master.vm.hostname = "Master"
    master.vm.network "private_network", ip: ENV['VmMaster_IP']
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "k3s-master"
    end

    master.vm.provision "shell" do |sh|
      sh.path = "Scripts/master.sh"
    end
  end


  config.vm.define "worker" do |worker|
    worker.vm.hostname = "Agent"
    worker.vm.network "private_network", ip: ENV['VmWorker_IP']
    
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "1536" 
      vb.cpus = 1
      vb.name = "k3s-worker"
    end

    worker.vm.provision "shell" do |sh|
      sh.path = "Scripts/worker.sh"
      sh.env = { "VmMaster_IP" => ENV['VmMaster_IP'], "VmWorker_IP" => ENV['VmWorker_IP'] }

    end
  end

end