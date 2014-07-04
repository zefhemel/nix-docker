{ config, pkgs, ... }:
with pkgs.lib;
{
  options = {
    docker.ports = mkOption {
      default = [];
      description = "Ports to expose to the outside world.";
      example = [ 80 22 ];
    };

    docker.volumes = mkOption {
      default = [];
      description = "Volumes to create for container.";
      example = [ "/var/lib" "/var/log" ];
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

    # HACK: Let's ignore these for now
    networking = mkOption {};
    security = mkOption {};
    services.xserver.enable = mkOption { default = false; };
  };

  config = {
    docker.buildScript = concatStrings (attrValues config.docker.buildScripts);
    networking.enableIPv6 = false;
  };
}
