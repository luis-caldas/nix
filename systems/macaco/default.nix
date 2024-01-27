{ pkgs, lib, config, modulesPath, ... }:
let

  # The system interfaces
  interfaces = {
    wireguard = "wire";
    local = "ens5";
  };

  # Agreed on ports
  wireguardPort = pkgs.networks.ports.simple;

in {

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "macaco";
    network.mac = "permanent";
    user.admin = false;
    services.ssh = true;
  };

  # Clear boot configuration
  boot.loader = lib.mkForce {};

  # Force IP parameters
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # All my imports
  imports = [
    # AWS files
    (modulesPath + "/virtualisation/amazon-image.nix")
  ];

  # DNS servers
  networking.networkmanager.insertNameservers = pkgs.networks.dns;

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  # Firewall setup
  # The firewall will only work after the NAT
  mine.network.firewall.enable = true;
  mine.network.firewall.ping = true;
  networking.firewall = {
    allowedTCPPorts = [
      22    # SSH port
      443   # HTTPS port for anything else
    ];
    allowedUDPPorts = [
      wireguardPort
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = pkgs.networks.allowed;
  };

  # Set up our NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = interfaces.local;
    internalInterfaces = [ interfaces.wireguard ];
    forwardPorts = [
      # SSH Port redirection to self
      { destination = "${pkgs.networks.tunnel.ips.macaco}:22"; proto = "tcp"; sourcePort = 22; }
      # Redirect the VPN ports to self
      {
        destination = "${pkgs.networks.tunnel.ips.macaco}:${builtins.toString wireguardPort}";
        proto = "udp";
        sourcePort = wireguardPort;
      }
      # Redirect all the rest to tunnel
      {
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
        proto = "tcp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
      }
      {
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
        proto = "udp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
      }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${interfaces.wireguard}" = {
    ips = [ "${pkgs.networks.tunnel.ips.macaco}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
    listenPort = pkgs.networks.ports.wireguard;
    privateKeyFile = "/data/wireguard/macaco.key";
    peers = [{
      publicKey = lib.strings.fileContents /data/wireguard/host.pub;
      presharedKeyFile = "/data/wireguard/macaco.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.ips.remote}/32" ];
      endpoint = "${lib.strings.fileContents /data/wireguard/endpoint}:${builtins.toString pkgs.networks.ports.simple}";
    }];
  };

  # User keys for ssh
  users.users."${config.mine.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/keys
  ];

  # Filesystems

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
