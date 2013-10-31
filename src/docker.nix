{ pkgs ? import <nixpkgs> {}
, configuration ? import <configuration> { inherit pkgs; }
}:
let
    inherit (pkgs.lib) concatMapStrings getAttr attrNames hasAttr;
    
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
    