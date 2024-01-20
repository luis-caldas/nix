{ pkgs, lib, config, modulesPath, ... }:
let

  # Network info for
  networks = {
    # IPs and ranges
    host = "10.255.255.254";
    remote = "10.255.255.1";
    prefix = 24;
    # Default interface
    interface = "wire";
    # Default Wireguard port
    port = 123;

    # NAT listening interface
    external = "ens5";
    # Gap for internal communication
    gap = 49152;
  };

in
{

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "vps";
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
  networking.networkmanager.insertNameservers = [ "9.9.9.10" ];

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  # Firewall setup
  # The firewall will only work after the NAT
  networking.firewall = {
    enable = lib.mkForce true;
    allowedTCPPorts = [
      22    # SSH port
      443   # HTTPS port for anything else
    ];
    allowedUDPPorts = [
      123   # Wireguard
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"         # Loopback subnet
      "10.0.0.0/8"          # Local subnet
      "192.168.0.0/16"      # Local subnet
      "172.17.0.0/16"       # Docker subnet
    ];
  };

  # Set up our NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = networks.external;
    internalInterfaces = [ networks.interface ];
    forwardPorts = [
      # SSH Port redirection to self
      { destination = "${networks.host}:22"; proto = "tcp"; sourcePort = 22; }
      # Redirect the VPN ports to self
      {
        destination = "${networks.host}:${builtins.toString networks.port}";
        proto = "udp";
        sourcePort = networks.port;
      }
      # Redirect all the rest to tunnel
      {
        destination = "${networks.remote}:1-${builtins.toString networks.gap}";
        proto = "tcp";
        sourcePort = "1:${builtins.toString networks.gap}";
      }
      {
        destination = "${networks.remote}:1-${builtins.toString networks.gap}";
        proto = "udp";
        sourcePort = "1:${builtins.toString networks.gap}";
      }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${networks.interface}" = {
    ips = [ "${networks.host}/${builtins.toString networks.prefix}" ];
    listenPort = networks.port;
    privateKeyFile = "/data/wireguard/host.key";
    peers = [{
      publicKey = pkgs.functions.safeReadFile /data/wireguard/remote.pub;
      presharedKeyFile = "/data/wireguard/shared.key";
      allowedIPs = [ "${networks.remote}/32" ];
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
