

Vagrant.configure("2") do |config|
    
    config.vm.box  =  "ubuntu/jammy64"

    # MASTER NODE
    config.vm.define "k3s-master" do |master|
        master.vm.hostname = "k3s-master"
        master.vm.network "private_network" , ip: "192.168.56.10"

        # THE PROVIDER SECTION 
        master.vm.provider "virtualbox" do |vb|
            vb.memory = "2048"  # aroung 2GB for k3s 
            vb.cpus = 2
        end

        # THE PROViSION SECTION THAT RESPONSIBLE FOR SCRIPTING AND INSTALATION TOOLS LIKE ANSIBLE OR CHEF 
        master.vm.provision "shell" do |sh|
            sh.path = "scripts/k3s_setup.sh"
        end
    end
end