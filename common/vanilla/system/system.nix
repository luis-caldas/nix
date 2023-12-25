{ my, lib, pkgs, ... }:
{

  # Enable Gnome Virtual Filesystem to browse shares
  services.gvfs.enable = my.config.graphical.enable;

  # Add zfs scrubbing
  services.zfs.autoScrub.enable = true;

  # Enable trimming when possible
  services.zfs.trim.enable = true;

  # My timezone
  time.timeZone = my.config.system.timezone;

  # Set locale
  i18n.defaultLocale = my.config.system.locale;

  # Set default keyboard and their consoles
  services.xserver.layout = my.config.system.layout;
  console.useXkbConfig = true;

  # Enable ZRam if set
  zramSwap.enable = my.config.zram;
  zramSwap.memoryPercent = 50;

  # Set hardware switches
  services.logind.lidSwitch = "lock";
  services.logind.lidSwitchDocked = "lock";
  services.logind.lidSwitchExternalPower = "lock";
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
  '';

}
