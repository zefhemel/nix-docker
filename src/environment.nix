{ pkgs
, config }:
with pkgs.lib;
let
  etc = config.config.environment.etc;
  systemPackages = config.config.environment.systemPackages;
in {
  updateEtcScript = concatMapStrings (filename:
      let
        file = getAttr filename etc;
      in
        if file.enable then
          ''
          mkdir -p /etc/${dirOf "/${file.target}"}
          ln -s ${file.source} ${file.target}
          ''
        else ""
    ) (attrNames etc);

  setupSystemProfile = ''
    rm -rf /usr
    ln -s ${config.config.system.path} /usr
  '';
}