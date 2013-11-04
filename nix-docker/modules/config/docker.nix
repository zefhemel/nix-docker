{ config, pkgs, ... }:
with pkgs.lib;
{
  options = {
    docker.ports = mkOption {
      default = [];
      description = "Ports to expose to the outside world.";
      example = [ 80 22 ];
    };

    docker.buildScripts = mkOption {
      default = {};
      example = {
        setupUsers = "cp passwd /etc/passwd";
      };
      description = "Scripts (as text) to be run during build, executed alphabetically";
    };

    docker.bootScript = mkOption {
      default = "";
      description = "Script (text) to run when container booted.";
    };

    docker.buildScript = mkOption {};

    docker.verbose = mkOption {
      default = false;
      type = types.bool;
    };

    networking = mkOption {};
    security = mkOption {};
    #system.nssModules.path = mkOption {};
    #services.samba = mkOption{};
  };

  config = {
    docker.buildScript = concatStrings (attrValues config.docker.buildScripts);
    networking.enableIPv6 = false;
    #system.nssModules.path = "";
    #services.samba.syncPasswordsByPam = false;
  };
}