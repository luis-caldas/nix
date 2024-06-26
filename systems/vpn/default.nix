{ pkgs, lib, config, modulesPath, ... }:
{

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
    services.prometheus.enable = true;
    services.prometheus.password = "/data/prometheus/pass";
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

  # Firewall setup
  # The firewall will only work after the NAT
  mine.network.firewall.enable = true;
  mine.network.firewall.ping = true;
  networking.firewall = {
    allowedTCPPorts = [
      # Escape Port
      pkgs.networks.ports.https
      # SSH
      (builtins.head config.services.openssh.ports)
      # Prometheus
      config.services.prometheus.port
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
  networking.wireguard.interfaces.wire = {
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
