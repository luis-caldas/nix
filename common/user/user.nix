{ ... }:
let
  configgo = import ../../config.nix;
in
{

  # Make users mutable
  users.mutableUsers = true;

  # Automatic login
  services.mingetty.autologinUser = configgo.user.name;

  # My user
  users.groups."${configgo.user.name}".gid = 1000;
  users.users."${configgo.user.name}" = {

    # Simple user configuration
    isNormalUser = true;
    home = "/home/" + configgo.user.name;
    description = configgo.user.desc;

    # Primary group
    group = configgo.user.name;

    # Give extra groups to the user
    extraGroups = configgo.user.groups;

    # Set out custom uid
    uid = 1000;

    # Set the user to the first default uid
    initialPassword = configgo.user.pass;
  
  };

  # Add my custom motd
  users.motd = configgo.system.motd;

}
