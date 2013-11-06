#!/bin/sh
sudo -E nix-docker -b -t zefhemel/base-nix --from busybox base-configuration.nix