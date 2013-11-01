{ config, pkgs, ... }:
{
  services.redis = {
    enable = true;
    logfile = "stdout";
    logLevel = "debug";
    port = 1234;
    syslog = false;
  };

  #docker.ports = [ 1234 ];

  users.extraUsers.zef = {
    group = "users";
    home = "/home/zef";
    createHome = true;
  };
}