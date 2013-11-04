{ config, pkgs, ... }:
with pkgs.lib;
let
  etc2 = filter (f: f.enable) (attrValues config.environment.etc);

  etc = pkgs.stdenv.mkDerivation {
    name = "etc";

    builder = <nixpkgs/nixos/modules/system/etc/make-etc.sh>;

    preferLocalBuild = true;

    /* !!! Use toXML. */
    sources = map (x: x.source) etc2;
    targets = map (x: x.target) etc2;
    modes = map (x: x.mode) etc2;
  };
in {
  options = {
    environment.systemPackages = mkOption {
      default = [];
      description = "Packages to be put in the system profile.";
    };

    system.activationScripts.etc = mkOption {}; # Ignore
    system.build.etc = mkOption {}; # Ignore

  };

  config = {
    docker.buildScripts."0-systemEnv" = let
        systemPackages = config.environment.systemPackages;
        systemEnv = pkgs.buildEnv { name = "system-env"; paths = systemPackages; };
      in ''
        rm -rf /usr
        chmod 777 /tmp
        ln -s ${systemEnv} /usr
        ln -sf /usr/bin/bash /bin/bash
      '';

    environment.systemPackages = with pkgs; [ coreutils bash ];

    docker.buildScripts."0-etc" = ''
        echo "setting up /etc..."
        ${pkgs.perl}/bin/perl ${<nixpkgs/nixos/modules/system/etc/setup-etc.pl>} ${etc}/etc
      '';
  };
}