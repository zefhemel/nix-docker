Vagrant.configure("2") do |config|
  config.vm.box = "raring64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"


  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]

    # We'll attach an extra 50GB disk for all nix and docker data
    file_to_disk = "disk.vmdk"
    vb.customize ['createhd', '--filename', file_to_disk, '--size', 50 * 1024]
    vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  end

  config.vm.provision :shell, inline: <<eos
echo "PATH=/home/vagrant/nix-docker/nix-docker/bin:\\$PATH" > /etc/profile.d/path.sh

if [ ! -d /data ]; then
    mkfs.ext4 -F /dev/sdb
    mkdir -p /nix
    echo "/dev/sdb /nix ext4 defaults 0 2" >> /etc/fstab
    mount /nix
    mkdir -p /nix/docker-lib
    ln -s /nix/docker-lib /var/lib/docker
fi
eos

  config.vm.provision :shell, :path => "scripts/install-docker.sh"
  #config.vm.provision :shell, inline: "chmod 777 /var/run/docker.sock"
  config.vm.provision :shell, :path => "scripts/install-nix.sh"

  config.vm.network "private_network", ip: "192.168.22.22"

  config.vm.synced_folder ".", "/home/vagrant/nix-docker"

end
