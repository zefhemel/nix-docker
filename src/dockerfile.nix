{ pkgs ? import <nixpkgs> {}
, configuration ? <configuration>
}:
with pkgs.lib;
let
  config = import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [ configuration ./base.nix ];
  };

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

  configToCommand = cfg: if hasAttr "ExecStart" cfg.serviceConfig then
          cfg.serviceConfig.ExecStart
        else if hasAttr "script" cfg then
          pkgs.writeScript "script" ''
            #!/bin/sh
            ${cfg.script}
            ''
        else
          "";

  supervisorConfig = pkgs.writeText "supervisord.conf" ''
    [supervisord]
    logfile=/tmp/supervisord.log

    ${concatMapStrings (name:
      let
        cfg = getAttr name runServices;
      in
        ''
        [program:${name}]
        command=${configToCommand cfg}''
      ) (attrNames runServices)
    }
  '';

  extraUsers = config.config.users.extraUsers;

  dockerFile = pkgs.writeText "Dockerfile" ''
FROM ubuntu
<<BODY>>
# Create users
${
  concatMapStrings (name: "RUN /usr/sbin/useradd ${name} || echo\n") (attrNames extraUsers)
}
# Run one shot services
${
  concatMapStrings (name: "RUN ${configToCommand (getAttr name oneShotServices)}\n") (attrNames oneShotServices)
}


${
    # if hasAttr "docker" configuration && hasAttr "ports" configuration.docker then
    #     concatMapStrings (port: "EXPOSE ${toString port}\n") configuration.docker.ports
    # else
    #   ""
    ""
}
CMD ${pkgs.pythonPackages.supervisor}/bin/supervisord -c ${supervisorConfig} -n
'';
in pkgs.stdenv.mkDerivation {
  name = "dockerfile";
  src = ./.;

  phases = [ "installPhase" ];

  installPhase = ''
      mkdir -p $out
      cp ${dockerFile} $out/Dockerfile
  '';
}