{ pkgs, config, ... }:
with pkgs.lib;
let
  services = config.systemd.services;

  isOneShot = cfg: hasAttr "Type" cfg.serviceConfig && cfg.serviceConfig.Type == "oneshot";

  runServices = filterAttrs (name: cfg: !(isOneShot cfg)) services;

  oneShotServices = filterAttrs (name: cfg: isOneShot cfg) services;

  configToCommand = name: cfg: ''
      #!/bin/sh -e
      ${if hasAttr "preStart" cfg then cfg.preStart else ""}
      ${if hasAttr "ExecStart" cfg.serviceConfig then
          cfg.serviceConfig.ExecStart
        else if hasAttr "script" cfg then
          cfg.script
        else
          ""
      }
      ${if hasAttr "postStart" cfg then cfg.postStart else ""}
      '';

in {

  options = {
    systemd.services = mkOption { }; # TODO make more specific
  };

  config = {
    docker.buildScripts."1-systemd-oneshot" = concatMapStrings (name: "${configToCommand name (getAttr name oneShotServices)}\n") (attrNames oneShotServices);

    supervisord.services = listToAttrs (map (name:
      let
        cfg = getAttr name runServices;
      in
        {
          name = name;
          value = {
            command = pkgs.writeScript "${name}-run" (configToCommand name cfg);
            user = if hasAttr "User" cfg.serviceConfig then cfg.serviceConfig.User else "root";
            environment = (if hasAttr "environment" cfg then cfg.environment else {}) //
              (if hasAttr "path" cfg then
                { PATH = concatStringsSep ":" (map (prg: "${prg}/bin") cfg.path); }
               else {});
          };
        }
      ) (attrNames runServices));
  };
}