{ pkgs, lib, config, modulesPath, ... }:
let

  # Bridge interface
  interfaces = {
    shared = "shared";
    wireguard = "wire";
  };

  # Agreed on ports
  wireguardPort = pkgs.networks.ports.simple;

in {

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "vpn";
    network.mac = "permanent";
    user.admin = false;
    services.ssh = true;
    services.docker = true;
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
    # Containers
    ./containers
  ];

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Networking virtual interface
  networking.interfaces = {
    "${interfaces.shared}" = {
      macAddress = pkgs.networks.mac.vpn;
      ipv4.addresses = [
        {
          address = pkgs.networks.virtual.address;
          prefixLength = pkgs.networks.virtual.prefix;
        }
      ];
    };
  };

  # Set up our NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = interfaces.shared;
    internalInterfaces = [ interfaces.wireguard ];
    forwardPorts = [
      # SSH Port redirection to self
      { destination = "${pkgs.networks.tunnel.ips.host}:22"; proto = "tcp"; sourcePort = 22; }
      # Redirect the VPN ports to self
      {
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString pkgs.networks.ports.open}";
        proto = "udp";
        sourcePort = pkgs.networks.ports.open;
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

  # Firewall setup
  # The firewall will only work after the NAT
  mine.network.firewall.enable = true;
  mine.network.firewall.ping = true;
  networking.firewall = {
    allowedTCPPorts = [
      22    # SSH port
    ];
    allowedUDPPorts = [
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = pkgs.networks.allowed;
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${interfaces.wireguard}" = {
    ips = [ "${pkgs.networks.tunnel.ips.vpn}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
    listenPort = pkgs.networks.ports.wireguard;
    privateKeyFile = "/data/wireguard/vpn.key";
    peers = [{
      publicKey = lib.strings.fileContents /data/wireguard/host.pub;
      presharedKeyFile = "/data/wireguard/vpn.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.network}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
      endpoint = "${lib.strings.fileContents /data/wireguard/endpoint}:${builtins.toString pkgs.networks.ports.simple}";
      persistentKeepalive = pkgs.networks.alive;
    }];
  };

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

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
