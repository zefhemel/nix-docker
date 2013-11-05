#!/bin/sh
sudo -E nix-docker/bin/nix-docker base-configuration.nix -t zefhemel/base-nix --from busybox -b
