let
  pkgs = import <nixpkgs> {};
in
  pkgs.stdenv.mkDerivation {
    name = "nix-docker-0.1";
    src = ./nix-docker;
    installPhase = ''
      mkdir -p $out
      cp -R * $out/
    '';
  }