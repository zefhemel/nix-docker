{ pkgs ? import <nixpkgs> {}
, configuration ? <configuration>
, mountBuild ? false
, imageName ? "docker-build-nix"
, baseImage ? "ubuntu"
}:
with pkgs.lib;
let
# pkgs = import <nixpkgs> {}
# config = import <nixpkgs/nixos/lib/eval-config.nix> { modules = [ ./configuration.nix ./src/base.nix ]; }
#
  config = import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [ configuration ./base.nix ];
  };

  localNixPath = pkg: "nix_store/${substring 11 (stringLength pkg.outPath) pkg.outPath}";

  users = import ./users.nix { inherit pkgs config; };
  systemd = import ./systemd.nix { inherit pkgs config; };
  environment = import ./environment.nix { inherit pkgs config; };

  setupScript = ''
    cp ${users.groupFile} /etc/group
    cp ${users.passwdFile} /etc/passwd
    ${environment.updateEtcScript}
    ${environment.setupSystemProfile}
    ${systemd.oneShotScript}
  '';

  shellScriptFile = pkgs.writeScript "shell" ''
    #!/bin/sh
    ${setupScriptFile}
    /usr/bin/bash
  '';

  setupScriptFile = pkgs.writeScript "setup" ''
    #!/bin/sh -e
    ${setupScript}
  '';

  runScript = pkgs.writeScript "run" ''
    #!/bin/sh
    ${if mountBuild then setupScript else ""}
    ${pkgs.pythonPackages.supervisor}/bin/supervisord -c ${systemd.supervisorConfigFile} -n &
    mkdir -p /var/log/supervisord
    sleep 2
    touch /var/log/supervisord/test.log
    tail -n 100 -f /var/log/supervisord/*.log
  '';

  dockerFile = pkgs.writeText "Dockerfile" ''
    FROM ${baseImage}
    ${if !mountBuild then
      ''
    ADD nix_store /nix/store
    RUN ${setupScriptFile}
      ''
    else ""
    }
    RUN ln -sf ${shellScriptFile} /bin/shell
    CMD ${runScript}
    ${
      concatMapStrings (port: "EXPOSE ${toString port}\n") config.config.docker.ports
    }
  '';

  runContainerScript = pkgs.writeScript "docker-run" ''
    #!/usr/bin/env bash

    OPTIONS="-t -i $*"
    if [ "$1" == "-d" ]; then
      OPTIONS="$*"
    fi

    docker run $OPTIONS ${if mountBuild then "-v /nix/store:/nix/store" else ""} ${imageName}
  '';

in pkgs.stdenv.mkDerivation {
  name = "dockerfile";
  src = ./.;

  phases = [ "installPhase" ];

  installPhase = ''
      mkdir -p $out/bin
      cp ${runContainerScript} $out/bin/run-container
      cp ${dockerFile} $out/Dockerfile
  '';
}