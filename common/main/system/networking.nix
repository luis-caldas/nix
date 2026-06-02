{ pkgs, lib, config, ... }:
{

  # Needed for ZFS to work
  networking.hostId = pkgs.reference.id;

  # Set the hostname
  networking.hostName = config.mine.system.hostname; # Define the hostname

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use NetworkManager
  networking.networkmanager.enable = true;

  # Use a custom MAC for wired networking
  networking.networkmanager.ethernet.macAddress = config.mine.network.mac;
  networking.networkmanager.wifi.macAddress = config.mine.network.mac;

  # VPN
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];

  # Disable IPv6
  networking.enableIPv6 = lib.mkForce false;

  # Handle resolved if it is enabled
  services.resolved.settings.Resolve.FallbackDNS = lib.mkForce [];

  # Firewall configuration
  networking.firewall.enable = config.mine.network.firewall.enable;
  networking.firewall.allowPing = config.mine.network.firewall.ping;

  # Disable failing wait online service
  systemd.services.NetworkManager-wait-online.enable = pkgs.lib.mkForce false;

  # Production software
  programs.mininet.enable = config.mine.production.software;
  virtualisation.vswitch.enable = config.mine.production.software;

  # Enable editing of hosts file
  environment.etc.hosts.mode = "0644";

}