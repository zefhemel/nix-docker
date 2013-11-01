{ pkgs
, config }:
with pkgs.lib;
let
  extraUsers = config.config.users.extraUsers;
  extraGroups = config.config.users.extraGroups;
in {
  passwdFile = pkgs.writeText "passwd" ''
    ${concatMapStrings (name:
      let
        user = getAttr name extraUsers;
      in
        if user.createUser then
          "${user.name}:x:${toString user.uid}:${toString (getAttr user.group extraGroups).gid}:Description:${user.home}:${user.shell}\n"
        else
          ""
    ) (attrNames extraUsers)}
    '';
  groupFile = pkgs.writeText "group" ''
    ${concatMapStrings (name:
      let
        group = getAttr name extraGroups;
      in
        "${group.name}:x:${toString group.gid}:\n"
    ) (attrNames extraGroups)}
  '';
}