#!/bin/bash

set -ex

if [ ! -d /data ]; then
    mkfs.ext4 -F /dev/sdb
    mkdir -p /nix
    echo "/dev/sdb /nix ext4 defaults 0 2" >> /etc/fstab
    mount /nix
    mkdir -p /nix/docker-lib
    ln -sf /nix/docker-lib /var/lib/docker
fi
