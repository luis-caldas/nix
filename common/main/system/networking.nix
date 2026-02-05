{ pkgs, lib, config, ... }:
{

  # Needed for ZFS to work
  networking.hostId = pkgs.reference.id;

  # Set the hostname
  networking.hostName = config.mine.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use networkmanager
  networking.networkmanager.enable = true;

  # Use custom mac for cable
  networking.networkmanager.ethernet.macAddress = config.mine.network.mac;
  networking.networkmanager.wifi.macAddress = config.mine.network.mac;

  # VPN
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];

  # Disable ipv6
  networking.enableIPv6 = lib.mkForce false;

  # If ResolveD is somehow enabled
  services.resolved.fallbackDns = lib.mkForce [];

  # Firewall configuration
  networking.firewall.enable = config.mine.network.firewall.enable;
  networking.firewall.allowPing = config.mine.network.firewall.ping;

  # Disable failing wait online service
  systemd.services.NetworkManager-wait-online.enable = pkgs.lib.mkForce false;

  # Software production
  programs.mininet.enable = config.mine.production.software;
  virtualisation.vswitch.enable = config.mine.production.software;

  # Enable editing of hosts file
  environment.etc.hosts.mode = "0644";

}