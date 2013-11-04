{ pkgs ? import <nixpkgs> {}
, name
, configuration ? <configuration>
, mountBuild ? true
, baseImage ? "ubuntu"
}:
with pkgs.lib;
let
  config = evalModules {
    modules = concatLists [ [configuration] (import ./all-modules.nix) ];
    args = { inherit pkgs; };
  };

  localNixPath = pkg: "nix_store/${substring 11 (stringLength pkg.outPath) pkg.outPath}";

  systemd = import ./systemd.nix { inherit pkgs config; };
  environment = import ./environment.nix { inherit pkgs config; };


  buildScript = pkgs.writeScript "build" ''
    #!/bin/sh -e
    ${config.config.docker.buildScript}
  '';

  bootScript = pkgs.writeScript "boot" ''
    #!/bin/sh -e
    ${if mountBuild then config.config.docker.buildScript else ""}
    ${config.config.docker.bootScript}
  '';

  dockerFile = pkgs.writeText "Dockerfile" ''
    FROM ${baseImage}
    ${if !mountBuild then
      ''
        ADD nix_store /nix/store
        RUN ${buildScript}
      ''
    else ""}
    CMD ${bootScript}
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

    docker run $OPTIONS ${if mountBuild then "-v /nix/store:/nix/store" else ""} ${name}
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