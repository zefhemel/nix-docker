{ config, pkgs, ... }:
{
  docker.ports = [ 1234 80 ];

  services.redis = {
    enable = true;
    port = 1234;
    logLevel = "debug";
  };

  services.httpd.enable = true;
  services.httpd.port = 80;
  services.httpd.documentRoot = ./www;
  services.httpd.adminAddr = "zef.hemel@logicblox.com";

  supervisord.tailLogs = true;

  users.extraUsers.zef = {
    group = "users";
    home = "/home/zef";
    createHome = true;
  };
}