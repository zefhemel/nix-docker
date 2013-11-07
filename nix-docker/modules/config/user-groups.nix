{pkgs, config, ...}:

with pkgs.lib;

let

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
      uid = mkDefault null;
      shell = mkDefault "/bin/sh";
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
      gid = mkDefault null;
    };

  };

  extraUsers = config.users.extraUsers;
  extraGroups = config.users.extraGroups;

  uidUsers = listToAttrs
    (imap (i: name:
      let
        user = getAttr name extraUsers;
      in {
        name=name;
        value = if user.uid == null then
          setAttr user "uid" (builtins.add 1000 i)
        else user;
      })
      (attrNames extraUsers));

  gidGroups = listToAttrs
    (imap (i: name:
      let
        group = getAttr name extraGroups;
      in {
        name=name;
        value = if group.gid == null then
          setAttr group "gid" (builtins.add 1000 i)
        else group;
      })
      (attrNames extraGroups));
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

  config = {

    users.extraUsers = {
      root = {
        uid = 0;
        description = "System administrator";
        home = "/root";
        group = "root";
      };
      nobody = {
        uid = 1;
        description = "Unprivileged account (don't use!)";
      };
      ldap = {};
    };

    users.extraGroups = {
      root = { gid = 0; };
      wheel = { };
      disk = { };
      kmem = {  };
      tty = { };
      floppy = { };
      uucp = { };
      lp = { };
      cdrom = { };
      tape = { };
      audio = { };
      video = { };
      dialout = { };
      nogroup = { };
      users = { };
      utmp = { };
      adm = { };
    };

    environment.etc.passwd.text =
      concatMapStrings (name:
          let
            user = getAttr name uidUsers;
          in
            if user.createUser then
              "${user.name}:x:${toString user.uid}:${toString (getAttr user.group gidGroups).gid}:${user.description}:${user.home}:${user.shell}\n"
            else
              ""
        ) (attrNames uidUsers);

    environment.etc.group.text =
      concatMapStrings (name:
          let
            group = getAttr name gidGroups;
          in
            "${group.name}:x:${toString group.gid}:\n"
        ) (attrNames gidGroups);
  };

}