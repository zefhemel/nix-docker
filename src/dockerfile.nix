{ pkgs ? import <nixpkgs> {}
, configuration ? import <configuration> { inherit pkgs; }
}:
let
  inherit (pkgs.lib) hasAttr concatMapStrings;
  dockerFile = pkgs.writeText "Dockerfile" ''
FROM busybox
<<BODY>>
${
    if hasAttr "docker" configuration && hasAttr "ports" configuration.docker then
        concatMapStrings (port: "EXPOSE ${toString port}\n") configuration.docker.ports
    else
    ""
}
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