{ pkgs
, config }:
with pkgs.lib;
let
  # etc = config.config.environment.etc;
  systemPackages = config.config.environment.systemPackages;
  systemEnv = pkgs.buildEnv { name = "system-env"; paths = systemPackages; };
in {
  setupSystemProfile = ''
    rm -rf /usr
    ln -s ${systemEnv} /usr
  '';
}