let
  pkgs = import <nixpkgs> {};
  nodePackages = pkgs.recurseIntoAttrs (import <nixpkgs/pkgs/top-level/node-packages.nix> {
    inherit pkgs;
    inherit (pkgs) stdenv nodejs fetchurl;
    neededNatives = [pkgs.python pkgs.utillinux];
    self = nodePackages;
    generated = ./node-packages-generated.nix;
  });
in
  nodePackages.buildNodePackage {
    name = "nixdocker";
    src = [ { outPath = ./src; name = "nixdocker"; } ];
    deps = with nodePackages; [optimist];
    passthru.names = [ "nixdocker" ];    
  }