{pkgs, config, ...}:

with pkgs.lib;

let

  ids = config.ids;
  users = config.users;

  userOpts = { name, config, ... }: {

    options = {

      name = mkOption {
        type = types.str;
        description = "The name of the user account. If undefined, the name of the attribute set will be used.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        example = "Alice Q. User";
        description = ''
          A short description of the user account, typically the
          user's full name.  This is actually the “GECOS” or “comment”
          field in <filename>/etc/passwd</filename>.
        '';
      };

      uid = mkOption {
        type = with types; uniq (nullOr int);
        default = null;
        description = "The account UID. If undefined, NixOS will select a free UID.";
      };

      group = mkOption {
        type = types.str;
        default = "nogroup";
        description = "The user's primary group.";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The user's auxiliary groups.";
      };

      home = mkOption {
        type = types.str;
        default = "/var/empty";
        description = "The user's home directory.";
      };

      shell = mkOption {
        type = types.str;
        default = "/run/current-system/sw/sbin/nologin";
        description = "The path to the user's shell.";
      };

      createHome = mkOption {
        type = types.bool;
        default = false;
        description = "If true, the home directory will be created automatically.";
      };

      useDefaultShell = mkOption {
        type = types.bool;
        default = false;
        description = "If true, the user's shell will be set to <literal>users.defaultUserShell</literal>.";
      };

      password = mkOption {
        type = with types; uniq (nullOr str);
        default = null;
        description = ''
          The user's password. If undefined, no password is set for
          the user.  Warning: do not set confidential information here
          because it is world-readable in the Nix store.  This option
          should only be used for public accounts such as
          <literal>guest</literal>.
        '';
      };

      isSystemUser = mkOption {
        type = types.bool;
        default = true;
        description = "Indicates if the user is a system user or not.";
      };

      createUser = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Indicates if the user should be created automatically as a local user.
          Set this to false if the user for instance is an LDAP user. NixOS will
          then not modify any of the basic properties for the user account.
        '';
      };

      isAlias = mkOption {
        type = types.bool;
        default = false;
        description = "If true, the UID of this user is not required to be unique and can thus alias another user.";
      };

    };

    config = {
      name = mkDefault name;
      uid = mkDefault (attrByPath [name] null ids.uids);
      shell = mkIf config.useDefaultShell (mkDefault users.defaultUserShell);
    };

  };

  groupOpts = { name, config, ... }: {

    options = {

      name = mkOption {
        type = types.str;
        description = "The name of the group. If undefined, the name of the attribute set will be used.";
      };

      gid = mkOption {
        type = with types; uniq (nullOr int);
        default = null;
        description = "The GID of the group. If undefined, NixOS will select a free GID.";
      };

    };

    config = {
      name = mkDefault name;
      gid = mkDefault (attrByPath [name] null ids.gids);
    };

  };

  # Note: the 'X' in front of the password is to distinguish between
  # having an empty password, and not having a password.
  serializedUser = u: "${u.name}\n${u.description}\n${if u.uid != null then toString u.uid else ""}\n${u.group}\n${toString (concatStringsSep "," u.extraGroups)}\n${u.home}\n${u.shell}\n${toString u.createHome}\n${if u.password != null then "X" + u.password else ""}\n${toString u.isSystemUser}\n${toString u.createUser}\n${toString u.isAlias}\n";

  usersFile = pkgs.writeText "users" (
    let
      p = partition (u: u.isAlias) (attrValues config.users.extraUsers);
    in concatStrings (map serializedUser p.wrong ++ map serializedUser p.right));

in

{

  ###### interface

  options = {

    users.extraUsers = mkOption {
      default = {};
      type = types.loaOf types.optionSet;
      example = {
        alice = {
          uid = 1234;
          description = "Alice Q. User";
          home = "/home/alice";
          createHome = true;
          group = "users";
          extraGroups = ["wheel"];
          shell = "/bin/sh";
        };
      };
      description = ''
        Additional user accounts to be created automatically by the system.
        This can also be used to set options for root.
      '';
      options = [ userOpts ];
    };

    users.extraGroups = mkOption {
      default = {};
      example =
        { students.gid = 1001;
          hackers = { };
        };
      type = types.loaOf types.optionSet;
      description = ''
        Additional groups to be created automatically by the system.
      '';
      options = [ groupOpts ];
    };

  };
}