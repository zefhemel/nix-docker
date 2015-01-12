Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]

    # We'll attach an extra 50GB disk for all nix and docker data
    file_to_disk = "disk.vmdk"
    vb.customize ['createhd', '--filename', file_to_disk, '--size', 50 * 1024]
    vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  end

  config.vm.synced_folder ".", "/home/vagrant/nix-docker"

  config.vm.provision :shell, inline: <<eos
  # setup nix-docker link
  ln -s /home/vagrant/nix-docker/nix-docker/bin/nix-docker /usr/local/bin/nix-docker
  # execute apt-get update once to save time
  apt-get update
eos
  config.vm.provision :shell, :path => "scripts/install-extradisk.sh"
  config.vm.provision :shell, :path => "scripts/install-docker.sh"
  config.vm.provision :shell, :path => "scripts/install-nix.sh"

  config.vm.network "private_network", ip: "192.168.22.22"


end
