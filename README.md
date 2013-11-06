nix-docker
==========

The problem
-----------

[Docker is great](http://www.infoq.com/articles/docker-containers). It's a nice,
pragmatic solution to deploying applications in a portable way. There are two
things I don't like about Docker:

1. How container images are provisioned
2. (This is more minor:) how images are distributed

We can argue about (2) and I'm sure it it will improve. Docker images are distributed
via a Docker registry. The main one lives at http://index.docker.io, and if your
application can be openly available to everyone, this works great. If you need
to keep applications in-house, you have to host your own registry server, and
support for that (e.g. with authentication) is still limited.

But my main gripe is (1). Docker images are provisioned using a
[Dockerfile](http://docs.docker.io/en/latest/use/builder/), which basically
a simple imperative script that builds up an image from a base image step by
step. Typical Dockerfile lines look like this:

    RUN apt-get update
    RUN apt-get upgrade -y
    RUN apt-get install -y openssh-server python curl

Every such command that you run is committed, resulting in an AuFS layer. This
can be helpful, because Docker can now do basic caching. For instance, if
your build fails at the third line, it can use the image resulting from
the first two lines and start from there. There's a number problems with this
approach:

1. Can those first two lines really be cached, or may their result be dependent
   on the time of being run? Answer: yes, running these lines tomorrow may yield
   different results than running them today, but Docker will naively assume
   they will always result in the same thing.
2. AuFS can not handle an unlimited number of layers, if your Dockerfile has too
   many commands the build will simply fail. So, you better make them count.
3. There's very little support for reuse. There's no include files or configuration
   language. All you can do is create a hierarchy of images, where you create
   a base image with software common to all other images, and then you use `FROM`
   to base future image on. And you're still limited by (2), the layers all add
   up.

What Nix brings to the table
----------------------------

[Nix](http://nixos.org/nix/) is a relatively new package manager for Unix systems,
it's not specific to Linux, it works on Mac as well, for instance. In short, it's
package management done right:

* Packages and sytems are built using the Nix functional language, which is a
  full-blown functional language designed specifically for deploying simple and
  complex systems.
* Completele dependency closures are automatically derived, so do not have to
  be constructed by hand (as is the case with dpkg and RPM).
* Rather than scattering files all over the disk (configuration files in `/etc`,
  binaries in `/usr/bin` or `/usr/local/bin` or is it `/bin`), components are
  stored in isolation in the Nix store (`/nix/store`) not interfering  with each
  other.
* Nix has excellent support for modularization.

While Nix itself is "just" a package manager, there are many tools built on top
of it, including a full-blown Linux distribution called [NixOS](http://nixos.org/nixos/).

NixOS enables you to declaratively specify your entire system configuration using
the Nix language. Based on this configuration, it can build the entire system, which
can be deployed locally or remotely via [NixOps](https://github.com/NixOS/nixops).

In the context of Docker, the problem with NixOS is that it's truly a full-blown
OS. All services run using [systemd](http://www.freedesktop.org/wiki/Software/systemd/),
kernels are deployed and a bunch of utility processes are running at all times.

I tried to see if it's feasible to deploy a system configuration built for NixOS
in a Docker container, but couldn't get it to run because systemd wouldn't run,
beside that, configurations quickly get large, many hundreds of megabytes. So
much for light-weight containers, huh.

Nevertheless, NixOS configurations are kind of nice and clean and would make sense
for Docker as well. For instance, here's how to run a simple Apache server
serving static files from `./www` directory:

    { config, pkgs, ... }:
    {
      services.httpd = {
        enable = true;
        documentRoot = ./www;
        adminAddr = "zef.hemel@logicblox.com";
      };
    }

That's all it takes. The `./www` there refers to the path `./www` local to the
system configuration file, by the way. When the system configuration is built,
the contents of `./www` is automatically copied into the Nix store and becomes
part of the dependencies of the system configuration.

Wouldn't it be cool to deploy NixOS configs in docker containers? That's what
nix-docker attempts to offer.

How it works
------------

`nix-docker` can be run in two modes:

1. A "traditional" Docker image building mode
2. A thin image mode which mounts the hosts's Nix store into the container

The first mode will build the system configuration, copy it into a temporary
directory and the `ADD` it into the image in a generated Dockerfile. The result
is a standard, portable Docker image that you can push to a repository.

To reduce the per-image size, it's possible to use a base image, `nix-docker` is
clever enought to check what `/nix/store` paths are available in the base image
already and not to copy those again for the new image thereby greatly reducing
image sizes.

The second option builds a very minimal Docker images on-demand containing
only some meta data (like `EXPOSE` and `VOLUME`, `RUN` commands in a Dockerfile)
and is used by mounting in the host's Nix store into the container via
`-v /nix/store:/nix/store`. There's two reasons you may want to use this mode
(even just during development):

1. Build times are _much_ faster, since Nix builds are fully incremental, only
   things that have not been build before will be built.
2. You don't polute your `/var/lib/docker` with a lot of copies of your software.

Installation with Vagrant
-------------------------
The easy way to do this is to use [Vagrant](http://vagrantup.com).

When you have Vagrant installed:

    git clone https://github.com/zefhemel/nix-docker.git
    cd nix-docker
    vagrant up
    vagrant ssh

If all went well, you're now in a VM that has both Docker and Nix installed
and `nix-docker` in its path. You can now cd into the nix-docker/samples directory
to try to build some of the examples. Note that the `~/nix-docker` directory
is mounted from your host machine, so you can edit your files with your
favorite editor and have them available within the VM.

Installation
------------

To use nix-docker you need [Nix](http://nixos.org/nix) installed as well as
[Docker](http://www.docker.io). Realistically, your best way to do this on
an Ubuntu (12.04 or 13.04) box. Once these are installed, installing `nix-docker`
is as simple as:

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

to daemonize it. What the `docker-run` script will do is check if there's already
a docker image available with the current image name and tag based on the Nix
build hash. If not, it will quickly build it first (these images take up barely
any space on disk). Then, it will boot up the container.

Distributing host-mounted packages is done by first copying the Nix closure
resulting from the build to the target machine (when you do the build it
will give you example commands to run):

    nix-copy-closure root@targetmachine /nix/store/....

Then, you can spawn the container remotely with the script path provided
in the output of the build command.