Vagrant.configure("2") do |config|
  config.vm.box = "raring64"
  config.vm.box_url = "http://goo.gl/ceHWg"

  config.vm.provision :shell, :path => "scripts/install-docker.sh"
  config.vm.provision :shell, :path => "scripts/install-nix.sh"
  config.vm.provision :shell, inline: <<eos
echo "PATH=/home/vagrant/nix-docker/nix-docker/bin:\\$PATH" > /etc/profile.d/path.sh
chmod 777 /var/run/docker.sock
eos

  config.vm.network "private_network", ip: "192.168.22.22"

  config.vm.synced_folder ".", "/home/vagrant/nix-docker"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
end
