{ config, pkgs, ... }:
with pkgs.lib;
{
  options = {
    docker = {
      ports = mkOption {
        default = [];
        description = "Ports to expose to the outside world.";
        example = [ 80 22 ];
      };
    };
  };
}