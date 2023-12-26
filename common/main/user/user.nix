{ lib, pkgs, config, ... }:
{

  # Make users mutable
  users.mutableUsers = true;

  # Automatic login
  services.getty.autologinUser = if config.mine.user.autologin then config.mine.user.name else null;

  # My user
  users.groups."${config.mine.user.name}".gid = config.mine.user.gid;
  users.users."${config.mine.user.name}" = {

    # Simple user configuration
    isNormalUser = true;
    home = "/home/" + config.mine.user.name;
    description = config.mine.user.desc;

    # Primary group
    group = config.mine.user.name;

    # Give extra groups to the user
    extraGroups = [ "networkmanager" "wireshark" "plugdev" "kvm" ] ++
                  (if config.mine.user.admin              then [ "wheel" ]        else []) ++
                  (if config.mine.audio                   then [ "audio" ]        else []) ++
                  (if config.mine.graphics.enable         then [ "video" ]        else []) ++
                  (if config.mine.services.docker         then [ "docker" ]       else []) ++
                  (if config.mine.services.virtual.enable then [ "libvirtd" ]     else []) ++
                  (if config.mine.services.printing       then [ "scanner" "lp" ] else []) ++
                  (if (pkgs.reference.arch != pkgs.reference.arches.arm) then [ "adbusers" ] else []) ++
                  config.mine.user.groups;

    # Set out custom uid
    uid = config.mine.user.uid;

    # Set the user to the first default uid
    initialPassword = config.mine.user.pass;

  };

  # Add custom getty message
  services.getty.greetingLine = config.mine.system.getty.greeting;
  services.getty.helpLine = lib.mkForce ("\n" + config.mine.system.getty.help);

  # Add my custom motd
  users.motd = config.mine.system.motd;

}
