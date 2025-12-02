{ config, ... }:
{

  # Enable Gnome Virtual Filesystem to browse shares
  services.gvfs.enable = config.mine.graphics.enable;

  # My timezone
  time.timeZone = config.mine.system.timezone;

  # Set locale
  i18n.defaultLocale = config.mine.system.locale;

  # Set default keyboard and their consoles
  services.xserver.xkb.layout = builtins.head config.mine.system.layout;
  console.useXkbConfig = true;

  # Enable ZRam if set
  zramSwap.enable = config.mine.zram;
  zramSwap.memoryPercent = 50;

  # Hardware Switches
  services.logind.settings.Login = {

    # Lid Lock
    HandleLidSwitch = "lock";
    HandleLidSwitchDocked = "lock";
    HandleLidSwitchExternalPower = "lock";

    # Buttons Ignore
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
    HandleRebootKey = "ignore";
    HandleRebootKeyLongPress = "ignore";
    HandleSuspendKey = "ignore";
    HandleSuspendKeyLongPress = "ignore";
    HandleHibernateKey = "ignore";
    HandleHibernateKeyLongPress = "ignore";

  };

}
