{ config, pkgs, ... }:
with pkgs.lib;
{
  options = {
    environment.systemPackages = mkOption {
      default = [];
      description = "Packages to be put in the system profile.";
    };
  };

  config = {
    docker.buildScripts.systemEnv = let
        systemPackages = config.environment.systemPackages;
        systemEnv = pkgs.buildEnv { name = "system-env"; paths = systemPackages; };
      in ''
        rm -rf /usr
        ln -s ${systemEnv} /usr
      '';
  };
}