[
  ./modules/config/docker.nix
  ./modules/config/user-groups.nix
  ./modules/config/environment.nix
  ./modules/servers/supervisord.nix

  ./modules/shim/systemd.nix
  <nixpkgs/nixos/modules/system/etc/etc.nix>
  <nixpkgs/nixos/modules/misc/assertions.nix>
  <nixpkgs/nixos/modules/misc/ids.nix>
  <nixpkgs/nixos/modules/services/databases/redis.nix>
  <nixpkgs/nixos/modules/services/databases/mysql.nix>
  <nixpkgs/nixos/modules/programs/ssh.nix>
  <nixpkgs/nixos/modules/services/search/elasticsearch.nix>

  # These modules needed some patching to work well
  ./modules/servers/http/apache/default.nix
  ./modules/servers/openssh.nix
]