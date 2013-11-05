# Runs an SSH server in a Docker container
# Creates a user "you" that you can login with
{ config, pkgs, ... }:
{
  docker.ports = [ 22 ];

  services.openssh.enable = true;

  users.extraUsers.you = {
    group = "users";
    home = "/";
    shell = "/bin/bash";
    createHome = true;
    openssh.authorizedKeys.keys = [
      # Replace with your own SSH key (e.g. from ~/.ssh/id_rsa.pub)
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjWpdyDIsS09lWlOsMG9OMTHB/N/afVU12BwKcyjjhbezPdFEgHK4cZBN7m1bvoFKl832BdB+ZjeRH4UGBcUpvrFu1vE7Lf/0vZDU7qzzWQE9V+tfSPwDiXPf9QnCYeZmYPDHUHDUEse9LKBZbt6UKF1tuTD8ussV5jvEFBaesDhCqD1TJ4b4O877cdx9+VTOuDSEDm32jQ2az27d1b/5DoEKBe5cJSC3PhObAQ7OAYrVVBFX9ffKpaSvV6yqo+rhCmXP9DjNgBwMtElreoXL3h5Xbw2AiER5oHNUAEA2XGpnOVOr7ZZUAbMC0/0dq387jQZCqe7gIDZCqjDpGhUa9"
    ];
  };
}