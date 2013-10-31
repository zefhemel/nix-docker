{ pkgs ? import <nixpkgs> {}
, configuration ? import <configuration> { inherit pkgs; }
}:
let
    inherit (pkgs.lib) concatMapStrings getAttr attrNames hasAttr;
    stdenv = pkgs.stdenv;
    supervisorConfig = pkgs.writeText "supervisord.conf" ''
[supervisord]
logfile=/tmp/supervisord.log

${concatMapStrings (name:
    let
        cfg = getAttr name configuration.services;
    in
        ''
        [program:${name}]
        command=${cfg.command}
        ${if hasAttr "cwd" cfg then
           "directory=${cfg.cwd}"
        else ""}
        ''
    ) (attrNames configuration.services)
}
'';
    startScript = pkgs.writeText "start" ''
    ${pkgs.pythonPackages.supervisor}/bin/supervisord -c ${supervisorConfig} -n
'';
in stdenv.mkDerivation {
    name = "dockerconfig";
    src = ./.;
    
    phases = [ "installPhase" ];
    
    installPhase = ''
        mkdir -p $out/bin
        cp ${startScript} $out/bin/start
        chmod +x $out/bin/start
    '';
}
    