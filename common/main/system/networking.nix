{ lib, config, ... }:
{

  # Needed for ZFS to work
  networking.hostId = config.mine.id;

  # Set the hostname
  networking.hostName = config.mine.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use networkmanager
  networking.networkmanager.enable = true;

  # Use custom mac for cable
  networking.networkmanager.ethernet.macAddress = config.mine.network.mac;
  networking.networkmanager.wifi.macAddress = config.mine.network.mac;

  # Disable ipv6
  networking.enableIPv6 = lib.mkForce false;

  # Firewall configuration
  networking.firewall.enable = config.mine.network.firewall.enable;
  networking.firewall.allowPing = config.mine.network.firewall.ping;

  # Enable editing of hosts file
  environment.etc.hosts.mode = "0644";

}