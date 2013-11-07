#!/bin/sh

if [ "$(which docker)" != "" ]; then
    exit 0
fi

apt-get update

apt-get install -y linux-image-extra-`uname -r`

sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"

# Add the Docker repository to your apt sources list.
sh -c "echo deb http://get.docker.io/ubuntu docker main\
> /etc/apt/sources.list.d/docker.list"

# update
apt-get update

# install
apt-get install -y lxc-docker
