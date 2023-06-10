{ my, mfunc, lib, ... }:
{

  # Make users mutable
  users.mutableUsers = true;

  # Automatic login
  services.getty.autologinUser = mfunc.useDefault my.config.user.autologin my.config.user.name null;

  # Add user to file permission group
  users.groups."${my.filer}" = {};

  # My user
  users.groups."${my.config.user.name}".gid = my.config.user.gid;
  users.users."${my.config.user.name}" = {

    # Simple user configuration
    isNormalUser = true;
    home = "/home/" + my.config.user.name;
    description = my.config.user.desc;

    # Primary group
    group = my.config.user.name;

    # Give extra groups to the user
    extraGroups = [ "networkmanager" "wireshark" "plugdev" "kvm" "${my.filer}" ] ++
                  mfunc.useDefault my.config.user.admin [ "wheel" ] [] ++
                  mfunc.useDefault my.config.audio [ "audio" ] [] ++
                  mfunc.useDefault my.config.graphical.enable [ "video" ] [] ++
                  mfunc.useDefault my.config.services.docker [ "docker" ] [] ++
                  mfunc.useDefault my.config.services.printing [ "scanner" "lp" ] [] ++
                  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [ "adbusers" ] [] ++
                  my.config.user.groups;

    # Set out custom uid
    uid = my.config.user.uid;

    # Set the user to the first default uid
    initialPassword = my.config.user.pass;

  };

  # Add custom getty message
  services.getty.greetingLine = my.config.system.getty.greeting;
  services.getty.helpLine = lib.mkOverride 70 ("\n" + my.config.system.getty.help);

  # Add my custom motd
  users.motd = my.config.system.motd;

}
