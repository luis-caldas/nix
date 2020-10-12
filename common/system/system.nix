{ my, ... }:
{

  # Needed for ZFS to work
  networking.hostId = my.config.net.id;

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

  # Enable adb debugging
  programs.adb.enable = my.config.x86_64;

  # My timezone
  time.timeZone = my.config.system.timezone;

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
