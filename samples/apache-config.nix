{ config, pkgs, ... }:
{
  # Expose the apache port (80)
  docker.ports = [
    config.services.httpd.port
  ];

  services.httpd = {
    enable = true;
    port = 80;
    documentRoot = ./www;
    adminAddr = "zef.hemel@logicblox.com";
  };
}