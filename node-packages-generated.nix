{ self, fetchurl, lib }:

{
  full."minimist"."~0.0.1" = lib.makeOverridable self.buildNodePackage {
    name = "minimist-0.0.5";
    src = [
      (fetchurl {
        url = "http://registry.npmjs.org/minimist/-/minimist-0.0.5.tgz";
        sha1 = "d7aa327bcecf518f9106ac6b8f003fa3bcea8566";
      })
    ];
    buildInputs =
      (self.nativeDeps."minimist"."~0.0.1" or []);
    deps = [
    ];
    peerDependencies = [
    ];
    passthru.names = [ "minimist" ];
  };
  full."optimist"."0.6.0" = lib.makeOverridable self.buildNodePackage {
    name = "optimist-0.6.0";
    src = [
      (fetchurl {
        url = "http://registry.npmjs.org/optimist/-/optimist-0.6.0.tgz";
        sha1 = "69424826f3405f79f142e6fc3d9ae58d4dbb9200";
      })
    ];
    buildInputs =
      (self.nativeDeps."optimist"."0.6.0" or []);
    deps = [
      self.full."wordwrap"."~0.0.2"
      self.full."minimist"."~0.0.1"
    ];
    peerDependencies = [
    ];
    passthru.names = [ "optimist" ];
  };
  "optimist" = self.full."optimist"."0.6.0";
  full."wordwrap"."~0.0.2" = lib.makeOverridable self.buildNodePackage {
    name = "wordwrap-0.0.2";
    src = [
      (fetchurl {
        url = "http://registry.npmjs.org/wordwrap/-/wordwrap-0.0.2.tgz";
        sha1 = "b79669bb42ecb409f83d583cad52ca17eaa1643f";
      })
    ];
    buildInputs =
      (self.nativeDeps."wordwrap"."~0.0.2" or []);
    deps = [
    ];
    peerDependencies = [
    ];
    passthru.names = [ "wordwrap" ];
  };
}
