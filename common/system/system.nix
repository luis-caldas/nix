{ ... }:
let
  my = import ../../config.nix;
in
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

  # My timezone
  time.timeZone = my.config.system.timezone;

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
