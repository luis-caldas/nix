{ my, lib, ... }:
{

  # Needed for ZFS to work
  networking.hostId = my.config.net.id;

  # Set the hostname
  networking.hostName = my.config.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use networkmanager
  networking.networkmanager.enable = true;

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

  # Auto start stuff
  systemd.services.starter = {
    script = lib.concatStrings (map (s: s + "\n") my.config.system.start);
    wantedBy = [ "multi-user.target" ];
  };

  # Files permissions
  systemd.services.filer = {
    script = lib.concatStrings (
      map (s: "chown :${my.config.system.filer} ${s}" + "\n")
      my.config.system.permit
    );
    wantedBy = [ "multi-user.target" ];
  };

}
