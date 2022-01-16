{ my, lib, ... }:
{

  # Allow non free software
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Needed for ZFS to work
  networking.hostId = my.id;

  # Add zfs scrubbing
  services.zfs.autoScrub.enable = true;

  # Fix ZFS scheduler
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';

  # Fix extra remote codes on g20
  services.udev.extraHwdb = ''
    evdev:input:*v4842p0001*
      KEYBOARD_KEY_c0041=enter
      KEYBOARD_KEY_c00cf=search
  '';

  # Enable trimming when possible
  services.zfs.trim.enable = true;

  # Set the hostname
  networking.hostName = my.config.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use networkmanager
  networking.networkmanager.enable = true;

  # Use custom mac for cable
  networking.networkmanager.ethernet.macAddress = my.config.net.mac.cable;
  networking.networkmanager.wifi.macAddress = my.config.net.mac.wifi;

  # Disable ipv6
  networking.enableIPv6 = false;

  # Firewall configuration
  networking.firewall.enable = my.config.net.firewall.enable;
  networking.firewall.allowPing = my.config.net.firewall.ping;

  # My timezone
  time.timeZone = my.config.system.timezone;

  # Set locale
  i18n.defaultLocale = my.config.system.locale;

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
