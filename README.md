nix-docker
==========

Use [NixOS](http://nixos.org/nixos) configurations to provision [Docker](http://docker.io) containers.

[Read about the what and why in this blog post](http://zef.me/6049/nix-docker)

DISCLAIMER: This project is no longer actively maintained and probably broken, if you're interested in fixing it, please fork and contact me: zefhemel@gmail.com
------------

Installation with Vagrant
-------------------------
The easy way to do this is to use [Vagrant](http://vagrantup.com).

When you have Vagrant installed:

    git clone https://github.com/zefhemel/nix-docker.git
    cd nix-docker
    vagrant up
    vagrant ssh

If all went well, you're now in a VM that has both Docker and Nix installed
and `nix-docker` in its path. 

At this point you need to connect to the VM and have nix setup the vagrant users own custom package stores. execute the follow

    nix-channel --update
    nix-env -i hello

You can now cd into the nix-docker/samples
directory to try to build some of the examples. Note that the `~/nix-docker`
directory is mounted from your host machine, so you can edit your files with
your favorite editor and have them available within the VM.

Installation
------------

To use nix-docker you need [Nix](http://nixos.org/nix) installed as well as
[Docker](http://www.docker.io). Realistically, your best way to do this on
an Ubuntu (12.04 or 13.04) box. Once these are installed, installing
`nix-docker` is as simple as:

    git clone https://github.com/zefhemel/nix-docker.git
    nix-env -f nix-docker/default.nix -i nix-docker

Usage
-----

To build a stand-alone Docker image:

    nix-docker -b -t my-image configuration.nix

This will build the configuration specified in `configuration.nix`, have a look
in the `samples/` directory for examples. It will produce a docker image named
`my-image` which you can then run anywhere. Use `username/my-image` to be able
to push them to the Docker index.

To build a host-mounted package:

    nix-docker -t my-image configuration.nix

This will produce a Nix package (symlinked in the current directory in `result`)
containing a script you can use to spawn the container using Docker, e.g.:

    sudo -E ./result/sbin/docker-run

to run the container in the foreground, or:

    sudo -E ./result/sbin/docker-run -d

to daemonize it. What the `docker-run` script will do is check if there's
already a docker image available with the current image name and tag based on
the Nix build hash. If not, it will quickly build it first (these images take up
barely any space on disk). Then, it will boot up the container.

Distributing host-mounted packages is done by first copying the Nix closure
resulting from the build to the target machine (when you do the build it
will give you example commands to run):

    nix-copy-closure root@targetmachine /nix/store/....

Then, you can spawn the container remotely with the script path provided
in the output of the build command.
