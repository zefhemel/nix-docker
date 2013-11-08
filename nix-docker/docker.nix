{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
, name
, configuration ? <configuration>
, mountBuild ? true
, baseImage ? "busybox"
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

  verboseFlag = if config.config.docker.verbose then "v" else "";


  buildScript = pkgs.writeScript "build" ''
    #!/bin/sh -e${verboseFlag}
    ${config.config.docker.buildScript}
  '';

  bootScript = pkgs.writeScript "boot" ''
    #!/bin/sh -e${verboseFlag}
    umask ${config.config.environment.umask}
    ${if mountBuild then config.config.docker.buildScript else ""}
    ${config.config.docker.bootScript}
  '';

  dockerFile = pkgs.writeText "Dockerfile" ''
    FROM ${if mountBuild then "busybox" else baseImage}
    ${if !mountBuild then
      ''
        ADD nix-closure /nix/store
        RUN ${buildScript}
      ''
    else ""}
    CMD ${bootScript}
    ${
      concatMapStrings (port: "EXPOSE ${toString port}\n") config.config.docker.ports
    }
    ${
      concatMapStrings (port: "VOLUME ${toString port}\n") config.config.docker.volumes
    }
  '';

  imageHash = substring 11 8 dockerFile.outPath;

  runContainerScript = pkgs.writeScript "docker-run" ''
    #!/usr/bin/env bash

    if [ "" == "$(docker images | grep -E "${name}\s*${imageHash}")" ]; then
      docker build -t ${name}:${imageHash} $(dirname $0)/..
    fi

    OPTIONS="-t -i $*"
    if [ "$1" == "-d" ]; then
      OPTIONS="$*"
    fi

    docker run $OPTIONS ${if mountBuild then "-v /nix/store:/nix/store" else ""} ${name}:${imageHash}
  '';

in pkgs.stdenv.mkDerivation {
  name = replaceChars ["/"] ["-"] name;
  src = ./.;

  phases = [ "installPhase" ];

  installPhase = ''
      mkdir -p $out
      ${if mountBuild then ''
        mkdir -p $out/sbin
        cp ${runContainerScript} $out/sbin/docker-run
      '' else ""}
      cp ${dockerFile} $out/Dockerfile
  '';
}