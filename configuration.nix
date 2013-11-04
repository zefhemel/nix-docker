{ config, pkgs, ... }:
{
  docker.ports = [ 1234 80 ];
  docker.verbose = true;

  services.redis = {
    enable = true;
    port = 1234;
    logLevel = "debug";
  };

  services.httpd.enable = true;
  services.httpd.port = 80;
  services.httpd.documentRoot = ./www;
  services.httpd.adminAddr = "zef.hemel@logicblox.com";

  services.mysql.enable = true;
  services.openssh.enable = true;

  supervisord.tailLogs = true;

  users.extraUsers.zef = {
    group = "users";
    home = "/";
    shell = "/bin/bash";
    createHome = true;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjWpdyDIsS09lWlOsMG9OMTHB/N/afVU12BwKcyjjhbezPdFEgHK4cZBN7m1bvoFKl832BdB+ZjeRH4UGBcUpvrFu1vE7Lf/0vZDU7qzzWQE9V+tfSPwDiXPf9QnCYeZmYPDHUHDUEse9LKBZbt6UKF1tuTD8ussV5jvEFBaesDhCqD1TJ4b4O877cdx9+VTOuDSEDm32jQ2az27d1b/5DoEKBe5cJSC3PhObAQ7OAYrVVBFX9ffKpaSvV6yqo+rhCmXP9DjNgBwMtElreoXL3h5Xbw2AiER5oHNUAEA2XGpnOVOr7ZZUAbMC0/0dq387jQZCqe7gIDZCqjDpGhUa9 zefhemel@gmail.com" ];
  };
}