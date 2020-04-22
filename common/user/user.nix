{ ... }:
let
  my = import ../../config.nix;
in
{

  # Make users mutable
  users.mutableUsers = true;

  # Automatic login
  services.mingetty.autologinUser = my.config.user.name;

  # My user
  users.groups."${my.config.user.name}".gid = 1000;
  users.users."${my.config.user.name}" = {

    # Simple user configuration
    isNormalUser = true;
    home = "/home/" + my.config.user.name;
    description = my.config.user.desc;

    # Primary group
    group = my.config.user.name;

    # Give extra groups to the user
    extraGroups = my.config.user.groups;

    # Set out custom uid
    uid = 1000;

    # Set the user to the first default uid
    initialPassword = my.config.user.pass;
  
  };

  # Add my custom motd
  users.motd = my.config.system.motd;

}
