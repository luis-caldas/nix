{ my, mfunc, lib, ... }:
{

  # Make users mutable
  users.mutableUsers = true;

  # Automatic login
  services.getty.autologinUser = mfunc.useDefault my.config.user.autologin my.config.user.name null;

  # Add user to file permission group
  users.groups."${my.config.system.filer}" = {};

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
    extraGroups = [ "networkmanager" "wireshark" "${my.config.system.filer}" ] ++
                  mfunc.useDefault my.config.x86_64 [ "adbusers" ] [] ++
                  mfunc.useDefault my.config.audio [ "audio" ] [] ++
                  mfunc.useDefault my.config.graphical.enable [ "video" ] [] ++
                  mfunc.useDefault my.config.services.docker [ "docker" ] [] ++
                  mfunc.useDefault my.config.services.printing [ "scanner" "lp" ] [] ++
                  my.config.user.groups;

    # Set out custom uid
    uid = 1000;

    # Set the user to the first default uid
    initialPassword = my.config.user.pass;

  };

  # Define extra users
  users.extraUsers = mfunc.useDefault my.config.graphical.kodi {
    kodi.isNormalUser = true;
  } {};

  # Add custom getty message
  services.getty.greetingLine = my.config.system.getty.greeting;
  services.getty.helpLine = lib.mkOverride 70 ("\n" + my.config.system.getty.help);

  # Add my custom motd
  users.motd = my.config.system.motd;

}
