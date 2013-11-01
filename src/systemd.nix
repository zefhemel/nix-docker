{ pkgs
, config }:
with pkgs.lib;
let
  services = removeAttrs config.config.systemd.services [
    "acpid"
    "network-setup"
    "prepare-kexec"
    "systemd-sysctl"
    "alsa-store"
    "nix-daemon"
    "rngd"
    "systemd-update-utmp"
    "cpufreq"
    "nix-gc"
    "scsi-link-pm"
    "systemd-vconsole-setup"
    "cron"
    "nscd"
    "synergy-client"
    "update-locatedb"
    "dhcpcd"
    "ntpd"
    "synergy-server"
    "post-resume"
    "systemd-modules-load"
    "klogd"
    "pre-sleep"
    "systemd-random-seed"
  ];

  isOneShot = cfg: hasAttr "Type" cfg.serviceConfig && cfg.serviceConfig.Type == "oneshot";

  runServices = filterAttrs (name: cfg: !(isOneShot cfg)) services;

  oneShotServices = filterAttrs (name: cfg: isOneShot cfg) services;

  configToCommand = name: cfg: if hasAttr "ExecStart" cfg.serviceConfig then
          cfg.serviceConfig.ExecStart
        else if hasAttr "script" cfg then
          pkgs.writeScript "${name}-script" ''
            #!/bin/sh -e
            ${cfg.script}
            ''
        else
          "";
in {
  oneShotScript = concatMapStrings (name: "${configToCommand name (getAttr name oneShotServices)}\n") (attrNames oneShotServices);
  supervisorConfigFile = pkgs.writeText "supervisord.conf" ''
    [supervisord]
    logfile=/var/log/supervisord/supervisord.log

    ${concatMapStrings (name:
      let
        cfg = getAttr name runServices;
      in
        ''
        [program:${name}]
        command=${configToCommand name cfg}
        redirect_stderr=true
        stdout_logfile=/var/log/supervisord/${name}.log
        ${if hasAttr "User" cfg.serviceConfig then "user=${cfg.serviceConfig.User}\n" else ""}
        ''
      ) (attrNames runServices)
    }
  '';
}